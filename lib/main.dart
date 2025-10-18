import 'dart:math';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'db/db_helper.dart';

import 'models/user.dart';
import 'models/bike.dart';
import 'models/route.dart';

import 'widgets/bike_manager.dart';
import 'widgets/user_manager.dart';
import 'widgets/route_detail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Usuarios y Bicicletas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0078D7), // Azul Windows
        scaffoldBackgroundColor: const Color(0xFFF3F3F3), // Gris claro
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0078D7),
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Segoe UI',
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0078D7),
            side: const BorderSide(color: Color(0xFF0078D7)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? selectedUser;
  Bike? selectedBike;

  final List<RouteData> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutesFromDatabase();
  }

  Future<void> _loadRoutesFromDatabase() async {
    final routes = await DatabaseHelper.instance.getRoutes();
    setState(() {
      _routes.clear();
      _routes.addAll(routes);
    });
  }

  void _openUserModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => UserManager(
        selectedUser: selectedUser,
        onUserSelected: (user) {
          setState(() {
            selectedUser = user;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openBikeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => BikeManager(
        selectedBike: selectedBike,
        onBikeSelected: (bike) {
          setState(() {
            selectedBike = bike;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  RouteData _parseGpxAndCreateRoute(String gpxData, String name) {
    final gpx = GpxReader().fromString(gpxData);

    if (gpx.trks.isEmpty ||
        gpx.trks.first.trksegs.isEmpty ||
        gpx.trks.first.trksegs.first.trkpts.isEmpty) {
      throw Exception('El archivo GPX no contiene datos de track válidos.');
    }

    DateTime? date;
    double distanceMeters = 0.0;
    double elevationGain = 0.0;

    final trks = gpx.trks;
    if (trks.isEmpty) {
      return RouteData(name: name, gpxContent: gpxData);
    }

    final points = <Wpt>[];
    for (final trk in trks) {
      for (final seg in trk.trksegs) {
        points.addAll(seg.trkpts);
      }
    }

    if (points.isEmpty) {
      return RouteData(name: name, gpxContent: gpxData);
    }

    date = points.first.time;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      if (prev.lat != null &&
          prev.lon != null &&
          curr.lat != null &&
          curr.lon != null) {
        final lat1 = prev.lat! * (3.141592653589793 / 180);
        final lon1 = prev.lon! * (3.141592653589793 / 180);
        final lat2 = curr.lat! * (3.141592653589793 / 180);
        final lon2 = curr.lon! * (3.141592653589793 / 180);

        const earthRadius = 6371000; // metros
        final dlat = lat2 - lat1;
        final dlon = lon2 - lon1;

        final a =
            (sin(dlat / 2) * sin(dlat / 2)) +
            cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
        final c = 2 * atan2(sqrt(a), sqrt(1 - a));
        final distance = earthRadius * c;

        distanceMeters += distance;
      }

      if (prev.ele != null && curr.ele != null) {
        final diff = curr.ele! - prev.ele!;
        if (diff > 0) {
          elevationGain += diff;
        }
      }
    }

    return RouteData(
      name: name,
      gpxContent: gpxData,
      date: date,
      distanceKm: distanceMeters / 1000.0,
      elevationGainM: elevationGain,
    );
  }

  Future<void> _importRouteFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );

      if (result != null) {
        String? gpxData;

        if (result.files.single.bytes != null) {
          gpxData = String.fromCharCodes(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          gpxData = await file.readAsString();
        }

        if (gpxData != null) {
          final route = _parseGpxAndCreateRoute(
            gpxData,
            'Ruta ${_routes.length + 1}',
          );

          await DatabaseHelper.instance.insertRoute(route);
          _loadRoutesFromDatabase(); // Reload routes to include the new one

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ruta importada y guardada con éxito'),
            ),
          );
        } else {
          throw Exception('No se pudo leer el contenido del archivo GPX.');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar el archivo: $e')),
      );
    }
  }

  Future<void> _deleteRoute(int? id) async {
    if (id == null) return; // Cannot delete a route without an ID

    try {
      await DatabaseHelper.instance.deleteRoute(id);
      _loadRoutesFromDatabase(); // Reload routes after deletion
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ruta eliminada con éxito')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar la ruta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estadísticas de Bici'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Seleccionar Usuario',
            onPressed: _openUserModal,
          ),
          IconButton(
            icon: const Icon(Icons.pedal_bike),
            tooltip: 'Seleccionar Bicicleta',
            onPressed: _openBikeModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/fondo1.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedUser != null
                      ? 'Usuario: ${selectedUser!.name} (${selectedUser!.gender}) - Edad: ${selectedUser!.age}'
                      : 'No hay usuario seleccionado',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedBike != null
                      ? 'Bicicleta: ${selectedBike!.brand} ${selectedBike!.model}'
                      : 'No hay bicicleta seleccionada',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: _importRouteFromFile,
                    child: const Text('Importar ruta'),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _routes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay rutas importadas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _routes.length,
                          itemBuilder: (context, index) {
                            final route = _routes[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(
                                    0xFF0078D7,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RouteDetailPage(route: route),
                                    ),
                                  );
                                },
                                title: Text(
                                  route.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (route.date != null)
                                        Text(
                                          'Fecha: ${route.date!.toLocal().toString().split(' ')[0]}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      if (route.distanceKm != null)
                                        Text(
                                          'Kilómetros: ${route.distanceKm!.toStringAsFixed(2)} km',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      if (route.elevationGainM != null)
                                        Text(
                                          'Desnivel: ${route.elevationGainM!.toStringAsFixed(0)} m',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteRoute(route.id),
                                  tooltip: 'Eliminar ruta',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
