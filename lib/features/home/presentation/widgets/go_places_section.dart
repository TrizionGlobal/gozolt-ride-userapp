import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';

class GoPlacesSection extends StatelessWidget {
  const GoPlacesSection({super.key});

  static const _places = [
    _PlaceData(name: 'Valletta', imagePath: AssetPaths.placeValletta),
    _PlaceData(name: 'Mdina', imagePath: AssetPaths.placeMdina),
    _PlaceData(name: 'Gozo', imagePath: AssetPaths.placeGozo),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Go Places with GOZOLT',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _places.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final place = _places[index];
              return _PlaceCard(data: place);
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceData {
  final String name;
  final String imagePath;

  const _PlaceData({required this.name, required this.imagePath});
}

class _PlaceCard extends StatelessWidget {
  final _PlaceData data;

  const _PlaceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pushNamed(
          RouteNames.searchDestination,
          queryParameters: {'destination': data.name},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 140,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                data.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).cardTheme.color,
                  child: const Center(
                    child: Icon(Icons.place,
                        color: AppColors.primaryGold, size: 40),
                  ),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // City name
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  data.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
