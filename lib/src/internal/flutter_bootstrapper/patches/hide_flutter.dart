import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_chrome_api/library.dart';
import 'package:web_window_api/library.dart';

import '../bases/base_patch.dart';

/// Hides flutter's variables
/// 
class HideFlutterPatch extends BasePatch {
  late final Map<String, dynamic> _cache;
  late final JSObject _jsPrototype;

  @override
  bool get isForExtension => false;
  
  @override
  bool get isForContentScript => true;


  @override
  Future<void> initState() async {
    super.initState();

    executeSync(() {
      _cache = {};
      
      final jsFunction = getProperty(jsSelf, 'Function');
      _jsPrototype = getProperty(jsFunction, 'prototype');

      final keys = objectKeys(_jsPrototype).cast<String>();

      final neededKeys = keys.where((e) => e.startsWith(r'$') || e.startsWith(r'call$')).toList();

      logger?.d('$TAG > overriding next keys:');
      logger?.d(neededKeys.join(', '));
      
      for(final key in neededKeys) {
        _cache[key] = getProperty(_jsPrototype, key);

        defineProperty(_jsPrototype, key, JSObjectDescriptor(
          get: () {
            return _cache[key];
          },
          set: (value) {
            _cache[key] = value;
          },
          enumerable: false,
        ));
      }
    });
  }

  @override
  Future<void> dispose() async {
    // TODO

    super.dispose();
  }

}