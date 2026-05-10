import 'package:flutter/material.dart';

class VinumSuccessIcon extends StatelessWidget {
  final double size;
  final double? iconSize;
  final Color? backgroundColor;
  final Color iconColor;

  const VinumSuccessIcon({
    super.key,
    this.size = 80,
    this.iconSize,
    this.backgroundColor,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF3DBA82),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        color: iconColor,
        size: iconSize ?? size * 0.55,
      ),
    );
  }
}
