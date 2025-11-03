import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';
import '../../providers/call_provider.dart';
import '../../widgets/user_avatar.dart';
import 'active_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;
  final WebRTCService webrtcService;

  const IncomingCallScreen({
    Key? key,
    required this.call,
    required this.webrtcService,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isVibrating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startRinging();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startRinging() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      _isVibrating = true;
      Vibration.vibrate(
        pattern: [0, 1000, 500, 1000, 500],
        repeat: 0,
      );
    }
  }

  Future<void> _stopRinging() async {
    if (_isVibrating) {
      await Vibration.cancel();
      _isVibrating = false;
    }
    // Stopper la sonnerie du CallProvider
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.stopRingtone();
  }

  Future<void> _answerCall() async {
    try {
      await _stopRinging();

      // Notifier le serveur qu'on répond
      await _callService.answerCall(widget.call.id!);

      // Préparer le PeerConnection (ne crée pas l'offre, attend de la recevoir)
      await widget.webrtcService.answerCall(
        widget.call.channelId.toString(),
        widget.call.callerId,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ActiveCallScreen(
              call: widget.call,
              webrtcService: widget.webrtcService,
              isOutgoing: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _answerCall: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la réponse à l\'appel')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _rejectCall() async {
    try {
      await _stopRinging();
      await _callService.rejectCall(widget.call.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _stopRinging();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Text(
                'Appel entrant',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: UserAvatar(
                      profilePictureUrl: widget.call.callerAvatar,
                      firstName: widget.call.callerName,
                      lastName: '',
                      radius: 70,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                widget.call.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Appel vocal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call_end,
                    label: 'Refuser',
                    onTap: _rejectCall,
                    backgroundColor: Colors.red,
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Répondre',
                    onTap: _answerCall,
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
