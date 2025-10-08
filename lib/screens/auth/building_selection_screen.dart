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
  List<BuildingSelection> _filteredBuildings = [];
  bool _isLoading = true;
  String? _error;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  final int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _loadUserBuildings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentPage = 0;
      _filterBuildings();
    });
  }

  void _filterBuildings() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredBuildings = List.from(_buildings);
    } else {
      _filteredBuildings = _buildings.where((building) {
        final addressMatch = building.address != null &&
            (building.address!.address.toLowerCase().contains(query) ||
                building.address!.ville.toLowerCase().contains(query) ||
                building.address!.codePostal.toLowerCase().contains(query));
        final labelMatch = building.buildingLabel.toLowerCase().contains(query);
        return addressMatch || labelMatch;
      }).toList();
    }
  }

  List<BuildingSelection> get _paginatedBuildings {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredBuildings.length);
    if (startIndex >= _filteredBuildings.length) return [];
    return _filteredBuildings.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredBuildings.length / _itemsPerPage).ceil();

  bool get _hasNextPage => _currentPage < _totalPages - 1;
  bool get _hasPreviousPage => _currentPage > 0;

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
        _filteredBuildings = buildings;
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

    BuildingContextService.clearAllProvidersData(context);
    BuildingContextService().setBuildingContext(building.buildingId);
    final success = await authProvider.selectBuilding(building.buildingId);

    if (mounted) Navigator.of(context).pop();
    if (success && mounted) {
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

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par adresse...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredBuildings.length} immeuble${_filteredBuildings.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.grid_view,
                          color: _isGridView ? AppTheme.primaryColor : Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = true;
                          });
                        },
                        tooltip: 'Vue grille',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.list,
                          color: !_isGridView ? AppTheme.primaryColor : Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = false;
                          });
                        },
                        tooltip: 'Vue liste',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _buildBuildingsList(),
              ),

              if (_totalPages > 1) ...[
                const SizedBox(height: 16),
                _buildPagination(),
              ],

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

    if (_filteredBuildings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez une autre recherche',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _paginatedBuildings.length,
        itemBuilder: (context, index) {
          final building = _paginatedBuildings[index];
          return _buildBuildingGridCard(building);
        },
      );
    } else {
      return ListView.builder(
        itemCount: _paginatedBuildings.length,
        itemBuilder: (context, index) {
          final building = _paginatedBuildings[index];
          return _buildBuildingCard(building);
        },
      );
    }
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _hasPreviousPage
              ? () {
            setState(() {
              _currentPage--;
            });
          }
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          'Page ${_currentPage + 1} sur $_totalPages',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _hasNextPage
              ? () {
            setState(() {
              _currentPage++;
            });
          }
              : null,
        ),
      ],
    );
  }

  Widget _buildBuildingGridCard(BuildingSelection building) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _selectBuilding(building),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getRoleColor(building.roleInBuilding).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: building.buildingPicture != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        building.buildingPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.apartment,
                            size: 40,
                            color: _getRoleColor(building.roleInBuilding),
                          );
                        },
                      ),
                    )
                        : Icon(
                      Icons.apartment,
                      size: 40,
                      color: _getRoleColor(building.roleInBuilding),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    building.buildingLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (building.address != null)
                    Text(
                      '${building.address!.address}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  if (building.address != null)
                    Text(
                      '${building.address!.ville} ${building.address!.codePostal}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoleChip(building.roleInBuilding),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectBuilding(building),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getRoleColor(building.roleInBuilding),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sélectionner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
