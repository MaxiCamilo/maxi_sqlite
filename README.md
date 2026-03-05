# maxi_sqlite

A Dart library that implements the abstract SQL commands from [maxi_sql](../maxi_sql) for SQLite database operations.

## Overview

`maxi_sqlite` is a specialized adapter layer that bridges the abstract SQL command interface provided by `maxi_sql` with the concrete implementation for SQLite databases. It provides a seamless way to work with SQLite while maintaining compatibility with the abstract SQL framework.

## Features

- **SQLite Integration**: Full support for SQLite database operations through the abstract SQL interface
- **Column Adapters**: Conversion utilities for column conditions and values to SQLite format
- **Query Engine**: Specialized engine implementations for SQLite-specific query execution
- **Model Mapping**: Easy conversion between Dart models and SQLite tables
- **Transaction Support**: Built-in support for database transactions
- **Type Safety**: Leverages Dart's type system for database operations

## Installation

Add `maxi_sqlite` to your `pubspec.yaml`:

```yaml
dependencies:
  maxi_sqlite:
    path: ../maxi_sqlite
  maxi_sql:
    path: ../maxi_sql
  maxi_framework:
    path: ../maxi_framework
```

## Dependencies

- **maxi_sql**: Abstract SQL command framework
- **maxi_framework**: Core framework utilities
- **sqlite3**: SQLite database driver for Dart

## Project Structure

```
lib/
├── maxi_sqlite.dart              # Main entry point
└── src/
    ├── adapters/                 # Column and condition adapters
    ├── enginer/                  # SQLite engine implementations
    ├── logic/                    # Business logic layer
    └── models/                   # Data models and mappings
```

## Architecture

### Adapters Layer
Converts abstract SQL conditions and column values into SQLite-compatible format.

### Engine Layer
Implements the concrete SQLite database engine that executes queries.

### Logic Layer
Contains helper functions and utility methods for SQLite operations.

### Models Layer
Defines data models and mappings for SQLite tables.

## Usage Example

```dart
import 'package:maxi_sqlite/maxi_sqlite.dart';

// Your SQLite database operations will use the maxi_sql interface
// implemented by this library
```

## Development

This library is part of the Maxi framework ecosystem and works in conjunction with:
- [maxi_sql](../maxi_sql) - Abstract SQL command framework
- [maxi_framework](../maxi_framework) - Core framework
- [maxi_reflection](../maxi_reflection) - Reflection utilities

## Testing

Run tests with:

```bash
dart test
```

## License

See LICENSE file for details.

