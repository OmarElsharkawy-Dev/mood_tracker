import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.appColors.outline);
  }
}
