import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/widgets/app_drawer.dart';
import 'package:selfcheckoutapp/widgets/theme_toggle.dart';
import 'package:selfcheckoutapp/services/theme_service.dart';
import 'package:selfcheckoutapp/services/biometric_service.dart';
import 'package:selfcheckoutapp/services/localization_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalizationService _localization = LocalizationService();
  final BiometricService _biometricService = BiometricService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: Constants.boldHeadingAppBar,
        ),
        actions: [
          ThemeToggle(),
        ],
      ),
      drawer: AppDrawer(),
      body: ListView(
        children: [
          _buildSection("Appearance", [
            _buildThemeToggle(),
            _buildLanguageSelector(),
          ]),
          _buildSection("Security", [
            _buildBiometricToggle(),
            _buildPasswordChange(),
          ]),
          _buildSection("About", [
            _buildAppInfo(),
            _buildVersionInfo(),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return ListTile(
          title: Text("Dark Mode"),
          subtitle: Text("Toggle between light and dark themes"),
          trailing: Switch(
            value: ThemeService().isDarkMode,
            onChanged: (value) {
              ThemeService().toggleTheme();
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      title: Text("Language"),
      subtitle: Text("Choose app language"),
      trailing: DropdownButton<String>(
        value: _localization.currentLocale,
        items: _localization.supportedLocales.map((locale) {
          return DropdownMenuItem(
            value: locale,
            child: Text(locale.toUpperCase()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _localization.setLocale(value);
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return FutureBuilder<bool>(
      future: _biometricService.isBiometricEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return ListTile(
          title: Text("Biometric Authentication"),
          subtitle: Text("Use fingerprint or Face ID to login"),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) async {
              if (value) {
                final result = await _biometricService.enableBiometric();
                if (!result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message ?? 'Failed to enable biometrics')),
                  );
                }
              } else {
                await _biometricService.disableBiometric();
              }
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildPasswordChange() {
    return ListTile(
      title: Text("Change Password"),
      subtitle: Text("Update your account password"),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Navigate to password change screen
      },
    );
  }

  Widget _buildAppInfo() {
    return ListTile(
      title: Text("About ScanGo"),
      subtitle: Text("Self-Checkout Mobile Application"),
      trailing: Icon(Icons.info_outline),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'ScanGo',
          applicationVersion: 'Version 1.0',
          applicationLegalese: 'Scan->Add->Check->Pay->Go',
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return ListTile(
      title: Text("Version"),
      subtitle: Text("1.0.0"),
      trailing: Icon(Icons.system_update),
    );
  }
}
