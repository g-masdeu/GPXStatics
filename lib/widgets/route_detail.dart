// lib/widgets/route_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

// Importaciones de modelos (asegúrate de que las rutas sean correctas)
import 'package:demo_bici/models/route.dart';
import 'package:demo_bici/models/sector.dart';
import 'package:demo_bici/models/route_point_data.dart';

// Importación del nuevo widget de selección de puntos en el mapa
import 'package:demo_bici/widgets/select_point_on_map_page.dart';

// Enum y clases de estadísticas... (Mantén el resto de tu código igual hasta _RouteDetailPageState)
enum ChartDataType { elevation, speed, temperature }

class ElevationStats {
  final double totalPositiveElevation;
  final double totalNegativeElevation;
  final double ascentPercentage;
  final double descentPercentage;
  final double flatPercentage;
  final double maxPositiveGradient;
  final double maxNegativeGradient;
  final double avgPositiveGradient;
  final double avgNegativeGradient;
  final double avgAscentRatePerHour;
  final double maxAscentRatePerHour;
  final double avgDescentRatePerHour;
  final double maxDescentRatePerHour;
  final double maxElevation;
  final double minElevation;

  ElevationStats({
    required this.totalPositiveElevation,
    required this.totalNegativeElevation,
    required this.ascentPercentage,
    required this.descentPercentage,
    required this.flatPercentage,
    required this.maxPositiveGradient,
    required this.maxNegativeGradient,
    required this.avgPositiveGradient,
    required this.avgNegativeGradient,
    required this.avgAscentRatePerHour,
    required this.maxAscentRatePerHour,
    required this.avgDescentRatePerHour,
    required this.maxDescentRatePerHour,
    required this.maxElevation,
    required this.minElevation,
  });

  factory ElevationStats.empty() {
    return ElevationStats(
      totalPositiveElevation: 0,
      totalNegativeElevation: 0,
      ascentPercentage: 0,
      descentPercentage: 0,
      flatPercentage: 0,
      maxPositiveGradient: 0,
      maxNegativeGradient: 0,
      avgPositiveGradient: 0,
      avgNegativeGradient: 0,
      avgAscentRatePerHour: 0,
      maxAscentRatePerHour: 0,
      avgDescentRatePerHour: 0,
      maxDescentRatePerHour: 0,
      maxElevation: 0,
      minElevation: 0,
    );
  }
}

class SpeedStats {
  final double maxSpeed;
  final double minSpeed;
  final double avgSpeed;
  final double medianSpeed;
  final double totalMovingTime;
  final double totalStoppedTime;
  final double movingTimePercentage;
  final double maxAcceleration;
  final double maxDeceleration;

  SpeedStats({
    required this.maxSpeed,
    required this.minSpeed,
    required this.avgSpeed,
    required this.medianSpeed,
    required this.totalMovingTime,
    required this.totalStoppedTime,
    required this.movingTimePercentage,
    required this.maxAcceleration,
    required this.maxDeceleration,
  });

  factory SpeedStats.empty() {
    return SpeedStats(
      maxSpeed: 0,
      minSpeed: 0,
      avgSpeed: 0,
      medianSpeed: 0,
      totalMovingTime: 0,
      totalStoppedTime: 0,
      movingTimePercentage: 0,
      maxAcceleration: 0,
      maxDeceleration: 0,
    );
  }
}

class TemperatureStats {
  final double minTemp;
  final double maxTemp;
  final double avgTemp;
  final DateTime? minTempTime;
  final DateTime? maxTempTime;
  final double temperatureRange;

  TemperatureStats({
    required this.minTemp,
    required this.maxTemp,
    required this.avgTemp,
    this.minTempTime,
    this.maxTempTime,
    required this.temperatureRange,
  });

  factory TemperatureStats.empty() {
    return TemperatureStats(
      minTemp: 0,
      maxTemp: 0,
      avgTemp: 0,
      temperatureRange: 0,
    );
  }
}

