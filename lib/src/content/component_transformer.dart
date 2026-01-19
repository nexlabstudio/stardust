import '../config/config.dart';
import '../core/interfaces.dart';
import '../utils/patterns.dart';
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

/// Transforms JSX-style components into HTML
///
/// Supports components like:
/// - `<Info>`, `<Warning>`, `<Danger>`, `<Tip>`, `<Note>`, `<Success>`
/// - `<Tabs>`, `<Tab>`
/// - `<CodeGroup>`, `<Code>`
/// - `<Accordion>`, `<AccordionGroup>`
/// - `<Steps>`, `<Step>`
/// - `<Cards>`, `<Card>`
/// - And many more...
///
/// Custom components can be registered via [register].
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

  /// Register a component builder
  ///
  /// This allows custom components to be added. The builder will handle
  /// all tag names returned by [ComponentBuilder.tagNames].
  void register(ComponentBuilder builder) {
    for (final tagName in builder.tagNames) {
      _builders[tagName] = builder;
    }
  }

  /// Transform JSX-style components in HTML content
  ///
  /// Note: This runs AFTER markdown parsing, so content inside code blocks
  /// is already HTML-escaped (e.g., `<Info>` becomes &lt;Info&gt;) and won't match.
  @override
  String transform(String content) {
    var result = content;

    for (final entry in _builders.entries) {
      final tagName = entry.key;
      final builder = entry.value;
      result = _transformTag(result, tagName, builder);
    }

    return result;
  }

  String _transformTag(String content, String tagName, ComponentBuilder builder) {
    var result = content;

    if (builder.allowSelfClosing) {
      result = result.replaceAllMapped(selfClosingComponentPattern(tagName), (match) {
        final attrs = parseAttributes(match.group(1) ?? '');
        return builder.build(tagName, attrs, '');
      });
    }

    final pattern = openCloseComponentPattern(tagName);
    var previousResult = '';
    while (previousResult != result) {
      previousResult = result;
      result = result.replaceAllMapped(pattern, (match) {
        final attrs = parseAttributes(match.group(1) ?? '');
        final innerContent = match.group(2) ?? '';
        return builder.build(tagName, attrs, innerContent.trim());
      });
    }

    return result;
  }
}
