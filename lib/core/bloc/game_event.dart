abstract class GameEvent {
  const GameEvent();
}

class GameStarted extends GameEvent {
  final String roomId;
  const GameStarted({required this.roomId});
}

class GameUpdated extends GameEvent {
  final Map<String, dynamic> data;
  const GameUpdated({required this.data});
}

class BidSubmitted extends GameEvent {
  final String roomId;
  final String uid;
  final int bid;
  const BidSubmitted({
    required this.roomId,
    required this.uid,
    required this.bid,
  });
}

class CardPlayed extends GameEvent {
  final String roomId;
  final String uid;
  final Map<String, dynamic> card;
  const CardPlayed({
    required this.roomId,
    required this.uid,
    required this.card,
  });
}

class BidDialogDismissed extends GameEvent {}

class RoundSummaryShown extends GameEvent {}

class NextRoundRequested extends GameEvent {
  final String roomId;
  final List<Map<String, dynamic>> players;
  final Map<String, int> playerScores;
  final int round;
  final int dealerIndex;
  final List<String> bidOrder;
  const NextRoundRequested({
    required this.roomId,
    required this.players,
    required this.playerScores,
    required this.round,
    required this.dealerIndex,
    required this.bidOrder,
  });
}

class InitialDistributionRequested extends GameEvent {
  final String roomId;
  const InitialDistributionRequested({required this.roomId});
}

class SuitCheckNextRoundRequested extends GameEvent {
  final String roomId;
  final String uid;
  final List<Map<String, dynamic>> players;
  const SuitCheckNextRoundRequested({
    required this.roomId,
    required this.uid,
    required this.players,
  });
}

class MissingSuitReported extends GameEvent {
  final String roomId;
  final String uid;
  final String playerName;
  const MissingSuitReported({
    required this.roomId,
    required this.uid,
    required this.playerName,
  });
}

class ReplayRequested extends GameEvent {
  final String roomId;
  const ReplayRequested({required this.roomId});
}

class GameReset extends GameEvent {}
