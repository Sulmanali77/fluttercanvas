import 'package:flutter/material.dart';

import 'device_preset.dart';

/// Draws a phone, tablet, Mac window or browser window around [child].
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, required this.device, required this.child});

  final DevicePreset device;
  final Widget child;

  static const _shadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 12)),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = SizedBox(
      width: device.width,
      height: device.height,
      child: child,
    );

    if (device.kind == DeviceKind.phone || device.kind == DeviceKind.tablet) {
      final isPhone = device.kind == DeviceKind.phone;
      final radius = isPhone ? 44.0 : 28.0;
      final bezel = isPhone ? 12.0 : 16.0;
      return Container(
        padding: EdgeInsets.all(bezel),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2430),
          borderRadius: BorderRadius.circular(radius + bezel),
          boxShadow: _shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: screen,
        ),
      );
    }

    final isBrowser = device.kind == DeviceKind.browser;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: device.width,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  for (final color in const [
                    Color(0xFFEF4444),
                    Color(0xFFF59E0B),
                    Color(0xFF10B981),
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
                  const SizedBox(width: 12),
                  if (isBrowser)
                    Expanded(
                      child: Container(
                        height: 26,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Text(
                          'localhost:8080',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Text(
                        'My App',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
