import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notifService = sl<NotificationService>();

  bool _remindersEnabled = false;
  bool _isLoading = true;
  int _reminderHour = 19;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _notifService.isReminderEnabled();
    final (hour, minute) = await _notifService.getReminderTime();

    setState(() {
      _remindersEnabled = enabled;
      _reminderHour = hour;
      _reminderMinute = minute;
      _isLoading = false;
    });
  }

  Future<void> _toggleReminders(bool value) async {
    if (value) {
      // Enabling — request permission and schedule
      setState(() => _isLoading = true);
      final success = await _notifService.enableDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );

      if (success) {
        setState(() {
          _remindersEnabled = true;
          _isLoading = false;
        });
        _showSnackBar('Daily reminders enabled at ${_formatTime(_reminderHour, _reminderMinute)}');
      } else {
        setState(() => _isLoading = false);
        _showPermissionDeniedDialog();
      }
    } else {
      // Disabling
      await _notifService.disableDailyReminder();
      setState(() => _remindersEnabled = false);
      _showSnackBar('Daily reminders disabled');
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      helpText: 'Choose reminder time',
    );

    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });

      if (_remindersEnabled) {
        // Re-schedule with new time
        await _notifService.disableDailyReminder();
        final success = await _notifService.enableDailyReminder(
          hour: _reminderHour,
          minute: _reminderMinute,
        );
        if (success) {
          _showSnackBar('Reminder time updated to ${_formatTime(_reminderHour, _reminderMinute)}');
        }
      }
    }
  }

  Future<void> _testNotification() async {
    await _notifService.showRecordingSavedNotification('Test Recording', '01:30');
    _showSnackBar('Test notification sent!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notification permission was denied. To receive practice reminders, '
          'please enable notifications in your device settings.\n\n'
          'Settings > Apps > IELTS Speaky > Notifications',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.h3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stay on Track',
                                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Get daily reminders to keep your speaking practice streak alive.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Daily reminder toggle
                    Text('Practice Reminders', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          // Toggle row
                          SwitchListTile(
                            value: _remindersEnabled,
                            onChanged: _toggleReminders,
                            activeTrackColor: AppColors.primary,
                            title: Text('Daily reminder', style: AppTextStyles.titleMedium),
                            subtitle: Text(
                              _remindersEnabled
                                  ? 'We\'ll remind you every day at ${_formatTime(_reminderHour, _reminderMinute)}'
                                  : 'Get a gentle nudge to practice speaking daily',
                              style: AppTextStyles.bodySmall,
                            ),
                            secondary: Icon(
                              Icons.alarm_rounded,
                              color: _remindersEnabled ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),

                          // Time picker (only when enabled)
                          if (_remindersEnabled) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: const Icon(Icons.schedule_rounded, color: AppColors.textSecondary),
                              title: Text('Reminder time', style: AppTextStyles.bodyMedium),
                              trailing: Text(
                                _formatTime(_reminderHour, _reminderMinute),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: _pickTime,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test notification button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _testNotification,
                        icon: const Icon(Icons.notifications_outlined, size: 18),
                        label: const Text('Send test notification'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // What you'll receive
                    Text('What you\'ll receive', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    _buildInfoCard(
                      icon: Icons.alarm_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primarySoft,
                      title: 'Daily practice reminder',
                      desc: 'A friendly reminder at your chosen time to open the app and practice.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.mic_rounded,
                      iconColor: AppColors.band5,
                      iconBg: AppColors.band5.withValues(alpha: 0.1),
                      title: 'Recording saved',
                      desc: 'Confirmation when your dictaphone recording is saved and ready to review.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.orange,
                      iconBg: AppColors.orangeSoft,
                      title: 'Streak milestone',
                      desc: 'Celebrate when you hit a new practice streak milestone!',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: AppColors.teal,
                      iconBg: AppColors.tealSoft,
                      title: 'Mock test completed',
                      desc: 'A summary notification with your estimated band score after each mock test.',
                    ),

                    const SizedBox(height: 28),

                    // Privacy note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'All notifications are local — they come from the app on your device. '
                              'No data is sent to any server. You can disable them anytime.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.bodySmall, textAlign: TextAlign.start),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
