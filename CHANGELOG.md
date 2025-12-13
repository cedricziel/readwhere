# Changelog

## [0.4.0](https://github.com/cedricziel/readwhere/compare/v0.3.0...v0.4.0) (2025-12-13)


### Features

* **catalog:** add mosaic cover preview for navigation sections ([647f184](https://github.com/cedricziel/readwhere/commit/647f1845785ad0c2d511ebc17aa629a5175d0afa))
* **import:** add CBZ/CBR metadata refresh support ([22e60f7](https://github.com/cedricziel/readwhere/commit/22e60f75e747847a76e907544da8bfdeefb9b7b9))
* **library:** add extended metadata display and EPUB CSS injection ([cae12d8](https://github.com/cedricziel/readwhere/commit/cae12d83bca9fb2292f21bb9c39a8e6b91ab08b4))
* **library:** add metadata refresh functionality ([9ac17ab](https://github.com/cedricziel/readwhere/commit/9ac17ab7bd7e19f7af133201879f85939b03ba76))
* **opds:** add pagination support to catalog search ([ccf0fc6](https://github.com/cedricziel/readwhere/commit/ccf0fc6dc8302264a6944b7f95dcf3e95f895d6f))
* **opds:** implement facet navigation support ([f0b5e58](https://github.com/cedricziel/readwhere/commit/f0b5e582988f50e893714c24e8697c286afb2977))
* **plugin:** expose extended metadata in CatalogEntry interface ([28e60c0](https://github.com/cedricziel/readwhere/commit/28e60c0415d2b62163e47a59e4c2133e74a0acd9))
* **ui:** render markdown in update dialog ([2945efc](https://github.com/cedricziel/readwhere/commit/2945efc57768c685ad6316dc26385a83f3fab0f2))


### Bug Fixes

* **ci:** preserve changelog in GitHub release body ([2603c47](https://github.com/cedricziel/readwhere/commit/2603c475c17ea4db8241588e5fee2b86b14d5f3a))
* **import:** preserve book title when comic has no metadata ([c03a2cf](https://github.com/cedricziel/readwhere/commit/c03a2cf0262f2da8f2d713ba0e496c908b2f5e84))
* **library:** pull-to-refresh now refreshes metadata from book files ([04a98f7](https://github.com/cedricziel/readwhere/commit/04a98f7ed92e51b931cd5868032080e21e960652))
* **nextcloud:** allow back navigation when server is unavailable ([8e906b4](https://github.com/cedricziel/readwhere/commit/8e906b444bee75bc400e2cdded213a7b4d2e2377))
* **opds:** resolve encoding and cache constraint issues for Kavita ([98152ef](https://github.com/cedricziel/readwhere/commit/98152ef779aab6f64dde2b4291c2563efa52df78))
* **reader:** resolve SelectionArea crash and CSS text flow issues ([6e1ec12](https://github.com/cedricziel/readwhere/commit/6e1ec1224f4606c3fdd7d10c9d0e04614e37f4b6))
* **tests:** add missing currentChapterCss mock stub ([e6fc0ba](https://github.com/cedricziel/readwhere/commit/e6fc0ba52bce92a081d8cb6d24022b8181c1279c))
* **theme:** add explicit text colors for light mode contrast ([c3af7e1](https://github.com/cedricziel/readwhere/commit/c3af7e1e4cb92a65b31ec18bfc0b47ac57c4243d))
* **ui:** show cover images for navigation entries in OPDS catalogs ([c8e574c](https://github.com/cedricziel/readwhere/commit/c8e574cfb8257c3a0cb33d6f07347d34ead872a7))

## [0.3.0](https://github.com/cedricziel/readwhere/compare/v0.2.0...v0.3.0) (2025-12-11)


### Features

* **catalog:** separate download-only vs download-and-open actions ([0226543](https://github.com/cedricziel/readwhere/commit/0226543f03aa69041da457ad610363a667240c26))
* **fanfiction:** show richer story metadata in catalog list ([c850911](https://github.com/cedricziel/readwhere/commit/c850911747191869fe401874adc98d2003dd45f6))
* **plugins:** add fanfiction.de catalog plugin ([d057b44](https://github.com/cedricziel/readwhere/commit/d057b448d643e9992c9139e0900a7206fbf417b6))
* **reader:** add center tap to toggle controls in CBR/CBZ reader ([5fa9e46](https://github.com/cedricziel/readwhere/commit/5fa9e463df70a0d0d8c00e5d009459ba54c4297f))
* **ui:** integrate fanfiction.de catalog into UI ([f0c1313](https://github.com/cedricziel/readwhere/commit/f0c131396274f27c8064078b6d4b6506e00823f3))


### Bug Fixes

* **catalog:** refresh library before navigating to reader after download ([e7382bb](https://github.com/cedricziel/readwhere/commit/e7382bba4c15d717a5289b614d63d940a1e10bfb))
* **ci:** correct keystore path in release workflow ([37f91fc](https://github.com/cedricziel/readwhere/commit/37f91fc41274b1007f2a8457727b89f9ca43b026))
* **epub:** use UTF-8 decoding for EPUB text content ([b60e349](https://github.com/cedricziel/readwhere/commit/b60e34996dd0054a79c8c8e7238ea636833b0ad0))
* **fanfictionde:** update parseFandoms regex to match actual HTML ([a739109](https://github.com/cedricziel/readwhere/commit/a739109f8da6de99d6c582eec0cb4f16e18b476d))
* **fanfiction:** filter fandom links by /updatedate suffix ([c3485c1](https://github.com/cedricziel/readwhere/commit/c3485c143a16eb8a63b88353666617dd75a89237))
* **fanfiction:** fix UTF-8 encoding in EPUB files ([761d49a](https://github.com/cedricziel/readwhere/commit/761d49a9b0585e2c21dc4deb31e83004dd7c0042))
* **fanfiction:** improve story parsing, page titles, and UTF-8 encoding ([28b2244](https://github.com/cedricziel/readwhere/commit/28b224406b4f9ffa03ca163337f5a4aa2f8aad98))
* **fanfiction:** normalize full URLs to paths in browse method ([98d61d4](https://github.com/cedricziel/readwhere/commit/98d61d4ec48735b37984a53181537e02c06202d5))
* **library:** fix SnackBar not dismissing after book deletion ([05dab7a](https://github.com/cedricziel/readwhere/commit/05dab7af742cb61b60334104cf3b40268367a89f))
* **library:** fix SnackBar not dismissing after book deletion ([7549d3b](https://github.com/cedricziel/readwhere/commit/7549d3b8891034da608afdd730c88a9b7b465108))
* **library:** shorten delete SnackBar duration to 2 seconds ([21b3bd5](https://github.com/cedricziel/readwhere/commit/21b3bd5b438cc00ad69c4957ffbc79d903d4ff17))
* **library:** use parent context for delete confirmation dialog ([95938c4](https://github.com/cedricziel/readwhere/commit/95938c44b2468694926787a9a47257234df45e5a))
* **reader:** use correct page index for CBR/CBZ image display ([1ff0e3d](https://github.com/cedricziel/readwhere/commit/1ff0e3d503f257a8eff413c07b8cfe3294bbaa05))

## [0.2.0](https://github.com/cedricziel/readwhere/compare/v0.1.2...v0.2.0) (2025-12-11)


### Features

* **android:** add release signing configuration ([f69c943](https://github.com/cedricziel/readwhere/commit/f69c9430b843a5847f10bcb437b9a8bc35edf06c))
* **branding:** add app logo and launcher icons ([1bf0abd](https://github.com/cedricziel/readwhere/commit/1bf0abd89da7b48a226b8820ff1be679ece378df))
* **reader:** add ESC key shortcut to exit reader ([412b9d8](https://github.com/cedricziel/readwhere/commit/412b9d8f4b100ded572fa1918c439216fbddd4ab))


### Bug Fixes

* **android:** add missing imports for Kotlin DSL build script ([5b54fb4](https://github.com/cedricziel/readwhere/commit/5b54fb4f951768a70703c73abf0d572305a9b583))
* **icons:** regenerate app icons with proper colors ([c202e60](https://github.com/cedricziel/readwhere/commit/c202e60b8893c52368d11e8daede169246108ff1))
* **reader:** add pointer event cleanup handlers ([3193437](https://github.com/cedricziel/readwhere/commit/3193437940098b645fa454b15bfa8fc5cb93e8ec))
* **reader:** add tap zones for EPUB chapter navigation ([658ffad](https://github.com/cedricziel/readwhere/commit/658ffada3aff401c3a912bb12e910d39b9318421))
* **reader:** correct TOC navigation to use href-to-spine mapping ([9ac7baf](https://github.com/cedricziel/readwhere/commit/9ac7baf76657983efd54f41e99e74334420bad0b))
* **reader:** ensure tap detection works with minimal content ([7247257](https://github.com/cedricziel/readwhere/commit/72472570cfe2e09a4c9087febc14a33ef28012c9))
* **reader:** resolve SelectionArea assertion failure on navigation ([21cb85a](https://github.com/cedricziel/readwhere/commit/21cb85a6373258b97bfd1707757ad855e5e14fbe))
* **reader:** use UnifiedPluginRegistry instead of empty PluginRegistry ([6373a7c](https://github.com/cedricziel/readwhere/commit/6373a7c6c373d0dac68c24d9d245de100f687e10))

## [0.1.2](https://github.com/cedricziel/readwhere/compare/v0.1.1...v0.1.2) (2025-12-09)


### Bug Fixes

* **ci:** disable code signing for macOS CI build ([18ee9b6](https://github.com/cedricziel/readwhere/commit/18ee9b66579251c9b03b08e9f73cef4dc1e0f2a9))

## [0.1.1](https://github.com/cedricziel/readwhere/compare/v0.1.0...v0.1.1) (2025-12-09)


### Bug Fixes

* **ci:** add libsecret-1-dev for Linux build ([25fe6a0](https://github.com/cedricziel/readwhere/commit/25fe6a0543d94aca46bd66a5a2d0792cb00157b1))

## [0.1.0](https://github.com/cedricziel/readwhere/compare/v0.0.2...v0.1.0) (2025-12-09)


### Features

* **feeds:** complete RSS feed reader with article scraping and tests ([5e3d764](https://github.com/cedricziel/readwhere/commit/5e3d764f75492d49228cb252dc344caeb91074da))
* **feeds:** implement FeedsScreen for RSS feed management ([82d3c41](https://github.com/cedricziel/readwhere/commit/82d3c4159b95e2c3e1ef16f5ca9a31174017c698))
* **feeds:** implement full RSS feed reader with article viewing ([74725c0](https://github.com/cedricziel/readwhere/commit/74725c0a2dead6f3a441df2d8f4c652dfd124c20))
* **plugin:** add unified plugin architecture (Checkpoint 1) ([a9f55c6](https://github.com/cedricziel/readwhere/commit/a9f55c602055cd18ea8ef5aeac0b36fd1d92e54b))
* **plugin:** add unified plugin validation to CatalogsProvider ([655ea95](https://github.com/cedricziel/readwhere/commit/655ea95c3f575c6fd205f6a1c6619a835ba1bc77))
* **plugin:** add UnifiedCatalogBrowsingProvider for catalog browsing ([45146e7](https://github.com/cedricziel/readwhere/commit/45146e7c5bb2eba94a88998b91910bbc8665b34a))
* **plugin:** implement PluginStorageImpl and migrate EPUB plugin (Checkpoint 2) ([e1f541b](https://github.com/cedricziel/readwhere/commit/e1f541b6e2dd79b7b94b771174ca4d8ba26c8ba8))
* **plugin:** migrate catalog plugins to unified architecture (Checkpoint 3b) ([284f0a4](https://github.com/cedricziel/readwhere/commit/284f0a40b7f2f2f42e81e923f872ca98e773efd6))
* **plugin:** migrate CBZ and CBR plugins to unified architecture (Checkpoint 3a) ([65e6843](https://github.com/cedricziel/readwhere/commit/65e684379f5ffd31ee67018ed72dcc759353c17e))
* **plugin:** register unified catalog plugins in service locator ([1e5cdec](https://github.com/cedricziel/readwhere/commit/1e5cdec1c3726bf06cd1292b89fed18d074ea79e))
* **rss:** add RSS/Atom feed and OPML support packages ([a94641f](https://github.com/cedricziel/readwhere/commit/a94641f78f6a54cbec07b1b99cfa0536a0940516))


### Bug Fixes

* **feeds:** fix RSS type parsing and add UI tests ([a0dbf3d](https://github.com/cedricziel/readwhere/commit/a0dbf3d372d358a5756cea9df818b39949b2ef5d))
* **feeds:** URL-encode article itemId to handle RSS items with URL-based IDs ([81e0c6d](https://github.com/cedricziel/readwhere/commit/81e0c6da45615b606fd2e10b8227fd50d89f0d54))

## 0.0.2 (2025-12-09)


### Features

* add automatic cover extraction for books missing covers ([780926f](https://github.com/cedricziel/readwhere/commit/780926f9d88f1e586e760028ad9ba2e39aee6937))
* add CBR support to ReaderProvider ([0747b8c](https://github.com/cedricziel/readwhere/commit/0747b8c3ccf7a510f098d440e933c3eb16b1fdfb))
* add CBR/CBZ to supported book formats ([72d2b90](https://github.com/cedricziel/readwhere/commit/72d2b908b4e98e9bf0130fdeaaf139eb2ab1440f))
* add format validation to prevent downloading unsupported file types ([aa6b9a3](https://github.com/cedricziel/readwhere/commit/aa6b9a3f29c3176dcc94c5593992907fd87fb5ec))
* add GitHub releases update checking with release-please ([a518b49](https://github.com/cedricziel/readwhere/commit/a518b49d08515bdd64177bc09b9eed9f26a1c63c))
* add HTML styling for code snippets and tables ([c67b774](https://github.com/cedricziel/readwhere/commit/c67b774adf7482d87d80e44354cc9a032b9493d7))
* add Kavita server integration via OPDS protocol ([22f2451](https://github.com/cedricziel/readwhere/commit/22f245134269be27eda012006b5ca5229c46f0ee)), closes [#1](https://github.com/cedricziel/readwhere/issues/1)
* add offline catalog caching for OPDS feeds ([74031ba](https://github.com/cedricziel/readwhere/commit/74031ba020460c4efc2640d030f1943196a2d3de))
* add readwhere_epub library (Phase 1) ([fb0a724](https://github.com/cedricziel/readwhere/commit/fb0a72407e83012b7e9aaa35948cb75c456706d8))
* adopt readwhere_plugin interfaces across codebase ([2faa324](https://github.com/cedricziel/readwhere/commit/2faa32450ec7b83cb37c0f8951501b29144472bc))
* bootstrap ReadWhere e-reader Flutter app ([c8cde7a](https://github.com/cedricziel/readwhere/commit/c8cde7aa060c86698b573d1f2e0d896c1ebf0f96))
* **cbr:** add platform-aware RAR extraction for desktop ([dd55049](https://github.com/cedricziel/readwhere/commit/dd55049043304a4e3d776816bfef64f7b50bd55a))
* **cbr:** add readwhere_cbr package for CBR comic book support ([47cc2c3](https://github.com/cedricziel/readwhere/commit/47cc2c336939779ccc6ed63fce1d71f26406544b))
* **cbz:** add CBZ plugin and improve cover extraction ([6e05649](https://github.com/cedricziel/readwhere/commit/6e0564959aaeb69a18d59bc399a4ebe882477e61))
* **cbz:** add readwhere_cbz package for comic book archives ([e58ee9e](https://github.com/cedricziel/readwhere/commit/e58ee9e8fdca3aba281caa08dc45bb4aec670bdf))
* **cbz:** complete CbzReader, validation, and testing ([78171b6](https://github.com/cedricziel/readwhere/commit/78171b688b7690b9c135c2e725e5793128c0b205))
* **epub:** add Phase 3 advanced EPUB features ([f95baaa](https://github.com/cedricziel/readwhere/commit/f95baaa7e72ff2111b9c615eae89588235397d8e))
* **epub:** implement Phase 2 enhanced features ([d789d43](https://github.com/cedricziel/readwhere/commit/d789d439b0c8803ce9f627ae840ac6682a8ce9f5))
* implement core reading experience with fallback EPUB parser ([3828301](https://github.com/cedricziel/readwhere/commit/38283019c0afca0e84dc242cdbb8082a9025b413))
* integrate Phase 2 EPUB features into app ([07727d8](https://github.com/cedricziel/readwhere/commit/07727d8468f9039037cd6f972a416998b2133042))
* integrate Phase 3 EPUB features into app ([6fa36c1](https://github.com/cedricziel/readwhere/commit/6fa36c1dcfcf239c25ca090e8c1b36f0aca1c2c0))
* integrate readwhere_epub library, remove epubx dependency ([fefd0c1](https://github.com/cedricziel/readwhere/commit/fefd0c1030c8fe4d53d00e5b1779014258302c04))
* **nextcloud:** add Nextcloud integration for browsing and downloading books ([b49acb7](https://github.com/cedricziel/readwhere/commit/b49acb7c230581d3f7d46ecc5c76cc56ba6198c4))
* **plugin:** add readwhere_plugin package with catalog provider interfaces ([77f5b4d](https://github.com/cedricziel/readwhere/commit/77f5b4d708c37ad186825f5d16c9ff456ef00d2d))
* **plugins:** extract reader plugins to standalone packages ([a3a29c3](https://github.com/cedricziel/readwhere/commit/a3a29c355f7640b1ef0c963bf738c5c8edbaeec2))
* **rar:** add pure Dart RAR 4.x archive reader package ([59022af](https://github.com/cedricziel/readwhere/commit/59022affb63b45c7c1d911879d31b70c294a04b0))
* **rar:** add RAR 4.x decompression support ([f12dfb4](https://github.com/cedricziel/readwhere/commit/f12dfb47ef7998575fbeacc3f2bf16d4fa83590a))
* **reader:** add panel detection for comic frame-by-frame reading ([92402bd](https://github.com/cedricziel/readwhere/commit/92402bdbae40f4e604d7fc9790e1aafaf7061a34))
* **reader:** add zoom/pan support for CBR/CBZ comics ([03ceb07](https://github.com/cedricziel/readwhere/commit/03ceb07d22141c3dce567071626940d17446f494))
* **reader:** enable text selection for copying and pasting ([7f89794](https://github.com/cedricziel/readwhere/commit/7f89794ae2dce4a1a920058aeb9d2749572a07f7))
* **sample-media:** add package for downloading test media ([49b8d35](https://github.com/cedricziel/readwhere/commit/49b8d35a81dc5e741eee5e9984ab32a869f109c1))
* **webdav,nextcloud:** extract WebDAV and Nextcloud into workspace packages ([7740d4f](https://github.com/cedricziel/readwhere/commit/7740d4fc77bbef9df473c7e19482155251d42e21))


### Bug Fixes

* add explicit FocusNodes to dialog to mitigate macOS keyboard bug ([4cae7be](https://github.com/cedricziel/readwhere/commit/4cae7be624678d50b9c084c0b09cd8aa49bf1b46))
* capture ScaffoldMessenger before popping dialog for delete snackbar ([bdecae9](https://github.com/cedricziel/readwhere/commit/bdecae9b96e24b44dc34403d1f05800899072e3e))
* cast OpdsLinkModel list to List&lt;OpdsLink&gt; to fix firstWhere type error ([6d99d55](https://github.com/cedricziel/readwhere/commit/6d99d55e4bbd90f2b0d3208cbd268008e3ca7b84))
* **catalogs:** defer provider call to avoid build-phase notifyListeners ([ded4063](https://github.com/cedricziel/readwhere/commit/ded406365493b06d5ece96b0f729ddc8fabae4c3))
* **cbr:** improve unrar detection and error messages ([6c346a0](https://github.com/cedricziel/readwhere/commit/6c346a045b6a70b3a49e65e33cca443922d5f878))
* **cbr:** remove unrar_file plugin dependency ([c62bae9](https://github.com/cedricziel/readwhere/commit/c62bae9446c73c7153c22b91b6a3d6c8a15fee7d))
* **cbr:** remove unrar_file plugin to fix desktop support ([20b8912](https://github.com/cedricziel/readwhere/commit/20b8912a749ee479aaab4be950fc7a28e0681892))
* **ci:** use dart pub get for pure Dart epub package ([505caa0](https://github.com/cedricziel/readwhere/commit/505caa0cb5d147aa0befad24fbb87b20bb68366b))
* **ci:** use Flutter for epub job due to workspace resolution ([e7fe799](https://github.com/cedricziel/readwhere/commit/e7fe799edd7dbc4ba935a860494ae0915b0cce73))
* epub CI ([899c09d](https://github.com/cedricziel/readwhere/commit/899c09dd99bed272bc9210e5aad3bcb2ebf8c0b8))
* improve OPDS format detection for CBR/CBZ ([ca8c705](https://github.com/cedricziel/readwhere/commit/ca8c70565b5a51f785b5fb513f9c8b7c120d8c1e))
* **ios,macos:** add keychain entitlements for secure storage ([7e549d3](https://github.com/cedricziel/readwhere/commit/7e549d397e2e6099174056bd794d601cd22463e4))
* **nextcloud:** add User-Agent header and improve error handling ([6d49474](https://github.com/cedricziel/readwhere/commit/6d49474a41a96c7c8847bbe24aa53831b0b74e26))
* prevent text overflow in OpdsEntryCard info section ([ae984ad](https://github.com/cedricziel/readwhere/commit/ae984adff67c2c7a3d4b1c7ce2cf665abf59ddc8))
* **reader:** enable tap and swipe navigation for comics without panel mode ([0b07abc](https://github.com/cedricziel/readwhere/commit/0b07abcd67cb790d3abf9b19b32771db474941c7))
* **reader:** handle base64 data URIs for CBR/CBZ images ([498f157](https://github.com/cedricziel/readwhere/commit/498f1572fb15f42bec5d1cc0b339ce5f019aea8b))
* **reader:** handle internal EPUB links for chapter navigation ([19c8723](https://github.com/cedricziel/readwhere/commit/19c8723f70c717dbf5102d30a2474d75a3461f00))
* **reader:** use getPluginForFile for magic byte detection ([3d66089](https://github.com/cedricziel/readwhere/commit/3d660894f2e72eaaa334c5f60e2e9bc53afe9352))
* render actual EPUB images instead of placeholders ([378e6c1](https://github.com/cedricziel/readwhere/commit/378e6c14301e02284857e00903f04b82b648393d))
* resolve all analyzer errors and warnings ([e95bd0f](https://github.com/cedricziel/readwhere/commit/e95bd0fd3b96d4aa10701efd9d8b13b13e4e52c9))
* use correct book ID when opening from OPDS catalog ([87abff9](https://github.com/cedricziel/readwhere/commit/87abff98af5816249115faef9cd01f43c20c20ad))
* use flutter pub run for pre-commit hook ([7a60993](https://github.com/cedricziel/readwhere/commit/7a609934bbce3e0bb5a79e64f39c8077e3697b73))


### Miscellaneous Chores

* trigger release ([ba2ce42](https://github.com/cedricziel/readwhere/commit/ba2ce429813530bc50b9442b1e4a01a340e2c999))

## Changelog
