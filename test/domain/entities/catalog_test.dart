import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/catalog.dart';

void main() {
  group('Catalog', () {
    group('constructor', () {
      test('creates catalog with required fields', () {
        final now = DateTime.now();
        final catalog = Catalog(
          id: 'test-id',
          name: 'Test Catalog',
          url: 'https://example.com',
          addedAt: now,
        );

        expect(catalog.id, 'test-id');
        expect(catalog.name, 'Test Catalog');
        expect(catalog.url, 'https://example.com');
        expect(catalog.addedAt, now);
        expect(catalog.type, CatalogType.opds); // default
      });

      test('creates catalog with all fields', () {
        final now = DateTime.now();
        final lastAccessed = DateTime.now().add(const Duration(hours: 1));
        final catalog = Catalog(
          id: 'test-id',
          name: 'Test Catalog',
          url: 'https://example.com',
          iconUrl: 'https://example.com/icon.png',
          addedAt: now,
          lastAccessedAt: lastAccessed,
          apiKey: 'api-key-123',
          type: CatalogType.kavita,
          serverVersion: '0.7.8',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-123',
        );

        expect(catalog.id, 'test-id');
        expect(catalog.name, 'Test Catalog');
        expect(catalog.url, 'https://example.com');
        expect(catalog.iconUrl, 'https://example.com/icon.png');
        expect(catalog.addedAt, now);
        expect(catalog.lastAccessedAt, lastAccessed);
        expect(catalog.apiKey, 'api-key-123');
        expect(catalog.type, CatalogType.kavita);
        expect(catalog.serverVersion, '0.7.8');
        expect(catalog.username, 'testuser');
        expect(catalog.booksFolder, '/MyBooks');
        expect(catalog.userId, 'user-123');
      });
    });

    group('effectiveBooksFolder', () {
      test('returns root when booksFolder is null', () {
        final catalog = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          booksFolder: null,
        );

        expect(catalog.effectiveBooksFolder, '/');
      });

      test('returns booksFolder when set', () {
        final catalog = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          booksFolder: '/Documents/Books',
        );

        expect(catalog.effectiveBooksFolder, '/Documents/Books');
      });

      test('returns custom folder path', () {
        final catalog = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          booksFolder: '/eBooks/Fiction',
        );

        expect(catalog.effectiveBooksFolder, '/eBooks/Fiction');
      });
    });

    group('type helpers', () {
      test('isKavita returns true only for Kavita type', () {
        final kavita = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.kavita,
        );
        final opds = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(kavita.isKavita, true);
        expect(opds.isKavita, false);
      });

      test('isNextcloud returns true only for Nextcloud type', () {
        final nextcloud = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
        );
        final opds = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(nextcloud.isNextcloud, true);
        expect(opds.isNextcloud, false);
      });

      test('isRss returns true only for RSS type', () {
        final rss = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.rss,
        );
        final opds = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(rss.isRss, true);
        expect(opds.isRss, false);
      });

      test('isFanfiction returns true only for Fanfiction type', () {
        final fanfiction = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.fanfiction,
        );
        final opds = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(fanfiction.isFanfiction, true);
        expect(opds.isFanfiction, false);
      });

      test('requiresAuth returns true when apiKey is set', () {
        final withKey = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          apiKey: 'my-api-key',
        );
        final withoutKey = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
        );
        final emptyKey = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          apiKey: '',
        );

        expect(withKey.requiresAuth, true);
        expect(withoutKey.requiresAuth, false);
        expect(emptyKey.requiresAuth, false);
      });
    });

    group('webdavUrl', () {
      test('returns url when not nextcloud', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(catalog.webdavUrl, 'https://example.com');
      });

      test('returns url when userId is null', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://nextcloud.example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          userId: null,
        );

        expect(catalog.webdavUrl, 'https://nextcloud.example.com');
      });

      test('returns webdav url for nextcloud with userId', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://nextcloud.example.com',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          userId: 'testuser',
        );

        expect(
          catalog.webdavUrl,
          'https://nextcloud.example.com/remote.php/dav/files/testuser',
        );
      });

      test('handles trailing slash in url', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://nextcloud.example.com/',
          addedAt: DateTime.now(),
          type: CatalogType.nextcloud,
          userId: 'testuser',
        );

        expect(
          catalog.webdavUrl,
          'https://nextcloud.example.com/remote.php/dav/files/testuser',
        );
      });
    });

    group('opdsUrl', () {
      test('returns url for opds catalog', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://example.com/opds',
          addedAt: DateTime.now(),
          type: CatalogType.opds,
        );

        expect(catalog.opdsUrl, 'https://example.com/opds');
      });

      test('returns kavita opds url with apiKey', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://kavita.example.com',
          addedAt: DateTime.now(),
          type: CatalogType.kavita,
          apiKey: 'my-api-key',
        );

        expect(
          catalog.opdsUrl,
          'https://kavita.example.com/api/opds/my-api-key',
        );
      });

      test('returns url for kavita without apiKey', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://kavita.example.com',
          addedAt: DateTime.now(),
          type: CatalogType.kavita,
          apiKey: null,
        );

        expect(catalog.opdsUrl, 'https://kavita.example.com');
      });

      test('handles trailing slash for kavita', () {
        final catalog = Catalog(
          id: 'test',
          name: 'Test',
          url: 'https://kavita.example.com/',
          addedAt: DateTime.now(),
          type: CatalogType.kavita,
          apiKey: 'my-api-key',
        );

        expect(
          catalog.opdsUrl,
          'https://kavita.example.com/api/opds/my-api-key',
        );
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime(2024, 1, 1),
          type: CatalogType.opds,
        );

        final copied = original.copyWith(
          name: 'Updated Name',
          booksFolder: '/NewFolder',
        );

        expect(copied.id, 'test-id');
        expect(copied.name, 'Updated Name');
        expect(copied.url, 'https://example.com');
        expect(copied.booksFolder, '/NewFolder');
        expect(copied.type, CatalogType.opds);
      });

      test('preserves original values when not specified', () {
        final original = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: DateTime(2024, 1, 1),
          type: CatalogType.nextcloud,
          username: 'user',
          booksFolder: '/Books',
          userId: 'user-id',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.url, original.url);
        expect(copied.type, original.type);
        expect(copied.username, original.username);
        expect(copied.booksFolder, original.booksFolder);
        expect(copied.userId, original.userId);
      });
    });

    group('equality', () {
      test('two catalogs with same values are equal', () {
        final addedAt = DateTime(2024, 1, 1);
        final catalog1 = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: addedAt,
        );
        final catalog2 = Catalog(
          id: 'test-id',
          name: 'Test',
          url: 'https://example.com',
          addedAt: addedAt,
        );

        expect(catalog1, catalog2);
        expect(catalog1.hashCode, catalog2.hashCode);
      });

      test('two catalogs with different values are not equal', () {
        final addedAt = DateTime(2024, 1, 1);
        final catalog1 = Catalog(
          id: 'test-id-1',
          name: 'Test',
          url: 'https://example.com',
          addedAt: addedAt,
        );
        final catalog2 = Catalog(
          id: 'test-id-2',
          name: 'Test',
          url: 'https://example.com',
          addedAt: addedAt,
        );

        expect(catalog1, isNot(catalog2));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final catalog = Catalog(
          id: 'test-id',
          name: 'My Catalog',
          url: 'https://example.com',
          addedAt: DateTime.now(),
        );

        expect(
          catalog.toString(),
          'Catalog(id: test-id, name: My Catalog, url: https://example.com)',
        );
      });
    });
  });
}
