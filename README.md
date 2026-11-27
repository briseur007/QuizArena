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
```

## Endpoints

| Méthode | Chemin | Rôle | Succès | Erreurs |
|---|---|---|---|---|
| GET | /health | public | 200 | — |
| _à compléter en M1_ | | | | |

## Comptes de test

_à compléter (script de seed)_

## Limites connues

_à compléter_
