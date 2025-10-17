import 'package:flutter/material.dart';
import '../../services/building_admin_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddApartmentScreen extends StatefulWidget {
  final String buildingId;

  const AddApartmentScreen({
    super.key,
    required this.buildingId,
  });

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final BuildingAdminService _adminService = BuildingAdminService();

  final _labelController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bedroomsController = TextEditingController();

  bool _hasBalcony = false;
  bool _isFurnished = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _labelController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    _surfaceController.dispose();
    _roomsController.dispose();
    _bedroomsController.dispose();
    super.dispose();
  }

  Future<void> _createApartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.createApartment(
        buildingId: widget.buildingId,
        apartmentLabel: _labelController.text.trim(),
        apartmentNumber: _numberController.text.trim(),
        apartmentFloor: int.parse(_floorController.text.trim()),
        livingAreaSurface: _surfaceController.text.isNotEmpty
            ? double.parse(_surfaceController.text.trim())
            : null,
        numberOfRooms: _roomsController.text.isNotEmpty
            ? int.parse(_roomsController.text.trim())
            : null,
        numberOfBedrooms: _bedroomsController.text.isNotEmpty
            ? int.parse(_bedroomsController.text.trim())
            : null,
        haveBalconyOrTerrace: _hasBalcony,
        isFurnished: _isFurnished,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appartement créé avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un appartement'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Informations de base',
              style: AppTheme.titleStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _labelController,
              label: 'Nom de l\'appartement',
              hint: 'Ex: Appartement A1',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _numberController,
              label: 'Numéro',
              hint: 'Ex: 101',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un numéro';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _floorController,
              label: 'Étage',
              hint: 'Ex: 1',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'étage';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Détails (optionnel)',
              style: AppTheme.titleStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _surfaceController,
              label: 'Surface habitable (m²)',
              hint: 'Ex: 75.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _roomsController,
              label: 'Nombre de pièces',
              hint: 'Ex: 3',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _bedroomsController,
              label: 'Nombre de chambres',
              hint: 'Ex: 2',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text(
              'Caractéristiques',
              style: AppTheme.titleStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Balcon ou terrasse'),
              value: _hasBalcony,
              onChanged: (value) {
                setState(() => _hasBalcony = value);
              },
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Meublé'),
              value: _isFurnished,
              onChanged: (value) {
                setState(() => _isFurnished = value);
              },
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Créer l\'appartement',
              onPressed: _isLoading ? null : _createApartment,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
