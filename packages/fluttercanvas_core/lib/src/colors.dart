/// Parses `#RGB`, `#RRGGBB` or `#AARRGGBB` into an ARGB integer.
///
/// Returns null for null, empty or invalid input, which FlutterCanvas treats
/// as "no color".
int? parseHexColor(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.isEmpty) return null;
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  return int.tryParse(hex, radix: 16);
}

/// Formats an ARGB integer as `#AARRGGBB`.
String formatHexColor(int argb) =>
    '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
