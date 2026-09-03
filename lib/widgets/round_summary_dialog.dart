import 'package:flutter/material.dart';

class RoundSummaryDialog extends StatelessWidget {
  final int roundNumber;
  final Map<String, int> playerScores;
  final Map<String, int> playerBids;
  final Map<String, int> playerTricks;
  final String dealerUid;
  final List<Map<String, dynamic>> players;

  const RoundSummaryDialog({
    super.key,
    required this.roundNumber,
    required this.playerScores,
    required this.playerBids,
    required this.playerTricks,
    required this.dealerUid,
    this.players = const [],
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;
    final isSmall = screenHeight < 700;

    String getName(String uid) {
      for (final p in players) {
        if (p['uid']?.toString() == uid)
          return p['name']?.toString() ?? 'Player';
      }
      return uid.substring(0, 1).toUpperCase();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 16,
        vertical: isSmall ? 10 : 16,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
        padding: EdgeInsets.all(isSmall ? 6 : 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2E40), Color(0xFF0D1B28)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD4A017), width: 1.2),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: isSmall ? 2 : 4,
                right: isSmall ? 2 : 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFD4A017),
                        Color(0xFFFFD866),
                        Color(0xFFD4A017),
                      ],
                      stops: [0, 0.5, 1],
                    ).createShader(bounds),
                    child: Text(
                      'Round $roundNumber Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 10 : 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmall ? 3 : 5),

                  // Player Scores (ছোট)
                  Container(
                    padding: EdgeInsets.all(isSmall ? 3 : 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: playerScores.entries.map((entry) {
                        final uid = entry.key;
                        final score = entry.value;
                        final bid = playerBids[uid] ?? 0;
                        final tricks = playerTricks[uid] ?? 0;
                        final diff = tricks - bid;
                        final scoreChange = diff >= 0
                            ? (bid * 10 + diff)
                            : -(bid * 10);
                        final isPos = scoreChange >= 0;
                        final isDealerPlayer = uid == dealerUid;
                        final playerName = getName(uid);

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmall ? 0 : 1,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: isSmall ? 6 : 8,
                                backgroundColor: isDealerPlayer
                                    ? Colors.amber.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                child: Text(
                                  playerName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: isDealerPlayer
                                        ? Colors.amber
                                        : Colors.white,
                                    fontSize: isSmall ? 5 : 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmall ? 2 : 3),
                              Expanded(
                                child: Text(
                                  '$playerName  |  B:$bid  |  T:$tricks',
                                  style: TextStyle(
                                    color: isDealerPlayer
                                        ? Colors.amber
                                        : Colors.white70,
                                    fontSize: isSmall ? 7 : 8,
                                  ),
                                ),
                              ),
                              Text(
                                'S:$score',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmall ? 7 : 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: isSmall ? 2 : 3),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmall ? 2 : 3,
                                  vertical: isSmall ? 0 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: isPos
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPos ? '+$scoreChange' : '$scoreChange',
                                  style: TextStyle(
                                    color: isPos ? Colors.green : Colors.red,
                                    fontSize: isSmall ? 7 : 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: isSmall ? 3 : 4),

                  SizedBox(height: isSmall ? 2 : 3),

                  Text(
                    'Target: 100',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isSmall ? 5 : 6,
                    ),
                  ),
                  SizedBox(height: isSmall ? 3 : 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
