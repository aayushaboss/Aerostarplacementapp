import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

const _logoAsset = 'assets/images/aerostar-logo.png';
const _markAsset = 'assets/images/aerostar-mark.png';

/// Width / height of [_logoAsset], so callers can size by height.
const _logoAspect = 810 / 223;

/// Aerostar's emblem (the two wing shapes and the star), without the lettering. [size] is its
/// height. Blue on white pages; pass [onBrand] on a solid-colour page to draw it white.
class BrandMark extends StatelessWidget {
  final double size;
  final bool onBrand;

  const BrandMark({super.key, this.size = 24, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _markAsset,
      height: size,
      color: onBrand ? AppColors.white : null,
      colorBlendMode: onBrand ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Aerostar',
    );
  }
}

/// "Powered by Aerostar": Aerostar Edge is an Aerostar product, so this sits right under the
/// logo on the first screens at a size that reads clearly (not fine print).
class PoweredByAerostar extends StatelessWidget {
  final double size;
  final TextAlign textAlign;

  const PoweredByAerostar({super.key, this.size = 14, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontFamily: kFontFamily, fontSize: size, height: 1.3, color: AppColors.gray500, fontWeight: AppFontWeight.medium),
        children: const [
          TextSpan(text: 'Powered by '),
          TextSpan(text: 'Aerostar', style: TextStyle(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
        ],
      ),
      textAlign: textAlign,
      maxLines: 1,
    );
  }
}

/// The full Aerostar Edge logo (emblem, "AEROSTAR" and the EDGE tag). [size] is a text-size
/// equivalent: the logo is drawn about 1.6 times that tall. Defaults suit a white page; on a
/// solid-colour page pass [onBrand] to draw it white.
class Wordmark extends StatelessWidget {
  final double size;
  final bool onBrand;

  const Wordmark({super.key, this.size = 22, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    final height = size * 1.6;
    return Image.asset(
      _logoAsset,
      height: height,
      width: height * _logoAspect,
      color: onBrand ? AppColors.white : null,
      colorBlendMode: onBrand ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Aerostar Edge',
    );
  }
}
