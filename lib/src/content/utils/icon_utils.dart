import '../../utils/html_utils.dart';
import '../../utils/patterns.dart';
import 'lucide_icons.dart';

/// Check if a string is an emoji
bool isEmoji(String text) => emojiPattern.hasMatch(text);

/// Get a Lucide icon as build-time inline SVG
String getLucideIcon(String name, String size) {
  final iconName = name.toLowerCase().replaceAll('_', '-');
  final px = int.tryParse(size) ?? 20;
  return switch (lucideIcons[iconName]) {
    final inner? => '<svg class="lucide" width="$px" height="$px" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
        'aria-hidden="true">$inner</svg>',
    null => '<span class="icon-missing" data-icon="${encodeHtmlAttribute(iconName)}"></span>',
  };
}

/// Resolve an icon - returns emoji as-is or converts to Lucide icon
String resolveIcon(String icon, String size) {
  if (isEmoji(icon)) return icon;
  return getLucideIcon(icon, size);
}

/// Get file icon based on extension
String getFileIcon(String filename) {
  final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
  return fileIconMap[ext] ?? '📄';
}

/// Map of file extensions to emoji icons
// TODO(mastersam07): Revisit this mapping and consider adding more icons or changing some
const fileIconMap = {
  'dart': '🎯',
  'js': '📜',
  'ts': '📘',
  'jsx': '⚛️',
  'tsx': '⚛️',
  'py': '🐍',
  'rb': '💎',
  'go': '🐹',
  'rs': '🦀',
  'java': '☕',
  'kt': '🇰',
  'swift': '🍎',
  'c': '🔷',
  'cpp': '🔷',
  'h': '🔷',
  'cs': '🟣',
  'php': '🐘',
  'html': '🌐',
  'css': '🎨',
  'scss': '🎨',
  'sass': '🎨',
  'less': '🎨',
  'json': '📋',
  'yaml': '📋',
  'yml': '📋',
  'toml': '📋',
  'xml': '📋',
  'md': '📝',
  'mdx': '📝',
  'txt': '📄',
  'pdf': '📕',
  'doc': '📘',
  'docx': '📘',
  'xls': '📗',
  'xlsx': '📗',
  'ppt': '📙',
  'pptx': '📙',
  'png': '🖼️',
  'jpg': '🖼️',
  'jpeg': '🖼️',
  'gif': '🖼️',
  'svg': '🖼️',
  'webp': '🖼️',
  'ico': '🖼️',
  'mp3': '🎵',
  'wav': '🎵',
  'mp4': '🎬',
  'mov': '🎬',
  'avi': '🎬',
  'zip': '📦',
  'tar': '📦',
  'gz': '📦',
  'rar': '📦',
  '7z': '📦',
  'env': '🔐',
  'lock': '🔒',
  'gitignore': '🙈',
  'dockerignore': '🐳',
  'dockerfile': '🐳',
  'makefile': '🔧',
  'sh': '🐚',
  'bash': '🐚',
  'zsh': '🐚',
  'fish': '🐚',
};
