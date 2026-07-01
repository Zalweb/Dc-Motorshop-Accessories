import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// App logo mark: shows the DC Motorshop Logo.svg on a black background
/// rounded square. Used wherever no custom shop logo is set.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: SvgPicture.asset(
            'assets/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
