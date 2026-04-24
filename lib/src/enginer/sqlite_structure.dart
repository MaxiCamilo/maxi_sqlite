import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/table_creator_command_to_sqlite.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_mutex.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class SqliteStructure implements SqlStructure {
  final SqliteMutex mutex;

  SqliteStructure({required this.mutex});

  @override
  FutureResult<bool> checkTableExists({required String tableName}) {
    return mutex.execute((conn) async {
      final result = await conn.executeQuery(
        command: SqliteCommand(sql: 'SELECT name FROM sqlite_master WHERE type=\'table\' AND name=?;', parameters: [tableName]),
      );
      if (result.itsFailure) {
        return result.cast();
      }

      return result.content.isNotEmpty.asResultValue();
    });
  }

  @override
  FutureResult<void> createTable({required SqlTableCreator command}) {
    return mutex.execute((conn) async {
      final sqlResult = TableCreatorCommandToSqlite(command: command).execute();
      if (sqlResult.itsFailure) {
        return sqlResult.cast();
      }

      return conn.executeCommand(command: sqlResult.content);
    });
  }

  @override
  Future<bool> deleteTable({required String tableName}) {
    return mutex
        .execute(
          (conn) => conn.executeCommand(
            command: SqliteCommand(sql: 'DROP TABLE IF EXISTS "$tableName";', parameters: const []),
          ),
        )
        .then((x) => x.itsCorrect);
  }

  @override
  FutureResult<void> validateTableSchema({required SqlTableCreator command}) async {
    final columnsResult = await obtainColumnsNames(tableName: command.name);
    if (columnsResult.itsFailure) {
      return columnsResult.cast();
    }

    final missingColumns = columnsResult.content.where((x) => !command.columns.any((c) => c.name.toLowerCase() == x)).toList();

    if (missingColumns.isNotEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Table %1 is not compatible with the desired structure, missing %2 columns: %3', textParts: [command.name, missingColumns.length, missingColumns.map((x) => '"$x"').join(', ')]),
      );
    }

    final extraColumns = command.columns.where((c) => !columnsResult.content.contains(c.name.toLowerCase())).toList();

    if (extraColumns.isNotEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(
          message: 'Table %1 is not compatible with the desired structure, it has %2 extra columns: %3',
          textParts: [command.name, extraColumns.length, extraColumns.map((x) => '"${x.name}"').join(', ')],
        ),
      );
    }

    return voidResult;
  }

  FutureResult<List<String>> obtainColumnsNames({required String tableName}) {
    return mutex.execute((conn) async {
      final tableResult = await conn.executeQuery(
        command: SqliteCommand(sql: 'PRAGMA table_info($tableName);', parameters: const []),
      );
      if (tableResult.itsFailure) {
        return tableResult.cast();
      }

      return tableResult.content.getColumnByName(columnName: 'name', caseSensitivity: true).onCorrectSelect((x) => x.cast<String>().map((x) => x.toLowerCase()).toList());
    });
  }
}
