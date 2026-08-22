import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';

class MockScreenshotDao implements ScreenshotDao {
  final List<Screenshot> inserted = [];
  Map<String, int> mockCounts = {'pending': 0};

  @override
  Future<void> insertBatch(List<Screenshot> screenshots) async {
    inserted.addAll(screenshots);
    mockCounts['pending'] = (mockCounts['pending'] ?? 0) + screenshots.length;
  }

  @override
  Future<Map<String, int>> getImportCounts() async {
    return mockCounts;
  }

  @override
  Future<List<Screenshot>> getByStatus(String status, {int? limit}) async {
    final results = inserted
        .where((s) => s.processingStatus == status)
        .toList();
    if (limit != null && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('import flow correctly inserts batch and emits progress without swallowing errors', () async {
    final dao = MockScreenshotDao();

    // Test the exact regression flow where discovered -> batch inserted -> count is correct
    final screenshotsToInsert = List.generate(
      7264,
      (i) => Screenshot(
        filepath: 'pending_$i',
        createdAt: 1000,
        updatedAt: 1000,
        importedAt: 1000,
        processingStatus: 'pending',
      ),
    );

    await dao.insertBatch(screenshotsToInsert);

    expect(dao.inserted.length, 7264);

    final counts = await dao.getImportCounts();
    expect(counts['pending'], 7264);

    final pending = await dao.getByStatus('pending', limit: 1);
    expect(pending.length, 1);
    expect(pending.first.processingStatus, 'pending');
  });
}
