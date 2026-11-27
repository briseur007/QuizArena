import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'student_home_page.dart';
import 'teacher_home_page.dart';

/// Onglet « Mes cours » : écran 02 (étudiant) ou écran 06 (enseignant).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.select((AuthBloc b) => b.state.user?.isTeacher ?? false);
    return isTeacher ? const TeacherHomePage() : const StudentHomePage();
  }
}
