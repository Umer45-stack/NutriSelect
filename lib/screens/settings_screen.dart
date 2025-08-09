import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          // Toggle for enabling/disabling notifications
          SwitchListTile(
            title: Text("Enable Notifications"),
            value: _enableNotifications,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
            },
            secondary: Icon(Icons.notifications),
          ),
          // Toggle for dark mode
          SwitchListTile(
            title: Text("Dark Mode"),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
            secondary: Icon(Icons.dark_mode),
          ),
          // About Section
          ListTile(
            leading: Icon(Icons.info),
            title: Text("About"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "NutriSelect Admin",
                applicationVersion: "1.0.0",
                applicationIcon: Icon(Icons.admin_panel_settings, size: 50, color: Colors.green),
                children: [
                  Text("NutriSelect Admin Panel is the administrative interface for managing the app."),
                ],
              );
            },
          ),
          // Add additional settings options here...
        ],
      ),
    );
  }
}
