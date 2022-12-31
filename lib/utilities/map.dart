double map(int value, int low1, int high1, int low2, int high2) {
  return low2 + ((high2 - low2) * (value - low1) / (high1 - low1));
}
