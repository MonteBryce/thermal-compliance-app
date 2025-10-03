# Contributing Guide

## Development Setup

### **Prerequisites**
- Flutter SDK 3.32.7+
- Node.js 24.4.0+
- Git
- Firebase CLI

### **Local Development**

```bash
# 1. Clone repository
git clone https://github.com/yourusername/thermal-compliance-app.git
cd thermal-compliance-app

# 2. Install Flutter dependencies
flutter pub get

# 3. Install admin dashboard dependencies
cd admin-dashboard && npm install && cd ..

# 4. Run Flutter app
flutter run -d chrome

# 5. Run admin dashboard (separate terminal)
cd admin-dashboard && npm run dev
```

## Git Workflow

### **Branch Naming**
- `feature/short-description` - New features
- `fix/issue-description` - Bug fixes
- `refactor/component-name` - Code improvements
- `docs/topic` - Documentation updates

### **Commit Messages**
Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add offline sync indicator to dashboard
fix: resolve race condition in form validation
docs: update architecture diagrams
refactor: simplify state management in job list
test: add integration tests for auth flow
```

### **Pull Request Process**
1. Create feature branch from `main`
2. Make changes with meaningful commits
3. Run tests: `flutter test && npm test`
4. Push and create PR
5. Wait for CI checks to pass
6. Request review

## Code Standards

### **Flutter/Dart**
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `flutter analyze` before committing
- Format code: `flutter format lib/`
- Keep widgets under 100 lines when possible

### **TypeScript/React**
- Use TypeScript strict mode
- Follow [Airbnb Style Guide](https://github.com/airbnb/javascript)
- Run `npm run lint` before committing
- Use functional components with hooks

## Testing

### **Flutter Tests**
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

### **Admin Dashboard Tests**
```bash
cd admin-dashboard
npm test
npm run test:coverage
```

## Documentation

- Update README.md for major features
- Add inline comments for complex logic
- Update API docs in `docs/api.md`
- Include screenshots for UI changes

## Questions?

Open an issue or reach out to maintainers.
