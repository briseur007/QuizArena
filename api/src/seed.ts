/**
 * Données de démonstration, reprises de la maquette Figma.
 *
 *   npm run seed            (refuse de tourner en production)
 *   npm run seed -- --force (production : efface et recrée TOUT)
 *
 * Tous les comptes ont le mot de passe DEMO_PASSWORD ci-dessous.
 */
import argon2 from 'argon2';
import mongoose, { Types } from 'mongoose';
import { env } from './config/env.js';
import { Attempt } from './modules/attempts/attempt.model.js';
import { User } from './modules/auth/user.model.js';
import { Course } from './modules/courses/course.model.js';
import { Enrollment } from './modules/courses/enrollment.model.js';
import { Question } from './modules/quizzes/question.model.js';
import { Quiz } from './modules/quizzes/quiz.model.js';

const DEMO_PASSWORD = 'QuizArena2026!';

type Q = [text: string, options: [string, string, string, string], correctIndex: number, explanation: string];

const flutterQuestions: Q[] = [
  ['Quel langage utilise Flutter ?', ['Dart', 'JavaScript', 'Kotlin', 'Python'], 0, 'Dart est le langage utilisé pour développer les applications Flutter.'],
  ['Quel est le rôle principal d’un BLoC dans Flutter ?', ['Dessiner les widgets', 'Gérer l’état de l’application', 'Stocker les mots de passe', 'Compiler le projet'], 1, 'Un BLoC transforme des événements en états : il porte la logique et l’état, pas l’affichage.'],
  ['Où stocker les jetons d’accès ?', ['SharedPreferences', 'Stockage sécurisé', 'Une variable globale', 'Le code source'], 1, 'Les jetons doivent rester protégés : Keystore / Keychain via flutter_secure_storage.'],
  ['Quel widget reconstruit l’interface quand l’état d’un bloc change ?', ['BlocBuilder', 'BlocProvider', 'RepositoryProvider', 'MultiBlocListener'], 0, 'BlocBuilder reconstruit ; BlocListener réagit sans reconstruire (SnackBar, navigation).'],
  ['Quel transformer ignore un nouvel événement tant que le précédent est en cours ?', ['sequential', 'concurrent', 'droppable', 'restartable'], 2, 'droppable abandonne les événements reçus pendant le traitement : idéal contre le double appui.'],
  ['Dans la Clean Architecture, quelle couche ne doit importer ni Flutter ni Dio ?', ['presentation', 'data', 'domain', 'core'], 2, 'Le domaine contient les entités et les contrats ; il ne dépend d’aucun framework.'],
  ['À quoi sert get_it ?', ['Naviguer entre les pages', 'Injecter les dépendances', 'Faire des requêtes HTTP', 'Tester les blocs'], 1, 'get_it est un localisateur de services : un point de composition unique pour les dépendances.'],
  ['Quelle commande vérifie le code sans le lancer ?', ['flutter run', 'flutter analyze', 'flutter clean', 'flutter doctor'], 1, 'flutter analyze applique les règles de lint et détecte les erreurs statiques.'],
  ['Comment passer l’URL de l’API à l’application ?', ['En dur dans le code', '--dart-define', 'Dans pubspec.yaml', 'Par un fichier .env commité'], 1, '--dart-define injecte la valeur à la compilation, sans la mettre dans le code source.'],
  ['Que montre un écran pendant le chargement des données ?', ['Rien', 'Un état de chargement distinct', 'Une erreur', 'Les données de démo'], 1, 'Chaque écran distingue chargement, vide, erreur (avec réessai) et contenu.'],
];

const securityQuestions: Q[] = [
  ['Quel algorithme pour hacher un mot de passe ?', ['MD5', 'SHA-1', 'Argon2id', 'Base64'], 2, 'Argon2id est lent et résistant aux GPU ; MD5/SHA-1 sont trop rapides et Base64 n’est pas un hachage.'],
  ['Que faire d’un refresh token déjà utilisé qui revient ?', ['L’accepter', 'Révoquer la session', 'Le prolonger', 'L’ignorer'], 1, 'La réutilisation d’un ancien token signale un vol probable : on révoque toute la session.'],
  ['Quel code HTTP pour des données invalides ?', ['200', '401', '422', '500'], 2, '422 Unprocessable Entity, avec le détail des erreurs par champ.'],
  ['Le contrôle « ce quiz est-il le mien ? » s’appelle…', ['Authentification', 'Autorisation objet', 'Chiffrement', 'Validation'], 1, 'L’autorisation au niveau de l’objet (OWASP API1) vérifie chaque ressource demandée.'],
  ['Où mettre les secrets de l’API ?', ['Dans Git', 'Variables d’environnement', 'Dans le README', 'Dans l’app mobile'], 1, 'Jamais dans le dépôt : variables d’environnement validées au démarrage.'],
  ['À quoi sert le rate limiting sur /auth ?', ['Accélérer l’API', 'Freiner les essais de mots de passe', 'Compresser les réponses', 'Mettre en cache'], 1, 'Il limite les attaques par force brute sur la connexion.'],
  ['', ['', '', '', ''], 0, ''],
  ['', ['', '', '', ''], 0, ''],
];

