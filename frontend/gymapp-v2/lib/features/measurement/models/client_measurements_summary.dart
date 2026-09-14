import 'shared_measurement.dart';

/// Antrenörün görüntülediği, öğrenci bazlı gruplandırılmış ölçüm özeti modeli.
class ClientMeasurementsSummary {
  final int clientId;
  final String clientName;
  final List<SharedMeasurement> measurements;

  ClientMeasurementsSummary({
    required this.clientId,
    required this.clientName,
    required this.measurements,
  });

  factory ClientMeasurementsSummary.fromJson(Map<String, dynamic> json) {
    return ClientMeasurementsSummary(
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      measurements:
          (json['measurements'] as List<dynamic>)
              .map((m) => SharedMeasurement.fromJson(m as Map<String, dynamic>))
              .toList(),
    );
  }
}
