import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/building_selection_model.dart';
import '../../services/api_service.dart';
import '../../services/building_context_service.dart';

class BuildingSelectionScreen extends StatefulWidget {
  const BuildingSelectionScreen({super.key});

  @override
  State<BuildingSelectionScreen> createState() => _BuildingSelectionScreenState();
}

class _BuildingSelectionScreenState extends State<BuildingSelectionScreen> {
  final ApiService _apiService = ApiService();
  List<BuildingSelection> _buildings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserBuildings();
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

  void _selectBuilding(BuildingSelection building) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connexion en cours...'),
          ],
        ),
      ),
    );

    // Nettoyer toutes les données avant de changer de bâtiment
    BuildingContextService.clearAllProvidersData(context);

    // Forcer la mise à jour du contexte
    BuildingContextService().setBuildingContext(building.buildingId);
    final success = await authProvider.selectBuilding(building.buildingId);

    // Fermer l'indicateur de chargement
    if (mounted) Navigator.of(context).pop();
    if (success && mounted) {
      // Forcer le rechargement des données pour le nouveau bâtiment
      BuildingContextService.forceRefreshForBuilding(context, building.buildingId);

      Navigator.of(context).pushReplacementNamed('/main');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.apartment,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sélectionner un immeuble',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choisissez l\'immeuble pour cette session',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Buildings List
              Expanded(
                child: _buildBuildingsList(),
              ),

              // Error Message
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              'Aucun immeuble trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contactez un administrateur',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _buildings.length,
      itemBuilder: (context, index) {
        final building = _buildings[index];
        return _buildBuildingCard(building);
      },
    );
  }

  Widget _buildBuildingCard(BuildingSelection building) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _selectBuilding(building),
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
                        Text(
                          building.buildingLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
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

              const SizedBox(height: 16),

              // Select Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _selectBuilding(building),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRoleColor(building.roleInBuilding),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sélectionner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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