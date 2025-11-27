## 0.4.0

### Breaking Changes

- **Minimum SDK**: Requires Dart 3.7.0+ and Flutter 3.29.0+
- **local_auth 3.0.0**: The `useErrorDialogs` option is no longer available. Error handling must be implemented by the client application

### Dependencies

- `local_auth`: 2.3.0 → 3.0.0
- `local_auth_android`: 1.0.53 → 2.0.3
- `local_auth_darwin`: 1.6.0 → 2.0.1
- `local_auth_windows`: 1.0.11 → 2.0.1
- `logger`: 2.6.1 → 2.6.2

### Bug Fixes

- Fix biometrics initialization when device doesn't support biometrics
- Fix app lifecycle state listener (use `paused` instead of `inactive`)
- Fix background timestamp not being cleared after Request Again check
- Fix initialization order for proper state handling

### Features

- Add optional `prefs` and `secureStorage` constructor parameters for dependency injection

## 0.3.1+1

- Add link to example project

## 0.3.1

- Make controller's events stream broadcast

## 0.3.0

- Make canSetBiometrics method synchronous
- Add availableBiometrics getter
- Fix timeouts reading from local storage

## 0.2.0

- Add current timeout duration getter

## 0.1.1

- Fix platform support

## 0.1.0

- Update dependencies
- Update README
- Add biometrics dialog messages customization

## 0.0.1

Initial release.
