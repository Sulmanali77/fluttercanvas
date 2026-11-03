import 'canvas_document.dart';
import 'canvas_project.dart';
import 'widget_catalog.dart';
import 'widget_node.dart';

/// Ready-made projects to start from.
abstract final class CanvasTemplates {
  /// The two-screen sample: Home links to Details.
  static CanvasProject starter() => CanvasProject.starter();

  /// One empty free-form screen to draw on.
  static CanvasProject blank() =>
      CanvasProject(screens: [CanvasDocument.freeForm()]);

  /// A small animated shop: Shop, Product, Cart and Profile, with a bottom
  /// navigation bar, a cart badge and linked product cards.
  static CanvasProject ecommerce() {
    const indigo = '#FF4F46E5';
    const grey = '#FF6B7280';

    WidgetNode n(
      String type, [
      Map<String, Object?> props = const {},
      List<WidgetNode> children = const [],
    ]) =>
        WidgetNode(
          id: NodeIds.next(),
          type: type,
          props: {...WidgetCatalog.defaultsFor(type), ...props},
          children: children,
        );

    WidgetNode column(List<WidgetNode> children, {double spacing = 16}) =>
        WidgetNode(
          id: 'root',
          type: WidgetTypes.column,
          props: {
            ...WidgetCatalog.defaultsFor(WidgetTypes.column),
            'spacing': spacing,
          },
          children: children,
        );

    String photo(String seed, [int w = 600, int h = 600]) =>
        'https://picsum.photos/seed/$seed/$w/$h';

    final product = CanvasDocument(
      name: 'Product',
      title: 'Product',
      bars: {BarKeys.action1Icon: 'share'},
      root: column([]),
    );
    final cart = CanvasDocument(
      name: 'Cart',
      title: 'Cart',
      bars: {BarKeys.navIcon: 'shopping_cart', BarKeys.navLabel: 'Cart'},
      root: column([]),
    );

    WidgetNode productCard(String name, String price, String seed, int i) => n(
          WidgetTypes.box,
          {
            'layout': 'column',
            'width': 0,
            'height': 0,
            'padding': 10,
            'spacing': 6,
            'crossAxisAlignment': 'start',
            'color': '#FFFFFFFF',
            'borderRadius': 18,
            'shadow': 6,
            'navigateTo': product.id,
            'animation': 'slideUp',
            'animationMs': 350 + i * 120,
          },
          [
            n(WidgetTypes.image, {
              'url': photo(seed),
              'height': 130,
              'borderRadius': 12,
            }),
            n(WidgetTypes.text, {
              'text': name,
              'fontSize': 15,
              'fontWeight': 'semibold',
            }),
            n(WidgetTypes.text, {
              'text': price,
              'fontSize': 15,
              'fontWeight': 'bold',
              'color': indigo,
            }),
          ],
        );

    final shop = CanvasDocument(
      name: 'Shop',
      title: 'Shop',
      backgroundColor: '#FFF8FAFC',
      bars: {
        BarKeys.navIcon: 'storefront',
        BarKeys.navLabel: 'Shop',
        BarKeys.action1Icon: 'shopping_cart',
        BarKeys.action1Link: cart.id,
        BarKeys.action1Badge: '2',
      },
      root: column([
        n(WidgetTypes.text, {
          'text': 'Find your style',
          'fontSize': 28,
          'fontWeight': 'bold',
          'animation': 'slideUp',
        }),
        n(WidgetTypes.text, {
          'text': 'New arrivals picked for you',
          'color': grey,
          'animation': 'fade',
          'animationMs': 600,
        }),
        n(
          WidgetTypes.box,
          {
            'width': 0,
            'height': 150,
            'color': indigo,
            'borderRadius': 22,
            'shadow': 8,
            'animation': 'scale',
          },
          [
            n(WidgetTypes.text, {
              'text': 'Summer sale',
              'fontSize': 24,
              'fontWeight': 'bold',
              'color': '#FFFFFFFF',
              'x': 20,
              'y': 22,
            }),
            n(WidgetTypes.text, {
              'text': r'Up to 50% off everything',
              'color': '#FFE0E7FF',
              'x': 20,
              'y': 58,
            }),
            n(WidgetTypes.button, {
              'label': 'Shop now',
              'variant': 'outlined',
              'color': '#FFFFFFFF',
              'x': 20,
              'y': 92,
              'navigateTo': product.id,
            }),
          ],
        ),
        n(WidgetTypes.text, {
          'text': 'Popular',
          'fontSize': 20,
          'fontWeight': 'bold',
        }),
        n(
          WidgetTypes.grid,
          {
            'mobileColumns': 2,
            'tabletColumns': 3,
            'desktopColumns': 4,
            'spacing': 12,
          },
          [
            productCard('Classic sneakers', r'$89', 'sneakers', 0),
            productCard('Leather bag', r'$129', 'bag', 1),
            productCard('Smart watch', r'$199', 'watch', 2),
            productCard('Sunglasses', r'$59', 'glasses', 3),
          ],
        ),
      ]),
    );

    final productScreen = product.copyWith(
      root: column([
        n(WidgetTypes.image, {
          'url': photo('sneakers', 900, 700),
          'height': 300,
          'borderRadius': 24,
          'animation': 'scale',
        }),
        n(WidgetTypes.text, {
          'text': 'Classic sneakers',
          'fontSize': 26,
          'fontWeight': 'bold',
          'animation': 'slideUp',
        }),
        n(WidgetTypes.text, {
          'text': r'$89',
          'fontSize': 22,
          'fontWeight': 'bold',
          'color': indigo,
          'animation': 'slideUp',
          'animationMs': 500,
        }),
        n(WidgetTypes.text, {
          'text': 'Soft leather, all-day comfort and a sole that grips. '
              'Available in five colors.',
          'color': grey,
          'animation': 'fade',
          'animationMs': 700,
        }),
        n(WidgetTypes.button, {
          'label': 'Add to cart',
          'fullWidth': true,
          'navigateTo': cart.id,
          'action': 'add_to_cart',
          'animation': 'slideUp',
          'animationMs': 800,
        }),
      ]),
    );

    WidgetNode cartItem(String name, String price, String seed, int i) => n(
          WidgetTypes.box,
          {
            'layout': 'row',
            'width': 0,
            'height': 0,
            'padding': 12,
            'spacing': 12,
            'color': '#FFFFFFFF',
            'borderRadius': 16,
            'shadow': 4,
            'animation': 'slideLeft',
            'animationMs': 350 + i * 150,
          },
          [
            n(
              WidgetTypes.box,
              {'width': 64, 'height': 64, 'borderRadius': 14},
              [
                n(WidgetTypes.image, {
                  'url': photo(seed, 200, 200),
                  'fill': true,
                  'borderRadius': 0,
                }),
              ],
            ),
            n(WidgetTypes.text, {
              'text': '$name\n$price',
              'fontSize': 15,
              'fontWeight': 'semibold',
            }),
            n(WidgetTypes.icon, {
              'icon': 'delete',
              'size': 22,
              'color': grey,
              'action': 'remove_item',
            }),
          ],
        );

    final cartScreen = cart.copyWith(
      backgroundColor: '#FFF8FAFC',
      root: column([
        n(WidgetTypes.text, {
          'text': 'Your cart',
          'fontSize': 26,
          'fontWeight': 'bold',
          'animation': 'slideUp',
        }),
        cartItem('Classic sneakers', r'$89', 'sneakers', 0),
        cartItem('Sunglasses', r'$59', 'glasses', 1),
        n(WidgetTypes.divider),
        n(
          WidgetTypes.box,
          {
            'layout': 'row',
            'width': 0,
            'height': 0,
            'color': '',
            'mainAxisAlignment': 'spaceBetween',
          },
          [
            n(WidgetTypes.text, {
              'text': 'Total',
              'fontSize': 18,
              'fontWeight': 'bold',
            }),
            n(WidgetTypes.text, {
              'text': r'$148',
              'fontSize': 18,
              'fontWeight': 'bold',
              'color': indigo,
            }),
          ],
        ),
        n(WidgetTypes.button, {
          'label': 'Checkout',
          'fullWidth': true,
          'action': 'checkout',
          'animation': 'fade',
          'animationMs': 700,
        }),
      ]),
    );

    final profile = CanvasDocument(
      name: 'Profile',
      title: 'Profile',
      bars: {
        BarKeys.navIcon: 'person',
        BarKeys.navLabel: 'Profile',
        BarKeys.centerTitle: true,
      },
      root: WidgetNode(
        id: 'root',
        type: WidgetTypes.column,
        props: {
          ...WidgetCatalog.defaultsFor(WidgetTypes.column),
          'spacing': 12,
          'crossAxisAlignment': 'center',
        },
        children: [
          n(
            WidgetTypes.box,
            {
              'width': 96,
              'height': 96,
              'borderRadius': 48,
              'borderColor': indigo,
              'borderWidth': 3,
              'animation': 'scale',
            },
            [
              n(WidgetTypes.image, {
                'url': photo('avatar', 300, 300),
                'fill': true,
                'borderRadius': 0,
              }),
            ],
          ),
          n(WidgetTypes.text, {
            'text': 'Sulman Ali',
            'fontSize': 22,
            'fontWeight': 'bold',
            'animation': 'fade',
          }),
          n(WidgetTypes.text, {
            'text': 'sulman@example.com',
            'color': grey,
            'animation': 'fade',
            'animationMs': 600,
          }),
          n(WidgetTypes.button, {
            'label': 'My orders',
            'variant': 'outlined',
            'fullWidth': true,
            'navigateTo': cart.id,
            'animation': 'slideUp',
            'animationMs': 700,
          }),
        ],
      ),
    );

    return CanvasProject(
      name: 'ShopEase',
      screens: [shop, productScreen, cartScreen, profile],
    );
  }
}
