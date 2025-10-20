import 'package:flutter/material.dart';
import '../../models/building_photo_model.dart';
import '../../services/building_admin_service.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import 'add_apartment_screen.dart';
import 'building_3d_view_screen.dart';
import 'building_photos_screen.dart';
import 'create_building_screen.dart';
import 'building_detail_screen.dart';

class AdminBuildingScreen extends StatefulWidget {
  const AdminBuildingScreen({super.key});

  @override
  State<AdminBuildingScreen> createState() => _AdminBuildingScreenState();
}

class _AdminBuildingScreenState extends State<AdminBuildingScreen> {
  final BuildingAdminService _adminService = BuildingAdminService();
  final BuildingContextService _contextService = BuildingContextService();

  String? _currentBuildingId;
  String? _buildingName;
  List<BuildingPhotoModel> _photos = [];
  List<Map<String, dynamic>> _apartments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildingData();
  }

  Future<void> _loadBuildingData() async {
    setState(() => _isLoading = true);

    try {
      final buildingId = await _contextService.getCurrentBuildingId();
      final buildingName = await _contextService.getCurrentBuildingName();

      if (buildingId != null) {
        final photos = await _adminService.getBuildingPhotos(buildingId);
        final apartments = await _adminService.getApartmentsByBuilding(buildingId);

        setState(() {
          _currentBuildingId = buildingId;
          _buildingName = buildingName ?? 'Immeuble';
          _photos = photos;
          _apartments = apartments;
        });
      }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentBuildingId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestion Immeuble')),
        body: const Center(
          child: Text('Aucun immeuble sélectionné'),
        ),
      );
    }

    final occupiedCount = _apartments.where((apt) => apt['resident'] != null).length;
    final emptyCount = _apartments.length - occupiedCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion - $_buildingName'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBuildingData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(occupiedCount, emptyCount),
              const SizedBox(height: 24),
              _buildActionSection(),
              const SizedBox(height: 24),
              _buildPhotosPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int occupiedCount, int emptyCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Statistiques',
              style: AppTheme.titleStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _apartments.length.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  'Occupés',
                  occupiedCount.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  'Vides',
                  emptyCount.toString(),
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: AppTheme.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.info,
          title: 'Détails de l\'immeuble',
          subtitle: 'Voir toutes les informations',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingDetailScreen(
                  buildingId: _currentBuildingId!,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.apartment,
          title: 'Ajouter un appartement',
          subtitle: 'Créer un nouveau bien dans l\'immeuble',
          color: Colors.green,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddApartmentScreen(
                  buildingId: _currentBuildingId!,
                ),
              ),
            );
            if (result == true) {
              _loadBuildingData();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.photo_library,
          title: 'Gérer les photos',
          subtitle: '${_photos.length} photo(s)',
          color: Colors.purple,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingPhotosScreen(
                  buildingId: _currentBuildingId!,
                  buildingName: _buildingName!,
                ),
              ),
            );
            if (result == true) {
              _loadBuildingData();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.view_in_ar,
          title: 'Vue 3D de l\'immeuble',
          subtitle: 'Visualiser l\'occupation',
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Building3DViewScreen(
                  buildingId: _currentBuildingId!,
                  buildingName: _buildingName!,
                  apartments: _apartments,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosPreview() {
    if (_photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos de l\'immeuble',
          style: AppTheme.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length > 5 ? 5 : _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photo.photoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
