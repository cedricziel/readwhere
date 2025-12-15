import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/presentation/screens/catalogs/widgets/synology_folder_picker_dialog.dart';
import 'package:readwhere/presentation/widgets/adaptive/adaptive_text_field.dart';
import 'package:readwhere_synology/readwhere_synology.dart';

import '../../../../helpers/test_helpers.dart';
import 'synology_folder_picker_dialog_test.mocks.dart';

/// Finder for text input fields that works with both Material and Cupertino.
/// AdaptiveTextField renders differently on different platforms, so we find
/// the EditableText widget which is the common underlying widget.
Finder findTextInput() {
  return find.byType(EditableText);
}

@GenerateMocks([SynologyClient, SynologySessionStorage])
void main() {
  late MockSynologyClient mockClient;
  late MockSynologySessionStorage mockStorage;

  setUp(() {
    mockClient = MockSynologyClient();
    mockStorage = MockSynologySessionStorage();

    // Reset and register mock in GetIt
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SynologyClient>()) {
      getIt.unregister<SynologyClient>();
    }
    if (getIt.isRegistered<SynologySessionStorage>()) {
      getIt.unregister<SynologySessionStorage>();
    }
    getIt.registerSingleton<SynologyClient>(mockClient);
    getIt.registerSingleton<SynologySessionStorage>(mockStorage);

    // Default mock behavior for authenticate
    when(
      mockClient.authenticate(
        catalogId: anyNamed('catalogId'),
        serverUrl: anyNamed('serverUrl'),
        account: anyNamed('account'),
        password: anyNamed('password'),
      ),
    ).thenAnswer(
      (_) async => SynologySession(
        catalogId: 'test',
        serverUrl: 'https://nas.example.com',
        sessionId: 'test-session',
        deviceId: 'test-device',
        createdAt: DateTime.now(),
      ),
    );

    // Default mock behavior for clearCredentials
    when(mockClient.clearCredentials(any)).thenAnswer((_) async {});
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SynologyClient>()) {
      getIt.unregister<SynologyClient>();
    }
    if (getIt.isRegistered<SynologySessionStorage>()) {
      getIt.unregister<SynologySessionStorage>();
    }
    // Small delay to ensure cleanup
    await Future<void>.delayed(Duration.zero);
  });

  Widget buildTestDialog() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SynologyFolderPickerDialog(
                  serverUrl: 'https://nas.example.com',
                  username: 'testuser',
                  password: 'testpassword',
                  initialPath: '/mydrive',
                ),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  Future<void> openDialogAndWait(WidgetTester tester) async {
    await tester.pumpWidget(buildTestDialog());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
  }

  group('SynologyFolderPickerDialog', () {
    group('rendering', () {
      testWidgets('displays dialog title', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        expect(find.text('Select Starting Folder'), findsOneWidget);
      });

      testWidgets('displays New Folder button', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
        expect(find.byTooltip('New Folder'), findsOneWidget);
      });

      testWidgets('displays Cancel and Select buttons', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Select This Folder'), findsOneWidget);
      });

      testWidgets('disables New Folder button while loading', (tester) async {
        final completer = Completer<ListResult>();

        when(
          mockClient.listDirectory(any, any),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestDialog());
        await tester.tap(find.text('Open Dialog'));
        await tester.pump();
        await tester.pump();

        final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.create_new_folder_outlined),
        );
        expect(iconButton.onPressed, isNull);

        // Complete the future to avoid pending timer
        completer.complete(ListResult(success: true, items: [], total: 0));
        await tester.pumpAndSettle();
      });
    });

    group('breadcrumbs', () {
      testWidgets('displays My Drive for root path', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        expect(find.text('My Drive'), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows empty state when folder has no subfolders', (
        tester,
      ) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        expect(find.text('No subfolders'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error state when loading fails', (tester) async {
        when(
          mockClient.listDirectory(any, any),
        ).thenThrow(Exception('Network error'));

        await openDialogAndWait(tester);

        expect(find.text('Failed to load folder'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('folder list', () {
      testWidgets('displays folders from API response', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(
            success: true,
            items: [
              SynologyFile(
                fileId: '1',
                name: 'Books',
                path: '/mydrive/Books',
                displayPath: '/mydrive/Books',
                type: 'dir',
              ),
              SynologyFile(
                fileId: '2',
                name: 'Documents',
                path: '/mydrive/Documents',
                displayPath: '/mydrive/Documents',
                type: 'dir',
              ),
            ],
            total: 2,
          ),
        );

        await openDialogAndWait(tester);

        expect(find.text('Books'), findsOneWidget);
        expect(find.text('Documents'), findsOneWidget);
      });

      testWidgets('filters out files (only shows directories)', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(
            success: true,
            items: [
              SynologyFile(
                fileId: '1',
                name: 'Books',
                path: '/mydrive/Books',
                displayPath: '/mydrive/Books',
                type: 'dir',
              ),
              SynologyFile(
                fileId: '2',
                name: 'readme.txt',
                path: '/mydrive/readme.txt',
                displayPath: '/mydrive/readme.txt',
                type: 'file',
              ),
            ],
            total: 2,
          ),
        );

        await openDialogAndWait(tester);

        expect(find.text('Books'), findsOneWidget);
        expect(find.text('readme.txt'), findsNothing);
      });
    });

    group('folder creation dialog', () {
      testWidgets('opens create folder dialog when button tapped', (
        tester,
      ) async {
        await setTestScreenSize(tester);
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        expect(find.text('New Folder'), findsOneWidget);
        expect(find.byType(AdaptiveTextField), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('validates empty folder name', (tester) async {
        await setTestScreenSize(tester);
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a folder name'), findsOneWidget);
      });

      testWidgets('validates folder name with slash', (tester) async {
        await setTestScreenSize(tester);
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        await tester.enterText(findTextInput(), 'folder/name');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Folder name cannot contain /'), findsOneWidget);
      });

      testWidgets('calls createFolder on create', (tester) async {
        await setTestScreenSize(tester);
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        when(mockClient.createFolder(any, any)).thenAnswer(
          (_) async => SynologyFile(
            fileId: 'new',
            name: 'MyNewFolder',
            path: '/mydrive/MyNewFolder',
            displayPath: '/mydrive/MyNewFolder',
            type: 'dir',
          ),
        );

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await tester.enterText(findTextInput(), 'MyNewFolder');
        });
        await tester.pump();

        await tester.tap(find.text('Create'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });

        verify(
          mockClient.createFolder(
            'synology-folder-picker-temp',
            '/mydrive/MyNewFolder',
          ),
        ).called(1);
      });
    });

    group('session management', () {
      testWidgets('authenticates on init', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        verify(
          mockClient.authenticate(
            catalogId: 'synology-folder-picker-temp',
            serverUrl: 'https://nas.example.com',
            account: 'testuser',
            password: 'testpassword',
          ),
        ).called(1);
      });

      testWidgets('clears credentials on cancel', (tester) async {
        when(mockClient.listDirectory(any, any)).thenAnswer(
          (_) async => ListResult(success: true, items: [], total: 0),
        );

        await openDialogAndWait(tester);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verify(
          mockClient.clearCredentials('synology-folder-picker-temp'),
        ).called(1);
      });
    });
  });
}
