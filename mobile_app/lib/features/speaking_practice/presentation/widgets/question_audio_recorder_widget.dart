import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Highly intuitive, comfortable, and responsive per-question audio recorder.
///
/// Provides:
/// - Clear visual cue in idle state with duration guidelines
/// - Animated pulsating red indicator and live sound wave bars during recording
/// - Instant cancel and stop-and-save controls
/// - In-place playback scrubber with seek capability, re-record, and delete
class QuestionAudioRecorderWidget extends StatefulWidget {
  final String questionId;
  final String? initialAudioPath;
  final String? label;
  final Function(String audioPath)? onRecordingCompleted;
  final VoidCallback? onRecordingDeleted;

  const QuestionAudioRecorderWidget({
    super.key,
    required this.questionId,
    this.initialAudioPath,
    this.label,
    this.onRecordingCompleted,
    this.onRecordingDeleted,
  });

  @override
  State<QuestionAudioRecorderWidget> createState() => _QuestionAudioRecorderWidgetState();
}

class _QuestionAudioRecorderWidgetState extends State<QuestionAudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;

  int _recordSeconds = 0;
  static const int _maxRecordSeconds = 90; // 1.5 minutes per answer
  Timer? _recordTimer;

  Duration _playDuration = Duration.zero;
  Duration _playPosition = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _recordedPath = widget.initialAudioPath;
    _recorder = AudioRecorder();
    _player = AudioPlayer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    _pulseController.dispose();
    _recordTimer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (_isPlaying) {
        await _player!.stop();
      }

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
          if (!mounted) return;
          if (_recordSeconds >= _maxRecordSeconds) {
            _stopAndSaveRecording();
          } else {
            setState(() {
              _recordSeconds++;
            });
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder!.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });
    }
  }

  Future<void> _stopAndSaveRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _recorder!.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });

      if (path != null && widget.onRecordingCompleted != null) {
        widget.onRecordingCompleted!(path);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
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

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ovozli javobni o\'chirish?'),
        content: const Text('Ushbu savol uchun yozilgan audioni o\'chirmoqchimisiz? Qaytadan yozishingiz mumkin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _player?.stop();
              setState(() {
                _recordedPath = null;
                _playDuration = Duration.zero;
                _playPosition = Duration.zero;
              });
              if (widget.onRecordingDeleted != null) {
                widget.onRecordingDeleted!();
              }
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 1. REJIM: Ovoz yozilmoqda (Recording Mode)
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.roseSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.rose,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Yozilmoqda: ${_formatSeconds(_recordSeconds)}',
                  style: const TextStyle(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${_formatSeconds(_maxRecordSeconds)}',
                  style: TextStyle(
                    color: AppColors.rose.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Mini live wave bars
                Row(
                  children: List.generate(5, (index) {
                    final height = 8.0 + ((index + (_recordSeconds % 3)) * 4.0).clamp(6.0, 20.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 3.5,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Bekor qilish tugmasi
                TextButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  label: const Text('Bekor qilish', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
                const Spacer(),
                // Saqlash tugmasi
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  label: const Text('Tugatish & Saqlash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _stopAndSaveRecording,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. REJIM: Audio yozildi va saqlandi (Recorded Audio Mode)
    if (_recordedPath != null && File(_recordedPath!).existsSync()) {
      final double totalMs = _playDuration.inMilliseconds.toDouble();
      final double currentMs = _playPosition.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 1.0);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ovozli javob saqlandi',
                  style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'O\'chirish',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose, size: 20),
                  onPressed: _deleteRecording,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Play / Pause round button
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: AppColors.teal,
                          inactiveTrackColor: AppColors.teal.withValues(alpha: 0.2),
                          thumbColor: AppColors.teal,
                        ),
                        child: Slider(
                          value: currentMs,
                          min: 0.0,
                          max: totalMs > 0 ? totalMs : 1.0,
                          onChanged: (val) async {
                            await _player?.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatSeconds(_playPosition.inSeconds),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            Text(
                              _formatSeconds(_playDuration.inSeconds > 0 ? _playDuration.inSeconds : _recordSeconds),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.teal),
                label: const Text('Qaytadan yozish', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 12)),
                onPressed: _startRecording,
              ),
            ),
          ],
        ),
      );
    }

    // 3. REJIM: Kutish rejimi (Idle State)
    final displayLabel = widget.label ?? 'Javobingizni ovozda yozib oling';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _startRecording,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ovozni yozish uchun bosing • Maks 90 soniya',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
