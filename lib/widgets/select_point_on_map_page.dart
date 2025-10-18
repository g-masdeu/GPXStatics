// lib/widgets/select_point_on_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Una página de mapa de pantalla completa que permite al usuario seleccionar un único punto [LatLng].
///
/// Muestra la ruta y el usuario puede tocar el mapa para establecer un marcador de selección.
/// El punto seleccionado se devuelve cuando el usuario confirma.
class SelectPointOnMapPage extends StatefulWidget {
  final List<LatLng> routePoints; // La polilínea completa de la ruta para el contexto visual
  final LatLngBounds initialBounds; // Límites iniciales de la vista del mapa
  final String title; // Título para la AppBar
  final LatLng? initialSelectedPoint; // Opcional: un punto ya seleccionado para mostrar inicialmente
  final bool isStartPoint; // **NUEVO:** Para indicar si es punto inicial o final

  const SelectPointOnMapPage({
    super.key,
    required this.routePoints,
    required this.initialBounds,
    required this.title,
    this.initialSelectedPoint,
    required this.isStartPoint, // **NUEVO:** Requerido
  });

  @override
  State<SelectPointOnMapPage> createState() => _SelectPointOnMapPageState();
}

class _SelectPointOnMapPageState extends State<SelectPointOnMapPage> {
  LatLng? _selectedPoint; // Almacena el LatLng de la selección actual del usuario
  Marker? _selectionMarker; // El widget de marcador para mostrar en el punto seleccionado

  @override
  void initState() {
    super.initState();
    // Inicializa con un punto preseleccionado si se proporciona
    _selectedPoint = widget.initialSelectedPoint;
    if (_selectedPoint != null) {
      _updateSelectionMarker(_selectedPoint!);
    }
  }

  /// Actualiza [_selectedPoint] y recrea [_selectionMarker].
  /// Se llama cada vez que el usuario toca el mapa.
  void _updateSelection(LatLng tappedPoint) {
    setState(() {
      _selectedPoint = tappedPoint;
      _updateSelectionMarker(tappedPoint);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Punto marcado!'),
        duration: Duration(seconds: 1), // Pequeña duración para no molestar
      ),
    );
  }

  /// Crea o actualiza el marcador que muestra la ubicación seleccionada.
  void _updateSelectionMarker(LatLng point) {
    _selectionMarker = Marker(
      point: point,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.location_on, // Icono de ubicación estándar
        color: Colors.red, // Color prominente para la selección
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Botón de confirmación: devuelve el punto seleccionado al cerrar la página.
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedPoint != null
                ? () {
                    // **MODIFICADO:** Añadir el print y pop con el resultado
                    if (_selectedPoint != null) {
                      print('Punto ${widget.isStartPoint ? 'Inicial' : 'Final'} marcado: Latitud ${_selectedPoint!.latitude}, Longitud ${_selectedPoint!.longitude}');
                    }
                    Navigator.pop(context, _selectedPoint);
                  }
                : null, // El botón está deshabilitado si no hay punto seleccionado
          ),
          // **NUEVO:** Botón de "Cerrar" para volver al modal sin guardar (opcionalmente)
          // Si el usuario quiere salir sin seleccionar un punto, esto devuelve null
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Simplemente cierra la página sin devolver un punto, o devuelve el _selectedPoint
              // si ya hay uno y el usuario pulsa cerrar en lugar de check.
              // Para el propósito del print, vamos a imprimir siempre el último punto seleccionado
              // antes de cerrar, si es que hay alguno.
              if (_selectedPoint != null) {
                print('Cerrando selección: Último punto ${widget.isStartPoint ? 'Inicial' : 'Final'} visto: Latitud ${_selectedPoint!.latitude}, Longitud ${_selectedPoint!.longitude}');
              } else {
                print('Cerrando selección de punto ${widget.isStartPoint ? 'Inicial' : 'Final'}: No se seleccionó ningún punto.');
              }
              Navigator.pop(context, _selectedPoint); // Devuelve el punto o null si no se tocó nada
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          bounds: widget.initialBounds, // Ajusta el mapa a los límites de toda la ruta inicialmente
          boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(40.0)),
          onTap: (tapPosition, latlng) => _updateSelection(latlng), // Captura los eventos de toque
        ),
        children: [
          // Capa de teselas de OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.yourapp',
          ),
          // Capa de polilínea de la ruta
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                strokeWidth: 4,
                color: Colors.deepOrange, // Color de la ruta
              ),
            ],
          ),
          // Capa de marcador del punto seleccionado
          // Solo muestra el marcador si se ha seleccionado un punto
          if (_selectionMarker != null) MarkerLayer(markers: [_selectionMarker!]),
        ],
      ),
    );
  }
}