import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/data/database/tables/catalogs_table.dart';
import 'package:readwhere/data/models/catalog_model.dart';
import 'package:readwhere/domain/entities/catalog.dart';

void main() {
  group('CatalogModel', () {
    final testAddedAt = DateTime(2024, 1, 15, 10, 30);
    final testLastAccessedAt = DateTime(2024, 1, 20, 14, 45);

    group('constructor', () {
      test('creates catalog model with all fields', () {
        final model = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        expect(model.id, equals('catalog-123'));
        expect(model.name, equals('Test Catalog'));
        expect(model.url, equals('https://example.com/opds'));
        expect(model.iconUrl, equals('https://example.com/icon.png'));
        expect(model.addedAt, equals(testAddedAt));
        expect(model.lastAccessedAt, equals(testLastAccessedAt));
        expect(model.apiKey, equals('test-api-key'));
        expect(model.type, equals(CatalogType.kavita));
        expect(model.serverVersion, equals('0.8.0'));
        expect(model.username, equals('testuser'));
        expect(model.booksFolder, equals('/MyBooks'));
        expect(model.userId, equals('user-456'));
      });

      test('creates catalog model with default values', () {
        final model = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
        );

        expect(model.iconUrl, isNull);
        expect(model.lastAccessedAt, isNull);
        expect(model.apiKey, isNull);
        expect(model.type, equals(CatalogType.opds));
        expect(model.serverVersion, isNull);
        expect(model.username, isNull);
        expect(model.booksFolder, isNull);
        expect(model.userId, isNull);
      });
    });

    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          CatalogsTable.columnId: 'catalog-123',
          CatalogsTable.columnName: 'Test Catalog',
          CatalogsTable.columnUrl: 'https://example.com/opds',
          CatalogsTable.columnIconUrl: 'https://example.com/icon.png',
          CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
          CatalogsTable.columnLastAccessedAt:
              testLastAccessedAt.millisecondsSinceEpoch,
          CatalogsTable.columnApiKey: 'test-api-key',
          CatalogsTable.columnType: 'kavita',
          CatalogsTable.columnServerVersion: '0.8.0',
          CatalogsTable.columnUsername: 'testuser',
          CatalogsTable.columnBooksFolder: '/MyBooks',
          CatalogsTable.columnUserId: 'user-456',
        };

        final model = CatalogModel.fromMap(map);

        expect(model.id, equals('catalog-123'));
        expect(model.name, equals('Test Catalog'));
        expect(model.url, equals('https://example.com/opds'));
        expect(model.iconUrl, equals('https://example.com/icon.png'));
        expect(
          model.addedAt.millisecondsSinceEpoch,
          equals(testAddedAt.millisecondsSinceEpoch),
        );
        expect(
          model.lastAccessedAt?.millisecondsSinceEpoch,
          equals(testLastAccessedAt.millisecondsSinceEpoch),
        );
        expect(model.apiKey, equals('test-api-key'));
        expect(model.type, equals(CatalogType.kavita));
        expect(model.serverVersion, equals('0.8.0'));
        expect(model.username, equals('testuser'));
        expect(model.booksFolder, equals('/MyBooks'));
        expect(model.userId, equals('user-456'));
      });

      test('parses null optional fields', () {
        final map = {
          CatalogsTable.columnId: 'catalog-123',
          CatalogsTable.columnName: 'Test Catalog',
          CatalogsTable.columnUrl: 'https://example.com/opds',
          CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
          CatalogsTable.columnIconUrl: null,
          CatalogsTable.columnLastAccessedAt: null,
          CatalogsTable.columnApiKey: null,
          CatalogsTable.columnType: null,
          CatalogsTable.columnServerVersion: null,
          CatalogsTable.columnUsername: null,
          CatalogsTable.columnBooksFolder: null,
          CatalogsTable.columnUserId: null,
        };

        final model = CatalogModel.fromMap(map);

        expect(model.iconUrl, isNull);
        expect(model.lastAccessedAt, isNull);
        expect(model.apiKey, isNull);
        expect(model.type, equals(CatalogType.opds)); // Default
        expect(model.serverVersion, isNull);
        expect(model.username, isNull);
        expect(model.booksFolder, isNull);
        expect(model.userId, isNull);
      });

      group('catalog type parsing', () {
        test('parses opds type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test Catalog',
            CatalogsTable.columnUrl: 'https://example.com/opds',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'opds',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.opds));
          expect(model.isRss, isFalse);
        });

        test('parses kavita type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test Catalog',
            CatalogsTable.columnUrl: 'https://example.com/kavita',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'kavita',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.kavita));
          expect(model.isKavita, isTrue);
          expect(model.isRss, isFalse);
        });

        test('parses nextcloud type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test Catalog',
            CatalogsTable.columnUrl: 'https://example.com/nextcloud',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'nextcloud',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.nextcloud));
          expect(model.isNextcloud, isTrue);
          expect(model.isRss, isFalse);
        });

        test('parses rss type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test RSS Feed',
            CatalogsTable.columnUrl: 'https://example.com/feed.xml',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'rss',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.rss));
          expect(model.isRss, isTrue);
          expect(model.isKavita, isFalse);
          expect(model.isNextcloud, isFalse);
        });

        test('parses fanfiction type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Fanfiction.de',
            CatalogsTable.columnUrl: 'https://www.fanfiktion.de',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'fanfiction',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.fanfiction));
          expect(model.isFanfiction, isTrue);
          expect(model.isRss, isFalse);
          expect(model.isKavita, isFalse);
          expect(model.isNextcloud, isFalse);
        });

        test('defaults to opds for null type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test Catalog',
            CatalogsTable.columnUrl: 'https://example.com/opds',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: null,
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.opds));
        });

        test('defaults to opds for unknown type', () {
          final map = {
            CatalogsTable.columnId: 'catalog-123',
            CatalogsTable.columnName: 'Test Catalog',
            CatalogsTable.columnUrl: 'https://example.com/opds',
            CatalogsTable.columnAddedAt: testAddedAt.millisecondsSinceEpoch,
            CatalogsTable.columnType: 'some_future_type',
          };

          final model = CatalogModel.fromMap(map);
          expect(model.type, equals(CatalogType.opds));
        });
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final model = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        final map = model.toMap();

        expect(map[CatalogsTable.columnId], equals('catalog-123'));
        expect(map[CatalogsTable.columnName], equals('Test Catalog'));
        expect(
          map[CatalogsTable.columnUrl],
          equals('https://example.com/opds'),
        );
        expect(
          map[CatalogsTable.columnIconUrl],
          equals('https://example.com/icon.png'),
        );
        expect(
          map[CatalogsTable.columnAddedAt],
          equals(testAddedAt.millisecondsSinceEpoch),
        );
        expect(
          map[CatalogsTable.columnLastAccessedAt],
          equals(testLastAccessedAt.millisecondsSinceEpoch),
        );
        expect(map[CatalogsTable.columnApiKey], equals('test-api-key'));
        expect(map[CatalogsTable.columnType], equals('kavita'));
        expect(map[CatalogsTable.columnServerVersion], equals('0.8.0'));
        expect(map[CatalogsTable.columnUsername], equals('testuser'));
        expect(map[CatalogsTable.columnBooksFolder], equals('/MyBooks'));
        expect(map[CatalogsTable.columnUserId], equals('user-456'));
      });

      test('serializes null optional fields', () {
        final model = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
        );

        final map = model.toMap();

        expect(map[CatalogsTable.columnIconUrl], isNull);
        expect(map[CatalogsTable.columnLastAccessedAt], isNull);
        expect(map[CatalogsTable.columnApiKey], isNull);
        expect(map[CatalogsTable.columnServerVersion], isNull);
        expect(map[CatalogsTable.columnUsername], isNull);
        expect(map[CatalogsTable.columnBooksFolder], isNull);
        expect(map[CatalogsTable.columnUserId], isNull);
      });

      test('serializes all catalog types', () {
        for (final catalogType in CatalogType.values) {
          final model = CatalogModel(
            id: 'catalog-123',
            name: 'Test Catalog',
            url: 'https://example.com/opds',
            addedAt: testAddedAt,
            type: catalogType,
          );

          final map = model.toMap();
          expect(map[CatalogsTable.columnType], equals(catalogType.name));
        }
      });
    });

    group('fromEntity', () {
      test('converts Catalog entity to CatalogModel', () {
        final catalog = Catalog(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        final model = CatalogModel.fromEntity(catalog);

        expect(model.id, equals(catalog.id));
        expect(model.name, equals(catalog.name));
        expect(model.url, equals(catalog.url));
        expect(model.iconUrl, equals(catalog.iconUrl));
        expect(model.addedAt, equals(catalog.addedAt));
        expect(model.lastAccessedAt, equals(catalog.lastAccessedAt));
        expect(model.apiKey, equals(catalog.apiKey));
        expect(model.type, equals(catalog.type));
        expect(model.serverVersion, equals(catalog.serverVersion));
        expect(model.username, equals(catalog.username));
        expect(model.booksFolder, equals(catalog.booksFolder));
        expect(model.userId, equals(catalog.userId));
      });

      test('converts RSS Catalog entity to CatalogModel', () {
        final catalog = Catalog(
          id: 'rss-123',
          name: 'Test RSS Feed',
          url: 'https://example.com/feed.xml',
          addedAt: testAddedAt,
          type: CatalogType.rss,
        );

        final model = CatalogModel.fromEntity(catalog);

        expect(model.type, equals(CatalogType.rss));
        expect(model.isRss, isTrue);
      });
    });

    group('toEntity', () {
      test('converts CatalogModel to Catalog entity', () {
        final model = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        final catalog = model.toEntity();

        expect(catalog.id, equals(model.id));
        expect(catalog.name, equals(model.name));
        expect(catalog.url, equals(model.url));
        expect(catalog.iconUrl, equals(model.iconUrl));
        expect(catalog.addedAt, equals(model.addedAt));
        expect(catalog.lastAccessedAt, equals(model.lastAccessedAt));
        expect(catalog.apiKey, equals(model.apiKey));
        expect(catalog.type, equals(model.type));
        expect(catalog.serverVersion, equals(model.serverVersion));
        expect(catalog.username, equals(model.username));
        expect(catalog.booksFolder, equals(model.booksFolder));
        expect(catalog.userId, equals(model.userId));
      });

      test('converts RSS CatalogModel to Catalog entity', () {
        final model = CatalogModel(
          id: 'rss-123',
          name: 'Test RSS Feed',
          url: 'https://example.com/feed.xml',
          addedAt: testAddedAt,
          type: CatalogType.rss,
        );

        final catalog = model.toEntity();

        expect(catalog.type, equals(CatalogType.rss));
        expect(catalog.isRss, isTrue);
      });
    });

    group('round-trip', () {
      test('toMap then fromMap preserves all data', () {
        final original = CatalogModel(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        final map = original.toMap();
        final restored = CatalogModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.url, equals(original.url));
        expect(restored.iconUrl, equals(original.iconUrl));
        expect(
          restored.addedAt.millisecondsSinceEpoch,
          equals(original.addedAt.millisecondsSinceEpoch),
        );
        expect(
          restored.lastAccessedAt?.millisecondsSinceEpoch,
          equals(original.lastAccessedAt?.millisecondsSinceEpoch),
        );
        expect(restored.apiKey, equals(original.apiKey));
        expect(restored.type, equals(original.type));
        expect(restored.serverVersion, equals(original.serverVersion));
        expect(restored.username, equals(original.username));
        expect(restored.booksFolder, equals(original.booksFolder));
        expect(restored.userId, equals(original.userId));
      });

      test('toMap then fromMap preserves RSS type', () {
        final original = CatalogModel(
          id: 'rss-123',
          name: 'Test RSS Feed',
          url: 'https://example.com/feed.xml',
          addedAt: testAddedAt,
          type: CatalogType.rss,
        );

        final map = original.toMap();
        final restored = CatalogModel.fromMap(map);

        expect(restored.type, equals(CatalogType.rss));
        expect(restored.isRss, isTrue);
      });

      test('toMap then fromMap preserves all catalog types', () {
        for (final catalogType in CatalogType.values) {
          final original = CatalogModel(
            id: 'catalog-123',
            name: 'Test Catalog',
            url: 'https://example.com/catalog',
            addedAt: testAddedAt,
            type: catalogType,
          );

          final map = original.toMap();
          final restored = CatalogModel.fromMap(map);

          expect(
            restored.type,
            equals(original.type),
            reason: 'Failed for type: ${catalogType.name}',
          );
        }
      });

      test('fromEntity then toEntity preserves all data', () {
        final original = Catalog(
          id: 'catalog-123',
          name: 'Test Catalog',
          url: 'https://example.com/opds',
          iconUrl: 'https://example.com/icon.png',
          addedAt: testAddedAt,
          lastAccessedAt: testLastAccessedAt,
          apiKey: 'test-api-key',
          type: CatalogType.kavita,
          serverVersion: '0.8.0',
          username: 'testuser',
          booksFolder: '/MyBooks',
          userId: 'user-456',
        );

        final model = CatalogModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.url, equals(original.url));
        expect(restored.iconUrl, equals(original.iconUrl));
        expect(restored.addedAt, equals(original.addedAt));
        expect(restored.lastAccessedAt, equals(original.lastAccessedAt));
        expect(restored.apiKey, equals(original.apiKey));
        expect(restored.type, equals(original.type));
        expect(restored.serverVersion, equals(original.serverVersion));
        expect(restored.username, equals(original.username));
        expect(restored.booksFolder, equals(original.booksFolder));
        expect(restored.userId, equals(original.userId));
      });

      test('fromEntity then toEntity preserves RSS type', () {
        final original = Catalog(
          id: 'rss-123',
          name: 'Test RSS Feed',
          url: 'https://example.com/feed.xml',
          addedAt: testAddedAt,
          type: CatalogType.rss,
        );

        final model = CatalogModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored.type, equals(CatalogType.rss));
        expect(restored.isRss, isTrue);
      });
    });

    group('type helpers', () {
      test('isRss returns true only for RSS type', () {
        final rssModel = CatalogModel(
          id: 'rss-123',
          name: 'Test RSS',
          url: 'https://example.com/feed.xml',
          addedAt: testAddedAt,
          type: CatalogType.rss,
        );
        expect(rssModel.isRss, isTrue);

        final opdsModel = CatalogModel(
          id: 'opds-123',
          name: 'Test OPDS',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
          type: CatalogType.opds,
        );
        expect(opdsModel.isRss, isFalse);
      });

      test('isKavita returns true only for Kavita type', () {
        final kavitaModel = CatalogModel(
          id: 'kavita-123',
          name: 'Test Kavita',
          url: 'https://example.com/kavita',
          addedAt: testAddedAt,
          type: CatalogType.kavita,
        );
        expect(kavitaModel.isKavita, isTrue);

        final opdsModel = CatalogModel(
          id: 'opds-123',
          name: 'Test OPDS',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
          type: CatalogType.opds,
        );
        expect(opdsModel.isKavita, isFalse);
      });

      test('isNextcloud returns true only for Nextcloud type', () {
        final nextcloudModel = CatalogModel(
          id: 'nextcloud-123',
          name: 'Test Nextcloud',
          url: 'https://example.com/nextcloud',
          addedAt: testAddedAt,
          type: CatalogType.nextcloud,
        );
        expect(nextcloudModel.isNextcloud, isTrue);

        final opdsModel = CatalogModel(
          id: 'opds-123',
          name: 'Test OPDS',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
          type: CatalogType.opds,
        );
        expect(opdsModel.isNextcloud, isFalse);
      });

      test('isFanfiction returns true only for Fanfiction type', () {
        final fanfictionModel = CatalogModel(
          id: 'fanfiction-123',
          name: 'Fanfiction.de',
          url: 'https://www.fanfiktion.de',
          addedAt: testAddedAt,
          type: CatalogType.fanfiction,
        );
        expect(fanfictionModel.isFanfiction, isTrue);

        final opdsModel = CatalogModel(
          id: 'opds-123',
          name: 'Test OPDS',
          url: 'https://example.com/opds',
          addedAt: testAddedAt,
          type: CatalogType.opds,
        );
        expect(opdsModel.isFanfiction, isFalse);
      });
    });
  });
}