class RouteStatistics {
  static ElevationStats calculateElevationStats(List<RoutePointData> points) {
    if (points.isEmpty) {
      return ElevationStats.empty();
    }

    double totalPositive = 0;
    double totalNegative = 0;
    double ascentDistance = 0;
    double descentDistance = 0;
    double flatDistance = 0;
    double maxPositiveGradient = 0;
    double maxNegativeGradient = 0;
    List<double> positiveGradients = [];
    List<double> negativeGradients = [];
    List<double> ascentRates = [];
    List<double> descentRates = [];
    double maxElevation = points.first.elevation ?? 0;
    double minElevation = points.first.elevation ?? 0;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      if (prev.elevation != null && curr.elevation != null) {
        final elevDiff = curr.elevation! - prev.elevation!;

        if (curr.elevation! > maxElevation) maxElevation = curr.elevation!;
        if (curr.elevation! < minElevation) minElevation = curr.elevation!;

        if (elevDiff > 0) {
          totalPositive += elevDiff;
        } else if (elevDiff < 0) {
          totalNegative += elevDiff.abs();
        }

        if (prev.time != null && curr.time != null) {
          final timeDiffSeconds = curr.time!.difference(prev.time!).inSeconds;
          if (timeDiffSeconds > 0) {
            final timeDiffHours = timeDiffSeconds / 3600.0;
            if (elevDiff > 0) {
              final ascentRate = elevDiff / timeDiffHours;
              ascentRates.add(ascentRate);
            } else if (elevDiff < 0) {
              final descentRate = elevDiff.abs() / timeDiffHours;
              descentRates.add(descentRate);
            }
          }
        }
      }
    }

    final List<_ElevationSegment> segments = _createElevationSegments(points);
    for (final segment in segments) {
      final gradient = segment.gradient;
      final distance = segment.distance;

      if (gradient > 2) {
        ascentDistance += distance;
        positiveGradients.add(gradient);
        if (gradient > maxPositiveGradient) maxPositiveGradient = gradient;
      } else if (gradient < -2) {
        descentDistance += distance;
        final absGradient = gradient.abs();
        negativeGradients.add(absGradient);
        if (absGradient > maxNegativeGradient) {
          maxNegativeGradient = absGradient;
        }
      } else {
        flatDistance += distance;
      }
    }

    final double totalDistance =
        points.isNotEmpty ? points.last.cumulativeDistanceKm : 0.0;

    final double ascentPercentage =
        totalDistance > 0 ? (ascentDistance / totalDistance) * 100 : 0;
    final double descentPercentage =
        totalDistance > 0 ? (descentDistance / totalDistance) * 100 : 0;
    final double flatPercentage =
        totalDistance > 0 ? (flatDistance / totalDistance) * 100 : 0;

    final double avgPositiveGradient = positiveGradients.isNotEmpty
        ? positiveGradients.reduce((a, b) => a + b) / positiveGradients.length
        : 0;
    final double avgNegativeGradient = negativeGradients.isNotEmpty
        ? negativeGradients.reduce((a, b) => a + b) / negativeGradients.length
        : 0;

    final double avgAscentRate = ascentRates.isNotEmpty
        ? ascentRates.reduce((a, b) => a + b) / ascentRates.length
        : 0;
    final double maxAscentRate = ascentRates.isNotEmpty
        ? ascentRates.reduce((a, b) => a > b ? a : b)
        : 0;

    final double avgDescentRate = descentRates.isNotEmpty
        ? descentRates.reduce((a, b) => a + b) / descentRates.length
        : 0;
    final double maxDescentRate = descentRates.isNotEmpty
        ? descentRates.reduce((a, b) => a > b ? a : b)
        : 0;

