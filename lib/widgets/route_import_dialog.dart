import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

enum RouteImportOption {
  localFile,
}

class RouteImportDialog extends StatefulWidget {
  final Function(RouteImportOption option, {String? gpxData}) onRouteImported;

  const RouteImportDialog({super.key, required this.onRouteImported});

  @override
  State<RouteImportDialog> createState() => _RouteImportDialogState();
}

class _RouteImportDialogState extends State<RouteImportDialog> {
  RouteImportOption? _selectedOption;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _pickLocalGpxFile() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final gpxContent = await file.readAsString();
        widget.onRouteImported(RouteImportOption.localFile, gpxData: gpxContent);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'No se seleccionó ningún archivo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al leer archivo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submit() {
    if (_selectedOption == RouteImportOption.localFile) {
      _pickLocalGpxFile();
    } else {
      setState(() {
        _errorMessage = 'Selecciona una opción';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Importar ruta desde archivo GPX local:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Archivo GPX local'),
            leading: Radio<RouteImportOption>(
              value: RouteImportOption.localFile,
              groupValue: _selectedOption,
              onChanged: (val) {
                setState(() {
                  _selectedOption = val;
                  _errorMessage = null;
                });
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Importar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
