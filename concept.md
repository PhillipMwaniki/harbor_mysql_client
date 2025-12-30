# Proof of Concept (POC)

## Cross-Platform MySQL Client (Sequel Ace–Style) using Flutter

---

## 1. Objective

Build a **proof-of-concept desktop application** using **Flutter** that delivers a Sequel Ace–like experience on **Windows first**, with a clean path to macOS and Linux.

The POC validates:

* Feasibility of Flutter for a serious DB admin tool
* SSH tunneling stability
* Query execution performance
* Result-grid rendering at scale
* Clean, non-web UI/UX

This is **not a full product**. It is a technical and UX validation.

---

## 2. Non-Goals (Explicitly Out of Scope)

To keep this sane:

* No ER diagramming
* No visual query builders
* No user/role management
* No cloud sync
* No plugin ecosystem

Those come later *if* the POC proves viable.

---

## 3. Target Platform

| Platform      | Support       |
| ------------- | ------------- |
| Windows 10/11 | Yes (Primary) |
| macOS         | Later         |
| Linux         | Later         |

---

## 4. Core Functional Requirements (POC Scope)

### 4.1 Connection Management

* Create, edit, delete saved connections
* Support:

  * Direct TCP connections
  * SSH tunneled connections
* Store connection metadata locally (encrypted at rest)

Required fields:

* Host
* Port
* Username
* Password (optional)
* Database (optional)
* SSH host
* SSH port
* SSH user
* SSH auth (password or key)

---

### 4.2 SSH Tunneling

**Design choice (recommended): External SSH process**

* Spawn system `ssh` binary
* Manage lifecycle per connection
* Bind to random or user-defined local ports
* Kill tunnel on disconnect or app exit

Why:

* Battle-tested
* Avoids Dart-native SSH fragility
* Mirrors how serious DBAs work

---

### 4.3 Query Editor

* Multi-line SQL editor
* Syntax highlighting (MySQL)
* Multiple tabs
* Run / Stop execution
* Display execution time

Nice-to-have:

* Query history (session-only for POC)

---

### 4.4 Query Execution Engine

* Async execution
* Cancelable queries
* Sequential execution per connection
* Proper error propagation

---

### 4.5 Results Grid

* Display tabular results
* Virtual scrolling (must handle 50k+ rows)
* Column resize
* Copy cell / row
* NULL vs empty distinction

This is **the most critical performance component**.

---

### 4.6 Schema Browser

Left-hand navigation:

* Databases
* Tables
* Views

For tables:

* Column list
* Index list (read-only)

---

## 5. Non-Functional Requirements

### 5.1 Performance

* App startup < 1.5s
* Query editor responsive under load
* Results grid must not freeze UI

### 5.2 Stability

* SSH tunnel cleanup on crash
* No zombie processes
* Graceful disconnects

### 5.3 UX Principles

* Keyboard-first
* Minimal chrome
* No modal spam
* Deterministic layouts

---

## 6. Architecture Overview

```
UI Layer (Flutter Widgets)
 └── Application Layer
      ├── ConnectionManager
      ├── SSHTunnelService
      ├── QueryService
      ├── SchemaService
      └── ResultSetAdapter

Platform Layer
 └── SSH Process / Native Hooks

Data Layer
 └── MySQL Connection (via tunnel or direct)
```

Strict separation:

* UI never talks to sockets
* Services never manipulate widgets

---

## 7. Technology Stack

### 7.1 Flutter & Dart

* Flutter Stable (Desktop enabled)
* Dart isolates for blocking operations

### 7.2 State Management

* `riverpod`

  * Predictable
  * Testable
  * No widget coupling

---

## 8. Key Libraries (Final Selection)

### MySQL Connectivity

* `mysql_client` — Pure Dart MySQL client with binary protocol support
  * Supports MySQL 5.7, 8.x and MariaDB 10.x
  * Real prepared statements (binary protocol)
  * TLS support built-in
  * **Note:** If maintenance stalls, migrate to `mysql_client_plus` (maintained fork)

### State Management

* `flutter_riverpod` — Predictable, testable, no widget coupling

### UI - Query Editor

* `syntax_highlight` — VSCode-style TextMate grammar highlighting
  * Explicit SQL support out of the box
  * Bundled CodeEditor widget for basic editing
  * Alternative: `flutter_code_editor` (by Akvelon) for richer features like code folding

### UI - Results Grid

* `material_table_view` — **Primary choice**
  * Lazy-built fixed-height rows (supports billions of rows)
  * Horizontal and vertical scrolling
  * Frozen columns support
  * **Fallback:** `mahop_data_table` (virtual scrolling with variable row heights, Feb 2025)
  * **Avoid:** `data_table_2` — not designed for 50k+ rows

### UI - Window & Layout

* `window_manager` — Window controls, title bar customization
* `multi_split_view` — Resizable split panels

### Security & Storage

* `flutter_secure_storage` — Platform-native secure credential storage
  * Windows: Uses Windows Credential Manager (requires C++ ATL libs)
  * Automatic key management
  * **Note:** Requires Visual Studio Build Tools with C++ ATL component
