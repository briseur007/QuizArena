import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/theme/app_theme.dart';
import 'package:quiz_arena/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:quiz_arena/features/quizzes/presentation/bloc/quiz_editor_bloc.dart';
import 'package:quiz_arena/features/quizzes/presentation/pages/quiz_editor_page.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

/// Régression : l'enseignant doit pouvoir désigner la bonne réponse,
/// et l'écran doit l'afficher.
void main() {
  late QuizEditorBloc bloc;

  // Bloc créé hors du temps simulé de testWidgets : il est prêt (« ready »)
  // avant le premier affichage. Ses traitements tournent donc en temps réel,
  // d'où le `settle` ci-dessous après chaque action.
  setUp(() {
    bloc = QuizEditorBloc(MockQuizRepository())
      ..add(const EditorStarted(courseId: 'c1', courseName: 'Développement mobile'));
  });

  tearDown(() => bloc.close());

  /// Laisse le bloc traiter l'événement (temps réel), puis redessine.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider.value(value: bloc, child: const QuizEditorView()),
      ),
    );
    await settle(tester);
  }

  testWidgets('toucher le rond désigne la bonne réponse et l’affiche', (tester) async {
    await pump(tester);
    expect(bloc.state.current.correctIndex, isNull);

    await tester.tap(find.byTooltip('Choisir B comme bonne réponse'));
    await settle(tester);

    expect(bloc.state.current.correctIndex, 1);
    expect(find.byTooltip('Bonne réponse'), findsOneWidget);
    expect(find.byTooltip('Choisir B comme bonne réponse'), findsNothing);
  });

  testWidgets('toucher la lettre désigne aussi la bonne réponse', (tester) async {
    await pump(tester);

    await tester.tap(find.text('D'));
    await settle(tester);

    expect(bloc.state.current.correctIndex, 3);
    expect(find.byTooltip('Bonne réponse'), findsOneWidget);
  });
}
