import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Floating iOS-style liquid glass capsule for the home tab bar.
///
/// Uses a real refraction shader (Impeller backdrop on modern Android/iOS),
/// not a BackdropFilter frost. Must be stacked over page content — never
/// isolated in a [RepaintBoundary] or it cannot sample what sits behind it.
class LiquidGlassHomeTabBar extends StatelessWidget {
  static const double height = 64;
  static const double horizontalInset = 20;
  static const double bottomGap = 16;

  final Widget child;

  const LiquidGlassHomeTabBar({
    super.key,
    required this.child,
  });

  static LiquidGlassStyle _style(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return LiquidGlassStyle(
      shape: const LiquidGlassShape.continuousRoundedRectangle(
        cornerRadius: height / 2,
        borderWidth: 1.15,
        lightIntensity: 1.2,
        lightDirection: 80,
        lightMode: LiquidGlassLightMode.edge,
        borderType: OpticalBorder(
          borderSaturation: 1.4,
          ambientIntensity: 1.15,
          borderSolidity: 0.18,
          lightSpread: 0.55,
        ),
      ),
      appearance: LiquidGlassAppearance(
        color: isDark ? const Color(0x33000000) : const Color(0x28FFFFFF),
        blur: const LiquidGlassBlur(sigmaX: 3.5, sigmaY: 3.5),
        saturation: 1.18,
        shadow: LiquidGlassShadow(
          blur: 10,
          opacity: isDark ? 0.42 : 0.2,
          color: Colors.black,
          offset: const Offset(0, 7),
          cornerRadius: height / 2,
        ),
      ),
      refraction: const LiquidGlassRefraction(
        magnification: 1.03,
        chromaticAberration: 0.0035,
        refractionMode: LiquidGlassRefractionMode.shapeRefraction,
        refractionType: OpticalRefraction(
          refraction: 1.5,
          refractionWidth: 20,
          depth: 0.12,
        ),
      ),
      adaptivity: LiquidGlassAdaptivity(
        continuousGlassColor: true,
        initialBrightness: brightness,
        glassColorOnDark: const Color(0x3D000000),
        glassColorOnLight: const Color(0x3DFFFFFF),
        contentColorOnDark: const Color(0xFFF5F5F7),
        contentColorOnLight: const Color(0xFF1C1C1E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Positioned(
      left: horizontalInset,
      right: horizontalInset,
      bottom: MediaQuery.paddingOf(context).bottom + bottomGap,
      child: SizedBox(
        height: height,
        child: LiquidGlassLens(
          style: _style(brightness),
          child: child,
        ),
      ),
    );
  }
}
