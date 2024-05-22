import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:js_util';

import 'package:logger/logger.dart';
import 'package:web_chrome_api/library.dart';
import 'package:web_extension_info/library.dart';

import 'bases/base_patch.dart';
import 'patches/add_event_listener.dart';
import 'patches/fetch.dart';
import 'patches/hide_flutter.dart';
import 'patches/trusted_types.dart';
import 'patches/window.dart';

class WebFlutterBootsrapperImpl implements WebFlutterBootsrapper {
  @override
  Logger? logger;

  @override
  late final html.Element rootElement;

  static final List<BasePatch> _patches = [
    AddEventListenerPatch(),
    FetchPatch(),
    HideFlutterPatch(),
    TrustedTypesPatch(),
    WindowPatch(),
  ];
  
  // static final Notifier<ErrorDescription?> errorState = Notifier(value: null);

  static bool get _isExtension => chrome.runtime?.id != null;

  static bool get _isContentScript => !_isExtension;

  static late bool _engineInitialized;

  @override
  Future<void> bootstrap() async {
    // if(errorState.length == 0)
    //   throw 'You should listen bootstrapper for errors. WebFlutterBootsrapper.errorState.bind()';
      
    if(ExtensionInfo.contentScript.isLaunchedByExtension()) {
      _engineInitialized = false;
    } else {
      _engineInitialized = true;
    }

    // TODO engineInitializer.initializeEngine

    final neededPatches = _patches.where((e) => _isExtension ? e.isForExtension : e.isForContentScript).toList();

    for(final patch in neededPatches) {
      patch.logger = logger;
      // patch.errorState.bind(_handleError);
      await patch.initState();
    }

    if(ExtensionInfo.contentScript.isLaunchedByExtension()) {
      rootElement = _createDomElementForFlutterEngine();
      
    } else {
      rootElement = html.document.body!;
    }
    

    if(!_engineInitialized ) {
      if(_isContentScript) {
        _engineInitialized = true;
        
        // ignore: undefined_function
        await ui.webOnlyInitializePlatform();
      }
    }
  }

  static html.Element _createDomElementForFlutterEngine() {
    html.Element? root = html.document.querySelector('.flutter_view');
    bool exists = root != null;

    if(!exists) {
      root = html.document.createElement('div');

      root.className = 'flutter_view';
      
      root.style.position = 'fixed';
      root.style.width = '100%';
      root.style.height = '100%';
      root.style.top = '0';
      root.style.left = '0';
      root.style.zIndex = '99999';
      root.style.pointerEvents = 'none';

      html.document.body!.append(root);

      setProperty(html.window, 'flutterConfiguration', jsify({
        'hostElement': root,
      }));
    }

    return root;
  }

  // static void _handleError(ErrorDescription? errorDescription) {
  //   for(final patch in _patches) {
  //     if(patch.disposed)
  //       continue;
      
  //     patch.dispose();
  //   }

  //   // errorState.value = errorDescription;
  // }
}