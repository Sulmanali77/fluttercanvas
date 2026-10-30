import 'package:flutter/material.dart';

/// The kind of device frame drawn around the canvas.
enum DeviceKind { phone, tablet, desktop, browser }

/// Screen sizes the canvas can preview.
enum DevicePreset {
  iphone('iPhone', 393, 852, DeviceKind.phone, Icons.phone_iphone),
  android('Android phone', 412, 915, DeviceKind.phone, Icons.phone_android),
  ipad('iPad', 820, 1180, DeviceKind.tablet, Icons.tablet_mac),
  mac('Mac', 1280, 800, DeviceKind.desktop, Icons.laptop_mac),
  chrome('Chrome', 1440, 900, DeviceKind.browser, Icons.public);

  const DevicePreset(this.label, this.width, this.height, this.kind, this.icon);

  final String label;
  final double width;
  final double height;
  final DeviceKind kind;
  final IconData icon;
}
