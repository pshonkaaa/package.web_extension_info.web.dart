import 'package:pshondation/library.dart';

abstract class IPatch implements IAsyncStateable {
  // INotifier<ErrorDescription?> get errorState;

  bool get isForExtension;
  
  bool get isForContentScript;
}