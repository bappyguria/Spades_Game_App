import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/bloc/room_bloc.dart';
import '../core/bloc/room_event.dart';
import '../core/bloc/room_state.dart';
import '../services/presence_service.dart';
import '../utils/app_orientation.dart';
import '../utils/player_presence.dart';
import '../widgets/player_presence_indicator.dart';
import 'game_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;

  static const Color bgBase = Color(0xFF0B1220);
  static const Color bgElevated = Color(0xFF141D2E);
  static const Color accent = Color(0xFFE8A93B);
  static const Color danger = Color(0xFFEF5350);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA9B4C6);
  static const Color textMuted = Color(0xFF6B7690);
  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const double _radiusLg = 22.0;
  static const double _radiusMd = 14.0;

  static final Set<String> _navigationLocks = <String>{};

  const WaitingRoomScreen({super.key, required this.roomId});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final PresenceService _presenceService = PresenceService();
  String _presenceKey = '';

  static final Set<String> _navigationLocks =
      WaitingRoomScreen._navigationLocks;
  static const Color bgBase = WaitingRoomScreen.bgBase;
  static const Color bgElevated = WaitingRoomScreen.bgElevated;
  static const Color accent = WaitingRoomScreen.accent;
  static const Color danger = WaitingRoomScreen.danger;
  static const Color textPrimary = WaitingRoomScreen.textPrimary;
  static const Color textSecondary = WaitingRoomScreen.textSecondary;
  static const Color textMuted = WaitingRoomScreen.textMuted;
  static const Color borderSubtle = WaitingRoomScreen.borderSubtle;
  static const double _radiusLg = WaitingRoomScreen._radiusLg;
  static const double _radiusMd = WaitingRoomScreen._radiusMd;

  String get roomId => widget.roomId;

  // ---------------------------------------------------------------------
  // DESIGN SYSTEM — kept identical to JoinRoomScreen so the two screens
  // feel like the same product.
  // ---------------------------------------------------------------------
  static const Color bgSurface = Color(0xFF1B2740);
  static const Color accentSoft = Color(0xFFF3C877);

  static const int maxPlayers = 4;

  void _syncPresence(List players) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Map<String, dynamic>? currentPlayer;
    for (final entry in players) {
      if (entry is Map && entry['uid']?.toString() == uid) {
        currentPlayer = Map<String, dynamic>.from(entry);
        break;
      }
    }

    final name = currentPlayer?['name']?.toString() ?? '';
    final key = '${widget.roomId}|$uid|$name';
    if (uid.isEmpty || name.isEmpty || key == _presenceKey) return;

    _presenceKey = key;
    _presenceService.start(roomId: widget.roomId, uid: uid, name: name);
  }

  @override
  void dispose() {
    _presenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
        title: Text(
          'Waiting Room',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: StreamBuilder<RoomState>(
        stream: context.read<RoomBloc>().watchRoom(roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data is RoomIdle) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }

          final roomState = snapshot.data!;
          if (roomState is RoomError) {
            return _buildRoomGoneState(context);
          }

          if (roomState is! RoomLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }

          final data = roomState.data;

          final List players = data['players'] ?? [];
          final presence = data['presence'] is Map
              ? Map<String, dynamic>.from(data['presence'] as Map)
              : <String, dynamic>{};
          _syncPresence(players);
          final String hostId = data['hostId'] ?? '';
          final String status = data['status'] ?? 'waiting';
          final String currentUid =
              FirebaseAuth.instance.currentUser?.uid ?? '';
          final bool isHost = currentUid == hostId;
          final bool isFull = players.length == maxPlayers;

          if (status == 'dealing') {
            if (_navigationLocks.add(roomId)) {
              AppOrientation.setLandscape();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (_, animation, __) =>
                          GameScreen(roomId: roomId),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                } finally {
                  _navigationLocks.remove(roomId);
                }
              });
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  _buildRoomIdCard(context),
                  const SizedBox(height: 20),
                  _buildPlayerCountRow(players.length),
                  const SizedBox(height: 16),
                  if (players.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final player = players[index];
                        final bool host = player['uid'] == hostId;
                        return _PlayerTile(
                          index: index,
                          name: player['name']?.toString() ?? 'Player',
                          isHost: host,
                          isOnline: playerOnline(
                            presence[player['uid']?.toString()],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  if (isHost)
                    _buildHostButton(context, isFull, players.length)
                  else
                    _buildWaitingBanner(players.length),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -- Room ID card ---------------------------------------------------

  Widget _buildRoomIdCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgElevated,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ROOM ID',
            style: TextStyle(
              color: textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roomId,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 10),
              _CopyButton(roomId: roomId),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Share this code with your friends',
            style: TextStyle(color: textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // -- Player count row --------------------------------------------------

  Widget _buildPlayerCountRow(int count) {
    return Row(
      children: [
        Icon(Icons.groups_rounded, color: accent, size: 20),
        const SizedBox(width: 8),
        Text(
          '$count/$maxPlayers Players Joined',
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Row(
          children: List.generate(maxPlayers, (i) {
            final filled = i < count;
            return Container(
              margin: const EdgeInsets.only(left: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? accent : borderSubtle,
              ),
            );
          }),
        ),
      ],
    );
  }

  // -- Empty state ------------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: textMuted, size: 32),
            const SizedBox(height: 10),
            Text(
              'Waiting for players to join…',
              style: TextStyle(color: textMuted, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomGoneState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off_rounded, color: danger, size: 34),
            const SizedBox(height: 14),
            Text(
              'This room no longer exists',
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The host may have closed it. Head back and try another code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: bgBase,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radiusMd),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Host / waiting controls --------------------------------------------

  Widget _buildHostButton(BuildContext context, bool isFull, int count) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: bgSurface,
          disabledForegroundColor: textMuted,
          foregroundColor: bgBase,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
            side: isFull ? BorderSide.none : BorderSide(color: borderSubtle),
          ),
        ),
        onPressed: isFull
            ? () {
                HapticFeedback.mediumImpact();
                context.read<RoomBloc>().add(
                  StartGameRequested(
                    roomId: roomId,
                    dealerIndex: 0,
                    roundNumber: 1,
                  ),
                );
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFull ? Icons.play_arrow_rounded : Icons.schedule_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isFull ? 'START GAME' : 'WAITING · $count/$maxPlayers',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingBanner(int count) {
    return Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgElevated,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          const SizedBox(width: 10),
          Text(
            'Waiting for host to start the game',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Player tile
// ---------------------------------------------------------------------
class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.index,
    required this.name,
    required this.isHost,
    required this.isOnline,
  });

  final int index;
  final String name;
  final bool isHost;
  final bool? isOnline;

  static const List<Color> _avatarColors = [
    Color(0xFFE8A93B),
    Color(0xFF5FA8D3),
    Color(0xFF7DBE83),
    Color(0xFFC97BD1),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[index % _avatarColors.length];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WaitingRoomScreen.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaitingRoomScreen.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withOpacity(0.18),
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WaitingRoomScreen.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PlayerPresenceIndicator(isOnline: isOnline),
          const SizedBox(width: 8),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WaitingRoomScreen.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: WaitingRoomScreen.accent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Host',
                    style: TextStyle(
                      color: WaitingRoomScreen.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Player',
              style: TextStyle(
                color: WaitingRoomScreen.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Copy-to-clipboard button for the room code
// ---------------------------------------------------------------------
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.roomId});

  final String roomId;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.roomId));
    HapticFeedback.selectionClick();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _copy,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            color: _copied ? const Color(0xFF3DBE7E) : WaitingRoomScreen.accent,
            size: 20,
          ),
        ),
      ),
    );
  }
}
