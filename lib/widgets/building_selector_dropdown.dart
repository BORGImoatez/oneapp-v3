import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/building_selection_model.dart';
import '../services/building_context_service.dart';
import '../utils/app_theme.dart';

class BuildingSelectorDropdown extends StatelessWidget {
  const BuildingSelectorDropdown({super.key});

  void _showBuildingsList(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.availableBuildings.isEmpty) {
      authProvider.loadAvailableBuildings();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.apartment, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Mes biens',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (authProvider.availableBuildings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Aucun bien disponible'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: authProvider.availableBuildings.length,
                    itemBuilder: (context, index) {
                      final building = authProvider.availableBuildings[index];
                      final isActive = building.buildingId == authProvider.user?.buildingId;

                      return _BuildingListItem(
                        building: building,
                        isActive: isActive,
                        onTap: () async {
                          // Capture parentContext avant fermeture
                          final parentContext = Navigator.of(context).context;
                          Navigator.pop(context);

                          if (!isActive) {
                            // Affiche le dialog de confirmation avant de changer
                            final confirmed = await showDialog<bool>(
                              context: parentContext,
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

                            if (confirmed == true) {
                              await _switchBuilding(parentContext, building);
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchBuilding(BuildContext parentContext, BuildingSelection building) async {
    final authProvider = Provider.of<AuthProvider>(parentContext, listen: false);

    bool isDialogShowing = false;

    try {
      // Affiche le loader
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          isDialogShowing = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Changement de bien...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      await authProvider.selectBuilding(building.buildingId);

      if (parentContext.mounted && isDialogShowing) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isDialogShowing = false;
      }

      if (parentContext.mounted) {
        BuildingContextService.clearAllProvidersData(parentContext);
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (parentContext.mounted) {
        BuildingContextService.forceRefreshForBuilding(parentContext, building.buildingId);
      }

      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Connecté à ${building.buildingLabel}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (parentContext.mounted && isDialogShowing) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isDialogShowing = false;
      }

      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
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
    return IconButton(
      onPressed: () => _showBuildingsList(context),
      icon: const Icon(Icons.list_alt),
      tooltip: 'Mes biens',
    );
  }
}

class _BuildingListItem extends StatelessWidget {
  final BuildingSelection building;
  final bool isActive;
  final VoidCallback onTap;

  const _BuildingListItem({
    required this.building,
    required this.isActive,
    required this.onTap,
  });

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'OWNER':
        return 'Propriétaire';
      case 'TENANT':
        return 'Locataire';
      case 'BUILDING_ADMIN':
        return 'Administrateur';
      case 'RESIDENT':
        return 'Résident';
      default:
        return role ?? 'Résident';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'OWNER':
        return Colors.purple;
      case 'TENANT':
        return Colors.blue;
      case 'BUILDING_ADMIN':
        return Colors.orange;
      case 'RESIDENT':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.apartment,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          building.buildingLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(building.roleInBuilding).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getRoleColor(building.roleInBuilding),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getRoleLabel(building.roleInBuilding),
                          style: TextStyle(
                            color: _getRoleColor(building.roleInBuilding),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          building.address!.codePostal + building.address!.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isActive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.login,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
