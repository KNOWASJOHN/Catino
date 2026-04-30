import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const SystemUiOverlayStyle catinoSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarContrastEnforced: false,
);

Future<void> configureSystemUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(catinoSystemUiOverlayStyle);
}
