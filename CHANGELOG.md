# Changelog

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
