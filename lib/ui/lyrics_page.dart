
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart'; // For ScrollDirection
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../widgets/optimized_artwork.dart';

import '../player/player_cubit.dart';

enum LyricsMode { loading, found, options, manual, noConnection }

class LyricsPage extends StatefulWidget {
  const LyricsPage({super.key});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> with SingleTickerProviderStateMixin {
  LyricsMode _mode = LyricsMode.loading;
  String? _lyrics;
  Timer? _timeoutTimer;

  bool _notifiedFound = false;
  int? _lastSongId;
  Timer? _copyDebounce;
  bool _copySheetVisible = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  double _fontSize = 16;
  double _lineHeight = 1.6;
  bool _alignCenter = true;
  bool _blurBackground = false;
  int? _lyricsSavedAt;
  bool _fromCache = false;
  static const int _lyricsTtlMs = 30 * 24 * 60 * 60 * 1000; // 30 jours
  bool _staleCache = false;
  String? _lastCopyText;
  
  // Synced Lyrics State
  List<LyricLine> _parsedLyrics = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isAutoScrolling = true;
  Timer? _resumeAutoScrollTimer;
  int _currentIndex = -1;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _lastSongId = _song?.id;
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulse = Tween<double>(begin: 0.35, end: 0.65).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    _loadFontSize();
    _loadLineHeight();
    _loadAlignCenter();
    _loadBlurBackground();
    _startAutoSearch();
    _ensureRecommendedDefaultsIfFirstRun();

    // Listen to playback position for sync using JustAudio player directly
    _positionSub = _cubit.player.positionStream.listen((duration) {
      if (_parsedLyrics.isNotEmpty && _mode == LyricsMode.found) {
        final pos = duration.inMilliseconds;
        _syncLyrics(pos);
      }
    });

    // Also need a periodic ticker for smooth updates if audioHandler doesn't emit often enough?
    // PlayerCubit has a position stream based on AudioPlayer? 
    // Usually AudioHandler emits frequently, but we can also use a ticker if needed.
    // For now, rely on AudioService state updates or add a periodic generic timer if smoother sync needed.
  }

