# Code Style and Conventions

## Commit Guidelines
- Use semantic commits: `feat:`, `fix:`, `chore:`, `refactor:`, etc.

## Dart/Flutter Conventions
- Use `super` parameters in constructors (Dart 3.x)
- Classes extend Equatable where needed for value equality
- ChangeNotifier for state management providers
- Private methods prefixed with underscore `_`
- Use `final` for immutable fields
- Constants in `app_constants.dart`

## File Organization
- One public class per file (typically)
- Models in `data/models/` extend domain entities
- Repository interfaces in `domain/repositories/`
- Repository implementations in `data/repositories/`

## Naming
- Files: snake_case (e.g., `book_card.dart`)
- Classes: PascalCase (e.g., `BookCard`)
- Variables/methods: camelCase (e.g., `buildCover`)
- Constants: camelCase or SCREAMING_SNAKE_CASE

## Pre-commit Checklist
- Run `flutter analyze` before commits
- Ensure 80%+ test coverage for new features