* `isar` — Local database for connection metadata, query history
  * Fast embedded NoSQL database
  * Works well on Windows desktop

### System Integration

* `dart:io Process` — Spawn SSH process (prefer over `process_run` for simplicity)
* `path_provider` — Platform-appropriate directories

---

## 9. UI Layouts to Consider

### 9.1 Main Application Shell

```
+--------------------------------------------------+
| Top Bar (Connections, Run, Stop)                 |
+------------------+-------------------------------+
| Schema Browser   | Query Editor (Tabs)           |
|                  |-------------------------------|
|                  | Results Grid                  |
+------------------+-------------------------------+
```

Characteristics:

* Docked panels
* Resizable splitters
* No floating windows (POC)

---

### 9.2 Connection Manager

* Left list of saved connections
* Right-side details panel
* Test connection button

---

### 9.3 Error Display

* Inline errors
* No blocking modals
* Copyable error text

---

## 10. Security Considerations

* Encrypt stored credentials
* Never log passwords
* SSH keys preferred over passwords
* Clear sensitive memory on disconnect

---

## 11. Risks & Mitigations

| Risk                     | Mitigation                  |
| ------------------------ | --------------------------- |
| Flutter grid performance | Custom virtualized grid     |
| SSH instability          | External SSH process        |
| MySQL protocol quirks    | Limit scope to common types |
| Desktop UX polish        | Strict layout rules         |

---

## 12. Identified Concerns & Resolutions

### 12.1 SSH Availability on Windows

**Concern:** The design assumes `ssh` binary availability. While Windows 10 (1809+) includes OpenSSH as an optional feature, it may not be installed on all systems.

**Resolution:**
* On startup, check for SSH availability using `where ssh` or `Get-Command ssh`
* If not found, display a clear message with installation instructions:
  * Settings → Apps → Optional Features → Add OpenSSH Client
  * Or via PowerShell: `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`
* Windows Server 2025 ships with OpenSSH by default
* Store SSH path in settings to allow custom SSH binary location

### 12.2 Query Cancellation

**Concern:** MySQL does not natively support query cancellation from the client connection. A long-running query cannot be stopped from the same connection that issued it.

**Resolution:**
* Maintain a secondary "control" connection per active connection
* When user clicks "Stop", issue `KILL QUERY <connection_id>` from control connection
* Retrieve connection ID via `SELECT CONNECTION_ID()` on primary connection
* Handle edge cases:
  * Control connection failure → warn user, suggest manual kill
  * Query completes before kill → graceful no-op

### 12.3 Results Grid Performance

**Concern:** `data_table_2` is not designed for 50k+ rows. Flutter's default DataTable renders all rows, causing UI freeze.

**Resolution:**
* Use `material_table_view` as primary grid implementation
  * Supports lazy-built rows (only renders visible viewport)
  * Fixed-height rows enable predictable scroll positions
* Fallback to `mahop_data_table` if variable row heights needed
* Implement result set pagination at the application layer:
  * Fetch in chunks (e.g., 10,000 rows)
  * Stream results to grid as they arrive
* Add "Limit Results" option in query settings (default: 1,000)

### 12.4 Credential Storage on Windows

**Concern:** The `encrypt` package requires manual key management. If keys are stored insecurely, encryption is pointless.

**Resolution:**
* Use `flutter_secure_storage` instead of raw `encrypt`
  * Leverages Windows Credential Manager
  * Automatic key management by OS
* Requires Visual Studio Build Tools with C++ ATL — document in README
* For SSH private keys: store file path only, not key contents
* Never log or print credentials (enforce via code review)

### 12.5 Testing Strategy

**Concern:** No testing approach was defined for validating SSH tunnel cleanup and query performance.

**Resolution:**
* **Unit tests:** Connection manager, query parsing, result set adapter
* **Integration tests:**
  * SSH tunnel lifecycle (connect, query, disconnect, crash recovery)
  * Use Docker MySQL container for reproducible test environment
* **Performance benchmarks:**
  * Measure grid render time for 1k, 10k, 50k, 100k rows
  * Track memory usage during large result sets
  * Automated regression tests in CI
* **Manual test checklist:**
  * Kill app during active SSH tunnel → verify no zombie `ssh.exe` processes
  * Network disconnect during query → verify graceful error handling

---

## 13. Success Criteria for POC

The POC is successful if:

* SSH tunnel connects reliably
* Queries return results without UI freeze
* 50k-row result sets are scrollable
* App feels closer to Sequel Ace than HeidiSQL

---

## 14. Estimated Effort

| Phase               | Duration |
| ------------------- | -------- |
| Setup & scaffolding | 1 week   |
| SSH + connections   | 1 week   |
| Query editor        | 1 week   |
| Results grid        | 2 weeks  |
| Schema browser      | 1 week   |

**Total:** ~6 weeks (focused effort)

---

## 15. Next Steps (Post-POC)

* Native MySQL driver binding
* Saved query library
* Export/import tools
* macOS build

---

## Final Note

This POC deliberately favors **correctness, performance, and boring engineering** over flashy features.
If this foundation is solid, everything else becomes easy.
If it is not, the project should be killed early.

That is success either way.
