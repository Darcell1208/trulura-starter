// src/theme/gradientUtils.js
// Safe gradient parser used across the app to ensure Expo <LinearGradient>
// always receives a valid array of color strings.
//
// Accepts:
//  - ["#fff", "#000"]
//  - "#fff, #000"
//  - "#fff"
//  - null / undefined (returns fallback)
//  - objects like { start: "#fff", end: "#000" } (future-proofed)
//
// Always returns: ["#xxxxxx", "#yyyyyy"]

export function ensureGradientArray(input, fallback = ['#6B73FF', '#000DFF']) {
  if (!input) return fallback;

  // Case 1: Already a valid array
  if (Array.isArray(input)) {
    const cleaned = input.filter(Boolean);
    if (cleaned.length >= 2) return cleaned;
    if (cleaned.length === 1) return [cleaned[0], cleaned[0]];
    return fallback;
  }

  // Case 2: Gradient object { start, end }
  if (typeof input === 'object') {
    const start = input.start || input.from || input.color1;
    const end = input.end || input.to || input.color2;
    if (start && end) return [start, end];
    if (start) return [start, start];
    return fallback;
  }

  // Case 3: Comma-separated string "#fff,#000"
  if (typeof input === 'string') {
    const parts = input
      .split(',')
      .map(c => c.trim())
      .filter(Boolean);

    if (parts.length >= 2) return [parts[0], parts[1]];
    if (parts.length === 1) return [parts[0], parts[0]];
    return fallback;
  }

  // Fallback if input is something unexpected
  return fallback;
}
