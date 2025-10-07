import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/building_selection_model.dart';
import '../../services/api_service.dart';
import '../../services/building_context_service.dart';

class BuildingSwitchScreen extends StatefulWidget {
  const BuildingSwitchScreen({super.key});

  @override
  State<BuildingSwitchScreen> createState() => _BuildingSwitchScreenState();
}

class _BuildingSwitchScreenState extends State<BuildingSwitchScreen> {
  final ApiService _apiService = ApiService();
  List<BuildingSelection> _buildings = [];
  bool _isLoading = true;
  String? _error;
  String? _currentBuildingId;

  @override
  void initState() {
    super.initState();
    _getCurrentBuildingId();
    _loadUserBuildings();
  }

  void _getCurrentBuildingId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentBuildingId = authProvider.user?.buildingId;
  }

  void _loadUserBuildings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getUserBuildings();
      final buildings = (response as List)
          .map((json) => BuildingSelection.fromJson(json))
          .toList();

      setState(() {
        _buildings = buildings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchBuilding(BuildingSelection building) async {
    // Afficher un dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer d\'immeuble'),
        content: Text('Voulez-vous vous connecter à "${building.buildingLabel}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Changement d\'immeuble...'),
          ],
        ),
      ),
    );
    // Nettoyer toutes les données avant de changer de bâtiment
    BuildingContextService.clearAllProvidersData(context);

    // Forcer la mise à jour du contexte
    BuildingContextService().setBuildingContext(building.buildingId);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.selectBuilding(building.buildingId);

    // Fermer l'indicateur de chargement
    if (mounted) Navigator.of(context).pop();
    if (success && mounted) {
      // Forcer le rechargement des données pour le nouveau bâtiment
      BuildingContextService.forceRefreshForBuilding(context, building.buildingId);

      // Retourner à l'écran principal et recharger les données
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecté à ${building.buildingLabel}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Changer d\'immeuble'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBuildingsList(),
    );
  }

  Widget _buildBuildingsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_error',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserBuildings,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_buildings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun immeuble disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _buildings.length,
      itemBuilder: (context, index) {
        final building = _buildings[index];
        final isCurrentBuilding = building.buildingId == _currentBuildingId;

        return _buildBuildingCard(building, isCurrentBuilding);
      },
    );
  }

  Widget _buildBuildingCard(BuildingSelection building, bool isCurrentBuilding) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentBuilding ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentBuilding
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrentBuilding ? null : () => _switchBuilding(building),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getRoleColor(building.roleInBuilding).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: building.buildingPicture != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        building.buildingPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.apartment,
                            size: 30,
                            color: _getRoleColor(building.roleInBuilding),
                          );
                        },
                      ),
                    )
                        : Icon(
                      Icons.apartment,
                      size: 30,
                      color: _getRoleColor(building.roleInBuilding),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                building.buildingLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (isCurrentBuilding)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Actuel',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (building.buildingNumber != null)
                          Text(
                            'N° ${building.buildingNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildRoleChip(building.roleInBuilding),
                ],
              ),

              const SizedBox(height: 16),

              // Address
              if (building.address != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${building.address!.address}, ${building.address!.ville} ${building.address!.codePostal}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Apartment info
              if (building.apartmentId != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.home,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Appartement ${building.apartmentNumber ?? building.apartmentId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (building.apartmentFloor != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Étage ${building.apartmentFloor}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (building.roleInBuilding == 'BUILDING_ADMIN') ...[
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Administrateur de l\'immeuble',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],

              if (!isCurrentBuilding) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _switchBuilding(building),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getRoleColor(building.roleInBuilding),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color = _getRoleColor(role);
    String label = _getRoleLabel(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'BUILDING_ADMIN':
        return AppTheme.warningColor;
      case 'GROUP_ADMIN':
        return AppTheme.accentColor;
      case 'SUPER_ADMIN':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'BUILDING_ADMIN':
        return 'Admin';
      case 'GROUP_ADMIN':
        return 'Admin Groupe';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return 'Résident';
    }
  }
}