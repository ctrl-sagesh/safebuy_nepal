import 'package:flutter/material.dart';

/// SafeBuy Nepal brand logo — renders the app's official emblem
/// (`assets/icon/app_icon.png`: the crescent moon and rayed sun carrying a
/// verification check on a crimson field) so every in-app logo matches the
/// launcher icon exactly.
class NepalLogo extends StatelessWidget {
  const NepalLogo({super.key, this.size = 80, this.rounded = true});

  final double size;

  /// Clip to a rounded square (the launcher-icon shape). Set false for a
  /// plain square.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/icon/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
    if (!rounded) {
      return SizedBox(width: size, height: size, child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// The full SafeBuy Nepal brand lockup (emblem + wordmark) for headers and
/// app bars, so the branding is consistent everywhere.
class SafeBuyWordmark extends StatelessWidget {
  const SafeBuyWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/safebuy_wordmark.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
