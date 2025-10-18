import 'package:demo_bici/models/route_point_data.dart';

class SectorStats {
  final double distanceKm;
  final Duration duration;
  final double avgSpeed;
  final double maxSpeed;
  final double minSpeed;
  final double elevationGain;
  final double elevationLoss;
  final double maxGradient;
  final double avgGradient;
  final double vam; // m/h
  final double theoreticalAvgPower;
  final double theoreticalMaxPower;

  SectorStats({
    required this.distanceKm,
    required this.duration,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.minSpeed,
    required this.elevationGain,
    required this.elevationLoss,
    required this.maxGradient,
    required this.avgGradient,
    required this.vam,
    required this.theoreticalAvgPower,
    required this.theoreticalMaxPower,
  });
}

// 2. FUNCIÓN: calcular métricas del tramo

SectorStats computeSectorStats(List<RoutePointData> points, {double riderMassKg = 75}) {
  if (points.length < 2) throw ArgumentError('Sector must have at least 2 points');

  final double g = 9.81;

  double totalPositive = 0;
  double totalNegative = 0;
  double totalDistance = 0;
  double maxGradient = 0;
  List<double> gradients = [];
  List<double> speeds = [];
  List<double> powerEstimates = [];

  for (int i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];

    if (prev.elevation != null && curr.elevation != null) {
      final elevDiff = curr.elevation! - prev.elevation!;
      final distDiff = (curr.cumulativeDistanceKm - prev.cumulativeDistanceKm) * 1000; // en metros

      if (distDiff > 0) {
        final gradient = (elevDiff / distDiff) * 100;
        gradients.add(gradient);
        if (gradient.abs() > maxGradient) maxGradient = gradient.abs();

        if (elevDiff > 1) totalPositive += elevDiff;
        if (elevDiff < -1) totalNegative += elevDiff.abs();
        totalDistance += distDiff;

        // Potencia teórica instantánea
        final timeDiff = curr.time?.difference(prev.time!).inSeconds ?? 1;
        if (timeDiff > 0 && elevDiff > 0) {
          final power = (riderMassKg * g * elevDiff) / timeDiff;
          powerEstimates.add(power);
        }
      }
    }

    if (curr.speed != null) speeds.add(curr.speed!);
  }

  final startTime = points.first.time;
  final endTime = points.last.time;
  final duration = (startTime != null && endTime != null)
      ? endTime.difference(startTime)
      : Duration.zero;

  final double avgSpeed = totalDistance > 0 && duration.inSeconds > 0
      ? (totalDistance / 1000) / (duration.inSeconds / 3600)
      : 0;

  final double vam = duration.inMinutes > 0
      ? (totalPositive / duration.inMinutes) * 60
      : 0;

  final double avgGradient = gradients.isNotEmpty
      ? gradients.reduce((a, b) => a + b) / gradients.length
      : 0;

  final double theoreticalAvgPower = powerEstimates.isNotEmpty
      ? powerEstimates.reduce((a, b) => a + b) / powerEstimates.length
      : 0;

  final double theoreticalMaxPower = powerEstimates.isNotEmpty
      ? powerEstimates.reduce((a, b) => a > b ? a : b)
      : 0;

  return SectorStats(
    distanceKm: totalDistance / 1000,
    duration: duration,
    avgSpeed: avgSpeed,
    maxSpeed: speeds.isNotEmpty ? speeds.reduce((a, b) => a > b ? a : b) : 0,
    minSpeed: speeds.isNotEmpty ? speeds.reduce((a, b) => a < b ? a : b) : 0,
    elevationGain: totalPositive,
    elevationLoss: totalNegative,
    maxGradient: maxGradient,
    avgGradient: avgGradient,
    vam: vam,
    theoreticalAvgPower: theoreticalAvgPower,
    theoreticalMaxPower: theoreticalMaxPower,
  );
}