  void _syncLyrics(int position) {
    if (_parsedLyrics.isEmpty) return;

    // Find the current line based on position
    int newIndex = -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (position >= _parsedLyrics[i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }

    // Only update if index changed
    if (newIndex != _currentIndex) {
      if (mounted) {
        setState(() => _currentIndex = newIndex);
        if (_isAutoScrolling && newIndex != -1) {
          _scrollToIndex(newIndex);
        }
      }
    }
  }

  void _scrollToIndex(int index) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  void _parseLrc(String raw) {
    _parsedLyrics.clear();
    final lines = raw.split('\n');
    final p = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');
    
    for (var line in lines) {
      final match = p.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.length == 2 ? '${msStr}0' : msStr); // .12 -> 120ms, .123 -> 123ms
        
        final time = (min * 60 * 1000) + (sec * 1000) + ms;
        final text = match.group(4)!.trim();
        _parsedLyrics.add(LyricLine(time, text));
      } else {
         // Non-synced lines? If we are in "Synced Mode", maybe ignore or add as comment?
         // For now, if we found ANY synced lines, we treat it as LRC.
         // If NO synced lines found at all, we fall back to plain text.
         if (line.trim().isNotEmpty && _parsedLyrics.isNotEmpty) {
           // Maybe append to previous line?
         }
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _resumeAutoScrollTimer?.cancel();
    _scrollController.dispose();
    _timeoutTimer?.cancel();
    _copyDebounce?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  PlayerCubit get _cubit => context.read<PlayerCubit>();
  SongModel? get _song => _cubit.currentSong;

  String? get _lyricsCacheKey {
    final s = _song;
    if (s == null) return null;
    final id = s.id;
    if (id != null) return 'lyrics_' + id.toString();
    final artist = (s.artist ?? '').trim();
    final title = (s.title).trim();
    return 'lyrics_${artist}_$title';
  }

  Future<void> _loadCachedLyrics() async {
    final key = _lyricsCacheKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null && cached.trim().isNotEmpty) {
        String? text;
        int? ts;
        final c = cached.trimLeft();
        if (c.startsWith('{')) {
          try {
            final m = json.decode(c) as Map<String, dynamic>;
            text = (m['text'] ?? m['lyrics'] ?? m['txt'])?.toString();
            final n = m['ts'];
            if (n is int) ts = n; else if (n is double) ts = n.toInt();
          } catch (_) {
            text = cached;
          }
        } else {
          text = cached;
        }
        if (text != null && text.trim().isNotEmpty) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final stale = ts != null && (now - ts) > _lyricsTtlMs;
          if (!mounted) return;
          setState(() {
            _lyrics = _cleanupLyrics(text!.trim());
            _lyricsSavedAt = ts;
            _fromCache = true;
            _staleCache = stale;
            _mode = LyricsMode.found;
          });
          // Parse loaded lyrics for sync
          if (_lyrics != null) _parseLrc(_lyrics!);
          
          _notifyFoundOnce();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLyricsToCache(String text) async {
    final key = _lyricsCacheKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload = json.encode({'text': text, 'ts': now});
      await prefs.setString(key, payload);
      _lyricsSavedAt = now;
      _fromCache = false;
      _staleCache = false;
    } catch (_) {}
  }

  String _normalizeArtist(String a) {
    var x = a;
    x = x.replaceAll(RegExp(r'\s*\((feat\.|ft\.|featuring)[^)]*\)', caseSensitive: false), '');
    x = x.replaceAll(RegExp(r'\s*(feat\.|ft\.|featuring)\s+.*$', caseSensitive: false), '');
    return x.trim();
  }

  String _normalizeTitle(String t) {
    var x = t;
    // Enlever qualités audio : (256k), (320k), (128kbps), etc.
    x = x.replaceAll(RegExp(r'\s*\((\d+k(bps)?|\d+kbps)\)', caseSensitive: false), '');
    // Enlever parenthèses et crochets
    x = x.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    x = x.replaceAll(RegExp(r'\s*\[[^\]]*\]'), '');
    x = x.replaceAll(RegExp(r'\s*-\s*(remaster(ed)?\s*\d{0,4}|live|single version|radio edit).*$', caseSensitive: false), '');
    x = x.replaceAll('"', '');
    // Remplacer underscores par espaces
    x = x.replaceAll('_', ' ');
    // Nettoyer espaces multiples
    x = x.replaceAll(RegExp(r'\s+'), ' ');
    return x.trim();
  }

  /// Extraire artiste depuis titre mal formaté (ex: "Artist_-_Song(256k)")
  Map<String, String>? _parseVidmateFormat(String title) {
    // Pattern 1 : "Artist_-_Song(256k)" ou "Artist_-_Song"
    final match1 = RegExp(r'^([^_]+?)_-_(.+?)(?:\(\d+k\))?$', caseSensitive: false).firstMatch(title);
    if (match1 != null) {
      return {
        'artist': match1.group(1)!.trim(),
        'title': match1.group(2)!.trim(),
      };
    }
    
    // Pattern 2 : "Artist - Song"
    final match2 = RegExp(r'^([^-]+?)\s*-\s*(.+?)$').firstMatch(title);
    if (match2 != null) {
      final artist = match2.group(1)!.trim();
      // Vérifier que ce n'est pas juste un numéro de piste
      if (!RegExp(r'^\d+$').hasMatch(artist)) {
        return {
          'artist': artist,
          'title': match2.group(2)!.trim(),
        };
      }
    }
    
    return null;
  }

  List<String> _artistCandidates(String a) {
    final base = <String>{};
    
    // Si artiste est "unknown" ou vide, essayer de parser le titre
    if (a.isEmpty || a.toLowerCase().contains('unknown')) {
      final parsed = _parseVidmateFormat(_song?.title ?? '');
      if (parsed != null && parsed['artist']!.isNotEmpty) {
        base.add(parsed['artist']!);
      }
    } else {
      base.add(a);
      base.add(_normalizeArtist(a));
    }
    
    // Split on comma, ampersand, and " x " patterns
    final split = a.split(RegExp(r'[,&]|\bx\b', caseSensitive: false)).map((s) => s.trim()).where((e) => e.isNotEmpty);
    base.addAll(split);
    
    // Filtrer "unknown"
    return base.where((e) => e.trim().isNotEmpty && !e.toLowerCase().contains('unknown')).map((e) => e.trim()).toSet().toList();
  }

  Future<String?> _fetchLyricsOvh(String artist, String title) async {
    try {
      final uri = Uri.parse('https://api.lyrics.ovh/v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}');
      final resp = await http.get(uri, headers: const {'User-Agent': 'MusicBox/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        final txt = map['lyrics']?.toString();
        if (txt != null && txt.trim().isNotEmpty) return txt;
      }
    } on SocketException {
      rethrow; // ✅ Propagate network errors for detection
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchLyricsLyrist(String artist, String title) async {
    try {
      final q = '$title $artist';
      final uri = Uri.parse('https://lyrist.vercel.app/api/lyrics?w=${Uri.encodeComponent(q)}');
      final resp = await http.get(uri, headers: const {'User-Agent': 'MusicBox/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        final txt = (map['lyrics'] ?? map['lyric'] ?? map['text'])?.toString();
        if (txt != null && txt.trim().isNotEmpty) return txt;
      }
    } on SocketException {
      rethrow; // ✅ Propagate network errors for detection
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchLyricsLrclib(String artist, String title) async {
    try {
      final uri = Uri.parse('https://lrclib.net/api/search?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}');
      final resp = await http.get(uri, headers: const {'User-Agent': 'MusicBox/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List && data.isNotEmpty) {
          // Choose the best candidate by simple score
          String norm(String s) => s.toLowerCase().trim();
          final at = norm(artist);
          final tt = norm(title);
          Map<String, dynamic>? best;
          int bestScore = -1;
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final ia = norm((item['artistName'] ?? '').toString());
              final it = norm((item['trackName'] ?? '').toString());
              int score = 0;
              if (ia == at) score += 2; else if (ia.contains(at) || at.contains(ia)) score += 1;
              if (it == tt) score += 2; else if (it.contains(tt) || tt.contains(it)) score += 1;
              if (score > bestScore) { bestScore = score; best = item; }
            }
          }
          final selected = best ?? (data.first as Map<String, dynamic>);
          final plain = (selected['plainLyrics'] ?? selected['lyrics'])?.toString();
          if (plain != null && plain.trim().isNotEmpty) return plain;
        }
      }
    } on SocketException {
      rethrow; // ✅ Propagate network errors for detection
    } catch (_) {}
    return null;
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble('lyrics_font_size');
      if (v != null && v >= 12 && v <= 28) {
        if (!mounted) return;
        setState(() => _fontSize = v);
      }
    } catch (_) {}
  }

  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lyrics_font_size', _fontSize);
    } catch (_) {}
  }

  Future<void> _loadLineHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble('lyrics_line_height');
      if (v != null && v >= 1.2 && v <= 2.0) {
        if (!mounted) return;
        setState(() => _lineHeight = v);
      }
    } catch (_) {}
  }

  Future<void> _saveLineHeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lyrics_line_height', _lineHeight);
    } catch (_) {}
  }

  Future<void> _loadAlignCenter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool('lyrics_align_center');
      if (v != null) {
        if (!mounted) return;
        setState(() => _alignCenter = v);
      }
    } catch (_) {}
  }

  Future<void> _saveAlignCenter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lyrics_align_center', _alignCenter);
    } catch (_) {}
  }

  Future<void> _loadBlurBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool('lyrics_blur_bg');
      if (v != null) {
        if (!mounted) return;
        setState(() => _blurBackground = v);
      }
    } catch (_) {}
  }

  Future<void> _saveBlurBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lyrics_blur_bg', _blurBackground);
    } catch (_) {}
  }

  void _ensureRecommendedDefaultsIfFirstRun() {
    // Apply immersive defaults only once and only where no prior user prefs exist.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final prefs = await SharedPreferences.getInstance();
        final applied = prefs.getBool('lyrics_defaults_applied_v2') ?? false;
        if (applied) return;

        final hasFont = prefs.containsKey('lyrics_font_size');
        final hasLH = prefs.containsKey('lyrics_line_height');
        final hasAlign = prefs.containsKey('lyrics_align_center');
        final hasBlur = prefs.containsKey('lyrics_blur_bg');

        final mq = MediaQuery.of(context);
        final shortest = mq.size.shortestSide;
        final isWide = shortest >= 600; // tablet-ish
        final defaultFont = isWide ? 20.0 : 18.0;
        const defaultLH = 1.65;
        const defaultAlign = true;
        const defaultBlur = true;

        if (!mounted) return;
        setState(() {
          if (!hasFont) _fontSize = defaultFont;
          if (!hasLH) _lineHeight = defaultLH;
          if (!hasAlign) _alignCenter = defaultAlign;
          if (!hasBlur) _blurBackground = defaultBlur;
        });

        if (!hasFont) await prefs.setDouble('lyrics_font_size', _fontSize);
        if (!hasLH) await prefs.setDouble('lyrics_line_height', _lineHeight);
        if (!hasAlign) await prefs.setBool('lyrics_align_center', _alignCenter);
        if (!hasBlur) await prefs.setBool('lyrics_blur_bg', _blurBackground);
        await prefs.setBool('lyrics_defaults_applied_v2', true);
      } catch (_) {}
    });
  }

  String _cleanupLyrics(String input) {
    try {
      var t = input.replaceAll('\r\n', '\n');
      final lines = t.split('\n');
      // Enlever entêtes parasites (Aperçu, Paroles, Lyrics) au début
      while (lines.isNotEmpty && lines.first.trim().isEmpty) {
        lines.removeAt(0);
      }
      final headerRe = RegExp(r'^(aperçu|paroles|lyrics)$', caseSensitive: false);
      while (lines.isNotEmpty && headerRe.hasMatch(lines.first.trim())) {
        lines.removeAt(0);
        while (lines.isNotEmpty && lines.first.trim().isEmpty) {
          lines.removeAt(0);
        }
      }
      // Réduire les multiples lignes vides consécutives
      final out = <String>[];
      var empty = 0;
      for (final l in lines) {
        if (l.trim().isEmpty) {
          empty++;
          if (empty > 1) continue;
          out.add('');
        } else {
          empty = 0;
          out.add(l.trimRight());
        }
      }
      return out.join('\n').trim();
    } catch (_) {
      return input.trim();
    }
  }

  Future<void> _openReaderSettings() async {
    double tempSize = _fontSize;
    double tempLH = _lineHeight;
    bool tempCenter = _alignCenter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_fields),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.lyricsDisplay, style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppLocalizations.of(context)!.blurBackground),
                        subtitle: Text(AppLocalizations.of(context)!.blurBackgroundDesc),
                        value: _blurBackground,
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return null;
                        }),
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _blurBackground = v);
                          _saveBlurBackground();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.alignment),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text(AppLocalizations.of(context)!.alignLeft),
                            selected: !tempCenter,
                            onSelected: (_) {
                              setSheetState(() => tempCenter = false);
                              setState(() => _alignCenter = false);
                              _saveAlignCenter();
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(AppLocalizations.of(context)!.alignCenter),
                            selected: tempCenter,
                            onSelected: (_) {
                              setSheetState(() => tempCenter = true);
                              setState(() => _alignCenter = true);
                              _saveAlignCenter();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('${AppLocalizations.of(context)!.textSize} (${_formatNumber(tempSize)})'),
                      Slider(
                        value: tempSize,
                        min: 12,
                        max: 28,
                        divisions: 16,
                        label: tempSize.toStringAsFixed(0),
                        onChanged: (v) {
                          setSheetState(() => tempSize = v);
                          setState(() => _fontSize = v);
                          _saveFontSize();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('${AppLocalizations.of(context)!.lineHeight} (${_formatNumber(tempLH)})'),
                      Slider(
                        value: tempLH,
                        min: 1.2,
                        max: 2.0,
                        divisions: 8,
                        label: tempLH.toStringAsFixed(2),
                        onChanged: (v) {
                          setSheetState(() => tempLH = v);
                          setState(() => _lineHeight = v);
                          _saveLineHeight();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(() { tempSize = 16; tempLH = 1.6; });
                              setState(() { _fontSize = 16; _lineHeight = 1.6; _alignCenter = true; _blurBackground = false; });
                              _saveFontSize();
                              _saveLineHeight();
                              _saveAlignCenter();
                              _saveBlurBackground();
                            },
                            child: Text(AppLocalizations.of(context)!.reset),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(AppLocalizations.of(context)!.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  String _formatAgo(int? ts) {
    if (ts == null) return '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - ts).clamp(0, 1 << 62);
    if (diff < 60000) return '${(diff / 1000).round()} s';
    if (diff < 3600000) return '${(diff / 60000).round()} min';
    if (diff < 86400000) return '${(diff / 3600000).round()} h';
    return '${(diff / 86400000).round()} j';
  }

  Widget _buildCacheInfo() {
    // Information de cache masquée car non pertinente pour l'utilisateur
    return const SizedBox.shrink();
  }

  void _handleCopiedText(String copied) {
    final txt = copied.trim();
    if (txt.isEmpty) return;
    if (_lastCopyText == txt) return;
    _lastCopyText = txt;
    _copyDebounce?.cancel();
    _copyDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (_copySheetVisible) return;
      _copySheetVisible = true;
      final res = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppLocalizations.of(context)!.copiedText, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        txt,
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx, true);
                    },
                    child: Text(AppLocalizations.of(context)!.useAsLyrics),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx, false);
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              ),
            ),
          );
        },
      );
      _copySheetVisible = false;
      if (res == true && mounted) {
        final cleaned = _cleanupLyrics(txt);
        setState(() {
          _lyrics = cleaned;
          _mode = LyricsMode.found;
        });
        await _saveLyricsToCache(cleaned);
        _notifyFoundOnce();
      }
    });
  }

  void _startAutoSearch() {
    setState(() {
      _mode = LyricsMode.loading;
      _lyrics = null;
      _notifiedFound = false;
    });
    _timeoutTimer?.cancel();
    // 22s timeout pour laisser le temps aux chansons mal formatées
    _timeoutTimer = Timer(const Duration(seconds: 22), () {
      if (!mounted) return;
      if (_mode == LyricsMode.loading && _lyrics == null) {
        setState(() => _mode = LyricsMode.options);
      }
    });
    _loadCachedLyrics();
    _autoSearch();
  }

  Future<void> _autoSearch() async {
    final s = _song;
    if (s == null) {
      if (!mounted) return;
      setState(() => _mode = LyricsMode.options);
      return;
    }
    var a = (s.artist ?? '').trim();
    var t = (s.title).trim();
    if (_mode == LyricsMode.found && _lyrics != null && !_staleCache) return;

    // Si artiste est "unknown", essayer de parser le titre
    if (a.isEmpty || a.toLowerCase().contains('unknown')) {
      final parsed = _parseVidmateFormat(t);
      if (parsed != null) {
        a = parsed['artist']!;
        t = parsed['title']!;
      }
    }

    final candidatesA = _artistCandidates(a);
    final candidatesT = <String>{t, _normalizeTitle(t)}.where((e) => e.trim().isNotEmpty).toList();

    try {
      for (final ca in candidatesA) {
        for (final ct in candidatesT) {
          if (!mounted || (_mode == LyricsMode.found && _lyrics != null)) return;
          // Priority: LRCLIB (reliable), then Lyrist, then OVH
          String? txt = await _fetchLyricsLrclib(ca, ct);
          txt ??= await _fetchLyricsLyrist(ca, ct);
          txt ??= await _fetchLyricsOvh(ca, ct);
          if (txt != null && txt.trim().isNotEmpty) {
            final cleaned = _cleanupLyrics(txt.trim());
            if (!mounted) return;
            // Try to parse synced lyrics if present
            _parseLrc(cleaned);
            
            setState(() {
              _lyrics = cleaned;
              _mode = LyricsMode.found;
              _fromCache = false;
              _lyricsSavedAt = DateTime.now().millisecondsSinceEpoch;
              _staleCache = false;
            });
            await _saveLyricsToCache(cleaned);
            _timeoutTimer?.cancel();
            return;
          }
        }
      }
    } on SocketException catch (_) {
      // ✅ No internet connection detected
      if (!mounted) return;
      setState(() => _mode = LyricsMode.noConnection);
      _timeoutTimer?.cancel();
      return;
    } catch (_) {
      // Other errors - continue to timeout
    }
    // Do nothing here; the global timeout will switch to options if still loading
  }

  void _notifyFoundOnce() {
    // ✅ Removed snackbar per user request - keep method for backwards compatibility
    _notifiedFound = true;
  }

  Widget _skeletonBar({double widthFactor = 1.0, double height = 14}) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: _pulse.value);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = _song;
    if (s == null) return const SizedBox.shrink();
    final title = s.title.trim();
    final artist = (s.artist ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12), // Reduced padding right for icon
      child: Row(
        children: [
          if (s.id != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: OptimizedArtwork.square(id: s.id!, type: ArtworkType.AUDIO, size: 56),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
              ],
            ),
          ),
          
          // Edit Button (Direct Access)
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: AppLocalizations.of(context)!.lyricsEdit,
            onPressed: () => _openEditor(),
          ),

          // Menu (More Options)
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                   if (controller.isOpen) controller.close(); else controller.open();
                },
              );
            },
            menuChildren: [
              if (_lyrics != null && _lyrics!.isNotEmpty)
                MenuItemButton(
                  leadingIcon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  child: Text(AppLocalizations.of(context)!.lyricsDelete, style: const TextStyle(color: Colors.red)),
                  onPressed: () => _showDeleteConfirmation(),
                ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.folder_open_rounded),
                child: Text(AppLocalizations.of(context)!.lyricsImportFile),
                onPressed: () => _showImportFileDialog(),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.paste_rounded),
                child: Text(AppLocalizations.of(context)!.lyricsImportClipboard),
                onPressed: () async {
                   final data = await Clipboard.getData(Clipboard.kTextPlain);
                   if (data?.text != null && data!.text!.isNotEmpty) {
                     _openEditor(initialText: data.text!);
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard empty')));
                   }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.searchingLyrics),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _skeletonBar(widthFactor: 0.85, height: 18),
                      _skeletonBar(widthFactor: 0.9),
                      _skeletonBar(widthFactor: 0.95),
                      _skeletonBar(widthFactor: 0.8),
                      _skeletonBar(widthFactor: 0.92),
                      const SizedBox(height: 12),
                      _skeletonBar(widthFactor: 0.88, height: 18),
                      _skeletonBar(widthFactor: 0.93),
                      _skeletonBar(widthFactor: 0.86),
                      _skeletonBar(widthFactor: 0.96),
                      _skeletonBar(widthFactor: 0.78),
                      const SizedBox(height: 12),
                      _skeletonBar(widthFactor: 0.9, height: 18),
                      _skeletonBar(widthFactor: 0.82),
                      _skeletonBar(widthFactor: 0.95),
                      _skeletonBar(widthFactor: 0.87),
                      _skeletonBar(widthFactor: 0.91),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Manual search mode with full-screen WebView
  Future<void> _enterManual() async {
    final s = _song;
    final artist = (s?.artist ?? '').trim();
    final title = (s?.title ?? '').trim();
    final q = '$title $artist lyrics';
    
    // Ouvrir une page plein écran pour la recherche web
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _LyricsWebSearchPage(
          searchQuery: q,
          onCopiedText: _handleCopiedText,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case LyricsMode.loading:
        return _buildLoadingSkeleton();
      case LyricsMode.found:
        // Check if we have synced lyrics
        if (_parsedLyrics.isNotEmpty) {
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle) {
                // User is scrolling
                if (_isAutoScrolling) {
                  setState(() => _isAutoScrolling = false);
                }
                _resumeAutoScrollTimer?.cancel();
              } else {
                // Scroll stopped, schedule resume
                _resumeAutoScrollTimer?.cancel();
                _resumeAutoScrollTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() => _isAutoScrolling = true);
                    if (_currentIndex != -1) _scrollToIndex(_currentIndex);
                  }
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 16),
              itemCount: _parsedLyrics.length,
              itemBuilder: (context, index) {
                final line = _parsedLyrics[index];
                final bool isActive = index == _currentIndex;
                final bool isPast = index < _currentIndex;
                
                return GestureDetector(
                   onTap: () {
                     // Optional: Seek to timestamp
                     // _cubit.audioHandler?.seek(Duration(milliseconds: line.timestamp));
                   },
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     curve: Curves.easeInOut,
                     margin: const EdgeInsets.symmetric(vertical: 8),
                     padding: EdgeInsets.symmetric(vertical: 8, horizontal: _alignCenter ? 12 : 0),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8),
                       color: isActive 
                           ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) 
                           : Colors.transparent,
                     ),
                     child: Text(
                       line.text,
                       textAlign: _alignCenter ? TextAlign.center : TextAlign.left,
                       style: TextStyle(
                         fontSize: isActive ? _fontSize * 1.1 : _fontSize,
                         height: _lineHeight,
                         fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                         color: isActive 
                             ? Theme.of(context).colorScheme.primary 
                             : Theme.of(context).colorScheme.onSurface.withValues(alpha: isPast ? 0.5 : 0.8),
                       ),
                     ),
                   ),
                );
              },
            ),
          );
        }

        // Fallback for unsynced lyrics
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildCacheInfo(),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        _lyrics ?? '',
                        textAlign: _alignCenter ? TextAlign.center : TextAlign.left,
                        style: TextStyle(
                          height: _lineHeight,
                          fontSize: _fontSize,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_staleCache)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.loading,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case LyricsMode.options:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.lyricsNotFound,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _startAutoSearch,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retryLyrics),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _enterManual,
                icon: const Icon(Icons.search),
                label: Text(AppLocalizations.of(context)!.webSearch),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      case LyricsMode.manual:
        // Mode manuel maintenant géré par une page plein écran séparée
        return const SizedBox.shrink();
      case LyricsMode.noConnection:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noConnectionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _startAutoSearch,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<PlayerCubit>().currentSong;
    final title = current?.title ?? AppLocalizations.of(context)!.lyrics;
    // Detect song change while page is open
    final curId = current?.id;
    if (curId != _lastSongId) {
      _lastSongId = curId;
      // Restart search for the new song
      // Schedule microtask to avoid setState during build
      Future.microtask(() {
        if (mounted) _startAutoSearch();
      });
    }

    Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildBody(),
    );

    Widget buildBackdrop() {
      final s = _song;
      if (!_blurBackground || s?.id == null) return const SizedBox.shrink();
      final songId = s!.id!;
      final customPath = context.select((PlayerCubit c) => c.state.customArtworkPaths[songId]);
      final hasCustom = (customPath != null && customPath.isNotEmpty && File(customPath).existsSync());
      return Positioned.fill(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCustom)
              Image.file(
                File(customPath!),
                fit: BoxFit.cover,
              )
            else
              QueryArtworkWidget(
                id: songId,
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: Container(color: Colors.black12),
              ),
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_outlined),
            tooltip: AppLocalizations.of(context)!.settings,
            onPressed: _openReaderSettings,
          ),
          if (_mode == LyricsMode.found && _lyrics != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: AppLocalizations.of(context)!.share,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _lyrics!));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.lyricsCopied)),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          buildBackdrop(),
          content,
        ],
      ),
    );
  }
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.lyricsDelete),
        content: Text(AppLocalizations.of(context)!.lyricsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLyrics();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLyrics() async {
    final key = _lyricsCacheKey;
    if (key != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
    if (mounted) {
      setState(() {
        _lyrics = null;
        _mode = LyricsMode.options; // Revenir aux options
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.lyricsDeleted)),
      );
    }
  }

  void _showImportFileDialog() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'lrc'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        if (content.isNotEmpty && mounted) {
          _openEditor(initialText: content);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _openEditor({String? initialText}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _LyricsEditor(
          initialText: initialText ?? _lyrics ?? '',
          songTitle: _song?.title ?? '',
        ),
      ),
    );

    if (result != null && mounted) {
      final cleaned = _cleanupLyrics(result);
      if (cleaned.isNotEmpty) {
        setState(() {
           _lyrics = cleaned;
           _mode = LyricsMode.found;
           _lyricsSavedAt = DateTime.now().millisecondsSinceEpoch;
        });
        _parseLrc(cleaned);
        await _saveLyricsToCache(cleaned);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.lyricsSaved)));
      }
    }
  }

}

