import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../models/food_grocery_delivery_address.dart';
import '../models/food_item_customization.dart';
import '../models/food_restaurant.dart';
import '../models/grocery_catalogue.dart';
import '../models/grocery_product_details.dart';
import '../models/grocery_store.dart';
import '../models/restaurant_menu.dart';

final foodGroceryRemoteDatasourceProvider =
    Provider<FoodGroceryRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return FoodGroceryRemoteDatasource(dio);
});

class FoodGroceryMenuResponse {
  const FoodGroceryMenuResponse({
    required this.restaurant,
    required this.categories,
    required this.items,
    required this.modifiersByItemId,
  });

  final FoodRestaurant restaurant;
  final List<RestaurantMenuCategory> categories;
  final List<RestaurantMenuItem> items;
  final Map<String, List<FoodModifierGroup>> modifiersByItemId;
}

class FoodGroceryCatalogueResponse {
  const FoodGroceryCatalogueResponse({
    required this.store,
    required this.categories,
    required this.products,
    required this.variantsByProductId,
  });

  final GroceryStore store;
  final List<GroceryProductCategory> categories;
  final List<GroceryProduct> products;
  final Map<String, List<GroceryProductSelectionOption>> variantsByProductId;
}

class FoodGroceryHomeResponse {
  const FoodGroceryHomeResponse({
    this.defaultAddress,
    this.activeOrder,
    this.recommendedRestaurants = const [],
    this.recommendedStores = const [],
    this.recentOrder,
  });

  final FoodGroceryDeliveryAddress? defaultAddress;
  final Map<String, dynamic>? activeOrder;
  final List<FoodRestaurant> recommendedRestaurants;
  final List<GroceryStore> recommendedStores;
  final Map<String, dynamic>? recentOrder;
}

class FoodGroceryRemoteDatasource {
  FoodGroceryRemoteDatasource(this._dio);

