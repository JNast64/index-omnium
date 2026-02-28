import 'package:flutter/material.dart';
import 'router.dart';
import 'theme/theme.dart';
class IndexOmniumApp extends StatelessWidget{ const IndexOmniumApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp.router(title:'Index Omnium', theme: buildLightTheme(), darkTheme: buildDarkTheme(), themeMode: ThemeMode.system, routerConfig: createRouter()); }
