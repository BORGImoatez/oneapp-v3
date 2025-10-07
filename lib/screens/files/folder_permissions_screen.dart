import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../models/building_members_model.dart';
import '../../services/document_service.dart';
import '../../utils/app_theme.dart';

class FolderPermissionsScreen extends StatefulWidget {
  final FolderModel folder;

  const FolderPermissionsScreen({
    super.key,
    required this.folder,
  });

  @override
  State<FolderPermissionsScreen> createState() =>
      _FolderPermissionsScreenState();
}

class _FolderPermissionsScreenState extends State<FolderPermissionsScreen> {
  final DocumentService _documentService = DocumentService();
  BuildingMembersModel? _buildingMembers;
  List<ResidentSummary> _filteredResidents = [];
  bool _isLoading = true;
  String? _error;

  String _shareType = 'PRIVATE';
  final Set<String> _selectedResidentIds = {};
  bool _allowUpload = false;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedFloor;
  List<String> _availableFloors = [];

  @override
  void initState() {
    super.initState();
    _shareType = widget.folder.shareType;
    _allowUpload = widget.folder.permissions.any((p) => p.canUpload);

    for (var permission in widget.folder.permissions) {
      if (permission.residentId != null) {
        _selectedResidentIds.add(permission.residentId!);
      }
    }

    _loadBuildingMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildingMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final members = await _documentService.getBuildingMembers();

      if (mounted) {
        final floors = members.residents
            .where((r) => r.floor != null && r.floor!.isNotEmpty)
            .map((r) => r.floor!)
            .toSet()
            .toList();
        floors.sort();

        setState(() {
          _buildingMembers = members;
          _filteredResidents = members.residents;
          _availableFloors = floors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (_buildingMembers == null) return;

    List<ResidentSummary> filtered = _buildingMembers!.residents;

    if (_selectedFloor != null) {
      filtered = filtered.where((r) => r.floor == _selectedFloor).toList();
    }

    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final fullName = r.fullName.toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredResidents = filtered;
    });
  }

  Future<void> _savePermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _documentService.updateFolderPermissions(
        folderId: widget.folder.id,
        shareType: _shareType,
        sharedResidentIds: _selectedResidentIds.toList(),
        sharedApartmentIds: [],
        allowUpload: _allowUpload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les permissions'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _savePermissions,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBuildingMembers,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFolderInfo(),
        const SizedBox(height: 24),
        _buildShareTypeSection(),
        if (_shareType == 'SPECIFIC_APARTMENTS') ...[
          const SizedBox(height: 24),
          _buildAllowUploadSection(),
          const SizedBox(height: 24),
          _buildFiltersSection(),
          const SizedBox(height: 16),
          _buildResidentsSection(),
        ],
      ],
    );
  }

  Widget _buildFolderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folder.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.folder.documentCount} fichier(s)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de partage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildShareTypeOption(
              'PRIVATE',
              'Privé',
              'Visible uniquement par le créateur',
              Icons.lock,
            ),
            const SizedBox(height: 12),
            _buildShareTypeOption(
              'ALL_APARTMENTS',
              'Tous les résidents de l\'immeuble',
              'Tous les résidents peuvent voir (lecture seule)',
              Icons.group,
            ),
            const SizedBox(height: 12),
            _buildShareTypeOption(
              'SPECIFIC_APARTMENTS',
              'Résidents spécifiques',
              'Sélectionner les résidents avec permissions personnalisées',
              Icons.people_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTypeOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _shareType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _shareType = value;
          if (value != 'SPECIFIC_APARTMENTS') {
            _selectedResidentIds.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Autoriser l\'upload',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les résidents peuvent ajouter des fichiers',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _allowUpload,
              onChanged: (value) {
                setState(() {
                  _allowUpload = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou prénom',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _applyFilters(),
            ),
            if (_availableFloors.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedFloor,
                decoration: InputDecoration(
                  hintText: 'Filtrer par étage',
                  prefixIcon: const Icon(Icons.layers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tous les étages'),
                  ),
                  ..._availableFloors.map((floor) {
                    return DropdownMenuItem<String>(
                      value: floor,
                      child: Text('Étage $floor'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                  });
                  _applyFilters();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResidentsSection() {
    if (_buildingMembers == null || _filteredResidents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun résident trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Résidents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedResidentIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedResidentIds.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_filteredResidents.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedResidentIds.length ==
                            _filteredResidents.length) {
                          for (var resident in _filteredResidents) {
                            _selectedResidentIds.remove(resident.id);
                          }
                        } else {
                          for (var resident in _filteredResidents) {
                            _selectedResidentIds.add(resident.id);
                          }
                        }
                      });
                    },
                    child: Text(
                      _selectedResidentIds.length == _filteredResidents.length
                          ? 'Tout désélectionner'
                          : 'Tout sélectionner',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._filteredResidents.map((resident) {
              final isSelected = _selectedResidentIds.contains(resident.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedResidentIds.add(resident.id);
                    } else {
                      _selectedResidentIds.remove(resident.id);
                    }
                  });
                },
                title: Text(
                  resident.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  resident.displayInfo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                activeColor: AppTheme.primaryColor,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
}
