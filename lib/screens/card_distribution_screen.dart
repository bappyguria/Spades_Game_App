import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/game_service.dart';
import 'game_screen.dart';

class CardDistributionScreen extends StatefulWidget {
  final String roomId;
  final bool alreadyDistributed;

  const CardDistributionScreen({
    super.key,
    required this.roomId,
    this.alreadyDistributed = false,
  });

  @override
  State<CardDistributionScreen> createState() => _CardDistributionScreenState();
}

class _CardDistributionScreenState extends State<CardDistributionScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDistribution());
  }

  Future<void> _startDistribution() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection("rooms")
          .doc(widget.roomId)
          .get();

      final roomData = roomDoc.data() ?? {};
      final players = roomData["players"] as List? ?? [];

      debugPrint('📦 [CardDistribution] Starting card distribution...');
      debugPrint('   Room ID: ${widget.roomId}');
      debugPrint('   Already Distributed: ${widget.alreadyDistributed}');
      debugPrint('   Players Count: ${players.length}');

      final claimedDistribution = await FirebaseFirestore.instance
          .runTransaction<bool>((transaction) async {
            final currentRoom = await transaction.get(
              FirebaseFirestore.instance.collection('rooms').doc(widget.roomId),
            );
            final status = currentRoom.data()?['status']?.toString() ?? '';
            if (status != 'dealing') return false;

            transaction.update(currentRoom.reference, {
              'status': 'distributing',
            });
            return true;
          });

      if (claimedDistribution) {
        debugPrint('   ➜ Distributing cards for Round 1...');
        await GameService.distributeCards(widget.roomId, players);
        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(widget.roomId)
            .update({"status": "bidding"});
      } else if (!claimedDistribution) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots()
            .firstWhere((snapshot) => snapshot.data()?['status'] == 'bidding');
      }

      debugPrint('✅ [CardDistribution] Navigating to GameScreen...');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, animation, __) => GameScreen(roomId: widget.roomId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      debugPrint('❌ [CardDistribution] Error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      const Color(0xFF1B2740).withOpacity(0.8),
                      const Color(0xFF0B1220),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Player indicators
            _buildPlayerIndicator("Player 2", size.width / 2 - 40, 50),
            _buildPlayerIndicator("Player 3", 30, size.height / 2 - 30),
            _buildPlayerIndicator(
              "Player 4",
              size.width - 100,
              size.height / 2 - 30,
            ),
            _buildPlayerIndicator(
              "YOU",
              size.width / 2 - 40,
              size.height - 100,
            ),

            // ✅ Center card deck display
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B2740), Color(0xFF0E2A42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE8A93B),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8A93B).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🃏', style: TextStyle(fontSize: 50)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.alreadyDistributed ? 'NEXT ROUND' : 'ROUND 1',
                    style: const TextStyle(
                      color: Color(0xFFE8A93B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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

  Widget _buildPlayerIndicator(String name, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
