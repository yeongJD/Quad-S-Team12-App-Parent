/// Runtime environment selector + per-environment config.
///
/// Phase 2A scaffolding: URLs below are placeholders and MUST be replaced
/// with real backend endpoints before any non-mock environment is shipped.
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

  factory EnvironmentConfig.development() => const EnvironmentConfig(
        environment: AppEnvironment.development,
        baseUrl: 'https://api.dev.bridge-p.example.com',
        useMocks: true,
      );

  factory EnvironmentConfig.staging() => const EnvironmentConfig(
        environment: AppEnvironment.staging,
        baseUrl: 'https://api.staging.bridge-p.example.com',
        useMocks: false,
      );

  factory EnvironmentConfig.production() => const EnvironmentConfig(
        environment: AppEnvironment.production,
        baseUrl: 'https://api.bridge-p.example.com',
        useMocks: false,
      );
}

/// Compile-time current environment.
///
/// Declared as a top-level `const` so feature factories can read this
/// synchronously (no async bootstrap required).
// TODO(env): swap to .staging() / .production() at build time before release.
const EnvironmentConfig currentEnvironment = EnvironmentConfig(
  environment: AppEnvironment.development,
  baseUrl: 'https://api.dev.bridge-p.example.com',
  useMocks: true,
);
