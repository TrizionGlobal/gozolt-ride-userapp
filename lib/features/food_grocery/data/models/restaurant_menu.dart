enum FoodDietaryTag {
  vegetarian,
  vegan,
  halal,
  glutenFree,
}

class RestaurantMenuCategory {
  const RestaurantMenuCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;
}

class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.isAvailable,
    required this.isPopular,
    required this.isCustomizable,
    required this.dietaryTags,
    required this.maximumQuantity,
    this.offerPrice,
    this.offerText,
    this.imageUrl,
  });

  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final double? offerPrice;
  final String? offerText;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final bool isCustomizable;
  final List<FoodDietaryTag> dietaryTags;
  final int maximumQuantity;

  double get currentPrice => offerPrice ?? basePrice;

  bool get hasOffer {
    return offerPrice != null && offerPrice! < basePrice;
  }

  String get dietaryText {
    return dietaryTags.map((tag) {
      switch (tag) {
        case FoodDietaryTag.vegetarian:
          return 'Vegetarian';

        case FoodDietaryTag.vegan:
          return 'Vegan';

        case FoodDietaryTag.halal:
          return 'Halal';

        case FoodDietaryTag.glutenFree:
          return 'Gluten Free';
      }
    }).join(' • ');
  }
}
