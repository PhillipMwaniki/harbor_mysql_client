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

## 8. Key Libraries (Recommended)

### Core

* `flutter_riverpod`
* `collection`
* `path_provider`
* `encrypt`

### UI

* `flutter_code_editor`
* `highlight`
* `data_table_2` (or custom virtual grid)
* `window_manager`

### System Integration

* `process_run` (spawn SSH)
* `ffi` (future native bindings)

### Local Storage

* `sqflite` or `isar`

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

## 12. Success Criteria for POC

The POC is successful if:

* SSH tunnel connects reliably
* Queries return results without UI freeze
* 50k-row result sets are scrollable
* App feels closer to Sequel Ace than HeidiSQL

---

## 13. Estimated Effort

| Phase               | Duration |
| ------------------- | -------- |
| Setup & scaffolding | 1 week   |
| SSH + connections   | 1 week   |
| Query editor        | 1 week   |
| Results grid        | 2 weeks  |
| Schema browser      | 1 week   |

**Total:** ~6 weeks (focused effort)

---

## 14. Next Steps (Post-POC)

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

