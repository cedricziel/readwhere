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
  });
}
