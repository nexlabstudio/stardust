import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../utils/logger.dart';

/// Manages Pagefind binary - downloads if needed and runs indexing
class PagefindRunner {
  static const _version = '1.4.0';
  static const _baseUrl = 'https://github.com/CloudCannon/pagefind/releases/download';

  /// SHA-256 of each release asset, matching the publisher's .sha256 files.
  static const _checksums = {
    'aarch64-apple-darwin': '647fa1da25fefeb24348ed09cccfcbcdd1dcab75c83e146c9f50336a78efb290',
    'x86_64-apple-darwin': '76aac3acd6f5c1e0d09c3943a4720ce74de7c2ffa17d6697f55ce218eea22402',
    'aarch64-unknown-linux-musl': 'bff145bda01fbe079f67d68efaee602a44211b79ea45ed98c15d212f064de2ed',
    'x86_64-unknown-linux-musl': '8737736d3450c3e0a497233324716e95e4d0119c4aacac9361f339968b24dc79',
    'x86_64-pc-windows-msvc': '2cd20a6d2a9f69a9d340471b1cd4decdf2e8731e2c01d4a8b4d328e23ffd4dbb',
  };

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

  /// Download URL and expected SHA-256 for the current platform
  static (String url, String sha256)? get _download {
    final arch = _getArch();
    if (arch == null) return null;

    final target = switch (Platform.operatingSystem) {
      'macos' => '$arch-apple-darwin',
      'linux' => '$arch-unknown-linux-musl',
      'windows' => '$arch-pc-windows-msvc',
      _ => null,
    };

    if (_checksums[target] case final sha256?) {
      return ('$_baseUrl/v$_version/pagefind-v$_version-$target.tar.gz', sha256);
    }
    return null;
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
    Logger logger = const Logger(),
    void Function(int received, int total)? onProgress,
  }) async {
    final download = _download;
    if (download == null) {
      logger.error('Unsupported platform for Pagefind');
      return false;
    }
    final (url, expectedSha256) = download;

    final oldVersion = _installedVersion;
    if (oldVersion != null && oldVersion != _version) {
      logger.log('   Updating Pagefind from v$oldVersion to v$_version...');
    } else {
      logger.log('   Downloading Pagefind v$_version...');
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
          logger.error('Failed to download Pagefind: HTTP ${response.statusCode}');
          return false;
        }

        var lastPercent = -1;
        void defaultProgress(int received, int total) {
          if (total <= 0) return;
          final percent = received * 100 ~/ total;
          if (percent ~/ 10 > lastPercent ~/ 10) {
            lastPercent = percent;
            logger.log('   Downloading... $percent%');
          }
        }

        return await _extractAndInstall(
          response,
          expectedSha256,
          logger: logger,
          onProgress: onProgress ?? defaultProgress,
        );
      } finally {
        httpClient.close();
      }
    } catch (e) {
      logger.error('Failed to download Pagefind: $e');
      return false;
    }
  }

  static Future<bool> _extractAndInstall(
    HttpClientResponse response,
    String expectedSha256, {
    required Logger logger,
    void Function(int received, int total)? onProgress,
  }) async {
    final tempFile = File(p.join(_cacheDir, 'pagefind.tar.gz'));

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

      final actualSha256 = sha256.convert(await tempFile.readAsBytes()).toString();
      if (actualSha256 != expectedSha256) {
        logger.error('Pagefind download failed checksum verification');
        logger.error('   expected: $expectedSha256');
        logger.error('   actual:   $actualSha256');
        return false;
      }

      final result = await Process.run(
        'tar',
        ['-xzf', tempFile.path, '-C', _cacheDir],
      );
      if (result.exitCode != 0) {
        logger.error('Failed to extract Pagefind: ${result.stderr}');
        return false;
      }

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', _binaryPath]);
      }

      await File(_versionFilePath).writeAsString(_version);

      if (isInstalled) {
        logger.log('   ✓ Pagefind v$_version installed');
        return true;
      } else {
        logger.error('Pagefind binary not found after extraction');
        return false;
      }
    } catch (e) {
      logger.error('Failed to extract Pagefind: $e');
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
    Logger logger = const Logger(),
  }) async {
    if (needsInstall) {
      final installed = await install(logger: logger);
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
          logger.log(result.stdout.toString());
        }
        logger.log('   ✓ Search index created');
        return true;
      } else {
        logger.error('Pagefind failed: ${result.stderr}');
        return false;
      }
    } catch (e) {
      logger.error('Failed to run Pagefind: $e');
      return false;
    }
  }
}
