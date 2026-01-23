import 'package:stardust/src/config/integrations_config.dart';
import 'package:stardust/src/generator/builders/page_analytics_builder.dart';
import 'package:test/test.dart';

void main() {
  group('PageAnalyticsBuilder', () {
    group('build', () {
      test('returns empty string when analytics is null', () {
        final builder = PageAnalyticsBuilder(analytics: null);
        expect(builder.build(), isEmpty);
      });

      test('returns empty string when no analytics configured', () {
        const analytics = AnalyticsConfig();
        final builder = PageAnalyticsBuilder(analytics: analytics);
        expect(builder.build(), isEmpty);
      });

      test('builds Google Analytics script', () {
        const analytics = AnalyticsConfig(google: 'G-TEST123');
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- Google Analytics -->'));
        expect(result, contains('googletagmanager.com/gtag/js?id=G-TEST123'));
        expect(result, contains("gtag('config', 'G-TEST123')"));
      });

      test('builds Plausible script', () {
        const analytics = AnalyticsConfig(plausible: 'example.com');
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- Plausible Analytics -->'));
        expect(result, contains('data-domain="example.com"'));
        expect(result, contains('plausible.io/js/script.js'));
        expect(result, contains('defer'));
      });

      test('builds PostHog script with default host', () {
        const analytics = AnalyticsConfig(
          posthog: PosthogConfig(key: 'phc_test123'),
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- PostHog Analytics -->'));
        expect(result, contains("posthog.init('phc_test123'"));
        expect(result, contains('api_host: \'https://us.i.posthog.com\''));
      });

      test('builds PostHog script with custom host', () {
        const analytics = AnalyticsConfig(
          posthog: PosthogConfig(key: 'phc_test123', host: 'https://custom.posthog.com'),
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('api_host: \'https://custom.posthog.com\''));
      });

      test('builds custom analytics with external src', () {
        const analytics = AnalyticsConfig(
          custom: [
            CustomAnalyticsConfig(name: 'Fathom', src: 'https://cdn.usefathom.com/script.js'),
          ],
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- Fathom -->'));
        expect(result, contains('src="https://cdn.usefathom.com/script.js"'));
        expect(result, contains('async'));
      });

      test('builds custom analytics with defer', () {
        const analytics = AnalyticsConfig(
          custom: [
            CustomAnalyticsConfig(name: 'Test', src: 'https://example.com/script.js', async: false, defer: true),
          ],
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, isNot(contains('async')));
        expect(result, contains('defer'));
      });

      test('builds custom analytics with inline script', () {
        const analytics = AnalyticsConfig(
          custom: [
            CustomAnalyticsConfig(name: 'Custom Tracker', script: 'console.log("tracking");'),
          ],
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- Custom Tracker -->'));
        expect(result, contains('console.log("tracking");'));
      });

      test('builds multiple analytics providers', () {
        const analytics = AnalyticsConfig(
          google: 'G-TEST123',
          plausible: 'example.com',
          custom: [
            CustomAnalyticsConfig(name: 'Fathom', src: 'https://cdn.usefathom.com/script.js'),
          ],
        );
        final builder = PageAnalyticsBuilder(analytics: analytics);

        final result = builder.build();

        expect(result, contains('<!-- Google Analytics -->'));
        expect(result, contains('<!-- Plausible Analytics -->'));
        expect(result, contains('<!-- Fathom -->'));
      });
    });

    group('AnalyticsConfig.hasAny', () {
      test('returns false when no analytics configured', () {
        const analytics = AnalyticsConfig();
        expect(analytics.hasAny, isFalse);
      });

      test('returns true when google is configured', () {
        const analytics = AnalyticsConfig(google: 'G-TEST');
        expect(analytics.hasAny, isTrue);
      });

      test('returns true when plausible is configured', () {
        const analytics = AnalyticsConfig(plausible: 'example.com');
        expect(analytics.hasAny, isTrue);
      });

      test('returns true when posthog is configured', () {
        const analytics = AnalyticsConfig(posthog: PosthogConfig(key: 'test'));
        expect(analytics.hasAny, isTrue);
      });

      test('returns true when custom is configured', () {
        const analytics = AnalyticsConfig(
          custom: [CustomAnalyticsConfig(name: 'Test', src: 'https://example.com/script.js')],
        );
        expect(analytics.hasAny, isTrue);
      });
    });

    group('AnalyticsConfig.fromYaml', () {
      test('parses google analytics', () {
        final config = AnalyticsConfig.fromYaml({'google': 'G-TEST123'});
        expect(config.google, 'G-TEST123');
      });

      test('parses plausible', () {
        final config = AnalyticsConfig.fromYaml({'plausible': 'example.com'});
        expect(config.plausible, 'example.com');
      });

      test('parses posthog', () {
        final config = AnalyticsConfig.fromYaml({
          'posthog': {'key': 'phc_test', 'host': 'https://custom.posthog.com'}
        });
        expect(config.posthog?.key, 'phc_test');
        expect(config.posthog?.host, 'https://custom.posthog.com');
      });

      test('parses custom analytics', () {
        final config = AnalyticsConfig.fromYaml({
          'custom': [
            {'name': 'Fathom', 'src': 'https://cdn.usefathom.com/script.js'},
            {'name': 'Inline', 'script': 'console.log("test")'},
          ]
        });
        expect(config.custom.length, 2);
        expect(config.custom[0].name, 'Fathom');
        expect(config.custom[0].src, 'https://cdn.usefathom.com/script.js');
        expect(config.custom[1].name, 'Inline');
        expect(config.custom[1].script, 'console.log("test")');
      });

      test('parses custom analytics with async and defer', () {
        final config = AnalyticsConfig.fromYaml({
          'custom': [
            {'name': 'Test', 'src': 'https://example.com/script.js', 'async': false, 'defer': true}
          ]
        });
        expect(config.custom[0].async, isFalse);
        expect(config.custom[0].defer, isTrue);
      });
    });
  });
}
