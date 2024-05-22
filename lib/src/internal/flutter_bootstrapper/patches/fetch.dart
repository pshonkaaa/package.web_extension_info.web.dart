import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_extension_info/library.dart';
import 'package:web_window_api/library.dart';

import '../bases/base_patch.dart';
import '../utils.dart';

/// Overrides [window.fetch]
/// 
/// Using [fetch], flutter preloads libraries in release mode,
/// loads resources, and executes multiple http requests.
/// 
/// In addition, all network actions with the Dart code use [fetch].
/// That's why we have to influence it
class FetchPatch extends BasePatch {
  late final JSObject _fetch;

  @override
  bool get isForExtension => false;
  
  @override
  bool get isForContentScript => true;

  @override
  Future<void> initState() async {
    super.initState();

    // TODO
    // InvalidAccessError: Failed to set the 'responseType' property on 'XMLHttpRequest': The response type cannot be changed for synchronous requests made from a document.

    executeSync(() {
      _fetch = getProperty(html.window, 'fetch');
      
      
      setProperty(html.window, 'fetch', Proxy(_fetch, ProxyHandler(
        apply: (target, thisArg, arguments) {
          return executeSync(() {
            arguments = arguments.toList();

            final endUri = Uri.parse(arguments[0]);
            // Object? options = arguments.tryElementAt(1);

            // 0 - <anonymous>
            // 1 - executeSync
            // 2 - <anonymous>
            final int skips = ExtensionInfo.contentScript.isLaunchedByExtension() ? 7 : 3;
            final uris = ExtensionInfo.contentScript.getCalculatedCallstack(skips).skipWhile(isDartSdkUri).toList();
            
            // print('caller = $caller');
            // for(int i = 0; i < 5; i++) {
            //   print('caller[$i] = ${ExtensionInfo.contentScript.getCallerUrl(i)}');
            // }

            final uri = uris.first;

            if(endUri.scheme.isEmpty) {
              final String newUrl;

              if(isSameHost(uri)) {
                // Error: Origin is only applicable to schemes http and https: chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js
                // url = '${_hostUri.origin}/$url';

                newUrl = buildUrl(endUri.toString());
              } else {
                newUrl = pageUri.resolveUri(endUri).toString();
              }
                
              logger?.d('$TAG > overriding url.');
              logger?.d('old url = [$endUri]');
              logger?.d('new url = [$newUrl]');
              logger?.d('Callstack: \n' + uris.join('\n'));

              arguments[0] = newUrl;
            }

            // print('fetch $url $options');
            // try {
            //   throw "";
            // } catch(e,s) {
            //   print(s);
            // }

            // TODO .cast<JSAny?>().toJS
            return target.apply(thisArg, arguments);
          }, onError: () {
            // TODO .cast<JSAny?>().toJS
            return target.apply(thisArg, arguments);
          });

        },
      )));
    });
  }

  @override
  Future<void> dispose() async {
    setProperty(html.window, 'fetch', _fetch);

    super.dispose();
  }

}