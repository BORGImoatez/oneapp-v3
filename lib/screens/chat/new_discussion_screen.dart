import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class NewDiscussionScreen extends StatefulWidget {
  const NewDiscussionScreen({super.key});

  @override
  State<NewDiscussionScreen> createState() => _NewDiscussionScreenState();
}

class _NewDiscussionScreenState extends State<NewDiscussionScreen> {
  final _searchController = TextEditingController();
  List<User> _filteredResidents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBuildingResidents();
    });
  }

  void _loadBuildingResidents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    final currentBuildingId = authProvider.user?.buildingId;
    print('DEBUG: Loading residents for current building: $currentBuildingId');

    if (currentBuildingId != null) {
      // Mettre à jour le contexte du bâtiment
      BuildingContextService().setBuildingContext(currentBuildingId);

      // Nettoyer seulement les résidents pour éviter de perdre les canaux
      channelProvider.clearBuildingResidents();

      await channelProvider.loadBuildingResidents(currentBuildingId);
    print(channelProvider.buildingResidents.length);
      setState(() {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) => resident.id != authProvider.user?.id)
            .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
            .toList();
        print('DEBUG: Filtered to ${_filteredResidents.length} residents for building $currentBuildingId (excluding current user)');
        for (var resident in _filteredResidents) {
          print('DEBUG: Resident: ${resident.fullName} (ID: ${resident.id}, Building: ${resident.buildingId})');
        }
      });
    } else {
      print('DEBUG: No current building ID found for user');
      setState(() {
        _filteredResidents = [];
      });
    }
  }

  void _filterResidents(String query) {
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    setState(() {
      if (query.isEmpty) {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) => resident.id != authProvider.user?.id)
            .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
            .toList();
      } else {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) =>
        resident.id != authProvider.user?.id &&
            (resident.buildingId == currentBuildingId || resident.buildingId == null) &&
            resident.fullName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _startDiscussion(User resident) async {
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    final channel = await channelProvider.getOrCreateDirectChannel(resident.id);

    if (channel != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(channel: channel),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nouvelle discussion'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un résident...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterResidents,
            ),
          ),

          // Residents List
          Expanded(
            child: Consumer<ChannelProvider>(
              builder: (context, channelProvider, child) {
                if (channelProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (channelProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${channelProvider.error}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBuildingResidents,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredResidents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Aucun résident trouvé'
                              : 'Aucun résultat pour "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredResidents.length,
                  itemBuilder: (context, index) {
                    final resident = _filteredResidents[index];
                    return _buildResidentTile(resident);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentTile(User resident) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: resident.picture != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            resident.picture!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                resident.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        )
            : Text(
          resident.initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        resident.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Appartement ${resident.apartmentId ?? 'Non assigné'}',
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.chat_bubble_outline,
        color: AppTheme.primaryColor,
      ),
      onTap: () => _startDiscussion(resident),
    );
  }
}