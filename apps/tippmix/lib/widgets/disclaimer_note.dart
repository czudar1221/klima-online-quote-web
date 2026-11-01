import 'package:flutter/material.dart';

import '../l10n/copy.dart';
import '../theme/app_theme.dart';

class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        Copy.disclaimer,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.navy,
          height: 1.45,
        ),
      ),
    );
  }
}
