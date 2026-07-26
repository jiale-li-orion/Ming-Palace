import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../shared/app_error.dart';
import '../shared/result.dart';

/// Data export service for telemetry logs.
///
/// Reads all events from the JSONL telemetry file and writes a formatted JSON
/// array to disk, then optionally shares it via the system share sheet.
class ExportService {
  static const String _telemetryFileName = 'telemetry.jsonl';

  /// Reads every event from the telemetry file and writes a pretty-printed
  /// JSON array to [filePath].  Returns the same [filePath] on success.
  Future<Result<String, AppError>> exportAsJson(
    String filePath, {
    String? sessionId,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final telemetryFile = File('${dir.path}/$_telemetryFileName');

      final List<Map<String, dynamic>> events;
      if (await telemetryFile.exists()) {
        final lines = await telemetryFile.readAsLines();
        final allEvents = lines
            .where((l) => l.trim().isNotEmpty)
            .map((l) => json.decode(l) as Map<String, dynamic>)
            .toList();
        events = sessionId == null
            ? allEvents
            : allEvents
                .where((event) => event['sessionId'] == sessionId)
                .toList();
      } else {
        events = [];
      }

      final exportFile = File(filePath);
      await exportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(events),
      );

      return Ok(filePath);
    } catch (_) {
      return Err(AppError.exportFailed);
    }
  }

  /// Shares the export file located at [filePath] through the OS share sheet.
  Future<Result<void, AppError>> shareExport(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([file]);
      return Ok(null);
    } catch (_) {
      return Err(AppError.exportFailed);
    }
  }
}
