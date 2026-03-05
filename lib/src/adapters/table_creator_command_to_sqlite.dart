import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class TableCreatorCommandToSqlite implements SyncFunctionality<SqliteCommand> {
  final SqlTableCreator command;

  const TableCreatorCommandToSqlite({required this.command});

  @override
  Result<SqliteCommand> execute() {
    final buffer = StringBuffer('CREATE TABLE ${command.name} (');

    //final simpleCommand = command.primaryKeyGroups.isEmpty && command.uniqueKeyGroups.isEmpty && command.foreignKeys.isEmpty;

    // Columns Data
    for (final col in command.columns) {
      buffer.write('\n  "${col.name}" ${_convertColumnType(col.type)}');
      if (col.isPrimaryKey && col.isAutoIncrement) {
        buffer.write(' PRIMARY KEY AUTOINCREMENT');
      }

      buffer.write(' NOT NULL');
      buffer.write(',');
    }

    //Primary Keys
    command.columns.where((x) => x.isPrimaryKey && !x.isAutoIncrement).lambda((pri) {
      buffer.write('\n  PRIMARY KEY ("${pri.name}")');
    });

    //Primary Keys groups
    for (final group in command.primaryKeyGroups) {
      if (group.columns.isEmpty) {
        continue;
      }
      buffer.write('\n  PRIMARY KEY (${group.columns.map((x) => '"$x"').join(', ')})');
    }

    //Unique Keys
    command.columns.where((x) => x.isUniqueKey).lambda((uni) {
      buffer.write('\n  UNIQUE ("${uni.name}")');
    });

    //Unique Keys groups
    for (final group in command.uniqueKeyGroups) {
      if (group.columns.isEmpty) {
        continue;
      }
      buffer.write('\n  UNIQUE (${group.columns.map((x) => '"$x"').join(', ')})');
    }

    //Foreign Keys
    command.foreignKeys.lambda((fore) {
      buffer.write('\n  FOREIGN KEY ("${fore.fieldName}") REFERENCES "${fore.tableName}" ("${fore.referenceFieldName}")');
    });

    buffer.write('\n);');
    return ResultValue(
      content: SqliteCommand(sql: buffer.toString(), parameters: []),
    );
  }

  String _convertColumnType(SqlColumnFormatType type) {
    return switch (type) {
      SqlColumnFormatType.text => 'TEXT',
      SqlColumnFormatType.boolean => 'NUMERIC',
      SqlColumnFormatType.intWithoutLimit => 'INTEGER',
      SqlColumnFormatType.int8 => 'INTEGER',
      SqlColumnFormatType.int16 => 'INTEGER',
      SqlColumnFormatType.int32 => 'INTEGER',
      SqlColumnFormatType.int64 => 'INTEGER',
      SqlColumnFormatType.uintWithoutLimit => 'INTEGER',
      SqlColumnFormatType.uint8 => 'INTEGER',
      SqlColumnFormatType.uint16 => 'INTEGER',
      SqlColumnFormatType.uint32 => 'INTEGER',
      SqlColumnFormatType.uint64 => 'INTEGER',
      SqlColumnFormatType.doubleWithoutLimit => 'REAL',
      SqlColumnFormatType.decimal => 'REAL',
      SqlColumnFormatType.dateTime => 'INTEGER',
      SqlColumnFormatType.binary => 'BLOB',
      SqlColumnFormatType.dynamicType => 'BLOB',
    };
  }
}
