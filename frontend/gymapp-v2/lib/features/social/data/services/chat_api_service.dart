import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/api_error_handler.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatApiService with ApiErrorHandler {
  final DioClient _dioClient;

  ChatApiService(this._dioClient);

  // Sohbet listesini getirir
  Future<ApiResponse<List<ConversationModel>>> getMyConversations({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/social/chat/conversations',
        queryParameters: {'page': page, 'size': size},
      );
      return ApiResponse<List<ConversationModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          final pageData = json as Map<String, dynamic>;
          final content = pageData['content'] as List;
          return content
              .map(
                (i) => ConversationModel.fromJson(i as Map<String, dynamic>),
              )
              .toList();
        },
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Bir sohbetteki mesajları getirir
  Future<ApiResponse<List<MessageModel>>> getMessages(
    int conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/social/chat/messages/$conversationId',
        queryParameters: {'page': page, 'size': size},
      );
      return ApiResponse<List<MessageModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          final pageData = json as Map<String, dynamic>;
          final content = pageData['content'] as List;
          return content
              .map((i) => MessageModel.fromJson(i as Map<String, dynamic>))
              .toList();
        },
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Yeni bir sohbet başlatır
  Future<ApiResponse<ConversationModel>> initiateConversation(
    int targetUserId,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/social/chat/initiate/$targetUserId',
      );
      return ApiResponse<ConversationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ConversationModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Mesaj gönderir
  Future<ApiResponse<MessageModel>> sendMessage(
    int conversationId,
    String? content,
    String? attachmentUrl,
    int? packageId,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/social/chat/send',
        data: {
          'conversationId': conversationId,
          'content': content,
          'attachmentUrl': attachmentUrl,
          if (packageId != null) 'packageId': packageId,
        },
      );
      return ApiResponse<MessageModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MessageModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Okundu bilgisi
  Future<ApiResponse<void>> markAsRead(int conversationId) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/social/chat/read/$conversationId',
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (json) {});
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Kullanıcı engeller
  Future<ApiResponse<void>> blockUser(int targetUserId) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/social/chat/block/$targetUserId',
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (json) {});
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Engeli kaldırır
  Future<ApiResponse<void>> unblockUser(int targetUserId) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/social/chat/block/$targetUserId',
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (json) {});
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  // Engelleme durumunu getirir
  Future<ApiResponse<Map<String, dynamic>>> getBlockStatus(int otherUserId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/social/chat/block-status/$otherUserId',
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
