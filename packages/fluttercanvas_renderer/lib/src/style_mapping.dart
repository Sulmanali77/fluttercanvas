import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

Color? colorOf(String? hex) {
  final value = parseHexColor(hex);
  return value == null ? null : Color(value);
}

MainAxisAlignment mainAxisOf(String value) => switch (value) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };

CrossAxisAlignment crossAxisOf(String value) => switch (value) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };

FontWeight fontWeightOf(String value) => switch (value) {
      'medium' => FontWeight.w500,
      'semibold' => FontWeight.w600,
      'bold' => FontWeight.w700,
      _ => FontWeight.w400,
    };

TextAlign textAlignOf(String value) => switch (value) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

BoxFit boxFitOf(String value) => switch (value) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      _ => BoxFit.cover,
    };

const Map<String, IconData> _icons = {
  'star': Icons.star,
  'favorite': Icons.favorite,
  'home': Icons.home,
  'person': Icons.person,
  'settings': Icons.settings,
  'search': Icons.search,
  'mail': Icons.mail,
  'phone': Icons.phone,
  'shopping_cart': Icons.shopping_cart,
  'check': Icons.check,
  'info': Icons.info,
  'menu': Icons.menu,
  'notifications': Icons.notifications,
  'lock': Icons.lock,
  'calendar_today': Icons.calendar_today,
  'camera_alt': Icons.camera_alt,
  'storefront': Icons.storefront,
  'shopping_bag': Icons.shopping_bag,
  'local_offer': Icons.local_offer,
  'arrow_back': Icons.arrow_back,
  'close': Icons.close,
  'add': Icons.add,
  'remove': Icons.remove,
  'delete': Icons.delete,
  'share': Icons.share,
  'more_vert': Icons.more_vert,
  'chevron_right': Icons.chevron_right,
  'location_on': Icons.location_on,
  'credit_card': Icons.credit_card,
  'tune': Icons.tune,
  'bookmark': Icons.bookmark,
  'grid_view': Icons.grid_view,
  'category': Icons.category,
};

IconData iconOf(String name) => _icons[name] ?? Icons.help_outline;
