import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/measurements_page.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_state.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/shared_measurements/shared_measurements_event.dart';

class SharedMeasurementsPage extends StatelessWidget {
  final SharedMeasurementsBloc? bloc;
  const SharedMeasurementsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => (bloc ?? sl<SharedMeasurementsBloc>())..add(LoadSharedMeasurements()),
      child: const SharedMeasurementsView(),
    );
  }
}

class SharedMeasurementsView extends StatelessWidget {
  const SharedMeasurementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.sharedMeasurements,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      body: BlocBuilder<SharedMeasurementsBloc, SharedMeasurementsState>(
        builder: (context, state) {
          if (state is SharedMeasurementsLoading) {
            return const ListSkeleton();
          } else if (state is SharedMeasurementsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: AppColors.error)));
          } else if (state is SharedMeasurementsLoaded) {
            if (state.summaries.isEmpty) {
              return const EmptyState(
                icon: Icons.straighten_rounded,
                title: AppStrings.noSharedMeasurements,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<SharedMeasurementsBloc>().add(LoadSharedMeasurements()),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: state.summaries.length,
                itemBuilder: (context, index) {
                  final summary = state.summaries[index];
                  final clientName = summary.clientName;

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider<MeasurementBloc>(
                            create: (context) => sl<MeasurementBloc>()
                              ..add(LoadMeasurements(clientId: summary.clientId)),
                            child: MeasurementsPage(targetClientId: summary.clientId),
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(clientName[0], style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${summary.measurements.length} ${AppStrings.measurementsShared}', style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
