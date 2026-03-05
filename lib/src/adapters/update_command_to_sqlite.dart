import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/column_condition_to_sqlite.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class UpdateCommandToSqlite implements SyncFunctionality<SqliteCommand> {
  final SqlUpdateCommand command;

  const UpdateCommandToSqlite({required this.command});

  @override
  Result<SqliteCommand> execute() {
    final shieldedValues = command.values.values.toList();
    final buffer = StringBuffer('UPDATE "${command.tableName}" SET \n ');

    final propertyNames = command.values.keys.map((x) => '"$x" = ?');
    buffer.write(propertyNames.map((x) => x).join(', '));

    if (command.conditions.isNotEmpty) {
      buffer.write('\n WHERE ');
      final conditionTexts = <String>[];

      for (final item in command.conditions) {
        final conditionResult = ColumnConditionToSqlite(condition: item).execute();

        if (conditionResult.itsFailure) {
          return conditionResult.cast();
        }

        conditionTexts.add(conditionResult.content.sql);
        shieldedValues.addAll(conditionResult.content.parameters);
      }

      buffer.write(conditionTexts.join(' AND \n'));
    }
    buffer.write(';');
    return ResultValue(
      content: SqliteCommand(sql: buffer.toString(), parameters: shieldedValues),
    );
  }
}
