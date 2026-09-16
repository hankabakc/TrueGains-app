import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/chat_avatar.dart';
import 'package:gymapp_v2/core/widgets/chat_loading_skeleton.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import '../bloc/chat_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/message_status_icon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';

const double _kBubbleMaxWidthRatio = 0.75;
const double _kImagePlaceholderHeight = 200.0;
const double _kSendButtonPadding = 12.0;
const double _kInlineSpinnerSize = 20.0;
const double _kSendIconSize = 20.0;

class ChatDetailPage extends StatefulWidget {
  final ConversationModel conversation;
  final int currentUserId;
  final SubscriptionPackageModel? stagedPackage;

  const ChatDetailPage({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.stagedPackage,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  SubscriptionPackageModel? _stagedPackage;
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;
  bool _isPickingImage = false;
  bool _isFirstLoad = true;
  bool _blockedByMe = false;
  bool _blockBusy = false;

  int get _otherUserId => widget.currentUserId == widget.conversation.coachId
      ? widget.conversation.clientId
      : widget.conversation.coachId;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(
      MessagesRequested(widget.conversation.id, widget.currentUserId),
    );
    _loadBlockStatus();
    _stagedPackage = widget.stagedPackage;
  }

  @override
  void dispose() {
    _chatBloc.add(ResetChatState());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Post-frame callback dispose'dan sonra çalışabilir; disposed controller'a
    // erişip "null check operator used on a null value" hatası vermesini engelle.
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: AppDurations.scroll,
        curve: Curves.easeOut,
      );
    }
  }

  /// Engelleme durumunu yükler.
  ///
  /// Hata sessizce yutulursa `_blockedByMe` `false` kalır ve arayüz "engellememişsin"
  /// gibi davranır: gönderimi durduran uyarı çıkmaz, kullanıcı mesajının gittiğini sanır.
  /// Sunucu teslimi yine engeller, yani veri sızmaz — yanlış olan kullanıcıya gösterilen
  /// durumdur. Bu yüzden başarısızlık görünür kılınıyor.
  Future<void> _loadBlockStatus() async {
    try {
      final repository = sl<ChatRepository>();
      final result = await repository.getBlockStatus(_otherUserId);
      if (!mounted) return;

      if (result.success && result.data != null) {
        setState(() {
          _blockedByMe = result.data!['blockedByMe'] == true;
        });
      } else {
        _warnBlockStatusUnknown();
      }
    } catch (_) {
      if (mounted) _warnBlockStatusUnknown();
    }
  }

  void _warnBlockStatusUnknown() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Engelleme durumu alınamadı. Bu sohbette engel varsa mesajın iletilmeyebilir.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Future<void> _confirmBlock() async {
    final bool? shouldBlock = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Kullanıcıyı Engelle'),
        content: const Text(
          'Bu kişiyi engellemek istediğinize emin misiniz? Engellediğinizde bu kişinin mesajları size ulaşmaz ve siz de ona mesaj gönderemezsiniz. Engeli istediğiniz zaman açabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (shouldBlock == true) {
      _block();
    }
  }

  Future<void> _block() async {
    if (_blockBusy) return;
    setState(() => _blockBusy = true);
    try {
      final repository = sl<ChatRepository>();
      final result = await repository.blockUser(_otherUserId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _blockedByMe = true;
          _blockBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı engellendi.')),
        );
      } else {
        setState(() => _blockBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _blockBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _unblock() async {
    if (_blockBusy) return;
    setState(() => _blockBusy = true);
    try {
      final repository = sl<ChatRepository>();
      final result = await repository.unblockUser(_otherUserId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _blockedByMe = false;
          _blockBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Engel kaldırıldı.')),
        );
      } else {
        setState(() => _blockBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _blockBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openOtherProfile() {
    final bool isCurrentUserCoach = widget.currentUserId == widget.conversation.coachId;
    if (isCurrentUserCoach) {
      context.push(
        '/client-360/${widget.conversation.clientId}',
        extra: {'studentName': widget.conversation.clientFullName},
      );
    } else {
      context.push(
        Uri(
          path: '/coach-profile/${widget.conversation.coachId}',
          queryParameters: {'name': widget.conversation.coachFullName},
        ).toString(),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_blockedByMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Engelleme nedeniyle mesaj gönderilemez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final int sizeInBytes = await file.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dosya boyutu 5MB\'dan büyük olamaz.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        _chatBloc.add(const FileUploadStatusChanged(true));
        final result = await sl<ChatRepository>()
            .uploadFile(image.path, image.name);
        if (mounted) {
          _chatBloc.add(const FileUploadStatusChanged(false));
        }

        if (result.success && result.data != null && mounted) {
          _chatBloc.add(
            MessageSubmitted(
              conversationId: widget.conversation.id,
              attachmentUrl: result.data!['url'] as String?,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showImageFullScreen(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.currentUserId == widget.conversation.coachId
        ? widget.conversation.clientFullName
        : widget.conversation.coachFullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _openOtherProfile,
          child: Row(
            children: [
              const ChatAvatar(radius: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.listTitle.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_blockedByMe)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (value) {
                if (value == 'block') {
                  _confirmBlock();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Text(
                    'Engelle',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.glassBorder,
                width: 1,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessagesLoaded && state.sendError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.sendError!),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                if (state is MessagesLoaded) {
                  if (_isFirstLoad) {
                    _isFirstLoad = false;
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) {
                        if (mounted) _scrollToBottom();
                      },
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state is MessagesLoaded && state.messages.isNotEmpty) {
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(state.messages[state.messages.length - 1 - index]),
                  );
                } else if (state is MessagesLoaded && state.messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Hemen sohbete başla!',
                  );
                } else if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        state.message,
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const ChatLoadingSkeleton();
              },
            ),
          ),
          if (_blockedByMe)
            _buildBlockedBanner()
          else
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final bool isMe = message.senderId == widget.currentUserId;
    final timeStr =
        '${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderRadius: AppRadius.md,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _kBubbleMaxWidthRatio,
        ),
        color: isMe ? AppColors.chatBubbleMine : AppColors.chatBubbleTheirs,
        border: isMe
            ? Border.all(color: AppColors.chatBubbleMineBorder)
            : Border.all(color: AppColors.glassBorder),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.packageId != null)
              GestureDetector(
                onTap: () {
                  context.push(
                    Uri(
                      path: '/coach-profile/${widget.conversation.coachId}',
                      queryParameters: {'name': widget.conversation.coachFullName},
                    ).toString(),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_membership_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.packageName ?? '',
                              style: AppTextStyles.bodyText.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${(message.packagePrice ?? 0).toStringAsFixed(0)} ₺',
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        'İncele >',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (message.attachmentUrl != null &&
                message.attachmentUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _showImageFullScreen(
                  AppConfig.resolveFileUrl(message.attachmentUrl!),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: AppConfig.resolveFileUrl(message.attachmentUrl!),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: _kImagePlaceholderHeight,
                        color: AppColors.glassWhite,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: AppTextStyles.bubbleText,
              ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: AppTextStyles.timestamp,
                ),
                if (isMe) const SizedBox(width: AppSpacing.xxs),
                if (isMe) MessageStatusIcon(message: message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final bool isUploading = state is MessagesLoaded && state.isUploading;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_stagedPackage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_membership_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stagedPackage!.name,
                            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_stagedPackage!.price.toStringAsFixed(0)} ₺',
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _stagedPackage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            GlassContainer(
              margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              borderRadius: AppRadius.pill,
              shadow: AppElevation.cardShadow,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Fotoğraf ekle',
                    onPressed: isUploading ? null : _pickAndUploadImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      ),
                      onSubmitted: (_) => isUploading ? null : _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (isUploading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: SizedBox(
                        width: _kInlineSpinnerSize,
                        height: _kInlineSpinnerSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Gönder',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _sendMessage,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(_kSendButtonPadding),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppElevation.softGlow(AppColors.primary),
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: _kSendIconSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockedBanner() {
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      borderRadius: AppRadius.md,
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bu kişiyi engellediniz. Mesaj göndermek için engeli açın.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _blockBusy ? null : _unblock,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Engeli Aç'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_blockedByMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Engelleme nedeniyle mesaj gönderilemez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final content = _messageController.text.trim();
    if (content.isNotEmpty || _stagedPackage != null) {
      _chatBloc.add(
        MessageSubmitted(
          conversationId: widget.conversation.id,
          content: content.isEmpty ? null : content,
          packageId: _stagedPackage?.id,
        ),
      );
      _messageController.clear();
      if (_stagedPackage != null) {
        setState(() {
          _stagedPackage = null;
        });
      }
    }
  }
}
