import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Parsed Readium LCP license document.
///
/// The license document (META-INF/license.lcpl) contains the encrypted
/// content key and information needed to decrypt the protected publication.
class LcpLicense extends Equatable {
  /// Unique identifier for this license.
  final String id;

  /// When the license was issued.
  final DateTime? issued;

  /// URI identifying the content provider.
  final String? provider;

  /// Encryption profile URI.
  final String profile;

  /// The encrypted content key (Base64 encoded).
  final String encryptedContentKey;

  /// Algorithm used to encrypt the content key.
  final String contentKeyAlgorithm;

  /// Algorithm used to hash the user passphrase.
  final String userKeyAlgorithm;

  /// User passphrase hint.
  final String? userKeyHint;

  /// Usage rights.
  final LcpRights? rights;

  /// Links to related resources.
  final List<LcpLink> links;

  const LcpLicense({
    required this.id,
    this.issued,
    this.provider,
    required this.profile,
    required this.encryptedContentKey,
    required this.contentKeyAlgorithm,
    required this.userKeyAlgorithm,
    this.userKeyHint,
    this.rights,
    this.links = const [],
  });

  /// Parses an LCP license from JSON content.
  ///
  /// Throws [LcpLicenseException] if the license is invalid.
  factory LcpLicense.parse(String jsonContent) {
    try {
      final json = jsonDecode(jsonContent) as Map<String, dynamic>;
      return LcpLicense.fromJson(json);
    } catch (e) {
      throw LcpLicenseException('Failed to parse LCP license: $e');
    }
  }

  /// Creates an LCP license from a JSON map.
  factory LcpLicense.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw const LcpLicenseException('Missing license ID');
    }

    final encryption = json['encryption'] as Map<String, dynamic>?;
    if (encryption == null) {
      throw const LcpLicenseException('Missing encryption information');
    }

    final profile = encryption['profile'] as String?;
    if (profile == null) {
      throw const LcpLicenseException('Missing encryption profile');
    }

    final contentKey = encryption['content_key'] as Map<String, dynamic>?;
    if (contentKey == null) {
      throw const LcpLicenseException('Missing content key');
    }

    final encryptedValue = contentKey['encrypted_value'] as String?;
    if (encryptedValue == null) {
      throw const LcpLicenseException('Missing encrypted content key value');
    }

    final contentKeyAlgorithm =
        contentKey['algorithm'] as String? ?? 'http://www.w3.org/2001/04/xmlenc#aes256-cbc';

    final userKey = encryption['user_key'] as Map<String, dynamic>?;
    final userKeyAlgorithm =
        userKey?['algorithm'] as String? ?? 'http://www.w3.org/2001/04/xmlenc#sha256';
    final userKeyHint = userKey?['text_hint'] as String?;

    // Parse dates
    DateTime? issued;
    final issuedStr = json['issued'] as String?;
    if (issuedStr != null) {
      issued = DateTime.tryParse(issuedStr);
    }

    // Parse rights
    LcpRights? rights;
    final rightsJson = json['rights'] as Map<String, dynamic>?;
    if (rightsJson != null) {
      rights = LcpRights.fromJson(rightsJson);
    }

    // Parse links
    final links = <LcpLink>[];
    final linksJson = json['links'] as List<dynamic>?;
    if (linksJson != null) {
      for (final linkJson in linksJson) {
        if (linkJson is Map<String, dynamic>) {
          links.add(LcpLink.fromJson(linkJson));
        }
      }
    }

    return LcpLicense(
      id: id,
      issued: issued,
      provider: json['provider'] as String?,
      profile: profile,
      encryptedContentKey: encryptedValue,
      contentKeyAlgorithm: contentKeyAlgorithm,
      userKeyAlgorithm: userKeyAlgorithm,
      userKeyHint: userKeyHint,
      rights: rights,
      links: links,
    );
  }

  /// Whether this license uses the basic encryption profile.
  bool get isBasicProfile =>
      profile == 'http://readium.org/lcp/basic-profile' || profile.contains('basic');

  /// Whether content is still within the allowed time window.
  bool get isValid {
    final r = rights;
    if (r == null) return true;

    final now = DateTime.now();
    if (r.start != null && now.isBefore(r.start!)) return false;
    if (r.end != null && now.isAfter(r.end!)) return false;

    return true;
  }

  @override
  List<Object?> get props => [
        id,
        issued,
        provider,
        profile,
        encryptedContentKey,
        contentKeyAlgorithm,
        userKeyAlgorithm,
        userKeyHint,
        rights,
        links,
      ];
}

/// Usage rights specified in an LCP license.
class LcpRights extends Equatable {
  /// Maximum number of prints allowed.
  final int? print;

  /// Maximum number of copies allowed.
  final int? copy;

  /// When the license becomes valid.
  final DateTime? start;

  /// When the license expires.
  final DateTime? end;

  const LcpRights({
    this.print,
    this.copy,
    this.start,
    this.end,
  });

  factory LcpRights.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;

    final startStr = json['start'] as String?;
    if (startStr != null) {
      start = DateTime.tryParse(startStr);
    }

    final endStr = json['end'] as String?;
    if (endStr != null) {
      end = DateTime.tryParse(endStr);
    }

    return LcpRights(
      print: json['print'] as int?,
      copy: json['copy'] as int?,
      start: start,
      end: end,
    );
  }

  @override
  List<Object?> get props => [print, copy, start, end];
}

/// A link in an LCP license document.
class LcpLink extends Equatable {
  /// Link relation type.
  final String rel;

  /// Target URL.
  final String href;

  /// Optional MIME type.
  final String? type;

  /// Optional title.
  final String? title;

  const LcpLink({
    required this.rel,
    required this.href,
    this.type,
    this.title,
  });

  factory LcpLink.fromJson(Map<String, dynamic> json) {
    return LcpLink(
      rel: json['rel'] as String? ?? '',
      href: json['href'] as String? ?? '',
      type: json['type'] as String?,
      title: json['title'] as String?,
    );
  }

  @override
  List<Object?> get props => [rel, href, type, title];
}

/// Exception thrown for LCP license errors.
class LcpLicenseException implements Exception {
  final String message;

  const LcpLicenseException(this.message);

  @override
  String toString() => 'LcpLicenseException: $message';
}
