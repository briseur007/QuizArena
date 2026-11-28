# QuizArena — quiz en classe (T17)

> Les enseignants créent des quiz chronométrés ; les étudiants rejoignent un cours avec un code, répondent une fois, et obtiennent leur note instantanément, corrigée par le serveur.

Projet *Advanced Mobile Development — Year 3*. Stack : **Flutter + BLoC** (app) · **Node.js + Express + MongoDB** (API).

## Équipe

| Membre | Rôle(s) |
|---|---|
| _à compléter_ | Team lead · API lead · … |
| _à compléter_ | App lead · Quality lead · … |

## Liens

- API déployée : _à venir (M2)_
- APK release : _à venir (M4)_
- Vidéo démo : _à venir (M4)_

## Le sujet (fiche T17)

- **Acteurs** : enseignant, étudiant.
- **Ressources** : `courses`, `quizzes`, `questions`, `attempts` (+ `users`).
- **Fonctionnalités** : l'enseignant crée des quiz (QCM, minuteur) ; les étudiants rejoignent un cours avec un code ; un seul passage par quiz ; correction automatique côté serveur ; résultats par question et par étudiant ; classement.
- **Règles serveur** : les bonnes réponses ne sont **jamais** envoyées au client avant la soumission ; le minuteur est appliqué **par le serveur** ; une tentative par étudiant sauf autorisation.
- **Fonctionnalité avancée suggérée** : mode quiz en direct (temps réel, WebSocket/SSE).

## Structure

```
api/                 API Node.js (src/, test/, package.json, .env.example)
app/                 App Flutter (lib/, test/, pubspec.yaml)
docs/                design.pdf, report.pdf, slides.pdf, screenshots/
.github/workflows/   CI
```

## Lancer en local

### API

Prérequis : Node.js 24+, et MongoDB (local, ou une base gratuite MongoDB Atlas).

```powershell
cd api
copy .env.example .env    # puis remplir MONGODB_URI et JWT_ACCESS_SECRET (≥ 32 caractères)
npm install
npm run seed              # données de démo + comptes de test (voir plus bas)
npm run dev               # http://localhost:3000/health
npm test                  # tests d'intégration (MongoDB en mémoire, aucune base à installer)
```

`api/requests.http` contient toutes les requêtes, prêtes à envoyer avec l'extension VS Code *REST Client*.

Structure de l'API (une couche par rôle, un module par ressource) :

```
src/
  app.ts, routes.ts      middlewares (helmet, CORS, limite de taille, rate limiting) et table de routage
  config/env.ts          variables d'environnement validées au démarrage (Zod)
  middlewares/           authentification JWT, contrôle de rôle, format d'erreur unique
  modules/
    auth/                users, sessions (refresh tokens hachés, rotation)
    courses/             courses, enrollments (code d'invitation)
    quizzes/             quizzes, questions (brouillon → publication), rapport
    attempts/            attempts : démarrage, minuteur serveur, correction, classement
  seed.ts                données de démonstration
```

Chaque module : `*.model.ts` (Mongoose + index), `*.schemas.ts` (Zod), `*.service.ts` (règles métier et autorisation objet), `*.controller.ts` (HTTP).

### App

```powershell
cd app
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000   # émulateur Android
flutter run -d chrome --web-port 5050 --dart-define=API_URL=http://localhost:3000   # test rapide dans Chrome
flutter test
```

En debug, Android autorise le HTTP non chiffré (`usesCleartextTraffic`, uniquement dans le manifeste `src/debug`) pour joindre l'API locale ; la version release n'accepte que HTTPS. Dans un navigateur large, l'app garde une largeur de téléphone (480 px maximum).

Structure de l'app (Clean Architecture, feature first) :

```
lib/
  core/        thème (couleurs de la maquette Figma), widgets partagés, réseau (Dio,
               rafraîchissement des jetons), stockage, DI (get_it), routeur (go_router)
  features/
    auth/      connexion, inscription, session (AuthBloc), profil et modification des informations
    courses/   écrans 02 et 06, rejoindre/créer un cours, cache hors ligne
    quizzes/   éditeur (07, choix de la bonne réponse), rapport (08), listes de quiz
    attempts/  passage du quiz (03), résultats (04), classement (05)
```

