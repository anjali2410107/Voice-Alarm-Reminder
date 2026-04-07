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
          _buildSection(context, 'App Information'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (MVP)'),
          ),
          const Divider(height: 32),
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
          const Divider(height: 32),
          _buildTroubleshootingTips(context),
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

  Widget _buildTroubleshootingTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('STILL NOT WORKING?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('1. Ensure Battery Optimization is set to "Unrestricted"'),
          const Text('2. Check system Settings > Notifications > Voice Alarms'),
          const Text('3. Some brands (MIUI/ColorOS) require "Auto-start" to be ON'),
        ],
      ),
    );
  }
}
