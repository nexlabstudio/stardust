import 'dart:io';
import 'package:path/path.dart' as p;

/// Manages Pagefind binary - downloads if needed and runs indexing
class PagefindRunner {
  static const _version = '1.4.0';
  static const _baseUrl = 'https://github.com/CloudCannon/pagefind/releases/download';

  /// Get the cache directory for Stardust binaries
  static String get _cacheDir {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return p.join(home, '.stardust', 'bin');
  }

  /// Get the path to the Pagefind binary
  static String get _binaryPath {
    final ext = Platform.isWindows ? '.exe' : '';
    return p.join(_cacheDir, 'pagefind$ext');
  }

  /// Get the path to the version file
  static String get _versionFilePath => p.join(_cacheDir, '.pagefind-version');

  /// Get the installed version, if any
  static String? get _installedVersion {
    final file = File(_versionFilePath);
    if (file.existsSync()) {
      return file.readAsStringSync().trim();
    }
    return null;
  }

  /// Check if Pagefind binary exists
  static bool get isInstalled => File(_binaryPath).existsSync();

  /// Check if installed version matches expected version
  static bool get _isCorrectVersion => _installedVersion == _version;

  /// Check if Pagefind needs to be installed or updated
  static bool get needsInstall => !isInstalled || !_isCorrectVersion;

  /// Get the download URL for the current platform
  static String? get _downloadUrl {
    final arch = _getArch();
    if (arch == null) return null;

    final (platform, ext) = switch (Platform.operatingSystem) {
      'macos' => ('$arch-apple-darwin', 'tar.gz'),
      'linux' => ('$arch-unknown-linux-musl', 'tar.gz'),
      'windows' => ('$arch-pc-windows-msvc', 'zip'),
      _ => (null, null),
    };

    if (platform == null) return null;
    return '$_baseUrl/v$_version/pagefind-v$_version-$platform.$ext';
  }

  /// Get the architecture string
  static String? _getArch() => switch (Platform.operatingSystem) {
        'macos' || 'linux' => _unameArch(),
        'windows' => 'x86_64',
        _ => null,
      };

  static String _unameArch() {
    try {
      final machine = Process.runSync('uname', ['-m']).stdout.toString().trim();
      return switch (machine) {
        'arm64' || 'aarch64' => 'aarch64',
        _ => 'x86_64',
      };
    } catch (_) {
      return 'x86_64';
    }
  }

  /// Download and install the Pagefind binary
  static Future<bool> install({
    void Function(String)? onLog,
    void Function(String)? onError,
    void Function(int received, int total)? onProgress,
  }) async {
    final url = _downloadUrl;
    if (url == null) {
      onError?.call('Unsupported platform for Pagefind');
      return false;
    }

    final oldVersion = _installedVersion;
    if (oldVersion != null && oldVersion != _version) {
      onLog?.call('   Updating Pagefind from v$oldVersion to v$_version...');
    } else {
      onLog?.call('   Downloading Pagefind v$_version...');
    }

    try {
      final cacheDir = Directory(_cacheDir);
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }

      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(Uri.parse(url));
        final response = await request.close();

        if (response.statusCode != 200) {
          onError?.call('Failed to download Pagefind: HTTP ${response.statusCode}');
          return false;
        }

        var lastPercent = -1;
        void defaultProgress(int received, int total) {
          if (total <= 0) return;
          final percent = received * 100 ~/ total;
          if (percent ~/ 10 > lastPercent ~/ 10) {
            lastPercent = percent;
            onLog?.call('   Downloading... $percent%');
          }
        }

        return await _extractAndInstall(
          response,
          url,
          onLog: onLog,
          onError: onError,
          onProgress: onProgress ?? (onLog != null ? defaultProgress : null),
        );
      } finally {
        httpClient.close();
      }
    } catch (e) {
      onError?.call('Failed to download Pagefind: $e');
      return false;
    }
  }

  static Future<bool> _extractAndInstall(
    HttpClientResponse response,
    String url, {
    void Function(String)? onLog,
    void Function(String)? onError,
    void Function(int received, int total)? onProgress,
  }) async {
    final isZip = url.endsWith('.zip');
    final tempFile = File(p.join(_cacheDir, isZip ? 'pagefind.zip' : 'pagefind.tar.gz'));

    try {
      final total = response.contentLength;
      var received = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null && total > 0) {
          onProgress(received, total);
        }
      }
      await sink.close();

      if (isZip) {
        final result = await Process.run(
          'powershell',
          ['-Command', 'Expand-Archive', '-Path', tempFile.path, '-DestinationPath', _cacheDir, '-Force'],
        );
        if (result.exitCode != 0) {
          onError?.call('Failed to extract Pagefind: ${result.stderr}');
          return false;
        }
      } else {
        final result = await Process.run(
          'tar',
          ['-xzf', tempFile.path, '-C', _cacheDir],
        );
        if (result.exitCode != 0) {
          onError?.call('Failed to extract Pagefind: ${result.stderr}');
          return false;
        }
      }

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', _binaryPath]);
      }

      await File(_versionFilePath).writeAsString(_version);

      if (isInstalled) {
        onLog?.call('   ✓ Pagefind v$_version installed');
        return true;
      } else {
        onError?.call('Pagefind binary not found after extraction');
        return false;
      }
    } catch (e) {
      onError?.call('Failed to extract Pagefind: $e');
      return false;
    } finally {
      if (tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Run Pagefind on the output directory
  static Future<bool> run(
    String outputDir, {
    bool verbose = false,
    void Function(String)? onLog,
    void Function(String)? onError,
  }) async {
    if (needsInstall) {
      final installed = await install(onLog: onLog, onError: onError);
      if (!installed) {
        return false;
      }
    }

    try {
      final result = await Process.run(
        _binaryPath,
        ['--site', outputDir],
      );

      if (result.exitCode == 0) {
        if (verbose) {
          onLog?.call(result.stdout.toString());
        }
        onLog?.call('   ✓ Search index created');
        return true;
      } else {
        onError?.call('Pagefind failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      onError?.call('Failed to run Pagefind: $e');
      return false;
    }
  }
}
