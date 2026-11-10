import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RecordedAudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String title;

  const RecordedAudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.title = 'Your Recorded Speech',
  });

  @override
  State<RecordedAudioPlayerWidget> createState() => _RecordedAudioPlayerWidgetState();
}

class _RecordedAudioPlayerWidgetState extends State<RecordedAudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _checkFileAndInit();
  }

  Future<void> _checkFileAndInit() async {
    final file = File(widget.audioPath);
    final exists = await file.exists();
    if (mounted) {
      setState(() {
        _fileExists = exists;
      });
    }

    if (!exists) return;

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _player.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    if (!_fileExists) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
      await _player.play(DeviceFileSource(widget.audioPath));
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_fileExists) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_off_rounded, color: AppColors.textMuted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No audio recording saved for this session.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final double maxSec = _duration.inMilliseconds.toDouble();
    final double curSec = _position.inMilliseconds.toDouble().clamp(0.0, maxSec > 0 ? maxSec : 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headphones_rounded, color: AppColors.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.title, style: AppTextStyles.titleMedium),
                ],
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primarySoft,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: curSec,
                    min: 0.0,
                    max: maxSec > 0 ? maxSec : 1.0,
                    onChanged: (val) {
                      _player.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

