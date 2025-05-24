import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final int streamSpeed; // 串流速度
  final ValueChanged<int> onStreamSpeedChanged; // 串流速度變更回調

  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.streamSpeed,
    required this.onStreamSpeedChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static bool _notificationsEnabled = true; // 通知開關狀態
  static String _selectedLanguage = 'English'; // 預設語言
  final List<String> _languages = [
    'English',
    '中文',
    'Español',
    'Français',
  ]; // 支援的語言列表
  late int _currentStreamSpeed; // 當前串流速度

  @override
  void initState() {
    super.initState();
    _currentStreamSpeed = widget.streamSpeed; // 初始化串流速度
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        children: [
          // 深色模式切換
          _buildSectionTitle('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.toggleTheme();
              },
            ),
          ),
          const Divider(),
          // 通知開關
          _buildSectionTitle('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          const Divider(),
          // 語言選擇
          _buildSectionTitle('Language'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            onTap: _showLanguageSelectionDialog,
          ),
          const Divider(),
          // 串流速度設置
          _buildSectionTitle('Stream Settings'),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Stream Speed'),
            subtitle: Text('Current: $_currentStreamSpeed ms/character'),
            onTap: _showStreamSpeedDialog,
          ),
          const Divider(),
          // 關於頁面
          _buildSectionTitle('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Flutter AI',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Flutter AI Team',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _languages.map((language) {
                  return RadioListTile<String>(
                    title: Text(language),
                    value: language,
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showStreamSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Stream Speed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _currentStreamSpeed.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                label: '$_currentStreamSpeed ms/character',
                onChanged: (value) {
                  setState(() {
                    _currentStreamSpeed = value.toInt();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onStreamSpeedChanged(_currentStreamSpeed);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
