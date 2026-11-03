// ignore_for_file: avoid_print
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Builds a two-screen project and prints every generated file.
void main() {
  final project = CanvasProject.starter();
  print(project.toJsonString(pretty: true));

  for (final file in const FlutterCodeGenerator().generateProject(project)) {
    print('// ===== ${file.path} =====');
    print(file.content);
  }
}
