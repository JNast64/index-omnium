import 'package:flutter_test/flutter_test.dart'; import 'package:flutter/material.dart'; import 'package:index_omnium_ui_grid_2_or_4/app.dart';
void main(){ testWidgets('app builds', (tester) async { await tester.pumpWidget(const IndexOmniumApp()); expect(find.byType(MaterialApp), findsOneWidget); }); }
