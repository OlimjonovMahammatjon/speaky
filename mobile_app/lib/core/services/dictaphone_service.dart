import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single saved recording entry with metadata.
class RecordingEntry {
  final String id;
  final String path;
  final String title;
  final DateTime date;
  final int durationSeconds;

  const RecordingEntry({
    required this.id,
    required this.path,
    required this.title,
    required this.date,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'title': title,
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory RecordingEntry.fromJson(Map<String, dynamic> json) {
    return RecordingEntry(
      id: json['id'] as String,
      path: json['path'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Service for the dictaphone feature.
///
/// Handles audio recording, playback, and recording metadata storage.
/// Recordings are saved in AAC/M4A format in the app's documents directory.
class DictaphoneService {
  static const _storageKey = 'dictaphone_recordings';

  AudioRecorder? _recorder;
  AudioPlayer? _player;
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;

  /// Ensures the recorder is initialized.
  AudioRecorder _getRecorder() {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  /// Ensures the player is initialized.
  AudioPlayer _getPlayer() {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Checks microphone permission.
  Future<bool> hasPermission() async {
    try {
      return await _getRecorder().hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// Starts recording audio.
  /// Returns true on success, false if permission denied.
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    try {
      final hasPerm = await _getRecorder().hasPermission();
      if (!hasPerm) return false;

      final dir = await getApplicationDocumentsDirectory();
      final id = 'rec_${DateTime.now().millisecondsSinceEpoch}';
      final path = '${dir.path}/$id.m4a';

      await _getRecorder().start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _isRecording = true;
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops recording and saves the recording metadata.
  /// Returns the saved [RecordingEntry], or null on failure.
  Future<RecordingEntry?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _getRecorder().stop();
      _isRecording = false;
      final endTime = DateTime.now();

      final durationSeconds = _recordingStartTime != null
          ? endTime.difference(_recordingStartTime!).inSeconds
          : 0;

      final entry = RecordingEntry(
        id: 'rec_${_recordingStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
        path: path ?? _currentRecordingPath ?? '',
        title: 'Recording ${endTime.day}/${endTime.month}',
        date: _recordingStartTime ?? endTime,
        durationSeconds: durationSeconds,
      );

      await _saveEntry(entry);
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return entry;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  /// Gets the live recording duration in seconds.
  int get recordingDurationSeconds {
    if (!_isRecording || _recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Loads all saved recordings, sorted by date (newest first).
  Future<List<RecordingEntry>> getAllRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json == null) return [];

      final list = jsonDecode(json) as List<dynamic>;
      final entries = list
          .map((e) => RecordingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.date.compareTo(a.date));

      // Filter out entries whose files no longer exist
      final valid = <RecordingEntry>[];
      for (final entry in entries) {
        if (await File(entry.path).exists()) {
          valid.add(entry);
        }
      }

      // If some entries were pruned, save the cleaned list
      if (valid.length != entries.length) {
        await _saveAllEntries(valid);
      }

      return valid;
    } catch (_) {
      return [];
    }
  }

  /// Deletes a recording (file + metadata).
  Future<bool> deleteRecording(String id) async {
    try {
      final entries = await getAllRecordings();
      final entry = entries.firstWhere((e) => e.id == id);

      // Delete the file
      final file = File(entry.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      entries.removeWhere((e) => e.id == id);
      await _saveAllEntries(entries);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renames a recording.
  Future<bool> renameRecording(String id, String newTitle) async {
    try {
      final entries = await getAllRecordings();
      final index = entries.indexWhere((e) => e.id == id);
      if (index == -1) return false;

      final old = entries[index];
      entries[index] = RecordingEntry(
        id: old.id,
        path: old.path,
        title: newTitle,
        date: old.date,
        durationSeconds: old.durationSeconds,
      );

      // Re-sort (though order doesn't change for rename)
      entries.sort((a, b) => b.date.compareTo(a.date));
      await _saveAllEntries(entries);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Plays a recording. Stops any current playback first.
  Future<void> playRecording(String path) async {
    await _getPlayer().stop();
    await _getPlayer().play(DeviceFileSource(path));
  }

  /// Pauses playback.
  Future<void> pausePlayback() async {
    await _getPlayer().pause();
  }

  /// Resumes playback.
  Future<void> resumePlayback() async {
    await _getPlayer().resume();
  }

  /// Stops playback.
  Future<void> stopPlayback() async {
    await _getPlayer().stop();
  }

  /// Gets the audio player instance (for streaming position/sate).
  AudioPlayer get player => _getPlayer();

  /// Disposes all resources.
  Future<void> dispose() async {
    if (_isRecording) {
      await _getRecorder().stop();
    }
    await _recorder?.dispose();
    await _player?.dispose();
  }

  // -- Private helpers --

  Future<void> _saveEntry(RecordingEntry entry) async {
    final entries = await getAllRecordings();
    entries.insert(0, entry);
    await _saveAllEntries(entries);
  }

  Future<void> _saveAllEntries(List<RecordingEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
