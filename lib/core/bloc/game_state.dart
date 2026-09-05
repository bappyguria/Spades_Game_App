abstract class GameState {
  const GameState();
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final String roomId;
  final Map<String, dynamic> data;
  final bool isBidDialogShowing;
  final bool hasShownRoundSummary;
  final bool isProcessingBid;
  final bool isPlayingCard;
  final bool hasShownWinner;

  const GameLoaded({
    required this.roomId,
    required this.data,
    this.isBidDialogShowing = false,
    this.hasShownRoundSummary = false,
    this.isProcessingBid = false,
    this.isPlayingCard = false,
    this.hasShownWinner = false,
  });

  GameLoaded copyWith({
    Map<String, dynamic>? data,
    bool? isBidDialogShowing,
    bool? hasShownRoundSummary,
    bool? isProcessingBid,
    bool? isPlayingCard,
    bool? hasShownWinner,
  }) {
    return GameLoaded(
      roomId: roomId,
      data: data ?? this.data,
      isBidDialogShowing: isBidDialogShowing ?? this.isBidDialogShowing,
      hasShownRoundSummary: hasShownRoundSummary ?? this.hasShownRoundSummary,
      isProcessingBid: isProcessingBid ?? this.isProcessingBid,
      isPlayingCard: isPlayingCard ?? this.isPlayingCard,
      hasShownWinner: hasShownWinner ?? this.hasShownWinner,
    );
  }
}

class BidSubmittedSuccess extends GameState {}

class CardPlayedSuccess extends GameState {}

class NextRoundStarted extends GameState {}

class InitialDistributionCompleted extends GameState {}

class GameActionCompleted extends GameState {}

class GameError extends GameState {
  final String message;
  const GameError({required this.message});
}
