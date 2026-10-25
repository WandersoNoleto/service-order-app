import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/client_config.dart';

void main() {
  runApp(ServiceOrderApp(config: ClientConfig.fromEnvironment()));
}