    return ElevationStats(
      totalPositiveElevation: totalPositive,
      totalNegativeElevation: totalNegative,
      ascentPercentage: ascentPercentage,
      descentPercentage: descentPercentage,
      flatPercentage: flatPercentage,
      maxPositiveGradient: maxPositiveGradient,
      maxNegativeGradient: maxNegativeGradient,
      avgPositiveGradient: avgPositiveGradient,
      avgNegativeGradient: avgNegativeGradient,
      avgAscentRatePerHour: avgAscentRate,
      maxAscentRatePerHour: maxAscentRate,
      avgDescentRatePerHour: avgDescentRate,
      maxDescentRatePerHour: maxDescentRate,
      maxElevation: maxElevation,
      minElevation: minElevation,
    );
  }

  static List<_ElevationSegment> _createElevationSegments(
    List<RoutePointData> points,
  ) {
    List<_ElevationSegment> segments = [];
    const double segmentLength = 0.05; // 50 metros = 0.05 km

    int startIndex = 0;

    for (int i = 1; i < points.length; i++) {
      final segmentStartPoint = points[startIndex];
      final currentPoint = points[i];

      final segmentDistance =
          currentPoint.cumulativeDistanceKm - segmentStartPoint.cumulativeDistanceKm;

      if (segmentDistance >= segmentLength || i == points.length - 1) {
        if (segmentStartPoint.elevation != null &&
            currentPoint.elevation != null &&
            segmentDistance > 0) {
          final elevDiff = currentPoint.elevation! - segmentStartPoint.elevation!;
          final gradient = (elevDiff / (segmentDistance * 1000)) * 100;

          segments.add(
            _ElevationSegment(
              distance: segmentDistance,
              elevationDiff: elevDiff,
              gradient: gradient,
              startElevation: segmentStartPoint.elevation!,
              endElevation: currentPoint.elevation!,
            ),
          );
        }
        startIndex = i;
      }
    }
    return segments;
  }

  static SpeedStats calculateSpeedStats(List<RoutePointData> points) {
    final speeds = points
        .where((p) => p.speed != null)
        .map((p) => p.speed!)
        .toList();

    if (speeds.isEmpty) {
      return SpeedStats.empty();
    }

    speeds.sort();
    final maxSpeed = speeds.last;
    final minSpeed = speeds.first;
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final medianSpeed = speeds.length % 2 == 0
        ? (speeds[speeds.length ~/ 2 - 1] + speeds[speeds.length ~/ 2]) / 2
        : speeds[speeds.length ~/ 2];

    double totalMovingTime = 0;
    double totalStoppedTime = 0;
    double maxAcceleration = 0;
    double maxDeceleration = 0;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      if (prev.time != null && curr.time != null) {
        final timeDiffSeconds = curr.time!.difference(prev.time!).inSeconds;
        final timeDiffMinutes = timeDiffSeconds / 60.0;

        if (timeDiffMinutes > 0) {
          if (curr.speed != null && curr.speed! > 1) {
            totalMovingTime += timeDiffMinutes;
          } else {
            totalStoppedTime += timeDiffMinutes;
          }

          if (prev.speed != null && curr.speed != null) {
            final acceleration = (curr.speed! - prev.speed!) /
                (timeDiffSeconds / 3600.0);
            if (acceleration > maxAcceleration) maxAcceleration = acceleration;
            if (acceleration < maxDeceleration) maxDeceleration = acceleration;
          }
        }
      }
    }

    final totalTime = totalMovingTime + totalStoppedTime;
    final double movingTimePercentage =
        totalTime > 0 ? (totalMovingTime / totalTime) * 100 : 0;

    return SpeedStats(
      maxSpeed: maxSpeed,
      minSpeed: minSpeed,
      avgSpeed: avgSpeed,
      medianSpeed: medianSpeed,
      totalMovingTime: totalMovingTime,
      totalStoppedTime: totalStoppedTime,
      movingTimePercentage: movingTimePercentage,
      maxAcceleration: maxAcceleration,
      maxDeceleration: maxDeceleration.abs(),
    );
  }

  static TemperatureStats calculateTemperatureStats(
    List<RoutePointData> points,
  ) {
    final tempPoints = points.where((p) => p.temperature != null).toList();

    if (tempPoints.isEmpty) {
      return TemperatureStats.empty();
    }

    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    DateTime? minTempTime;
    DateTime? maxTempTime;
    double totalTemp = 0;

    for (final point in tempPoints) {
      final temp = point.temperature!;
      totalTemp += temp;

      if (temp < minTemp) {
        minTemp = temp;
        minTempTime = point.time;
      }

      if (temp > maxTemp) {
        maxTemp = temp;
        maxTempTime = point.time;
      }
    }

    final avgTemp = totalTemp / tempPoints.length;
    final temperatureRange = maxTemp - minTemp;

    return TemperatureStats(
      minTemp: minTemp,
      maxTemp: maxTemp,
      avgTemp: avgTemp,
      minTempTime: minTempTime,
      maxTempTime: maxTempTime,
      temperatureRange: temperatureRange,
    );
  }
}

class _ElevationSegment {
  final double distance;
  final double elevationDiff;
  final double gradient;
  final double startElevation;
  final double endElevation;

  _ElevationSegment({
    required this.distance,
    required this.elevationDiff,
    required this.gradient,
    required this.startElevation,
    required this.endElevation,
  });
}

final Uuid _uuid = const Uuid();

String generateNewId() {
  return _uuid.v4();
}

