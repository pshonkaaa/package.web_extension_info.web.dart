import 'package:web/web.dart' as html;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_chrome_api/library.dart';
import 'package:web_window_api/library.dart';

import '../bases/base_patch.dart';

/// Creates [window] for extension's background script
/// 
/// Patches WidgetsFlutterBinding.ensureInitialized()
/// which uses [window]
/// 
/// self.window.navigator
/// self.document.documentElement.computedStyleMap()..get('font-size')
class WindowPatch extends BasePatch {
  late final JSObject _addEventListener;

  @override
  bool get isForExtension => true;
  
  @override
  bool get isForContentScript => false;

  @override
  Future<void> initState() async {
    super.initState();

    executeSync(() {
      setProperty(jsSelf, 'window', Proxy(newObject(), ProxyHandler(
        apply: (target, thisArg, arguments) {
          // print('hallow');
          // if(target == 'addEventListener') {
          //   return getProperty(jsSelf, 'addEventListener');

          // }
          
          
          // return null;
        },
        get: (target, property, receiver) {
          if(property == 'navigator') {
            return getProperty(jsSelf, 'navigator');

          } else if(property == 'matchMedia') {
            return _g_matchMedia();

          } else if(property == 'addEventListener') {
            return allowInterop((JSAny? a1, JSAny? a2) {
              return getProperty<JSFunction>(jsSelf, 'addEventListener').apply(jsSelf, [a1, a2]);
            });

          }
          
          return null;
        },
      )));
      
      setProperty(jsSelf, 'MutationObserver', Proxy(allowInterop((_) {}) as JSObject, ProxyHandler(
        construct: (target, arguments, newTarget) {
          final jsObject = newObject();
          setProperty(jsObject, 'observe', allowInterop((_1, _2) {}));
          
          return jsObject;
        },
      )));
      
      setProperty(jsSelf, 'document', Proxy(newObject(), ProxyHandler(
        get: (target, property, receiver) {
          if(property == 'documentElement') {
            return _g_documentElement();

          }
          
          return null;
        },
      )));
    });
  }

  // Object _g_languagechange() {
  //   final jsObject = newObject();
    
  //   setProperty(jsObject, 'addEventListener', value)

  //   return jsObject;
  // }

  Object _g_matchMedia() {
    return allowInterop((String value) {
      if(value == '(forced-colors: active)') {
        // MediaQueryList
        final jsValue = newObject();
        setProperty(jsValue, 'matches', false);
        setProperty(jsValue, 'addListener', allowInterop((_) {}));
        return jsValue;

        
      } else if(value == '(prefers-color-scheme: dark)') {
        // MediaQueryList
        final jsValue = newObject();
        setProperty(jsValue, 'matches', false);
        setProperty(jsValue, 'addListener', allowInterop((_) {}));
        return jsValue;
      }
      
      throw 'unreachable';
    });
  }

  JSObject _g_documentElement() {
    final jsElement = newObject();

    setProperty(jsElement, 'computedStyleMap', allowInterop(() {
      final jsComputedStyleMap = newObject();

      setProperty(jsComputedStyleMap, 'get', allowInterop((String name) {
        if(name == 'font-size') {
          // CSSUnitValue
          final jsValue = newObject();
          setProperty(jsValue, 'unit', 'px');
          setProperty(jsValue, 'value', 16);
          return jsValue;
        }
          
        throw 'unreachable';
      }));

      return jsComputedStyleMap;
    }));
    
    return jsElement;
  }

  @override
  Future<void> dispose() async {
    setProperty(html.window, 'addEventListener', _addEventListener);

    super.dispose();
  }

}