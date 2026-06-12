# Fit Diary

Fit Diary is a Flutter prototype for keeping small, practical fitness records in one place. The app combines a workout diary, exercise guide, meal log, recipe browser, and simple notes with a consistent Material 3 interface.

## What It Does

- **Home dashboard**: quick entry points for the main product areas.
- **Workout Log**: save workouts with date, focus, duration, exercises, notes, optional photo, filters, sorting, and summary stats.
- **Nutrition**: log meals with calories/protein, browse recipes, search recipes, filter by category/time/difficulty, save favorite recipes, and add recipes directly to the meal log.
- **Exercise Guide**: browse training areas and muscle groups, then open exercise technique pages with local GIF demonstrations.
- **Notes**: save small reminders and tasks locally.

## Tech Stack

- Flutter / Dart
- Material 3 UI
- `sqflite` for local persistence
- JSON assets for recipes, categories, and exercise content
- Local image and GIF assets for offline-friendly browsing

## Project Structure

```text
lib/
  app_theme.dart                 App-wide visual system
  main.dart                      Flutter entry point
  start/                         Home screen and quick action cards
  trainings/                     Workout log model, database, and UI
  train_help/                    Exercise guide data, service, and screens
  meals/                         Nutrition, recipes, meal log, and models
  notes/                         Notes model, database, and screens

assets/
  data/                          Recipe/category/exercise JSON
  images/                        App, meal, and training guide images
  ATTRIBUTIONS.md                Source and license notes for media assets

test/
  *_test.dart                    Model, database, catalog, and widget tests
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run checks:

```bash
flutter analyze
flutter test
```

Build a debug APK:

```bash
flutter build apk --debug
```

## Test Coverage

The current tests cover:

- recipe and exercise catalog integrity;
- local asset references for meals and training GIFs;
- notes, meal log, and workout log database CRUD;
- workout database migration;
- meal and workout model serialization;
- home screen, Nutrition, Recipes, Notes, Exercise Guide, and Workout Log widget flows.

## Asset Notes

Meal photos and exercise media are stored locally where possible. Source and license details are tracked in [assets/ATTRIBUTIONS.md](assets/ATTRIBUTIONS.md). New training GIFs use the same OpenTraining/Everkinetic style already used in the project.

## Prototype Status

This is a solid interactive prototype rather than a production release. The next best improvements would be polishing recipe details, adding richer workout charts, tightening empty/error states, and cleaning any unused media before submission or publishing.
