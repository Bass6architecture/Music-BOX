import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';


import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_box/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';


// Phase d'Ã©tat pour l'Ã©cran de scan
enum ScanPhase { idle, scanning, done }

class ScanMusicPage extends StatefulWidget {
  const ScanMusicPage({super.key});

  @override
  State<ScanMusicPage> createState() => _ScanMusicPageState();
}

class _ScanMusicPageState extends State<ScanMusicPage> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  bool _hasPermission = false;
  bool _busy = false;

  int _minDurationMs = 30000; // 30 secs
  int _minSizeBytes = 50 * 1024; // 50 KB
  late final AnimationController _spinCtrl;
  ScanPhase _phase = ScanPhase.idle;
  int _addedCount = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _init();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final has = await _audioQuery.permissionsStatus();
    setState(() => _hasPermission = has);
    if (has) await _refreshCount();
  }

  Future<void> _requestPermission() async {
    final ok = await _audioQuery.permissionsRequest();
    setState(() => _hasPermission = ok);
    if (ok) await _refreshCount();
  }

  Future<void> _refreshCount() async {
    if (!_hasPermission) return;
    setState(() => _busy = true);
    try {
      // final songs = await _audioQuery.querySongs(
      //   sortType: SongSortType.TITLE,
      //   orderType: OrderType.ASC_OR_SMALLER,
      //   uriType: UriType.EXTERNAL,
      //   ignoreCase: true,
      // );
      // Applique les seuils choisis pour un aperÃ§u cohÃ©rent avec l'analyse.
      // final filtered = songs.where((s) {
      //   final int d = s.duration ?? 0;
      //   final int sz = s.size;
      //   return d >= _minDurationMs && sz >= _minSizeBytes;
      // }).toList();
      // setState(() {
      //   _lastMessage = 'BibliothÃ¨que mise Ã  jour (${filtered.length} titres)';
      // });
    } catch (e) {
      // setState(() => _lastMessage = 'Erreur lors de la mise Ã  jour: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _scanAll() async {
    if (!_hasPermission) {
      // setState(() => _lastMessage = "Permission requise");
      return;
    }
    if (!io.Platform.isAndroid) {
      // setState(() => _lastMessage = 'Le scan est disponible uniquement sur Android');
      return;
    }
    setState(() {
      _busy = true;
      _phase = ScanPhase.scanning;
      _addedCount = 0;
    });
    _spinCtrl.repeat();
    try {
      // Compte initial (avec filtres)
      final beforeSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      final beforeCount = beforeSongs.where((s) {
        final int d = s.duration ?? 0;
        final int sz = s.size;
        return d >= _minDurationMs && sz >= _minSizeBytes;
      }).length;

      // Appel direct du canal natif du plugin pour la mÃ©thode 'scan'.
      final channel = MethodChannel('com.lucasjosino.on_audio_query');
      // Racines courantes du stockage partagÃ© Android. On scanne toutes celles qui existent.
      final roots = <String>[
        '/storage/emulated/0',
        '/sdcard',
        '/storage/self/primary',
      ].where((p) => io.Directory(p).existsSync()).toList();
      if (roots.isEmpty) {
        // setState(() => _lastMessage = AppLocalizations.of(context)!.error);
        return;
      }
      var anyOk = false;
      for (final root in roots) {
        final ok = await channel.invokeMethod<bool>('scan', {"path": root});
        anyOk = anyOk || (ok == true);
      }
      await _refreshCount();

      // Compte aprÃ¨s scan (avec filtres)
      final afterSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      final afterCount = afterSongs.where((s) {
        final int d = s.duration ?? 0;
        final int sz = s.size;
        return d >= _minDurationMs && sz >= _minSizeBytes;
      }).length;

      final added = afterCount > beforeCount ? (afterCount - beforeCount) : 0;
      setState(() {
        _addedCount = added;
        _phase = ScanPhase.done;
        // _lastMessage = anyOk ? AppLocalizations.of(context)!.scanComplete : AppLocalizations.of(context)!.error;
      });
    } catch (e) {
      setState(() {
        // _lastMessage = '${AppLocalizations.of(context)!.error}: $e';
        _phase = ScanPhase.idle;
      });
    } finally {
      _spinCtrl.stop();
      _spinCtrl.reset();
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scanMusic, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Etat permissions
            if (!_hasPermission)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.permissionRequired,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _requestPermission,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context)!.allow),
                    ),
                  ],
                ),
              ),
            if (!_hasPermission) const SizedBox(height: 20),

            // Illustration circulaire moderne
            Center(
              child: RotationTransition(
                turns: _spinCtrl,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                        theme.colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _phase == ScanPhase.done ? Icons.check_circle_rounded : Icons.music_note_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Texte d'Ã©tat
            if (_phase == ScanPhase.scanning)
              Center(
                child: Text(
                  AppLocalizations.of(context)!.scanningInProgress,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_phase == ScanPhase.done) ...[
              Center(
                child: Text(
                  AppLocalizations.of(context)!.scanComplete,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.songCount(_addedCount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Options de filtrage
            if (_phase == ScanPhase.idle) ...[
              Container(
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.filterDuration,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.filterDuration,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment<int>(value: 30000, label: Text(AppLocalizations.of(context)!.duration30s)),
                        ButtonSegment<int>(value: 60000, label: Text(AppLocalizations.of(context)!.duration60s)),
                      ],
                      selected: {_minDurationMs},
                      onSelectionChanged: (sel) => setState(() => _minDurationMs = sel.first),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.filterSize,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment<int>(value: 50 * 1024, label: Text(AppLocalizations.of(context)!.size50kb)),
                        ButtonSegment<int>(value: 100 * 1024, label: Text(AppLocalizations.of(context)!.size100kb)),
                      ],
                      selected: {_minSizeBytes},
                      onSelectionChanged: (sel) => setState(() => _minSizeBytes = sel.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bouton principal
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _phase == ScanPhase.scanning
                  ? null
                  : (_phase == ScanPhase.done ? () => Navigator.of(context).maybePop() : _scanAll),
              child: Text(
                _phase == ScanPhase.done ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.startScan,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



