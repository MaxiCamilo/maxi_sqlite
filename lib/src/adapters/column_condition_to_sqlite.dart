import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/column_condition_value_to_sqlite.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class ColumnConditionToSqlite implements SyncFunctionality<SqliteCommand> {
  final ColumnCondition condition;

  const ColumnConditionToSqlite({required this.condition});

  static String castOperatorToSqlite(ConditionCompareType compareType) {
    return switch (compareType) {
      ConditionCompareType.equal => '=',
      ConditionCompareType.notEqual => '<>',
      ConditionCompareType.greater => '>',
      ConditionCompareType.less => '<',
      ConditionCompareType.greaterEqual => '>=',
      ConditionCompareType.lessEqual => '<=',
    };
  }

  @override
  Result<SqliteCommand> execute() {
    return switch (condition) {
      ColumnCompareValue() => ColumnConditionValueToSqlite(condition: condition as ColumnCompareValue).execute(),
      ColumnCompareTwoColumns() => _createComparationBetweenTwoColumns(condition as ColumnCompareTwoColumns),
      _ => NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'ColumnCondition type not supported for SQLite conversion'),
      ),
    };
  }

  Result<SqliteCommand> _createComparationBetweenTwoColumns(ColumnCompareTwoColumns condition) {
    final column1 = condition.tableName1.isNotEmpty ? '${condition.tableName1}.${condition.columnName1}' : condition.columnName1;
    final column2 = condition.tableName2.isNotEmpty ? '${condition.tableName2}.${condition.columnName2}' : condition.columnName2;
    final sqlOperator = castOperatorToSqlite(condition.condition);
    return ResultValue(
      content: SqliteCommand(sql: '$column1 $sqlOperator $column2', parameters: const []),
    );
  }
}
