import '../utils/attribute_parser.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds step components: Steps, Step
class StepBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Steps'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) {
    final steps = extractChildComponents(content, 'Step');

    if (steps.isEmpty) {
      return '<div class="steps-empty">No steps defined</div>';
    }

    final stepsHtml = StringBuffer();
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final title = step.attributes['title'] ?? '';
      final icon = step.attributes['icon'];
      final stepNumber = step.attributes['stepNumber'] ?? '${i + 1}';

      String numberDisplay;
      if (icon == null) {
        numberDisplay = stepNumber;
      } else if (isEmoji(icon)) {
        numberDisplay = icon;
      } else {
        numberDisplay = getLucideIcon(icon, '18');
      }

      stepsHtml.writeln('''
  <div class="step">
    <div class="step-indicator">
      <div class="step-number">$numberDisplay</div>
      <div class="step-line"></div>
    </div>
    <div class="step-body">
      ${title.isNotEmpty ? '<h4 class="step-title">$title</h4>' : ''}
      <div class="step-content">

${step.content}

      </div>
    </div>
  </div>''');
    }

    return '''
<div class="steps">
$stepsHtml</div>
''';
  }
}
