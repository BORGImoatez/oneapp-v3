import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/apartment_details_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/apartment_details_service.dart';
import 'edit_apartment_section_screen.dart';

class MyApartmentScreen extends StatefulWidget {
  final String apartmentId;

  const MyApartmentScreen({
    Key? key,
    required this.apartmentId,
  }) : super(key: key);

  @override
  State<MyApartmentScreen> createState() => _MyApartmentScreenState();
}

class _MyApartmentScreenState extends State<MyApartmentScreen> {
  final ApartmentDetailsService _service = ApartmentDetailsService();
  final ImagePicker _picker = ImagePicker();
  ApartmentDetailsModel? _details;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  bool _hasLoadedOnce = false; // Add this flag

  @override
  void initState() {
    super.initState();
    // Don't call _loadDetails() here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load details only once when dependencies are ready
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadDetails();
    }
  }
  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);


      final details =
      await _service.getApartmentDetails(widget.apartmentId);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);


      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _service.uploadPhoto(
        widget.apartmentId,
         File(image.path),
      );

      Navigator.pop(context);
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo téléchargée avec succès')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);


      await _service.deletePhoto(photoId);
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Appartement'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildPhotoCarousel(),
                        _buildAccordionSections(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPhotoCarousel() {
    final photos = _details?.photos ?? [];

    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Stack(
        children: [
          if (photos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune photo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photo.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.7),
                        ),
                        onPressed: () => _deletePhoto(photo.id),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (photos.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: photos.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _showImageSourceDialog,
              child: const Icon(Icons.add_a_photo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSections() {
    return Column(
      children: [
        _buildAccordionTile(
          title: 'Informations Générales',
          icon: Icons.info_outline,
          content: _buildGeneralInfoContent(),
          section: 'general',
        ),
        _buildAccordionTile(
          title: 'Intérieur',
          icon: Icons.home,
          content: _buildInteriorContent(),
          section: 'interior',
        ),
        _buildAccordionTile(
          title: 'Extérieur',
          icon: Icons.deck,
          content: _buildExteriorContent(),
          section: 'exterior',
        ),
        _buildAccordionTile(
          title: 'Installations',
          icon: Icons.build,
          content: _buildInstallationsContent(),
          section: 'installations',
        ),
        _buildAccordionTile(
          title: 'Énergie',
          icon: Icons.bolt,
          content: _buildEnergieContent(),
          section: 'energie',
        ),
      ],
    );
  }

  Widget _buildAccordionTile({
    required String title,
    required IconData icon,
    required Widget content,
    required String section,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _navigateToEdit(section),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(String section) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditApartmentSectionScreen(
          apartmentId: widget.apartmentId,
          section: section,
          currentData: _details,
        ),
      ),
    );

    if (result == true) {
      _loadDetails();
    }
  }

  Widget _buildGeneralInfoContent() {
    final info = _details?.generalInfo;
    if (info == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Nombre de chambres', info.nbChambres?.toString()),
        _buildInfoRow(
            'Nombre de salles de bain', info.nbSalleBain?.toString()),
        _buildInfoRow('Surface', info.surface != null ? '${info.surface} m²' : null),
        _buildInfoRow('Étage', info.etage?.toString()),
      ],
    );
  }

  Widget _buildInteriorContent() {
    final interior = _details?.interior;
    if (interior == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Quartier/Lieu', interior.quartierLieu),
        _buildInfoRow('Surface habitable',
            interior.surfaceHabitable != null ? '${interior.surfaceHabitable} m²' : null),
        _buildInfoRow('Surface salon',
            interior.surfaceSalon != null ? '${interior.surfaceSalon} m²' : null),
        _buildInfoRow('Type de cuisine', interior.typeCuisine),
        _buildInfoRow('Surface cuisine',
            interior.surfaceCuisine != null ? '${interior.surfaceCuisine} m²' : null),
        _buildInfoRow(
            'Nombre salles de douche', interior.nbSalleDouche?.toString()),
        _buildInfoRow('Nombre toilettes', interior.nbToilette?.toString()),
        _buildInfoRow('Cave', interior.cave == true ? 'Oui' : 'Non'),
        _buildInfoRow('Grenier', interior.grenier == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildExteriorContent() {
    final exterior = _details?.exterior;
    if (exterior == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Surface terrasse',
            exterior.surfaceTerrasse != null ? '${exterior.surfaceTerrasse} m²' : null),
        _buildInfoRow('Orientation terrasse', exterior.orientationTerrasse),
      ],
    );
  }

  Widget _buildInstallationsContent() {
    final installations = _details?.installations;
    if (installations == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            'Ascenseur', installations.ascenseur == true ? 'Oui' : 'Non'),
        _buildInfoRow('Accès handicapé',
            installations.accesHandicap == true ? 'Oui' : 'Non'),
        _buildInfoRow(
            'Parlophone', installations.parlophone == true ? 'Oui' : 'Non'),
        _buildInfoRow('Interphone vidéo',
            installations.interphoneVideo == true ? 'Oui' : 'Non'),
        _buildInfoRow('Porte blindée',
            installations.porteBlindee == true ? 'Oui' : 'Non'),
        _buildInfoRow('Piscine', installations.piscine == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildEnergieContent() {
    final energie = _details?.energie;
    if (energie == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Classe énergétique', energie.classeEnergetique),
        _buildInfoRow(
            'Consommation énergie primaire',
            energie.consommationEnergiePrimaire != null
                ? '${energie.consommationEnergiePrimaire} kWh/m²/an'
                : null),
        _buildInfoRow(
            'Consommation théorique totale',
            energie.consommationTheoriqueTotale != null
                ? '${energie.consommationTheoriqueTotale} kWh/an'
                : null),
        _buildInfoRow('Émission CO2',
            energie.emissionCo2 != null ? '${energie.emissionCo2} kg/m²/an' : null),
        _buildInfoRow('Numéro rapport PEB', energie.numeroRapportPeb),
        _buildInfoRow('Type de chauffage', energie.typeChauffage),
        _buildInfoRow(
            'Double vitrage', energie.doubleVitrage == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non renseigné',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
