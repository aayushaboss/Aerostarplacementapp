enum DataMode { mock, http }

/// Selects which repository implementations [buildRepositories] (see
/// repositories.dart) wires up. Defaults to mock so the app behaves exactly
/// as it always has unless a build explicitly opts into the (currently
/// unimplemented — see BACKEND_API_CONTRACT.md) HTTP path via
/// `--dart-define=DATA_MODE=http`.
class DataConfig {
  DataConfig._();

  static const _raw = String.fromEnvironment('DATA_MODE', defaultValue: 'mock');
  static const DataMode mode = _raw == 'http' ? DataMode.http : DataMode.mock;

  /// Base URL for the HTTP repositories — only consulted once DATA_MODE=http
  /// is actually wired up to something real. `--dart-define=API_BASE_URL=…`
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
