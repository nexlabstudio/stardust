import '../config/config.dart';
import '../core/interfaces.dart';
import 'components/accordion_builder.dart';
import 'components/api_builder.dart';
import 'components/base_component.dart';
import 'components/callout_builder.dart';
import 'components/card_builder.dart';
import 'components/embed_builder.dart';
import 'components/layout_builder.dart';
import 'components/media_builder.dart';
import 'components/step_builder.dart';
import 'components/tab_builder.dart';
import 'components/utility_builder.dart';
import 'utils/attribute_parser.dart';
import 'utils/code_masker.dart';
import 'utils/component_scanner.dart';

/// Transforms JSX-style components into HTML; custom builders register via [register].
class ComponentTransformer implements ContentTransformer {
  final Map<String, ComponentBuilder> _builders = {};

  ComponentTransformer({ComponentsConfig config = const ComponentsConfig()}) {
    register(CalloutBuilder(config: config));
    register(TabBuilder());
    register(AccordionBuilder());
    register(StepBuilder());
    register(CardBuilder());
    register(LayoutBuilder());
    register(MediaBuilder());
    register(EmbedBuilder());
    register(ApiBuilder());
    register(UtilityBuilder());
  }

  /// Register a builder for every tag name it declares
  void register(ComponentBuilder builder) {
    for (final tagName in builder.tagNames) {
      _builders[tagName] = builder;
    }
  }

  /// Tag names with a registered builder.
  Set<String> get registeredTags => _builders.keys.toSet();

  /// Builders receive raw inner source; their output is transformed
  /// recursively, and code spans are re-masked at every level.
  @override
  String transform(String content) {
    for (final builder in _builders.values.toSet()) {
      builder.resetPageState();
    }
    return _transformLevel(content, 0);
  }

  String _transformLevel(String content, int depth) {
    if (depth > 16) return content;

    final masked = maskCodeSpans(content);
    final out = StringBuffer();
    var pos = 0;

    for (var match = findFirstComponent(masked.text, registeredTags, pos);
        match != null;
        match = findFirstComponent(masked.text, registeredTags, pos)) {
      out.write(masked.restore(masked.text.substring(pos, match.start)));
      pos = match.end;

      final builder = _builders[match.name];
      if (builder == null) continue;

      if (match.selfClosing && !builder.allowSelfClosing) {
        out.write(masked.restore(masked.text.substring(match.start, match.end)));
        continue;
      }

      final attrs = parseAttributes(masked.restore(match.attributes));
      final inner = switch (match.inner) {
        final inner? => masked.restore(inner).trim(),
        null => '',
      };
      out.write(_transformLevel(builder.build(match.name, attrs, inner), depth + 1));
    }

    out.write(masked.restore(masked.text.substring(pos)));
    return out.toString();
  }
}
