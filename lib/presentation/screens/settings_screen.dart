import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart';
import '../../data/models/alarm_model.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _notificationsEnabled = false;
  bool _exactAlarmsEnabled = false;
  bool _overlayEnabled = false;
  bool _fullScreenIntentEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final ns = NotificationService();
    final notifications = await ns.checkNotificationPermission();
    final exact = await ns.checkExactAlarmPermission();
    final overlay = await ns.checkOverlayPermission();
    final fsi = await ns.checkFullScreenIntentPermission();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _exactAlarmsEnabled = exact;
        _overlayEnabled = overlay;
        _fullScreenIntentEnabled = fsi;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _buildSection(context, 'Permissions Dashboard'),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else ...[
            _buildPermissionTile(
              context,
              'Notifications',
              'Required to show alerts',
              _notificationsEnabled,
              () => NotificationService().requestPermissions(),
            ),
            _buildPermissionTile(
              context,
              'Exact Alarms',
              'Required for pinpoint timing',
              _exactAlarmsEnabled,
              () => NotificationService().openAlarmSettings(),
            ),
            _buildPermissionTile(
              context,
              'Appear on Top',
              'Required for full-screen alarm',
              _overlayEnabled,
              () => NotificationService().openOverlaySettings(),
            ),
            _buildPermissionTile(
              context,
              'Full Screen Intent',
              'Required for Android 14+',
              _fullScreenIntentEnabled,
              () => NotificationService().openFullScreenIntentSettings(),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(BuildContext context, String title, String subtitle, bool isGranted, VoidCallback onRepair) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isGranted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        child: Icon(
          isGranted ? Icons.check_circle_rounded : Icons.error_rounded,
          color: isGranted ? Colors.green : Colors.red,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isGranted 
        ? null 
        : TextButton(
            onPressed: onRepair,
            child: const Text('FIX'),
          ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }


}
