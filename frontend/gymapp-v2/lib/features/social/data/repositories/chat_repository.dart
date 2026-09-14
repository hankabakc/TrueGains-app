import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/constants/network_constants.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/message_status.dart';
import '../services/chat_api_service.dart';
import '../services/file_api_service.dart';
import 'package:gymapp_v2/core/network/api_response.dart';

class ChatRepository {
  final ChatApiService _apiService;
  final FileApiService _fileApiService;
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ChatRepository(
    this._apiService,
    this._fileApiService,
    this._networkInfo,
    this._syncManager,
  );

  Future<ApiResponse<List<ConversationModel>>> getMyConversations({
    int page = 0,
    int size = 20,
  }) {
    return _apiService.getMyConversations(page: page, size: size);
  }

  Future<ApiResponse<List<MessageModel>>> getMessages(
    int conversationId, {
    int page = 0,
    int size = 50,
  }) {
    return _apiService.getMessages(conversationId, page: page, size: size);
  }

  Future<ApiResponse<ConversationModel>> initiateConversation(
    int targetUserId,
  ) {
    return _apiService.initiateConversation(targetUserId);
  }

  Future<ApiResponse<MessageModel>> sendMessage(
    int conversationId,
    String? content,
    String? attachmentUrl,
    int? packageId, {
    int? senderId,
  }) async {
    if (await _networkInfo.isConnected) {
      return _apiService.sendMessage(conversationId, content, attachmentUrl, packageId);
    }

    // Kullanıcı gönder'e bastığında giriş kutusu anında temizleniyor; kuyruğa
    // alınmazsa yazdığı metin hiçbir yerde kalmaz.
    await _syncManager.addToQueue('/social/chat/send', {
      'conversationId': conversationId,
      'content': content,
      'attachmentUrl': attachmentUrl,
      if (packageId != null) 'packageId': packageId,
    });

    if (senderId == null) {
      // Kimlik bilinmiyorsa iyimser balon çizilemez; eski davranış korunur.
      return ApiResponse<MessageModel>(
        success: false,
        message: 'Bağlantı yok. Mesaj internet geldiğinde gönderilecek.',
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    // Geçici mesaj: id NEGATİF. Sunucu asla negatif id üretmez, bu yüzden işaret
    // tek başına "henüz gönderilmedi" bilgisini taşır ve MessageStatus enum'ına
    // dokunmak gerekmez.
    final MessageModel pending = MessageModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: senderId,
      senderFullName: '',
      content: content ?? '',
      status: MessageStatus.sent,
      attachmentUrl: attachmentUrl,
      sentAt: DateTime.now(),
      packageId: packageId,
    );

    return ApiResponse<MessageModel>(
      success: true,
      data: pending,
      message: 'Bağlantı yok. Mesaj internet geldiğinde gönderilecek.',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<ApiResponse<void>> markAsRead(int conversationId) {
    return _apiService.markAsRead(conversationId);
  }

  Future<ApiResponse<void>> blockUser(int targetUserId) {
    return _apiService.blockUser(targetUserId);
  }

  Future<ApiResponse<void>> unblockUser(int targetUserId) {
    return _apiService.unblockUser(targetUserId);
  }

  Future<ApiResponse<Map<String, dynamic>>> getBlockStatus(int otherUserId) {
    return _apiService.getBlockStatus(otherUserId);
  }

  Future<ApiResponse<Map<String, dynamic>>> uploadFile(
    String path,
    String name,
  ) {
    return _fileApiService.uploadFile(path, name);
  }

  // --- WebSocket (Stomp) Bölümü ---
  StompClient? _stompClient;
  void Function()? _chatUnsubscribe;
  void Function()? _bulkReadUnsubscribe;
  void Function()? _globalUnsubscribe;
  Future<void>? _connectFuture;

  // Reconnect sonrası abonelikleri yenilemek için callback'ler
  void Function()? _onReconnectGlobalSubscription;
  void Function()? _onReconnectChatSubscription;
  bool _hasConnectedBefore = false;

  Future<void> _ensureConnected(String wsUrl) async {
    if (_stompClient != null && _stompClient!.connected) return;

    if (_connectFuture != null) {
      return _connectFuture;
    }

    final token = await _storage.read(key: StorageKeys.accessToken);

    _connectFuture = _connectInternal(wsUrl, token);
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connectInternal(String wsUrl, String? token) async {
    final completer = Completer<void>();

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        stompConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        webSocketConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        onConnect: (frame) {
          if (!completer.isCompleted) completer.complete();
          if (_hasConnectedBefore) {
            // Reconnect — abonelikleri yeniden kur
            _onReconnectGlobalSubscription?.call();
            _onReconnectChatSubscription?.call();
          }
          _hasConnectedBefore = true;
        },
        onWebSocketError: (error) {
          if (kDebugMode) {
            print('[WebSocket Error] Chat: $error');
          }
          if (!completer.isCompleted) completer.completeError(error.toString());
        },
        onStompError: (frame) {
          if (kDebugMode) {
            print('[Stomp Error] Chat Command: ${frame.command}');
          }
          if (!completer.isCompleted) {
            completer.completeError(frame.body ?? 'Stomp Error');
          }
        },
        onDisconnect: (frame) {
          _connectFuture = null;
          if (kDebugMode) {
            print('[WebSocket Disconnected] Yeniden bağlanma bekleniyor...');
          }
        },
      ),
    );
    _stompClient?.activate();

    // Timeout ekleyelim (opsiyonel ama önerilir)
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      if (!completer.isCompleted) completer.complete();
    });
  }

