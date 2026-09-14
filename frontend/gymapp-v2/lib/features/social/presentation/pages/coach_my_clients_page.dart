import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/social_bloc.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_state.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_event.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class CoachMyClientsPage extends StatelessWidget {
  final int? userId;

  const CoachMyClientsPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    int finalUserId = 0;
    if (userId != null) {
      finalUserId = userId!;
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        finalUserId = authState.auth.id;
      }
    }

    return BlocProvider<SharedMeasurementsBloc>(
      create: (context) => sl<SharedMeasurementsBloc>()..add(LoadSharedMeasurements()),
      child: _CoachMyClientsView(userId: finalUserId),
    );
  }
}

class _CoachMyClientsView extends StatefulWidget {
  final int userId;
  const _CoachMyClientsView({required this.userId});

  @override
  State<_CoachMyClientsView> createState() => _CoachMyClientsViewState();
}

class _CoachMyClientsViewState extends State<_CoachMyClientsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SocialBloc>().add(LoadMyClientsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Öğrenci adı veya soyadı ile ara...',
          hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted.withValues(alpha: 0.6)),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.textMuted),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.textPrimary.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Öğrencilerim',
          style: AppTextStyles.pageTitle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatInitiated) {
            final chatBloc = context.read<ChatBloc>();
            context.push(
              '/chat',
              extra: <String, dynamic>{
                'conversation': state.conversation,
                'currentUserId': widget.userId,
              },
            ).then((_) {
              chatBloc.add(ResetChatState());
            });
          } else if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionsBar(context, widget.userId),
                _buildSearchBar(),
                Expanded(
                  child: BlocBuilder<SocialBloc, SocialState>(
                builder: (context, socialState) {
                  if (socialState is SocialLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (socialState is SocialClientsLoaded) {
                    final query = _searchController.text.toLowerCase().trim();
                    final filteredClients = socialState.clients.where((client) {
                      final fullName = (client.fullName ?? '').toLowerCase();
                      return fullName.contains(query);
                    }).toList();

                    if (filteredClients.isEmpty) {
                      if (query.isNotEmpty) {
                        return Center(
                          child: Text(
                            'Aramanızla eşleşen öğrenci bulunamadı.',
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return _buildEmptyState();
                    }

                    return BlocBuilder<SharedMeasurementsBloc, SharedMeasurementsState>(
                      builder: (context, sharedState) {
                        return ListView.builder(
                          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg, top: AppSpacing.sm),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = filteredClients[index];
                            ClientMeasurementsSummary? summary;
                            if (sharedState is SharedMeasurementsLoaded) {
                              try {
                                summary = sharedState.summaries.firstWhere(
                                  (s) => s.clientId == client.userId,
                                );
                              } catch (_) {
                                summary = null;
                              }
                            }
                            return _buildClientCard(context, client, summary);
                          },
                        );
                      },
                    );
                  }

                  if (socialState is SocialError) {
                    return Center(child: Text(socialState.message, style: AppTextStyles.bodyText.copyWith(color: AppColors.error)));
                  }

                  return const SizedBox();
                },
              ),
            ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context, int currentUserId) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildActionButton(
              context,
              Icons.explore_rounded,
              'Keşfet',
              AppColors.primary,
              () => context.push('/discovery', extra: currentUserId),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionButton(
              context,
              Icons.menu_book_rounded,
              'Kütüphane',
              AppColors.primary,
              () => context.push('/exercises'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionButton(
              context,
              Icons.local_drink_rounded,
              'Tüm Sular',
              AppColors.primary,
              () => context.push('/coach-water-tracking'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildActionButton(
              context,
              Icons.straighten_rounded,
              'Tüm Ölçümler',
              AppColors.primary,
              () => context.push('/shared-measurements'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return PressableScale(
      onTap: onTap,
      child: GlassContainer(
        elevated: true,
        border: Border.all(color: color.withValues(alpha: 0.15)),
        shadow: AppElevation.softGlow(color),
        borderRadius: AppRadius.md,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz aktif öğrenciniz yok.',
            style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Abonelik sistemi üzerinden öğrencilerinizle bağlanabilirsiniz.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: PremiumButton(
              text: 'SPORCU KEŞFET',
              onPressed: () => context.push('/discovery', extra: widget.userId),
              height: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, DiscoveryUserModel client, ClientMeasurementsSummary? summary) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/client-360/${client.userId}',
          extra: {
            'studentName': client.fullName ?? 'İsimsiz Sporcu',
            'measurementSummary': summary,
          },
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        elevated: true,
        border: Border.all(color: AppColors.glassBorder),
        shadow: AppElevation.cardShadow,
        child: Row(
          children: [
            NetworkAvatar(
              imageUrl: client.profilePhotoUrl,
              fallbackText: client.fullName,
              size: AppSpacing.xxl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName ?? 'İsimsiz Sporcu',
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    client.bio ?? 'Aktif Sporcu',
                    style: AppTextStyles.listSubtitle.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
