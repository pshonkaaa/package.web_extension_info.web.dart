import 'package:logger/logger.dart';
import 'package:pshondation/library.dart';
import 'package:web_chrome_api/library.dart';
import 'package:web_communication/library.dart';

abstract class ExtensionInfo implements IPrettyPrint {
  static const CHANNEL = "package://extension_info";
  static final PACKETS = [
    _GetExtensionInfoPacket.create(),
    _PostExtensionInfoPacket.create(),
  ];

  static Logger? logger;

  static final background = _ExtensionInfoBackground();
  static final contentScript = _ExtensionInfoContentScript();

  String get id;
  String get name;
  String get description;
  // Map<Object, StackTrace> get errors;
}

class _ExtensionInfo extends ExtensionInfo {
  final String id;
  final String name;
  final String description;
  _ExtensionInfo({
    required this.id,
    required this.name,
    required this.description,
  });
  
  @override
  PrettyPrint toPrettyPrint() {
    final pp = PrettyPrint(title: this);
    pp.add('id', id);
    pp.add('name', name);
    pp.add('description', description);
    return pp;
  }

  @override
  String toString()
    => toPrettyPrint().generate();
}

class _GetExtensionInfoPacket extends Packet {
  _GetExtensionInfoPacket();
  _GetExtensionInfoPacket.create();

  @override
  Object? build() {
    return null;
  }
  
  @override
  Packet parse(Object? data) {
    return _GetExtensionInfoPacket(
      
    );
  }

}

class _PostExtensionInfoPacket extends Packet {
  late String id;
  late String name;
  late String description;
  _PostExtensionInfoPacket({
    required this.id,
    required this.name,
    required this.description,
  });
  _PostExtensionInfoPacket.create();
  

  @override
  Object? build() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
  
  @override
  Packet parse(covariant Map data) {
    data = data.cast<String, Object?>();
    return _PostExtensionInfoPacket(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }
}

class _ExtensionInfoBackground {
  final ServerCommunicator communicator = Communicator.server(
    handshake: ExtensionInfo.CHANNEL,
    packets: ExtensionInfo.PACKETS,
  );
  _ExtensionInfoBackground();
  
  Future<void> initialize() async {
    communicator.logger = ExtensionInfo.logger;
    await communicator.open();
    communicator.onReceive((socket, packet) {
      if(packet is _GetExtensionInfoPacket) {
        final manifest = chrome.runtime!.getManifest();

        final response = _PostExtensionInfoPacket(
          id: chrome.runtime!.id,
          name: manifest.name ?? '',
          description: manifest.description ?? '',
        );

        socket.send(
          response,
          responseTo: packet,
        );
      }

    });
  }
}



enum EScriptInjectionType {
  extension,
  url,
}

class _ExtensionInfoContentScript {
  static final String EXCEPTION_IDENTIFIER = 'TEST_EXCEPTION_FOR_STACK_IDENTIFICTION';

  final Map<String, ClientCommunicator> _communicators = {};

  final Map<String, _ExtensionInfo> _cache = {};

  Future<ExtensionInfo?> get({
    String? id,
  }) async {
    id = id ?? getCurrentExtensionId();

    if(id == null)
      return null;

    if(_cache.containsKey(id)) {
      return _cache[id]!;
    }

    final ClientCommunicator communicator;
    if(!_communicators.containsKey(id)) {
      communicator = Communicator.client(
        handshake: ExtensionInfo.CHANNEL,
        extensionId: id,
        packets: ExtensionInfo.PACKETS,
      );
      communicator.logger = ExtensionInfo.logger;
      _communicators[id] = communicator;
      await communicator.connect();
    } else {
      communicator = _communicators[id]!;
      await communicator.connect();
    }
    
    final packet = await communicator.sendWithResponse<_PostExtensionInfoPacket>(_GetExtensionInfoPacket());
    packet!;
    await communicator.close();

    final info = _ExtensionInfo(
      id: packet.id,
      name: packet.name ,
      description: packet.description,
    );
    return _cache[id] = info;
  }

  late final EScriptInjectionType _injectionType = _determineScriptInjectionype();
  late final bool _isLaunchedByExtension = _injectionType == EScriptInjectionType.extension;

  EScriptInjectionType _determineScriptInjectionype() {
    try {
      throw EXCEPTION_IDENTIFIER;
    } catch(_, stackTrace) {
      final lines =  _getStackTraceLines(stackTrace);

      final EScriptInjectionType injectionType;
      if(lines.first.startsWith('dart:sdk_internal')) {
        injectionType = EScriptInjectionType.url;
      } else {
        injectionType = EScriptInjectionType.extension;
      }
      
      return injectionType;
    }
  }

  /// Means, launched script by extension - (chrome-)extension://*/
  /// 
  /// or injected by url - http(s)://*/
  bool isLaunchedByExtension()
    => _isLaunchedByExtension;

