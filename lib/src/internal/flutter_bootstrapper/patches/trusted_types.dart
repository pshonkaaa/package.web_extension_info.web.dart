import 'package:web/web.dart' as html;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_window_api/library.dart';

import '../bases/base_patch.dart';
import '../utils.dart';

/// Overrides [window.trustedTypes.createPolicy]
/// 
/// Using [createPolicy], flutter creates a URL for canvaskit.js.
/// And then inject canvaskit using the [script] tag,
/// so we can't affect the loading
class TrustedTypesPatch extends BasePatch {
  late final JSObject _trustedTypes;

  late final JSObject _createPolicy;

  @override
  bool get isForExtension => false;
  
  @override
  bool get isForContentScript => true;

  @override
  Future<void> initState() async {
    super.initState();

    executeSync(() {
      _trustedTypes = getProperty(html.window, 'trustedTypes');

      _createPolicy = getProperty(_trustedTypes, 'createPolicy');

      
      setProperty(_trustedTypes, 'createPolicy', Proxy(_createPolicy, ProxyHandler(
        apply: (target, thisArg, arguments) {
          return executeSync(() {
            final String name = arguments[0];
            final JSObject options = arguments[1]; 
            
            if(name == 'flutter-engine') {
              logger?.d('$TAG > overriding createPolicy. name = [$name]');
              
              final createScriptURL = getProperty(options, 'createScriptURL');
              setProperty(options, 'createScriptURL', allowInterop((String url) {
                final newUrl = buildUrl(url);

                logger?.d('$TAG > overriding url.');
                logger?.d('old url = $url');
                logger?.d('new url = $newUrl');

                return createScriptURL(newUrl);
              }));
            }
            
            // TODO .cast<JSAny?>().toJS
            return target.apply(thisArg, arguments);
          }, onError: () {
            return target.apply(thisArg, arguments);
          });
      })));
    });
  }

  @override
  Future<void> dispose() async {
    setProperty(_trustedTypes, 'createPolicy', _createPolicy);

    super.dispose();
  }

}