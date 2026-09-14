import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ChatAvatar extends StatelessWidget {
  final double radius;
  final int unreadCount;

  const ChatAvatar({
    super.key,
    required this.radius,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = unreadCount > 0;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: radius * 1.1,
      ),
    );

    final avatarWithRing = !hasUnread
        ? avatar
        : Container(
            padding: const EdgeInsets.all(2.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: avatar,
          );

    if (!hasUnread) {
      return avatarWithRing;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWithRing,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.unreadIndicator,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTextStyles.timestamp.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
