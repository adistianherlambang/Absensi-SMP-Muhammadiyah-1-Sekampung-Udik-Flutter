import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';

class FileDownloadHelper {
  /// Menyimpan byte data ke Folder Downloads Publik di Android / Desktop / iOS
  static Future<String?> saveToPublicDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      String targetPath = '';

      if (Platform.isAndroid) {
        // Coba akses folder Downloads publik Android: /storage/emulated/0/Download
        final downloadDir = Directory('/storage/emulated/0/Download');
        try {
          if (await downloadDir.exists()) {
            targetPath = '${downloadDir.path}/$fileName';
            final file = File(targetPath);
            await file.create(recursive: true);
            await file.writeAsBytes(bytes);
            return targetPath;
          }
        } catch (_) {
          // Fallback jika Scoped Storage Android 10+ menolak penulisan langsung
        }

        // Fallback jika direktori publik tidak langsung dapat ditulis
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          targetPath = '${extDir.path}/$fileName';
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          targetPath = '${appDocDir.path}/$fileName';
        }

        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return targetPath;
      } else if (Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        targetPath = '${docDir.path}/$fileName';
        final file = File(targetPath);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return targetPath;
      } else {
        // Desktop (macOS, Windows, Linux)
        String? selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Pilih lokasi penyimpanan berkas ($fileName):',
          fileName: fileName,
        );

        if (selectedPath != null) {
          final file = File(selectedPath);
          await file.create(recursive: true);
          await file.writeAsBytes(bytes);
          return selectedPath;
        }
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mengubah path teknis sistem menjadi teks yang ramah pengguna
  static String getUserFriendlyPath(String path) {
    if (path.contains('/Download/') || path.endsWith('/Download')) {
      final fileName = path.split('/').last;
      return 'Folder Download HP ($fileName)';
    } else {
      final fileName = path.split('/').last;
      return 'Penyimpanan HP ($fileName)';
    }
  }

  /// Membagikan berkas via Share Sheet HP / OS
  static Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subjectText,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      final xFile = XFile(
        tempFile.path,
        mimeType: mimeType,
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        text: subjectText ?? 'Berbagikan $fileName',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Membuat berkas ZIP dari kumpulan file PNG / Data (misal Kartu QR Siswa per Kelas)
  static Uint8List createZipArchive(Map<String, Uint8List> filesMap) {
    final archive = Archive();

    filesMap.forEach((fileName, bytes) {
      final archiveFile = ArchiveFile(fileName, bytes.length, bytes);
      archive.addFile(archiveFile);
    });

    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);
    return Uint8List.fromList(zipBytes!);
  }
}
