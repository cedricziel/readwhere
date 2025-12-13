import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/presentation/screens/catalogs/widgets/nextcloud_folder_picker_dialog.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import 'nextcloud_folder_picker_dialog_test.mocks.dart';

@GenerateMocks([NextcloudClient, NextcloudCredentialStorage])
void main() {
  late MockNextcloudClient mockClient;
  late MockNextcloudCredentialStorage mockStorage;

  setUp(() {
    mockClient = MockNextcloudClient();
    mockStorage = MockNextcloudCredentialStorage();

    // Reset and register mock in GetIt
    final getIt = GetIt.instance;
    if (getIt.isRegistered<NextcloudClient>()) {
      getIt.unregister<NextcloudClient>();
    }
    if (getIt.isRegistered<NextcloudCredentialStorage>()) {
      getIt.unregister<NextcloudCredentialStorage>();
    }
    getIt.registerSingleton<NextcloudClient>(mockClient);
    getIt.registerSingleton<NextcloudCredentialStorage>(mockStorage);
  });

  tearDown(() async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<NextcloudClient>()) {
      getIt.unregister<NextcloudClient>();
    }
    if (getIt.isRegistered<NextcloudCredentialStorage>()) {
      getIt.unregister<NextcloudCredentialStorage>();
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
                builder: (context) => const NextcloudFolderPickerDialog(
                  serverUrl: 'https://cloud.example.com',
                  userId: 'testuser',
                  username: 'testuser',
                  appPassword: 'testpassword',
                  initialPath: '/',
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

  group('NextcloudFolderPickerDialog', () {
    group('rendering', () {
      testWidgets('displays dialog title', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        expect(find.text('Select Starting Folder'), findsOneWidget);
      });

      testWidgets('displays New Folder button', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
        expect(find.byTooltip('New Folder'), findsOneWidget);
      });

      testWidgets('displays Cancel and Select buttons', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Select This Folder'), findsOneWidget);
      });

      testWidgets('disables New Folder button while loading', (tester) async {
        final completer = Completer<List<NextcloudFile>>();

        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
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
        completer.complete(<NextcloudFile>[]);
        await tester.pumpAndSettle();
      });
    });

    group('breadcrumbs', () {
      testWidgets('displays Home for root path', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        expect(find.text('Home'), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('shows empty state when folder has no subfolders', (
        tester,
      ) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        expect(find.text('No subfolders'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error state when loading fails', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenThrow(Exception('Network error'));

        await openDialogAndWait(tester);

        expect(find.text('Failed to load folder'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    // Put folder creation tests last since they can affect widget state
    group('folder creation dialog', () {
      testWidgets('opens create folder dialog when button tapped', (
        tester,
      ) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        expect(find.text('New Folder'), findsOneWidget);
        expect(find.text('Folder name'), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('validates empty folder name', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a folder name'), findsOneWidget);
      });

      testWidgets('validates folder name with slash', (tester) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'folder/name');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Folder name cannot contain /'), findsOneWidget);
      });

      // This test verifies that createDirectoryWithCredentials is called with correct params
      testWidgets('calls createDirectoryWithCredentials on create', (
        tester,
      ) async {
        when(
          mockClient.listDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async => <NextcloudFile>[]);

        when(
          mockClient.createDirectoryWithCredentials(
            serverUrl: anyNamed('serverUrl'),
            userId: anyNamed('userId'),
            username: anyNamed('username'),
            password: anyNamed('password'),
            path: anyNamed('path'),
          ),
        ).thenAnswer((_) async {});

        await openDialogAndWait(tester);

        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();

        // Use runAsync for text entry to avoid caret scheduling issues
        await tester.runAsync(() async {
          await tester.enterText(find.byType(TextFormField), 'MyNewFolder');
        });
        await tester.pump();

        await tester.tap(find.text('Create'));
        // Use runAsync to let the async operation complete
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });

        // Verify the method was called with correct parameters
        verify(
          mockClient.createDirectoryWithCredentials(
            serverUrl: 'https://cloud.example.com',
            userId: 'testuser',
            username: 'testuser',
            password: 'testpassword',
            path: '/MyNewFolder',
          ),
        ).called(1);
      });
    });
  });
}
