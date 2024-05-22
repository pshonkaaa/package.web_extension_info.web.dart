import 'dart:html';

import 'package:web_extension_info/library.dart';

/// Uri of current executable script
/// 
/// Could be http(s)://localhost/ or (chrome-)extension://abcdef/
final Uri hostUri = ExtensionInfo.contentScript.getHostUri();
final Uri pageUri = Uri.parse(document.baseUri!);

bool isSameHost(Uri uri) {
  return (uri.host == hostUri.host && uri.port == hostUri.port)
    || isDartSdkUri(uri);
}

bool isDartSdkUri(Uri uri) {
  return uri.toString() == 'dart:sdk_internal';
}

String buildUrl(String path) {
  final String host = '${hostUri.host}' + (hostUri.hasPort ? ':${hostUri.port}' : '');
  return '${hostUri.scheme}://$host/$path';
}