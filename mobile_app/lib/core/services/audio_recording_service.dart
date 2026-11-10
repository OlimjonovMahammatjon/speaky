import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Service for recording audio during speaking practice sessions.
///
/// Wraps the `record` package to provide a clean API for the BLoC layer.
/// If recording is not available (permission denied, no hardware),
/// the app falls back to a "practice timer" mode.
class AudioRecordingService {
  AudioRecorder? _recorder;

  AudioRecorder _getRecorder() {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;

  /// Checks if the app has microphone permission.
  Future<bool> hasPermission() async {
    try {
      return await _getRecorder().hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// Starts recording audio to a temporary file.
  /// If [customFileName] is provided, uses it as the file prefix.
  /// Returns true on success, false if permission denied or hardware unavailable.
  Future<bool> startRecording({String? customFileName}) async {
    if (_isRecording) return true;

    try {
      final recorder = _getRecorder();
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) return false;

      final dir = await getTemporaryDirectory();
      final prefix = customFileName ?? 'ielts_speaky';
      final path =
          '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _isRecording = true;
      _currentPath = path;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops recording and returns the file path.
  /// Returns null if recording wasn't active or failed.
  Future<String?> stopRecording() async {
    if (!_isRecording || _recorder == null) return null;

    try {
      final path = await _recorder!.stop();
      _isRecording = false;
      _currentPath = path;
      return path;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  /// Resets the recording session without permanently disposing the native channel.
  Future<void> reset() async {
    if (_isRecording) {
      await stopRecording();
    }
    _currentPath = null;
    _isRecording = false;
  }

  /// Gets the current amplitude (for audio wave visualization).
  /// Returns 0.0 if not recording or unavailable.
  Future<Amplitude> getAmplitude() async {
    if (!_isRecording || _recorder == null) {
      return Amplitude(current: 0, max: 0);
    }
    try {
      return await _recorder!.getAmplitude();
    } catch (_) {
      return Amplitude(current: 0, max: 0);
    }
  }

  /// Disposes the recorder — call when the session is done.
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
  }

  /// Deletes the recorded audio file (optional cleanup).
  Future<void> deleteRecording() async {
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentPath = null;
    }
  }
}

/// Thrown when audio recording encounters a critical error.
class AudioRecordingException implements Exception {
  final String message;
  AudioRecordingException([this.message = 'Audio recording failed']);
  @override
  String toString() => 'AudioRecordingException: $message';
}
