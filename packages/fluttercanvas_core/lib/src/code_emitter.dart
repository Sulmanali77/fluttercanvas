/// A tiny code model the generator uses to print readable, indented Dart.
sealed class CodeExpr {
  const CodeExpr();

  /// Renders this expression. [indent] is the nesting level (2 spaces each)
  /// of the line the expression starts on.
  String render(int indent);
}

/// Code that is printed as-is.
class RawCode extends CodeExpr {
  const RawCode(this.code);

  final String code;

  @override
  String render(int indent) => code;
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
  const CallCode(this.name, [this.args = const []]);

  final String name;
  final List<Arg> args;

  static const _maxLine = 72;

  @override
  String render(int indent) {
    if (args.isEmpty) return '$name()';
    final parts = [
      for (final arg in args)
        arg.name == null
            ? arg.value.render(indent + 1)
            : '${arg.name}: ${arg.value.render(indent + 1)}',
    ];
    if (parts.every((part) => !part.contains('\n'))) {
      final inline = '$name(${parts.join(', ')})';
      if (inline.length + indent * 2 <= _maxLine) return inline;
    }
    final pad = '  ' * (indent + 1);
    final buffer = StringBuffer('$name(\n');
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
  String render(int indent) {
    if (items.isEmpty) return '[]';
    final pad = '  ' * (indent + 1);
    final buffer = StringBuffer('[\n');
    for (final item in items) {
      buffer
        ..write(pad)
        ..write(item.render(indent + 1))
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
