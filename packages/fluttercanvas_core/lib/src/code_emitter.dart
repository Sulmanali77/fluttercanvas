/// A tiny code model the generator uses to print readable, indented Dart.
///
/// Expressions know whether they can be `const`, so the printer adds `const`
/// once at the outermost possible place, the way a person would write it.
sealed class CodeExpr {
  const CodeExpr();

  /// Whether this expression can appear in a const context.
  bool get isConst;

  /// Renders this expression. [indent] is the nesting level (2 spaces each)
  /// of the line the expression starts on. [inConst] is true when an
  /// enclosing expression is already `const`.
  String render(int indent, {bool inConst = false});
}

/// Code printed as-is.
class RawCode extends CodeExpr {
  const RawCode(this.code, {this.isConst = true});

  final String code;

  @override
  final bool isConst;

  @override
  String render(int indent, {bool inConst = false}) => code;
}

/// A closure with a block body, such as `() { ... }`.
class BlockCode extends CodeExpr {
  const BlockCode(this.lines);

  final List<String> lines;

  @override
  bool get isConst => false;

  @override
  String render(int indent, {bool inConst = false}) {
    if (lines.isEmpty) return '() {}';
    final pad = '  ' * (indent + 1);
    final buffer = StringBuffer('() {\n');
    for (final line in lines) {
      buffer.writeln('$pad$line');
    }
    buffer.write('${'  ' * indent}}');
    return buffer.toString();
  }
}

/// A named or positional argument.
class Arg {
  const Arg(this.name, this.value);
  const Arg.positional(this.value) : name = null;

  final String? name;
  final CodeExpr value;
}

/// A constructor or function call. Short calls stay on one line; longer
/// ones get one argument per line with trailing commas, like `dart format`.
class CallCode extends CodeExpr {
  const CallCode(this.name, [this.args = const [], this.canBeConst = true]);

  final String name;
  final List<Arg> args;

  /// False for calls that are never const, such as `Image.network` or
  /// `Container`.
  final bool canBeConst;

  static const _maxLine = 72;

  @override
  bool get isConst => canBeConst && args.every((arg) => arg.value.isConst);

  @override
  String render(int indent, {bool inConst = false}) {
    final constHere = isConst && !inConst;
    final childConst = inConst || constHere;
    final head = '${constHere ? 'const ' : ''}$name';
    if (args.isEmpty) return '$head()';
    final parts = [
      for (final arg in args)
        arg.name == null
            ? arg.value.render(indent + 1, inConst: childConst)
            : '${arg.name}: ${arg.value.render(indent + 1, inConst: childConst)}',
    ];
    if (parts.every((part) => !part.contains('\n'))) {
      final inline = '$head(${parts.join(', ')})';
      if (inline.length + indent * 2 <= _maxLine) return inline;
    }
    final pad = '  ' * (indent + 1);
    final buffer = StringBuffer('$head(\n');
    for (final part in parts) {
      buffer
        ..write(pad)
        ..write(part)
        ..write(',\n');
    }
    buffer.write('${'  ' * indent})');
    return buffer.toString();
  }
}

/// A list literal, always one item per line.
class ListCode extends CodeExpr {
  const ListCode(this.items);

  final List<CodeExpr> items;

  @override
  bool get isConst => items.every((item) => item.isConst);

  @override
  String render(int indent, {bool inConst = false}) {
    if (items.isEmpty) return '[]';
    final pad = '  ' * (indent + 1);
    final buffer = StringBuffer('[\n');
    for (final item in items) {
      buffer
        ..write(pad)
        ..write(item.render(indent + 1, inConst: inConst))
        ..write(',\n');
    }
    buffer.write('${'  ' * indent}]');
    return buffer.toString();
  }
}

/// Quotes [value] as a Dart string literal.
String dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\r', '')
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}

/// Formats a number without a trailing `.0`.
String formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
