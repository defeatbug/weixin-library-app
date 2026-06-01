import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

class DarkModeSettingPage extends StatefulWidget {
  const DarkModeSettingPage({super.key});

  static const routePath = '/settings/dark_mode';

  @override
  State<DarkModeSettingPage> createState() => _DarkModeSettingPageState();
}

class _DarkModeSettingPageState extends State<DarkModeSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('深色模式')),
      body: ListView(
        children: [
          _buildCard([
            SwitchListTile(
              title: const Text('跟随系统'),
              value: appTheme.auto,
              onChanged: (value) async {
                await appTheme.setFollowSystem(value);
                setState(() {});
              },
            ),
            if (!appTheme.auto)
              SwitchListTile(
                title: const Text('深色模式'),
                value: appTheme.brightness == Brightness.dark,
                onChanged: (value) async {
                  await appTheme.setDarkMode(value);
                  setState(() {});
                },
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '开启「跟随系统」后，应用会自动匹配系统的浅色/深色模式。',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 0.5, color: AppColors.divider, indent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}
