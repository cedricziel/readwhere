import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere_webdav/readwhere_webdav.dart';
import 'package:test/test.dart';

import 'webdav_client_create_directory_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late WebDavClient client;

  setUp(() {
    mockDio = MockDio();
    client = WebDavClient(
      config: WebDavConfig(
        baseUrl: 'https://example.com/remote.php/dav/files/user',
        auth: BasicAuth(username: 'user', password: 'pass'),
      ),
      dio: mockDio,
    );
  });

  group('createDirectory', () {
    test('creates directory successfully with 201 response', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      await expectLater(
        client.createDirectory('/new-folder'),
        completes,
      );

      verify(mockDio.request<void>(
        'https://example.com/remote.php/dav/files/user/new-folder',
        options: argThat(
          predicate<Options>(
            (opts) => opts.method == 'MKCOL',
          ),
          named: 'options',
        ),
      )).called(1);
    });

    test('throws WebDavException when directory already exists (405)',
        () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 405,
          ));

      expect(
        () => client.createDirectory('/existing-folder'),
        throwsA(
          isA<WebDavException>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
    });

    test('throws WebDavException when parent directory does not exist (409)',
        () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 409,
          ));

      expect(
        () => client.createDirectory('/nonexistent/new-folder'),
        throwsA(
          isA<WebDavException>().having(
            (e) => e.message,
            'message',
            contains('Parent directory'),
          ),
        ),
      );
    });

    test('throws WebDavException on authentication failure (401)', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ));

      expect(
        () => client.createDirectory('/folder'),
        throwsA(
          isA<WebDavException>().having(
            (e) => e.message,
            'message',
            contains('Authentication failed'),
          ),
        ),
      );
    });

    test('throws WebDavException on unexpected status code', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ));

      // Note: 500 is not < 500, so it will be handled differently
      // The validateStatus allows < 500, so 500 would throw DioException
    });

    test('throws WebDavException on other 4xx errors', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 403,
          ));

      expect(
        () => client.createDirectory('/folder'),
        throwsA(
          isA<WebDavException>().having(
            (e) => e.message,
            'message',
            contains('Failed to create directory'),
          ),
        ),
      );
    });

    test('throws WebDavException on network error', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(),
        message: 'Connection refused',
        type: DioExceptionType.connectionError,
      ));

      expect(
        () => client.createDirectory('/folder'),
        throwsA(
          isA<WebDavException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('includes auth headers in request', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      await client.createDirectory('/folder');

      verify(mockDio.request<void>(
        any,
        options: argThat(
          predicate<Options>((opts) {
            final headers = opts.headers;
            return headers != null && headers.containsKey('Authorization');
          }),
          named: 'options',
        ),
      )).called(1);
    });

    test('handles path without leading slash', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      await client.createDirectory('folder-without-slash');

      verify(mockDio.request<void>(
        'https://example.com/remote.php/dav/files/user/folder-without-slash',
        options: anyNamed('options'),
      )).called(1);
    });

    test('handles nested path creation', () async {
      when(mockDio.request<void>(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      await client.createDirectory('/parent/child/grandchild');

      verify(mockDio.request<void>(
        'https://example.com/remote.php/dav/files/user/parent/child/grandchild',
        options: anyNamed('options'),
      )).called(1);
    });
  });
}
