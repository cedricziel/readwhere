import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readwhere_opds/readwhere_opds.dart';

void main() {
  group('OpdsClient search', () {
    group('search template substitution', () {
      test('substitutes {searchTerms} placeholder', () async {
        final client = _createMockClient(
          feedWithSearchTemplate: '/search?q={searchTerms}',
          searchResponse: _minimalFeedXml('Search Results'),
        );

        final rootFeed = await client.fetchFeed('http://example.com/opds');
        final result = await client.search(rootFeed, 'test query');

        expect(result.title, equals('Search Results'));
      });

      test('URL encodes search query', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchTerms}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'hello world');

        expect(capturedUrl, contains('hello%20world'));
      });

      test('handles lowercase {searchterms} variant', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchterms}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'test');

        expect(capturedUrl, contains('q=test'));
      });

      test('adds q parameter when no placeholder found', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(_feedWithSearchTemplate('/search'), 200);
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'myquery');

        expect(capturedUrl, contains('q=myquery'));
      });
    });

    group('search pagination', () {
      test('page parameter is optional and defaults to first page', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchTerms}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'test');

        // Should not have page parameter when not specified
        expect(capturedUrl, isNot(contains('page=')));
        expect(capturedUrl, isNot(contains('startPage=')));
      });

      test('substitutes {startPage} placeholder with page number', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchTerms}&page={startPage}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'test', page: 3);

        expect(capturedUrl, contains('page=3'));
      });

      test('substitutes {startIndex} placeholder with offset', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate(
              '/search?q={searchTerms}&start={startIndex}',
            ),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        // Page 3 with default 20 items per page = start index 40
        await client.search(rootFeed, 'test', page: 3);

        expect(capturedUrl, contains('start=40'));
      });

      test('removes pagination placeholders for page 1', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchTerms}&page={startPage}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'test', page: 1);

        // Pagination placeholders should be removed for first page
        expect(capturedUrl, isNot(contains('{startPage}')));
        expect(capturedUrl, isNot(contains('page=')));
      });

      test('adds page query param when no placeholder but page > 1', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Results'), 200);
          }
          return http.Response(_feedWithSearchTemplate('/search'), 200);
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        await client.search(rootFeed, 'test', page: 2);

        expect(capturedUrl, contains('page=2'));
      });
    });

    group('OpenSearch description', () {
      test('fetches and parses OpenSearch description', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('opensearch')) {
            return http.Response(
              _openSearchDescription('/search?q={searchTerms}'),
              200,
            );
          }
          if (request.url.path.contains('search')) {
            return http.Response(_minimalFeedXml('Search Results'), 200);
          }
          return http.Response(
            _feedWithOpenSearchLink('http://example.com/opensearch.xml'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');
        final result = await client.search(rootFeed, 'query');

        expect(result.title, equals('Search Results'));
      });

      test('throws when OpenSearch description fetch fails', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('opensearch')) {
            return http.Response('Not Found', 404);
          }
          return http.Response(
            _feedWithOpenSearchLink('http://example.com/opensearch.xml'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');

        expect(
          () => client.search(rootFeed, 'test'),
          throwsA(isA<OpdsException>()),
        );
      });

      test('throws when no template in OpenSearch description', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('opensearch')) {
            // Invalid OpenSearch without template
            return http.Response('''<?xml version="1.0"?>
              <OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
                <ShortName>Search</ShortName>
              </OpenSearchDescription>''', 200);
          }
          return http.Response(
            _feedWithOpenSearchLink('http://example.com/opensearch.xml'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');

        expect(
          () => client.search(rootFeed, 'test'),
          throwsA(
            isA<OpdsException>().having(
              (e) => e.message,
              'message',
              contains('No search template'),
            ),
          ),
        );
      });
    });

    group('error handling', () {
      test('throws when catalog does not support search', () async {
        final client = _createMockClient(
          feedWithSearchTemplate: null, // No search support
          searchResponse: _minimalFeedXml('Results'),
        );

        final rootFeed = await client.fetchFeed('http://example.com/opds');

        expect(
          () => client.search(rootFeed, 'test'),
          throwsA(
            isA<OpdsException>().having(
              (e) => e.message,
              'message',
              contains('does not support search'),
            ),
          ),
        );
      });

      test('throws when search request fails', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('search')) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            _feedWithSearchTemplate('/search?q={searchTerms}'),
            200,
          );
        });

        final client = OpdsClient(mockClient);
        final rootFeed = await client.fetchFeed('http://example.com/opds');

        expect(
          () => client.search(rootFeed, 'test'),
          throwsA(isA<OpdsException>()),
        );
      });
    });

    group('searchWithUrl', () {
      test('searches with direct URL path', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(_minimalFeedXml('Results'), 200);
        });

        final client = OpdsClient(mockClient);
        await client.searchWithUrl(
          'http://example.com/opds',
          '/search?q={searchTerms}',
          'myquery',
        );

        expect(capturedUrl, contains('example.com'));
        expect(capturedUrl, contains('/search'));
        expect(capturedUrl, contains('myquery'));
      });

      test('handles absolute search URL', () async {
        String? capturedUrl;
        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(_minimalFeedXml('Results'), 200);
        });

        final client = OpdsClient(mockClient);
        await client.searchWithUrl(
          'http://example.com/opds',
          'http://search.example.com/find?q={searchTerms}',
          'test',
        );

        expect(capturedUrl, startsWith('http://search.example.com'));
      });
    });
  });
}

/// Creates a mock OpdsClient with configurable search behavior
OpdsClient _createMockClient({
  String? feedWithSearchTemplate,
  required String searchResponse,
}) {
  final mockClient = MockClient((request) async {
    if (request.url.path.contains('search')) {
      return http.Response(searchResponse, 200);
    }
    if (feedWithSearchTemplate != null) {
      return http.Response(
        _feedWithSearchTemplate(feedWithSearchTemplate),
        200,
      );
    }
    return http.Response(_minimalFeedXml('Root'), 200);
  });

  return OpdsClient(mockClient);
}

/// Creates minimal OPDS feed XML
String _minimalFeedXml(String title) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>urn:uuid:test</id>
  <title>$title</title>
  <updated>2024-01-01T00:00:00Z</updated>
</feed>
''';

/// Creates OPDS feed XML with search template link
String _feedWithSearchTemplate(String searchTemplate) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:opds="http://opds-spec.org/2010/catalog">
  <id>urn:uuid:test</id>
  <title>Root Feed</title>
  <updated>2024-01-01T00:00:00Z</updated>
  <link rel="search"
        type="application/atom+xml"
        href="http://example.com$searchTemplate"/>
</feed>
''';

/// Creates OPDS feed XML with OpenSearch description link
String _feedWithOpenSearchLink(String descriptionUrl) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>urn:uuid:test</id>
  <title>Root Feed</title>
  <updated>2024-01-01T00:00:00Z</updated>
  <link rel="search"
        type="application/opensearchdescription+xml"
        href="$descriptionUrl"/>
</feed>
''';

/// Creates minimal OpenSearch description XML
String _openSearchDescription(String template) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Search</ShortName>
  <Description>Search the catalog</Description>
  <Url type="application/atom+xml" template="http://example.com$template"/>
</OpenSearchDescription>
''';
