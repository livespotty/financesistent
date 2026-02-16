import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

// Tables
/// Database table for managing financial accounts.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get role => text().nullable()();
  TextColumn get currencyCode => text()();
  RealColumn get currentBalance => real()();
  RealColumn get openingBalance => real()();
  TextColumn get notes => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for managing financial transactions.
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text()();
  TextColumn get sourceAccountId => text()();
  TextColumn get destinationAccountId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get budgetId => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for transaction categories.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for budget tracking.
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get period => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get categoryIds => text().nullable()(); // JSON array
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for piggy banks (savings goals).
class PiggyBanks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountId => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table for auto-categorization rules.
class CategorizationRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  IntColumn get matchType => integer()();
  TextColumn get pattern => text()();
  BoolColumn get caseSensitive => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Accounts,
  Transactions,
  Categories,
  Budgets,
  PiggyBanks,
  CategorizationRules,
],)
/// The main database class using Drift for persistence.
class AppDatabase extends _$AppDatabase {
  /// Initializes the database with an open connection.
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // We added the CategorizationRules table in version 2
          await m.createTable(categorizationRules);
        }
      },
    );
  }

  /// The secure storage key used to store the database encryption key.
  static const _dbEncryptionKeyName = 'db_encryption_key';

  /// Private helper to open a connection to the SQLite database file with encryption.
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      try {
        print('DB_DEBUG: Starting database initialization...');
        
        // NOTE: In a production macOS app, you should use flutter_secure_storage
        // to manage this key. However, this requires "Keychain Sharing" entitlements
        // and a valid developer signing certificate in Xcode (Error -34018).
        // For development/demo purposes, we use a fixed key.
        const key = 'dev-secure-passphrase-123';
        print('DB_DEBUG: Using development encryption key.');

        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'financesistent.sqlite'));
        print('DB_DEBUG: Database file path: ${file.path}');
        
        return NativeDatabase(
          file,
          setup: (rawDb) {
            print('DB_DEBUG: Running database setup (PRAGMA key)...');
            // Encryption key must be set via PRAGMA immediately after opening
            rawDb.execute("PRAGMA key = '$key';");
          },
        );
      } catch (e, stack) {
        print('DB_DEBUG: Error during database initialization: $e');
        print('DB_DEBUG: Stack track: $stack');
        rethrow;
      }
    });
  }
}
