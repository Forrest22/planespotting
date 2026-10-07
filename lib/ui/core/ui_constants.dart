/// Widest a column of text or tiles gets in a big window.
const double contentMaxWidth = 600;

/// A card's corner radius as a share of its short side (a real card's is about 4.8%). Slightly
/// over rather than under, because the card's border is black and a wedge of the filled-in
/// corner would show otherwise.
const double cardCornerRatio = 0.055;

/// How far in from the image's edge a card is cut, as a share of its short side. The files have a
/// faint light fringe on the outermost pixels, which would show as a line against a dark background.
const double cardEdgeTrim = 0.004;

/// Corner radius of panels, sheets and banners.
const double panelRadius = 20;

/// "1 card" or "3 cards".
String cardCount(int count) => '$count ${count == 1 ? 'card' : 'cards'}';
