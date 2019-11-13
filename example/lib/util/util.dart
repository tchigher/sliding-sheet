// Shrink animation values inside a specified range. E.g. from .2 - .4 => .3 = 50%.
double fInRange(double lower, double upper, double progress) {
  assert(lower < upper);

  if (progress > upper) return 1.0;
  if (progress < lower) return 0.0;

  return ((progress - lower) / (upper - lower)).clamp(0.0, 1.0);
}