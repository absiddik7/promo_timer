import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Sound settings
              _buildSettingSection(
                context,
                'Audio',
                [
                  _buildToggleSetting(
                    context,
                    'Sound Effects',
                    settingsProvider.state.soundEnabled,
                    (value) => settingsProvider.toggleSound(),
                  ),
                  SizedBox(height: 16),
                  _buildSliderSetting(
                    context,
                    'Volume',
                    settingsProvider.state.soundVolume,
                    (value) => settingsProvider.setVolume(value),
                  ),
                ],
              ),
              SizedBox(height: 32),
              // Timer settings
              _buildSettingSection(
                context,
                'Timer',
                [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Default Duration',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        Builder(builder: (ctx) {
                          final v = settingsProvider.state.defaultDurationMinutes;
                          String label;
                          if (v < 1.0) {
                            label = '${(v * 60).round()} sec';
                          } else if (v % 1.0 == 0) {
                            label = '${v.toInt()} min';
                          } else {
                            label = '${v.toStringAsFixed(1)} min';
                          }
                          return Text(
                            label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Slider(
                    value: settingsProvider.state.defaultDurationMinutes,
                    onChanged: (value) => settingsProvider.setDefaultDuration(value),
                    min: 0.5,
                    max: 60.0,
                    divisions: 119,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white10,
                  ),
                ],
              ),
              SizedBox(height: 32),
              // Haptic settings
              _buildSettingSection(
                context,
                'Haptics',
                [
                  _buildToggleSetting(
                    context,
                    'Haptic Feedback',
                    settingsProvider.state.hapticEnabled,
                    (value) => settingsProvider.toggleHaptic(),
                  ),
                ],
              ),
              SizedBox(height: 32),
              // Display settings
              _buildSettingSection(
                context,
                'Display',
                [
                  _buildToggleSetting(
                    context,
                    'Keep Screen On',
                    settingsProvider.state.keepScreenOn,
                    (value) => settingsProvider.toggleKeepScreenOn(),
                  ),
                ],
              ),
              SizedBox(height: 32),
              // About
              _buildSettingSection(
                context,
                'About',
                [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ZenFlow Timer v1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A meditation-grade Pomodoro timer with sensory themes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white54,
                letterSpacing: 1,
              ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    BuildContext context,
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
          activeColor: Colors.white,
          inactiveColor: Colors.white10,
        ),
      ],
    );
  }
}
