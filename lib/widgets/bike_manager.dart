import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../db/db_helper.dart';

class BikeManager extends StatefulWidget {
  final Function(Bike?) onBikeSelected;
  final Bike? selectedBike;

  const BikeManager({
    super.key,
    required this.onBikeSelected,
    required this.selectedBike,
  });

  @override
  State<BikeManager> createState() => _BikeManagerState();
}

class _BikeManagerState extends State<BikeManager> {
  List<Bike> bikes = [];

  @override
  void initState() {
    super.initState();
    _loadBikes();
  }

  Future<void> _loadBikes() async {
    try {
      bikes = await DatabaseHelper.instance.getBikes();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading bikes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar bicicletas')),
        );
      }
    }
  }

  void _addOrEditBike({Bike? bike}) {
    final brandController = TextEditingController(text: bike?.brand ?? '');
    final modelController = TextEditingController(text: bike?.model ?? '');
    final yearController = TextEditingController(text: bike?.year.toString() ?? '');
    final weightController = TextEditingController(text: bike?.weight.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(bike == null ? 'Nueva Bicicleta' : 'Editar Bicicleta'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Marca'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'La marca no puede estar vacía.' : null,
                      ),
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'El modelo no puede estar vacío.' : null,
                      ),
                      TextFormField(
                        controller: yearController,
                        decoration: const InputDecoration(labelText: 'Año'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final year = int.tryParse(value ?? '');
                          if (year == null || year < 1900 || year > DateTime.now().year) {
                            return 'Introduce un año válido.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: weightController,
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final weight = double.tryParse(value ?? '');
                          if (weight == null || weight < 3 || weight > 50) {
                            return 'Introduce un peso válido (3-50 kg).';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final newBike = Bike(
                    id: bike?.id,
                    brand: brandController.text.trim(),
                    model: modelController.text.trim(),
                    year: int.parse(yearController.text.trim()),
                    weight: double.parse(weightController.text.trim()),
                  );

                  if (bike == null) {
                    await DatabaseHelper.instance.insertBike(newBike);
                  } else {
                    await DatabaseHelper.instance.updateBike(newBike);
                  }

                  if (context.mounted) Navigator.pop(context);
                  _loadBikes();
                } catch (e) {
                  debugPrint('Error saving bike: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al guardar bicicleta')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteBike(int id) async {
    try {
      await DatabaseHelper.instance.deleteBike(id);
      _loadBikes();
      if (widget.selectedBike?.id == id) {
        widget.onBikeSelected(null);
      }
    } catch (e) {
      debugPrint('Error deleting bike: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar bicicleta')),
        );
      }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bicicletas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addOrEditBike(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bikes.isEmpty) const Text('No hay bicicletas.'),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: bikes.map((bike) {
                final selected = widget.selectedBike?.id == bike.id;
                return ListTile(
                  title: Text('${bike.brand} ${bike.model} (${bike.year})'),
                  subtitle: Text('Peso: ${bike.weight} kg'),
                  selected: selected,
                  onTap: () => widget.onBikeSelected(bike),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditBike(bike: bike),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBike(bike.id!),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}