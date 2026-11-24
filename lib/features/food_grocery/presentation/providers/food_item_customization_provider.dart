import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_grocery_cart.dart';
import '../../data/models/food_item_customization.dart';
import '../../data/models/restaurant_menu.dart';
import 'food_grocery_cart_provider.dart';
import 'restaurant_menu_provider.dart';

final foodItemCustomizationProvider = StateNotifierProvider.autoDispose.family<
    FoodItemCustomizationNotifier,
    FoodItemCustomizationState,
    RestaurantMenuItem>(
  (ref, item) {
    final menuState = ref.watch(restaurantMenuProvider(item.restaurantId));
    final apiGroups = menuState.modifiersByItemId[item.id];
    final notifier = FoodItemCustomizationNotifier(item, apiGroups);

    final cart = ref.read(foodGroceryCartProvider);
    final existingItem = cart.items
        .where((c) =>
            c.cartType == FoodGroceryCartType.food &&
            c.productId == item.id &&
            c.supplierId == item.restaurantId)
        .lastOrNull;
    if (existingItem != null) {
      notifier.loadFromCartItem(existingItem);
    }

    return notifier;
  },
);

class FoodItemCustomizationState {
  const FoodItemCustomizationState({
    required this.item,
    required this.groups,
    required this.selectedOptionIds,
    this.optionCounts = const {},
    required this.quantity,
    required this.specialInstructions,
  });

  final RestaurantMenuItem item;
  final List<FoodModifierGroup> groups;
  final Map<String, Set<String>> selectedOptionIds;
  final Map<String, int> optionCounts;
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

  int optionCount(String groupId, String optionId) {
    if (!isOptionSelected(groupId: groupId, optionId: optionId)) {
      return 0;
    }
    return optionCounts[optionId] ?? 1;
  }

  int totalGroupCount(String groupId) {
    final optionIds = selectionsFor(groupId);
    var total = 0;
    for (final id in optionIds) {
      total += optionCounts[id] ?? 1;
    }
    return total;
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

    for (final entry in selectedOptionIds.entries) {
      final groupId = entry.key;
      for (final optionId in entry.value) {
        final option = optionById(optionId);
        if (option != null) {
          final count = optionCount(groupId, optionId);
          total += option.priceAdjustment * count;
        }
      }
    }

    return total;
  }

  /// Base price for 1 item unit, including size variant option if selected.
  double get baseItemPrice {
    FoodModifierOption? sizeOption;
    for (final group in groups) {
      if (group.id == 'size') {
        final sizeOptions = selectedOptionsFor(group);
        if (sizeOptions.isNotEmpty) {
          sizeOption = sizeOptions.first;
        }
        break;
      }
    }

    return item.currentPrice + (sizeOption?.priceAdjustment ?? 0.0);
  }

  /// Unit price for the base item.
  double get unitPrice {
    return baseItemPrice;
  }

  /// Total price for this customized line:
  /// (base item price * item quantity) + total add-ons price.
  /// The quantity stepper increments the item itself, while add-ons
  /// have their own independent quantity steppers.
  double get totalPrice {
    return (baseItemPrice * quantity) + modifierPrice;
  }

