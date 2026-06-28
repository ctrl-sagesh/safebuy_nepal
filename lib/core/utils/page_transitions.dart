import 'package:flutter/material.dart';

/// Custom slide + fade page route transition.
/// Used for all push navigations across the app.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideIn = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(position: slideIn, child: child),
            );
          },
        );
}

/// Bottom-up slide transition for modals and detail screens.
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideIn = Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(position: slideIn, child: child),
            );
          },
        );
}
