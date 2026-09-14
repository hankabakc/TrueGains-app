import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gymapp_v2/features/social/data/models/coach_review_model.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_event.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_state.dart' as coach_state;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';

class ReviewsSection extends StatelessWidget {
  final int coachId;
  final bool isSubscribed;

  const ReviewsSection({
    super.key,
    required this.coachId,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoachProfileBloc, coach_state.CoachProfileState>(
      listener: (context, state) {
        if (state is coach_state.CoachReviewSubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Değerlendirmeniz alındı.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<CoachProfileBloc>().add(LoadCoachReviews(coachId));
        } else if (state is coach_state.CoachReviewSubmissionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<CoachProfileBloc, coach_state.CoachProfileState>(
        builder: (context, state) {
          List<CoachReviewModel>? reviews;
          if (state is coach_state.CoachReviewsLoaded) {
            reviews = state.reviews;
          } else if (state is coach_state.CoachProfileLoaded) {
            reviews = state.reviews;
          }

          final activeReviews = reviews;
          if (activeReviews != null) {
            return Column(
              children: [
                if (isSubscribed) _buildReviewButton(context),
                Expanded(
                  child: activeReviews.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz yorum yapılmamış.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                          itemCount: activeReviews.length,
                          itemBuilder: (context, index) {
                            final r = activeReviews[index];
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.clientName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      RatingBarIndicator(
                                        rating: r.rating.toDouble(),
                                        itemCount: 5,
                                        itemSize: 14,
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      if (r.packageName != null && r.packageName!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            r.packageName!,
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      r.comment!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => _showReviewDialog(context),
          icon: const Icon(Icons.rate_review_rounded, color: Colors.black, size: 20),
          label: const Text(
            'ANTRENÖRÜ DEĞERLENDİR',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    // Modal bottom sheet kök overlay bağlamında çizilir; sayfanın CoachProfileBloc
    // sağlayıcısı bu alt ağaçta bulunmaz. Bloc'u yakalayıp BlocProvider.value ile
    // sheet'e yeniden sağlıyoruz (aksi halde ProviderNotFoundException).
    final coachProfileBloc = context.read<CoachProfileBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider<CoachProfileBloc>.value(
          value: coachProfileBloc,
          child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: GlassContainer(
                  borderRadius: 32,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Antrenörünü Değerlendir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Deneyimini yıldızlarla derecelendir ve bir yorum bırak.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      RatingBar.builder(
                        initialRating: 5,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.primary,
                        ),
                        onRatingUpdate: (rating) {
                          setSheetState(() {
                            selectedRating = rating.toInt();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Yorumunuzu buraya yazın (opsiyonel)...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocConsumer<CoachProfileBloc, coach_state.CoachProfileState>(
                        listener: (blocCtx, state) {
                          if (state is coach_state.CoachReviewSubmissionSuccess) {
                            Navigator.pop(ctx);
                          }
                        },
                        builder: (blocCtx, state) {
                          final isLoading = state is coach_state.CoachReviewSubmissionLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      final comment = commentController.text.trim();
                                      coachProfileBloc.add(
                                            SubmitCoachReview(
                                              coachId: coachId,
                                              rating: selectedRating,
                                              comment: comment.isEmpty ? null : comment,
                                            ),
                                          );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text(
                                      'GÖNDER',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        );
      },
    );
  }
}
