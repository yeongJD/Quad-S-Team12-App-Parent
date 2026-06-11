/// Runtime environment selector + per-environment config.
///
/// [useMocks] toggles whether feature repositories should return canned
/// mock data instead of hitting the network.
enum AppEnvironment { development, staging, production }

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    required this.useMocks,
  });

  final AppEnvironment environment;
  final String baseUrl;
  final bool useMocks;

  /// Development defaults to the shared AWS-backed API server.
  ///
  /// Override at build/run time when targeting Android emulator or a remote
  /// server:
  /// `--dart-define=BRIDGE_API_BASE_URL=http://10.0.2.2:8080`
  /// `--dart-define=BRIDGE_USE_MOCKS=true`
  const EnvironmentConfig.development()
    : this(
        environment: AppEnvironment.development,
        baseUrl: const String.fromEnvironment(
          'BRIDGE_API_BASE_URL',
          defaultValue: 'https://leyoung.shop',
        ),
        useMocks: const bool.fromEnvironment(
          'BRIDGE_USE_MOCKS',
          defaultValue: false,
        ),
      );

  const EnvironmentConfig.staging()
    : this(
        environment: AppEnvironment.staging,
        baseUrl: const String.fromEnvironment(
          'BRIDGE_API_BASE_URL',
          defaultValue: 'https://leyoung.shop',
        ),
        useMocks: false,
      );

  const EnvironmentConfig.production()
    : this(
        environment: AppEnvironment.production,
        baseUrl: const String.fromEnvironment(
          'BRIDGE_API_BASE_URL',
          defaultValue: 'https://leyoung.shop',
        ),
        useMocks: false,
      );
}

/// Compile-time current environment.
///
/// Declared as a top-level `const` so feature factories can read this
/// synchronously (no async bootstrap required).
const EnvironmentConfig currentEnvironment = EnvironmentConfig.development();