class RouteDetailPage extends StatefulWidget {
  final RouteData route;

  const RouteDetailPage({Key? key, required this.route}) : super(key: key);

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  ChartDataType _selectedDataType = ChartDataType.elevation;
  late final List<RoutePointData> _routeDataPoints;
  late final List<LatLng> _points;
  late final LatLngBounds _bounds;
  late final List<Marker> _directionArrows;
  late final List<Marker> _mainMarkers;

  final Distance _distanceCalculator = const Distance();
  List<Sector> sectors = [];

  // Variables para almacenar los LatLng de inicio/fin seleccionados para la creación de un nuevo sector
  // Son propiedades del State para que el StatefulBuilder del diálogo pueda actualizarlas.
  LatLng? _selectedStartLatLng;
  LatLng? _selectedEndLatLng;

  @override
  void initState() {
    super.initState();
    _routeDataPoints = _parseGpxContent(widget.route.gpxContent);
    _points = _routeDataPoints.map((data) => data.location).toList();
    _bounds = LatLngBounds.fromPoints(_points);
    _mainMarkers = _buildMainMarkers(_points);
    _directionArrows = _buildDirectionArrows(_points);
  }

  List<RoutePointData> _parseGpxContent(String gpxContent) {
    final RegExp trkptRegExp = RegExp(
      r'<trkpt lat="([\d\.\-]+)" lon="([\d\.\-]+)">\s*<ele>([\d\.\-]+)</ele>(?:\s*<time>([\dTZ\.:\-]+)</time>)?',
    );
    final List<RoutePointData> pointsData = [];

    double totalDistance = 0.0;
    LatLng? previousPoint;
    DateTime? previousTime;

    for (final match in trkptRegExp.allMatches(gpxContent)) {
      final lat = double.parse(match.group(1)!);
      final lon = double.parse(match.group(2)!);
      final elevation = double.parse(match.group(3)!);
      final timeStr = match.group(4);
      final DateTime? time = timeStr != null ? DateTime.tryParse(timeStr) : null;

      final currentLatLng = LatLng(lat, lon);

      if (previousPoint != null) {
        totalDistance += _distanceCalculator.distance(previousPoint, currentLatLng) / 1000;
      }

      final double tempPlaceholder = (elevation / 100).roundToDouble() + Random().nextDouble() * 5 - 2;

      double? currentSpeed;
      if (previousPoint != null && previousTime != null && time != null) {
        final double distMeters = _distanceCalculator.distance(previousPoint, currentLatLng);
        final Duration timeDiff = time.difference(previousTime);
        if (timeDiff.inSeconds > 0) {
          currentSpeed = (distMeters / timeDiff.inSeconds) * 3.6;
        } else {
          currentSpeed = 0.0;
        }
      } else {
        currentSpeed = null;
      }

      pointsData.add(
        RoutePointData(
          location: currentLatLng,
          elevation: elevation,
          time: time,
          temperature: tempPlaceholder,
          speed: currentSpeed,
          cumulativeDistanceKm: totalDistance,
        ),
      );
      previousPoint = currentLatLng;
      previousTime = time;
    }

    return pointsData;
  }

