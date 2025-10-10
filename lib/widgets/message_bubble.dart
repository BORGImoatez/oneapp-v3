import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'package:dio/dio.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 360 ? screenWidth * 0.8 : screenWidth * 0.75;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                message.senderId.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.myMessageColor : AppTheme.otherMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyToId != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Réponse à un message',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  _buildMessageContent(context),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isDeleted) {
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white70 : Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.type.toString()) {
      case 'MessageType.IMAGE':
      case 'IMAGE':
        return _buildImageMessage();
      case 'MessageType.FILE':
      case 'FILE':
        return _buildFileMessage(context);
      case 'MessageType.AUDIO':
      case 'AUDIO':
        return _buildAudioMessage();
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.textPrimary,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _downloadImage(message.content),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxImageWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;
                    return Image.network(
                      message.content,
                      width: maxImageWidth.clamp(150.0, 250.0),
                      fit: BoxFit.cover,
                      headers: const {
                        'Accept': 'image/*',
                      },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final maxImageWidth = constraints.maxWidth > 0 ? constraints.maxWidth.clamp(150.0, 250.0) : 200.0;
                  return Container(
                    width: maxImageWidth,
                    height: maxImageWidth * 0.75,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            '${((loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)) * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  final maxImageWidth = constraints.maxWidth > 0 ? constraints.maxWidth.clamp(150.0, 250.0) : 200.0;
                  return Container(
                    width: maxImageWidth,
                    height: maxImageWidth * 0.75,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image non disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Télécharger',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Note: Pas besoin de permission pour écrire dans l'espace privé de l'app

      // Utiliser le répertoire approprié selon la plateforme
      Directory? directory;
      if (Platform.isAndroid) {
        // Sur Android, utiliser getExternalStorageDirectory()
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Créer un sous-dossier Images dans notre espace app
          final imagesDir = Directory('${directory.path}/Images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          directory = imagesDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        print('DEBUG: Impossible d\'obtenir le répertoire');
        return;
      }

      final fileName = 'MGI_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      print('DEBUG: Téléchargement de l\'image depuis: $imageUrl');
      print('DEBUG: Vers: $filePath');

      final dio = Dio();
      await dio.download(
        imageUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Téléchargement image: $progress%');
          }
        },
      );

      print('DEBUG: Image téléchargée avec succès: $filePath');
    } catch (e) {
      print('DEBUG: Erreur lors du téléchargement de l\'image: $e');
    }
  }

  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.fileAttachment?.originalFilename ??
        message.content.split('/').last.split('?').first;

    return InkWell(
      onTap: () => _downloadFile(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isMe ? Colors.white : AppTheme.primaryColor).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(fileName),
              color: isMe ? Colors.white : AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (message.fileAttachment?.fileSize != null)
                        Text(
                          _formatFileSize(message.fileAttachment!.fileSize),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.download,
                        size: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Télécharger',
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    // Obtenir l'URL de téléchargement
    String? downloadUrl = message.fileAttachment?.downloadUrl;

    // Si pas de downloadUrl dans fileAttachment, utiliser message.content comme fallback
    if (downloadUrl == null || downloadUrl.isEmpty) {
      downloadUrl = message.content;
    }

    // Vérifier que nous avons une URL valide
    if (downloadUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL de téléchargement non disponible'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('DEBUG: Tentative de téléchargement du fichier depuis: $downloadUrl');

    try {
      // Note: Pas besoin de permission pour écrire dans getExternalStorageDirectory()
      // sur Android (espace privé de l'app) ou getApplicationDocumentsDirectory() sur iOS

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Téléchargement en cours...'),
              ],
            ),
          ),
        );
      }

      // Utiliser le répertoire approprié selon la plateforme
      Directory? directory;
      if (Platform.isAndroid) {
        // Sur Android, utiliser getExternalStorageDirectory() qui pointe vers
        // /storage/emulated/0/Android/data/[package]/files
        // C'est accessible sans permission spéciale sur Android 10+
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Créer un sous-dossier Downloads dans notre espace app
          final downloadDir = Directory('${directory.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          directory = downloadDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Impossible d\'obtenir le répertoire de téléchargement');
      }

      final fileName = message.fileAttachment?.originalFilename ??
          downloadUrl.split('/').last.split('?').first;
      final filePath = '${directory.path}/$fileName';

      print('DEBUG: Téléchargement vers: $filePath');

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Téléchargement: $progress%');
          }
        },
      );

      print('DEBUG: Fichier téléchargé avec succès: $filePath');

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        final locationMsg = Platform.isAndroid
            ? 'Fichiers de l\'app > Downloads'
            : 'Documents de l\'app';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ Fichier téléchargé: $fileName'),
                const SizedBox(height: 4),
                Text(
                  'Emplacement: $locationMsg',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final result = await OpenFilex.open(filePath);
                  print('DEBUG: Résultat d\'ouverture du fichier: ${result.message}');
                } catch (e) {
                  print('DEBUG: Erreur lors de l\'ouverture: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Impossible d\'ouvrir: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }

    } catch (e) {
      print('DEBUG: Erreur lors du téléchargement: $e');

      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }


  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildAudioMessage() {
    return AudioMessageWidget(
      audioUrl: message.content,
      isMe: isMe,
      messageId: message.id.toString(),
    );
  }
}

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final String messageId;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.messageId,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _downloadAudioFile();
  }

  Future<void> _downloadAudioFile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Vérifier si l'URL est locale ou distante
      if (widget.audioUrl.startsWith('http')) {
        // Obtenir le répertoire temporaire
        final directory = await getTemporaryDirectory();
        final fileName = 'audio_${widget.messageId}.aac';
        final filePath = '${directory.path}/$fileName';

        // Vérifier si le fichier existe déjà
        final file = File(filePath);
        if (await file.exists()) {
          _localFilePath = filePath;
          await _setAudioSource();
          return;
        }

        // Télécharger le fichier
        final dio = Dio();
        await dio.download(widget.audioUrl, filePath);

        _localFilePath = filePath;
        await _setAudioSource();
      } else {
        // Fichier local
        _localFilePath = widget.audioUrl;
        await _setAudioSource();
      }

    } catch (e) {
      print('Error downloading audio file: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setAudioSource() async {
    if (_localFilePath == null) return;

    try {
      // Vérifier que le fichier existe
      final file = File(_localFilePath!);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $_localFilePath');
      }

      // Vérifier la taille du fichier
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Audio file is empty');
      }

      print('Audio file exists: $_localFilePath, size: $fileSize bytes');
      await _audioPlayer.setSourceDeviceFile(_localFilePath!);
      print('Audio source set successfully: $_localFilePath');
    } catch (e) {
      print('Error setting audio source: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _initializeAudio() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });
  }

  void _togglePlayPause() async {
    if (_localFilePath == null) {
      print('Audio file not ready yet, downloading...');
      await _downloadAudioFile();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Essayer de reprendre, sinon jouer depuis le début
        try {
          await _audioPlayer.resume();
        } catch (e) {
          print('Resume failed, trying to play from start: $e');
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture audio: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isMe ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              )
                  : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de progression
                GestureDetector(
                  onTapDown: (details) {
                    if (_duration.inMilliseconds > 0) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final progress = localPosition.dx / box.size.width;
                      final newPosition = Duration(
                        milliseconds: (_duration.inMilliseconds * progress).round(),
                      );
                      _audioPlayer.seek(newPosition);
                    }
                  },
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: _duration.inMilliseconds > 0
                        ? LinearProgressIndicator(
                      value: _position.inMilliseconds / _duration.inMilliseconds,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    )
                        : LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Durée
                Text(
                  _duration.inMilliseconds > 0
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                      : _isLoading ? 'Chargement...' : 'Message vocal',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
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