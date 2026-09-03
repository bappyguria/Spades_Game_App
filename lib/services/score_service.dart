class ScoreService {
  int calculateRoundDelta({required int bid, required int tricksTaken}) {
    if (tricksTaken >= bid) {
      return bid * 10;
    }
    return -(bid * 10);
  }

  int applyScore({
    required int currentScore,
    required int bid,
    required int tricksTaken,
  }) {
    return currentScore +
        calculateRoundDelta(bid: bid, tricksTaken: tricksTaken);
  }
}