  double _getBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double lon2 = end.longitude * pi / 180;

    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  List<Marker> _buildDirectionArrows(List<LatLng> points) {
    List<Marker> arrows = [];
    if (points.length < 2) return arrows;

    const int arrowInterval = 100;

    for (int i = 0; i < points.length - 1; i += arrowInterval) {
      final LatLng p1 = points[i];
      final LatLng p2 = points[i + 1 < points.length ? i + 1 : i];

      final double bearing = _getBearing(p1, p2);

      arrows.add(
        Marker(
          point: p1,
          width: 15,
          height: 15,
          child: Transform.rotate(
            angle: (bearing) * pi / 180,
            child: const Icon(
              Icons.navigation,
              color: Colors.deepOrange,
              size: 12,
              shadows: [
                Shadow(
                  blurRadius: 1.0,
                  color: Colors.black45,
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return arrows;
  }

  List<Marker> _buildMainMarkers(List<LatLng> points) {
    final List<Marker> mainMarkers = [];
    if (points.isNotEmpty) {
      mainMarkers.add(
        Marker(
          point: points.first,
          width: 30.0,
          height: 30.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.0),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
          ),
        ),
      );
      if (points.length > 1) {
        mainMarkers.add(
          Marker(
            point: points.last,
            width: 30.0,
            height: 30.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: const Center(
                child: Text('🏁', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        );
      }
    }
    return mainMarkers;
  }

  Widget _buildStatisticsCard() {
    // ... (El código de _buildStatisticsCard es el mismo que antes, no lo repetiré aquí)
    switch (_selectedDataType) {
      case ChartDataType.elevation:
        final stats = RouteStatistics.calculateElevationStats(_routeDataPoints);
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas de Desnivel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Desnivel positivo total',
                  '${widget.route.elevationGainM?.toStringAsFixed(0) ?? 'N/A'} m',
                ),
                _buildStatRow(
                  'Desnivel negativo total',
                  '${stats.totalNegativeElevation.toStringAsFixed(0)} m',
                ),
                _buildStatRow(
                  'Elevación máxima',
                  '${stats.maxElevation.toStringAsFixed(0)} m',
                ),
                _buildStatRow(
                  'Elevación mínima',
                  '${stats.minElevation.toStringAsFixed(0)} m',
                ),
                const Divider(),
                _buildStatRow(
                  '% Ruta ascendente',
                  '${stats.ascentPercentage.toStringAsFixed(1)}%',
                ),
                _buildStatRow(
                  '% Ruta descendente',
                  '${stats.descentPercentage.toStringAsFixed(1)}%',
                ),
                _buildStatRow(
                  '% Ruta llana',
                  '${stats.flatPercentage.toStringAsFixed(1)}%',
                ),
                const Divider(),
                _buildStatRow(
                  'Pendiente positiva máxima',
                  '${stats.maxPositiveGradient.toStringAsFixed(1)}%',
                ),
                _buildStatRow(
                  'Pendiente negativa máxima',
                  '${stats.maxNegativeGradient.toStringAsFixed(1)}%',
                ),
                _buildStatRow(
                  'Pendiente positiva media',
                  '${stats.avgPositiveGradient.toStringAsFixed(1)}%',
                ),
                _buildStatRow(
                  'Pendiente negativa media',
                  '${stats.avgNegativeGradient.toStringAsFixed(1)}%',
                ),
                const Divider(),
                _buildStatRow(
                  'Ascenso medio por hora',
                  '${stats.avgAscentRatePerHour.toStringAsFixed(0)} m/h',
                ),
                _buildStatRow(
                  'Ascenso máximo por hora',
                  '${stats.maxAscentRatePerHour.toStringAsFixed(0)} m/h',
                ),
                _buildStatRow(
                  'Descenso medio por hora',
                  '${stats.avgDescentRatePerHour.toStringAsFixed(0)} m/h',
                ),
                _buildStatRow(
                  'Descenso máximo por hora',
                  '${stats.maxDescentRatePerHour.toStringAsFixed(0)} m/h',
                ),
              ],
            ),
          ),
        );
      case ChartDataType.speed:
        final stats = RouteStatistics.calculateSpeedStats(_routeDataPoints);
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas de Velocidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Velocidad máxima',
                  '${stats.maxSpeed.toStringAsFixed(1)} km/h',
                ),
                _buildStatRow(
                  'Velocidad mínima',
                  '${stats.minSpeed.toStringAsFixed(1)} km/h',
                ),
                _buildStatRow(
                  'Velocidad media',
                  '${stats.avgSpeed.toStringAsFixed(1)} km/h',
                ),
                _buildStatRow(
                  'Velocidad mediana',
                  '${stats.medianSpeed.toStringAsFixed(1)} km/h',
                ),
                const Divider(),
                _buildStatRow(
                  'Tiempo en movimiento',
                  '${stats.totalMovingTime.toStringAsFixed(0)} min',
                ),
                _buildStatRow(
                  'Tiempo parado',
                  '${stats.totalStoppedTime.toStringAsFixed(0)} min',
                ),
                _buildStatRow(
                  '% Tiempo en movimiento',
                  '${stats.movingTimePercentage.toStringAsFixed(1)}%',
                ),
                const Divider(),
                _buildStatRow(
                  'Aceleración máxima',
                  '${stats.maxAcceleration.toStringAsFixed(1)} km/h²',
                ),
                _buildStatRow(
                  'Desaceleración máxima',
                  '${stats.maxDeceleration.toStringAsFixed(1)} km/h²',
                ),
              ],
            ),
          ),
        );
      case ChartDataType.temperature:
        final stats = RouteStatistics.calculateTemperatureStats(
          _routeDataPoints,
        );
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas de Temperatura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Temperatura máxima',
                  '${stats.maxTemp.toStringAsFixed(1)}°C',
                ),
                _buildStatRow(
                  'Hora temp. máxima',
                  stats.maxTempTime
                          ?.toLocal()
                          .toString()
                          .split(' ')[1]
                          .substring(0, 5) ??
                      'N/A',
                ),
                _buildStatRow(
                  'Temperatura mínima',
                  '${stats.minTemp.toStringAsFixed(1)}°C',
                ),
                _buildStatRow(
                  'Hora temp. mínima',
                  stats.minTempTime
                          ?.toLocal()
                          .toString()
                          .split(' ')[1]
                          .substring(0, 5) ??
                      'N/A',
                ),
                _buildStatRow(
                  'Temperatura media',
                  '${stats.avgTemp.toStringAsFixed(1)}°C',
                ),
                _buildStatRow(
                  'Rango térmico',
                  '${stats.temperatureRange.toStringAsFixed(1)}°C',
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// **MODIFICADO:** Ahora también devuelve el punto de la ruta más cercano
  /// al LatLng del toque. Esto es crucial para la lógica del sector.
  int _findClosestPointIndex(LatLng targetLatLng) {
    if (_routeDataPoints.isEmpty) return -1;

    double minDistance = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < _routeDataPoints.length; i++) {
      final currentPointLatLng = _routeDataPoints[i].location;
      final distance = _distanceCalculator.distance(targetLatLng, currentPointLatLng);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  /// Muestra un diálogo para añadir un nuevo sector, permitiendo la selección de puntos de inicio/fin en un mapa.
  Future<void> _showAddSectorDialog() async {
    final nameController = TextEditingController();
    // Reiniciar los puntos seleccionados cuando se abre el diálogo
    _selectedStartLatLng = null;
    _selectedEndLatLng = null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir nuevo sector'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del sector'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final LatLng? result = await Navigator.push<LatLng>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectPointOnMapPage(
                            routePoints: _points,
                            initialBounds: _bounds,
                            title: 'Seleccionar Punto de Inicio',
                            initialSelectedPoint: _selectedStartLatLng,
                            isStartPoint: true, // **NUEVO:** Indicamos que es el punto inicial
                          ),
                        ),
                      );
                      if (result != null) {
                        setDialogState(() {
                          _selectedStartLatLng = result;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Punto de inicio guardado!')),
                        );
                      } else {
                        // **MODIFICADO:** Mensaje si se cancela la selección (o no se seleccionó nada)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selección de punto de inicio cancelada.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: Text(_selectedStartLatLng == null
                        ? 'Seleccionar Inicio en Mapa'
                        : 'Inicio Seleccionado (${_selectedStartLatLng!.latitude.toStringAsFixed(3)}, ${_selectedStartLatLng!.longitude.toStringAsFixed(3)})'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final LatLng? result = await Navigator.push<LatLng>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectPointOnMapPage(
                            routePoints: _points,
                            initialBounds: _bounds,
                            title: 'Seleccionar Punto Final',
                            initialSelectedPoint: _selectedEndLatLng,
                            isStartPoint: false, // **NUEVO:** Indicamos que es el punto final
                          ),
                        ),
                      );
                      if (result != null) {
                        setDialogState(() {
                          _selectedEndLatLng = result;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Punto final guardado!')),
                        );
                      } else {
                        // **MODIFICADO:** Mensaje si se cancela la selección (o no se seleccionó nada)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selección de punto final cancelada.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: Text(_selectedEndLatLng == null
                        ? 'Seleccionar Fin en Mapa'
                        : 'Fin Seleccionado (${_selectedEndLatLng!.latitude.toStringAsFixed(3)}, ${_selectedEndLatLng!.longitude.toStringAsFixed(3)})'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty || _selectedStartLatLng == null || _selectedEndLatLng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Por favor, completa el nombre y selecciona ambos puntos en el mapa.')),
                      );
                      return;
                    }

                    final startIndex = _findClosestPointIndex(_selectedStartLatLng!);
                    final endIndex = _findClosestPointIndex(_selectedEndLatLng!);

                    if (startIndex == -1 || endIndex == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No se pudieron encontrar puntos de la ruta cercanos a tus selecciones. Intenta de nuevo.')),
                      );
                      return;
                    }

                    if (startIndex >= endIndex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('El punto de inicio debe ser anterior al punto final en la ruta.')),
                      );
                      return;
                    }

                    final newSector = Sector(
                      id: generateNewId(),
                      name: name,
                      startIndex: startIndex,
                      endIndex: endIndex,
                      polyline: _points.sublist(startIndex, endIndex + 1),
                      distanceKm: _routeDataPoints[endIndex].cumulativeDistanceKm -
                          _routeDataPoints[startIndex].cumulativeDistanceKm,
                    );

                    setState(() {
                      sectors.add(newSector);
                    });

                    Navigator.of(context).pop(); // Cierra el diálogo de añadir sector
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );
    
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto del método build es el mismo que antes, no lo repetiré aquí)
    List<FlSpot> chartSpots = [];
    String yAxisTitle = '';
    double maxY = 0;
    double minY = 0;

    switch (_selectedDataType) {
      case ChartDataType.elevation:
        yAxisTitle = 'Desnivel (m)';
        minY = _routeDataPoints.fold<double>(
          double.infinity,
          (prev, curr) => curr.elevation != null && curr.elevation! < prev
              ? curr.elevation!
              : prev,
        );
        maxY = _routeDataPoints.fold<double>(
          double.negativeInfinity,
          (prev, curr) => curr.elevation != null && curr.elevation! > prev
              ? curr.elevation!
              : prev,
        );

        if (minY == double.infinity) minY = 0;
        if (maxY == double.negativeInfinity) maxY = 100;

        for (var data in _routeDataPoints) {
          if (data.elevation != null) {
            chartSpots.add(
              FlSpot(data.cumulativeDistanceKm.toDouble(), data.elevation!),
            );
          }
        }
        break;
      case ChartDataType.speed:
        yAxisTitle = 'Velocidad (km/h)';
        minY = _routeDataPoints.fold<double>(
          double.infinity,
          (prev, curr) =>
              curr.speed != null && curr.speed! < prev ? curr.speed! : prev,
        );
        maxY = _routeDataPoints.fold<double>(
          double.negativeInfinity,
          (prev, curr) =>
              curr.speed != null && curr.speed! > prev ? curr.speed! : prev,
        );

        if (minY == double.infinity) minY = 0;
        if (maxY == double.negativeInfinity) maxY = 30;

        for (var data in _routeDataPoints) {
          if (data.speed != null) {
            chartSpots.add(
              FlSpot(data.cumulativeDistanceKm.toDouble(), data.speed!),
            );
          }
        }
        break;
      case ChartDataType.temperature:
        yAxisTitle = 'Temperatura (°C)';
        minY = _routeDataPoints.fold<double>(
          double.infinity,
          (prev, curr) => curr.temperature != null && curr.temperature! < prev
              ? curr.temperature!
              : prev,
        );
        maxY = _routeDataPoints.fold<double>(
          double.negativeInfinity,
          (prev, curr) => curr.temperature != null && curr.temperature! > prev
              ? curr.temperature!
              : prev,
        );

        if (minY == double.infinity) minY = 0;
        if (maxY == double.negativeInfinity) maxY = 30;

        for (var data in _routeDataPoints) {
          if (data.temperature != null) {
            chartSpots.add(
              FlSpot(data.cumulativeDistanceKm.toDouble(), data.temperature!),
            );
          }
        }
        break;
    }

    if (chartSpots.isNotEmpty) {
      if (maxY == minY) {
        if (maxY == 0) {
          maxY = 1.0;
        } else {
          maxY *= 1.1;
          minY *= 0.9;
        }
      } else {
        final range = maxY - minY;
        maxY += range * 0.1;
        minY -= range * 0.1;
        if (minY < 0 &&
            (_selectedDataType == ChartDataType.elevation ||
                _selectedDataType == ChartDataType.temperature)) {
          minY = 0;
        }
      }
    } else {
      minY = 0;
      maxY = 1;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.route.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.extended(
                onPressed: _showAddSectorDialog,
                icon: const Icon(Icons.add_chart),
                label: const Text('Añadir Sector'),
                heroTag: null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📅 Fecha: ${widget.route.date?.toLocal().toString().split(' ')[0] ?? 'Desconocida'}",
                  ),
                  Text(
                    "📏 Distancia: ${widget.route.distanceKm?.toStringAsFixed(2)} km",
                  ),
                  Text(
                    "⛰️ Desnivel positivo: ${widget.route.elevationGainM?.toStringAsFixed(0) ?? 'N/A'} m",
                  ),
                ],
              ),
            ),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.6,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        bounds: _bounds,
                        boundsOptions: const FitBoundsOptions(
                          padding: EdgeInsets.all(20.0),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.yourapp',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _points,
                              strokeWidth: 4,
                              color: Colors.deepOrange,
                            ),
                          ],
                        ),
                        MarkerLayer(markers: [..._mainMarkers, ..._directionArrows]),
                      ],
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenMapPage(
                                route: widget.route,
                                points: _points,
                                initialBounds: _bounds,
                                routeDataPoints: _routeDataPoints,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.fullscreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<ChartDataType>(
                        value: _selectedDataType,
                        items: const [
                          DropdownMenuItem(
                            value: ChartDataType.elevation,
                            child: Text('Desnivel'),
                          ),
                          DropdownMenuItem(
                            value: ChartDataType.speed,
                            child: Text('Velocidad'),
                          ),
                          DropdownMenuItem(
                            value: ChartDataType.temperature,
                            child: Text('Temperatura'),
                          ),
                        ],
                        onChanged: (ChartDataType? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDataType = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(
                                    '${value.toInt()} km',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                String text;
                                if (_selectedDataType == ChartDataType.elevation) {
                                  text = value.toStringAsFixed(0);
                                } else {
                                  text = value.toStringAsFixed(1);
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                            axisNameWidget: Text(
                              yAxisTitle,
                              style: const TextStyle(fontSize: 12),
                            ),
                            axisNameSize: 20,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: const Color(0xff37434d),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: _routeDataPoints.isNotEmpty
                            ? _routeDataPoints.last.cumulativeDistanceKm
                            : 1,
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartSpots,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatisticsCard(),
            if (sectors.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sectores Definidos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...sectors.map((sector) => ListTile(
                          title: Text(sector.name),
                          subtitle: Text(
                              'Inicio: ${sector.startIndex}, Fin: ${sector.endIndex}'),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ... (El resto del código para FullScreenMapPage es el mismo que antes, no lo repetiré aquí)
class FullScreenMapPage extends StatelessWidget {
  final RouteData route;
  final List<LatLng> points;
  final LatLngBounds initialBounds;
  final List<RoutePointData> routeDataPoints;

  const FullScreenMapPage({
    super.key,
    required this.route,
    required this.points,
    required this.initialBounds,
    required this.routeDataPoints,
  });

  double _getBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double lon2 = end.longitude * pi / 180;

    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  List<Marker> _buildDirectionArrows(List<LatLng> points) {
    List<Marker> arrows = [];
    if (points.length < 2) return arrows;

    const int arrowInterval = 100;

    for (int i = 0; i < points.length - 1; i += arrowInterval) {
      final LatLng p1 = points[i];
      final LatLng p2 = points[i + 1 < points.length ? i + 1 : i];

      final double bearing = _getBearing(p1, p2);

      arrows.add(
        Marker(
          point: p1,
          width: 15,
          height: 15,
          child: Transform.rotate(
            angle: (bearing) * pi / 180,
            child: const Icon(
              Icons.navigation,
              color: Colors.deepOrange,
              size: 12,
              shadows: [
                Shadow(
                  blurRadius: 1.0,
                  color: Colors.black45,
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return arrows;
  }

  List<Marker> _buildMainMarkers(List<LatLng> points) {
    final List<Marker> mainMarkers = [];
    if (points.isNotEmpty) {
      mainMarkers.add(
        Marker(
          point: points.first,
          width: 30.0,
          height: 30.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.0),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
          ),
        ),
      );
      if (points.length > 1) {
        mainMarkers.add(
          Marker(
            point: points.last,
            width: 30.0,
            height: 30.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: const Center(
                child: Text('🏁', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        );
      }
    }
    return mainMarkers;
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> allMarkers = [
      ..._buildMainMarkers(points),
      ..._buildDirectionArrows(points)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${route.name} (Mapa Completo)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          bounds: initialBounds,
          boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(40.0)),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.yourapp',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4,
                color: Colors.deepOrange,
              ),
            ],
          ),
          MarkerLayer(markers: allMarkers),
        ],
      ),
    );
  }
}