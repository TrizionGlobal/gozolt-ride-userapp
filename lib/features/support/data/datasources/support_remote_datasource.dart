import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/create_ticket_request.dart';
import '../models/support_ticket.dart';
import '../models/ticket_reply.dart';

class SupportRemoteDatasource {
  final Dio _dio;

  SupportRemoteDatasource(this._dio);

  Future<List<SupportTicket>> getTickets() async {
    final response = await _dio.get(ApiConstants.supportTickets);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicket> getTicketDetail(String ticketId) async {
    final response =
        await _dio.get(ApiConstants.supportTicketById(ticketId));
    return SupportTicket.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SupportTicket> createTicket(CreateTicketRequest request) async {
    final response = await _dio.post(
      ApiConstants.supportTickets,
      data: request.toJson(),
    );
    return SupportTicket.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TicketReply> replyToTicket(String ticketId, String message) async {
    final response = await _dio.post(
      ApiConstants.supportTicketReplies(ticketId),
      data: {'message': message},
    );
    return TicketReply.fromJson(response.data as Map<String, dynamic>);
  }
}