const sqlQuestions: Q[] = [
  ['Quelle commande lit des lignes ?', ['SELECT', 'INSERT', 'DELETE', 'DROP'], 0, 'SELECT lit ; INSERT ajoute ; DELETE supprime des lignes ; DROP supprime la table.'],
  ['Quelle clause filtre les lignes ?', ['ORDER BY', 'WHERE', 'GROUP BY', 'LIMIT'], 1, 'WHERE filtre avant le regroupement ; HAVING filtre après.'],
  ['Une clé primaire est…', ['Facultative', 'Unique et non nulle', 'Toujours un texte', 'Partagée entre tables'], 1, 'Elle identifie chaque ligne de façon unique.'],
  ['Quel index accélère une recherche par e-mail ?', ['Aucun', 'Un index sur email', 'Un index sur id', 'Un trigger'], 1, 'On indexe les champs sur lesquels on filtre.'],
  ['Que fait COUNT(*) ?', ['Additionne', 'Compte les lignes', 'Trie', 'Supprime les doublons'], 1, 'COUNT(*) renvoie le nombre de lignes.'],
];

async function main() {
  if (env.NODE_ENV === 'production' && !process.argv.includes('--force')) {
    console.error('Refusé en production. Relance avec --force si tu veux vraiment tout effacer.');
    process.exit(1);
  }

  await mongoose.connect(env.MONGODB_URI);
  await mongoose.connection.syncIndexes();
  // On vide chaque collection (dropDatabase demanderait des droits d'admin sur Atlas).
  for (const collection of await mongoose.connection.db!.collections()) await collection.deleteMany({});

  const passwordHash = await argon2.hash(DEMO_PASSWORD, { type: argon2.argon2id });
  const user = (name: string, email: string, role: 'student' | 'teacher') => User.create({ name, email, role, passwordHash });

  const nikiema = await user('Dr Nikiema', 'nikiema@quizarena.bf', 'teacher');
  const traore = await user('Mme Traoré', 'traore@quizarena.bf', 'teacher');
  const amina = await user('Amina Ouédraogo', 'amina@quizarena.bf', 'student');
  const fatou = await user('Fatou Ouédraogo', 'fatou@quizarena.bf', 'student');
  const ibrahim = await user('Ibrahim Traoré', 'ibrahim@quizarena.bf', 'student');
  const moussa = await user('Moussa Diallo', 'moussa@quizarena.bf', 'student');
  const sarah = await user('Sarah Kaboré', 'sarah@quizarena.bf', 'student');
  const students = [amina, fatou, ibrahim, moussa, sarah];

  const mobile = await Course.create({ name: 'Développement mobile', level: 'L3', teacherId: nikiema._id, code: 'MOBL3A' });
  const bdd = await Course.create({ name: 'Bases de données', level: 'L3', teacherId: traore._id, code: 'BDDL3A' });
  await Enrollment.insertMany(students.flatMap((s) => [mobile, bdd].map((c) => ({ courseId: c._id, studentId: s._id }))));

  async function quiz(courseId: Types.ObjectId, teacherId: Types.ObjectId, title: string, questions: Q[], status: 'draft' | 'open', durationMinutes = 10) {
    const q = await Quiz.create({
      courseId,
      teacherId,
      title,
      durationMinutes,
      maxAttempts: 1,
      status,
      questionCount: questions.length,
      ...(status === 'open' ? { publishedAt: new Date() } : {}),
    });
    const docs = await Question.insertMany(
      questions.map(([text, options, correctIndex, explanation], order) => ({
        quizId: q._id,
        order,
        text,
        options,
        correctIndex: text ? correctIndex : null,
        explanation,
      })),
    );
    return { quiz: q, questions: docs };
  }

  const flutter = await quiz(mobile._id, nikiema._id, 'Flutter & BLoC', flutterQuestions, 'open');
  await quiz(mobile._id, nikiema._id, 'API & sécurité', securityQuestions, 'draft', 15);
  const sql = await quiz(bdd._id, traore._id, 'SQL de base', sqlQuestions, 'open', 5);

  /** Remise terminée : les [score] premières réponses justes, les autres fausses. */
  async function submitted(
    target: Awaited<ReturnType<typeof quiz>>,
    student: typeof amina,
    score: number,
    seconds: number,
    daysAgo: number,
  ) {
    const startedAt = new Date(Date.now() - daysAgo * 86_400_000);
    const submittedAt = new Date(startedAt.getTime() + seconds * 1000);
    await Attempt.create({
      quizId: target.quiz._id,
      courseId: target.quiz.courseId,
      studentId: student._id,
      attemptNumber: 1,
      status: 'submitted',
      startedAt,
      expiresAt: new Date(startedAt.getTime() + target.quiz.durationMinutes * 60_000),
      submittedAt,
      answers: target.questions.map((q, i) => ({
        questionId: q._id,
        optionIndex: i < score ? (q.correctIndex ?? 0) : ((q.correctIndex ?? 0) + 1) % 4,
        answeredAt: submittedAt,
      })),
      score,
      total: target.questions.length,
      durationSeconds: seconds,
    });
  }

  // Classement de la maquette (Amina garde « Flutter & BLoC » à faire pour la démo en direct).
  await submitted(flutter, fatou, 10, 342, 1);
  await submitted(flutter, ibrahim, 9, 375, 1);
  await submitted(flutter, moussa, 8, 483, 1);
  await submitted(flutter, sarah, 7, 504, 1);
  await submitted(sql, amina, 4, 250, 2);
  await submitted(sql, fatou, 5, 210, 2);

  console.log(`Base remplie. Mot de passe de tous les comptes : ${DEMO_PASSWORD}`);
  console.log('Enseignants : nikiema@quizarena.bf, traore@quizarena.bf');
  console.log('Étudiants   : amina@, fatou@, ibrahim@, moussa@, sarah@quizarena.bf');
  console.log('Codes de cours : MOBL3A (Développement mobile), BDDL3A (Bases de données)');
  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error(err);
  await mongoose.disconnect();
  process.exit(1);
});
