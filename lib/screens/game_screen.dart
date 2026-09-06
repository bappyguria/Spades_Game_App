import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/bloc/game_bloc.dart';
import '../core/bloc/game_event.dart';
import '../core/bloc/game_state.dart';
import '../services/presence_service.dart';
import 'home_screen.dart';
import '../utils/app_orientation.dart';
import '../utils/player_presence.dart';
import '../widgets/player_presence_indicator.dart';
import '../widgets/round_summary_dialog.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
class _C {
  static const bgDeep = Color(0xFF0A1A2B);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFFD700);
  static const goldDark = Color(0xFF996515);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF43A047);
  static const white = Colors.white;
  static const white80 = Color(0xCCFFFFFF);
  static const white50 = Color(0x80FFFFFF);
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
  colors: [Color(0xFF1454A0), Color(0xFF061632)],
);

final _woodTableGrad = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFFDF7A),
    Color(0xFFC78329),
    Color(0xFF6A3213),
    Color(0xFFB86D20),
    Color(0xFFFFD96A),
  ],
  stops: [0.0, 0.22, 0.50, 0.78, 1.0],
);

final _feltTableGrad = const RadialGradient(
  center: Alignment(0, -.18),
  radius: 1.15,
  colors: [
    Color(0xFFD9414F),
    Color(0xFFB71F31),
    Color(0xFF781426),
    Color(0xFF430D1B),
  ],
  stops: [0.0, 0.36, 0.72, 1.0],
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
  const GameScreen({
    super.key,
    required this.roomId,
    this.animateInitialDeal = true,
  });
  final String roomId;
  final bool animateInitialDeal;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final PresenceService _presenceService = PresenceService();
  Stream<GameState>? _gameStream;
  bool _initialDistributionRequested = false;
  bool _dealAnimationFinished = false;
  bool _showDealAnimation = false;
  bool _hasShownWinner = false;
  bool _hasRequestedBidDialog = false;
  bool _hasShownRoundSummary = false;
  bool _isBidDialogShowing = false;
  bool _isProcessingBid = false;
  bool _isPlayingCard = false;
  bool _isReportingMissingHeart = false;
  bool _isReportingMissingSuit = false;
  bool _tableAnimationStateReady = false;
  bool _isCollectingTrick = false;
  final Set<String> _animatedTableCards = <String>{};
  final Set<String> _visibleTableCards = <String>{};
  String _animatedTrickKey = '';
  String _dealKey = '';
  String _lastRoomMessageId = '';
  BuildContext? _bidDialogContext;
  BuildContext? _summaryDialogContext;

  @override
  void initState() {
    super.initState();
    AppOrientation.setLandscape();
    _hasShownRoundSummary = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialDistributionRequested) return;
      _initialDistributionRequested = true;
      context.read<GameBloc>().add(
        InitialDistributionRequested(roomId: widget.roomId),
      );
    });
  }

  @override
  void dispose() {
    // ✅ Game Screen থেকে বের হলে Portrait Mode এ ফিরে যাবে
    _presenceService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final gameStream = _gameStream ??= context.read<GameBloc>().watchGame(
      widget.roomId,
    );

    return Scaffold(
      backgroundColor: _C.bgDeep,
      body: SafeArea(
        child: StreamBuilder<GameState>(
          stream: gameStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }
            if (!snapshot.hasData || snapshot.data is! GameLoaded) {
              return const _ErrorView('Room not found');
            }

            final data = (snapshot.data! as GameLoaded).data;
            final players = _normalizePlayers(data['players']);
            final presence = data['presence'] is Map
                ? Map<String, dynamic>.from(data['presence'] as Map)
                : <String, dynamic>{};
            _syncPresence(players, uid);
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
            final isMyBidTurnForState =
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
            bool? onlineAt(int rel) => playerOnline(presence[uidAt(rel)]);

            // Trick Winner Detect
            final trickWinner = data['trickWinner']?.toString() ?? '';

            final dealKey = '${data['round'] ?? data['roundNumber'] ?? ''}';
            final isDealPhase =
                hands.isNotEmpty &&
                (status == 'bidding' || status == 'suit_check');
            if (isDealPhase && dealKey != _dealKey) {
              _dealKey = dealKey;
              _tableAnimationStateReady = false;
              _isCollectingTrick = false;
              _animatedTableCards.clear();
              _visibleTableCards.clear();
              _animatedTrickKey = '';
              _dealAnimationFinished = !widget.animateInitialDeal;
              _hasRequestedBidDialog = false;
              _isProcessingBid = false;
              _isBidDialogShowing = false;
              _bidDialogContext = null;
              if (widget.animateInitialDeal) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _showDealAnimation = true);
                });
              }
            }
            final dealAnimationReady =
                !widget.animateInitialDeal || !_showDealAnimation;
            final isMyBidTurn = isMyBidTurnForState && dealAnimationReady;

            _syncTableAnimations(
              tableCards: tableCards,
              trickWinner: trickWinner,
              players: players,
              myUid: uid,
            );

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
                      visibleTableCardKeys: _isCollectingTrick
                          ? const <String>{}
                          : _visibleTableCards,
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
                  bottom: 0,
                  left: 0,
                  child: _PlayerCornerCard(
                    player: players.isNotEmpty ? players.first : null,
                    name: 'You',
                    isTurn: isMyTurn,
                    bid: _valueFor(bids, uid),
                    tricks: _valueFor(tricks, uid),
                    point: myPoint,
                    isMe: true,
                    isSmallScreen: isSmallScreen,
                    isOnline: playerOnline(presence[uid]),
                  ),
                ),

                // Right Player (Serial 1)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: isSmallScreen ? 8 : 20,
                  child: Center(
                    child: _PlayerCornerCard(
                      player: playerAt(1),
                      name: nameAt(1),
                      isTurn: currentTurn == uidAt(1),
                      bid: _valueFor(bids, uidAt(1)),
                      tricks: _valueFor(tricks, uidAt(1)),
                      point: _valueFor(playerScores, uidAt(1)),
                      isSmallScreen: isSmallScreen,
                      isOnline: onlineAt(1),
                    ),
                  ),
                ),

                // Top Player (Serial 2)
                Positioned(
                  top: isSmallScreen ? 8 : 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PlayerCornerCard(
                      player: playerAt(2),
                      name: nameAt(2),
                      isTurn: currentTurn == uidAt(2),
                      bid: _valueFor(bids, uidAt(2)),
                      tricks: _valueFor(tricks, uidAt(2)),
                      point: _valueFor(playerScores, uidAt(2)),
                      isSmallScreen: isSmallScreen,
                      isOnline: onlineAt(2),
                    ),
                  ),
                ),

                // Left Player (Serial 3)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isSmallScreen ? 8 : 20,
                  child: Center(
                    child: _PlayerCornerCard(
                      player: playerAt(3),
                      name: nameAt(3),
                      isTurn: currentTurn == uidAt(3),
                      bid: _valueFor(bids, uidAt(3)),
                      tricks: _valueFor(tricks, uidAt(3)),
                      point: _valueFor(playerScores, uidAt(3)),
                      isSmallScreen: isSmallScreen,
                      isOnline: onlineAt(3),
                    ),
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
                  bottom: -15,
                  left: 0,
                  right: 0,
                  child: _MyHand(
                    cards: dealAnimationReady ? sortedCards : const [],
                    isMyTurn: isMyTurn,
                    isSmallScreen: isSmallScreen,
                    onCardTap: (card) {
                      _playCard(card);
                    },
                  ),
                ),
                if (_showDealAnimation)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _DealAnimation(
                        isSmallScreen: isSmallScreen,
                        onComplete: () {
                          if (mounted) {
                            setState(() {
                              _showDealAnimation = false;
                              _dealAnimationFinished = true;
                            });
                          }
                        },
                      ),
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
                        AppOrientation.setPortrait();
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
                        context.read<GameBloc>().add(
                          ReplayRequested(roomId: widget.roomId),
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
    context.read<GameBloc>().add(
      BidSubmitted(roomId: widget.roomId, uid: uid, bid: bid),
    );
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _isProcessingBid = false);
  }

  Future<void> _startNextRoundAfterSuitCheck(
    List<Map<String, dynamic>> players,
  ) async {
    if (_isReportingMissingHeart) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() => _isReportingMissingHeart = true);
    context.read<GameBloc>().add(
      SuitCheckNextRoundRequested(
        roomId: widget.roomId,
        uid: uid,
        players: players,
      ),
    );
    if (mounted) setState(() => _isReportingMissingHeart = false);
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
    context.read<GameBloc>().add(
      MissingSuitReported(
        roomId: widget.roomId,
        uid: uid,
        playerName: playerName,
      ),
    );
    if (mounted) setState(() => _isReportingMissingSuit = false);
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

    context.read<GameBloc>().add(
      CardPlayed(roomId: widget.roomId, uid: uid, card: card),
    );
    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _isPlayingCard = false);
  }

  // ✅ Card Fly Animation (নিচ থেকে শুরু → টেবিলে)
  void _syncTableAnimations({
    required List<Map<String, dynamic>> tableCards,
    required String trickWinner,
    required List<Map<String, dynamic>> players,
    required String myUid,
  }) {
    final currentKeys = tableCards.map(_tableCardKey).toSet();
    if (!_tableAnimationStateReady) {
      _animatedTableCards.addAll(currentKeys);
      _visibleTableCards.addAll(currentKeys);
      _animatedTrickKey = _trickKey(tableCards, trickWinner);
      _tableAnimationStateReady = true;
      return;
    }

    for (final entry in tableCards) {
      final key = _tableCardKey(entry);
      if (_animatedTableCards.add(key)) {
        final card = Map<String, dynamic>.from(entry['card'] ?? {});
        final uid = entry['uid']?.toString() ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showCardFlyAnimation(
            card,
            start: _seatOffset(uid, players, myUid),
            end: _boardCardOffset(uid, players, myUid),
            onComplete: () {
              if (!mounted) return;
              setState(() => _visibleTableCards.add(key));
            },
          );
        });
      }
    }

    final trickKey = _trickKey(tableCards, trickWinner);
    if (trickWinner.isNotEmpty &&
        tableCards.length == players.length &&
        trickKey != _animatedTrickKey) {
      _animatedTrickKey = trickKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future<void>.delayed(const Duration(milliseconds: 720), () {
          if (!mounted) return;
          setState(() => _isCollectingTrick = true);
          for (var index = 0; index < tableCards.length; index++) {
            final card = Map<String, dynamic>.from(
              tableCards[index]['card'] ?? {},
            );
            _showCardFlyAnimation(
              card,
              start: _tableCenterOffset(index: index),
              end: _seatOffset(trickWinner, players, myUid),
              duration: const Duration(milliseconds: 450),
            );
          }
        });
      });
    }

    _animatedTableCards.removeWhere((key) => !currentKeys.contains(key));
    _visibleTableCards.removeWhere((key) => !currentKeys.contains(key));
    if (currentKeys.isEmpty && trickWinner.isEmpty && _isCollectingTrick) {
      _isCollectingTrick = false;
    }
  }

  String _tableCardKey(Map<String, dynamic> entry) {
    final card = entry['card'] is Map
        ? Map<String, dynamic>.from(entry['card'] as Map)
        : <String, dynamic>{};
    return '${entry['uid']}:${card['rank']}:${card['suit']}';
  }

  String _trickKey(List<Map<String, dynamic>> cards, String winner) {
    return '$winner|${cards.map(_tableCardKey).join('|')}';
  }

  Offset _tableCenterOffset({int index = 0}) {
    final size = MediaQuery.of(context).size;
    final spread = (index - 1.5) * 12;
    return Offset(size.width / 2 + spread, size.height / 2);
  }

  Offset _boardCardOffset(
    String targetUid,
    List<Map<String, dynamic>> players,
    String myUid,
  ) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final padding = isSmallScreen ? 8.0 : 16.0;
    final cardWidth = isSmallScreen ? 50.0 : 66.0;
    final cardHeight = isSmallScreen ? 70.0 : 92.0;
    final sideInset = isSmallScreen ? 48.0 : 150.0;
    final verticalInset = isSmallScreen ? 8.0 : 45.0;
    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    final targetIndex = players.indexWhere(
      (p) => p['uid']?.toString() == targetUid,
    );
    final relative = myIndex < 0 || targetIndex < 0
        ? 0
        : (targetIndex - myIndex + players.length) % players.length;

    switch (relative) {
      case 1:
        return Offset(
          size.width - padding - sideInset - cardWidth / 2,
          size.height / 2,
        );
      case 2:
        return Offset(size.width / 2, padding + verticalInset + cardHeight / 2);
      case 3:
        return Offset(padding + sideInset + cardWidth / 2, size.height / 2);
      default:
        return Offset(
          size.width / 2,
          size.height - padding - verticalInset - cardHeight / 2,
        );
    }
  }

  Offset _seatOffset(
    String targetUid,
    List<Map<String, dynamic>> players,
    String myUid,
  ) {
    final size = MediaQuery.of(context).size;
    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    final targetIndex = players.indexWhere(
      (p) => p['uid']?.toString() == targetUid,
    );
    final relative = myIndex < 0 || targetIndex < 0
        ? 0
        : (targetIndex - myIndex + players.length) % players.length;
    switch (relative) {
      case 1:
        return Offset(size.width - 78, size.height / 2);
      case 2:
        return Offset(size.width / 2, 78);
      case 3:
        return Offset(78, size.height / 2);
      default:
        return Offset(size.width / 2, size.height - 92);
    }
  }

  void _showCardFlyAnimation(
    Map<String, dynamic> card, {
    required Offset start,
    required Offset end,
    Duration duration = const Duration(milliseconds: 360),
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FlyingCardOverlay(
        card: card,
        start: start,
        end: end,
        duration: duration,
        onComplete: () {
          overlayEntry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _syncPresence(List<Map<String, dynamic>> players, String uid) {
    if (uid.isEmpty) return;

    final player = players.firstWhere(
      (entry) => entry['uid']?.toString() == uid,
      orElse: () => <String, dynamic>{},
    );
    final name = player['name']?.toString() ?? '';
    if (name.isEmpty) return;

    _presenceService.start(roomId: widget.roomId, uid: uid, name: name);
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
    this.isOnline,
  });

  final Map<String, dynamic>? player;
  final String name;
  final bool isTurn;
  final int bid, tricks, point;
  final bool isMe;
  final bool isSmallScreen;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    final avatar = player?['avatar']?.toString();
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();

    final avatarSize = isSmallScreen ? 32.0 : 48.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: isSmallScreen ? 116 : 148,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 5 : 7,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTurn
              ? const [Color(0xFFFFECA6), Color(0xFFE0A32D), Color(0xFF8D4E13)]
              : const [Color(0xFF123E70), Color(0xFF071D3A), Color(0xFF031326)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isTurn ? _C.goldLight : const Color(0xFFD49A32),
          width: isTurn ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.65),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
          if (isTurn)
            BoxShadow(
              color: _C.goldLight.withOpacity(.42),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Realistic-looking avatar frame.
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF6B8EAA),
                  Color(0xFF152A42),
                  Color(0xFF050B13),
                ],
              ),
              border: Border.all(
                color: isTurn ? _C.goldLight : const Color(0xFFD5A83C),
                width: isTurn ? 2 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: isOnline == false
                ? const Center(
                    child: PlayerPresenceIndicator(isOnline: false),
                  )
                : ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.asset(
                            avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _AvatarPlaceholder(initials: initials),
                          )
                        : _AvatarPlaceholder(initials: initials),
                  ),
          ),


          SizedBox(width: isSmallScreen ? 5 : 8),

          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? 58 : 76,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: isTurn ? _goldGrad : _panelGrad,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isTurn ? _C.goldLight : _C.goldDark,
                    ),
                  ),
                  child: Text(
                    isMe ? 'YOU' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isTurn ? Colors.black : Colors.white,
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BidTricksBar(
                      tricks: tricks,
                      bid: bid,
                      isSmallScreen: isSmallScreen,
                    ),
                    const SizedBox(width: 3),
                    _PointDisplay(point: point, isSmallScreen: isSmallScreen),
                  ],
                ),
                if (isTurn)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'YOUR TURN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isSmallScreen ? 5 : 6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF526D86), Color(0xFF172B42)],
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 40,
            color: Colors.white.withOpacity(.72),
          ),
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
    required this.visibleTableCardKeys,
    required this.currentTurn,
    required this.myUid,
    required this.trickWinner,
    this.isSmallScreen = false,
  });

  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> tableCards;
  final Set<String> visibleTableCardKeys;
  final String currentTurn, myUid;
  final String trickWinner;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final seatCards = <String, Map<String, dynamic>>{};
    for (final e in tableCards) {
      final u = e['uid']?.toString() ?? '';
      final card = e['card'] is Map
          ? Map<String, dynamic>.from(e['card'] as Map)
          : <String, dynamic>{};
      final cardKey = '${e['uid']}:${card['rank']}:${card['suit']}';
      if (u.isNotEmpty && visibleTableCardKeys.contains(cardKey)) {
        seatCards[u] = card;
      }
    }

    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    final total = players.length;

    String uidAt(int rel) {
      if (total == 0 || myIndex < 0) return '';
      return players[(myIndex + rel) % total]['uid']?.toString() ?? '';
    }

    final topUid = uidAt(2);
    final leftUid = uidAt(3);
    final rightUid = uidAt(1);

    final sideInset = isSmallScreen ? 48.0 : 250.0;
    final verticalInset = isSmallScreen ? 8.0 : 45.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD778),
            Color(0xFFC47A25),
            Color(0xFF6D3212),
            Color(0xFFB96A1D),
            Color(0xFFFFD978),
          ],
          stops: [0, .20, .50, .78, 1],
        ),
        border: Border.all(
          color: const Color(0xFFFFE8A4),
          width: isSmallScreen ? 2 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.72),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFFD66B).withOpacity(.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _WoodGrainPainter(),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 5 : 9),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const RadialGradient(
                center: Alignment(0, -.18),
                radius: 1.15,
                colors: [
                  Color(0xFFD9414F),
                  Color(0xFFB71F31),
                  Color(0xFF781426),
                  Color(0xFF430D1B),
                ],
                stops: [0, .36, .72, 1],
              ),
              border: Border.all(
                color: const Color(0xFFFFA0A5).withOpacity(.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.65),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.redAccent.withOpacity(.10),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FeltMarkingsPainter()),
                ),

                // Soft table reflection.
                Align(
                  alignment: const Alignment(0, -.55),
                  child: IgnorePointer(
                    child: Container(
                      width: double.infinity,
                      height: isSmallScreen ? 32 : 70,
                      margin: const EdgeInsets.symmetric(horizontal: 80),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(.09),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Opacity(
                    opacity: .045,
                    child: Text(
                      '♠',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 80 : 150,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Top played card.
                Positioned(
                  top: verticalInset,
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

                // Left played card.
                Positioned(
                  left: sideInset,
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

                // Right played card.
                Positioned(
                  right: sideInset,
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

                // My played card.
                Positioned(
                  bottom: verticalInset,
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
          ),
        ),
      ),
    );
  }

  String nameAt(int rel) {
    if (players.isEmpty) return 'Player';
    final myIndex = players.indexWhere((p) => p['uid']?.toString() == myUid);
    if (myIndex < 0) return 'Player';
    final abs = (myIndex + rel) % players.length;
    return players[abs]['name']?.toString() ?? 'Player';
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grain = Paint()
      ..color = const Color(0x66FFE39A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final shadowGrain = Paint()
      ..color = const Color(0x331E0903)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (var index = 0; index < 5; index++) {
      final inset = 16.0 + (index * 7.0);
      final rect = Rect.fromLTWH(
        inset,
        inset * .45,
        size.width - inset * 2,
        size.height - inset * .9,
      );
      canvas.drawOval(rect, shadowGrain);
      canvas.drawOval(rect.deflate(2), grain);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeltMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = const Color(0x55FFD98A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final shade = Paint()
      ..color = const Color(0x331B0610)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final inset = size.width * .08;
    canvas.drawOval(
      Rect.fromLTWH(
        inset,
        size.height * .1,
        size.width - inset * 2,
        size.height * .8,
      ),
      shade,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        inset + 3,
        size.height * .1 + 3,
        size.width - inset * 2 - 6,
        size.height * .8 - 6,
      ),
      rail,
    );
    canvas.drawLine(
      Offset(size.width * .25, size.height * .5),
      Offset(size.width * .75, size.height * .5),
      rail,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final cardW = isSmallScreen ? 50.0 : 66.0;
    final cardH = isSmallScreen ? 70.0 : 92.0;

    if (card == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: cardW,
        height: cardH,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTurn ? _C.goldLight : Colors.white.withOpacity(.10),
            width: isTurn ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isTurn ? 'YOUR TURN' : '',
          style: TextStyle(
            color: _C.goldLight,
            fontSize: isSmallScreen ? 6 : 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final suit = card!['suit']?.toString() ?? '';
    final rank = card!['rank']?.toString() ?? '';
    final isRed = suit == '♥' || suit == '♦';
    final suitColor = isRed ? const Color(0xFFD7192E) : Colors.black87;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF2F2F2), Color(0xFFD9D9D9)],
        ),
        border: Border.all(
          color: isWinner
              ? Colors.greenAccent
              : isTurn
              ? _C.goldLight
              : const Color(0xFFB98B37),
          width: isWinner || isTurn ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.70),
            blurRadius: 8,
            offset: const Offset(2, 5),
          ),
          if (isWinner)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(.45),
              blurRadius: 15,
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black.withOpacity(.08)),
                ),
              ),
            ),
          ),

          Positioned(
            top: 4,
            left: 5,
            child: _CardCorner(
              rank: rank,
              suit: suit,
              color: suitColor,
              small: isSmallScreen,
            ),
          ),

          Center(
            child: rank == 'K'
                ? Text(
                    'K',
                    style: TextStyle(
                      color: suitColor,
                      fontSize: isSmallScreen ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                  )
                : Text(
                    suit,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: isSmallScreen ? 30 : 43,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),

          Positioned(
            bottom: 4,
            right: 5,
            child: RotatedBox(
              quarterTurns: 2,
              child: _CardCorner(
                rank: rank,
                suit: suit,
                color: suitColor,
                small: isSmallScreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardCorner extends StatelessWidget {
  const _CardCorner({
    required this.rank,
    required this.suit,
    required this.color,
    required this.small,
  });

  final String rank;
  final String suit;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rank,
          style: TextStyle(
            color: color,
            fontSize: small ? 11 : 15,
            height: .9,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          suit,
          style: TextStyle(color: color, fontSize: small ? 12 : 16, height: .9),
        ),
      ],
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

    final cardW = isSmallScreen ? 58.0 : 82.0;
    final cardH = isSmallScreen ? 76.0 : 112.0;

    return SizedBox(
      height: isSmallScreen ? 58 : 82,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final maxSpread = constraints.maxWidth * .56;
          final spacing = cards.length > 1
              ? (maxSpread / (cards.length - 1)).clamp(
                  isSmallScreen ? 18.0 : 22.0,
                  isSmallScreen ? 32.0 : 48.0,
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
              final suitColor = isRed
                  ? const Color(0xFFD7192E)
                  : Colors.black87;

              final center = (cards.length - 1) / 2;
              final curve = i - center;
              final angle = curve * .018;

              return Positioned(
                left: startLeft + i * spacing,
                bottom: isSmallScreen ? -3 : -23,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isMyTurn ? () => onCardTap(card) : null,
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: cardW,
                      height: cardH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF7F7F7),
                            Color(0xFFD7D7D7),
                          ],
                        ),
                        border: Border.all(
                          color: isMyTurn
                              ? _C.goldLight
                              : const Color(0xFF9B9B9B),
                          width: isMyTurn ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.68),
                            blurRadius: 8,
                            offset: const Offset(1, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(.07),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 4,
                            left: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rank,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 17,
                                    height: .9,
                                    fontWeight: FontWeight.w900,
                                    color: suitColor,
                                  ),
                                ),
                                Text(
                                  suit,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 20,
                                    height: .9,
                                    color: suitColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Center(
                            child: Text(
                              suit,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 36 : 51,
                                color: suitColor,
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 4,
                            right: 5,
                            child: RotatedBox(
                              quarterTurns: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rank,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 17,
                                      height: .9,
                                      fontWeight: FontWeight.w900,
                                      color: suitColor,
                                    ),
                                  ),
                                  Text(
                                    suit,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 20,
                                      height: .9,
                                      color: suitColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
  final Offset start;
  final Offset end;
  final Duration duration;
  final VoidCallback onComplete;

  const _FlyingCardOverlay({
    required this.card,
    required this.start,
    required this.end,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 360),
  });

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

    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ MediaQuery এখন নিরাপদে ব্যবহার করা যাবে
    final size = MediaQuery.of(context).size;
    if (_screenSize != size) {
      _screenSize = size;

      _positionAnimation = Tween<Offset>(
        begin: widget.start,
        end: widget.end,
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

class _DealAnimation extends StatefulWidget {
  const _DealAnimation({required this.isSmallScreen, required this.onComplete});

  final bool isSmallScreen;
  final VoidCallback onComplete;

  @override
  State<_DealAnimation> createState() => _DealAnimationState();
}

class _DealAnimationState extends State<_DealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = widget.isSmallScreen ? 34.0 : 44.0;
    final cardHeight = widget.isSmallScreen ? 50.0 : 66.0;
    final center = Offset(size.width / 2, size.height * .48);
    final destinations = [
      Offset(size.width / 2, size.height * .16),
      Offset(size.width * .84, size.height * .46),
      Offset(size.width / 2, size.height * .78),
      Offset(size.width * .16, size.height * .46),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final cards = <Widget>[];
        for (var index = 0; index < 52; index++) {
          final start = index * .012;
          final end = start + .13;
          final progress = ((_controller.value - start) / (end - start)).clamp(
            0.0,
            1.0,
          );
          if (progress <= 0 || progress >= 1) continue;

          final destination = destinations[index % 4];
          final position = Offset.lerp(
            center,
            destination,
            Curves.easeOut.transform(progress),
          )!;
          final rotation = (index.isEven ? -1 : 1) * .12 * progress;

          cards.add(
            Positioned(
              left: position.dx - cardWidth / 2,
              top: position.dy - cardHeight / 2,
              child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB83C4A), Color(0xFF671B2B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFD66B)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '♠',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.72),
                      fontSize: widget.isSmallScreen ? 16 : 22,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: cards);
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
