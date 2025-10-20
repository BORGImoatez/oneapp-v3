import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/building_admin_service.dart';
import '../../models/building_photo_model.dart';
import '../../utils/app_theme.dart';

class BuildingDetailScreen extends StatefulWidget {
  final String buildingId;

  const BuildingDetailScreen({
    super.key,
    required this.buildingId,
  });

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  final BuildingAdminService _adminService = BuildingAdminService();
  final PageController _pageController = PageController();

  Map<String, dynamic>? _buildingData;
  List<BuildingPhotoModel> _photos = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBuildingDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildingDetails() async {
    setState(() => _isLoading = true);

    try {
      final building = await _adminService.getBuildingById(widget.buildingId);
      final photos = await _adminService.getBuildingPhotos(widget.buildingId);

      setState(() {
        _buildingData = building;
        _photos = photos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de l\'immeuble')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_buildingData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de l\'immeuble')),
        body: const Center(child: Text('Immeuble introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_buildingData!['buildingLabel'] ?? 'Détails'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBuildingDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAccordionSection(
                      title: 'Informations Générales',
                      icon: Icons.info_outline,
                      color: Colors.blue,
                      children: _buildGeneralInfo(),
                    ),
                    const SizedBox(height: 12),
                    _buildAccordionSection(
                      title: 'Adresse',
                      icon: Icons.location_on,
                      color: Colors.green,
                      children: _buildAddressInfo(),
                    ),
                    const SizedBox(height: 12),
                    _buildAccordionSection(
                      title: 'Informations Spécifiques',
                      icon: Icons.home_work,
                      color: Colors.orange,
                      children: _buildSpecificInfo(),
                    ),
                    const SizedBox(height: 12),
                    _buildAccordionSection(
                      title: 'Équipements',
                      icon: Icons.playlist_add_check,
                      color: Colors.teal,
                      children: _buildFacilitiesInfo(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_photos.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 60, color: Colors.grey),
              SizedBox(height: 8),
              Text('Aucune photo disponible'),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: Image.network(
                  _photos[index].photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 60),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _photos.length,
                effect: WormEffect(
                  dotWidth: 8,
                  dotHeight: 8,
                  spacing: 8,
                  dotColor: Colors.white.withOpacity(0.4),
                  activeDotColor: Colors.white,
                ),
              ),
            ),
          ),
        if (_photos.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_photos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: AppTheme.titleStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }

  List<Widget> _buildGeneralInfo() {
    return [
      _buildInfoRow('Nom', _buildingData!['buildingLabel']),
      _buildInfoRow('Numéro', _buildingData!['buildingNumber']),
      _buildInfoRow(
        'Année de construction',
        _buildingData!['yearOfConstruction']?.toString(),
      ),
      _buildInfoRow(
        'Nombre d\'étages',
        _buildingData!['numberOfFloors']?.toString(),
      ),
      _buildInfoRow('État du bâtiment', _buildingData!['buildingState']),
      _buildInfoRow(
        'Largeur de la façade',
        _buildingData!['facadeWidth'] != null
            ? '${_buildingData!['facadeWidth']} m'
            : null,
      ),
    ];
  }

  List<Widget> _buildAddressInfo() {
    final address = _buildingData!['address'];
    if (address == null) {
      return [const Text('Aucune adresse disponible')];
    }

    return [
      _buildInfoRow('Adresse', address['address']),
      _buildInfoRow('Complément', address['addressSuite']),
      _buildInfoRow('Code postal', address['codePostal']),
      _buildInfoRow('Ville', address['ville']),
      _buildInfoRow('État/Département', address['etatDep']),
      _buildInfoRow('Observations', address['observation']),
    ];
  }

  List<Widget> _buildSpecificInfo() {
    return [
      _buildInfoRow(
        'Surface du terrain',
        _buildingData!['landArea'] != null
            ? '${_buildingData!['landArea']} m²'
            : null,
      ),
      _buildInfoRow(
        'Largeur du terrain',
        _buildingData!['landWidth'] != null
            ? '${_buildingData!['landWidth']} m'
            : null,
      ),
      _buildInfoRow(
        'Surface bâtie',
        _buildingData!['builtArea'] != null
            ? '${_buildingData!['builtArea']} m²'
            : null,
      ),
    ];
  }

  List<Widget> _buildFacilitiesInfo() {
    return [
      _buildBooleanRow(
        'Ascenseur',
        _buildingData!['hasElevator'],
        Icons.elevator,
      ),
      _buildBooleanRow(
        'Accès handicapé',
        _buildingData!['hasHandicapAccess'],
        Icons.accessible,
      ),
      _buildBooleanRow(
        'Piscine',
        _buildingData!['hasPool'],
        Icons.pool,
      ),
      _buildBooleanRow(
        'Câble TV',
        _buildingData!['hasCableTv'],
        Icons.tv,
      ),
    ];
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanRow(String label, bool? value, IconData icon) {
    final isAvailable = value == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isAvailable ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
