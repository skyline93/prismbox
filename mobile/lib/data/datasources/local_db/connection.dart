import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_database.dart';

const String _isolatePortName = 'db_isolate_port';

LazyDatabase _openConnection(String dbPath) {
  return LazyDatabase(() async {
    log(
      "==========> [DB Isolate] Opening database at: $dbPath",
      name: "DBConnection",
    );
    final file = File(dbPath);
    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}

Future<void> initializeDatabaseIsolate() async {
  if (IsolateNameServer.lookupPortByName(_isolatePortName) != null) {
    log("Database isolate port is already registered.", name: "DBSetup");
    return;
  }

  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, 'media_library.sqlite');
  log("Database path determined in main isolate: $dbPath", name: "DBSetup");

  log("Spawning new database isolate...", name: "DBSetup");

  final driftIsolate = await DriftIsolate.spawn(() => _openConnection(dbPath));

  final success = IsolateNameServer.registerPortWithName(
    driftIsolate.connectPort,
    _isolatePortName,
  );

  if (!success) {
    driftIsolate.shutdownAll();
    throw Exception(
      "Failed to register database isolate port. Another port might already be registered with the same name.",
    );
  }
  log("Database isolate port registered successfully.", name: "DBSetup");
}

Future<AppDatabase> connect() async {
  log("Attempting to connect to database isolate...", name: "DBConnect");

  final port = IsolateNameServer.lookupPortByName(_isolatePortName);

  if (port == null) {
    throw Exception(
      "Database isolate port not found. Was initializeDatabaseIsolate() called?",
    );
  }

  final isolate = DriftIsolate.fromConnectPort(port);

  final connection = await isolate.connect();
  return AppDatabase(connection);
}
