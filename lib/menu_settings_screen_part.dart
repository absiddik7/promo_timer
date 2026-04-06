part of 'main.dart';

class MenuSettingsScreen extends StatelessWidget {
  const MenuSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MenuCard(
            title: 'Library / Timer Theme',
            subtitle: 'Candle, Sand Timer, and future themes',
            icon: Icons.palette_outlined,
          ),
          SizedBox(height: 12),
          _MenuCard(
            title: 'Audio',
            subtitle: 'Sound effects and volume',
            icon: Icons.volume_up_outlined,
          ),
          SizedBox(height: 12),
          _MenuCard(
            title: 'Timer',
            subtitle: 'Default duration and timer behavior',
            icon: Icons.timer_outlined,
          ),
          SizedBox(height: 12),
          _MenuCard(
            title: 'Haptics',
            subtitle: 'Feedback on interactions and completion',
            icon: Icons.vibration_outlined,
          ),
          SizedBox(height: 12),
          _MenuCard(
            title: 'Display',
            subtitle: 'Keep screen on and visual options',
            icon: Icons.display_settings_outlined,
          ),
          SizedBox(height: 12),
          _MenuCard(
            title: 'About',
            subtitle: 'App version and details',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF5D080)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}
