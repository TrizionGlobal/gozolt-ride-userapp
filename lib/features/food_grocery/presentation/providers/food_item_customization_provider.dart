import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_item_customization.dart';
import '../../data/models/restaurant_menu.dart';

final foodItemCustomizationProvider = StateNotifierProvider.family<
    FoodItemCustomizationNotifier,
    FoodItemCustomizationState,
    RestaurantMenuItem>(
  (ref, item) {
    return FoodItemCustomizationNotifier(item);
  },
);

class FoodItemCustomizationState {
  const FoodItemCustomizationState({
    required this.item,
    required this.groups,
    required this.selectedOptionIds,
    required this.quantity,
    required this.specialInstructions,
  });

  final RestaurantMenuItem item;
  final List<FoodModifierGroup> groups;
  final Map<String, Set<String>> selectedOptionIds;
  final int quantity;
  final String specialInstructions;

  Set<String> selectionsFor(String groupId) {
    return selectedOptionIds[groupId] ?? <String>{};
  }

  bool isOptionSelected({
    required String groupId,
    required String optionId,
  }) {
    return selectionsFor(groupId).contains(optionId);
  }

  FoodModifierOption? optionById(String optionId) {
    for (final group in groups) {
      for (final option in group.options) {
        if (option.id == optionId) {
          return option;
        }
      }
    }

    return null;
  }

  double get modifierPrice {
    var total = 0.0;

    for (final optionIds in selectedOptionIds.values) {
      for (final optionId in optionIds) {
        total += optionById(optionId)?.priceAdjustment ?? 0;
      }
    }

    return total;
  }

  double get unitPrice {
    return item.currentPrice + modifierPrice;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }

  bool get requiredSelectionsComplete {
    for (final group in groups) {
      if (!group.isRequired) {
        continue;
      }

      final selectionCount = selectionsFor(group.id).length;

      if (selectionCount < group.minimumSelection) {
        return false;
      }

      if (selectionCount > group.maximumSelection) {
        return false;
      }
    }

    return true;
  }

  FoodModifierGroup? get firstMissingRequiredGroup {
    for (final group in groups) {
      if (!group.isRequired) {
        continue;
      }

      final selectionCount = selectionsFor(group.id).length;

      if (selectionCount < group.minimumSelection) {
        return group;
      }
    }

    return null;
  }

  List<FoodModifierOption> selectedOptionsFor(
    FoodModifierGroup group,
  ) {
    final selectedIds = selectionsFor(group.id);

    return group.options.where((option) {
      return selectedIds.contains(option.id);
    }).toList();
  }

