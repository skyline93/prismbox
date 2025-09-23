import 'dart:async';
import 'package:drift/drift.dart';
import 'connection/connection.dart'
    if (dart.library.html) 'connection/unsupported.dart';
import 'tables/media_assets.dart';
import 'tables/user_settings.dart';
part 'daos/media_asset_dao.dart';
part 'daos/user_settings_dao.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [MediaAssets, UserSettings],
  daos: [MediaAssetDao, UserSettingDao],
)
class AppDatabase extends _$AppDatabase {
  // This constructor is for regular app usage.
  AppDatabase() : super(constructDb());
  // This constructor is useful for testing, allowing you to inject a connection.
  // THE FIX IS HERE: Changed from super.connect(connection) to super(connection).
  AppDatabase.connect(DatabaseConnection connection) : super(connection);
  @override
  int get schemaVersion => 1;
}
