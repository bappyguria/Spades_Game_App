import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color background = Color(0xFF0B0B10);
  static const Color card = Color(0xFF15151C);
  static const Color gold = Color(0xFFFAC775);
  static const Color blue = Color(0xFF378ADD);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : 'Spades Player';
    final email = user?.email?.trim().isNotEmpty == true ? user!.email! : 'Guest account';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text('PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [gold, Color(0xFFD4A017)]),
                boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.25), blurRadius: 24)],
              ),
              child: const Icon(Icons.person, size: 56, color: Color(0xFF2C1D02)),
            ),
            const SizedBox(height: 18),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 32),
            _ProfileInfoTile(icon: Icons.emoji_events_outlined, label: 'Player status', value: 'Ready to play', accent: gold),
            const SizedBox(height: 12),
            _ProfileInfoTile(icon: Icons.shield_outlined, label: 'Account', value: user == null ? 'Guest' : 'Connected', accent: blue),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({required this.icon, required this.label, required this.value, required this.accent});

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileScreen.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 25),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}