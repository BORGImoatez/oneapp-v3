import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';
import '../../providers/call_provider.dart';
import '../../widgets/user_avatar.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallModel call;
  final WebRTCService webrtcService;
  final bool isOutgoing;

  const ActiveCallScreen({
    Key? key,
    required this.call,
    required this.webrtcService,
    required this.isOutgoing,
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final CallService _callService = CallService();
  bool _isMuted = false;
  int _callDuration = 0;
  Timer? _timer;
  StreamSubscription? _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenToCallState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _listenToCallState() {
    _callStateSubscription = widget.webrtcService.callState.listen((state) {
      if (state == CallState.ended) {
        _endCall();
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = widget.webrtcService.isMuted;
    });
  }

  Future<void> _endCall() async {
    try {
      _timer?.cancel();
      _callStateSubscription?.cancel();

      final callProvider = Provider.of<CallProvider>(context, listen: false);
      await callProvider.endCall();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error ending call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherPerson = widget.isOutgoing
        ? widget.call.receiverName
        : widget.call.callerName;
    final otherPersonAvatar = widget.isOutgoing
        ? widget.call.receiverAvatar
        : widget.call.callerAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Text(
                'Appel en cours',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              UserAvatar(
                profilePictureUrl: otherPersonAvatar,
                firstName: otherPerson,
                lastName: '',
                radius: 60,
              ),
              const SizedBox(height: 24),
              Text(
                otherPerson,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Muet' : 'Micro',
                    onTap: _toggleMute,
                    backgroundColor: _isMuted
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'Raccrocher',
                    onTap: _endCall,
                    backgroundColor: Colors.red,
                    size: 72,
                    iconSize: 36,
                  ),
                  _buildControlButton(
                    icon: Icons.volume_up,
                    label: 'Haut-parleur',
                    onTap: () {},
                    backgroundColor: Colors.white.withOpacity(0.1),
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    double size = 64,
    double iconSize = 28,
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
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