  FoodItemCustomizationState copyWith({
    RestaurantMenuItem? item,
    List<FoodModifierGroup>? groups,
    Map<String, Set<String>>? selectedOptionIds,
    int? quantity,
    String? specialInstructions,
  }) {
    return FoodItemCustomizationState(
      item: item ?? this.item,
      groups: groups ?? this.groups,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class FoodItemCustomizationNotifier
    extends StateNotifier<FoodItemCustomizationState> {
  FoodItemCustomizationNotifier(
    RestaurantMenuItem item,
  ) : super(
          FoodItemCustomizationState(
            item: item,
            groups: _temporaryGroups,
            selectedOptionIds: _defaultSelections(),
            quantity: 1,
            specialInstructions: '',
          ),
        );

  static const List<FoodModifierGroup> _temporaryGroups = [
    FoodModifierGroup(
      id: 'size',
      name: 'Choose Size',
      selectionType: ModifierSelectionType.single,
      isRequired: true,
      minimumSelection: 1,
      maximumSelection: 1,
      displayOrder: 1,
      options: [
        FoodModifierOption(
          id: 'size-regular',
          name: 'Regular',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'size-large',
          name: 'Large',
          priceAdjustment: 2,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'size-family',
          name: 'Family',
          priceAdjustment: 4,
          isAvailable: true,
        ),
      ],
    ),
    FoodModifierGroup(
      id: 'crust',
      name: 'Choose Crust',
      selectionType: ModifierSelectionType.single,
      isRequired: true,
      minimumSelection: 1,
      maximumSelection: 1,
      displayOrder: 2,
      options: [
        FoodModifierOption(
          id: 'crust-classic',
          name: 'Classic Crust',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'crust-thin',
          name: 'Thin Crust',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'crust-stuffed',
          name: 'Cheese Stuffed Crust',
          priceAdjustment: 2.50,
          isAvailable: true,
        ),
      ],
    ),
    FoodModifierGroup(
      id: 'toppings',
      name: 'Extra Toppings',
      selectionType: ModifierSelectionType.multiple,
      isRequired: false,
      minimumSelection: 0,
      maximumSelection: 4,
      displayOrder: 3,
      options: [
        FoodModifierOption(
          id: 'topping-cheese',
          name: 'Extra Cheese',
          priceAdjustment: 1.50,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'topping-mushrooms',
          name: 'Mushrooms',
          priceAdjustment: 1,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'topping-olives',
          name: 'Olives',
          priceAdjustment: 1,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'topping-pepperoni',
          name: 'Pepperoni',
          priceAdjustment: 1.50,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'topping-chicken',
          name: 'Grilled Chicken',
          priceAdjustment: 2,
          isAvailable: false,
        ),
      ],
    ),
    FoodModifierGroup(
      id: 'remove',
      name: 'Remove Ingredients',
      selectionType: ModifierSelectionType.multiple,
      isRequired: false,
      minimumSelection: 0,
      maximumSelection: 3,
      displayOrder: 4,
      options: [
        FoodModifierOption(
          id: 'remove-onions',
          name: 'No Onions',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'remove-olives',
          name: 'No Olives',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'remove-sauce',
          name: 'No Sauce',
          priceAdjustment: 0,
          isAvailable: true,
        ),
      ],
    ),
    FoodModifierGroup(
      id: 'spice',
      name: 'Spice Level',
      selectionType: ModifierSelectionType.single,
      isRequired: false,
      minimumSelection: 0,
      maximumSelection: 1,
      displayOrder: 5,
      options: [
        FoodModifierOption(
          id: 'spice-mild',
          name: 'Mild',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'spice-medium',
          name: 'Medium',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'spice-hot',
          name: 'Hot',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'spice-extra-hot',
          name: 'Extra Hot',
          priceAdjustment: 0,
          isAvailable: true,
        ),
      ],
    ),
    FoodModifierGroup(
      id: 'cooking',
      name: 'Cooking Preference',
      selectionType: ModifierSelectionType.single,
      isRequired: false,
      minimumSelection: 0,
      maximumSelection: 1,
      displayOrder: 6,
      options: [
        FoodModifierOption(
          id: 'cooking-regular',
          name: 'Regular',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'cooking-well-done',
          name: 'Well Done',
          priceAdjustment: 0,
          isAvailable: true,
        ),
        FoodModifierOption(
          id: 'cooking-crispy',
          name: 'Extra Crispy',
          priceAdjustment: 0,
          isAvailable: true,
        ),
      ],
    ),
  ];

  static Map<String, Set<String>> _defaultSelections() {
    final selections = <String, Set<String>>{};

    for (final group in _temporaryGroups) {
      final defaults = group.options
          .where((option) {
            return option.isDefault && option.isAvailable;
          })
          .map((option) => option.id)
          .toSet();

      if (defaults.isNotEmpty) {
        selections[group.id] = defaults;
      }
    }

    return selections;
  }

  String? toggleOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    if (!option.isAvailable) {
      return '${option.name} is currently unavailable';
    }

    final updatedSelections = <String, Set<String>>{
      for (final entry in state.selectedOptionIds.entries)
        entry.key: Set<String>.from(entry.value),
    };

    final currentSelections = updatedSelections[group.id] ?? <String>{};

    if (group.selectionType == ModifierSelectionType.single) {
      if (currentSelections.contains(option.id) && !group.isRequired) {
        currentSelections.clear();
      } else {
        currentSelections
          ..clear()
          ..add(option.id);
      }
    } else {
      if (currentSelections.contains(option.id)) {
        currentSelections.remove(option.id);
      } else {
        if (currentSelections.length >= group.maximumSelection) {
          return 'You can select up to ${group.maximumSelection} options';
        }

        currentSelections.add(option.id);
      }
    }

    if (currentSelections.isEmpty) {
      updatedSelections.remove(group.id);
    } else {
      updatedSelections[group.id] = currentSelections;
    }

    state = state.copyWith(
      selectedOptionIds: updatedSelections,
    );

    return null;
  }

  void increaseQuantity() {
    if (state.quantity >= state.item.maximumQuantity) {
      return;
    }

    state = state.copyWith(
      quantity: state.quantity + 1,
    );
  }

  void decreaseQuantity() {
    if (state.quantity <= 1) {
      return;
    }

    state = state.copyWith(
      quantity: state.quantity - 1,
    );
  }

  void updateSpecialInstructions(String value) {
    final limitedValue = value.length > 300 ? value.substring(0, 300) : value;

    state = state.copyWith(
      specialInstructions: limitedValue,
    );
  }

  void reset() {
    state = state.copyWith(
      selectedOptionIds: _defaultSelections(),
      quantity: 1,
      specialInstructions: '',
    );
  }
}
