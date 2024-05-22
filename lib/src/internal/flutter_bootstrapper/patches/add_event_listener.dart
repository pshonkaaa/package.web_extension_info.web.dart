import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_extension_info/library.dart';
import 'package:web_window_api/library.dart';

import '../bases/base_patch.dart';
import '../utils.dart';

/// Overrides [window.addEventListener]
/// 
/// Patches flutter's popstate listener,
/// it is triggered when the 'Back' button is pressed
class AddEventListenerPatch extends BasePatch {
  late final JSObject _addEventListener;

  @override
  bool get isForExtension => false;
  
  @override
  bool get isForContentScript => true;

  @override
  Future<void> initState() async {
    super.initState();

    executeSync(() {
      _addEventListener = getProperty(html.window, 'addEventListener');
      
      setProperty(html.window, 'addEventListener', Proxy(_addEventListener, ProxyHandler(
        apply: (target, thisArg, arguments) {
          return executeSync(() {
            arguments = arguments.toList();
            final String type = arguments.first;

            
            final uris = ExtensionInfo.contentScript.getCalculatedCallstack();
            // print('type = $type');
            // // print('caller = $caller');
            // for(int i = 0; i < callers.length; i++) {
            //   print('caller[$i] = ${callers[i]}');
            // }

            final uri = uris[1];

            if(type == 'popstate') {
              if(isSameHost(uri)) {
                logger?.d('$TAG > canceling the [$type] event.');
                logger?.d('Callstack: \n' + uris.join('\n'));
                
                return null;
              }
            }

            // print('fetch $url $options');
            // try {
            //   throw "";
            // } catch(e,s) {
            //   print(s);
            // }
            return target.apply(thisArg, arguments);
          }, onError: () {
            return target.apply(thisArg, arguments);
          });

        },
      )));
    });
  }

  @override
  Future<void> dispose() async {
    setProperty(html.window, 'addEventListener', _addEventListener);

    super.dispose();
  }

}