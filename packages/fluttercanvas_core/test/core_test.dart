import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

WidgetNode _node(
  String type, {
  String? id,
  String name = '',
  Map<String, Object?> props = const {},
  List<WidgetNode> children = const [],
}) {
  return WidgetNode(
    id: id ?? NodeIds.next(),
    type: type,
    name: name,
    props: {...WidgetCatalog.defaultsFor(type), ...props},
    children: children,
  );
}

void _expectBalanced(String code, String path) {
  for (final pair in const [('(', ')'), ('[', ']'), ('{', '}')]) {
    expect(
      pair.$1.allMatches(code).length,
      pair.$2.allMatches(code).length,
      reason: 'unbalanced ${pair.$1}${pair.$2} in $path',
    );
  }
}

void main() {
  group('CanvasDocument', () {
    test('survives a JSON round trip', () {
      final document = CanvasDocument.starter();
      final restored = CanvasDocument.fromJsonString(document.toJsonString());
      expect(restored.toJson(), document.toJson());
      expect(restored.id, document.id);
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

  group('CanvasProject', () {
    test('survives a JSON round trip', () {
      final project = CanvasProject.starter();
      final restored = CanvasProject.fromJsonString(project.toJsonString());
      expect(restored.toJson(), project.toJson());
      expect(restored.screens, hasLength(2));
    });

    test('reads single-screen JSON from version 0.1', () {
      final json = CanvasDocument.starter().toJsonString();
      final project = CanvasProject.fromJsonString(json);
      expect(project.screens, hasLength(1));
      expect(project.initialScreenId, project.screens.single.id);
    });

    test('moves the start screen when it is removed', () {
      final project = CanvasProject.starter();
      final rest = project.removeScreen(project.initialScreenId);
      expect(rest.screens, hasLength(1));
      expect(rest.initialScreenId, rest.screens.single.id);
      expect(rest.removeScreen(rest.initialScreenId).screens, hasLength(1));
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

    test('clones with new ids and keeps names', () {
      final named = _node(WidgetTypes.card, name: 'Promo card');
      final copy = named.cloneWithNewIds();
      expect(copy.id, isNot(named.id));
      expect(copy.name, 'Promo card');
    });
  });

  group('FlutterCodeGenerator.generate', () {
    test('writes one self-contained screen', () {
      final code =
          const FlutterCodeGenerator().generate(CanvasDocument.starter());
      expect(code, contains('class HomeScreen extends StatelessWidget'));
      expect(code, contains('LayoutBuilder('));
      expect(code, contains('ResponsiveGrid('));
      expect(code, contains('class ResponsiveGrid extends StatelessWidget'));
      expect(code, isNot(contains('class AdaptiveRow')));
      expect(code, contains('const Text('));
      expect(code, contains('// TODO: Add what this button does.'));
      _expectBalanced(code, 'single file');
    });

    test('escapes text safely', () {
      final document = CanvasDocument.blank().copyWith(
        root: _node(WidgetTypes.column, id: 'root', children: [
          _node(WidgetTypes.text, props: {'text': r"It's $5"}),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains(r"'It\'s \$5'"));
    });

    test('turns named layers into widget classes', () {
      final document = CanvasDocument.blank().copyWith(
        root: _node(WidgetTypes.column, id: 'root', children: [
          _node(WidgetTypes.card, name: 'feature card', children: [
            _node(WidgetTypes.text, props: {'text': 'Fast'}),
          ]),
          _node(WidgetTypes.card, name: 'feature card'),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains('class FeatureCard extends StatelessWidget'));
      expect(code, contains('class FeatureCard2 extends StatelessWidget'));
      expect(code, contains('FeatureCard(),'));
      _expectBalanced(code, 'named layers');
    });

    test('sizes any widget and positions widgets in a free canvas', () {
      final document = CanvasDocument.blank().copyWith(
        root: _node(WidgetTypes.column, id: 'root', children: [
          _node(WidgetTypes.text,
              props: {'text': 'Sized', 'width': 120, 'margin': 8}),
          _node(WidgetTypes.freeCanvas, children: [
            _node(WidgetTypes.text, props: {'text': 'Free', 'x': 40, 'y': 24}),
            _node(WidgetTypes.image, props: {'x': 10, 'y': 80}),
          ]),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains('width: 120'));
      expect(code, contains('Positioned('));
      expect(code, contains('left: 40'));
      expect(code, contains('width: 200'));
      expect(code, contains('class FreeCanvas extends StatelessWidget'));
      _expectBalanced(code, 'free canvas');
    });

    test('draws boxes inside boxes on a free-form screen', () {
      final screen = CanvasDocument.freeForm();
      final document = screen.copyWith(
        root: screen.root.copyWith(children: [
          _node(WidgetTypes.box, props: {
            'x': 20,
            'y': 30,
            'borderColor': '#FF000000',
            'borderWidth': 2,
            'shadow': 8,
          }, children: [
            _node(WidgetTypes.box, props: {'x': 10, 'y': 10, 'width': 60}),
            _node(WidgetTypes.text, props: {'text': 'Inside', 'x': 8, 'y': 80}),
          ]),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains('body: SingleChildScrollView('));
      expect(code, isNot(contains('LayoutBuilder(')));
      expect(code, contains('FreeCanvas('));
      expect(code, contains('Border.fromBorderSide('));
      expect(code, contains('BoxShadow('));
      expect(code, contains('left: 20'));
      expect(code, contains('width: 60'));
      expect(code, contains("'Inside'"));
      _expectBalanced(code, 'boxes');
    });

    test('keeps the drawn size inside a stretched column', () {
      final document = CanvasDocument.blank().copyWith(
        root: _node(WidgetTypes.column, id: 'root', children: [
          _node(WidgetTypes.box, props: {'width': 40, 'height': 40}),
          _node(WidgetTypes.container, props: {'width': 80}),
          _node(WidgetTypes.text, props: {'text': 'Full width'}),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect('Alignment.centerLeft'.allMatches(code).length, 2);
      expect(code, contains('widthFactor: 1'));
      expect(code, contains('height: 40'));
      _expectBalanced(code, 'sizes');
    });

    test('boxes lay out in a row and images can fill a box', () {
      final screen = CanvasDocument.freeForm();
      final document = screen.copyWith(
        root: screen.root.copyWith(children: [
          _node(WidgetTypes.box, props: {
            'layout': 'row',
            'width': 300,
            'height': 64,
            'spacing': 12,
          }, children: [
            _node(WidgetTypes.box, props: {
              'width': 40,
              'height': 40,
              'borderRadius': 20,
            }, children: [
              _node(WidgetTypes.image, props: {'fill': true}),
            ]),
            _node(WidgetTypes.text, props: {'text': 'Sulman Ali'}),
          ]),
        ]),
      );
      final code = const FlutterCodeGenerator().generate(document);
      expect(code, contains('Row('));
      expect(code, contains('spacing: 12'));
      expect(code, contains('Positioned.fill('));
      expect(code, contains("'Sulman Ali'"));
      _expectBalanced(code, 'auto layout');
    });

    test('copies one widget as code', () {
      final code = const FlutterCodeGenerator().generateWidget(
        _node(WidgetTypes.text, props: {'text': 'Hi'}),
      );
      expect(code, startsWith('const Text('));
      expect(code, contains("'Hi'"));
    });

    test('builds class, file and route names', () {
      expect(FlutterCodeGenerator.className('my cool page'), 'MyCoolPage');
      expect(FlutterCodeGenerator.screenClassName('Login'), 'LoginScreen');
      expect(
          FlutterCodeGenerator.screenClassName('LoginScreen'), 'LoginScreen');
      expect(FlutterCodeGenerator.fileName('Home'), 'home_screen.dart');
      expect(FlutterCodeGenerator.routeName('Order details'), 'orderDetails');
      expect(FlutterCodeGenerator.routeName('Routes'), 'routesScreen');
    });
  });

  group('FlutterCodeGenerator.generateProject', () {
    late List<GeneratedFile> files;
    String file(String path) => files.firstWhere((f) => f.path == path).content;

    setUp(() {
      files = const FlutterCodeGenerator()
          .generateProject(CanvasProject.starter());
    });

    test('writes a lib folder', () {
      expect(files.map((f) => f.path), [
        'lib/main.dart',
        'lib/app_routes.dart',
        'lib/screens/home_screen.dart',
        'lib/screens/details_screen.dart',
        'lib/widgets/responsive_layout.dart',
      ]);
      for (final f in files) {
        _expectBalanced(f.content, f.path);
      }
    });

    test('links screens with named routes', () {
      expect(file('lib/main.dart'), contains('initialRoute: AppRoutes.home'));
      expect(file('lib/app_routes.dart'), contains("static const home = '/';"));
      expect(file('lib/app_routes.dart'),
          contains("static const details = '/details';"));
      expect(file('lib/screens/home_screen.dart'),
          contains('Navigator.pushNamed(context, AppRoutes.details);'));
      expect(file('lib/screens/home_screen.dart'),
          contains("import '../app_routes.dart';"));
      expect(file('lib/screens/details_screen.dart'),
          contains('Navigator.maybePop(context);'));
      expect(file('lib/screens/details_screen.dart'),
          isNot(contains('app_routes.dart')));
    });

    test('keeps duplicate screen names apart', () {
      final project = CanvasProject(screens: [
        CanvasDocument.blank(name: 'Home'),
        CanvasDocument.blank(name: 'Home'),
      ]);
      final paths = const FlutterCodeGenerator()
          .generateProject(project)
          .map((f) => f.path);
      expect(paths, contains('lib/screens/home_screen.dart'));
      expect(paths, contains('lib/screens/home2_screen.dart'));
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

  group('0.3 features', () {
    test('e-commerce template exports a complete app', () {
      final project = CanvasTemplates.ecommerce();
      final files =
          const FlutterCodeGenerator().generateProject(project);
      final shop =
          files.firstWhere((f) => f.path == 'lib/screens/shop_screen.dart');
      expect(shop.content, contains('bottomNavigationBar: NavigationBar('));
      expect(shop.content, contains('Badge('));
      expect(shop.content, contains('EntranceAnimation('));
      expect(shop.content, contains('GestureDetector('));
      expect(shop.content, contains('AppRoutes.product'));
      final layout = files.firstWhere(
          (f) => f.path == 'lib/widgets/responsive_layout.dart');
      expect(layout.content, contains('class EntranceAnimation'));
      for (final f in files) {
        _expectBalanced(f.content, f.path);
      }
      final restored = CanvasProject.fromJsonString(project.toJsonString());
      expect(restored.toJson(), project.toJson());
    });

    test('custom code adds imports and pubspec packages', () {
      final screen = CanvasDocument.blank();
      final project = CanvasProject(screens: [
        screen.copyWith(
          root: screen.root.copyWith(children: [
            _node(WidgetTypes.customCode, props: {
              'code': "Lottie.asset('assets/cart.json')",
              'imports': "import 'package:lottie/lottie.dart';",
              'packages': 'lottie: ^3.1.0',
            }),
          ]),
        ),
      ]);
      final files = const FlutterCodeGenerator().generateProject(project);
      final home =
          files.firstWhere((f) => f.path == 'lib/screens/home_screen.dart');
      expect(home.content, contains("import 'package:lottie/lottie.dart';"));
      expect(home.content, contains("Lottie.asset('assets/cart.json')"));
      final deps =
          files.firstWhere((f) => f.path == 'pubspec_dependencies.yaml');
      expect(deps.content, contains('lottie: ^3.1.0'));
    });

    test('AI replies are read even with text around them', () {
      final json = CanvasTemplates.blank().toJsonString();
      final project = DesignPrompt.parseReply('Here you go:\n```json\n$json\n```');
      expect(project.screens, hasLength(1));
      expect(DesignPrompt.formatGuide(), contains('freeCanvas'));
      expect(() => DesignPrompt.parseReply('sorry'), throwsFormatException);

      final chat = DesignPrompt.parseChatReply(
          '{"message": "Added a banner", "project": $json}');
      expect(chat.message, 'Added a banner');
      expect(chat.project, isNotNull);
      final answer = DesignPrompt.parseChatReply('Sure, I can help with that.');
      expect(answer.project, isNull);
      expect(answer.message, 'Sure, I can help with that.');
    });
  });
}
