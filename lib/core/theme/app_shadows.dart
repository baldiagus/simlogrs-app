import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.04),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.02),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> heroCard = [
    BoxShadow(
      color: Color.fromRGBO(91, 80, 230, 0.22),
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> floatingNav = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];
}
