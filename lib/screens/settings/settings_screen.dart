import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'building_switch_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            _buildProfileSection(context),

            const SizedBox(height: 20),

            // Settings Sections
            _buildSettingsSection(
              title: 'Compte',
              items: [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Profil',
                  subtitle: 'Modifier vos informations personnelles',
                  onTap: () {
                    // Navigate to profile screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.security,
                  title: 'Sécurité',
                  subtitle: 'Mot de passe et authentification',
                  onTap: () {
                    // Navigate to security screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.apartment,
                  title: 'Changer d\'immeuble',
                  subtitle: 'Sélectionner un autre immeuble',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BuildingSwitchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'Notifications',
              items: [
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications push',
                  subtitle: 'Gérer les notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Toggle notifications
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                _buildSettingsItem(
                  icon: Icons.volume_up_outlined,
                  title: 'Sons',
                  subtitle: 'Sons des messages et notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Toggle sounds
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'Confidentialité',
              items: [
                _buildSettingsItem(
                  icon: Icons.visibility_outlined,
                  title: 'Statut en ligne',
                  subtitle: 'Afficher votre statut aux autres',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Toggle online status
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                _buildSettingsItem(
                  icon: Icons.block,
                  title: 'Utilisateurs bloqués',
                  subtitle: 'Gérer les utilisateurs bloqués',
                  onTap: () {
                    // Navigate to blocked users screen
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'Support',
              items: [
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Aide',
                  subtitle: 'FAQ et support',
                  onTap: () {
                    // Navigate to help screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'Version et informations',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.bug_report_outlined,
                  title: 'Signaler un problème',
                  subtitle: 'Nous faire part d\'un bug',
                  onTap: () {
                    // Navigate to bug report screen
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor,
                child: user?.picture != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    user!.picture!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                )
                    : Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (user?.apartmentId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Appartement ${user!.apartmentId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MGI',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.apartment,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text('Messagerie Gestion Immobilière'),
        const SizedBox(height: 16),
        const Text(
          'Application de messagerie pour la gestion des communications dans les immeubles résidentiels.',
        ),
      ],
    );
  }
}