import '../../config/config.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds callout/alert components: Info, Warning, Danger, Tip, Note, Success
class CalloutBuilder extends ComponentBuilder {
  final ComponentsConfig config;

  CalloutBuilder({required this.config});

  @override
  List<String> get tagNames => ['Info', 'Warning', 'Danger', 'Tip', 'Note', 'Success'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) {
    final type = tagName.toLowerCase();
    final title = attributes['title'];
    final icon = attributes['icon'];

    final calloutConfig =
        config.callouts[type] ?? _defaultCallouts[type] ?? const CalloutConfig(icon: '📌', color: '#6b7280');

    final rawIcon = icon ?? calloutConfig.icon;
    final displayIcon = resolveIcon(rawIcon, '18');
    final displayTitle = title ?? _capitalize(type);

    return '''
<div class="callout callout-$type" style="--callout-color: ${calloutConfig.color}">
  <p class="callout-title">$displayIcon $displayTitle</p>
  <div class="callout-content">

$content

  </div>
</div>
''';
  }

  static const _defaultCallouts = {
    'info': CalloutConfig(icon: 'ℹ️', color: '#3b82f6'),
    'warning': CalloutConfig(icon: '⚠️', color: '#f59e0b'),
    'danger': CalloutConfig(icon: '🚨', color: '#ef4444'),
    'tip': CalloutConfig(icon: '💡', color: '#22c55e'),
    'note': CalloutConfig(icon: '📝', color: '#8b5cf6'),
    'success': CalloutConfig(icon: '✅', color: '#10b981'),
  };

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
