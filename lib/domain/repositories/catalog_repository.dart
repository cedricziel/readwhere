import '../entities/catalog.dart';

/// Abstract repository interface for managing OPDS catalogs
///
/// This interface defines all operations for catalog data access.
abstract class CatalogRepository {
  /// Retrieve all catalogs
  ///
  /// Returns a list of all catalogs, ordered by most recently added first.
  Future<List<Catalog>> getAll();

  /// Retrieve a specific catalog by its ID
  ///
  /// Returns the catalog if found, null otherwise.
  Future<Catalog?> getById(String id);

  /// Insert a new catalog
  ///
  /// Returns the inserted catalog.
  /// Throws an exception if a catalog with the same URL already exists.
  Future<Catalog> insert(Catalog catalog);

  /// Update an existing catalog
  ///
  /// Returns the updated catalog.
  Future<Catalog> update(Catalog catalog);

  /// Delete a catalog by its ID
  ///
  /// Returns true if the catalog was deleted, false if it didn't exist.
  Future<bool> delete(String id);

  /// Update the last accessed timestamp for a catalog
  ///
  /// Sets the lastAccessedAt field to the current time.
  Future<void> updateLastAccessed(String id);

  /// Find a catalog by its URL
  ///
  /// Returns the catalog if found, null otherwise.
  /// Useful for checking if a catalog already exists.
  Future<Catalog?> findByUrl(String url);
}
