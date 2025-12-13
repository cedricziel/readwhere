import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/reading_settings.dart';
import '../../../providers/reader_provider.dart';
import '../../../themes/reading_themes.dart';

/// Bottom sheet for adjusting reading settings
///
/// Allows users to customize:
/// - Font size (12-32)
/// - Font family
/// - Line height (1.0-2.5)
/// - Margins
/// - Theme (light/dark/sepia)
///
/// Changes are applied in real-time with a preview.
class ReadingSettingsSheet extends StatefulWidget {
  const ReadingSettingsSheet({super.key});

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet> {
  late ReadingSettings _tempSettings;

  @override
  void initState() {
    super.initState();
    _tempSettings = context.read<ReaderProvider>().settings;
  }

  void _updateSettings(ReadingSettings newSettings) {
    setState(() {
      _tempSettings = newSettings;
    });
    // Apply settings to provider immediately for live preview
    context.read<ReaderProvider>().updateSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final readingTheme = ReadingThemes.fromSettings(_tempSettings);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.text_format, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Reading Settings',
                  style: TextStyle(
                    // Use textScaler for accessibility
                    fontSize: MediaQuery.textScalerOf(context).scale(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview text
                  _buildPreview(readingTheme),
                  const SizedBox(height: 24),

                  // Theme selector
                  _buildThemeSelector(),
                  const SizedBox(height: 24),

                  // Font size
                  _buildFontSizeControl(),
                  const SizedBox(height: 24),

                  // Font family
                  _buildFontFamilyControl(),
                  const SizedBox(height: 24),

                  // Line height
                  _buildLineHeightControl(),
                  const SizedBox(height: 24),

                  // Margins
                  _buildMarginControl(),
                  const SizedBox(height: 16),

                  // Reset button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        _updateSettings(ReadingSettings.defaults());
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ReadingThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        'The quick brown fox jumps over the lazy dog. '
        'This is a preview of your reading settings.',
        style: TextStyle(
          fontFamily: theme.fontFamily,
          fontSize: theme.fontSize,
          height: theme.lineHeight,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: TextStyle(
            fontSize: textScaler.scale(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeOption(
              ReadingTheme.light,
              'Light',
              Colors.white,
              Colors.black,
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              ReadingTheme.dark,
              'Dark',
              const Color(0xFF1E1E1E),
              Colors.white,
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              ReadingTheme.sepia,
              'Sepia',
              const Color(0xFFF4ECD8),
              const Color(0xFF5F4B32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    ReadingTheme theme,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    final isSelected = _tempSettings.theme == theme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _updateSettings(_tempSettings.copyWith(theme: theme));
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.text_fields, color: textColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  // Use textScaler for accessibility
                  fontSize: MediaQuery.textScalerOf(context).scale(12),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeControl() {
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: TextStyle(
                fontSize: textScaler.scale(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_tempSettings.fontSize.toInt()}',
              style: TextStyle(
                fontSize: textScaler.scale(14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.text_decrease, size: 20),
            Expanded(
              child: Slider(
                value: _tempSettings.fontSize,
                min: 12,
                max: 32,
                divisions: 20,
                onChanged: (value) {
                  _updateSettings(_tempSettings.copyWith(fontSize: value));
                },
              ),
            ),
            const Icon(Icons.text_increase, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildFontFamilyControl() {
    final textScaler = MediaQuery.textScalerOf(context);
    final fontFamilies = [
      'Georgia',
      'Merriweather',
      'Inter',
      'Arial',
      'Times New Roman',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Family',
          style: TextStyle(
            fontSize: textScaler.scale(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tempSettings.fontFamily,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: fontFamilies.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _updateSettings(_tempSettings.copyWith(fontFamily: value));
            }
          },
        ),
      ],
    );
  }

  Widget _buildLineHeightControl() {
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Line Height',
              style: TextStyle(
                fontSize: textScaler.scale(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _tempSettings.lineHeight.toStringAsFixed(1),
              style: TextStyle(
                fontSize: textScaler.scale(14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _tempSettings.lineHeight,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          onChanged: (value) {
            _updateSettings(_tempSettings.copyWith(lineHeight: value));
          },
        ),
      ],
    );
  }

  Widget _buildMarginControl() {
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Margins',
              style: TextStyle(
                fontSize: textScaler.scale(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_tempSettings.marginHorizontal.toInt()}',
              style: TextStyle(
                fontSize: textScaler.scale(14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _tempSettings.marginHorizontal,
          min: 0,
          max: 48,
          divisions: 12,
          onChanged: (value) {
            _updateSettings(
              _tempSettings.copyWith(
                marginHorizontal: value,
                marginVertical: value * 1.5,
              ),
            );
          },
        ),
      ],
    );
  }
}