  Future<void> subscribeToConversation({
    required int conversationId,
    required String wsUrl,
    required void Function(MessageModel) onMessageReceived,
    required void Function(List<int>) onBulkReadReceived,
  }) async {
    _onReconnectChatSubscription = () {
      _chatUnsubscribe?.call();
      _bulkReadUnsubscribe?.call();

      // Ana mesaj dinleyici
      _chatUnsubscribe = _stompClient?.subscribe(
        destination: '/topic/chat/$conversationId',
        callback: (frame) {
          if (frame.body != null) {
            final Map<String, dynamic> data =
                jsonDecode(frame.body!) as Map<String, dynamic>;
            final message = MessageModel.fromJson(data);
            onMessageReceived(message);
          }
        },
      );

      // Toplu okundu dinleyici
      _bulkReadUnsubscribe = _stompClient?.subscribe(
        destination: '/topic/chat/$conversationId/bulk-read',
        callback: (frame) {
          if (frame.body != null) {
            final Map<String, dynamic> data =
                jsonDecode(frame.body!) as Map<String, dynamic>;
            final List<int> messageIds =
                (data['messageIds'] as List).cast<int>();
            onBulkReadReceived(messageIds);
          }
        },
      );
    };

    await _ensureConnected(wsUrl);
    _onReconnectChatSubscription?.call();
  }

  Future<void> subscribeToConversationUpdates({
    required int userId,
    required String wsUrl,
    required void Function(ConversationModel) onConversationUpdated,
  }) async {
    _onReconnectGlobalSubscription = () {
      _globalUnsubscribe?.call();

      _globalUnsubscribe = _stompClient?.subscribe(
        destination: '/topic/user/$userId/conversations',
        callback: (frame) {
          if (frame.body != null) {
            final Map<String, dynamic> data =
                jsonDecode(frame.body!) as Map<String, dynamic>;
            final conversation = ConversationModel.fromJson(data);
            onConversationUpdated(conversation);
          }
        },
      );
    };

    await _ensureConnected(wsUrl);
    _onReconnectGlobalSubscription?.call();
  }

  void unsubscribeFromConversation() {
    _chatUnsubscribe?.call();
    _bulkReadUnsubscribe?.call();
    _chatUnsubscribe = null;
    _bulkReadUnsubscribe = null;
    _onReconnectChatSubscription = null;
  }

  void dispose() {
    _onReconnectGlobalSubscription = null;
    _onReconnectChatSubscription = null;
    _globalUnsubscribe?.call();
    _globalUnsubscribe = null;
    _chatUnsubscribe?.call();
    _chatUnsubscribe = null;
    _bulkReadUnsubscribe?.call();
    _bulkReadUnsubscribe = null;
    _hasConnectedBefore = false;
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
