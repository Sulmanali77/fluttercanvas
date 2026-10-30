import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

WidgetNode _node(String type, {String? id, List<WidgetNode> children = const []}) {
  return WidgetNode(
    id: id ?? NodeIds.next(),
    type: type,
    props: WidgetCatalog.defaultsFor(type),
    children: children,
  );
}

void main() {
  group('CanvasDocument', () {
    test('survives a JSON round trip', () {
      final document = CanvasDocument.starter();
      final restored = CanvasDocument.fromJsonString(document.toJsonString());
      expect(restored.toJson(), document.toJson());
    });

    test('fills in default props for partial JSON', () {
      final document = CanvasDocument.fromJsonString(
        '{"root": {"type": "column", "children": [{"type": "text"}]}}',
      );
      final text = document.root.children.single;
      expect(text.string('text'), 'Text');
      expect(text.number('fontSize'), 16);
    });

    test('rejects JSON without a root', () {
      expect(() => CanvasDocument.fromJsonString('{}'), throwsFormatException);
    });
  });

  group('WidgetTree', () {
    late WidgetNode root;

    setUp(() {
      root = _node(WidgetTypes.column, id: 'root', children: [
        _node(WidgetTypes.text, id: 'a'),
        _node(WidgetTypes.text, id: 'b'),
        _node(WidgetTypes.card, id: 'card'),
      ]);
    });

    test('finds nodes and parents', () {
      expect(root.find('b')?.id, 'b');
      expect(root.parentOf('b')?.id, 'root');
      expect(root.find('missing'), isNull);
    });

    test('inserts, removes and moves', () {
      var tree = root.insert('card', 0, _node(WidgetTypes.icon, id: 'icon'));
      expect(tree.find('card')!.children.single.id, 'icon');

      tree = tree.move('b', 'root', 0);
      expect(tree.children.map((c) => c.id), ['b', 'a', 'card']);

      tree = tree.move('b', 'root', 3);
      expect(tree.children.map((c) => c.id), ['a', 'card', 'b']);

      tree = tree.remove('card');
      expect(tree.contains('icon'), isFalse);
      expect(root.contains('card'), isTrue, reason: 'original is unchanged');
    });

    test('refuses to move a node into itself', () {
      final tree = root
          .insert('card', 0, _node(WidgetTypes.column, id: 'inner'))
          .move('card', 'inner', 0);
      expect(tree.find('card')!.children.single.id, 'inner');
    });

    test('clones with new ids', () {
      final copy = root.cloneWithNewIds();
      expect(copy.id, isNot(root.id));
      expect(copy.children.length, root.children.length);
    });
  });

  group('FlutterCodeGenerator', () {
    test('generates a screen with responsive helpers', () {
      final code = const FlutterCodeGenerator().generate(CanvasDocument.starter());
      expect(code, contains('class HomeScreen extends StatelessWidget'));
      expect(code, contains('LayoutBuilder('));
      expect(code, contains('_ResponsiveGrid('));
      expect(code, contains('class _ResponsiveGrid extends StatelessWidget'));
      expect(code, isNot(contains('class _AdaptiveRow')));
      for (final pair in const [('(', ')'), ('[', ']'), ('{', '}')]) {
        expect(
          pair.$1.allMatches(code).length,
          pair.$2.allMatches(code).length,
          reason: 'unbalanced ${pair.$1}${pair.$2}',
        );
      }
    });

    test('escapes text safely', () {
      final document = CanvasDocument.blank().copyWith(
        root: WidgetNode(id: 'root', type: WidgetTypes.column, children: [
          WidgetNode(
            id: 't',
            type: WidgetTypes.text,
            props: {...WidgetCatalog.defaultsFor(WidgetTypes.text), 'text': r"It's $5"},
          ),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains(r"'It\'s \$5'"));
    });

    test('builds class and file names', () {
      expect(FlutterCodeGenerator.className('my cool page'), 'MyCoolPage');
      expect(FlutterCodeGenerator.className(''), 'GeneratedScreen');
      expect(FlutterCodeGenerator.fileName('HomeScreen'), 'home_screen.dart');
    });
  });

  group('colors', () {
    test('parses hex colors', () {
      expect(parseHexColor('#FFF'), 0xFFFFFFFF);
      expect(parseHexColor('#112233'), 0xFF112233);
      expect(parseHexColor('#80112233'), 0x80112233);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('nope'), isNull);
      expect(formatHexColor(0xFF112233), '#FF112233');
    });
  });
}
