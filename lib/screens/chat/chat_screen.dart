import 'package:flutter/material.dart';
import 'package:mgi/screens/vote/vote_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/channel_model.dart';
import '../../models/message_model.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../services/audio_service.dart';
import 'shared_media_screen.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;

  const ChatScreen({super.key, required this.channel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isRecording = false;
  bool _isTyping = false;
  bool _hasText = false;
  String? _recordingPath;
  DateTime? _recordingStartTime;
  double _slideOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ==================== LIFECYCLE METHODS ====================

  void _loadMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadChannelMessages(widget.channel.id, refresh: true);
  }

  void _onTypingChanged() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    final hasText = _messageController.text.trim().isNotEmpty;

    if (isCurrentlyTyping != _isTyping) {
      _isTyping = isCurrentlyTyping;
      chatProvider.sendTypingIndicator(widget.channel.id, _isTyping);
    }

    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  // ==================== MESSAGE HANDLING ====================

  void _sendMessage({String? content, String type = Constants.messageTypeText}) {
    if (content == null || content.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(widget.channel.id, content.trim(), type);

    _messageController.clear();
    setState(() {
      _hasText = false;
    });

    // Scroll to bottom après un petit délai
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ==================== MEDIA HANDLING ====================

  void _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      try {
        // Upload the file first to get the file ID
        final result = await chatProvider.sendMessageWithFile(
          widget.channel.id,
          File(image.path),
          Constants.messageTypeImage,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'envoi de l\'image: $e')),
          );
        }
      }
    }
  }

  void _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      try {
        await chatProvider.sendMessageWithFile(
          widget.channel.id,
          File(image.path),
          Constants.messageTypeImage,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'envoi de la photo: $e')),
          );
        }
      }
    }
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessageWithFile(
        widget.channel.id,
        File(result.files.single.path!),
        Constants.messageTypeFile,
      );
    }
  }

  void _startRecording() async {
    final audioService = AudioService();

    // Vérifier les permissions d'abord
    if (!await audioService.requestPermissions()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise pour enregistrer'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _slideOffset = 0.0;
    });

    try {
      _recordingPath = await audioService.startRecording();
      if (_recordingPath == null) {
        throw Exception('Impossible de démarrer l\'enregistrement');
      }

      print('DEBUG: Recording started at path: $_recordingPath');
    } catch (e) {
      print('DEBUG: Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
      });
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

    if (duration.inMilliseconds < 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenez le bouton plus longtemps pour enregistrer'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      await _cancelRecording();
      return;
    }

    final audioService = AudioService();

    try {
      await audioService.stopRecording();

      setState(() {
        _isRecording = false;
      });

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          await chatProvider.sendMessageWithFile(
            widget.channel.id,
            file,
            'AUDIO',
          );
          print('DEBUG: Audio message sent successfully');
        } else {
          throw Exception('Fichier audio non trouvé');
        }
      }
    } catch (e) {
      print('DEBUG: Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
        );
      }
    } finally {
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
        _slideOffset = 0.0;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;

    final audioService = AudioService();

    try {
      await audioService.cancelRecording();
    } catch (e) {
      print('DEBUG: Error cancelling recording: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
        _slideOffset = 0.0;
      });
    }
  }

  // ==================== UI BUILDERS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.channel.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${widget.channel.memberCount} membres',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SharedMediaScreen(
                  channelId: widget.channel.id,
                  channelName: widget.channel.name,
                ),
              ),
            );
          },
          icon: const Icon(Icons.photo_library_outlined),
          tooltip: 'Médias partagés',
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VoteScreen(channel: widget.channel),
              ),
            );
          },
          icon: const Icon(Icons.poll),
          tooltip: 'Votes',
        ),
        IconButton(
          onPressed: () {
            _showChannelInfo();
          },
          icon: const Icon(Icons.info_outline),
          tooltip: 'Informations',
        ),
      ],
    );
  }

  void _showChannelInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              widget.channel.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.channel.description != null)
              Text(
                'Sujet: ${widget.channel.description}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${widget.channel.memberCount} membres',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.getChannelMessages(widget.channel.id);
        final typingUsers = chatProvider.getTypingUsers(widget.channel.id);

        if (chatProvider.isLoadingMessages(widget.channel.id)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (typingUsers.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && typingUsers.isNotEmpty) {
              return TypingIndicator(users: typingUsers);
            }

            final messageIndex = typingUsers.isNotEmpty ? index - 1 : index;
            final message = messages[messageIndex];
            final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
            final isMe = message.senderId == currentUser?.id || message.senderId == currentUser?.email;

            return MessageBubble(
              message: message,
              isMe: isMe,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à envoyer un message !',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isRecording) ...[
              _buildAttachmentButton(),
              const SizedBox(width: 8),
              _buildTextInput(),
              const SizedBox(width: 8),
            ],
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return IconButton(
      onPressed: _showAttachmentOptions,
      icon: const Icon(Icons.attach_file),
      color: AppTheme.primaryColor,
    );
  }

  Widget _buildTextInput() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: _messageController,
          focusNode: _focusNode,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Tapez votre message...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) {
              _sendMessage(content: text);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _hasText
          ? _buildSendIconButton()
          : _buildMicrophoneButton(),
    );
  }

  Widget _buildSendIconButton() {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: () => _sendMessage(content: _messageController.text),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.send,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return _isRecording
        ? _buildRecordingControls()
        : GestureDetector(
      key: const ValueKey('mic'),
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressMoveUpdate: (details) {
        setState(() {
          _slideOffset = details.localPosition.dx;
        });

        // Si l'utilisateur glisse trop vers la gauche, annuler
        if (_slideOffset < -100) {
          _cancelRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isRecording ? AppTheme.errorColor : Colors.grey[400],
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isRecording
              ? [
            BoxShadow(
              color: AppTheme.errorColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    final isNearCancel = _slideOffset < -50;

    return Expanded(
      key: const ValueKey('recording'),
      child: Row(
        children: [
          // Icône de suppression (glisser vers la gauche pour annuler)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNearCancel ? Colors.red[400] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              color: isNearCancel ? Colors.white : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Barre d'enregistrement
          Expanded(
            child: Transform.translate(
              offset: Offset(_slideOffset.clamp(-100, 0), 0),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
              child: Row(
                children: [
                  // Point rouge pulsant
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: (value * 0.5) + 0.5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (_isRecording && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 12),

                  // Timer
                  StreamBuilder<int>(
                    stream: Stream.periodic(const Duration(seconds: 1), (count) => count),
                    builder: (context, snapshot) {
                      final duration = _recordingStartTime != null
                          ? DateTime.now().difference(_recordingStartTime!)
                          : Duration.zero;
                      final minutes = duration.inMinutes.toString().padLeft(2, '0');
                      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

                      return Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Onde sonore animée
                  Row(
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.3, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Container(
                              width: 3,
                              height: 20 * value,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                          onEnd: () {
                            if (_isRecording && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(width: 12),

                  // Flèche glisser pour annuler
                  const Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: Colors.grey,
                        size: 16,
                      ),
                      Text(
                        'Glisser pour annuler',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ATTACHMENT OPTIONS ====================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAttachmentBottomSheet(),
    );
  }

  Widget _buildAttachmentBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHandle(),
          const SizedBox(height: 20),
          const Text(
            'Envoyer un fichier',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildAttachmentOptionsRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAttachmentOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAttachmentOption(
          icon: Icons.photo,
          label: 'Photo',
          color: Colors.blue,
          onTap: () {
            Navigator.pop(context);
            _pickImage();
          },
        ),
        _buildAttachmentOption(
          icon: Icons.camera_alt,
          label: 'Caméra',
          color: Colors.green,
          onTap: () {
            Navigator.pop(context);
            _takePhoto();
          },
        ),
        _buildAttachmentOption(
          icon: Icons.insert_drive_file,
          label: 'Fichier',
          color: Colors.orange,
          onTap: () {
            Navigator.pop(context);
            _pickFile();
          },
        ),
      ],
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}