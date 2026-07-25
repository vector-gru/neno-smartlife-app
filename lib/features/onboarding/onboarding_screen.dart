import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    const _OnboardingPage(
      svgAsset: 'assets/svg/onboarding_1.svg',
      title: AppStrings.onboarding1Title,
      subtitle: AppStrings.onboarding1Subtitle,
      bgColor: AppColors.onboardingBg1,
      accentColor: AppColors.primary,
    ),
    const _OnboardingPage(
      svgAsset: 'assets/svg/onboarding_2.svg',
      title: AppStrings.onboarding2Title,
      subtitle: AppStrings.onboarding2Subtitle,
      bgColor: AppColors.onboardingBg2,
      accentColor: AppColors.primary,
    ),
    const _OnboardingPage(
      svgAsset: 'assets/svg/onboarding_3.svg',
      title: AppStrings.onboarding3Title,
      subtitle: AppStrings.onboarding3Subtitle,
      bgColor: AppColors.onboardingBg3,
      accentColor: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    AppRouter.completeOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) =>
                _OnboardingPageWidget(page: _pages[i], size: size),
          ),

          // Top bar: logo + skip
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mini logo
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'N',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Neno SmartLife',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                  // Skip
                  if (!isLast)
                    GestureDetector(
                      onTap: _finish,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Text(
                          AppStrings.skip,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textOnDark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).padding.bottom + 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0.97),
                    AppColors.background,
                  ],
                  stops: const [0, 0.3, 1],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page dots
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.primary.withValues(alpha: 0.25),
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 3.5,
                      spacing: 5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? AppStrings.getStarted : AppStrings.next,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page data model ───────────────────────────────────────────────────────────
class _OnboardingPage {
  final String svgAsset;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color accentColor;

  const _OnboardingPage({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.accentColor,
  });
}

// ─── Single page widget ────────────────────────────────────────────────────────
class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  final Size size;

  const _OnboardingPageWidget({required this.page, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.bgColor,
      child: Column(
        children: [
          // Doodle illustration — takes upper 55% of screen
          SizedBox(
            height: size.height * 0.55,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle radial glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.7,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // SVG doodle
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
                  child: SvgPicture.asset(
                    page.svgAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textOnDark.withValues(alpha: 0.55),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Space for bottom controls overlay
          const SizedBox(height: 140),
        ],
      ),
    );
  }
}
