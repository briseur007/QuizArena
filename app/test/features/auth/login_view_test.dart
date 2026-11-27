import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/core/theme/app_theme.dart';
import 'package:quiz_arena/features/auth/domain/repositories/auth_repository.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/login_cubit.dart';
import 'package:quiz_arena/features/auth/presentation/pages/login_page.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthRepository repo;
  late MockAuthBloc authBloc;

  setUp(() {
    repo = MockAuthRepository();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthState.unauthenticated());
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider(create: (_) => LoginCubit(repo)),
          ],
          child: const LoginView(),
        ),
      ),
    );
  }

  testWidgets('affiche les textes de la maquette', (tester) async {
    await pump(tester);
    expect(find.text('QuizArena'), findsOneWidget);
    expect(find.text('Étudiant'), findsOneWidget);
    expect(find.text('Enseignant'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('champs vides : erreurs affichées sous les champs', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text("L'adresse e-mail est obligatoire."), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
  });

  testWidgets('connexion réussie : prévient l’AuthBloc', (tester) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Ok(Fx.student));

    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'amina@universite.bf');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(const AuthLoggedIn(Fx.student))).called(1);
  });

  testWidgets('identifiants refusés : message général', (tester) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Err(UnauthorizedFailure()));

    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'amina@universite.bf');
    await tester.enterText(find.byType(TextField).at(1), 'mauvais');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);
  });
}
