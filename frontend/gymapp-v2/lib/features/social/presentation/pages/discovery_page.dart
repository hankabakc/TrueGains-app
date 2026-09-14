import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_state.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/discovery_search_bar.dart';
import 'package:gymapp_v2/features/social/data/models/coach_specialization.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/discovery_user_card.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/discovery_loading_skeleton.dart';

class DiscoveryPage extends StatefulWidget {
  final int currentUserId;
  const DiscoveryPage({super.key, required this.currentUserId});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final ScrollController _coachScrollController = ScrollController();
  final ScrollController _clientScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late DiscoveryCubit _cubit;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<DiscoveryCubit>();

    final authState = context.read<AuthBloc>().state;
    final bool isCoach = authState is AuthAuthenticated && authState.auth.role == UserRole.COACH;

    _cubit.loadUsers(role: UserRole.COACH);
    if (isCoach) {
      _cubit.loadUsers(role: UserRole.CLIENT);
    }

    _coachScrollController.addListener(() => _scrollListener(UserRole.COACH, _coachScrollController));
    _clientScrollController.addListener(() => _scrollListener(UserRole.CLIENT, _clientScrollController));
  }

  @override
  void dispose() {
    _coachScrollController.dispose();
    _clientScrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener(UserRole role, ScrollController controller) {
    if (controller.position.pixels >= controller.position.maxScrollExtent * 0.9) {
      final bool isCoach = role == UserRole.COACH;
      final bool isLastPage = isCoach ? _cubit.state.isCoachLastPage : _cubit.state.isClientLastPage;

      if (_cubit.state.status != DiscoveryStatus.loadingMore && !isLastPage) {
        _cubit.loadUsers(role: role, nextPage: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _cubit.updateSearchFilters(
        searchQuery: query,
        specialization: _cubit.state.selectedSpecialization,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final bool isCoach = authState is AuthAuthenticated && authState.auth.role == UserRole.COACH;

    Widget buildSearchAndFilters(UserRole role) {
      final searchBar = DiscoverySearchBar(
        controller: _searchController,
        hintText: role == UserRole.COACH ? 'Antrenör ismi ara...' : 'Sporcu ismi ara...',
        onChanged: _onSearchChanged,
        onClear: () {
          _searchController.clear();
          _cubit.updateSearchFilters(
            searchQuery: '',
            specialization: _cubit.state.selectedSpecialization,
          );
        },
      );

      const padding = EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      );

      if (role != UserRole.COACH) {
        return Padding(padding: padding, child: searchBar);
      }

      // Uzmanlık şeridi + sıralama çipi + filtre çipi üçü birden tek panele
      // taşındı. Üst kabuk artık tek satır; aktif filtre yoksa hiç yer kaplamıyor.
      return Padding(
        padding: padding,
        child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
          builder: (context, state) {
            final chips = _activeFilterChips(state);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: searchBar),
                    const SizedBox(width: AppSpacing.sm),
                    _filterButton(context, state, chips.length),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: chips,
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    final content = MultiBlocListener(
      listeners: [
        BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatInitiated) {
              final chatBloc = context.read<ChatBloc>();
              context
                  .push(
                    '/chat',
                    extra: <String, dynamic>{
                      'conversation': state.conversation,
                      'currentUserId': widget.currentUserId,
                    },
                  )
                  .then((_) {
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
        ),
        BlocListener<DiscoveryCubit, DiscoveryState>(
          listenWhen: (previous, current) => previous.selectedUserProfile != current.selectedUserProfile,
          listener: (context, state) {
            if (state.selectedUserProfile != null) {
              context.push('/profile/detail', extra: state.selectedUserProfile);
              _cubit.clearSelectedUserProfile();
            }
          },
        ),
      ],
      child: isCoach
          ? TabBarView(
              children: [
                Column(
                  children: [
                    buildSearchAndFilters(UserRole.COACH),
                    Expanded(child: _buildUserList(UserRole.COACH, _coachScrollController)),
                  ],
                ),
                Column(
                  children: [
                    buildSearchAndFilters(UserRole.CLIENT),
                    Expanded(child: _buildUserList(UserRole.CLIENT, _clientScrollController)),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                buildSearchAndFilters(UserRole.COACH),
                Expanded(child: _buildUserList(UserRole.COACH, _coachScrollController)),
              ],
            ),
    );

    final appBar = AppBar(
      title: Text(
        'Keşfet',
        style: AppTextStyles.pageTitle,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => context.pop(),
      ),
      bottom: isCoach
          ? TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Antrenörler'),
                Tab(text: 'Sporcular'),
              ],
            )
          : null,
    );

    if (isCoach) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: appBar,
          body: content,
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: content,
      );
    }
  }

  Widget _buildUserList(UserRole role, ScrollController controller) {
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      builder: (context, state) {
        final users = role == UserRole.COACH ? state.coaches : state.clients;
        final isLastPage = role == UserRole.COACH ? state.isCoachLastPage : state.isClientLastPage;

        if (state.status == DiscoveryStatus.loading && users.isEmpty) {
          return const DiscoveryLoadingSkeleton();
        }

        if (state.status == DiscoveryStatus.failure && users.isEmpty) {
          return Center(
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
                  state.error ?? 'Hata oluştu',
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => _cubit.loadUsers(role: role),
                  child: const Text(
                    'Tekrar Dene',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }

        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.explore_rounded,
            title: 'Kullanıcı bulunamadı',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _cubit.loadUsers(role: role),
          color: AppColors.primary,
          backgroundColor: AppColors.background,
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: users.length + (isLastPage ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == users.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final user = users[index];
              return DiscoveryUserCard(
                user: user,
                onViewProfile: () {
                  if (user.role == UserRole.COACH) {
                    context.push(
                      Uri(
                        path: '/coach-profile/${user.userId}',
                        queryParameters: {'name': user.fullName ?? 'Antrenör'},
                      ).toString(),
                    );
                  } else {
                    context.read<DiscoveryCubit>().fetchUserProfile(user.userId);
                  }
                },
                onSendMessage: () {
                  context.read<ChatBloc>().add(
                        ChatInitiationRequested(user.userId),
                      );
                },
              );
            },
          ),
        );
      },
    );
  }

  static const String _defaultSort = 'rating';

  static const Map<String, String> _sortOptions = {
    'rating': 'Puana Göre',
    'newest': 'En Yeni',
  };

  String _getSortLabel(String option) =>
      _sortOptions[option] ?? _sortOptions[_defaultSort]!;

  /// Filtre düğmesi. 48x48 dokunma hedefi, aktif filtre sayısını rozetle gösterir.
  Widget _filterButton(BuildContext context, DiscoveryState state, int activeCount) {
    final bool isActive = activeCount > 0;

    return Badge(
      isLabelVisible: isActive,
      label: Text('$activeCount'),
      backgroundColor: AppColors.primary,
      textColor: AppColors.background,
      child: IconButton(
        onPressed: () => _showFilterSheet(context, state),
        tooltip: 'Filtrele',
        icon: Icon(
          Icons.tune_rounded,
          size: 20,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        style: IconButton.styleFrom(
          backgroundColor:
              isActive ? AppColors.primary.withValues(alpha: 0.14) : AppColors.glassWhite,
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  /// Yalnızca AÇIK olan filtreler gösterilir; her biri tek dokunuşla kaldırılır.
  List<Widget> _activeFilterChips(DiscoveryState state) {
    final chips = <Widget>[];
    final spec = state.selectedSpecialization;

    if (spec != null && spec != CoachSpecialization.all) {
      chips.add(_removableChip(
        spec.label,
        () => _cubit.updateSearchFilters(
          specialization: CoachSpecialization.all,
          searchQuery: _searchController.text,
        ),
      ));
    }
    if (state.minRating != null) {
      chips.add(_removableChip(
        '${state.minRating!.toStringAsFixed(1)}+ puan',
        () => _cubit.updateCoachSortFilter(clearMinRating: true),
      ));
    }
    if (state.sortOption != _defaultSort) {
      chips.add(_removableChip(
        _getSortLabel(state.sortOption),
        () => _cubit.updateCoachSortFilter(sort: _defaultSort),
      ));
    }
    return chips;
  }

  Widget _removableChip(String label, VoidCallback onRemove) {
    return InputChip(
      key: Key('discovery_active_filter_$label'),
      label: Text(
        label,
        style: AppTextStyles.tagText.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
      deleteButtonTooltipMessage: '$label filtresini kaldır',
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Uzmanlık + sıralama + minimum puan TEK panelde. Başparmakla ulaşılan
  /// yerden açılıyor; önceki kayan çip şeridi ekranın tepesinde kalıyordu.
  void _showFilterSheet(BuildContext context, DiscoveryState state) {
    CoachSpecialization selectedSpec =
        state.selectedSpecialization ?? CoachSpecialization.all;
    String selectedSort = state.sortOption;
    double? selectedRating = state.minRating;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget section(String title, List<Widget> children) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardLabel.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: children,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            }

            Widget choice(String label, bool isSelected, VoidCallback onTap) {
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: AppTextStyles.tagText.copyWith(
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.glassWhite,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                onSelected: (val) {
                  if (val) onTap();
                },
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
                ),
                child: GlassContainer(
                  borderRadius: AppRadius.xl,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filtrele', style: AppTextStyles.listTitle.copyWith(fontSize: 18)),
                          TextButton(
                            onPressed: () {
                              _cubit.updateCoachSortFilter(clearFilters: true);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Temizle', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              section(
                                'Uzmanlık',
                                CoachSpecialization.values.map((spec) {
                                  return choice(
                                    spec.label,
                                    selectedSpec == spec,
                                    () => setSheetState(() => selectedSpec = spec),
                                  );
                                }).toList(),
                              ),
                              section(
                                'Sıralama',
                                _sortOptions.entries.map((entry) {
                                  return choice(
                                    entry.value,
                                    selectedSort == entry.key,
                                    () => setSheetState(() => selectedSort = entry.key),
                                  );
                                }).toList(),
                              ),
                              section(
                                'Minimum Puan',
                                <double?>[null, 3.0, 4.0, 4.5].map((rating) {
                                  return choice(
                                    rating == null ? 'Hepsi' : '$rating+',
                                    selectedRating == rating,
                                    () => setSheetState(() => selectedRating = rating),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            _cubit.updateCoachSortFilter(
                              sort: selectedSort,
                              minRating: selectedRating,
                              clearMinRating: selectedRating == null,
                              specialization: selectedSpec,
                            );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Text(
                            'Uygula',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
