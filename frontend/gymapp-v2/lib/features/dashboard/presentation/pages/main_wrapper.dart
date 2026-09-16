import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/offline_banner.dart';
import 'package:gymapp_v2/core/widgets/sync_on_resume.dart';
import 'package:gymapp_v2/core/widgets/unsynced_banner.dart';
import 'package:gymapp_v2/features/dashboard/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:gymapp_v2/features/dashboard/presentation/pages/coach_dashboard_page.dart';
import 'package:gymapp_v2/features/dashboard/presentation/pages/client_dashboard_page.dart';
import 'package:gymapp_v2/features/social/presentation/pages/conversation_list_page.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import '../../../../features/auth/data/models/user_role.dart';
import '../../../../features/profile/presentation/pages/profile_settings_page.dart';
import '../../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../../features/profile/presentation/bloc/profile_event.dart';

import 'package:gymapp_v2/features/social/presentation/pages/coach_my_clients_page.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart' as social_chat;
import 'package:gymapp_v2/features/dashboard/presentation/pages/platform_hub_page.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/pages/discovery_page.dart';
import 'package:gymapp_v2/core/widgets/tab_fade_stack.dart' show TabFadeStack;

class MainWrapper extends StatelessWidget {
  final UserRole role;
  final int userId;
  final String? accessToken;
  final NavigationCubit navigationCubit;

  const MainWrapper({
    super.key,
    required this.role,
    required this.userId,
    this.accessToken,
    required this.navigationCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NavigationCubit>.value(
      value: navigationCubit,
      child: MainWrapperView(
        role: role,
        userId: userId,
      ),
    );
  }
}

class MainWrapperView extends StatefulWidget {
  final UserRole role;
  final int userId;

  const MainWrapperView({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<MainWrapperView> createState() => _MainWrapperViewState();
}

class _MainWrapperViewState extends State<MainWrapperView> {
  late final List<Widget> _pages;
  DateTime? _lastBackPressAt;

  @override
  void initState() {
    super.initState();

    context.read<ProfileBloc>().add(
      FetchProfile(isCoach: widget.role == UserRole.COACH),
    );

    _pages = [
      widget.role == UserRole.COACH
          ? const CoachDashboardPage()
          : const ClientDashboardPage(),
      BlocProvider<DiscoveryCubit>(
        create: (_) => sl<DiscoveryCubit>(),
        child: DiscoveryPage(currentUserId: widget.userId),
      ),
      ConversationListPage(currentUserId: widget.userId),
      widget.role == UserRole.COACH
          ? CoachMyClientsPage(userId: widget.userId)
          : PlatformHubPage(role: widget.role),
      ProfileSettingsPage(role: widget.role, userId: widget.userId),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ActiveWorkoutState workoutState = context.read<ActiveWorkoutBloc>().state;
      if (workoutState.workoutDay == null) return;
      if (workoutState.status == ActiveWorkoutStatus.finished) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tamamlanmamış antrenman: ${workoutState.workoutDay!.name}'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'DEVAM ET',
            textColor: AppColors.primary,
            onPressed: () {
              context.push(
                '/active-workout',
                extra: {
                  'day': workoutState.workoutDay,
                  'trainingBlockId': workoutState.trainingBlockId,
                  'restSeconds': workoutState.sessionRestSeconds,
                },
              );
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, selectedIndex) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            if (selectedIndex != 0) {
              context.read<NavigationCubit>().setPage(0);
              return;
            }
            final DateTime now = DateTime.now();
            if (_lastBackPressAt == null || now.difference(_lastBackPressAt!) > const Duration(seconds: 2)) {
              _lastBackPressAt = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Çıkmak için tekrar geri tuşuna basın'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            SystemNavigator.pop();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SyncOnResume(
              child: Column(
                children: [
                  const OfflineBanner(),
                  const UnsyncedBanner(),
                  Expanded(child: TabFadeStack(index: selectedIndex, children: _pages)),
                ],
              ),
            ),
            bottomNavigationBar: _buildModernNavBar(context, selectedIndex),
          ),
        );
      },
    );
  }

  Widget _buildModernNavBar(BuildContext context, int selectedIndex) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: BlocBuilder<social_chat.ChatBloc, social_chat.ChatState>(
          builder: (context, chatState) {
            final totalUnread = chatState.totalUnreadCount;

            return BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => context.read<NavigationCubit>().setPage(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                _navItem(
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'Panel',
                ),
                _navItem(
                  Icons.explore_rounded,
                  Icons.explore_outlined,
                  'Keşfet',
                ),
                _navItem(
                  Icons.chat_bubble_rounded,
                  Icons.chat_bubble_outline_rounded,
                  'Mesaj',
                  badgeCount: totalUnread,
                ),
                widget.role == UserRole.COACH
                    ? _navItem(
                        Icons.people_rounded,
                        Icons.people_outline_rounded,
                        'Öğrenciler',
                      )
                    : _navItem(
                        Icons.grid_view_rounded,
                        Icons.grid_view_outlined,
                        'Platform',
                      ),
                _navItem(
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profil',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
    IconData active,
    IconData inactive,
    String label, {
    int badgeCount = 0,
  }) {
    final String badgeText = badgeCount > 99 ? '99+' : '$badgeCount';
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: badgeCount > 0
            ? Badge(
                label: Text(badgeText),
                backgroundColor: AppColors.primary,
                textColor: Colors.black,
                child: Icon(inactive, size: 24),
              )
            : Icon(inactive, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: badgeCount > 0
            ? Badge(
                label: Text(badgeText),
                backgroundColor: AppColors.primary,
                textColor: Colors.black,
                child: Icon(active, size: 24),
              )
            : Icon(active, size: 24),
      ),
      label: label,
    );
  }
}


