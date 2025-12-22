import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/background/background_cubit.dart';


class MusicBoxScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const MusicBoxScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackgroundCubit, BackgroundType>(
      builder: (context, backgroundType) {
        final cubit = context.read<BackgroundCubit>();
        final assetPath = cubit.assetPath;
        final isCustomBackground = assetPath != null;

        // Determine effective background color
        // If custom background, use transparent for Scaffold to show container
        // Otherwise use provided color or theme default
        final effectiveBackgroundColor = isCustomBackground 
            ? Colors.transparent 
            : backgroundColor;

        return Container(
          decoration: isCustomBackground
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(assetPath),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Scaffold(
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            bottomNavigationBar: bottomNavigationBar,
            drawer: drawer,
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            backgroundColor: effectiveBackgroundColor,
          ),
        );
      },
    );
  }
}

