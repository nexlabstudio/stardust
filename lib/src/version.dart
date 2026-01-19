/// Stardust version, injected at compile time via --define=VERSION=x.y.z
const String version = String.fromEnvironment('VERSION', defaultValue: 'dev');
