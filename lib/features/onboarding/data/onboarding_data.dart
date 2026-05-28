import '../../../core/constants/asset_paths.dart';

class OnboardingPageData {
  final String title;
  final String highlightedWord;
  final String subtitle;
  final String imagePath;
  final bool titleAllGold;
  final double imageHeight;
  final bool fadeTop;
  final bool fullWidthImage;
  final double horizontalPadding;

  const OnboardingPageData({
    required this.title,
    required this.highlightedWord,
    required this.subtitle,
    required this.imagePath,
    this.titleAllGold = false,
    this.imageHeight = 280.0,
    this.fadeTop = false,
    this.fullWidthImage = false,
    this.horizontalPadding = 32.0,
  });
}

const onboardingPages = [
  OnboardingPageData(
    title: '"Your Ride, ',
    highlightedWord: 'Your Way"',
    subtitle:
        'Enjoy the pinnacle of individualized mobility. Adjust every aspect of your trip to fit your lifestyle.',
    imagePath: AssetPaths.onboardingRide,
  ),
  OnboardingPageData(
    title: '"Earn GoCoin, ',
    highlightedWord: 'Every Ride"',
    subtitle:
        'Obtain digital rewards on each journey. You can use it to get premium upgrades and exclusive luxury benefits.',
    imagePath: AssetPaths.onboardingCoins,
    imageHeight: 320.0,
    horizontalPadding: 16.0,
  ),
  OnboardingPageData(
    title: '"Track ',
    highlightedWord: 'Every Moment"',
    subtitle:
        'With elite safety protocols and Real-time ride tracking, you can rest assured that your journey will be safe from beginning to end.',
    imagePath: AssetPaths.onboardingTracking,
    imageHeight: 360.0,
    fadeTop: true,
    fullWidthImage: true,
  ),
];
