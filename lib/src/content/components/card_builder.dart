import '../utils/attribute_parser.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds card components: Cards, Card, Tiles, Tile
class CardBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Cards', 'Card', 'Tiles'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Cards' => _buildCards(attributes, content),
        'Card' => _buildCard(attributes, content),
        'Tiles' => _buildTiles(attributes, content),
        _ => content
      };

  String _buildCards(Map<String, String> attributes, String content) {
    final columns = attributes['columns'] ?? '2';
    final cards = extractChildComponents(content, 'Card');

    final cardsHtml = StringBuffer();
    for (final card in cards) {
      cardsHtml.writeln(_buildCard(card.attributes, card.content));
    }

    return '''
<div class="cards" style="--cards-columns: $columns">
$cardsHtml</div>
''';
  }

  String _buildCard(Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? '';
    final icon = attributes['icon'];
    final href = attributes['href'];

    String iconHtml = '';
    switch (icon) {
      case _?:
        iconHtml = isEmoji(icon)
            ? '<span class="card-icon">$icon</span>'
            : '<span class="card-icon">${getLucideIcon(icon, '20')}</span>';
    }

    final titleHtml = title.isNotEmpty ? '<h3 class="card-title">$iconHtml$title</h3>' : '';

    final cardContent = '''
$titleHtml
<div class="card-content">

$content

</div>
''';

    if (href case final href?) {
      return '''
<a href="$href" class="card card-link">
$cardContent</a>
''';
    }

    return '''
<div class="card">
$cardContent</div>
''';
  }

  String _buildTiles(Map<String, String> attributes, String content) {
    final columns = attributes['columns'] ?? '3';
    final tiles = extractChildComponents(content, 'Tile');

    if (tiles.isEmpty) {
      return '<div class="tiles-empty">No tiles defined</div>';
    }

    final tilesHtml = StringBuffer();
    for (final tile in tiles) {
      tilesHtml.writeln(_buildTile(tile.attributes, tile.content));
    }

    return '''
<div class="tiles" style="--tiles-columns: $columns">
$tilesHtml</div>
''';
  }

  String _buildTile(Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? '';
    final icon = attributes['icon'];
    final href = attributes['href'];

    String iconHtml = '';
    switch (icon) {
      case _?:
        iconHtml = isEmoji(icon)
            ? '<div class="tile-icon">$icon</div>'
            : '<div class="tile-icon">${getLucideIcon(icon, '24')}</div>';
    }

    final titleHtml = title.isNotEmpty ? '<h4 class="tile-title">$title</h4>' : '';

    final tileContent = '''
$iconHtml
$titleHtml
<div class="tile-content">

$content

</div>
''';

    if (href case final href?) {
      return '''
<a href="$href" class="tile tile-link">
$tileContent</a>
''';
    }

    return '''
<div class="tile">
$tileContent</div>
''';
  }
}
