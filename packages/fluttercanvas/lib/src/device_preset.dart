import 'package:flutter/material.dart';

/// The kind of device frame drawn around the canvas.
enum DeviceKind { phone, tablet, desktop, browser }

/// Screen sizes the canvas can preview.
enum DevicePreset {
  iphone('iPhone 16 Pro', 393, 852, DeviceKind.phone, Icons.phone_iphone,
      safeTop: 59, safeBottom: 34),
  android('Pixel 9', 412, 915, DeviceKind.phone, Icons.phone_android,
      safeTop: 36, safeBottom: 20),
  ipad('iPad Air', 820, 1180, DeviceKind.tablet, Icons.tablet_mac,
      safeTop: 24, safeBottom: 20),
  mac('MacBook', 1280, 800, DeviceKind.desktop, Icons.laptop_mac),
  chrome('Chrome', 1440, 900, DeviceKind.browser, Icons.public);

  const DevicePreset(
    this.label,
    this.width,
    this.height,
    this.kind,
    this.icon, {
    this.safeTop = 0,
    this.safeBottom = 0,
  });

  final String label;
  final double width;
  final double height;
  final DeviceKind kind;
  final IconData icon;

  /// Space taken by the status bar and camera at the top.
  final double safeTop;

  /// Space taken by the home indicator or navigation bar at the bottom.
  final double safeBottom;

  bool get isApple => this == iphone || this == ipad || this == mac;
}
