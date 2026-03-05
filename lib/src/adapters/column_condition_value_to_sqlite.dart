import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/column_condition_to_sqlite.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class ColumnConditionValueToSqlite implements SyncFunctionality<SqliteCommand> {
  final ColumnCompareValue condition;

  const ColumnConditionValueToSqlite({required this.condition});

  @override
  Result<SqliteCommand> execute() {
    final function = condition.conditionator;
    return _castFunction(function);
  }

  Result<SqliteCommand> _castFunction(Conditionator function) {
    if (function is CompareSelectedValue) {
      return _convertCompareSelectedValueToSqlite(function);
    } else if (function is CompareIncludeValues) {
      return _convertCompareIncludeValuesToSqlite(function);
    } else if (function is CompareNested) {
      return _convertCompareNestedToSqlite(function);
    } else if (function is CompareSimilarText) {
      return _convertCompareSimilarTextToSqlite(function);
    } else if (function is CompareNumberRange) {
      return _convertCompareNumberRangeToSqlite(function);
    } else if (function is CompareAntagonist) {
      return _convertCompareAntagonistToSqlite(function);
    }
    if (function is CompareValues) {
      return _convertCompareValuesToSqlite(function);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'Conditionator type not supported for SQLite conversion'),
      );
    }
  }

  Result<SqliteCommand> _convertCompareSelectedValueToSqlite(CompareSelectedValue function) {
    final column = condition.tableName.isNotEmpty ? '${condition.tableName}.${condition.columnName}' : condition.columnName;
    final operatorCompare = ColumnConditionToSqlite.castOperatorToSqlite(function.compareType);

    return ResultValue(
      content: SqliteCommand(sql: '$column $operatorCompare ?', parameters: [function.value]),
    );
  }

  Result<SqliteCommand> _convertCompareValuesToSqlite(CompareValues function) {
    log('Warning: CompareValues is a condition for two values, not for comparing a column. It will return the result of the two resolved values', name: 'ColumnConditionValueToSqlite');
    return ResultValue(
      content: SqliteCommand(parameters: [], sql: function.execute() ? '1=1' : '1=0'),
    );
  }

  Result<SqliteCommand> _convertCompareIncludeValuesToSqlite(CompareIncludeValues function) {
    if (function.values.isEmpty) {
      log('Warning: CompareIncludeValues with empty values list. This condition will always be true', name: 'ColumnConditionValueToSqlite');
      return ResultValue(
        content: SqliteCommand(sql: '1=1', parameters: []),
      );
    }

    final column = condition.tableName.isNotEmpty ? '${condition.tableName}.${condition.columnName}' : condition.columnName;

    final placeholders = List.filled(function.values.length, '?').join(', ');
    return ResultValue(
      content: SqliteCommand(sql: '$column IN ($placeholders)', parameters: function.values.toList()),
    );
  }

  Result<SqliteCommand> _convertCompareNestedToSqlite(CompareNested function) {
    final parameters = [];
    final sqlList = <String>[];

    for (final coma in function.conditionators) {
      final convResult = ColumnConditionValueToSqlite(
        condition: ColumnCompareValue(columnName: condition.columnName, tableName: condition.tableName, conditionator: coma),
      ).execute();
      if (convResult.itsFailure) {
        return convResult.cast();
      }

      sqlList.add(convResult.content.sql);
      parameters.addAll(convResult.content.parameters);
    }

    return SqliteCommand(sql: '(${sqlList.join(' ${function.allMustMatch ? 'AND' : 'OR'} ')})', parameters: parameters).asResultValue();
  }

  Result<SqliteCommand> _convertCompareSimilarTextToSqlite(CompareSimilarText function) {
    final column = condition.tableName.isNotEmpty ? '${condition.tableName}.${condition.columnName}' : condition.columnName;
    return ResultValue(
      content: SqliteCommand(sql: '$column LIKE ?', parameters: ['%${function.similarTo}%']),
    );
  }

  Result<SqliteCommand> _convertCompareNumberRangeToSqlite(CompareNumberRange function) {
    final column = condition.tableName.isNotEmpty ? '${condition.tableName}.${condition.columnName}' : condition.columnName;

    if (function.min > function.max) {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: const FixedOration(message: 'Invalid number range: min is greater than max'),
      );
    }

    if (function.min == double.negativeInfinity && function.max == double.infinity) {
      log('Warning: CompareNumberRange with infinite range. This condition will always be true', name: 'ColumnConditionValueToSqlite');
      return ResultValue(
        content: SqliteCommand(sql: '1=1', parameters: []),
      );
    }

    if (function.min == double.negativeInfinity) {
      return _convertCompareSelectedValueToSqlite(CompareSelectedValue.lessEqual(function.max));
    }

    if (function.max == double.infinity) {
      return _convertCompareSelectedValueToSqlite(CompareSelectedValue.greaterEqual(function.min));
    }

    

    return ResultValue(
      content: SqliteCommand(sql: '$column BETWEEN ? AND ?', parameters: [function.min, function.max]),
    );
  }

  Result<SqliteCommand> _convertCompareAntagonistToSqlite(CompareAntagonist function) {
    final consResult = _castFunction(function.conditionator);
    if (consResult.itsFailure) {
      return consResult.cast();
    }

    return ResultValue(
      content: SqliteCommand(sql: 'NOT (${consResult.content.sql})', parameters: consResult.content.parameters),
    );
  }
}
