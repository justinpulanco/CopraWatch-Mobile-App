import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/page_guide_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/raspberry_pi_service.dart';
import '../../../../services/first_time_service.dart';
import '../../../../core/widgets/user_guide_dialog.dart';
import '../../../../core/routes/app_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _rpiService = RaspberryPiService();

  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _tempThresholdController;
  late TextEditingController _humidityThresholdController;

  bool _autoConnect = true;
  bool _notificationsEnabled = true;
  String _temperatureUnit = 'Celsius';
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: AppConstants.raspberryPiDefaultIP);
    _portController = TextEditingController(text: AppConstants.raspberryPiDefaultPort.toString());
    _tempThresholdController = TextEditingController(text: '80');
    _humidityThresholdController = TextEditingController(text: '15');
    _loadSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tempThresholdController.dispose();
    _humidityThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString(PreferenceKeys.raspberryPiIP) ?? AppConstants.raspberryPiDefaultIP;
      _portController.text = (prefs.getInt(PreferenceKeys.raspberryPiPort) ?? AppConstants.raspberryPiDefaultPort).toString();
      _autoConnect = prefs.getBool(PreferenceKeys.autoConnectRaspberryPi) ?? true;
      _notificationsEnabled = prefs.getBool(PreferenceKeys.notificationsEnabled) ?? true;
      _temperatureUnit = prefs.getString(PreferenceKeys.temperatureUnit) ?? 'Celsius';
      _tempThresholdController.text = (prefs.getDouble('tempThreshold') ?? 80.0).toString();
      _humidityThresholdController.text = (prefs.getDouble('humidityThreshold') ?? 15.0).toString();
    });

    // Update API Constants on load
    ApiConstants.updateBaseUrl(_ipController.text, int.tryParse(_portController.text) ?? 5000);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.raspberryPiIP, _ipController.text);
    await prefs.setInt(PreferenceKeys.raspberryPiPort, int.tryParse(_portController.text) ?? 5000);
    await prefs.setBool(PreferenceKeys.autoConnectRaspberryPi, _autoConnect);
    await prefs.setBool(PreferenceKeys.notificationsEnabled, _notificationsEnabled);
    await prefs.setString(PreferenceKeys.temperatureUnit, _temperatureUnit);
    await prefs.setDouble('tempThreshold', double.tryParse(_tempThresholdController.text) ?? 80.0);
    await prefs.setDouble('humidityThreshold', double.tryParse(_humidityThresholdController.text) ?? 15.0);

    // Update API Constants
    ApiConstants.updateBaseUrl(_ipController.text, int.tryParse(_portController.text) ?? 5000);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        subtitle: 'Configuration & Preferences',
        showBackButton: true,
        onBackPressed: () => context.go(AppRoutes.dashboard),
        actions: [
          PageHelpButton(
            pageName: 'settings',
            pageTitle: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Connection Settings
            _buildSection(context, 'Device Connection'),
            _buildConnectionStatus(),
            _buildIPAddressField(),
            _buildPortField(),
            _buildSwitchTile(
              'Auto-Connect',
              _autoConnect,
              (value) => setState(() => _autoConnect = value),
            ),
            _buildButton(
              _isTestingConnection ? 'Testing...' : 'Test & Save Connection',
              _isTestingConnection ? null : () => _testAndSaveConnection()
            ),
            const Divider(height: 24),

            // Sensor Settings
            _buildSection(context, 'Sensor Configuration'),
            _buildListTile(
              'Temperature Unit',
              _temperatureUnit,
              () => _showTemperatureUnitDialog(),
            ),
            _buildButton('Calibrate Sensors', _calibrateSensors),
            _buildButton(
              'Open User Guide',
              () => showUserGuide(context),
            ),
            _buildButton(
              'View All Page Guides',
              () => _showAllGuidesMenu(context),
            ),
            _buildButton(
              'Reset Tutorials',
              () => _resetTutorials(),
            ),
            const Divider(height: 24),

            // Notifications
            _buildSection(context, 'Notifications'),
            _buildSwitchTile(
              'Enable Notifications',
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            const Divider(height: 24),

            // Alert Thresholds
            _buildSection(context, 'Alert Thresholds'),
            _buildThresholdField(
              'Temperature Alert (°C)',
              _tempThresholdController,
              'Alert when temperature exceeds this value',
            ),
            _buildThresholdField(
              'Humidity Alert (%)',
              _humidityThresholdController,
              'Alert when humidity drops below this value',
            ),
            const Divider(height: 24),

            // System Information
            _buildSection(context, 'System Information'),
            _buildInfoRow('App Version', AppConstants.appVersion),
            _buildInfoRow('Pi IP Address', ApiConstants.baseUrl),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save All Settings'),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        16,
        AppConstants.defaultPadding,
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final connected = _rpiService.isConnected;
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: connected ? AppTheme.successColor : AppTheme.warningColor,
          shape: BoxShape.circle,
        ),
      ),
      title: const Text('Raspberry Pi Status'),
      subtitle: Text(connected ? 'Connected' : 'Disconnected'),
      trailing: Text(connected ? 'Online' : 'Offline'),
    );
  }

  Widget _buildIPAddressField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: TextFormField(
        controller: _ipController,
        decoration: const InputDecoration(
          labelText: 'Raspberry Pi IP Address',
          hintText: '192.168.1.100',
          prefixIcon: Icon(Icons.router_rounded),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPortField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: TextFormField(
        controller: _portController,
        decoration: const InputDecoration(
          labelText: 'Port Number',
          hintText: '5000',
          prefixIcon: Icon(Icons.numbers_rounded),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: const Icon(Icons.warning_amber_rounded),
          suffixText: label.contains('Temperature') ? '°C' : '%',
        ),
      ),
    );
  }

  Future<void> _testAndSaveConnection() async {
    setState(() => _isTestingConnection = true);

    final ip = _ipController.text;
    final port = int.tryParse(_portController.text) ?? 5000;

    // Temporarily update base URL to test
    final originalBaseUrl = ApiConstants.baseUrl;
    ApiConstants.updateBaseUrl(ip, port);

    try {
      final success = await _rpiService.connect(ipAddress: ip, port: port);

      if (success) {
        await _saveSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Real Connection Successful! Settings Saved.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Revert base URL if failed
        ApiConstants.baseUrl = originalBaseUrl;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to Raspberry Pi. Check IP and Port.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      ApiConstants.baseUrl = originalBaseUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  void _calibrateSensors() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibration command sent to Raspberry Pi')),
    );
  }

  void _showTemperatureUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temperature Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Celsius (°C)'),
              value: 'Celsius',
              groupValue: _temperatureUnit,
              onChanged: (value) {
                setState(() => _temperatureUnit = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Fahrenheit (°F)'),
              value: 'Fahrenheit',
              groupValue: _temperatureUnit,
              onChanged: (value) {
                setState(() => _temperatureUnit = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllGuidesMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.primaryGreen, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Page Guides',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Learn how to use each feature of CopraWatch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Guide buttons
            _buildGuideMenuItem(context, 'Dashboard', 'dashboard', Icons.dashboard),
            _buildGuideMenuItem(context, 'Monitor', 'monitor', Icons.monitor_heart),
            _buildGuideMenuItem(context, 'Scanner', 'scanner', Icons.camera_alt),
            _buildGuideMenuItem(context, 'Batches', 'batches', Icons.inventory),
            _buildGuideMenuItem(context, 'Analytics', 'analytics', Icons.analytics),
            _buildGuideMenuItem(context, 'Settings', 'settings', Icons.settings),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideMenuItem(BuildContext context, String title, String pageName, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          PageGuideDialog.show(context, pageName, title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title Guide',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Learn how to use $title features',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _resetTutorials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tutorials?'),
        content: const Text(
          'This will mark all tutorials as unseen. The welcome guide will show again on next app launch, and page guides will be offered when you visit each page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirstTimeService.resetFirstTimeFlags();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tutorials reset! Welcome guide will show on next app launch.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
