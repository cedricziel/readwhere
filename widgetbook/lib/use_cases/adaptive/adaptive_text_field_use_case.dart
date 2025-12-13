import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/adaptive/adaptive_text_field.dart';

@widgetbook.UseCase(
  name: 'Basic Text Field',
  type: AdaptiveTextField,
  path: '[Adaptive]',
)
Widget buildAdaptiveTextField(BuildContext context) {
  final showPrefix = context.knobs.boolean(
    label: 'Show Prefix Icon',
    initialValue: false,
  );

  final showSuffix = context.knobs.boolean(
    label: 'Show Suffix Icon',
    initialValue: false,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: AdaptiveTextField(
              placeholder: 'Enter your name',
              label: 'Name',
              prefixIcon: showPrefix ? Icons.person : null,
              suffixIcon: showSuffix ? Icons.check_circle : null,
              onChanged: (value) => debugPrint('Changed: $value'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive text field',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: TextField\n'
            '• Cupertino: CupertinoTextField',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Password Field',
  type: AdaptiveTextField,
  path: '[Adaptive]',
)
Widget buildAdaptivePasswordField(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: AdaptiveTextField(
              placeholder: 'Enter your password',
              label: 'Password',
              obscureText: true,
              prefixIcon: Icons.lock,
              onChanged: (value) => debugPrint('Password changed'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Password input with obscured text',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Multiline Field',
  type: AdaptiveTextField,
  path: '[Adaptive]',
)
Widget buildAdaptiveMultilineField(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: AdaptiveTextField(
              placeholder: 'Enter a description...',
              label: 'Description',
              maxLines: 4,
              minLines: 2,
              onChanged: (value) => debugPrint('Description changed'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Multiline text input',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Search Field',
  type: AdaptiveSearchField,
  path: '[Adaptive]',
)
Widget buildAdaptiveSearchField(BuildContext context) {
  final autofocus = context.knobs.boolean(
    label: 'Autofocus',
    initialValue: false,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: AdaptiveSearchField(
              placeholder: 'Search books...',
              autofocus: autofocus,
              onChanged: (value) => debugPrint('Search: $value'),
              onSubmitted: (value) => debugPrint('Search submitted: $value'),
              onClear: () => debugPrint('Search cleared'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Platform-adaptive search field',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Material: TextField with search styling\n'
            '• Cupertino: CupertinoSearchTextField',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Disabled Field',
  type: AdaptiveTextField,
  path: '[Adaptive]',
)
Widget buildAdaptiveDisabledField(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: AdaptiveTextField(
              placeholder: 'Cannot edit',
              label: 'Disabled Field',
              enabled: false,
              controller: TextEditingController(text: 'Read-only value'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Disabled/read-only text field',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Form Gallery',
  type: AdaptiveTextField,
  path: '[Adaptive]',
)
Widget buildAdaptiveFormGallery(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Form Gallery',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const AdaptiveTextField(
              label: 'Email',
              placeholder: 'you@example.com',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const AdaptiveTextField(
              label: 'Password',
              placeholder: 'Enter password',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const AdaptiveTextField(
              label: 'Phone',
              placeholder: '+1 (555) 123-4567',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const AdaptiveSearchField(placeholder: 'Search...'),
            const SizedBox(height: 24),
            Text(
              'All fields adapt to platform styling',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
