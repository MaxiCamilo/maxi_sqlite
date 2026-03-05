import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class InsertCommandToSqlite implements SyncFunctionality<SqliteCommand> {
  final SqlInsertCommand command;

  const InsertCommandToSqlite({required this.command});

  @override
  Result<SqliteCommand> execute() {
    final buffer = StringBuffer('INSERT INTO "${command.tableName}" (');
    buffer.write(command.values.keys.map((x) => '"$x"').join(', '));
    buffer.write(') VALUES (');
    buffer.write(command.values.keys.map((x) => '?').join(', '));
    buffer.write(');');

    return ResultValue(
      content: SqliteCommand(sql: buffer.toString(), parameters: command.values.values.toList()),
    );
  }
}
