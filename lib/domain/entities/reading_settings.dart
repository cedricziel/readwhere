import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Available reading themes
enum ReadingTheme { light, dark, sepia }

/// Represents user reading preferences and settings
class ReadingSettings extends Equatable {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double marginHorizontal;
  final double marginVertical;
  final ReadingTheme theme;
  final TextAlign textAlign;

  const ReadingSettings({
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.marginHorizontal,
    required this.marginVertical,
    required this.theme,
    required this.textAlign,
  });

  /// Factory constructor with default values
  factory ReadingSettings.defaults() {
    return const ReadingSettings(
      fontSize: 16.0,
      fontFamily: 'Georgia',
      lineHeight: 1.5,
      marginHorizontal: 16.0,
      marginVertical: 24.0,
      theme: ReadingTheme.light,
      textAlign: TextAlign.justify,
    );
  }

  /// Creates a copy of this ReadingSettings with the given fields replaced
  ReadingSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? marginHorizontal,
    double? marginVertical,
    ReadingTheme? theme,
    TextAlign? textAlign,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      marginHorizontal: marginHorizontal ?? this.marginHorizontal,
      marginVertical: marginVertical ?? this.marginVertical,
      theme: theme ?? this.theme,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  @override
  List<Object?> get props => [
    fontSize,
    fontFamily,
    lineHeight,
    marginHorizontal,
    marginVertical,
    theme,
    textAlign,
  ];

  @override
  String toString() {
    return 'ReadingSettings(fontSize: $fontSize, fontFamily: $fontFamily, '
        'theme: $theme, textAlign: $textAlign)';
  }
}
