import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/apartment_details_model.dart';
import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';
import '../../services/apartment_details_service.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateClaimScreen extends StatefulWidget {
  const CreateClaimScreen({Key? key}) : super(key: key);

  @override
  State<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends State<CreateClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _causeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();

  final BuildingContextService _contextService = BuildingContextService();
  final ApartmentDetailsService _apartmentService = ApartmentDetailsService();
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedClaimTypes = [];
  List<int> _selectedAffectedApartments = [];
  List<File> _selectedPhotos = [];
  List<ApartmentDto> _buildingApartments = [];
  bool _isLoadingApartments = true;
  int? _userApartmentId;

  @override
  void initState() {
    super.initState();
    _loadUserApartmentAndBuildings();
  }

  Future<void> _loadUserApartmentAndBuildings() async {
    try {
      final buildingId = await _contextService.getSelectedBuildingId();
      if (buildingId != null) {
        final apartments =
            await _apartmentService.getApartmentsByBuilding(buildingId);
        final userApartment =
            await _apartmentService.getCurrentUserApartment(buildingId);

        setState(() {
          _buildingApartments = apartments;
          _userApartmentId = userApartment?.id;
          _isLoadingApartments = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingApartments = false;
      });
    }
  }

  @override
  void dispose() {
    _causeController.dispose();
    _descriptionController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() {
        _selectedPhotos.addAll(images.map((xFile) => File(xFile.path)));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClaimTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner au moins un type de sinistre')),
      );
      return;
    }

    if (_userApartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de déterminer votre appartement')),
      );
      return;
    }

    final claimProvider = Provider.of<ClaimProvider>(context, listen: false);

    final success = await claimProvider.createClaim(
      apartmentId: _userApartmentId!,
      claimTypes: _selectedClaimTypes,
      cause: _causeController.text.trim(),
      description: _descriptionController.text.trim(),
      insuranceCompany: _insuranceCompanyController.text.trim().isEmpty
          ? null
          : _insuranceCompanyController.text.trim(),
      insurancePolicyNumber: _insurancePolicyController.text.trim().isEmpty
          ? null
          : _insurancePolicyController.text.trim(),
      affectedApartmentIds: _selectedAffectedApartments,
      photos: _selectedPhotos,
    );

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinistre déclaré avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(claimProvider.errorMessage ?? 'Erreur inconnue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimProvider = Provider.of<ClaimProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarer un sinistre'),
        elevation: 0,
      ),
      body: _isLoadingApartments
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Type de sinistre/dégât *'),
                    const SizedBox(height: 12),
                    _buildClaimTypesSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Cause du sinistre *'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _causeController,
                      hintText: 'Décrivez la cause du sinistre',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez indiquer la cause';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Description des dégâts *'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Décrivez les dégâts en détail',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez décrire les dégâts';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Assurance RC familiale'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _insuranceCompanyController,
                      hintText: 'Compagnie d\'assurance',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _insurancePolicyController,
                      hintText: 'Numéro de police',
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Appartements touchés'),
                    const SizedBox(height: 8),
                    _buildAffectedApartmentsSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Photos (optionnel)'),
                    const SizedBox(height: 8),
                    _buildPhotosSection(),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Déclarer le sinistre',
                      onPressed: claimProvider.isLoading ? null : _submitClaim,
                      isLoading: claimProvider.isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildClaimTypesSection() {
    return Column(
      children: ClaimType.values.map((type) {
        final isSelected = _selectedClaimTypes.contains(type.value);
        return CheckboxListTile(
          title: Text(type.displayName),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedClaimTypes.add(type.value);
              } else {
                _selectedClaimTypes.remove(type.value);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildAffectedApartmentsSection() {
    if (_buildingApartments.isEmpty) {
      return const Text(
        'Aucun autre appartement disponible',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: _buildingApartments
          .where((apt) => apt.id != _userApartmentId)
          .map((apartment) {
        final isSelected = _selectedAffectedApartments.contains(apartment.id);
        return CheckboxListTile(
          title: Text('Appartement ${apartment.apartmentNumber}'),
          subtitle: apartment.floor != null
              ? Text('Étage ${apartment.floor}')
              : null,
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedAffectedApartments.add(apartment.id);
              } else {
                _selectedAffectedApartments.remove(apartment.id);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (_selectedPhotos.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedPhotos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
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
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter des photos'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
