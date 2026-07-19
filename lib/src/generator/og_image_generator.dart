import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../core/file_system.dart';
import '../models/page.dart';
import '../utils/concurrency.dart';
import '../utils/logger.dart';

/// Generates Open Graph images for pages at build time
class OgImageGenerator {
  final StardustConfig config;
  final String outputDir;
  final Logger logger;
  final FileSystem fileSystem;

  /// Rendered images are cached here keyed by their inputs, so unchanged
  /// pages skip the expensive pixel work on rebuilds.
  final String cacheDir;

  // Standard OG image dimensions
  static const _width = 1200;
  static const _height = 630;

  /// Bump when the drawing code changes to invalidate cached images.
  static const _renderVersion = 1;

  OgImageGenerator({
    required this.config,
    required this.outputDir,
    this.logger = const Logger(),
    FileSystem? fileSystem,
    this.cacheDir = '.dart_tool/stardust/og-cache',
  }) : fileSystem = fileSystem ?? const LocalFileSystem();

  String get _bgColor => config.theme.colors.background?.dark ?? '#0f172a';
  String get _textColor => config.theme.colors.text?.dark ?? '#f8fafc';
  String get _accentColor => config.theme.colors.primary;
  static const _secondaryColor = '#94a3b8';

  /// Generate OG images for all pages, in parallel and cache-backed
  Future<Map<String, String>> generateAll(List<Page> pages) async {
    final results = <String, String>{};
    final ogDir = p.join(outputDir, 'images', 'og');

    await fileSystem.createDirectory(ogDir, recursive: true);
    await fileSystem.createDirectory(cacheDir, recursive: true);

    final logoBytes = await _loadLogoBytes();
    final logoFingerprint = switch (logoBytes) {
      final bytes? => sha256.convert(bytes).toString(),
      null => 'none',
    };
    final styleKey = '$_renderVersion|${config.name}|$_bgColor|$_textColor|$_accentColor|$logoFingerprint';

    for (final chunk in chunked(pages, Platform.numberOfProcessors)) {
      await Future.wait(chunk.map((page) async {
        if (await _generateCached(page, ogDir, styleKey, logoBytes) case final url?) {
          results[page.path] = url;
        }
      }));
    }

    return results;
  }

  /// Generate the OG image for a single page
  Future<String?> generate(Page page, String ogDir) async {
    final logoBytes = await _loadLogoBytes();
    final logoFingerprint = switch (logoBytes) {
      final bytes? => sha256.convert(bytes).toString(),
      null => 'none',
    };
    await fileSystem.createDirectory(cacheDir, recursive: true);
    final styleKey = '$_renderVersion|${config.name}|$_bgColor|$_textColor|$_accentColor|$logoFingerprint';
    return _generateCached(page, ogDir, styleKey, logoBytes);
  }

  Future<String?> _generateCached(Page page, String ogDir, String styleKey, Uint8List? logoBytes) async {
    try {
      final fileName = _pagePathToFileName(page.path);
      final cacheKey = sha256.convert(utf8.encode('$styleKey|${page.title}')).toString();
      final cachePath = p.join(cacheDir, '$cacheKey.png');

      final Uint8List bytes;
      if (await fileSystem.fileExists(cachePath)) {
        bytes = await fileSystem.readFileBytes(cachePath);
      } else {
        final title = page.title;
        final siteName = config.name;
        final bgHex = _bgColor;
        final textHex = _textColor;
        final accentHex = _accentColor;
        bytes = await Isolate.run(
          () => render(
            title: title,
            siteName: siteName,
            bgHex: bgHex,
            textHex: textHex,
            accentHex: accentHex,
            logoBytes: logoBytes,
          ),
        );
        await fileSystem.writeFileBytes(cachePath, bytes);
      }

      await fileSystem.writeFileBytes(p.join(ogDir, fileName), bytes);
      return '${config.basePath}/images/og/$fileName';
    } catch (e) {
      logger.error('Failed to generate OG image for ${page.path}: $e');
      return null;
    }
  }

  /// Load the raw logo bytes from the public directory.
  /// SVG is not supported — falls back to a PNG/JPG sibling when present.
  Future<Uint8List?> _loadLogoBytes() async {
    var logoPath = config.logo?.effectiveDark ?? config.logo?.effectiveLight;
    if (logoPath == null) return null;

    if (logoPath.startsWith('/')) {
      logoPath = logoPath.substring(1);
    }

    final fullPath = p.join(config.build.assets.dir, logoPath);
    final ext = p.extension(fullPath).toLowerCase();

    if (ext == '.svg') {
      final basePath = p.withoutExtension(fullPath);
      for (final rasterExt in const ['.png', '.jpg', '.jpeg', '.webp']) {
        final rasterPath = '$basePath$rasterExt';
        if (await fileSystem.fileExists(rasterPath)) {
          return _readImageBytes(rasterPath);
        }
      }

      logger.log(
          '⚠️  SVG logos not supported for OG images. Add a PNG/JPG version: ${p.basenameWithoutExtension(logoPath)}.png');
      return null;
    }

    return _readImageBytes(fullPath);
  }

  Future<Uint8List?> _readImageBytes(String path) async {
    if (!await fileSystem.fileExists(path)) return null;

    try {
      return await fileSystem.readFileBytes(path);
    } catch (e) {
      logger.error('Failed to load logo: $e');
      return null;
    }
  }

