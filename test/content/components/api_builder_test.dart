import 'package:stardust/src/content/components/api_builder.dart';
import 'package:test/test.dart';

void main() {
  group('ApiBuilder', () {
    late ApiBuilder builder;

    setUp(() {
      builder = ApiBuilder();
    });

    test('tagNames includes all API components', () {
      expect(builder.tagNames, containsAll(['Api', 'Field', 'ParamField', 'ResponseField']));
    });

    group('Api component', () {
      test('builds basic API endpoint', () {
        final result = builder.build('Api', {'path': '/users'}, 'Description');

        expect(result, contains('api-endpoint'));
        expect(result, contains('api-method'));
        expect(result, contains('/users'));
        expect(result, contains('Description'));
      });

      test('uses GET method by default', () {
        final result = builder.build('Api', {'path': '/test'}, '');

        expect(result, contains('GET'));
        expect(result, contains('api-method-get'));
      });

      test('handles POST method', () {
        final result = builder.build('Api', {'method': 'POST', 'path': '/users'}, '');

        expect(result, contains('POST'));
        expect(result, contains('api-method-post'));
      });

      test('handles PUT method', () {
        final result = builder.build('Api', {'method': 'put', 'path': '/users'}, '');

        expect(result, contains('PUT'));
        expect(result, contains('api-method-put'));
      });

      test('handles DELETE method', () {
        final result = builder.build('Api', {'method': 'delete', 'path': '/users/1'}, '');

        expect(result, contains('DELETE'));
        expect(result, contains('api-method-delete'));
      });

      test('includes title when provided', () {
        final result = builder.build('Api', {'path': '/users', 'title': 'Get all users'}, '');

        expect(result, contains('api-title'));
        expect(result, contains('Get all users'));
      });

      test('includes auth badge when provided', () {
        final result = builder.build('Api', {'path': '/users', 'auth': 'Bearer token'}, '');

        expect(result, contains('api-auth'));
        expect(result, contains('Bearer token'));
      });

      test('uses endpoint as fallback for path', () {
        final result = builder.build('Api', {'endpoint': '/api/v1/users'}, '');

        expect(result, contains('/api/v1/users'));
      });

      test('defaults to / when no path provided', () {
        final result = builder.build('Api', {}, '');

        expect(result, contains('<code class="api-path">/</code>'));
      });
    });

    group('Field component', () {
      test('builds basic field', () {
        final result = builder.build('Field', {'name': 'id', 'type': 'string'}, 'The unique identifier');

        expect(result, contains('field'));
        expect(result, contains('field-name'));
        expect(result, contains('id'));
        expect(result, contains('field-type'));
        expect(result, contains('string'));
        expect(result, contains('The unique identifier'));
      });

      test('shows required badge when required=true', () {
        final result = builder.build('Field', {'name': 'id', 'required': 'true'}, '');

        expect(result, contains('field-required'));
        expect(result, contains('required'));
      });

      test('shows required badge when required attribute exists', () {
        final result = builder.build('Field', {'name': 'id', 'required': ''}, '');

        expect(result, contains('field-required'));
      });

      test('shows optional badge when not required', () {
        final result = builder.build('Field', {'name': 'id'}, '');

        expect(result, contains('field-optional'));
        expect(result, contains('optional'));
      });

      test('shows deprecated badge when deprecated', () {
        final result = builder.build('Field', {'name': 'oldId', 'deprecated': 'true'}, '');

        expect(result, contains('field-deprecated'));
        expect(result, contains('deprecated'));
        expect(result, contains('field-is-deprecated'));
      });

      test('shows default value when provided', () {
        final result = builder.build('Field', {'name': 'count', 'default': '10'}, '');

        expect(result, contains('field-default'));
        expect(result, contains('Default:'));
        expect(result, contains('<code>10</code>'));
      });

      test('uses any as default type', () {
        final result = builder.build('Field', {'name': 'data'}, '');

        expect(result, contains('any'));
      });
    });

    group('ParamField component', () {
      test('builds basic param field', () {
        final result = builder.build('ParamField', {'name': 'userId', 'type': 'integer'}, 'User ID');

        expect(result, contains('field-param'));
        expect(result, contains('userId'));
        expect(result, contains('integer'));
        expect(result, contains('User ID'));
      });

      test('shows param type badge with query default', () {
        final result = builder.build('ParamField', {'name': 'page'}, '');

        expect(result, contains('field-param-type'));
        expect(result, contains('query'));
      });

      test('supports paramType attribute', () {
        final result = builder.build('ParamField', {'name': 'id', 'paramType': 'path'}, '');

        expect(result, contains('path'));
      });

      test('supports in attribute as alternative to paramType', () {
        final result = builder.build('ParamField', {'name': 'token', 'in': 'header'}, '');

        expect(result, contains('header'));
      });

      test('shows required badge', () {
        final result = builder.build('ParamField', {'name': 'id', 'required': 'true'}, '');

        expect(result, contains('field-required'));
      });

      test('shows default value', () {
        final result = builder.build('ParamField', {'name': 'limit', 'default': '20'}, '');

        expect(result, contains('Default:'));
        expect(result, contains('<code>20</code>'));
      });

      test('uses string as default type', () {
        final result = builder.build('ParamField', {'name': 'search'}, '');

        expect(result, contains('string'));
      });
    });

    group('ResponseField component', () {
      test('builds basic response field', () {
        final result = builder.build('ResponseField', {'name': 'data', 'type': 'object'}, 'Response data');

        expect(result, contains('field-response'));
        expect(result, contains('data'));
        expect(result, contains('object'));
        expect(result, contains('Response data'));
      });

      test('shows nullable badge when nullable', () {
        final result = builder.build('ResponseField', {'name': 'error', 'nullable': 'true'}, '');

        expect(result, contains('field-nullable'));
        expect(result, contains('nullable'));
      });

      test('does not show nullable badge when not nullable', () {
        final result = builder.build('ResponseField', {'name': 'id'}, '');

        expect(result, isNot(contains('field-nullable')));
      });

      test('uses any as default type', () {
        final result = builder.build('ResponseField', {'name': 'result'}, '');

        expect(result, contains('any'));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
