import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import 'nextcloud_webdav_test.mocks.dart';

@GenerateMocks([Dio, NextcloudCredentialStorage])
void main() {
  late MockDio mockDio;
  late MockNextcloudCredentialStorage mockStorage;
  late NextcloudWebDav webdav;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockNextcloudCredentialStorage();
    webdav = NextcloudWebDav(mockStorage, dio: mockDio);
  });

  group('NextcloudWebDav', () {
    group('listDirectoryWithCredentials', () {
      test('builds correct WebDAV URL', () async {
        // Setup mock to throw to capture the request
        when(mockDio.request<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'Mock error',
        ));

        // Act - try to list directory (will fail due to mock)
        try {
          await webdav.listDirectoryWithCredentials(
            serverUrl: 'https://cloud.example.com',
            userId: 'testuser',
            username: 'testuser',
            password: 'testpassword',
            path: '/Books',
          );
        } catch (_) {
          // Expected to fail
        }

        // Verify the URL was built correctly
        final captured = verify(mockDio.request<dynamic>(
          captureAny,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).captured;

        expect(captured.isNotEmpty, true);
        final url = captured.first as String;
        expect(url, contains('/remote.php/dav/files/testuser'));
      });

      test('normalizes server URL with trailing slash', () async {
        when(mockDio.request<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'Mock error',
        ));

        try {
          await webdav.listDirectoryWithCredentials(
            serverUrl: 'https://cloud.example.com/',
            userId: 'testuser',
            username: 'testuser',
            password: 'testpassword',
            path: '/',
          );
        } catch (_) {
          // Expected to fail
        }

        final captured = verify(mockDio.request<dynamic>(
          captureAny,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).captured;

        expect(captured.isNotEmpty, true);
        final url = captured.first as String;
        // The path portion (after protocol://) should not have double slashes
        final pathPortion = url.replaceFirst(RegExp(r'https?://'), '');
        expect(pathPortion, isNot(contains('//')));
      });

      test('accepts different userId and username', () async {
        when(mockDio.request<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'Mock error',
        ));

        try {
          await webdav.listDirectoryWithCredentials(
            serverUrl: 'https://cloud.example.com',
            userId: 'user123',
            username: 'admin',
            password: 'password',
            path: '/Documents',
          );
        } catch (_) {
          // Expected to fail
        }

        final captured = verify(mockDio.request<dynamic>(
          captureAny,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).captured;

        expect(captured.isNotEmpty, true);
        final url = captured.first as String;
        // URL should use userId, not username
        expect(url, contains('/files/user123'));
        expect(url, isNot(contains('/files/admin')));
      });

      test('does not require catalogId (no storage lookup)', () async {
        when(mockDio.request<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'Mock error',
        ));

        try {
          await webdav.listDirectoryWithCredentials(
            serverUrl: 'https://cloud.example.com',
            userId: 'user',
            username: 'user',
            password: 'pass',
            path: '/',
          );
        } catch (_) {
          // Expected to fail
        }

        // Should NOT have called storage.getCredential
        verifyNever(mockStorage.getCredential(any));
      });
    });

    group('createDirectoryWithCredentials', () {
      test('builds correct WebDAV URL for MKCOL', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com',
          userId: 'testuser',
          username: 'testuser',
          password: 'testpassword',
          path: '/NewFolder',
        );

        final captured = verify(mockDio.request<void>(
          captureAny,
          options: anyNamed('options'),
        )).captured;

        expect(captured.isNotEmpty, true);
        final url = captured.first as String;
        expect(url, contains('/remote.php/dav/files/testuser'));
        expect(url, contains('/NewFolder'));
      });

      test('uses MKCOL method', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com',
          userId: 'user',
          username: 'user',
          password: 'pass',
          path: '/test',
        );

        verify(mockDio.request<void>(
          any,
          options: argThat(
            predicate<Options>((opts) => opts.method == 'MKCOL'),
            named: 'options',
          ),
        )).called(1);
      });

      test('normalizes server URL', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com/',
          userId: 'user',
          username: 'user',
          password: 'pass',
          path: '/test',
        );

        final captured = verify(mockDio.request<void>(
          captureAny,
          options: anyNamed('options'),
        )).captured;

        final url = captured.first as String;
        final pathPortion = url.replaceFirst(RegExp(r'https?://'), '');
        expect(pathPortion, isNot(contains('//')));
      });

      test('does not require catalogId (no storage lookup)', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com',
          userId: 'user',
          username: 'user',
          password: 'pass',
          path: '/NewFolder',
        );

        verifyNever(mockStorage.getCredential(any));
      });

      test('handles nested paths', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com',
          userId: 'user',
          username: 'user',
          password: 'pass',
          path: '/Books/Comics/Marvel',
        );

        final captured = verify(mockDio.request<void>(
          captureAny,
          options: anyNamed('options'),
        )).captured;

        final url = captured.first as String;
        expect(url, contains('/Books/Comics/Marvel'));
      });

      test('accepts different userId and username', () async {
        when(mockDio.request<void>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await webdav.createDirectoryWithCredentials(
          serverUrl: 'https://cloud.example.com',
          userId: 'user123',
          username: 'admin',
          password: 'password',
          path: '/Test',
        );

        final captured = verify(mockDio.request<void>(
          captureAny,
          options: anyNamed('options'),
        )).captured;

        final url = captured.first as String;
        expect(url, contains('/files/user123'));
        expect(url, isNot(contains('/files/admin')));
      });
    });
  });
}
