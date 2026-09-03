class WinnerService {
  String? determineWinner({
    required int teamAScore,
    required int teamBScore,
    required int targetScore,
  }) {
    if (teamAScore >= targetScore) {
      return 'Team A';
    }

    if (teamBScore >= targetScore) {
      return 'Team B';
    }

    return null;
  }
}
