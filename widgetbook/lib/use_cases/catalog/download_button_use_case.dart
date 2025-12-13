import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/screens/catalogs/browse/widgets/download_button.dart';

@widgetbook.UseCase(name: 'Idle', type: DownloadButton, path: '[Catalog]')
Widget buildDownloadButtonIdle(BuildContext context) {
  return Center(
    child: DownloadButton(
      isDownloading: false,
      isDownloaded: false,
      progress: 0,
      onDownload: () {
        debugPrint('Download pressed!');
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'Downloading',
  type: DownloadButton,
  path: '[Catalog]',
)
Widget buildDownloadButtonDownloading(BuildContext context) {
  return Center(
    child: DownloadButton(
      isDownloading: true,
      isDownloaded: false,
      progress: context.knobs.double.slider(
        label: 'Progress',
        initialValue: 0.45,
        min: 0,
        max: 1,
      ),
      onDownload: () {},
    ),
  );
}

@widgetbook.UseCase(name: 'Downloaded', type: DownloadButton, path: '[Catalog]')
Widget buildDownloadButtonDownloaded(BuildContext context) {
  return Center(
    child: DownloadButton(
      isDownloading: false,
      isDownloaded: true,
      progress: 1,
      onDownload: () {},
      onOpen: () {
        debugPrint('Open pressed!');
      },
    ),
  );
}

@widgetbook.UseCase(name: 'All States', type: DownloadButton, path: '[Catalog]')
Widget buildDownloadButtonAllStates(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStateRow(context, 'Idle', false, false, 0),
        const SizedBox(height: 16),
        _buildStateRow(context, 'Downloading (25%)', true, false, 0.25),
        const SizedBox(height: 16),
        _buildStateRow(context, 'Downloading (50%)', true, false, 0.50),
        const SizedBox(height: 16),
        _buildStateRow(context, 'Downloading (75%)', true, false, 0.75),
        const SizedBox(height: 16),
        _buildStateRow(context, 'Downloaded', false, true, 1),
      ],
    ),
  );
}

Widget _buildStateRow(
  BuildContext context,
  String label,
  bool isDownloading,
  bool isDownloaded,
  double progress,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 120,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      const SizedBox(width: 16),
      DownloadButton(
        isDownloading: isDownloading,
        isDownloaded: isDownloaded,
        progress: progress,
        onDownload: () {},
        onOpen: () {},
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Idle', type: DownloadIconButton, path: '[Catalog]')
Widget buildDownloadIconButtonIdle(BuildContext context) {
  return Center(
    child: DownloadIconButton(
      isDownloading: false,
      isDownloaded: false,
      progress: 0,
      onDownload: () {
        debugPrint('Download pressed!');
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'Downloading',
  type: DownloadIconButton,
  path: '[Catalog]',
)
Widget buildDownloadIconButtonDownloading(BuildContext context) {
  return Center(
    child: DownloadIconButton(
      isDownloading: true,
      isDownloaded: false,
      progress: context.knobs.double.slider(
        label: 'Progress',
        initialValue: 0.65,
        min: 0,
        max: 1,
      ),
      onDownload: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Downloaded',
  type: DownloadIconButton,
  path: '[Catalog]',
)
Widget buildDownloadIconButtonDownloaded(BuildContext context) {
  return Center(
    child: DownloadIconButton(
      isDownloading: false,
      isDownloaded: true,
      progress: 1,
      onDownload: () {},
      onOpen: () {
        debugPrint('Open pressed!');
      },
    ),
  );
}

@widgetbook.UseCase(
  name: 'All States',
  type: DownloadIconButton,
  path: '[Catalog]',
)
Widget buildDownloadIconButtonAllStates(BuildContext context) {
  return Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DownloadIconButton(
              isDownloading: false,
              isDownloaded: false,
              progress: 0,
              onDownload: () {},
            ),
            const SizedBox(height: 8),
            Text('Idle', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DownloadIconButton(
              isDownloading: true,
              isDownloaded: false,
              progress: 0.5,
              onDownload: () {},
            ),
            const SizedBox(height: 8),
            Text('Downloading', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DownloadIconButton(
              isDownloading: false,
              isDownloaded: true,
              progress: 1,
              onDownload: () {},
              onOpen: () {},
            ),
            const SizedBox(height: 8),
            Text('Downloaded', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    ),
  );
}
