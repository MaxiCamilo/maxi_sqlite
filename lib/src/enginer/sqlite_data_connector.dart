import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/adapters/delete_command_to_sqlite.dart';
import 'package:maxi_sqlite/src/adapters/insert_command_to_sqlite.dart';
import 'package:maxi_sqlite/src/adapters/query_command_to_sqlite.dart';
import 'package:maxi_sqlite/src/adapters/update_command_to_sqlite.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_mutex.dart';

class SqliteDataConnector implements SqlDataConnector {
  final SqliteMutex reserver;
  SqliteDataConnector({required this.reserver});

  @override
  FutureResult<TableResult> executeQuery(SqlQueryCommand command) {
    return reserver.execute((adapter) async {
      final sqlCommandResult = QueryCommandToSqlite(command: command).execute();
      if (sqlCommandResult.itsFailure) {
        return sqlCommandResult.cast();
      }

      return adapter.executeQuery(command: sqlCommandResult.content);
    });
  }

  @override
  FutureResult<void> executeDelete(SqlDeleteCommand command) {
    return reserver.execute((adapter) async {
      final sqlCommandResult = DeleteCommandToSqlite(command: command).execute();
      if (sqlCommandResult.itsFailure) {
        return sqlCommandResult.cast();
      }

      return adapter.executeCommand(command: sqlCommandResult.content);
    });
  }

  @override
  FutureResult<void> executeInsert(SqlInsertCommand command) {
    return reserver.execute((adapter) async {
      final sqlCommandResult = InsertCommandToSqlite(command: command).execute();
      if (sqlCommandResult.itsFailure) {
        return sqlCommandResult.cast();
      }

      return adapter.executeCommand(command: sqlCommandResult.content);
    });
  }

  @override
  FutureResult<void> executeUpdate(SqlUpdateCommand command) {
    return reserver.execute((adapter) async {
      final sqlCommandResult = UpdateCommandToSqlite(command: command).execute();
      if (sqlCommandResult.itsFailure) {
        return sqlCommandResult.cast();
      }

      return adapter.executeCommand(command: sqlCommandResult.content);
    });
  }
}
