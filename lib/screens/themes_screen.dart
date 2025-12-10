import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/settings_provider.dart';
import '../providers/sensory_provider.dart';
import '../widgets/candle_painter.dart';
import '../widgets/hourglass_painter.dart';
import '../widgets/water_glass_painter.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sensory Themes',
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
      body: Consumer2<SettingsProvider, SensoryProvider>(
        builder: (context, settingsProvider, sensoryProvider, _) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildThemeCard(
                context,
                SensoryTheme.candle,
                sensoryProvider.getThemeConfig(SensoryTheme.candle),
                settingsProvider.state.selectedTheme == SensoryTheme.candle,
                () {
                  settingsProvider.setTheme(SensoryTheme.candle);
                },
              ),
              SizedBox(height: 24),
              _buildThemeCard(
                context,
                SensoryTheme.hourglass,
                sensoryProvider.getThemeConfig(SensoryTheme.hourglass),
                settingsProvider.state.selectedTheme == SensoryTheme.hourglass,
                () {
                  settingsProvider.setTheme(SensoryTheme.hourglass);
                },
              ),
              SizedBox(height: 24),
              _buildThemeCard(
                context,
                SensoryTheme.waterGlass,
                sensoryProvider.getThemeConfig(SensoryTheme.waterGlass),
                settingsProvider.state.selectedTheme == SensoryTheme.waterGlass,
                () {
                  settingsProvider.setTheme(SensoryTheme.waterGlass);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    SensoryTheme theme,
    SensoryThemeConfig config,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? config.primaryColor : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.02),
        ),
        child: Column(
          children: [
            // Theme preview
            SizedBox(
              height: 200,
              child: _buildThemePreview(theme),
            ),
            // Theme info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        config.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: config.primaryColor),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    config.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
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

  Widget _buildThemePreview(SensoryTheme theme) {
    switch (theme) {
      case SensoryTheme.candle:
        return CustomPaint(
          painter: CandlePainter(progress: 0.5),
          size: Size.infinite,
        );
      case SensoryTheme.hourglass:
        return CustomPaint(
          painter: HourglassPainter(progress: 0.5),
          size: Size.infinite,
        );
      case SensoryTheme.waterGlass:
        return CustomPaint(
          painter: WaterGlassPainter(progress: 0.5),
          size: Size.infinite,
        );
    }
  }
}
