import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/dictaphone_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';

class DictaphonePage extends StatefulWidget {
  const DictaphonePage({super.key});

  @override
  State<DictaphonePage> createState() => _DictaphonePageState();
}

class _DictaphonePageState extends State<DictaphonePage> {
  final DictaphoneService _service = sl<DictaphoneService>();
  final NotificationService _notifService = sl<NotificationService>();
  List<RecordingEntry> _recordings = [];
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // Playback state
  String? _playingId;
  bool _isPlaying = false;
  final ValueNotifier<Duration> _playbackPosition = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _playbackDuration = ValueNotifier<Duration>(Duration.zero);

  // Stream subscriptions
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completeSub;

  // Recording pulse animation
  bool _pulseVisible = true;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _setupPlayerStreams();
  }

  void _setupPlayerStreams() {
    _positionSub = _service.player.onPositionChanged.listen((pos) {
      if (_playingId != null) {
        _playbackPosition.value = pos;
      }
    });

    _durationSub = _service.player.onDurationChanged.listen((dur) {
      if (_playingId != null) {
        _playbackDuration.value = dur;
      }
    });

    _completeSub = _service.player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _playbackPosition.value = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _service.stopPlayback();
    _playbackPosition.dispose();
    _playbackDuration.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final recordings = await _service.getAllRecordings();
    if (mounted) {
      setState(() {
        _recordings = recordings;
      });
    }
  }

  // -- Recording --

  Future<void> _startRecording() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('Microphone permission denied. Please enable it in settings.');
      return;
    }

    // Stop any playback first
    await _service.stopPlayback();
    setState(() {
      _playingId = null;
      _isPlaying = false;
    });

    final success = await _service.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _startRecordTimer();
      _startPulse();
    } else {
      _showSnackBar('Failed to start recording. Please try again.');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _pulseTimer?.cancel();

    final entry = await _service.stopRecording();
    setState(() {
      _isRecording = false;
      _pulseVisible = true;
    });

    if (entry != null) {
      await _loadRecordings();
      _showSnackBar('Recording saved (${entry.formattedDuration})');
      // Show local notification
      await _notifService.showRecordingSavedNotification(
        entry.title,
        entry.formattedDuration,
      );
    } else {
      _showSnackBar('Failed to save recording.');
    }
  }

  void _startRecordTimer() {
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordSeconds++);
      }
    });
  }

  void _startPulse() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) {
        setState(() => _pulseVisible = !_pulseVisible);
      }
    });
  }

  // -- Playback --

  Future<void> _togglePlayback(RecordingEntry entry) async {
    if (_isPlaying && _playingId == entry.id) {
      await _service.pausePlayback();
      setState(() => _isPlaying = false);
      return;
    }

    // If switching to a different recording, stop the current one
    if (_playingId != null && _playingId != entry.id) {
      await _service.stopPlayback();
    }

    // Start/resume playback
    if (_playingId == entry.id && _playbackPosition.value > Duration.zero) {
      await _service.resumePlayback();
    } else {
      await _service.playRecording(entry.path);
      setState(() {
        _playingId = entry.id;
      });
      _playbackPosition.value = Duration.zero;
      _playbackDuration.value = Duration(seconds: entry.durationSeconds);
    }

    setState(() => _isPlaying = true);
  }

  // -- Share/Download --

  Future<void> _shareRecording(RecordingEntry entry) async {
    final file = File(entry.path);
    if (!await file.exists()) {
      _showSnackBar('Recording file not found.');
      return;
    }

    await Share.shareXFiles(
      [XFile(entry.path)],
      text: '${entry.title} - IELTS Speaky Recording (${entry.formattedDuration})',
      subject: 'IELTS Speaky Voice Recording',
    );
  }

  // -- Delete --

  Future<void> _deleteRecording(RecordingEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Delete "${entry.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.band5),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_playingId == entry.id) {
      await _service.stopPlayback();
      setState(() {
        _playingId = null;
        _isPlaying = false;
      });
    }

    final success = await _service.deleteRecording(entry.id);
    if (success) {
      await _loadRecordings();
      _showSnackBar('Recording deleted.');
    } else {
      _showSnackBar('Failed to delete recording.');
    }
  }

  // -- Rename --

  Future<void> _renameRecording(RecordingEntry entry) async {
    final controller = TextEditingController(text: entry.title);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Recording'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Recording name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await _service.renameRecording(entry.id, newName);
      await _loadRecordings();
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dictaphone', style: AppTextStyles.h3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Recording section
            _buildRecordingSection(),

            // Divider
            Container(height: 1, color: AppColors.surfaceBorderLight),

            // Recordings list
            Expanded(
              child: _recordings.isEmpty
                  ? _buildEmptyState()
                  : _buildRecordingsList(),
            ),

            // Format note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.backgroundSecondary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Recordings are in M4A format (AAC) — compatible with all media players',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Recording Section --

  Widget _buildRecordingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Timer
          Text(
            _formatDuration(_recordSeconds),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: _isRecording ? AppColors.band5 : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRecording ? 'Recording...' : 'Tap to record',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _isRecording ? AppColors.band5 : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Record/Stop Button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.band5,
                boxShadow: [
                  if (_isRecording && _pulseVisible)
                    BoxShadow(
                      color: AppColors.band5.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRecording
                    ? const Icon(Icons.stop_rounded, color: Colors.white, size: 40, key: ValueKey('stop'))
                    : const Icon(Icons.mic_rounded, color: Colors.white, size: 40, key: ValueKey('mic')),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Hint text
          if (!_isRecording)
            Text(
              'Hold the phone close and speak clearly',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          if (_isRecording)
            TextButton(
              onPressed: _stopRecording,
              child: Text(
                'Stop & Save',
                style: AppTextStyles.label.copyWith(color: AppColors.band5),
              ),
            ),
        ],
      ),
    );
  }

  // -- Empty State --

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text('No recordings yet', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Tap the red button above to record your voice.\n'
              'Then listen back and analyze your speaking!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -- Recordings List --

  Widget _buildRecordingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _recordings.length,
      itemBuilder: (context, index) => _buildRecordingCard(_recordings[index]),
    );
  }

  Widget _buildRecordingCard(RecordingEntry entry) {
    final isThisPlaying = _playingId == entry.id && _isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isThisPlaying ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceBorderLight,
          width: isThisPlaying ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Top row: play button + title + actions
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () => _togglePlayback(entry),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isThisPlaying ? AppColors.primary : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isThisPlaying ? Colors.white : AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + date + duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(entry.formattedDate, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.formattedDuration,
                            style: TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'download':
                      _shareRecording(entry);
                      break;
                    case 'rename':
                      _renameRecording(entry);
                      break;
                    case 'delete':
                      _deleteRecording(entry);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(children: [
                      Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Download / Share'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Rename'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.band5),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ]),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar (only visible when playing or paused)
          if (_playingId == entry.id) ...[
            const SizedBox(height: 12),
            _PlaybackProgressBar(
              positionNotifier: _playbackPosition,
              durationNotifier: _playbackDuration,
              formatDuration: _formatDuration,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaybackProgressBar extends StatelessWidget {
  final ValueNotifier<Duration> positionNotifier;
  final ValueNotifier<Duration> durationNotifier;
  final String Function(int) formatDuration;

  const _PlaybackProgressBar({
    required this.positionNotifier,
    required this.durationNotifier,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: positionNotifier,
      builder: (context, pos, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: durationNotifier,
          builder: (context, dur, _) {
            final progress = dur.inSeconds > 0
                ? pos.inSeconds / dur.inSeconds
                : 0.0;
            return Row(
              children: [
                Text(
                  formatDuration(pos.inSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceBorderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(dur.inSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
