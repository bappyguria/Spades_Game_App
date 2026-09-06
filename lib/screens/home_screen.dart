import 'package:flutter/material.dart';
import '../utils/app_orientation.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _backgroundSoundEnabled = true;
  bool _cardSoundEnabled = true;

  // ─── থিম কালার ────────────────────────────────────────────────
  static const Color bgColor = Color(0xFF0B0B10);
  static const Color yellow = Color(0xFFFAC775);
  static const Color yellowDark = Color(0xFF2C1D02);
  static const Color blue = Color(0xFF378ADD);
  static const Color blueDark = Color(0xFF042C53);
  static const Color cardBg = Color(0xFF15151C);

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tune, color: yellow),
              SizedBox(width: 10),
              Text('SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: _backgroundSoundEnabled,
                onChanged: (value) {
                  setDialogState(() => _backgroundSoundEnabled = value);
                  setState(() {});
                },
                activeThumbColor: yellow,
                title: const Text('Background sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Music and ambient audio', style: TextStyle(color: Colors.white54, fontSize: 12)),
                secondary: Icon(_backgroundSoundEnabled ? Icons.volume_up : Icons.volume_off, color: yellow),
              ),
              SwitchListTile(
                value: _cardSoundEnabled,
                onChanged: (value) {
                  setDialogState(() => _cardSoundEnabled = value);
                  setState(() {});
                },
                activeThumbColor: blue,
                title: const Text('Card sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Sound when cards are played', style: TextStyle(color: Colors.white54, fontSize: 12)),
                secondary: Icon(_cardSoundEnabled ? Icons.style : Icons.style_outlined, color: blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('DONE', style: TextStyle(color: yellow, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'SPADES GAME',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_outline, color: yellow),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings_outlined, color: blue),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo (asset image) ────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardBg,
                      border: Border.all(color: yellow.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: yellow.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Image.asset(
                          'assets/images/Spades_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Title ──────────────────────────────────────────
                  const Text(
                    'SPADES GAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Play with friends online',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ─── Row 1: CREATE ROOM + JOIN ROOM ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'CREATE ROOM',
                          icon: Icons.add,
                          backgroundColor: yellow,
                          contentColor: yellowDark,
                          onPressed: () {
                            AppOrientation.setPortrait();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateRoomScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'JOIN ROOM',
                          icon: Icons.login,
                          backgroundColor: blue,
                          contentColor: blueDark,
                          onPressed: () {
                            AppOrientation.setPortrait();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinRoomScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── Row 2: FRIEND PLAY + OFFLINE PLAY ──────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'FRIEND PLAY',
                          icon: Icons.people,
                          backgroundColor: cardBg,
                          contentColor: yellow,
                          borderColor: yellow,
                          onPressed: () {
                            AppOrientation.setPortrait();
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const FriendPlayScreen(),
                            //   ),
                            // );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'OFFLINE PLAY',
                          icon: Icons.wifi_off,
                          backgroundColor: cardBg,
                          contentColor: blue,
                          borderColor: blue,
                          onPressed: () {
                            AppOrientation.setPortrait();
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const OfflinePlayScreen(),
                            //   ),
                            // );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ─── Version Info ────────────────────────────────────
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable premium button (icon on top, label below) ───────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color contentColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.contentColor,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.5)
                : BorderSide.none,
          ),
          elevation: borderColor != null ? 0 : 6,
          shadowColor: backgroundColor.withValues(alpha: 0.4),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: contentColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}