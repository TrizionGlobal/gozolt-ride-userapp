import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/referral_info.dart';
import '../models/reward_rules.dart';
import '../models/reward_summary.dart';
import '../models/reward_transaction.dart';

class RewardsRemoteDatasource {
  final Dio _dio;

  RewardsRemoteDatasource(this._dio);

  Future<RewardSummary> getRewardSummary() async {
    final response = await _dio.get(ApiConstants.rewardSummary);
    return RewardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RewardTransaction>> getRewardHistory({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;

    final response =
        await _dio.get(ApiConstants.rewardHistory, queryParameters: params);
    final data = response.data;

    // Handle both paginated response {data: [...]} and direct array [...]
    List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      items = data['data'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    return items
        .map((item) =>
            RewardTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RewardRules> getRewardRules() async {
    final response = await _dio.get(ApiConstants.rewardRules);
    return RewardRules.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReferralInfo> getReferralInfo() async {
    final response = await _dio.get(ApiConstants.rewardReferral);
    return ReferralInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> redeemPoints(int points) async {
    await _dio.post(ApiConstants.rewardRedeem, data: {'points': points});
  }
}