Chaque feature a trois couches : `domain` (entités + contrats, sans Flutter ni Dio), `data` (modèles JSON, sources, implémentations), `presentation` (blocs, pages, widgets).

## Comptes et mots de passe

- **Inscription** : nom (2 caractères minimum), e-mail unique, rôle (étudiant ou enseignant), mot de passe de **8 caractères minimum** (128 maximum), à **retaper** pour confirmation. L'app vérifie la confirmation ; le serveur revérifie la longueur.
- **Stockage** : les mots de passe sont hachés avec **Argon2id**, jamais stockés ni renvoyés en clair. Les refresh tokens sont conservés sous forme d'empreinte SHA-256.
- **Profil → Modifier mes informations** (tous les comptes) : changer son nom et son e-mail (409 si l'e-mail est déjà pris). Le rôle ne peut pas être modifié.
- **Changer de mot de passe** : saisir le mot de passe actuel, puis le nouveau deux fois. Le nouveau doit faire 8 caractères minimum et être différent de l'actuel. Les autres appareils connectés sont déconnectés.
- **Connexion** : on choisit son rôle avant de se connecter ; un compte enseignant ne peut pas se connecter côté étudiant, et inversement. Après trop d'essais, le serveur répond 429.

## Endpoints

Toutes les listes sont paginées : `?page=&limit=` (limite max 50), réponse `{ items, page, limit, total }`. Erreurs : `{ error: { code, message, details? } }`. Authentification : `Authorization: Bearer <accessToken>`.

Codes d'erreur : **401** non connecté, **403** mauvais rôle (ex. un étudiant qui crée un cours), **404** ressource inexistante *ou appartenant à quelqu'un d'autre* (on ne révèle pas son existence), **409** conflit métier (`code` précis dans la réponse), **422** validation (`details` par champ), **429** trop de tentatives de connexion.

| Méthode | Chemin | Rôle | Succès | Erreurs principales |
|---|---|---|---|---|
| GET | /health | public | 200 | — |
| POST | /auth/register | public | 201 `{user, accessToken, refreshToken}` | 409 e-mail pris, 422 |
| POST | /auth/login | public | 200 `{user, accessToken, refreshToken}` | 401, 422, 429 |
| POST | /auth/refresh | public (refresh token) | 200 nouvelle paire (rotation) | 401 |
| POST | /auth/logout | détenteur du refresh token | 204 (révoque la session, idempotent) | 422 |
| GET | /auth/me | connecté | 200 `user` (`id, name, email, role, level`) | 401 |
| PATCH | /auth/me | connecté | 200 `user` (nom et/ou e-mail ; le rôle est ignoré) | 401, 409 `EMAIL_TAKEN`, 422 |
| PATCH | /auth/me/password | connecté | 204 (révoque les autres sessions) | 401, 422 mot de passe actuel incorrect, 429 |
| GET | /courses?q= | étudiant : rejoints · enseignant : créés | 200 page de `Course` (recherche par nom) | 401, 422 |
| POST | /courses | enseignant | 201 `Course` (code généré) | 403, 422 |
| POST | /courses/join | étudiant | 200 `Course` | 404 `COURSE_CODE_UNKNOWN`, 409 `ALREADY_ENROLLED` |
| GET | /courses/:id/quizzes | membre / propriétaire du cours | 200 page de `Quiz` (étudiant : publiés seulement) | 404 |
| POST | /courses/:id/quizzes | enseignant propriétaire | 201 quiz complet (brouillon) | 403, 404, 422 |
| GET | /courses/:id/leaderboard | membre / propriétaire du cours | 200 `{title, participants, entries[]}` cumul du cours | 404 |
| GET | /quizzes?todo=true | étudiant | 200 quiz ouverts encore jouables | 401 |
| GET | /quizzes?status=open\|closed\|draft | enseignant | 200 ses quiz filtrés | 422 |
| GET | /quizzes/:id | enseignant propriétaire | 200 quiz avec `correctIndex` | 403, 404 |
| PATCH | /quizzes/:id | enseignant propriétaire | 200 quiz complet | 403, 404, 409 `QUIZ_PUBLISHED`, 422 |
| POST | /quizzes/:id/publish | enseignant propriétaire | 200 `Quiz` | 404, 409, 422 `QUIZ_INCOMPLETE` |
| POST | /quizzes/:id/close | enseignant propriétaire | 200 `Quiz` (résultats définitifs) | 404, 409 |
| GET | /quizzes/:id/report | enseignant propriétaire | 200 `{questions[], submissions[], average…}` | 403, 404 |
| GET | /quizzes/:id/leaderboard | membre / propriétaire du cours | 200 `{title, participants, entries[]}` (score puis durée, `isMe`) | 404 |
| POST | /quizzes/:id/attempts | étudiant inscrit | 201 tentative **sans les bonnes réponses**, `expiresAt`, `serverTime` · 200 si reprise | 403, 404, 409 `NO_ATTEMPT_LEFT` / `QUIZ_CLOSED` |
| PUT | /attempts/:id/answers | étudiant propriétaire | 204 | 404, 409 `ATTEMPT_EXPIRED` / `ATTEMPT_SUBMITTED`, 422 |
| POST | /attempts/:id/submit | étudiant propriétaire | 200 résultat corrigé | 404, 409 `ATTEMPT_SUBMITTED` |
| GET | /attempts/:id | étudiant propriétaire ou enseignant du cours | 200 résultat + corrections | 404, 409 `ATTEMPT_IN_PROGRESS` |
| GET | /attempts/me/latest | étudiant | 200 dernier résultat | 404 `NO_RESULT` |

**Règles serveur T17** : la bonne réponse n'est jamais renvoyée avant la remise ; le minuteur est appliqué par le serveur (`expiresAt` fixé au démarrage, réponses refusées après, remise tardive corrigée avec les seules réponses enregistrées à temps) ; une tentative par étudiant sauf si `maxAttempts > 1`.

## Comptes de test

Créés par `npm run seed`. Mot de passe de tous les comptes : **`QuizArena2026!`** (données de démonstration uniquement).

| Rôle | E-mail | Contenu |
|---|---|---|
| Enseignant | nikiema@quizarena.bf | cours « Développement mobile » (code `MOBL3A`), quiz ouvert « Flutter & BLoC », brouillon « API & sécurité » |
| Enseignant | traore@quizarena.bf | cours « Bases de données » (code `BDDL3A`), quiz « SQL de base » |
| Étudiante | amina@quizarena.bf | inscrite aux 2 cours, « Flutter & BLoC » **à faire** (pour la démo en direct) |
| Étudiants | fatou@, ibrahim@, moussa@, sarah@quizarena.bf | ont déjà passé « Flutter & BLoC » (classement rempli) |

## Tests

- **API** : `npm test` dans `api/`, 64 tests d'intégration (auth et profil, cours, quiz, tentatives et minuteur, erreurs), sur une base MongoDB en mémoire.
- **App** : `flutter test` dans `app/`, 63 tests (blocs avec bloc_test et mocktail, formulaires, éditeur de quiz, erreurs réseau).
- La CI GitHub Actions lance les deux suites, `flutter analyze` et la vérification du format à chaque push et à chaque pull request.

## Déploiement (A14)

1. **MongoDB Atlas** : créer un cluster gratuit, un utilisateur de base, autoriser l'accès réseau de l'hébergeur, copier l'URI `mongodb+srv://…`.
2. **Hébergeur** (Render, Railway…) : service Node depuis ce dépôt, dossier racine `api`, build `npm ci && npm run build`, démarrage `npm start`.
3. Variables d'environnement : `NODE_ENV=production`, `MONGODB_URI`, `JWT_ACCESS_SECRET` (nouveau secret aléatoire), `TRUST_PROXY=1`.
4. Une fois en ligne : `npm run seed -- --force` avec la `MONGODB_URI` de production (depuis votre poste), puis vérifier `https://<votre-api>/health`.
5. App : `flutter build apk --release --dart-define=API_URL=https://<votre-api>`.

## Limites connues

- Le jeton d'accès reste valide jusqu'à son expiration (15 min) après une déconnexion ; seule la session (refresh token) est révoquée immédiatement.
- Le mode quiz en direct (fonctionnalité avancée) n'est pas encore implémenté.
- L'APK release est encore signé avec la clé de debug.
