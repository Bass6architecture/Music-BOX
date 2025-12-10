import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Reusable list card styled like the "À reprendre" items.
class ListCardItem extends StatelessWidget {
  const ListCardItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onPlay,
    this.trailing,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.contentPadding = const EdgeInsets.all(12),
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final Widget? trailing;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PressableScale(
      scale: 0.98,
      borderRadius: borderRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.16),
                    theme.colorScheme.secondary.withValues(alpha: 0.16),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: contentPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    leading,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        (onPlay != null
                            ? GestureDetector(
                                onTap: onPlay,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Local micro-interaction: scale on press
class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.onTap,
    this.scale = 0.98,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;
  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _down ? widget.scale : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    );
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      behavior: HitTestBehavior.opaque,
      child: widget.borderRadius == null
          ? child
          : ClipRRect(borderRadius: widget.borderRadius!, child: child),
    );
  }
}
