import 'package:flutter/material.dart';
import '../models/user.dart';
import '../db/db_helper.dart'; // Asegúrate de tener acceso a la DB

class UserManager extends StatefulWidget {
  final Function(User?) onUserSelected;
  final User? selectedUser;

  const UserManager({
    super.key,
    required this.onUserSelected,
    required this.selectedUser,
  });

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      users = await DatabaseHelper.instance.getUsers();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar usuarios')),
        );
      }
    }
  }

  void _addOrEditUser({User? user}) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final heightController = TextEditingController(
      text: user?.height.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: user?.weight.toString() ?? '',
    );
    final birthDate = user?.birthDate;
    DateTime? selectedBirthDate = birthDate;
    String? gender = user?.gender;

    final formKey = GlobalKey<FormState>();

    final ageController = TextEditingController(
      text: birthDate != null ? _calculateAge(birthDate).toString() : '',
    );

    Future<void> pickBirthDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedBirthDate ?? DateTime(now.year - 20),
        firstDate: DateTime(now.year - 100),
        lastDate: now,
      );
      if (picked != null) {
        selectedBirthDate = picked;
        ageController.text = _calculateAge(picked).toString();
        setState(() {});
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(user == null ? 'Nuevo Usuario' : 'Editar Usuario'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Introduce un nombre'
                            : null,
                      ),
                      TextFormField(
                        controller: heightController,
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null) return 'Altura inválida';
                          if (parsed < 50 || parsed > 250) {
                            return 'Debe estar entre 50 y 250 cm';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null) return 'Peso inválido';
                          if (parsed < 20 || parsed > 300) {
                            return 'Debe estar entre 20 y 300 kg';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: const InputDecoration(labelText: 'Género'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Masculino',
                            child: Text('Masculino'),
                          ),
                          DropdownMenuItem(
                            value: 'Femenino',
                            child: Text('Femenino'),
                          ),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          setStateDialog(() => gender = value);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un género' : null,
                      ),
                      TextFormField(
                        controller: ageController,
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: pickBirthDate,
                        validator: (value) => selectedBirthDate == null
                            ? 'Selecciona fecha de nacimiento'
                            : null,
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
                  final newUser = User(
                    id: user?.id,
                    name: nameController.text.trim(),
                    height: int.parse(heightController.text.trim()),
                    weight: int.parse(weightController.text.trim()),
                    gender: gender!,
                    birthDate: selectedBirthDate!,
                  );

                  if (user == null) {
                    await DatabaseHelper.instance.insertUser(newUser);
                  } else {
                    await DatabaseHelper.instance.updateUser(newUser);
                  }

                  if (context.mounted) Navigator.pop(context);
                  _loadUsers();
                } catch (e) {
                  debugPrint('Error saving user: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al guardar usuario')),
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

  void _deleteUser(int id) async {
    try {
      await DatabaseHelper.instance.deleteUser(id);
      _loadUsers();
      if (widget.selectedUser?.id == id) {
        widget.onUserSelected(null);
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar usuario')),
        );
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
                'Usuarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addOrEditUser(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (users.isEmpty) const Text('No hay usuarios.'),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: users.map((user) {
                final selected = widget.selectedUser?.id == user.id;
                return ListTile(
                  title: Text('${user.name} (${user.gender})'),
                  subtitle: Text(
                    'Edad: ${_calculateAge(user.birthDate)} | Altura: ${user.height} cm | Peso: ${user.weight} kg',
                  ),
                  selected: selected,
                  onTap: () => widget.onUserSelected(user),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditUser(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id!),
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