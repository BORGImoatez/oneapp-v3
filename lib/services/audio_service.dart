import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  Future<void> _initializeRecorder() async {
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      try {
        await _recorder!.openRecorder();
        print('DEBUG: Recorder initialized successfully');
      } catch (e) {
        print('DEBUG: Error initializing recorder: $e');
        _recorder = null;
      }
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      print('DEBUG: Microphone permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e) {
      print('DEBUG: Error requesting microphone permission: $e');
      return false;
    }
  }

  Future<String?> startRecording() async {
    print('DEBUG: Starting audio recording...');

    if (!await requestPermissions()) {
      print('DEBUG: Microphone permission denied');
      return null;
    }

    try {
      await _initializeRecorder();

      if (_recorder == null) {
        print('DEBUG: Recorder not ready');
        return null;
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      print('DEBUG: Recording to path: $filePath');

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      print('DEBUG: Recording started successfully');
      return filePath;
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  Future<void> stopRecording() async {
    print('DEBUG: Stopping audio recording...');

    try {
      if (_recorder != null && _isRecording) {
        await _recorder!.stopRecorder();
        _isRecording = false;
        print('DEBUG: Recording stopped. Path: $_currentRecordingPath');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
    }
  }

  Future<void> cancelRecording() async {
    print('DEBUG: Cancelling audio recording...');

    try {
      if (_recorder != null && _isRecording) {
        await _recorder!.stopRecorder();
      }
      _isRecording = false;

      // Supprimer le fichier si il existe
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('DEBUG: Recording file deleted');
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      print('Error cancelling recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
    }
  }

  Future<bool> isRecordingAvailable() async {
    try {
      await _initializeRecorder();
      return _recorder != null;
    } catch (e) {
      print('Error checking recording availability: $e');
      return false;
    }
  }

  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      if (_recorder != null) {
        await _recorder!.closeRecorder();
        _recorder = null;
      }
    } catch (e) {
      print('Error disposing audio service: $e');
    }
  }
}