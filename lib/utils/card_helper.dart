class CardHelper {
  static const suitOrder = {
    "♣": 0,
    "♦": 1,
    "♥": 2,
    "♠": 3,
  };

  static const rankOrder = {
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9,
    "10": 10,
    "J": 11,
    "Q": 12,
    "K": 13,
    "A": 14,
  };

  static List sortCards(List cards) {
    cards.sort((a, b) {
      int suitCompare =
          suitOrder[a["suit"]]!
              .compareTo(
        suitOrder[b["suit"]]!,
      );

      if (suitCompare != 0) {
        return suitCompare;
      }

      return rankOrder[a["rank"]]!
          .compareTo(
        rankOrder[b["rank"]]!,
      );
    });

    return cards;
  }
}