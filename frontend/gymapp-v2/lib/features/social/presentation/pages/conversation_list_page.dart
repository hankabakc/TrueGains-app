import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/chat_avatar.dart';
import 'package:gymapp_v2/features/social/data/models/conversation_model.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import '../widgets/conversation_loading_skeleton.dart' show ConversationLoadingSkeleton;

class ConversationListPage extends StatefulWidget {
  final int currentUserId;
  const ConversationListPage({super.key, required this.currentUserId});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ConversationsRequested());
    context.read<ChatBloc>().add(
          GlobalConversationSubscriptionRequested(widget.currentUserId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mesajlar',
          style: AppTextStyles.pageTitle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          List<ConversationModel> conversations = [];

          if (state is ConversationsLoaded) {
            conversations = state.conversations;
          } else if (state is MessagesLoaded) {
            conversations = state.conversations;
          }

          if (state is ChatLoading && conversations.isEmpty) {
            return const ConversationLoadingSkeleton();
          }

          if (conversations.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ChatBloc>().add(ConversationsRequested()),
              color: AppColors.primary,
              backgroundColor: AppColors.background,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: conversations.length,
                itemBuilder: (ctx, index) =>
                    _buildConversationCard(ctx, conversations[index]),
              ),
            );
          }

          if (state is ChatError && conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.read<ChatBloc>().add(
                            ConversationsRequested(),
                          ),
                      child: const Text(
                        'Tekrar Dene',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ChatInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ChatBloc>().add(ConversationsRequested());
              }
            });
          }

          if (conversations.isEmpty && state is! ChatLoading) {
            return _buildEmptyState();
          }

          return const ConversationLoadingSkeleton();
        },
      ),
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    ConversationModel conversation,
  ) {
    // Diğer tarafın ismini belirle
    final otherPartyName = widget.currentUserId == conversation.coachId
        ? conversation.clientFullName
        : conversation.coachFullName;
    final timeStr = conversation.lastMessageAt != null
        ? '${conversation.lastMessageAt!.hour}:${conversation.lastMessageAt!.minute.toString().padLeft(2, '0')}'
        : '';

    final hasUnread = conversation.unreadCount > 0;

    return PressableScale(
      onTap: () {
        context.push(
          '/chat',
          extra: {
            'conversation': conversation,
            'currentUserId': widget.currentUserId,
          },
        );
      },
      child: GlassContainer(
        elevated: true,
        shadow: AppElevation.cardShadow,
        borderRadius: AppRadius.lg,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ChatAvatar(
                radius: 28,
                unreadCount: conversation.unreadCount,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherPartyName,
                      style: AppTextStyles.listTitle.copyWith(
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      conversation.lastMessagePreview,
                      style: AppTextStyles.listSubtitle.copyWith(
                        color: hasUnread ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.timestamp.copyWith(
                      color: hasUnread ? AppColors.primary : AppColors.textMuted,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlassContainer(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Henüz bir sohbet yok',
                style: AppTextStyles.emptyTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'İletişime geçmek için ilk mesajı at.',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
