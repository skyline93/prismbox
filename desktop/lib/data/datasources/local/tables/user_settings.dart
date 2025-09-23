import 'package:drift/drift.dart';

@DataClassName('UserSetting')
class UserSettings extends Table {
  @override
  String get tableName => 'user_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
