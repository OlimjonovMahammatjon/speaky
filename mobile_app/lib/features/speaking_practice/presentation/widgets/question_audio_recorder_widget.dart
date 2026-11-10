import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reusable per-question voice recording widget.
///
/// Allows the candidate to record an answer specifically for one question,
/// preview/playback their speech, and re-record if desired.
class QuestionAudioRecorderWidget extends StatefulWidget {
  final String questionId;
  final String? initialAudioPath;
  final Function(String audioPath)? onRecordingCompleted;

  const QuestionAudioRecorderWidget({
    super.key,
    required this.questionId,
    this.initialAudioPath,
    this.onRecordingCompleted,
  });

  @override
  State<QuestionAudioRecorderWidget> createState() => _QuestionAudioRecorderWidgetState();
}

class _QuestionAudioRecorderWidgetState extends State<QuestionAudioRecorderWidget> {
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;

  int _recordSeconds = 0;
  Timer? _recordTimer;

  Duration _playDuration = Duration.zero;
  Duration _playPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recordedPath = widget.initialAudioPath;
    _recorder = AudioRecorder();
    _player = AudioPlayer();

    _player!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player!.onDurationChanged.listen((d) {
      if (mounted) setState(() => _playDuration = d);
    });

    _player!.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playPosition = p);
    });

    _player!.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/q_${widget.questionId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder!.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordSeconds++;
            });
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _recorder!.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });

      if (path != null && widget.onRecordingCompleted != null) {
        widget.onRecordingCompleted!(path);
      }
    } catch (_) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordedPath == null || !File(_recordedPath!).existsSync()) return;

    if (_isPlaying) {
      await _player!.pause();
    } else {
      if (_playPosition >= _playDuration && _playDuration > Duration.zero) {
        await _player!.seek(Duration.zero);
      }
      await _player!.play(DeviceFileSource(_recordedPath!));
    }
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Currently recording mode
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.roseSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.rose,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Recording: ${_formatSeconds(_recordSeconds)}',
              style: const TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
              label: const Text('Stop & Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _stopRecording,
            ),
          ],
        ),
      );
    }

    // 2. Audio has been recorded
    if (_recordedPath != null && File(_recordedPath!).existsSync()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Recorded Response',
                    style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  Text(
                    _formatSeconds(_playDuration.inSeconds > 0 ? _playPosition.inSeconds : _recordSeconds),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.teal),
              label: const Text('Re-record', style: TextStyle(color: AppColors.teal, fontSize: 12)),
              onPressed: _startRecording,
            ),
          ],
        ),
      );
    }

    // 3. Idle / Record answer button
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.mic_rounded, size: 18, color: AppColors.primary),
        label: const Text('Record Voice for this Question'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _startRecording,
      ),
    );
  }
}
