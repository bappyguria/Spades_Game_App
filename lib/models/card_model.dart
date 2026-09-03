class PlayingCard {
  final String suit;
  final String rank;

  PlayingCard({
    required this.suit,
    required this.rank,
  });

  Map<String, dynamic> toJson() {
    return {
      "suit": suit,
      "rank": rank,
    };
  }

  factory PlayingCard.fromJson(
      Map<String, dynamic> json) {
    return PlayingCard(
      suit: json["suit"],
      rank: json["rank"],
    );
  }
}