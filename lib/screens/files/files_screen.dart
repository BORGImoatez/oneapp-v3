import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/folder_model.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import 'folder_permissions_screen.dart';
import 'dart:io';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final DocumentService _documentService = DocumentService();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadRootFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: _buildAppBar(documentProvider),
          body: Column(
            children: [
              if (documentProvider.navigationStack.isNotEmpty)
                _buildBreadcrumb(documentProvider),
              Expanded(child: _buildBody(documentProvider)),
            ],
          ),
          floatingActionButton: _buildFloatingActionButtons(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(DocumentProvider documentProvider) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.folder_open, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              documentProvider.currentFolder?.name ?? 'Mes Documents',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: documentProvider.canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                documentProvider.goBack();
              },
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog(documentProvider);
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            documentProvider.refresh();
          },
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(DocumentProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBreadcrumbItem(
              icon: Icons.home,
              label: 'Accueil',
              isLast: provider.navigationStack.isEmpty,
              onTap: () {
                if (provider.navigationStack.isNotEmpty) {
                  provider.loadRootFolders();
                }
              },
            ),
            for (int i = 0; i < provider.navigationStack.length; i++)
              _buildBreadcrumbItem(
                icon: Icons.chevron_right,
                label: provider.navigationStack[i].name,
                isLast: i == provider.navigationStack.length - 1,
                onTap: () {
                  if (i < provider.navigationStack.length - 1) {
                    while (provider.navigationStack.length > i + 1) {
                      provider.navigationStack.removeLast();
                    }
                    provider.refresh();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem({
    required IconData icon,
    required String label,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        if (icon != Icons.home)
          Icon(icon, size: 16, color: Colors.grey[400]),
        InkWell(
          onTap: isLast ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (icon == Icons.home)
                  Icon(icon, size: 16, color: isLast ? AppTheme.primaryColor : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                    color: isLast ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(DocumentProvider documentProvider) {
    if (documentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (documentProvider.error != null) {
      return _buildErrorView(documentProvider);
    }

    final folders = documentProvider.folders;
    final documents = documentProvider.documents;

    if (folders.isEmpty && documents.isEmpty) {
      return _buildEmptyView();
    }

    if (_isGridView) {
      return _buildGridView(folders, documents, documentProvider);
    } else {
      return _buildListView(folders, documents, documentProvider);
    }
  }

  Widget _buildErrorView(DocumentProvider documentProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              documentProvider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                documentProvider.clearError();
                documentProvider.refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun fichier',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez un dossier ou uploadez un fichier\npour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<FolderModel> folders, List<DocumentModel> documents, DocumentProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (folders.isNotEmpty) ...[
          _buildSectionHeader('Dossiers', folders.length),
          const SizedBox(height: 12),
          ...folders.map((folder) => _buildFolderListItem(folder, provider)),
          const SizedBox(height: 24),
        ],
        if (documents.isNotEmpty) ...[
          _buildSectionHeader('Fichiers', documents.length),
          const SizedBox(height: 12),
          ...documents.map((document) => _buildDocumentListItem(document, provider)),
        ],
      ],
    );
  }

  Widget _buildGridView(List<FolderModel> folders, List<DocumentModel> documents, DocumentProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: folders.length + documents.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return _buildFolderGridItem(folders[index], provider);
        } else {
          return _buildDocumentGridItem(documents[index - folders.length], provider);
        }
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderListItem(FolderModel folder, DocumentProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            if (folder.shareType != 'PRIVATE')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: folder.shareType == 'ALL_APARTMENTS'
                        ? Colors.green
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    folder.shareType == 'ALL_APARTMENTS'
                        ? Icons.group
                        : Icons.people_outline,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                folder.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (folder.shareType != 'PRIVATE')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: folder.shareType == 'ALL_APARTMENTS'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  folder.shareType == 'ALL_APARTMENTS' ? 'Tous' : 'Partagé',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: folder.shareType == 'ALL_APARTMENTS'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${folder.subFolderCount} dossiers • ${folder.documentCount} fichiers',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        trailing: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isCreator = authProvider.currentUserId == folder.createdBy;
            return PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              itemBuilder: (context) => [
                if (isCreator)
                  const PopupMenuItem(
                    value: 'permissions',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 12),
                        Text('Gérer les permissions'),
                      ],
                    ),
                  ),
                if (isCreator)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                if (!isCreator)
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Informations'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteFolder(folder, provider);
                } else if (value == 'permissions') {
                  _openPermissionsDialog(folder, provider);
                } else if (value == 'info') {
                  _showFolderInfo(folder);
                }
              },
            );
          },
        ),
        onTap: () {
          provider.openFolder(folder);
        },
      ),
    );
  }

  Widget _buildFolderGridItem(FolderModel folder, DocumentProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          provider.openFolder(folder);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.folder,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                folder.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${folder.subFolderCount + folder.documentCount} éléments',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(DocumentModel document, DocumentProvider provider) {
    final iconData = _getDocumentIcon(document);
    final iconColor = _getDocumentColor(document);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          document.originalFilename,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.getFormattedSize(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (document.description != null && document.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    document.description!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Aperçu'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Télécharger'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDeleteDocument(document, provider);
            } else if (value == 'download') {
              _downloadDocument(document);
            } else if (value == 'preview') {
              _previewDocument(document);
            }
          },
        ),
        onTap: () {
          _previewDocument(document);
        },
      ),
    );
  }

  Widget _buildDocumentGridItem(DocumentModel document, DocumentProvider provider) {
    final iconData = _getDocumentIcon(document);
    final iconColor = _getDocumentColor(document);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _previewDocument(document);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                document.originalFilename,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                document.getFormattedSize(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentModel document) {
    if (document.isImage) return Icons.image;
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getDocumentColor(DocumentModel document) {
    if (document.isImage) return Colors.blue;
    if (document.isPdf) return Colors.red;
    if (document.isDocument) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "create_folder_fab",
          onPressed: _showCreateFolderDialog,
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.create_new_folder),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "upload_file_fab",
          onPressed: _showUploadFileDialog,
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.upload_file),
        ),
      ],
    );
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau dossier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du dossier',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.folder),
                  errorText: errorText,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  setState(() {
                    errorText = 'Le nom du dossier est obligatoire';
                  });
                } else {
                  context
                      .read<DocumentProvider>()
                      .createFolder(nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadFileDialog() async {
    final file = await _documentService.pickFile();
    if (file == null) return;

    if (!mounted) return;

    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uploader un fichier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file.path.split('/').last,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DocumentProvider>().uploadDocument(
                    file,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: const Text('Uploader'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPermissionsDialog(FolderModel folder, DocumentProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderPermissionsScreen(folder: folder),
      ),
    );

    if (result == true) {
      provider.refresh();
    }
  }

  void _confirmDeleteFolder(FolderModel folder, DocumentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer le dossier "${folder.name}" et tout son contenu ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteFolder(folder.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDocument(DocumentModel document, DocumentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer le fichier "${document.originalFilename}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteDocument(document.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(DocumentModel document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Téléchargement de ${document.originalFilename}...'),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _previewDocument(DocumentModel document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Aperçu de ${document.originalFilename}'),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showSearchDialog(DocumentProvider provider) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Rechercher un fichier',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.trim().isNotEmpty) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showFolderInfo(FolderModel folder) {
    String shareTypeText;
    switch (folder.shareType) {
      case 'PRIVATE':
        shareTypeText = 'Privé';
        break;
      case 'ALL_APARTMENTS':
        shareTypeText = 'Tous les résidents';
        break;
      case 'SPECIFIC_APARTMENTS':
        shareTypeText = 'Résidents spécifiques';
        break;
      default:
        shareTypeText = folder.shareType;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Type de partage',
              shareTypeText,
              Icons.share,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Sous-dossiers',
              folder.subFolderCount.toString(),
              Icons.folder_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Fichiers',
              folder.documentCount.toString(),
              Icons.insert_drive_file,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Permissions',
              folder.canUpload ? 'Lecture et écriture' : 'Lecture seule',
              folder.canUpload ? Icons.edit : Icons.visibility,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
