/// Base interface for all JSX-style component builders
abstract class ComponentBuilder {
  /// Tag names this builder handles (e.g., ['Info', 'Warning', 'Tip'])
  List<String> get tagNames;

  /// Whether this component supports self-closing syntax (`<Component />`)
  bool get allowSelfClosing => true;

  /// Build the HTML output for a component
  String build(String tagName, Map<String, String> attributes, String content);

  /// Reset any per-document state (e.g. ID counters) before a new page is transformed
  void resetPageState() {}
}