  bool get requiredSelectionsComplete {
    for (final group in groups) {
      if (!group.isRequired) {
        continue;
      }

      final count = totalGroupCount(group.id);

      if (count < group.minimumSelection) {
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

      final count = totalGroupCount(group.id);

      if (count < group.minimumSelection) {
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
    Map<String, int>? optionCounts,
    int? quantity,
    String? specialInstructions,
  }) {
    return FoodItemCustomizationState(
      item: item ?? this.item,
      groups: groups ?? this.groups,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      optionCounts: optionCounts ?? this.optionCounts,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class FoodItemCustomizationNotifier
    extends StateNotifier<FoodItemCustomizationState> {
  FoodItemCustomizationNotifier(
    RestaurantMenuItem item,
    List<FoodModifierGroup>? apiGroups,
  ) : super(
          FoodItemCustomizationState(
            item: item,
            groups: (apiGroups != null && apiGroups.isNotEmpty)
                ? apiGroups
                : const [],
            selectedOptionIds: _defaultSelections(
              (apiGroups != null && apiGroups.isNotEmpty)
                  ? apiGroups
                  : const [],
            ),
            optionCounts: _defaultCounts(
              (apiGroups != null && apiGroups.isNotEmpty)
                  ? apiGroups
                  : const [],
            ),
            quantity: 1,
            specialInstructions: '',
          ),
        );

  static Map<String, Set<String>> _defaultSelections(
    List<FoodModifierGroup> groups,
  ) {
    final selections = <String, Set<String>>{};

    for (final group in groups) {
      // Add-on options default to 0 count (unselected).
      // Only single-choice groups (e.g. Size) select a default option.
      if (group.selectionType == ModifierSelectionType.single) {
        final defaults = group.options
            .where((option) {
              return option.isDefault && option.isAvailable;
            })
            .map((option) => option.id)
            .toSet();

        if (defaults.isNotEmpty) {
          selections[group.id] = defaults;
        } else if (group.isRequired && group.options.isNotEmpty) {
          final firstAvail = group.options.firstWhere(
            (o) => o.isAvailable,
            orElse: () => group.options.first,
          );
          selections[group.id] = {firstAvail.id};
        }
      }
    }

    return selections;
  }

  static Map<String, int> _defaultCounts(
    List<FoodModifierGroup> groups,
  ) {
    final counts = <String, int>{};

    for (final group in groups) {
      if (group.selectionType == ModifierSelectionType.single) {
        for (final option in group.options) {
          if (option.isDefault && option.isAvailable) {
            counts[option.id] = 1;
          }
        }
      }
    }

    return counts;
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
    final updatedCounts = Map<String, int>.from(state.optionCounts);

    final currentSelections = updatedSelections[group.id] ?? <String>{};

    if (group.selectionType == ModifierSelectionType.single) {
      if (currentSelections.contains(option.id) && !group.isRequired) {
        currentSelections.clear();
        updatedCounts.remove(option.id);
      } else {
        for (final prevId in currentSelections) {
          updatedCounts.remove(prevId);
        }
        currentSelections
          ..clear()
          ..add(option.id);
        updatedCounts[option.id] = 1;
      }
    } else {
      if (currentSelections.contains(option.id)) {
        currentSelections.remove(option.id);
        updatedCounts.remove(option.id);
      } else {
        currentSelections.add(option.id);
        updatedCounts[option.id] = 1;
      }
    }

    if (currentSelections.isEmpty) {
      updatedSelections.remove(group.id);
    } else {
      updatedSelections[group.id] = currentSelections;
    }

    state = state.copyWith(
      selectedOptionIds: updatedSelections,
      optionCounts: updatedCounts,
    );

    return null;
  }

  String? incrementOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    if (!option.isAvailable) {
      return '${option.name} is currently unavailable';
    }

    if (group.selectionType == ModifierSelectionType.single) {
      return toggleOption(group: group, option: option);
    }

    final currentCount = state.optionCount(group.id, option.id);
    final updatedSelections = <String, Set<String>>{
      for (final entry in state.selectedOptionIds.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final updatedCounts = Map<String, int>.from(state.optionCounts);

    final currentSelections = updatedSelections[group.id] ?? <String>{};
    currentSelections.add(option.id);
    updatedSelections[group.id] = currentSelections;
    updatedCounts[option.id] = currentCount + 1;

    state = state.copyWith(
      selectedOptionIds: updatedSelections,
      optionCounts: updatedCounts,
    );

    return null;
  }

  void decrementOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    final currentCount = state.optionCount(group.id, option.id);
    if (currentCount <= 0) return;

    final updatedSelections = <String, Set<String>>{
      for (final entry in state.selectedOptionIds.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final updatedCounts = Map<String, int>.from(state.optionCounts);

    final currentSelections = updatedSelections[group.id] ?? <String>{};

    if (currentCount <= 1) {
      currentSelections.remove(option.id);
      updatedCounts.remove(option.id);
      if (currentSelections.isEmpty) {
        updatedSelections.remove(group.id);
      } else {
        updatedSelections[group.id] = currentSelections;
      }
    } else {
      updatedCounts[option.id] = currentCount - 1;
    }

    state = state.copyWith(
      selectedOptionIds: updatedSelections,
      optionCounts: updatedCounts,
    );
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

  void loadFromCartItem(FoodGroceryCartItem cartItem) {
    final selections = <String, Set<String>>{};
    final counts = <String, int>{};

    for (final modifier in cartItem.modifiers) {
      for (final group in state.groups) {
        final option = group.options
            .where((o) =>
                o.id == modifier.id ||
                o.name.trim().toLowerCase() ==
                    modifier.name.split(' (').first.trim().toLowerCase())
            .firstOrNull;
        if (option != null) {
          selections.putIfAbsent(group.id, () => <String>{}).add(option.id);
          counts[option.id] = modifier.quantity;
          break;
        }
      }
    }

    if (cartItem.variantId != null) {
      for (final group in state.groups) {
        if (group.id == 'size') {
          selections[group.id] = {cartItem.variantId!};
          break;
        }
      }
    }

    state = state.copyWith(
      selectedOptionIds: selections,
      optionCounts: counts,
      quantity: cartItem.quantity > 0 ? cartItem.quantity : 1,
      specialInstructions: cartItem.instructions ?? '',
    );
  }

  void reset() {
    state = state.copyWith(
      selectedOptionIds: _defaultSelections(state.groups),
      optionCounts: _defaultCounts(state.groups),
      quantity: 1,
      specialInstructions: '',
    );
  }
}
