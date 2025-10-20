import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/building_admin_service.dart';
import '../../utils/app_theme.dart';

class CreateBuildingScreen extends StatefulWidget {
  const CreateBuildingScreen({super.key});

  @override
  State<CreateBuildingScreen> createState() => _CreateBuildingScreenState();
}

class _CreateBuildingScreenState extends State<CreateBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final BuildingAdminService _adminService = BuildingAdminService();
  final ImagePicker _picker = ImagePicker();

  final _buildingLabelController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _yearOfConstructionController = TextEditingController();
  final _numberOfFloorsController = TextEditingController();
  final _buildingStateController = TextEditingController();
  final _facadeWidthController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _landWidthController = TextEditingController();
  final _builtAreaController = TextEditingController();

  final _addressController = TextEditingController();
  final _addressSuiteController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _observationController = TextEditingController();

  bool _hasElevator = false;
  bool _hasHandicapAccess = false;
  bool _hasPool = false;
  bool _hasCableTv = false;

  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _buildingLabelController.dispose();
    _buildingNumberController.dispose();
    _yearOfConstructionController.dispose();
    _numberOfFloorsController.dispose();
    _buildingStateController.dispose();
    _facadeWidthController.dispose();
    _landAreaController.dispose();
    _landWidthController.dispose();
    _builtAreaController.dispose();
    _addressController.dispose();
    _addressSuiteController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final buildingData = {
        'buildingLabel': _buildingLabelController.text,
        'buildingNumber': _buildingNumberController.text,
        'yearOfConstruction': _yearOfConstructionController.text.isNotEmpty
            ? int.parse(_yearOfConstructionController.text)
            : null,
        'numberOfFloors': _numberOfFloorsController.text.isNotEmpty
            ? int.parse(_numberOfFloorsController.text)
            : null,
        'buildingState': _buildingStateController.text,
        'facadeWidth': _facadeWidthController.text.isNotEmpty
            ? double.parse(_facadeWidthController.text)
            : null,
        'landArea': _landAreaController.text.isNotEmpty
            ? double.parse(_landAreaController.text)
            : null,
        'landWidth': _landWidthController.text.isNotEmpty
            ? double.parse(_landWidthController.text)
            : null,
        'builtArea': _builtAreaController.text.isNotEmpty
            ? double.parse(_builtAreaController.text)
            : null,
        'hasElevator': _hasElevator,
        'hasHandicapAccess': _hasHandicapAccess,
        'hasPool': _hasPool,
        'hasCableTv': _hasCableTv,
        'address': {
          'address': _addressController.text,
          'addressSuite': _addressSuiteController.text,
          'codePostal': _postalCodeController.text,
          'ville': _cityController.text,
          'etatDep': _stateController.text,
          'pays': _countryController.text,
          'observation': _observationController.text,
        },
      };

      await _adminService.createBuilding(buildingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Immeuble créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Ajouter un immeuble'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Informations Générales'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _buildingLabelController,
              label: 'Nom de l\'immeuble',
              icon: Icons.apartment,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _buildingNumberController,
              label: 'Numéro de bâtiment',
              icon: Icons.numbers,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _yearOfConstructionController,
              label: 'Année de construction',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _numberOfFloorsController,
              label: 'Nombre d\'étages',
              icon: Icons.layers,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _buildingStateController,
              label: 'État du bâtiment',
              icon: Icons.info_outline,
              hint: 'Excellent, Bon, Moyen, À rénover...',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _facadeWidthController,
              label: 'Largeur de la façade (m)',
              icon: Icons.straighten,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Adresse'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Adresse',
              icon: Icons.location_on,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressSuiteController,
              label: 'Complément d\'adresse',
              icon: Icons.add_location,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _postalCodeController,
                    label: 'Code postal',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'Ville',
                    icon: Icons.location_city,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _stateController,
              label: 'État/Département',
              icon: Icons.map,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _countryController,
              label: 'Pays (code ISO3)',
              icon: Icons.flag,
              hint: 'Ex: BEL, FRA, USA',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _observationController,
              label: 'Observations',
              icon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Informations Spécifiques'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _landAreaController,
              label: 'Surface du terrain (m²)',
              icon: Icons.landscape,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _landWidthController,
              label: 'Largeur du terrain (m)',
              icon: Icons.swap_horiz,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _builtAreaController,
              label: 'Surface bâtie (m²)',
              icon: Icons.home_work,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildCheckboxTile(
              title: 'Ascenseur',
              value: _hasElevator,
              onChanged: (value) => setState(() => _hasElevator = value!),
              icon: Icons.elevator,
            ),
            _buildCheckboxTile(
              title: 'Accès handicapé',
              value: _hasHandicapAccess,
              onChanged: (value) =>
                  setState(() => _hasHandicapAccess = value!),
              icon: Icons.accessible,
            ),
            _buildCheckboxTile(
              title: 'Piscine',
              value: _hasPool,
              onChanged: (value) => setState(() => _hasPool = value!),
              icon: Icons.pool,
            ),
            _buildCheckboxTile(
              title: 'Câble TV',
              value: _hasCableTv,
              onChanged: (value) => setState(() => _hasCableTv = value!),
              icon: Icons.tv,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Photos de l\'immeuble'),
            const SizedBox(height: 12),
            _buildImageSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Créer l\'immeuble',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImages[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
