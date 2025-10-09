import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../models/user_model.dart';

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<User> _selectedMembers = [];

  bool _isPrivate = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBuildingResidents();
    });
  }

  void _loadBuildingResidents() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    final currentBuildingId = authProvider.user?.buildingId;
    print('DEBUG: Loading residents for channel creation in building: $currentBuildingId');

    if (currentBuildingId != null) {
      // Mettre à jour le contexte du bâtiment
      BuildingContextService().setBuildingContext(currentBuildingId);

      // Nettoyer seulement les résidents pour éviter de perdre les canaux
      channelProvider.clearBuildingResidents();
      channelProvider.loadBuildingResidents(currentBuildingId);
    } else {
      print('DEBUG: No current building ID found for channel creation');
    }
  }

  void _createChannel() async {
    if (_formKey.currentState!.validate()) {
      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le sujet du canal est obligatoire'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
      final currentBuildingId = BuildingContextService().currentBuildingId;

      final channelData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': 'GROUP',
        'isPrivate': _isPrivate,
        'memberIds': _selectedMembers.map((user) => user.id).toList(),
        'buildingId':currentBuildingId
      };

      final channel = await channelProvider.createChannel(channelData);

      if (channel != null && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canal créé avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showMemberSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMemberSelectionSheet(),
    );
  }

  Widget _buildMemberSelectionSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ajouter des membres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<ChannelProvider>(
              builder: (context, channelProvider, child) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentBuildingId = authProvider.user?.buildingId;
                final residents = channelProvider.buildingResidents
                    .where((resident) => resident.id != authProvider.user?.id)
                    .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
                    .toList();

                if (channelProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (residents.isEmpty) {
                  return const Center(
                    child: Text('Aucun résident trouvé dans l\'immeuble actuel'),
                  );
                }

                return ListView.builder(
                  itemCount: residents.length,
                  itemBuilder: (context, index) {
                    final resident = residents[index];
                    final isSelected = _selectedMembers.any((m) => m.id == resident.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedMembers.add(resident);
                          } else {
                            _selectedMembers.removeWhere((m) => m.id == resident.id);
                          }
                        });
                      },
                      title: Text(resident.fullName),
                      subtitle: Text('Appartement ${resident.apartmentId ?? 'Non assigné'}'),
                      secondary: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          resident.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      activeColor: AppTheme.primaryColor,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text('Ajouter (${_selectedMembers.length})'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur est admin
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user?.role != 'BUILDING_ADMIN' &&
        user?.role != 'GROUP_ADMIN' &&
        user?.role != 'SUPER_ADMIN') {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Accès refusé'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Accès refusé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Seuls les administrateurs peuvent créer des canaux',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Créer un canal'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Channel Name
              CustomTextField(
                controller: _nameController,
                label: 'Nom du canal',
                hint: 'Entrez le nom du canal',
                prefixIcon: Icons.forum,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un nom';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Sujet (obligatoire)
              CustomTextField(
                controller: _descriptionController,
                label: 'Sujet du canal',
                hint: 'Décrivez le sujet de discussion',
                prefixIcon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le sujet est obligatoire';
                  }
                  if (value.length < 10) {
                    return 'Le sujet doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Membres sélectionnés
              _buildSelectedMembers(),

              const SizedBox(height: 20),

              // Ajouter des membres
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person_add, color: AppTheme.primaryColor),
                  title: const Text('Ajouter des membres'),
                  subtitle: Text('${_selectedMembers.length} membre(s) sélectionné(s)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showMemberSelection,
                ),
              ),

              const SizedBox(height: 24),

              // Paramètres de confidentialité
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Canal privé'),
                  subtitle: const Text('Seuls les membres ajoutés peuvent voir le canal'),
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 40),

              // Create Button
              Consumer<ChannelProvider>(
                builder: (context, channelProvider, child) {
                  return CustomButton(
                    text: 'Créer le canal',
                    onPressed: channelProvider.isLoading ? null : _createChannel,
                    isLoading: channelProvider.isLoading,
                    icon: Icons.add,
                  );
                },
              ),

              // Error Message
              Consumer<ChannelProvider>(
                builder: (context, channelProvider, child) {
                  if (channelProvider.error != null) {
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        channelProvider.error!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMembers() {
    if (_selectedMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membres sélectionnés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _selectedMembers.map((member) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(member.fullName),
                subtitle: Text('Appartement ${member.apartmentId ?? 'Non assigné'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                  onPressed: () {
                    setState(() {
                      _selectedMembers.removeWhere((m) => m.id == member.id);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}