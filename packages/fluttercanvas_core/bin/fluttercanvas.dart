import 'dart:io';

import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Exports a design to Flutter files:
///
///     dart run fluttercanvas_core:fluttercanvas export design.json [folder]
void main(List<String> args) {
  if (args.length < 2 || args.first != 'export') {
    stderr.writeln(
      'Usage: dart run fluttercanvas_core:fluttercanvas '
      'export <design.json> [output folder]',
    );
    exitCode = 64;
    return;
  }
  final source = File(args[1]);
  if (!source.existsSync()) {
    stderr.writeln('Could not find ${source.path}');
    exitCode = 66;
    return;
  }
  final project = CanvasProject.fromJsonString(source.readAsStringSync());
  final output = args.length > 2 ? args[2] : '.';
  for (final file in const FlutterCodeGenerator().generateProject(project)) {
    final target = File('$output/${file.path}');
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(file.content);
    stdout.writeln('Wrote ${target.path}');
  }
}
