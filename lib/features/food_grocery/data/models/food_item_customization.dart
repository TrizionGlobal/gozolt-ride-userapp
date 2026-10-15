enum ModifierSelectionType {
  single,
  multiple,
}

class FoodModifierOption {
  const FoodModifierOption({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isAvailable,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final double priceAdjustment;
  final bool isAvailable;
  final bool isDefault;

  String get priceText {
    if (priceAdjustment == 0) {
      return 'Included';
    }

    return '+€${priceAdjustment.toStringAsFixed(2)}';
  }
}

class FoodModifierGroup {
  const FoodModifierGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minimumSelection,
    required this.maximumSelection,
    required this.displayOrder,
    required this.options,
  });

  final String id;
  final String name;
  final ModifierSelectionType selectionType;
  final bool isRequired;
  final int minimumSelection;
  final int maximumSelection;
  final int displayOrder;
  final List<FoodModifierOption> options;

  String get requirementText {
    final requirement = isRequired ? 'Required' : 'Optional';

    if (selectionType == ModifierSelectionType.single) {
      return '$requirement • Select 1';
    }

    if (minimumSelection > 0) {
      return '$requirement • Select $minimumSelection–$maximumSelection';
    }

    return '$requirement • Select up to $maximumSelection';
  }
}
