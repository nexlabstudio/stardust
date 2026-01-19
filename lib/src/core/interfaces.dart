import '../content/markdown_parser.dart';
import '../models/page.dart';

abstract class ContentParser {
  ParsedPage parse(String content, {String? defaultTitle});
}

abstract class ContentTransformer {
  String transform(String content);
}

abstract class HtmlBuilder {
  String build(Page page);
}
