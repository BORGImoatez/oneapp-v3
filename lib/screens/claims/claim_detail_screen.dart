import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/claim_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/channel_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';

class ClaimDetailScreen extends StatefulWidget {
  final int claimId;

  const ClaimDetailScreen({Key? key, required this.claimId}) : super(key: key);

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  final StorageService _storageService = StorageService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadClaimAndCheckAdmin();
  }

  Future<void> _loadClaimAndCheckAdmin() async {
    await Provider.of<ClaimProvider>(context, listen: false)
        .loadClaimById(widget.claimId);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = user?.role;
    setState(() {
      _isAdmin = role == 'BUILDING_ADMIN';
    });
  }

  Future<void> _updateStatus(String status) async {
    final claimProvider = Provider.of<ClaimProvider>(context, listen: false);
    final success =
    await claimProvider.updateClaimStatus(widget.claimId, status);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut mis à jour avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(claimProvider.errorMessage ?? 'Erreur inconnue')),
      );
    }
  }

  void _showStatusDialog(ClaimModel claim) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ClaimStatus.values.map((status) {
              return ListTile(
                title: Text(status.displayName),
                leading: Radio<String>(
                  value: status.value,
                  groupValue: claim.status,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.pop(context);
                      _updateStatus(value);
                    }
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(status.value);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoViewer(List<ClaimPhotoModel> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimProvider = Provider.of<ClaimProvider>(context);

    if (claimProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du sinistre')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (claimProvider.selectedClaim == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du sinistre')),
        body: const Center(child: Text('Sinistre non trouvé')),
      );
    }

    final claim = claimProvider.selectedClaim!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du sinistre'),
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showStatusDialog(claim),
              tooltip: 'Modifier le statut',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(claim),
            const Divider(height: 1),
            _buildContent(claim),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ClaimModel claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                profilePictureUrl: claim.reporterAvatar,
                firstName: claim.reporterName,
                lastName:'',
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.reporterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Appartement ${claim.apartmentNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(claim.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatDate(claim.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ClaimModel claim) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Type de sinistre',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: claim.claimTypes.map((type) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getClaimTypeDisplayName(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (claim.emergencyChannelId != null || claim.emergencyFolderId != null) ...[
            const SizedBox(height: 16),
            _buildEmergencySection(claim),
          ],
          const SizedBox(height: 24),
          _buildSection(
            'Cause du sinistre',
            Text(
              claim.cause,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Description des dégâts',
            Text(
              claim.description,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (claim.insuranceCompany != null ||
              claim.insurancePolicyNumber != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Assurance RC familiale',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (claim.insuranceCompany != null)
                    Text(
                      'Compagnie: ${claim.insuranceCompany}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  if (claim.insurancePolicyNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Police N°: ${claim.insurancePolicyNumber}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (claim.affectedApartmentIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Appartements touchés',
              Text(
                '${claim.affectedApartmentIds.length} appartement(s) concerné(s)',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
          if (claim.photos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Photos',
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: claim.photos.length,
                  itemBuilder: (context, index) {
                    final photo = claim.photos[index];
                    return GestureDetector(
                      onTap: () => _showPhotoViewer(claim.photos, index),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(photo.photoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'PENDING':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case 'IN_PROGRESS':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case 'RESOLVED':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'CLOSED':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        ClaimStatus.fromValue(status).displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getClaimTypeDisplayName(String type) {
    try {
      return ClaimType.fromValue(type).displayName;
    } catch (e) {
      return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openEmergencyChannel(ClaimModel claim) async {
    if (claim.emergencyChannelId == null) return;

    try {
      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
      await channelProvider.loadChannelById(claim.emergencyChannelId!);

      final channel = channelProvider.selectedChannel;
      if (channel != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              channel: channel,
              claimId: claim.id,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger le canal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmergencySection(ClaimModel claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Canal d\'urgence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Un canal de discussion et un dossier ont été créés pour ce sinistre.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (claim.emergencyChannelId != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openEmergencyChannel(claim),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Discussion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (claim.emergencyChannelId != null && claim.emergencyFolderId != null)
                const SizedBox(width: 12),
              if (claim.emergencyFolderId != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/files',
                        arguments: {
                          'folderId': claim.emergencyFolderId,
                        },
                      );
                    },
                    icon: Icon(Icons.folder, size: 18, color: Colors.red.shade700),
                    label: Text('Dossier', style: TextStyle(color: Colors.red.shade700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          if (claim.status == 'CLOSED')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce sinistre est clôturé. Le canal est en lecture seule.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<ClaimPhotoModel> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.photos[index].photoUrl,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
