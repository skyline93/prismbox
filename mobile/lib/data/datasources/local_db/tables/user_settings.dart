import 'package:drift/drift.dart';

@DataClassName('UserSetting')
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