  final Dio _dio;

  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data') && raw.containsKey('success')) {
      return raw['data'];
    }
    return raw;
  }

  static double _toDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static RestaurantOperationalStatus _parseRestaurantStatus(dynamic status) {
    switch (status?.toString().toUpperCase()) {
      case 'CLOSING_SOON':
        return RestaurantOperationalStatus.closingSoon;
      case 'BUSY':
        return RestaurantOperationalStatus.busy;
      case 'CLOSED':
        return RestaurantOperationalStatus.closed;
      case 'TEMPORARILY_UNAVAILABLE':
        return RestaurantOperationalStatus.temporarilyUnavailable;
      case 'OPEN':
      default:
        return RestaurantOperationalStatus.open;
    }
  }

  static GroceryStoreOperationalStatus _parseStoreStatus(dynamic status) {
    switch (status?.toString().toUpperCase()) {
      case 'CLOSING_SOON':
        return GroceryStoreOperationalStatus.closingSoon;
      case 'BUSY':
        return GroceryStoreOperationalStatus.busy;
      case 'CLOSED':
        return GroceryStoreOperationalStatus.closed;
      case 'TEMPORARILY_UNAVAILABLE':
        return GroceryStoreOperationalStatus.temporarilyUnavailable;
      case 'OPEN':
      default:
        return GroceryStoreOperationalStatus.open;
    }
  }

  static FoodDietaryTag? _parseDietaryTag(dynamic tag) {
    switch (tag?.toString().toUpperCase()) {
      case 'VEGETARIAN':
        return FoodDietaryTag.vegetarian;
      case 'VEGAN':
        return FoodDietaryTag.vegan;
      case 'HALAL':
        return FoodDietaryTag.halal;
      case 'GLUTEN_FREE':
      case 'GLUTENFREE':
        return FoodDietaryTag.glutenFree;
      default:
        return null;
    }
  }

  static GroceryProductUnitType _parseUnitType(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'PACK':
        return GroceryProductUnitType.pack;
      case 'WEIGHT':
        return GroceryProductUnitType.weight;
      case 'PIECE':
        return GroceryProductUnitType.piece;
      case 'FIXED_UNIT':
      default:
        return GroceryProductUnitType.fixedUnit;
    }
  }

  static GroceryProductStockStatus _parseStockStatus(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'LOW_STOCK':
        return GroceryProductStockStatus.lowStock;
      case 'OUT_OF_STOCK':
        return GroceryProductStockStatus.outOfStock;
      case 'IN_STOCK':
      default:
        return GroceryProductStockStatus.inStock;
    }
  }

  static FoodRestaurant parseRestaurant(Map<String, dynamic> json) {
    final cuisinesRaw = json['cuisines'] as List<dynamic>? ?? const [];
    return FoodRestaurant(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cuisines: cuisinesRaw.map((e) => e.toString()).toList(),
      rating: _toDouble(json['rating'], 4.5),
      ratingCount: _toInt(json['ratingCount'], 0),
      estimatedDeliveryTime:
          json['estimatedDeliveryTime']?.toString() ?? '25–35 min',
      deliveryFee: _toDouble(json['deliveryFee'], 0),
      distanceKm: _toDouble(json['distanceKm'], 1.5),
      priceLevel: json['priceLevel']?.toString() ?? '€€',
      status: _parseRestaurantStatus(json['status']),
      isFavourite: json['isFavourite'] == true,
      hasVegetarianOptions: json['hasVegetarianOptions'] == true,
      address: json['address']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      offerText: json['offerText']?.toString(),
      promotionalTag: json['promotionalTag']?.toString(),
    );
  }

  static GroceryStore parseGroceryStore(Map<String, dynamic> json) {
    final catsRaw = json['mainCategories'] as List<dynamic>? ?? const [];
    final matchingRaw = json['matchingProductNames'] as List<dynamic>? ?? const [];
    return GroceryStore(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeType: json['storeType']?.toString() ?? 'Supermarket',
      mainCategories: catsRaw.map((e) => e.toString()).toList(),
      rating: _toDouble(json['rating'], 4.5),
      ratingCount: _toInt(json['ratingCount'], 0),
      estimatedDeliveryTime:
          json['estimatedDeliveryTime']?.toString() ?? '25–35 min',
      deliveryFee: _toDouble(json['deliveryFee'], 0),
      distanceKm: _toDouble(json['distanceKm'], 1.5),
      minimumOrder: _toDouble(json['minimumOrder'], 0),
      status: _parseStoreStatus(json['status']),
      isFavourite: json['isFavourite'] == true,
      matchingProductNames: matchingRaw.map((e) => e.toString()).toList(),
      imageUrl: json['imageUrl']?.toString(),
      offerText: json['offerText']?.toString(),
      promotionalTag: json['promotionalTag']?.toString(),
    );
  }

  static FoodGroceryDeliveryAddress parseAddress(Map<String, dynamic> json) {
    return FoodGroceryDeliveryAddress(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      recipientName: json['recipientName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Malta',
      postalCode: json['postalCode']?.toString() ?? '',
      apartmentDetails: json['apartmentDetails']?.toString(),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _toDouble(json['longitude']) : null,
      isDefault: json['isDefault'] == true,
    );
  }

  Future<FoodGroceryHomeResponse> getHome({double? lat, double? lng}) async {
    final res = await _dio.get(
      ApiConstants.foodGroceryHome,
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    final data = _unwrap(res.data) as Map<String, dynamic>;
    final recList = (data['recommended'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    final restaurants = <FoodRestaurant>[];
    final stores = <GroceryStore>[];
    for (final b in recList) {
      if (b['businessType']?.toString().toUpperCase() == 'GROCERY_STORE') {
        stores.add(parseGroceryStore(b));
      } else {
        restaurants.add(parseRestaurant(b));
      }
    }

    return FoodGroceryHomeResponse(
      defaultAddress: data['defaultAddress'] is Map<String, dynamic>
          ? parseAddress(data['defaultAddress'] as Map<String, dynamic>)
          : null,
      activeOrder: data['activeOrder'] is Map<String, dynamic>
          ? data['activeOrder'] as Map<String, dynamic>
          : null,
      recommendedRestaurants: restaurants,
      recommendedStores: stores,
      recentOrder: data['recentOrder'] is Map<String, dynamic>
          ? data['recentOrder'] as Map<String, dynamic>
          : null,
    );
  }

  Future<List<FoodRestaurant>> getRestaurants({
    String? search,
    String? category,
    String? sort,
    double? lat,
    double? lng,
    double? minRating,
    bool? freeDelivery,
    bool? hasOffers,
    bool? vegetarian,
    bool? openNow,
    int? maxMinutes,
  }) async {
    final res = await _dio.get(
      ApiConstants.foodGroceryRestaurants,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (minRating != null) 'minRating': minRating,
        if (freeDelivery == true) 'freeDelivery': 'true',
        if (hasOffers == true) 'hasOffers': 'true',
        if (vegetarian == true) 'vegetarian': 'true',
        if (openNow == true) 'openNow': 'true',
        if (maxMinutes != null) 'maxMinutes': maxMinutes,
      },
    );
    final data = _unwrap(res.data) as List<dynamic>;
    return data
        .map((e) => parseRestaurant(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FoodGroceryMenuResponse> getRestaurantMenu(String restaurantId) async {
    final res = await _dio.get(ApiConstants.foodGroceryRestaurantMenu(restaurantId));
    final data = _unwrap(res.data) as Map<String, dynamic>;

    final restaurant = parseRestaurant(
      Map<String, dynamic>.from(data['restaurant'] as Map),
    );
    final categories = (data['categories'] as List<dynamic>? ?? const [])
        .map((raw) {
          final c = Map<String, dynamic>.from(raw as Map);
          return RestaurantMenuCategory(
            id: c['id']?.toString() ?? '',
            name: c['name']?.toString() ?? '',
            displayOrder: _toInt(c['displayOrder']),
            isActive: c['isActive'] != false,
          );
        })
        .toList();

    final modifiersByItemId = <String, List<FoodModifierGroup>>{};
    final items = (data['items'] as List<dynamic>? ?? const []).map((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['id']?.toString() ?? '';

      final modGroupsRaw = p['modifierGroups'] as List<dynamic>? ?? const [];
      modifiersByItemId[id] = modGroupsRaw.map((mgRaw) {
        final mg = Map<String, dynamic>.from(mgRaw as Map);
        final optsRaw = mg['options'] as List<dynamic>? ?? const [];
        return FoodModifierGroup(
          id: mg['id']?.toString() ?? '',
          name: mg['name']?.toString() ?? '',
          selectionType: mg['selectionType']?.toString().toUpperCase() == 'MULTIPLE'
              ? ModifierSelectionType.multiple
              : ModifierSelectionType.single,
          isRequired: mg['isRequired'] == true,
          minimumSelection: _toInt(mg['minimumSelection']),
          maximumSelection: _toInt(mg['maximumSelection'], 1),
          displayOrder: _toInt(mg['displayOrder']),
          options: optsRaw.map((optRaw) {
            final opt = Map<String, dynamic>.from(optRaw as Map);
            return FoodModifierOption(
              id: opt['id']?.toString() ?? '',
              name: opt['name']?.toString() ?? '',
              priceAdjustment: _toDouble(opt['priceAdjustment']),
              isAvailable: opt['isAvailable'] != false,
              isDefault: opt['isDefault'] == true,
            );
          }).toList(),
        );
      }).toList();

      final tagsRaw = p['dietaryTags'] as List<dynamic>? ?? const [];
      return RestaurantMenuItem(
        id: id,
        restaurantId: p['restaurantId']?.toString() ?? restaurantId,
        categoryId: p['categoryId']?.toString() ?? 'popular',
        name: p['name']?.toString() ?? '',
        description: p['description']?.toString() ?? '',
        basePrice: _toDouble(p['basePrice']),
        offerPrice: p['offerPrice'] != null ? _toDouble(p['offerPrice']) : null,
        offerText: p['offerText']?.toString(),
        imageUrl: p['imageUrl']?.toString(),
        isAvailable: p['isAvailable'] != false,
        isPopular: p['isPopular'] == true,
        isCustomizable: p['isCustomizable'] == true ||
            (modifiersByItemId[id]?.isNotEmpty ?? false),
        dietaryTags: tagsRaw
            .map(_parseDietaryTag)
            .whereType<FoodDietaryTag>()
            .toList(),
        maximumQuantity: _toInt(p['maximumQuantity'], 10),
      );
    }).toList();

    return FoodGroceryMenuResponse(
      restaurant: restaurant,
      categories: categories,
      items: items,
      modifiersByItemId: modifiersByItemId,
    );
  }

  Future<List<GroceryStore>> getStores({
    String? search,
    String? category,
    String? sort,
    double? lat,
    double? lng,
    double? minRating,
    bool? freeDelivery,
    bool? hasOffers,
    bool? openNow,
    int? maxMinutes,
    double? maxMinimumOrder,
  }) async {
    final res = await _dio.get(
      ApiConstants.foodGroceryStores,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (minRating != null) 'minRating': minRating,
        if (freeDelivery == true) 'freeDelivery': 'true',
        if (hasOffers == true) 'hasOffers': 'true',
        if (openNow == true) 'openNow': 'true',
        if (maxMinutes != null) 'maxMinutes': maxMinutes,
        if (maxMinimumOrder != null) 'maxMinimumOrder': maxMinimumOrder,
      },
    );
    final data = _unwrap(res.data) as List<dynamic>;
    return data
        .map((e) => parseGroceryStore(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FoodGroceryCatalogueResponse> getStoreCatalogue(String storeId) async {
    final res = await _dio.get(ApiConstants.foodGroceryStoreCatalogue(storeId));
    final data = _unwrap(res.data) as Map<String, dynamic>;

    final store = parseGroceryStore(
      Map<String, dynamic>.from(data['store'] as Map),
    );
    final categories = (data['categories'] as List<dynamic>? ?? const [])
        .map((raw) {
          final c = Map<String, dynamic>.from(raw as Map);
          return GroceryProductCategory(
            id: c['id']?.toString() ?? '',
            name: c['name']?.toString() ?? '',
            displayOrder: _toInt(c['displayOrder']),
            isActive: c['isActive'] != false,
          );
        })
        .toList();

    final variantsByProductId = <String, List<GroceryProductSelectionOption>>{};
    final products = (data['products'] as List<dynamic>? ?? const []).map((raw) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['id']?.toString() ?? '';

      final variantsRaw = p['variants'] as List<dynamic>? ?? const [];
      variantsByProductId[id] = variantsRaw.map((vRaw) {
        final v = Map<String, dynamic>.from(vRaw as Map);
        return GroceryProductSelectionOption(
          id: v['id']?.toString() ?? '',
          name: v['name']?.toString() ?? '',
          unitText: v['unitText']?.toString() ?? '',
          price: _toDouble(v['price']),
          originalPrice:
              v['originalPrice'] != null ? _toDouble(v['originalPrice']) : null,
          stockStatus: _parseStockStatus(v['stockStatus']),
          availableQuantity: _toInt(v['availableQuantity'], 10),
          maximumQuantity: _toInt(v['maximumQuantity'], 10),
          isActive: v['isActive'] != false,
          isEstimatedWeight: v['isEstimatedWeight'] == true,
        );
      }).toList();

      return GroceryProduct(
        id: id,
        storeId: p['storeId']?.toString() ?? storeId,
        categoryId: p['categoryId']?.toString() ?? 'popular',
        name: p['name']?.toString() ?? '',
        brand: p['brand']?.toString() ?? '',
        description: p['description']?.toString() ?? '',
        unitType: _parseUnitType(p['unitType']),
        unitText: p['unitText']?.toString() ?? '',
        basePrice: _toDouble(p['basePrice']),
        offerPrice: p['offerPrice'] != null ? _toDouble(p['offerPrice']) : null,
        offerText: p['offerText']?.toString(),
        stockStatus: _parseStockStatus(p['stockStatus']),
        availableQuantity: _toInt(p['availableQuantity'], 20),
        maximumQuantity: _toInt(p['maximumQuantity'], 10),
        hasVariants:
            p['hasVariants'] == true || (variantsByProductId[id]?.isNotEmpty ?? false),
        isActive: p['isActive'] != false,
        imageUrl: p['imageUrl']?.toString(),
      );
    }).toList();

    return FoodGroceryCatalogueResponse(
      store: store,
      categories: categories,
      products: products,
      variantsByProductId: variantsByProductId,
    );
  }

  Future<bool> toggleFavourite(String businessId) async {
    final res = await _dio.post(ApiConstants.foodGroceryFavourite(businessId));
    final data = _unwrap(res.data) as Map<String, dynamic>;
    return data['isFavourite'] == true;
  }

  Future<List<FoodGroceryDeliveryAddress>> getAddresses() async {
    final res = await _dio.get(ApiConstants.foodGroceryAddresses);
    final data = _unwrap(res.data) as List<dynamic>;
    return data
        .map((e) => parseAddress(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FoodGroceryDeliveryAddress> createAddress(
    FoodGroceryDeliveryAddress address,
  ) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryAddresses,
      data: {
        'label': address.label,
        'recipientName': address.recipientName,
        'phoneNumber': address.phoneNumber,
        'addressLine': address.addressLine,
        'locality': address.locality,
        'city': address.city,
        'postalCode': address.postalCode,
        if (address.apartmentDetails != null)
          'apartmentDetails': address.apartmentDetails,
        if (address.latitude != null) 'latitude': address.latitude,
        if (address.longitude != null) 'longitude': address.longitude,
        'isDefault': address.isDefault,
      },
    );
    return parseAddress(Map<String, dynamic>.from(_unwrap(res.data) as Map));
  }

  Future<FoodGroceryDeliveryAddress> updateAddress(
    FoodGroceryDeliveryAddress address,
  ) async {
    final res = await _dio.patch(
      ApiConstants.foodGroceryAddressById(address.id),
      data: {
        'label': address.label,
        'recipientName': address.recipientName,
        'phoneNumber': address.phoneNumber,
        'addressLine': address.addressLine,
        'locality': address.locality,
        'city': address.city,
        'postalCode': address.postalCode,
        if (address.apartmentDetails != null)
          'apartmentDetails': address.apartmentDetails,
        if (address.latitude != null) 'latitude': address.latitude,
        if (address.longitude != null) 'longitude': address.longitude,
        'isDefault': address.isDefault,
      },
    );
    return parseAddress(Map<String, dynamic>.from(_unwrap(res.data) as Map));
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete(ApiConstants.foodGroceryAddressById(id));
  }

  Future<Map<String, dynamic>> createPaymentSheet(double amount) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryPaymentSheet,
      data: {'amount': amount},
    );
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<Map<String, dynamic>> createOrder({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? stripePaymentMethodId,
    String? stripePaymentIntentId,
    int goCoinsToUse = 0,
    String? deliveryAddressId,
    Map<String, dynamic>? deliveryAddressSnapshot,
    bool leaveAtDoor = false,
    String? deliveryInstructions,
  }) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryOrders,
      data: {
        'businessId': businessId,
        'items': items,
        'paymentMethod': paymentMethod,
        if (stripePaymentMethodId != null)
          'stripePaymentMethodId': stripePaymentMethodId,
        if (stripePaymentIntentId != null)
          'stripePaymentIntentId': stripePaymentIntentId,
        'goCoinsToUse': goCoinsToUse,
        if (deliveryAddressId != null) 'deliveryAddressId': deliveryAddressId,
        if (deliveryAddressSnapshot != null)
          'deliveryAddressSnapshot': deliveryAddressSnapshot,
        'leaveAtDoor': leaveAtDoor,
        if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
          'deliveryInstructions': deliveryInstructions,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<Map<String, dynamic>?> getActiveOrder() async {
    final res = await _dio.get(ApiConstants.foodGroceryActiveOrder);
    final raw = _unwrap(res.data);
    if (raw == null || raw is! Map || raw.isEmpty) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final res = await _dio.get(ApiConstants.foodGroceryOrderHistory);
    final data = _unwrap(res.data) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final res = await _dio.get(ApiConstants.foodGroceryOrderDetails(orderId));
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<Map<String, dynamic>> submitSubstitutions({
    required String orderId,
    required List<Map<String, dynamic>> decisions,
  }) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryOrderSubstitutions(orderId),
      data: {'decisions': decisions},
    );
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<Map<String, dynamic>> confirmOrderReceived(String orderId) async {
    final res = await _dio.post(ApiConstants.foodGroceryConfirmReceived(orderId));
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<Map<String, dynamic>> rateOrder({
    required String orderId,
    required int overallRating,
    required int supplierRating,
    required int deliveryRating,
    required List<String> tags,
    String? comment,
  }) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryRateOrder(orderId),
      data: {
        'overallRating': overallRating,
        'supplierRating': supplierRating,
        'deliveryRating': deliveryRating,
        'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }

  Future<List<Map<String, dynamic>>> getMessages(String orderId) async {
    final res = await _dio.get(ApiConstants.foodGroceryOrderMessages(orderId));
    final data = _unwrap(res.data) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String orderId,
    String message,
  ) async {
    final res = await _dio.post(
      ApiConstants.foodGroceryOrderMessages(orderId),
      data: {'message': message},
    );
    return Map<String, dynamic>.from(_unwrap(res.data) as Map);
  }
}

