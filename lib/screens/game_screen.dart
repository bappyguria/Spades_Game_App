import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/game_service.dart';
import '../services/turn_service.dart';
import 'home_screen.dart';
import '../widgets/round_summary_dialog.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
class _C {
  static const bgDeep = Color(0xFF0A1A2B);
  static const bgTable = Color(0xFF12304A);
  static const bgPanel = Color(0xFF1B3A5C);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFFD700);
  static const goldDark = Color(0xFF996515);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF43A047);
  static const white = Colors.white;
  static const white80 = Color(0xCCFFFFFF);
  static const white50 = Color(0x80FFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const black = Colors.black;
}

final _goldGrad = const LinearGradient(
  colors: [
    Color(0xFF996515),
    Color(0xFFD4AF37),
    Color(0xFFFFD700),
    Color(0xFFD4AF37),
    Color(0xFF996515),
  ],
  stops: [0.0, 0.2, 0.5, 0.8, 1.0],
);

final _panelGrad = const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1B3A5C), Color(0xFF0E2A42)],
);

final _tableBg = const RadialGradient(
  center: Alignment.center,
  radius: 1.0,
  colors: [Color(0xFF163C5A), Color(0xFF081A2B)],
);

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _Nameplate extends StatelessWidget {
  const _Nameplate({
    required this.name,
    this.isTurn = false,
    this.isSmallScreen = false,
  });
  final String name;
  final bool isTurn;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 2 : 4,
        vertical: isSmallScreen ? 0 : 1,
      ),
      decoration: BoxDecoration(
        gradient: isTurn ? _goldGrad : _panelGrad,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isTurn ? _C.goldLight : _C.goldDark,
          width: 1,
        ),
        boxShadow: isTurn
            ? [BoxShadow(color: _C.gold.withOpacity(.3), blurRadius: 4)]
            : [],
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isTurn ? _C.black : _C.white80,
          fontSize: isSmallScreen ? 8 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _BidTricksBar extends StatelessWidget {
  const _BidTricksBar({
    required this.tricks,
    required this.bid,
    this.isSmallScreen = false,
  });
  final int tricks, bid;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 2 : 4,
        vertical: isSmallScreen ? 0 : 1,
      ),
      decoration: BoxDecoration(
        color: _C.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _C.goldDark, width: 1),
      ),
      child: Text(
        '$tricks/$bid',
        style: TextStyle(
          color: _C.goldLight,
          fontSize: isSmallScreen ? 8 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PointDisplay extends StatelessWidget {
  const _PointDisplay({required this.point, this.isSmallScreen = false});
  final int point;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 2 : 4,
        vertical: isSmallScreen ? 0 : 1,
      ),
      decoration: BoxDecoration(
        color: _C.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _C.gold, width: 1),
      ),
      child: Text(
        'P: $point',
        style: TextStyle(
          color: _C.goldLight,
          fontSize: isSmallScreen ? 7 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onTap,
    this.height = 30,
  });
  final String label;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _C.goldDark, width: 1.5),
          boxShadow: [BoxShadow(color: _C.gold.withOpacity(.4), blurRadius: 8)],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: _C.black,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main Game Screen State ────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TurnService _turnService = TurnService();
  bool _hasShownWinner = false;
  bool _hasRequestedBidDialog = false;
  bool _hasShownRoundSummary = false;
  bool _isBidDialogShowing = false;
  bool _isProcessingBid = false;
  bool _isPlayingCard = false;
  bool _isReportingMissingHeart = false;
  bool _isReportingMissingSuit = false;
  String _lastRoomMessageId = '';
  BuildContext? _bidDialogContext;
  BuildContext? _summaryDialogContext;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _hasShownRoundSummary = false;
  }

  @override
  void dispose() {
    // ✅ Game Screen থেকে বের হলে Portrait Mode এ ফিরে যাবে

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: _C.bgDeep,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return const _ErrorView('Room not found');
            }

            final data = snapshot.data!.data()!;
            final players = _normalizePlayers(data['players']);
            final hands = Map<String, dynamic>.from(data['hands'] ?? {});
            final myCards = _normalizeCards(hands[uid]);
            const nonSpadeSuits = ['♣', '♦', '♥'];
            final missingSuit = nonSpadeSuits.firstWhere(
              (suit) =>
                  !myCards.any((card) => card['suit']?.toString() == suit),
              orElse: () => '',
            );
            final sortedCards = List<Map<String, dynamic>>.from(myCards)
              ..sort(_compareCards);
            final currentTurn = data['currentTurn']?.toString() ?? '';
            final status = data['status']?.toString() ?? '';
            final missingSpadePlayers =
                (data['missingSpadePlayers'] as List<dynamic>? ?? [])
                    .map((entry) => entry.toString())
                    .toList();
            final tableCards = _normalizeTableCards(data['tableCards']);
            final bids = Map<String, dynamic>.from(data['bids'] ?? {});
            final tricks = Map<String, dynamic>.from(data['tricks'] ?? {});
            final playerScores = Map<String, int>.from(
              data['playerScores'] ?? {},
            );
            final winner = data['winner']?.toString() ?? '';
            final gameOver = data['gameOver'] == true;
            final isMyTurn = currentTurn == uid && !gameOver;
            final hasSubmittedBid = bids.containsKey(uid);

            final bidTurn = data['bidTurn']?.toString() ?? '';
            final bidOrder = (data['bidOrder'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();
            final isMyBidTurn =
                status == 'bidding' &&
                bidTurn == uid &&
                !hasSubmittedBid &&
                !gameOver &&
                players.length == 4;
            final allBidsDone =
                bids.length == players.length && players.length == 4;

            final showSummary = data['showSummary'] == true;

            final myPoint = playerScores[uid] ?? 0;

            // Serial order:
            // 0 = Me (Bottom)
            // 1 = Right
            // 2 = Top
            // 3 = Left
            final myIndex = players.indexWhere(
              (p) => p['uid']?.toString() == uid,
            );
            final total = players.length;

            Map<String, dynamic>? playerAt(int rel) {
              if (total == 0) return null;
              final abs = (myIndex + rel) % total;
              return abs < players.length ? players[abs] : null;
            }

            String uidAt(int rel) => playerAt(rel)?['uid']?.toString() ?? '';
            String nameAt(int rel) =>
                playerAt(rel)?['name']?.toString() ?? 'Player';

            // Trick Winner Detect
            final trickWinner = data['trickWinner']?.toString() ?? '';

            final roomMessage = data['roomMessage'];
            if (roomMessage is Map) {
              final messageId = roomMessage['id']?.toString() ?? '';
              if (messageId.isNotEmpty && messageId != _lastRoomMessageId) {
                _lastRoomMessageId = messageId;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final message = roomMessage['text']?.toString() ?? '';
                  if (message.isNotEmpty) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(message),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                  }
                });
              }
            }

            if (showSummary && !_hasShownRoundSummary) {
              _hasShownRoundSummary = true;
              final summaryData = data['roundSummary'];
              if (summaryData != null && summaryData is Map<String, dynamic>) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _showRoundSummaryDialog(summaryData, players),
                );
              }
            }

            if (isMyBidTurn &&
                !_isBidDialogShowing &&
                !_hasRequestedBidDialog &&
                !_isProcessingBid) {
              _hasRequestedBidDialog = true;
              _isBidDialogShowing = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showBidDialog(
                  players: players,
                  bids: bids,
                  uid: uid,
                  bidOrder: bidOrder,
                );
              });
            }

            if ((allBidsDone || (!isMyBidTurn && _bidDialogContext != null)) &&
                _isBidDialogShowing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_bidDialogContext != null) {
                  Navigator.of(_bidDialogContext!).pop();
                  _bidDialogContext = null;
                }
                setState(() {
                  _isBidDialogShowing = false;
                  _hasRequestedBidDialog = false;
                  _isProcessingBid = false;
                });
              });
            }

            if (gameOver && winner.isNotEmpty && !_hasShownWinner) {
              _hasShownWinner = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _showWinnerDialog(
                  winner: winner,
                  playerScores: playerScores,
                ),
              );
            }

            return Stack(
              children: [
                // Background
                Container(decoration: BoxDecoration(gradient: _tableBg)),

                // Main Board (Full Screen)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                    child: _FeltTable(
                      players: players,
                      tableCards: tableCards,
                      currentTurn: currentTurn,
                      myUid: uid,
                      trickWinner: trickWinner,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ),

                // Player Details - Serial Order অনুযায়ী
                // Me (Bottom) - সবচেয়ে নিচে
                Positioned(
                  bottom: isSmallScreen ? 8 : 30,
                  left: isSmallScreen ? 8 : 20,
                  child: _PlayerCornerCard(
                    player: players.isNotEmpty ? players.first : null,
                    name: 'You',
                    isTurn: isMyTurn,
                    bid: _valueFor(bids, uid),
                    tricks: _valueFor(tricks, uid),
                    point: myPoint,
                    isMe: true,
                    isSmallScreen: isSmallScreen,
                  ),
                ),

                // Right Player (Serial 1)
                Positioned(
                  top: isSmallScreen ? 60 : 120,
                  right: isSmallScreen ? 8 : 20,
                  child: _PlayerCornerCard(
                    player: playerAt(1),
                    name: nameAt(1),
                    isTurn: currentTurn == uidAt(1),
                    bid: _valueFor(bids, uidAt(1)),
                    tricks: _valueFor(tricks, uidAt(1)),
                    point: _valueFor(playerScores, uidAt(1)),
                    isSmallScreen: isSmallScreen,
                  ),
                ),

                // Top Player (Serial 2)
                Positioned(
                  top: isSmallScreen ? 8 : 30,
                  left: 0,
                  right: isSmallScreen ? 100 : 150,
                  child: Center(
                    child: _PlayerCornerCard(
                      player: playerAt(2),
                      name: nameAt(2),
                      isTurn: currentTurn == uidAt(2),
                      bid: _valueFor(bids, uidAt(2)),
                      tricks: _valueFor(tricks, uidAt(2)),
                      point: _valueFor(playerScores, uidAt(2)),
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ),

                // Left Player (Serial 3)
                Positioned(
                  left: isSmallScreen ? 8 : 20,
                  top: isSmallScreen ? 60 : 120,
                  child: _PlayerCornerCard(
                    player: playerAt(3),
                    name: nameAt(3),
                    isTurn: currentTurn == uidAt(3),
                    bid: _valueFor(bids, uidAt(3)),
                    tricks: _valueFor(tricks, uidAt(3)),
                    point: _valueFor(playerScores, uidAt(3)),
                    isSmallScreen: isSmallScreen,
                  ),
                ),

                // Target Badge (Top Center)
                Positioned(
                  top: isSmallScreen ? 8 : 20,
                  left: 500,
                  right: 0,
                  child: Center(
                    child: _TargetBadge(isSmallScreen: isSmallScreen),
                  ),
                ),

                if (status == 'suit_check' &&
                    missingSpadePlayers.contains(uid) &&
                    !gameOver)
                  Positioned(
                    top: isSmallScreen ? 42 : 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _isReportingMissingHeart
                            ? null
                            : () => _startNextRoundAfterSuitCheck(players),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(
                          _isReportingMissingHeart
                              ? 'পাঠানো হচ্ছে...'
                              : 'NEXT ROUND',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.red,
                          foregroundColor: _C.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (status == 'bidding' && missingSuit.isNotEmpty && !gameOver)
                  Positioned(
                    top: isSmallScreen ? 42 : 150,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _isReportingMissingSuit
                            ? null
                            : () => _reportMissingSuit(players, missingSuit),
                        icon: const Icon(Icons.report_problem, size: 16),
                        label: Text(
                          _isReportingMissingSuit
                              ? 'পাঠানো হচ্ছে...'
                              : 'আমার কাছে $missingSuit কার্ড নেই',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.red,
                          foregroundColor: _C.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Waiting Banner
                if (players.length == 4 &&
                    !gameOver &&
                    bids.length < players.length)
                  Positioned(
                    top: isSmallScreen ? 50 : 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _WaitingBanner(
                        hasSubmittedBid: hasSubmittedBid,
                        readyCount: bids.length,
                        total: players.length,
                        isMyBidTurn: isMyBidTurn,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ),

                // Bottom (You Cards)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _MyHand(
                    cards: sortedCards,
                    isMyTurn: isMyTurn,
                    isSmallScreen: isSmallScreen,
                    onCardTap: (card) {
                      _playCard(card);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Helper Methods ──────────────────────────────────────────────────────────
  Future<void> _showWinnerDialog({
    required String winner,
    required Map<String, int> playerScores,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _panelGrad,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.gold, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: _C.goldLight, size: 40),
              const SizedBox(height: 8),
              Text(
                '$winner WINS!',
                style: const TextStyle(
                  color: _C.goldLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...playerScores.entries.map(
                (e) => Text(
                  '${e.key.substring(0, 1)}: ${e.value}',
                  style: const TextStyle(color: _C.white80, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.goldLight,
                        side: const BorderSide(color: _C.gold),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GoldButton(
                      label: 'Play Again',
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _hasShownRoundSummary = false;
                          _hasShownWinner = false;
                          _hasRequestedBidDialog = false;
                          _bidDialogContext = null;
                          _isBidDialogShowing = false;
                          _isProcessingBid = false;
                        });
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({
                              'playerScores': {},
                              'winner': '',
                              'gameOver': false,
                              'roundNumber': 0,
                              'currentDealerIndex': 0,
                            });
                        final roomDoc = await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .get();
                        final players = roomDoc['players'] as List;
                        await GameService.distributeCards(
                          widget.roomId,
                          players,
                          round: 1,
                          dealerIndex: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoundSummaryDialog(
    Map<String, dynamic> summary,
    List<Map<String, dynamic>> players,
  ) async {
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _summaryDialogContext = ctx;
        return RoundSummaryDialog(
          roundNumber: summary['roundNumber'] ?? 1,
          playerScores: Map<String, int>.from(summary['playerScores'] ?? {}),
          playerBids: Map<String, int>.from(summary['playerBids'] ?? {}),
          playerTricks: Map<String, int>.from(summary['playerTricks'] ?? {}),
          dealerUid: summary['dealerUid'] ?? '',
          players: players,
        );
      },
    );
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted && _summaryDialogContext != null) {
        Navigator.of(_summaryDialogContext!).pop();
        _summaryDialogContext = null;
      }
    });
    await dialogFuture;
  }

  Future<void> _submitBid({required String uid, required int bid}) async {
    if (_isProcessingBid) return;
    setState(() => _isProcessingBid = true);
    try {
      await _turnService.submitBid(roomId: widget.roomId, uid: uid, bid: bid);
      HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessingBid = false);
    }
  }

  Future<void> _startNextRoundAfterSuitCheck(
    List<Map<String, dynamic>> players,
  ) async {
    if (_isReportingMissingHeart) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() => _isReportingMissingHeart = true);
    try {
      await _turnService.startNextRoundAfterSuitCheck(
        roomId: widget.roomId,
        uid: uid,
        players: players,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isReportingMissingHeart = false);
    }
  }

  Future<void> _reportMissingSuit(
    List<Map<String, dynamic>> players,
    String suit,
  ) async {
    if (_isReportingMissingSuit) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final player = players.firstWhere(
      (entry) => entry['uid']?.toString() == uid,
      orElse: () => <String, dynamic>{},
    );
    final playerName = player['name']?.toString() ?? 'A player';

    setState(() => _isReportingMissingSuit = true);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'roomMessage': {
              'id': DateTime.now().microsecondsSinceEpoch.toString(),
              'text': '$playerName এর কাছে কার্ড নেই।',
              'senderUid': uid,
            },
          });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isReportingMissingSuit = false);
    }
  }

  Future<void> _showBidDialog({
    required List<Map<String, dynamic>> players,
    required Map<String, dynamic> bids,
    required String uid,
    required List<String> bidOrder,
  }) async {
    if (!mounted) return;
    int localBid = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _bidDialogContext = dialogContext;
        return StatefulBuilder(
          builder: (ctx, setS) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: 140,
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _panelGrad,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.gold, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'BID',
                    style: TextStyle(
                      color: _C.goldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bids.length}/${players.length}',
                    style: const TextStyle(color: _C.white50, fontSize: 8),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _goldGrad,
                      boxShadow: [
                        BoxShadow(
                          color: _C.gold.withOpacity(.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$localBid',
                      style: const TextStyle(
                        color: _C.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleButton(
                        icon: Icons.remove,
                        color: _C.red,
                        size: 24,
                        onTap: () =>
                            setS(() => localBid = (localBid - 1).clamp(0, 13)),
                      ),
                      const SizedBox(width: 10),
                      _CircleButton(
                        icon: Icons.add,
                        color: _C.green,
                        size: 24,
                        onTap: () =>
                            setS(() => localBid = (localBid + 1).clamp(0, 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _GoldButton(
                    label: _isProcessingBid ? '...' : 'OK',
                    height: 24,
                    onTap: _isProcessingBid
                        ? null
                        : () async {
                            await _submitBid(uid: uid, bid: localBid);
                            if (!mounted) return;
                            if (_bidDialogContext != null) {
                              Navigator.pop(_bidDialogContext!);
                              _bidDialogContext = null;
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Card Play Animation + Logic
  Future<void> _playCard(Map<String, dynamic> card) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || _isPlayingCard) return;

    setState(() => _isPlayingCard = true);

    // ✅ Animation: কার্ডটি হাত থেকে (নিচ থেকে) শুরু হয়ে টেবিলে Slide/Fly করবে
    _showCardFlyAnimation(card);

    try {
      await _turnService.playCard(roomId: widget.roomId, uid: uid, card: card);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isPlayingCard = false);
    }
  }

  // ✅ Card Fly Animation (নিচ থেকে শুরু → টেবিলে)
  void _showCardFlyAnimation(Map<String, dynamic> card) {
    final overlay = Overlay.of(context);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FlyingCardOverlay(
        card: card,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  List<Map<String, dynamic>> _normalizePlayers(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  List<Map<String, dynamic>> _normalizeCards(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  List<Map<String, dynamic>> _normalizeTableCards(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  int _compareCards(Map<String, dynamic> a, Map<String, dynamic> b) {
    const so = {'♣': 0, '♦': 1, '♥': 2, '♠': 3};
    const ro = {
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      '10': 10,
      'J': 11,
      'Q': 12,
      'K': 13,
      'A': 14,
    };
    final as_ = so[a['suit'] ?? ''] ?? 0;
    final bs_ = so[b['suit'] ?? ''] ?? 0;
    if (as_ != bs_) return as_.compareTo(bs_);
    return (ro[a['rank'] ?? ''] ?? 0).compareTo(ro[b['rank'] ?? ''] ?? 0);
  }

  int _valueFor(Map<String, dynamic> src, String uid) =>
      uid.isEmpty ? 0 : (src[uid] is num ? (src[uid] as num).toInt() : 0);
}

// ── UI Components ─────────────────────────────────────────────────────────────

// Player Detail Card (Serial Order অনুযায়ী)
class _PlayerCornerCard extends StatelessWidget {
  const _PlayerCornerCard({
    required this.player,
    required this.name,
    required this.isTurn,
    required this.bid,
    required this.tricks,
    required this.point,
    this.isMe = false,
    this.isSmallScreen = false,
  });
  final Map<String, dynamic>? player;
  final String name;
  final bool isTurn;
  final int bid, tricks, point;
  final bool isMe;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: _panelGrad,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTurn ? _C.goldLight : _C.goldDark,
          width: isTurn ? 2 : 1,
        ),
        boxShadow: isTurn
            ? [BoxShadow(color: _C.goldLight.withOpacity(.3), blurRadius: 8)]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Nameplate(
            name: isMe ? 'You' : name,
            isTurn: isTurn,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 2 : 3),
          _BidTricksBar(tricks: tricks, bid: bid, isSmallScreen: isSmallScreen),
          SizedBox(height: isSmallScreen ? 2 : 3),
          _PointDisplay(point: point, isSmallScreen: isSmallScreen),
          if (isTurn) ...[
            SizedBox(height: isSmallScreen ? 2 : 3),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              decoration: BoxDecoration(
                color: _C.goldLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'TURN',
                style: TextStyle(
                  color: _C.black,
                  fontSize: isSmallScreen ? 5 : 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge({this.isSmallScreen = false});
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: _goldGrad,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _C.goldDark, width: 1.5),
        boxShadow: [BoxShadow(color: _C.gold.withOpacity(.5), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TARGET',
            style: TextStyle(
              color: _C.black,
              fontSize: isSmallScreen ? 6 : 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          Text(
            '100',
            style: TextStyle(
              color: _C.black,
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeltTable extends StatelessWidget {
  const _FeltTable({
    required this.players,
    required this.tableCards,
    required this.currentTurn,
    required this.myUid,
    required this.trickWinner,
    this.isSmallScreen = false,
  });
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> tableCards;
  final String currentTurn, myUid;
  final String trickWinner;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final seatCards = <String, Map<String, dynamic>>{};
    for (final e in tableCards) {
      final u = e['uid']?.toString() ?? '';
      if (u.isNotEmpty)
        seatCards[u] = Map<String, dynamic>.from(e['card'] ?? {});
    }

    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    final total = players.length;
    String uidAt(int rel) => total == 0
        ? ''
        : players[(myIndex + rel) % total]['uid']?.toString() ?? '';

    final topUid = uidAt(2);
    final leftUid = uidAt(3);
    final rightUid = uidAt(1);

    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF163C5A), Color(0xFF081A2B)],
          radius: 0.9,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
        border: Border.all(color: _C.gold, width: isSmallScreen ? 1.5 : 2),
        boxShadow: [BoxShadow(color: _C.gold.withOpacity(.15), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Text(
                '♠',
                style: TextStyle(
                  fontSize: isSmallScreen ? 80 : 120,
                  color: _C.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Table Cards (Serial Order অনুযায়ী)
          // Top Card
          Positioned(
            top: isSmallScreen ? 20 : 40,
            left: 0,
            right: 0,
            child: Center(
              child: _TableCardSlot(
                card: seatCards[topUid],
                label: nameAt(2),
                isTurn: currentTurn == topUid,
                isWinner: trickWinner == topUid,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ),
          // Left Card
          Positioned(
            left: isSmallScreen ? 40 : 200,
            top: 0,
            bottom: 0,
            child: Center(
              child: _TableCardSlot(
                card: seatCards[leftUid],
                label: nameAt(3),
                isTurn: currentTurn == leftUid,
                isWinner: trickWinner == leftUid,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ),
          // Right Card
          Positioned(
            right: isSmallScreen ? 40 : 200,
            top: 0,
            bottom: 0,
            child: Center(
              child: _TableCardSlot(
                card: seatCards[rightUid],
                label: nameAt(1),
                isTurn: currentTurn == rightUid,
                isWinner: trickWinner == rightUid,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ),
          // Bottom Card (You)
          Positioned(
            bottom: isSmallScreen ? 20 : 70,
            left: 0,
            right: 0,
            child: Center(
              child: _TableCardSlot(
                card: seatCards[myUid],
                label: 'You',
                isTurn: currentTurn == myUid,
                isWinner: trickWinner == myUid,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String nameAt(int rel) {
    if (players.isEmpty) return 'Player';
    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    final abs = (myIndex + rel) % players.length;
    return players[abs]['name']?.toString() ?? 'Player';
  }
}

class _TableCardSlot extends StatelessWidget {
  const _TableCardSlot({
    required this.card,
    required this.label,
    required this.isTurn,
    required this.isWinner,
    this.isSmallScreen = false,
  });
  final Map<String, dynamic>? card;
  final String label;
  final bool isTurn;
  final bool isWinner;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final double cardW = isSmallScreen ? 48.0 : 60.0;
    final double cardH = isSmallScreen ? 68.0 : 86.0;

    if (card == null) {
      return Container(
        width: cardW,
        height: cardH,
        decoration: BoxDecoration(
          color: isTurn ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTurn ? _C.goldLight : _C.white20,
            width: isTurn ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isTurn ? _C.goldLight : _C.white50,
            fontSize: isSmallScreen ? 8 : 10,
          ),
        ),
      );
    }

    final suit = card!['suit']?.toString() ?? '';
    final rank = card!['rank']?.toString() ?? '';
    final isRed = suit == '♥' || suit == '♦';
    final suitColor = isRed ? _C.red : _C.black;

    // Winner হলে Gold Glow Effect
    final borderColor = isWinner
        ? Colors.greenAccent
        : (isTurn ? _C.goldLight : _C.goldDark);
    final boxShadow = isWinner
        ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ];

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isWinner ? 3 : 1),
        boxShadow: boxShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 14,
                    fontWeight: FontWeight.w900,
                    color: suitColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  suit,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 16,
                    color: suitColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 2,
            right: 3,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 14,
                      fontWeight: FontWeight.w900,
                      color: suitColor,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    suit,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 16,
                      color: suitColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              suit,
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 36,
                color: suitColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Hand (Cards bigger) ─────────────────────────────────────────────────────
class _MyHand extends StatelessWidget {
  const _MyHand({
    required this.cards,
    required this.isMyTurn,
    required this.isSmallScreen,
    required this.onCardTap,
  });
  final List<Map<String, dynamic>> cards;
  final bool isMyTurn;
  final bool isSmallScreen;
  final void Function(Map<String, dynamic>) onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox(height: 40);

    // ✅ কার্ডের সাইজ বড় করুন
    final double cardW = isSmallScreen ? 56.0 : 80.0;
    final double cardH = isSmallScreen ? 72.0 : 100.0;
    final double fontSize = isSmallScreen ? 12.0 : 16.0;
    final double suitSize = isSmallScreen ? 16.0 : 22.0;
    final double bigSuitSize = isSmallScreen ? 36.0 : 48.0;

    // ✅ কার্ডের স্পেস বাড়ান
    final double visibleHeight = isSmallScreen ? 36.0 : 50.0;

    return SizedBox(
      height: visibleHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final spacing = cards.length > 1
              ? ((constraints.maxWidth * .7) / (cards.length - 1)).clamp(
                  isSmallScreen ? 10.0 : 14.0,
                  isSmallScreen ? 24.0 : 46.0,
                )
              : 0.0;
          final handWidth = cardW + ((cards.length - 1) * spacing);
          final startLeft = (constraints.maxWidth - handWidth) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: List.generate(cards.length, (i) {
              final card = cards[i];
              final suit = card['suit']?.toString() ?? '';
              final rank = card['rank']?.toString() ?? '';
              final isRed = suit == '♥' || suit == '♦';
              final suitColor = isRed ? _C.red : _C.black;
              final angle = (i - cards.length / 2) * 0.01;

              return Positioned(
                left: startLeft + (i * spacing),
                bottom: isSmallScreen ? 2.0 : -15,
                child: GestureDetector(
                  // ✅ Behavior: HitTestBehavior.opaque - পুরো কার্ডের উপর ক্লিক কাজ করবে
                  behavior: HitTestBehavior.opaque,
                  onTap: isMyTurn ? () => onCardTap(card) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: cardW,
                    height: cardH,
                    transform: Matrix4.rotationZ(angle),
                    transformAlignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 6.0 : 8.0,
                      ),
                      border: Border.all(
                        color: isMyTurn ? _C.goldDark : Colors.grey,
                        width: isMyTurn ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 6.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 3,
                          left: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rank,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w900,
                                  color: suitColor,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                suit,
                                style: TextStyle(
                                  fontSize: suitSize,
                                  color: suitColor,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          right: 4,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rank,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w900,
                                    color: suitColor,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  suit,
                                  style: TextStyle(
                                    fontSize: suitSize,
                                    color: suitColor,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            suit,
                            style: TextStyle(
                              fontSize: bigSuitSize,
                              color: suitColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}


// ── Flying Card Overlay (Card Play Animation) ─────────────────────────────────
class _FlyingCardOverlay extends StatefulWidget {
  final Map<String, dynamic> card;
  final VoidCallback onComplete;

  const _FlyingCardOverlay({required this.card, required this.onComplete});

  @override
  State<_FlyingCardOverlay> createState() => _FlyingCardOverlayState();
}

class _FlyingCardOverlayState extends State<_FlyingCardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // ✅ MediaQuery থেকে পাওয়া সাইজ সংরক্ষণ করার জন্য
  Size? _screenSize;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // ✅ দ্রুত Animation (250ms)
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ MediaQuery এখন নিরাপদে ব্যবহার করা যাবে
    final size = MediaQuery.of(context).size;
    if (_screenSize != size) {
      _screenSize = size;

      // ✅ Animation শুরুর অবস্থান: নিচে (হাত) থেকে শুরু হবে
      _positionAnimation = Tween<Offset>(
        begin: Offset(size.width / 2, size.height - 50), // Bottom (Hand)
        end: Offset(size.width / 2, size.height / 2), // Center (Table)
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _rotationAnimation = Tween<double>(
        begin: 0,
        end: 0.1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }

    // ✅ Animation শুরু করুন (প্রথমবার)
    if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward().whenComplete(() {
        widget.onComplete();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suit = widget.card['suit']?.toString() ?? '';
    final rank = widget.card['rank']?.toString() ?? '';
    final isRed = suit == '♥' || suit == '♦';
    final suitColor = isRed ? Colors.red : Colors.black;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx - 40,
          top: _positionAnimation.value.dy - 60,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        left: 6,
                        child: Text(
                          rank,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: suitColor,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 6,
                        child: Text(
                          suit,
                          style: TextStyle(fontSize: 16, color: suitColor),
                        ),
                      ),
                      Center(
                        child: Text(
                          suit,
                          style: TextStyle(fontSize: 36, color: suitColor),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 6,
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: Text(
                            rank,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: suitColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Waiting Banner ─────────────────────────────────────────────────────────────
class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner({
    required this.hasSubmittedBid,
    required this.readyCount,
    required this.total,
    required this.isMyBidTurn,
    this.isSmallScreen = false,
  });
  final bool hasSubmittedBid;
  final int readyCount, total;
  final bool isMyBidTurn;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: _panelGrad,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.gold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMyBidTurn ? Icons.play_arrow : Icons.hourglass_top,
            color: isMyBidTurn ? _C.goldLight : _C.white50,
            size: isSmallScreen ? 10 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            hasSubmittedBid
                ? 'Waiting…'
                : (isMyBidTurn ? 'Your turn!' : 'Waiting…'),
            style: TextStyle(
              color: isMyBidTurn ? _C.goldLight : _C.white80,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: isMyBidTurn ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: _goldGrad,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$readyCount/$total',
              style: TextStyle(
                color: _C.black,
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 30,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: _C.gold, strokeWidth: 2),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: const TextStyle(color: _C.white80, fontSize: 14),
    ),
  );
}
