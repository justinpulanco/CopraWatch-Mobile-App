import 'package:intl/intl.dart';
import '../../models/batch_model.dart';
import '../../database/models/scan_result.dart';

/// Exports batch data to CSV format
class CSVExporter {
  /// Generate CSV content from batch
  static String generateBatchCSV(Batch batch, List<ScanResult> scanResults) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('COPRAWATCH BATCH EXPORT');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');
    
    // Batch Info
    buffer.writeln('BATCH INFORMATION');
    buffer.writeln('Batch ID,${batch.id}');
    buffer.writeln('Batch Name,${batch.name}');
    buffer.writeln('Start Date,${DateFormat('yyyy-MM-dd HH:mm:ss').format(batch.startDate)}');
    if (batch.endDate != null) {
      buffer.writeln('End Date,${DateFormat('yyyy-MM-dd HH:mm:ss').format(batch.endDate!)}');
    }
    buffer.writeln('Status,${batch.status}');
    buffer.writeln('Initial Moisture Condition,${batch.initialMoistureStatus}');
    buffer.writeln('Final Moisture Condition,${batch.finalMoistureStatus}');
    buffer.writeln('Duration (hours),${batch.dryingDuration.inHours}');
    buffer.writeln('');
    
    // Quality Results
    buffer.writeln('QUALITY ASSESSMENT');
    buffer.writeln('Quality Result,${batch.qualityResult ?? 'N/A'}');
    buffer.writeln('Confidence,${batch.confidence != null ? '${(batch.confidence! * 100).toStringAsFixed(2)}%' : 'N/A'}');
    buffer.writeln('');
    
    // Scan Results Header
    buffer.writeln('SCAN HISTORY');
    buffer.writeln('Timestamp,Classification,Confidence,Moisture Status');
    
    // Scan Results Data
    for (var result in scanResults) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(result.timestamp)},'
        '${result.classification},'
        '${(result.confidence * 100).toStringAsFixed(2)}%,'
        '${result.moistureStatus}'
      );
    }
    
    return buffer.toString();
  }
  
  /// Generate CSV for all batches summary
  static String generateAllBatchesCSV(List<Batch> batches) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('COPRAWATCH ALL BATCHES SUMMARY');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');
    
    // Column headers
    buffer.writeln('Batch ID,Batch Name,Start Date,End Date,Status,Initial Condition,Final Condition,Duration (hrs),Quality Result,Confidence');
    
    // Data rows
    for (var batch in batches) {
      buffer.writeln(
        '${batch.id},'
        '"${batch.name}",'
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(batch.startDate)},'
        '${batch.endDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(batch.endDate!) : ''},'
        '${batch.status},'
        '${batch.initialMoistureStatus},'
        '${batch.finalMoistureStatus},'
        '${batch.dryingDuration.inHours},'
        '${batch.qualityResult ?? 'N/A'},'
        '${batch.confidence != null ? (batch.confidence! * 100).toStringAsFixed(2) : 'N/A'}'
      );
    }
    
    return buffer.toString();
  }
  
  /// Get filename for export
  static String getExportFilename({bool allBatches = false}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return allBatches 
      ? 'copra_batches_all_$timestamp.csv'
      : 'copra_batch_$timestamp.csv';
  }
}
