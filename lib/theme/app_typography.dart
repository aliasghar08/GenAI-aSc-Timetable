import 'package:flutter/painting.dart';

/// Custom, native-rendered typography utility that eliminates `package:google_fonts`
/// Uses modern system font fallbacks (Inter, San Francisco, Segoe UI, Roboto)
/// ensuring instantaneous render without network font fetch delays or layout shifts.
class AppTypography {
  static const String _fontFamily =
      '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';

  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }
}
