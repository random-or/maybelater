import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static const String databaseName = 'maybelater.db';
  static const int databaseVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  Future<Database> initDatabase({String? pathOverride}) async {
    String path;
    if (pathOverride != null) {
      path = pathOverride;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, databaseName);
    }

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _migrate(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _migrate(db, oldVersion, newVersion);
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      if (i == 1) {
        await _migration1(db);
      }
    }
  }

  Future<void> _migration1(Database db) async {
    // 1. collections table
    await db.execute('''
      CREATE TABLE collections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT DEFAULT '',
          color TEXT DEFAULT '#7C3AED',
          icon TEXT DEFAULT 'folder',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
      )
    ''');

    // 2. screenshots table
    await db.execute('''
      CREATE TABLE screenshots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          filepath TEXT NOT NULL UNIQUE,
          thumbnail_path TEXT,
          original_uri TEXT,
          filename TEXT DEFAULT '',
          ocr_text TEXT DEFAULT '',
          ai_labels TEXT DEFAULT '[]',
          manual_tags TEXT DEFAULT '[]',
          collection_id INTEGER,
          source TEXT DEFAULT 'import',
          created_at INTEGER NOT NULL,
          imported_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          file_size INTEGER DEFAULT 0,
          width INTEGER DEFAULT 0,
          height INTEGER DEFAULT 0,
          content_hash TEXT,
          processing_status TEXT DEFAULT 'pending',
          processing_error TEXT DEFAULT '',
          is_deleted INTEGER DEFAULT 0,
          deleted_at INTEGER,
          is_favorite INTEGER DEFAULT 0,
          FOREIGN KEY (collection_id) REFERENCES collections(id)
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_screenshots_hash
      ON screenshots(content_hash)
      WHERE content_hash IS NOT NULL
    ''');

    await db.execute('''
      CREATE INDEX idx_screenshots_created
      ON screenshots(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_screenshots_collection
      ON screenshots(collection_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_screenshots_deleted
      ON screenshots(is_deleted)
    ''');

    await db.execute('''
      CREATE INDEX idx_screenshots_status
      ON screenshots(processing_status)
    ''');

    // 3. tags tables
    await db.execute('''
      CREATE TABLE tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          usage_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE screenshot_tags (
          screenshot_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (screenshot_id, tag_id),
          FOREIGN KEY (screenshot_id) REFERENCES screenshots(id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // 4. search_history table
    await db.execute('''
      CREATE TABLE search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL,
          searched_at INTEGER NOT NULL
      )
    ''');

    // 5. FTS5 table
    await db.execute('''
      CREATE VIRTUAL TABLE screenshots_fts USING fts5(
          ocr_text,
          ai_labels,
          manual_tags,
          content='screenshots',
          content_rowid='id',
          tokenize='unicode61'
      )
    ''');

    // FTS triggers
    await db.execute('''
      CREATE TRIGGER screenshots_ai AFTER INSERT ON screenshots
      BEGIN
          INSERT INTO screenshots_fts(rowid, ocr_text, ai_labels, manual_tags)
          VALUES (new.id, new.ocr_text, new.ai_labels, new.manual_tags);
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER screenshots_ad AFTER DELETE ON screenshots
      BEGIN
          INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, ai_labels, manual_tags)
          VALUES ('delete', old.id, old.ocr_text, old.ai_labels, old.manual_tags);
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER screenshots_au AFTER UPDATE ON screenshots
      BEGIN
          INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, ai_labels, manual_tags)
          VALUES ('delete', old.id, old.ocr_text, old.ai_labels, old.manual_tags);
          
          INSERT INTO screenshots_fts(rowid, ocr_text, ai_labels, manual_tags)
          VALUES (new.id, new.ocr_text, new.ai_labels, new.manual_tags);
      END;
    ''');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Truncate method solely for integration testing (avoids deleting the DB entirely)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('DELETE FROM screenshot_tags');
      await txn.execute('DELETE FROM tags');
      await txn.execute('DELETE FROM screenshots');
      await txn.execute('DELETE FROM collections');
      await txn.execute('DELETE FROM search_history');
      // No need to delete from FTS directly if triggers are in place, but we must delete FTS tables just in case, wait, DELETE ON screenshots will trigger FTS delete!
    });
  }

  Future<void> rebuildFts() async {
    final db = await database;
    await db.execute(
      "INSERT INTO screenshots_fts(screenshots_fts) VALUES('rebuild')",
    );
  }
}
