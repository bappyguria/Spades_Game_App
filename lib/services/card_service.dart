import '../models/card_model.dart';

class CardService {
  static List<PlayingCard> createDeck() {
    List<String> suits = [
      "♠",
      "♥",
      "♦",
      "♣",
    ];

    List<String> ranks = [
      "A",
      "K",
      "Q",
      "J",
      "10",
      "9",
      "8",
      "7",
      "6",
      "5",
      "4",
      "3",
      "2",
    ];

    List<PlayingCard> deck = [];

    for (var suit in suits) {
      for (var rank in ranks) {
        deck.add(
          PlayingCard(
            suit: suit,
            rank: rank,
          ),
        );
      }
    }

    return deck;
  }

  static List<PlayingCard> shuffleDeck() {
    final deck = createDeck();
    deck.shuffle();
    return deck;
  }
}