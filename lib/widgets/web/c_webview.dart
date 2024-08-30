// import 'package:dailyanimelist/main.dart';
// import 'package:flutter/material.dart';

import 'dart:io';

import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs_lite.dart' as cc;
import 'package:flutter_custom_tabs/flutter_custom_tabs_lite.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<void> launchWebView(String url, {BuildContext? context}) async {
  try {
    if (!kIsWeb && Platform.isAndroid) {
      await _openInWebView(context, url);
    } else {
      await url_launcher.launchUrl(Uri.parse(url));
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}

Future<void> _openInWebView(BuildContext? context, String url) async {
  Color? barColor;
  Color? onBarColor;
  if (context != null) {
    final theme = Theme.of(context);
    barColor = theme.colorScheme.surface;
    onBarColor = theme.colorScheme.onSurface;
  }
  try {
    await cc.launchUrl(
      Uri.parse(url),
      options: LaunchOptions(
        barColor: barColor,
        onBarColor: onBarColor,
        barFixingEnabled: false,
      ),
    );
  } catch (e) {
    logDal(e.toString());
    showToast(S.current.No_Connection);
  }
}
