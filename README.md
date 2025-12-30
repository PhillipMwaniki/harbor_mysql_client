# Harbor

A cross-platform MySQL client built with Flutter, inspired by Sequel Ace.

Harbor aims to deliver a native desktop experience for MySQL database management on Windows, macOS, and Linux.

## Features

### Current (Implemented)

- **Connection Management**
  - Create, edit, and delete saved connections
  - Direct TCP connections with TLS support
  - Encrypted credential storage (AES-256)
  - Connection persistence across app restarts

- **Schema Browser**
  - Database tree navigation
  - Table listing with filtering
  - Column and index information
  - Table metadata display (row count, engine, collation)

- **Query Editor**
  - Multi-line SQL editing with line numbers
  - Query execution with timing
  - Results displayed in tabular format

- **Results Grid**
  - Tabular data display
  - Column information
  - NULL value distinction

- **Content Tabs**
  - Structure view (columns, indexes)
  - Content view (table data)
  - Query view (custom SQL)
  - Info view (CREATE TABLE statement)

### Planned

- SSH tunneled connections
- Query cancellation
- Virtual scrolling for large result sets (50k+ rows)
- Syntax highlighting
- Multiple query tabs
- Query history
- Export/import tools

## Screenshots

*Coming soon*

## Installation

### Prerequisites

- Flutter SDK (stable channel, desktop enabled)
- Windows 10/11, macOS, or Linux
- MySQL 5.7+, MySQL 8.x, or MariaDB 10.x

### Build from Source

```bash
# Clone the repository
git clone https://github.com/PhillipMwaniki/harbor_mysql_client.git
cd harbor_mysql_client

# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux
```

### Build Release

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Architecture

```
lib/
├── main.dart                 # Application entry point
├── models/
│   └── connection_info.dart  # Connection data model
├── providers/
│   └── database_provider.dart # Riverpod state management
├── services/
│   ├── mysql_service.dart           # MySQL operations
│   └── connection_storage_service.dart # Encrypted storage
└── ui/
    ├── screens/
    │   ├── main_screen.dart        # Main application shell
    │   └── connection_manager.dart # Connection dialog
    ├── widgets/
    │   ├── app_toolbar.dart     # Top toolbar
    │   ├── schema_browser.dart  # Left sidebar
    │   ├── content_tabs.dart    # Tabbed content area
    │   ├── query_editor.dart    # SQL editor
    │   └── results_grid.dart    # Data grid
    └── theme/
        └── app_theme.dart       # Dark theme
```

### Design Principles

- **Separation of concerns**: UI never talks to sockets; services never manipulate widgets
- **State management**: Riverpod for predictable, testable state
- **Security**: Credentials encrypted at rest using AES-256
- **Performance**: Designed for large result sets

## Technology Stack

| Component | Library |
|-----------|---------|
| Framework | Flutter (Desktop) |
| MySQL Client | `mysql_client` |
| State Management | `flutter_riverpod` |
| Encryption | `encrypt` |
| Storage | `path_provider` |

## Security

- All connection credentials are encrypted using AES-256
- Encryption keys are generated per-installation and stored locally
- Passwords are never logged or printed
- Data stored in platform-appropriate application support directory

### Storage Location

| Platform | Location |
|----------|----------|
| Windows | `%APPDATA%\Harbor\` |
| macOS | `~/Library/Application Support/Harbor/` |
| Linux | `~/.local/share/Harbor/` |

## Development

### Project Structure

The project follows a layered architecture:

1. **UI Layer** - Flutter widgets and screens
2. **Provider Layer** - Riverpod state management
3. **Service Layer** - Business logic and external integrations
4. **Model Layer** - Data structures

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## Non-Goals (Current Scope)

To keep the project focused, the following are explicitly out of scope for the initial release:

- ER diagramming
- Visual query builders
- User/role management
- Cloud sync
- Plugin ecosystem

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

*License to be determined*

## Acknowledgments

- Inspired by [Sequel Ace](https://sequel-ace.com/) and [Sequel Pro](https://sequelpro.com/)
- Built with [Flutter](https://flutter.dev/)
