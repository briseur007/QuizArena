import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/di/injector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const QuizArenaApp());
}
