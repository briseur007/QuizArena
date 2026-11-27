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

```powershell
cd api
copy .env.example .env    # puis remplir MONGODB_URI et JWT_ACCESS_SECRET
npm install
npm run dev               # http://localhost:3000/health
npm test
```

### App

```powershell
cd app
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000   # émulateur Android
flutter test
```

Structure de l'app (Clean Architecture, feature first) :

```
lib/
  core/        thème (couleurs de la maquette Figma), widgets partagés, réseau (Dio,
               rafraîchissement des jetons), stockage, DI (get_it), routeur (go_router)
  features/
    auth/      connexion, inscription, session (AuthBloc), profil
    courses/   écrans 02 et 06, rejoindre/créer un cours, cache hors ligne
    quizzes/   éditeur (07), rapport (08), listes de quiz
    attempts/  passage du quiz (03), résultats (04), classement (05)
```

Chaque feature a trois couches : `domain` (entités + contrats, sans Flutter ni Dio), `data` (modèles JSON, sources, implémentations), `presentation` (blocs, pages, widgets).

## Endpoints

Contrat attendu par l'app Flutter (`app/lib/features/*/data/datasources`). Toutes les listes sont paginées : `?page=&limit=` (limite max 50), réponse `{ items, page, limit, total }`. Erreurs : `{ error: { code, message, details? } }`.

| Méthode | Chemin | Rôle | Succès | Erreurs principales |
|---|---|---|---|---|
| GET | /health | public | 200 | — |
| POST | /auth/register | public | 201 `{user, accessToken, refreshToken}` | 409 e-mail pris, 422 |
| POST | /auth/login | public | 200 `{user, accessToken, refreshToken}` | 401, 422, 429 |
| POST | /auth/refresh | public (refresh token) | 200 nouvelle paire (rotation) | 401 |
| POST | /auth/logout | connecté | 204 (révoque la session) | 401 |
| GET | /auth/me | connecté | 200 `user` (`id, name, email, role, level`) | 401 |
| GET | /courses | étudiant : rejoints · enseignant : créés | 200 page de `Course` | 401 |
| POST | /courses | enseignant | 201 `Course` (code généré) | 403, 422 |
| POST | /courses/join | étudiant | 200 `Course` | 404 code inconnu, 409 déjà inscrit |
| GET | /courses/:id/quizzes | membre / propriétaire du cours | 200 page de `Quiz` (étudiant : publiés seulement) | 403, 404 |
| POST | /courses/:id/quizzes | enseignant propriétaire | 201 quiz complet (brouillon) | 403, 422 |
| GET | /quizzes?todo=true | étudiant | 200 quiz ouverts encore jouables | 401 |
| GET | /quizzes?status=open\|closed\|draft | enseignant | 200 ses quiz filtrés | 401 |
| GET | /quizzes/:id | enseignant propriétaire | 200 quiz avec `correctIndex` | 403, 404 |
| PATCH | /quizzes/:id | enseignant propriétaire | 200 quiz complet | 403, 409 déjà publié, 422 |
| POST | /quizzes/:id/publish | enseignant propriétaire | 200 `Quiz` | 403, 422 quiz incomplet |
| GET | /quizzes/:id/report | enseignant propriétaire | 200 `{questions[], submissions[], average…}` | 403 |
| POST | /quizzes/:id/attempts | étudiant inscrit | 201 tentative **sans les bonnes réponses**, `expiresAt`, `serverTime` (reprend la tentative en cours) | 403, 409 `NO_ATTEMPT_LEFT` |
| PUT | /attempts/:id/answers | étudiant propriétaire | 204 | 403, 409 temps écoulé / déjà remis |
| POST | /attempts/:id/submit | étudiant propriétaire | 200 résultat corrigé | 403, 409 déjà remis |
| GET | /attempts/:id | étudiant propriétaire ou enseignant du cours | 200 résultat + corrections | 403, 404 |
| GET | /attempts/me/latest | étudiant | 200 dernier résultat | 404 aucun |
| GET | /quizzes/:id/leaderboard | membre du cours | 200 `{title, participants, entries[]}` (score puis durée, `isMe`) | 403 |
| GET | /courses/:id/leaderboard | membre du cours | 200 idem, tous les quiz du cours | 403 |

**Règles serveur T17** : la bonne réponse n'est jamais renvoyée avant la remise ; le minuteur est appliqué par le serveur (`expiresAt` fixé au démarrage, réponses refusées après, remise tardive corrigée avec les seules réponses enregistrées à temps) ; une tentative par étudiant sauf si `maxAttempts > 1`.

## Comptes de test

_à compléter (script de seed)_

## Limites connues

_à compléter_
