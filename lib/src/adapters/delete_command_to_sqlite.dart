import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/column_condition_to_sqlite.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class DeleteCommandToSqlite implements SyncFunctionality<SqliteCommand> {
  final SqlDeleteCommand command;

  const DeleteCommandToSqlite({required this.command});

  @override
  Result<SqliteCommand> execute() {
    final buffer = StringBuffer();
    final shieldedValues = [];

    buffer.write('DELETE FROM "${command.tableName}"');

    if (command.conditions.isNotEmpty) {
      buffer.write('\n WHERE ');
      final conditionCommands = command.conditions.map((e) => ColumnConditionToSqlite(condition: e).execute()).toList();
      final error = conditionCommands.selectItem((result) => result.itsFailure);
      if (error != null) {
        return error.cast();
      }
      buffer.write(conditionCommands.map((result) => result.content.sql).join(' AND \n'));
      for (final result in conditionCommands) {
        shieldedValues.addAll(result.content.parameters);
      }
    }

    buffer.write(';');

    return ResultValue(
      content: SqliteCommand(sql: buffer.toString(), parameters: shieldedValues),
    );
  }
}
