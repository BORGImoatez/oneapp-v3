import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/shared_media_model.dart';
import '../../services/shared_media_service.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class SharedMediaScreen extends StatefulWidget {
  final int channelId;
  final String channelName;

  const SharedMediaScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<SharedMediaScreen> createState() => _SharedMediaScreenState();
}

class _SharedMediaScreenState extends State<SharedMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SharedMediaService _mediaService = SharedMediaService();

  List<SharedMediaModel> _allMedia = [];
  List<SharedMediaModel> _images = [];
  List<SharedMediaModel> _videos = [];
  List<SharedMediaModel> _documents = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMedia() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allMediaFuture = _mediaService.getSharedMedia(widget.channelId);
      final imagesFuture = _mediaService.getSharedImages(widget.channelId);
      final videosFuture = _mediaService.getSharedVideos(widget.channelId);
      final documentsFuture = _mediaService.getSharedDocuments(widget.channelId);

      final results = await Future.wait([
        allMediaFuture,
        imagesFuture,
        videosFuture,
        documentsFuture,
      ]);

      setState(() {
        _allMedia = results[0];
        _images = results[1];
        _videos = results[2];
        _documents = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Médias partagés'),
            Text(
              widget.channelName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tout (${_allMedia.length})'),
            Tab(text: 'Photos (${_images.length})'),
            Tab(text: 'Vidéos (${_videos.length})'),
            Tab(text: 'Documents (${_documents.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllMedia,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMediaGrid(_allMedia),
                    _buildMediaGrid(_images),
                    _buildMediaGrid(_videos),
                    _buildDocumentsList(_documents),
                  ],
                ),
    );
  }

  Widget _buildMediaGrid(List<SharedMediaModel> mediaList) {
    if (mediaList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun média partagé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return _buildMediaThumbnail(media);
      },
    );
  }

  Widget _buildMediaThumbnail(SharedMediaModel media) {
    return GestureDetector(
      onTap: () => _showMediaDetail(media),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: media.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
            else if (media.isVideo)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: const Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Icon(
                  _getFileIcon(media.messageType),
                  size: 48,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(List<SharedMediaModel> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun document partagé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return ListTile(
          leading: Icon(_getFileIcon(doc.messageType), size: 40),
          title: Text(doc.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.senderName),
              Text(
                DateFormat('dd/MM/yyyy').format(doc.createdAt),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          onTap: () => _showMediaDetail(doc),
        );
      },
    );
  }

  void _showMediaDetail(SharedMediaModel media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (media.isImage)
                        CachedNetworkImage(
                          imageUrl: media.mediaUrl,
                          fit: BoxFit.contain,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.fileName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Partagé par: ${media.senderName}'),
                            Text('Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(media.createdAt)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String messageType) {
    switch (messageType) {
      case 'IMAGE':
        return Icons.image;
      case 'VIDEO':
        return Icons.video_library;
      case 'AUDIO':
        return Icons.audiotrack;
      case 'FILE':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
