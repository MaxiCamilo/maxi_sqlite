import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/column_condition_to_sqlite.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class QueryCommandToSqlite implements SyncFunctionality<SqliteCommand> {
  final SqlQueryCommand command;

  const QueryCommandToSqlite({required this.command});

  @override
  Result<SqliteCommand> execute() {
    final buffer = StringBuffer();
    final shieldedValues = [];

    buffer.write('SELECT ');

    //Columns
    if (command.columns.isEmpty) {
      buffer.write('*');
    } else {
      _convertSelectFields(buffer);
    }

    //From
    buffer.write('\n FROM ');
    _convertSelectedTable(buffer);
    _convertJoinedTables(buffer, command.joinedTables);

    //Wheres
    final conditionResult = _defineConditions(buffer, shieldedValues);
    if (conditionResult.itsFailure) {
      return conditionResult.cast();
    }

    //Group by & Having
    if (command.grouped.isNotEmpty) {
      buffer.write('\n GROUP BY ${command.grouped.map((x) => '"$x"').join(', ')} ');

      if (command.havings.isNotEmpty) {
        buffer.write('\n HAVING ');
        final havingCommands = command.havings.map((e) => ColumnConditionToSqlite(condition: e).execute()).toList();
        final error = havingCommands.selectItem((result) => result.itsFailure);
        if (error != null) {
          return error.cast();
        }
        buffer.write(havingCommands.map((result) => result.content.sql).join(' AND \n'));
        for (final result in havingCommands) {
          shieldedValues.addAll(result.content.parameters);
        }
      }
    }

    //Order by
    if (command.orders.isNotEmpty) {
      final orderTexts = command.orders.where((x) => x.fields.isNotEmpty).map((x) => '\n ORDER BY ${x.fields.map((f) => '"$f"').join(', ')} ${x.isAscendent ? ' ASC' : ' DESC'}').toList();
      orderTexts.lambda((x) => buffer.write(x));
    }

    //Limit
    if (command.limit != null && command.limit! > 0) {
      buffer.write('\n LIMIT ${command.limit}');
    }

    buffer.write(';');
    return SqliteCommand(sql: buffer.toString(), parameters: shieldedValues).asResultValue();
  }

  void _convertSelectFields(StringBuffer buffer) {
    final textsCommands = <String>[];
    for (final field in command.columns) {
      late String text;
      if (field.columnName == '') {
        text = '*';
      } else if (field.tableName != '') {
        text = '"${field.tableName}"."${field.columnName}"';
      } else {
        text = '"${field.columnName}"';
      }

      switch (field.function) {
        case ColumnSelectionFunction.field:
          break;
        case ColumnSelectionFunction.count:
          text = 'COUNT($text)';
          break;
        case ColumnSelectionFunction.maximum:
          text = 'MAX($text)';
          break;
        case ColumnSelectionFunction.minimum:
          text = 'MIN($text)';
          break;
        case ColumnSelectionFunction.sum:
          text = 'SUM($text)';
          break;
        case ColumnSelectionFunction.average:
          text = 'AVG($text)';
          break;
      }

      if (field.alias != '') {
        text = '$text AS "${field.alias}"';
      }

      textsCommands.add(text);
    }

    buffer.write(textsCommands.join(', '));
  }

  void _convertSelectedTable(StringBuffer buffer) {
    final textsCommands = <String>[];

    for (final table in command.tables) {
      if (table.alias.isEmpty) {
        textsCommands.add(table.tableName);
      } else {
        textsCommands.add('${table.tableName} AS ${table.alias}');
      }
    }

    buffer.write(textsCommands.join(', '));
  }

  Result<void> _defineConditions(StringBuffer buffer, List shieldedValues) {
    if (command.conditions.isEmpty) {
      return voidResult;
    }

    final subCommand = command.conditions.map((e) => ColumnConditionToSqlite(condition: e).execute()).toList();
    final error = subCommand.selectItem((result) => result.itsFailure);
    if (error != null) {
      return error.cast();
    }

    buffer.write('\n WHERE ');
    final commandTexts = subCommand.map((result) => result.content.sql).join(' AND \n');
    buffer.write(commandTexts);
    for (final result in subCommand) {
      shieldedValues.addAll(result.content.parameters);
    }
    return voidResult;
  }

  void _convertJoinedTables(StringBuffer buffer, List<QueryJoiner> joinedTables) {
    if (joinedTables.isEmpty) {
      return;
    }

    for (final item in joinedTables) {
      buffer.write('\n');
      buffer.write(switch (item.type) {
        QueryJoinerFunction.inner => 'INNER JOIN ',
        QueryJoinerFunction.left => 'LEFT JOIN ',
        QueryJoinerFunction.right => 'RIGHT JOIN ',
        QueryJoinerFunction.fullOuter => 'FULL OUTER JOIN ',
      });

      if (item.externalTable.alias.isEmpty) {
        buffer.write(item.externalTable.columnName);
      } else {
        buffer.write('"${item.externalTable.columnName}" AS "${item.externalTable.alias}"');
      }

      buffer.write(' ON ');

      final wheres = <String>[];

      for (final condition in item.comparers) {
        final column1 = item.originTable.alias.isNotEmpty ? '"${item.originTable.alias}"."${condition.columnName1}"' : '"${condition.columnName1}"';
        final column2 = item.externalTable.alias.isNotEmpty ? '"${item.externalTable.alias}"."${condition.columnName2}"' : '"${condition.columnName2}"';
        final sqlOperator = ColumnConditionToSqlite.castOperatorToSqlite(condition.condition);
        wheres.add('$column1 $sqlOperator $column2');
      }

      buffer.write(wheres.join(' AND '));
    }
  }
}
