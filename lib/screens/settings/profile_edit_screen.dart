import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();

  late TextEditingController _fnameController;
  late TextEditingController _lnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _fnameController = TextEditingController(text: user?.fname);
    _lnameController = TextEditingController(text: user?.lname);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _profilePictureUrl = user?.picture;
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.getToken();

    if (token == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final updatedUser = await _profileService.uploadProfilePicture(
        token: token,
        imageFile: imageFile,
      );

      print('DEBUG: Updated user picture: ${updatedUser.picture}');
      setState(() => _profilePictureUrl = updatedUser.picture);
      authProvider.updateUser(updatedUser);
      print('DEBUG: Local state updated, picture URL: $_profilePictureUrl');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.getToken();

    if (token == null) return;

    setState(() => _isUploadingImage = true);

    try {
      await _profileService.deleteProfilePicture(token);

      setState(() => _profilePictureUrl = null);

      final user = authProvider.user!;
      final updatedUser = user;
      authProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.getToken();

    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = await _profileService.updateProfile(
        token: token,
        fname: _fnameController.text,
        lname: _lnameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      authProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = await authProvider.getToken();

              if (token == null) return;

              try {
                await _profileService.changePassword(
                  token: token,
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe changé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        child: _isUploadingImage
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Builder(
                            builder: (context) {
                              final imageUrl = '${Constants.baseUrl}$_profilePictureUrl';
                              print('DEBUG ProfileEdit: Loading image from: $imageUrl');
                              return Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    print('DEBUG ProfileEdit: Image loaded');
                                    return child;
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('DEBUG ProfileEdit: Error loading image: $error');
                                  return Text(
                                    user?.initials ?? 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )
                            : Text(
                          user?.initials ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'upload') {
                                _pickImage();
                              } else if (value == 'delete') {
                                _deleteProfilePicture();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'upload',
                                child: Text('Télécharger une photo'),
                              ),
                              if (_profilePictureUrl != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer la photo'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fnameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre prénom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lnameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Changer le mot de passe',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
