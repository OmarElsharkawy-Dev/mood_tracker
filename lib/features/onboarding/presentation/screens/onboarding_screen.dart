import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_controller.dart';
import '../widgets/illustration_how.dart';
import '../widgets/illustration_privacy.dart';
import '../widgets/illustration_what.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.today);
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final page = ref.watch(onboardingControllerProvider);
    final isLast = page == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => ref
                    .read(onboardingControllerProvider.notifier)
                    .setPage(i),
                children: [
                  OnboardingPage(
                    illustration: IllustrationWhat(color: colors.primary),
                    title: l10n.onboardingWhatTitle,
                    body: l10n.onboardingWhatBody,
                  ),
                  OnboardingPage(
                    illustration: IllustrationHow(
                      color: colors.onBackground,
                      accent: colors.primary,
                    ),
                    title: l10n.onboardingHowTitle,
                    body: l10n.onboardingHowBody,
                  ),
                  OnboardingPage(
                    illustration: IllustrationPrivacy(color: colors.primary),
                    title: l10n.onboardingPrivacyTitle,
                    body: l10n.onboardingPrivacyBody,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: i == page ? 12 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == page ? colors.primary : colors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: isLast ? _finish : _next,
                    child: Text(isLast
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