  /// Pure rendering function, safe to run in an isolate.
  static Uint8List render({
    required String title,
    required String siteName,
    required String bgHex,
    required String textHex,
    required String accentHex,
    Uint8List? logoBytes,
  }) {
    final image = img.Image(width: _width, height: _height);

    final bgColor = _parseColor(bgHex);
    final accentColor = _parseColor(accentHex);
    final textColor = _parseColor(textHex);
    final secondaryColor = _parseColor(_secondaryColor);

    _fillGradient(image, bgColor, _darken(bgColor, 0.2));
    _drawAccentElements(image, accentColor);

    var textStartX = 80;
    final logo = switch (logoBytes) { final bytes? => _tryDecode(bytes), null => null };
    if (logo != null) {
      final scaledLogo = _scaleLogo(logo, maxHeight: 40);
      img.compositeImage(image, scaledLogo, dstX: 80, dstY: 70);
      textStartX = 80 + scaledLogo.width + 16;
    }

    img.drawString(
      image,
      siteName.toUpperCase(),
      font: img.arial24,
      x: textStartX,
      y: 78,
      color: secondaryColor,
    );

    _drawRect(image, 80, 130, 60, 4, accentColor);

    _drawWrappedText(
      image,
      title,
      x: 80,
      y: 200,
      maxWidth: _width - 160,
      color: textColor,
    );

    _drawRect(image, 0, _height - 8, _width, 8, accentColor);

    return img.encodePng(image);
  }

  static img.Image? _tryDecode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Scale logo to fit within maxHeight while preserving aspect ratio
  static img.Image _scaleLogo(img.Image logo, {required int maxHeight}) {
    if (logo.height <= maxHeight) return logo;

    final scale = maxHeight / logo.height;
    final newWidth = (logo.width * scale).round();

    return img.copyResize(logo, width: newWidth, height: maxHeight);
  }

  static void _fillGradient(img.Image image, img.Color topColor, img.Color bottomColor) {
    for (var y = 0; y < image.height; y++) {
      final ratio = y / image.height;
      final r = (topColor.r + (bottomColor.r - topColor.r) * ratio).round();
      final g = (topColor.g + (bottomColor.g - topColor.g) * ratio).round();
      final b = (topColor.b + (bottomColor.b - topColor.b) * ratio).round();
      final color = img.ColorRgb8(r, g, b);

      for (var x = 0; x < image.width; x++) {
        image.setPixel(x, y, color);
      }
    }
  }

  static void _drawAccentElements(img.Image image, img.Color accentColor) {
    final orbX = image.width - 200;
    const orbY = 150;
    const orbRadius = 300;

    final minX = math.max(0, orbX - orbRadius);
    final maxX = math.min(image.width, orbX + orbRadius);
    final maxY = math.min(image.height, orbY + orbRadius);

    for (var y = 0; y < maxY; y++) {
      for (var x = minX; x < maxX; x++) {
        final dx = x - orbX;
        final dy = y - orbY;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < orbRadius) {
          final intensity = (1 - distance / orbRadius) * 0.12;
          final currentPixel = image.getPixel(x, y);

          final r = math.min(255, (currentPixel.r + accentColor.r * intensity).round());
          final g = math.min(255, (currentPixel.g + accentColor.g * intensity).round());
          final b = math.min(255, (currentPixel.b + accentColor.b * intensity).round());

          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
    }
  }

  static void _drawRect(img.Image image, int x, int y, int width, int height, img.Color color) {
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        final px = x + dx;
        final py = y + dy;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }

  static void _drawWrappedText(
    img.Image image,
    String text, {
    required int x,
    required int y,
    required int maxWidth,
    required img.Color color,
  }) {
    final font = img.arial48;
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';
    const maxLines = 3;

    for (final word in words) {
      final testLine = currentLine.isEmpty ? word : '$currentLine $word';
      final testWidth = _measureTextWidth(testLine, font);

      if (testWidth > maxWidth && currentLine.isNotEmpty) {
        lines.add(currentLine);
        currentLine = word;

        if (lines.length >= maxLines) {
          if (currentLine.isNotEmpty) {
            lines[maxLines - 1] = '${lines[maxLines - 1]}...';
          }
          break;
        }
      } else {
        currentLine = testLine;
      }
    }

    if (currentLine.isNotEmpty && lines.length < maxLines) {
      lines.add(currentLine);
    }

    const lineHeight = 60;
    for (var i = 0; i < lines.length; i++) {
      img.drawString(
        image,
        lines[i],
        font: font,
        x: x,
        y: y + i * lineHeight,
        color: color,
      );
    }
  }

  static int _measureTextWidth(String text, img.BitmapFont font) {
    var width = 0;
    for (final char in text.codeUnits) {
      final glyph = font.characters[char];
      if (glyph != null) {
        width += glyph.xAdvance;
      } else {
        width += font.size ~/ 2;
      }
    }
    return width;
  }

  static img.Color _parseColor(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    final value = int.parse(h, radix: 16);
    return img.ColorRgb8(
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }

  static img.Color _darken(img.Color color, double amount) => img.ColorRgb8(
        (color.r * (1 - amount)).round(),
        (color.g * (1 - amount)).round(),
        (color.b * (1 - amount)).round(),
      );

  String _pagePathToFileName(String path) {
    if (path == '/') return 'index.png';
    final slug = path.substring(1).replaceAll('/', '-');
    return '$slug.png';
  }
}
