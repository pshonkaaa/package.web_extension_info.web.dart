import 'package:web/web.dart' as html;

import 'package:logger/logger.dart';

import '../internal/flutter_bootstrapper/bootstrapper_impl.dart';


abstract class WebFlutterBootsrapper {
  static final WebFlutterBootsrapper instance = WebFlutterBootsrapperImpl();

  Logger? logger;

  html.Element get rootElement;

  Future<void> bootstrap();
}