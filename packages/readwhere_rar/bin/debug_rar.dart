// ignore_for_file: avoid_print
import 'dart:io';
import 'package:readwhere_rar/readwhere_rar.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/debug_rar.dart <file.rar>');
    exit(1);
  }

  final a = await RarArchive.fromFile(args[0]);
  print('Files: ${a.fileCount}');

  if (a.files.isNotEmpty) {
    final first = a.files.first;
    print('\nFirst file: ${first.path}');
    print('  Data offset: ${first.dataOffset}');
    print('  Packed size: ${first.packedSize}');
    print('  Method: ${first.compressionMethod}');
    print('  Method name: ${first.compressionMethodName}');

    // Read first 16 bytes of compressed data
    final bytes = File(args[0]).readAsBytesSync();
    final start = first.dataOffset;
    print('\nFirst 16 bytes of compressed data (hex):');
    for (var i = 0; i < 16 && start + i < bytes.length; i++) {
      print(
          '  Byte $i: 0x${bytes[start + i].toRadixString(16).padLeft(2, '0')} = ${bytes[start + i].toRadixString(2).padLeft(8, '0')}');
    }

    // The first byte after alignment should tell us the mode
    // Bit 0 (first bit read) = PPM flag
    // Bit 1 = discard table flag
    final firstByte = bytes[start];
    print('\nFirst byte: 0x${firstByte.toRadixString(16)}');
    print('  Bit 7 (MSB): ${(firstByte >> 7) & 1} - this is PPM flag');
    print('  Bit 6: ${(firstByte >> 6) & 1} - this is discard table flag');
  }
}
