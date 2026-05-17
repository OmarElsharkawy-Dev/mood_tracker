import 'package:flutter/material.dart';

abstract final class AppElevation {
  static const e1 = <BoxShadow>[
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const e2 = <BoxShadow>[
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const e3 = <BoxShadow>[
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 4)),
  ];
}
