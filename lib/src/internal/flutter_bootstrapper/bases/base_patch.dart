import 'dart:async';

import 'package:logger/logger.dart';
import 'package:pshondation/library.dart';

import '../interfaces/patch.dart';

typedef _Runnable<T> = FutureOr<T> Function();

abstract class BasePatch extends BaseAsyncStateable implements IPatch {
  late final String TAG = (runtimeType).toString();
  // @override
  // final Notifier<ErrorDescription?> errorState = Notifier(value: null);
  @override
  bool get isForExtension;
  
  @override
  bool get isForContentScript;

  Logger? logger;

  // FutureOr<T> execute<T>(
  //   _Runnable<T> runnable, {
  //     required _Runnable<T> onError,
  // }) {
    
  // }

  @override
  Future<void> initState() async {
    super.initState();

    logger?.d('$TAG > initState()');
  }

  @override
  Future<void> dispose() async {
    logger?.d('$TAG > dispose()');
    // errorState.clear();
    
    super.dispose();
  }

  T executeSync<T>(
    _Runnable<T> runnable, {
      _Runnable<T>? onError,
  }) {
    try {
      return runnable() as T;
    } catch(e) {
      dispose();
      // _handleError(e, s);
      rethrow;
      // return onError() as T;
    }
  }

  // void _handleError(Object error, StackTrace stackTrace) {
  //   errorState.value = ErrorDescription(
  //     error: error,
  //     stackTrace: stackTrace,
  //   );

  //   dispose();
  // }
}