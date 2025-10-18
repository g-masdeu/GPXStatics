// lib/models/route_point_data.dart
import 'package:latlong2/latlong.dart';

/// Clase para almacenar un punto de la ruta con sus datos adicionales.
///
/// Incluye ubicación, elevación, tiempo, temperatura, velocidad y distancia acumulada.
class RoutePointData {
  final LatLng location;
  final double? elevation;
  final DateTime? time;
  final double? temperature;
  final double? speed;
  final double cumulativeDistanceKm; // Distancia acumulada desde el inicio de la ruta en KM

  RoutePointData({
    required this.location,
    this.elevation,
    this.time,
    this.temperature,
    this.speed,
    this.cumulativeDistanceKm = 0.0, // Valor predeterminado, se calculará
  });
}