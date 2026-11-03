import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_preset.dart';

/// Draws a realistic device around [child]: an iPhone with Dynamic Island,
/// an Android phone with a punch-hole camera, an iPad, a Mac window or a
/// Chrome window.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, required this.device, required this.child});

  final DevicePreset device;
  final Widget child;

  static const _shadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 48, offset: Offset(0, 24)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = SizedBox(
      width: device.width,
      height: device.height,
      child: child,
    );
    return switch (device.kind) {
      DeviceKind.phone => device == DevicePreset.iphone
          ? _IPhone(screen: screen, device: device)
          : _AndroidPhone(screen: screen, device: device),
      DeviceKind.tablet => _Tablet(screen: screen, device: device),
      DeviceKind.desktop || DeviceKind.browser =>
        _Window(screen: screen, device: device),
    };
  }
}

/// iPhone 16 Pro: titanium edge, Dynamic Island, status bar, home
/// indicator and side buttons.
class _IPhone extends StatelessWidget {
  const _IPhone({required this.screen, required this.device});

  final Widget screen;
  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    const bezel = 12.0;
    const radius = 55.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Side buttons: action button and volume on the left, power on the
        // right.
        _sideButton(left: true, top: 150, height: 34),
        _sideButton(left: true, top: 215, height: 62),
        _sideButton(left: true, top: 290, height: 62),
        _sideButton(left: false, top: 240, height: 96),
        Container(
          padding: const EdgeInsets.all(bezel),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + bezel),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8D8A85), Color(0xFF3F3D3A), Color(0xFF8D8A85)],
            ),
            boxShadow: DeviceFrame._shadow,
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 3),
              child: Stack(
                children: [
                  screen,
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 54,
                    child: _StatusBar(time: '9:41', apple: true),
                  ),
                  Positioned(
                    top: 11,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 124,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const _HomeIndicator(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sideButton({
    required bool left,
    required double top,
    required double height,
  }) {
    return Positioned(
      top: top,
      left: left ? -3 : null,
      right: left ? null : -3,
      child: Container(
        width: 5,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5E5B57),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _AndroidPhone extends StatelessWidget {
  const _AndroidPhone({required this.screen, required this.device});

  final Widget screen;
  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    const bezel = 10.0;
    const radius = 40.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 200,
          right: -3,
          child: Container(
            width: 5,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3F47),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(bezel),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2328),
            borderRadius: BorderRadius.circular(radius + bezel),
            boxShadow: DeviceFrame._shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                screen,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 36,
                  child: _StatusBar(time: '12:30', apple: false),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const _HomeIndicator(width: 108, bottom: 7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet({required this.screen, required this.device});

  final Widget screen;
  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(40),
        boxShadow: DeviceFrame._shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            screen,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24,
              child: _StatusBar(time: '9:41', apple: true, compact: true),
            ),
            const _HomeIndicator(width: 300, bottom: 6),
          ],
        ),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({required this.screen, required this.device});

  final Widget screen;
  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    final isBrowser = device.kind == DeviceKind.browser;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33000000)),
        boxShadow: DeviceFrame._shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: device.width,
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final color in const [
                    Color(0xFFFF5F57),
                    Color(0xFFFEBC2E),
                    Color(0xFF28C840),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  if (isBrowser)
                    Expanded(
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 13, color: Color(0xFF6B7280)),
                            SizedBox(width: 6),
                            Text(
                              'myapp.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Text(
                        'My App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ),
          screen,
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.time,
    required this.apple,
    this.compact = false,
  });

  final String time;
  final bool apple;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF111111);
    final size = compact ? 12.0 : 15.0;
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: apple && !compact ? 34 : 20),
        child: Row(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt, size: size + 1, color: color),
            const SizedBox(width: 4),
            Icon(Icons.wifi, size: size + 1, color: color),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: math.pi / 2,
              child: Icon(Icons.battery_full, size: size + 4, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator({this.width = 134, this.bottom = 8});

  final double width;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: width,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