// Page plein écran pour la recherche web de paroles
class _LyricsWebSearchPage extends StatefulWidget {
  final String searchQuery;
  final void Function(String) onCopiedText;

  const _LyricsWebSearchPage({
    required this.searchQuery,
    required this.onCopiedText,
  });

  @override
  State<_LyricsWebSearchPage> createState() => _LyricsWebSearchPageState();
}

class _LyricsWebSearchPageState extends State<_LyricsWebSearchPage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _initWebView();
    
    // Afficher automatiquement le conseil au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTipBottomSheet();
    });
  }
  
  void _showTipBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.tip, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.copyTip),
            ],
          ),
        ),
      ),
    );
  }



  void _initWebView() {

    final urlStr = widget.searchQuery.startsWith('http') 
        ? widget.searchQuery 
        : 'https://www.google.com/search?q=${Uri.encodeComponent(widget.searchQuery)}';

    final url = Uri.parse(urlStr);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('CopyChannel', onMessageReceived: (JavaScriptMessage msg) {
        widget.onCopiedText(msg.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.copiedText),
            duration: const Duration(seconds: 2),
          ),
        );
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            // Inject JavaScript pour détecter les copies
            const js = '''
(function(){
  try {
    if (window.__lyricsCopyListenerAdded) return;
    window.__lyricsCopyListenerAdded = true;
    document.addEventListener('copy', function(){
      var txt = '';
      try { txt = (window.getSelection && window.getSelection().toString()) || ''; } catch(e) {}
      if (!txt && document.activeElement && document.activeElement.value != null) {
        try {
          var el = document.activeElement;
          txt = el.value.substring(el.selectionStart||0, el.selectionEnd||0);
        } catch(e) {}
      }
      if (txt) { CopyChannel.postMessage(txt); }
    }, true);
  } catch(e) {}
})();
''';
            try { await _controller?.runJavaScript(js); } catch (_) {}
          },
        ),
      )
      ..loadRequest(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.webSearch),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try { await _controller?.reload(); } catch (_) {}
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showTipBottomSheet(),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller!),
    );
  }
}

class _LyricsEditor extends StatefulWidget {
  final String initialText;
  final String songTitle;

  const _LyricsEditor({required this.initialText, required this.songTitle});

  @override
  State<_LyricsEditor> createState() => _LyricsEditorState();
}

class _LyricsEditorState extends State<_LyricsEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lyricsEdit),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context, _controller.text);
            },
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             if (widget.songTitle.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(bottom: 12),
                 child: Text(widget.songTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
             Expanded(
               child: TextField(
                 controller: _controller,
                 maxLines: null,
                 expands: true,
                 textAlignVertical: TextAlignVertical.top,
                 decoration: InputDecoration(
                   hintText: AppLocalizations.of(context)!.lyricsPasteHint,
                   border: const OutlineInputBorder(),
                   filled: true,
                 ),
                 cursorColor: Colors.white,
                 style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
               ),
             ),
          ],
        ),
      ),
    );
  }

}

class LyricLine {
  final int timestamp; // milliseconds
  final String text;

  const LyricLine(this.timestamp, this.text);
}
