import '../models/route_point_data.dart'; // Ajusta según tu estructura

class RouteData {
  int? id;
  String name;
  String gpxContent;

  DateTime? date;
  double? distanceKm;
  double? elevationGainM;

  /// NUEVO: lista de puntos parseados desde el GPX (no se guarda en DB)
  late final List<RoutePointData> points;

  RouteData({
    this.id,
    required this.name,
    required this.gpxContent,
    this.date,
    this.distanceKm,
    this.elevationGainM,
    List<RoutePointData>? points,
  }) {
    this.points = points ?? [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gpxContent': gpxContent,
      'date': date?.toIso8601String(),
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      // NOTA: points no se guarda aquí
    };
  }

  factory RouteData.fromMap(Map<String, dynamic> map) {
    return RouteData(
      id: map['id'] as int?,
      name: map['name'] as String,
      gpxContent: map['gpxContent'] as String,
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      distanceKm: map['distanceKm'] != null ? (map['distanceKm'] as num).toDouble() : null,
      elevationGainM: map['elevationGainM'] != null ? (map['elevationGainM'] as num).toDouble() : null,
      points: [], // Se parsearán luego manualmente si hace falta
    );
  }

  /// Crear ruta desde GPX y pasar puntos procesados
  static RouteData fromGpx(
    String gpx,
    String name, {
    required List<RoutePointData> parsedPoints,
    DateTime? date,
    double? distanceKm,
    double? elevationGainM,
  }) {
    return RouteData(
      name: name,
      gpxContent: gpx,
      date: date,
      distanceKm: distanceKm,
      elevationGainM: elevationGainM,
      points: parsedPoints,
    );
  }
}
