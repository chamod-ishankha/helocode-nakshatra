import 'dart:math' as math;

/// How many rows of a locked list are shown before the lock (KAN-70).
///
/// A lock that hides everything asks the reader to pay for something they
/// cannot picture. The first two rows — two sub-periods, two porondam — show
/// the shape of what is behind it, and nothing is pretended unavailable.
///
/// Never the whole list: at least one row always stays behind the lock, or a
/// short list would be given away entire and the lock would guard nothing.
int previewCount(int total) => total <= 1 ? 0 : math.min(2, total - 1);