  /// Means, launched script by extension - (chrome-)extension://*/
  /// 
  /// or injected by url - http(s)://*/
  EScriptInjectionType getScriptInjectionType()
    => _injectionType;
  
  String? getCurrentExtensionId() {
    // Skipping current function
    return getCalculatedCallstack(1).first.host;
  }
  
  Uri getHostUri() {
    // Skipping current function
    return getCalculatedCallstack(1).first;
  }

  List<Uri> getCalculatedCallstack([int index = 0]) {
    try {
      throw EXCEPTION_IDENTIFIER;
    } catch(_, stackTrace) {
      int toSkip = index;
      switch(_injectionType) {
        // TEST_EXCEPTION_FOR_STACK_IDENTIFICTION
        //   at Object.wrapException (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:14097:43)
        //   at _ExtensionInfoContentScript.getCalculatedCallstack$1 (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:187129:17)
        case EScriptInjectionType.extension:
          toSkip += 2;
          break;

        // dart:sdk_internal 5402:11                                                                              throw_
        // http://localhost:4444/packages/vk_music_ex/libs/common/ExtensionInfo/ExtensionInfo.dart.lib.js 430:19  getCalculatedCallstack
        case EScriptInjectionType.url:
          toSkip += 2;
          break;
      }
      
      return extractCallstack(
        stackTrace: stackTrace,
        injectionType: _injectionType,
      ).skip(toSkip).map((e) => e.uri).toList();
    }
  }

  List<Uri> getRawCallstack() {
    try {
      throw EXCEPTION_IDENTIFIER;
    } catch(_, stackTrace) {
      return extractCallstack(
        stackTrace: stackTrace,
        injectionType: _injectionType,
      ).map((e) => e.uri).toList();
    }
  }

  List<StackCall> extractCallstack({
    required StackTrace stackTrace,
    required EScriptInjectionType injectionType,
  }) {
    // [EScriptInjectionType.url]
    // dart:sdk_internal 5402:11                                                                              throw_
    // http://localhost:4444/packages/vk_music_ex/libs/common/ExtensionInfo/ExtensionInfo.dart.lib.js 368:19  [_determineContentScriptType]
    // http://localhost:4444/packages/vk_music_ex/libs/common/ExtensionInfo/ExtensionInfo.dart.lib.js 364:72  get [_isExtension]
    // http://localhost:4444/packages/vk_music_ex/libs/common/ExtensionInfo/ExtensionInfo.dart.lib.js 380:18  isExtension
    // ...

    // [EScriptInjectionType.extension]
    // TEST_EXCEPTION_FOR_STACK_IDENTIFICTION
    //    at Object.wrapException (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:14097:43)
    //    at _ExtensionInfoContentScript._determineContentScriptType$0 (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:187064:17)
    //    at _ExtensionInfoContentScript.get$_isExtension (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:187055:20)
    //    at _ExtensionInfoContentScript.isExtension$0 (chrome-extension://nnlpboghmdkieffjfjojojnbhdfgmnjd/injected.dart.js:187072:19)
    // ...

    try {
      final lines =  _getStackTraceLines(stackTrace);

      final List<StackCall> parsedStack = [];
      
      if(injectionType == EScriptInjectionType.url) {
        // 1 - file, 2 - column, 3 - function
        final regex = RegExp(r'(.*?)[\s]*?(\d{1,}:\d{1,})[\s]*(\S.*)');

        parsedStack.addAll(lines.map((e) {
          final match = regex.firstMatch(e)!;
          return StackCall(
            uri: Uri.parse(match.group(1)!),
            function: match.group(3) ?? '',
            column: match.group(2)!,
          );
        }));
      } else if(injectionType == EScriptInjectionType.extension) {
        // 2 - file, 3 - column, 1 - function
        // NOTE: sometimes the function is missing
        final regex = RegExp(r'^\s*at\s*(.*)?\s+\(?(S+|\S+)?:(\d+:\d+)\)?');
        final atRegex = RegExp(r'^[\s]*?at');

        // Skipping StackTrace header until [...at]
        final sublines = lines.skipWhile((line) => !atRegex.hasMatch(line));

        parsedStack.addAll(sublines.map((e) {
          final match = regex.firstMatch(e)!;
          return StackCall(
            uri: Uri.parse(match.group(2)!),
            function: match.group(1) ?? '',
            column: match.group(3)!,
          );
        }));
      } else {
        throw 'Unknown injectionType';
      }
      
      return parsedStack;
    } catch(e) {
      print(stackTrace);
      throw 'unknown stacktrace';
    }
  }

  List<String> _getStackTraceLines(StackTrace stackTrace) {
    return stackTrace.toString().split('\n')..removeWhere((e) => e == '');
  }
}

class StackCall {
  final Uri uri;
  final String function;
  final String column;
  StackCall({
    required this.uri,
    required this.function,
    required this.column,
  });
}