import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color color;

  const AppLogo({
    super.key,
    this.fontSize = 32,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      "Mungle",
      style: GoogleFonts.dancingScript(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
