import 'base_component.dart';

/// Builds API documentation components: Api, Field, ParamField, ResponseField
class ApiBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Api', 'Field', 'ParamField', 'ResponseField'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Api' => _buildApiEndpoint(attributes, content),
        'Field' => _buildField(attributes, content),
        'ParamField' => _buildParamField(attributes, content),
        'ResponseField' => _buildResponseField(attributes, content),
        _ => content
      };

  String _buildApiEndpoint(Map<String, String> attributes, String content) {
    final method = (attributes['method'] ?? 'GET').toUpperCase();
    final path = attributes['path'] ?? attributes['endpoint'] ?? '/';
    final title = attributes['title'];
    final auth = attributes['auth'];

    final methodClass = 'api-method-${method.toLowerCase()}';

    final titleHtml = title != null ? '<div class="api-title">$title</div>' : '';

    final authHtml = auth != null ? '<span class="api-auth">🔒 $auth</span>' : '';

    return '''
<div class="api-endpoint">
  <div class="api-header">
    <span class="api-method $methodClass">$method</span>
    <code class="api-path">$path</code>
    $authHtml
  </div>
  $titleHtml
  <div class="api-content">

$content

  </div>
</div>
''';
  }

  String _buildField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'any';
    final required = attributes['required'] == 'true' || attributes.containsKey('required');
    final defaultValue = attributes['default'];
    final deprecated = attributes['deprecated'] == 'true';

    final requiredBadge = required
        ? '<span class="field-badge field-required">required</span>'
        : '<span class="field-badge field-optional">optional</span>';

    final deprecatedBadge = deprecated ? '<span class="field-badge field-deprecated">deprecated</span>' : '';

    final defaultHtml =
        defaultValue != null ? '<span class="field-default">Default: <code>$defaultValue</code></span>' : '';

    return '''
<div class="field${deprecated ? ' field-is-deprecated' : ''}">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $requiredBadge
    $deprecatedBadge
  </div>
  $defaultHtml
  <div class="field-description">

$content

  </div>
</div>
''';
  }

  String _buildParamField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'string';
    final paramType = attributes['paramType'] ?? attributes['in'] ?? 'query';
    final required = attributes['required'] == 'true' || attributes.containsKey('required');
    final defaultValue = attributes['default'];

    final requiredBadge = required
        ? '<span class="field-badge field-required">required</span>'
        : '<span class="field-badge field-optional">optional</span>';

    final paramTypeBadge = '<span class="field-badge field-param-type">$paramType</span>';

    final defaultHtml =
        defaultValue != null ? '<span class="field-default">Default: <code>$defaultValue</code></span>' : '';

    return '''
<div class="field field-param">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $paramTypeBadge
    $requiredBadge
  </div>
  $defaultHtml
  <div class="field-description">

$content

  </div>
</div>
''';
  }

  String _buildResponseField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'any';
    final nullable = attributes['nullable'] == 'true';

    final nullableBadge = nullable ? '<span class="field-badge field-nullable">nullable</span>' : '';

    return '''
<div class="field field-response">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $nullableBadge
  </div>
  <div class="field-description">

$content

  </div>
</div>
''';
  }
}
