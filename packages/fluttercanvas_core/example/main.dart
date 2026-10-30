// ignore_for_file: avoid_print
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Builds a design in code, saves it as JSON and prints the generated
/// Flutter screen.
void main() {
  final document = CanvasDocument.blank().copyWith(name: 'Profile page');
  final title = WidgetCatalog.create(WidgetTypes.text)
      .withProp('text', 'Hello from FlutterCanvas')
      .withProp('fontSize', 24);
  final design = document.copyWith(
    root: document.root.insert(document.root.id, 0, title),
  );

  print(design.toJsonString(pretty: true));
  print(const FlutterCodeGenerator().generate(design));
}
