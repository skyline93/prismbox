import 'package:flutter/material.dart';

class MediaItemPlaceholder extends StatelessWidget {
  final IconData? icon;
  final Widget? child;

  const MediaItemPlaceholder({super.key, this.icon, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (icon != null) Icon(icon, color: Colors.grey[600], size: 24),
          if (child != null) child!,
        ],
      ),
    );
  }
}
