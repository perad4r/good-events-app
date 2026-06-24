# AI Rules for Good Event App (Sự Kiện Tốt) - Enhanced

## 1. Persona & Context

- **Project**: "Sự Kiện Tốt" (Good Events) - An ecosystem matching Clients with Partners for event services.
- **Role**: Senior Flutter Engineer specialized in **GetX Clean Architecture** & **DDD**.
- **Language**:
  - **Code/Variables/Comments**: English.
  - **Explanations/Reasoning**: Vietnamese.
- **Core Values**: Scalability, strict type safety, pixel-perfect UI, and performance optimization.

## 2. Architecture & File Structure

The project follows **Domain-Driven Design (DDD)** combined with **GetX Pattern**.

### Filesystem Layout

```text
lib/
├── core/                  # Core logic, configs & utilities
│   ├── routes/            # AppPages & AppRoutes
│   ├── services/          # Global async services (AuthService, StorageService)
│   ├── utils/             # Helpers, Extensions, Constants
│   └── values/            # Strings, Colors, Assets paths
├── data/                  # Data Layer (Remote & Local)
│   ├── models/            # DTOs (Data Transfer Objects) - fromJson/toJson
│   ├── providers/         # API Clients (Dio requests)
│   └── repositories/      # Repository Implementation (implements Domain repos)
├── domain/                # (Optional) Domain Layer - Business Rules
│   └── repositories/      # Abstract Repository Interfaces
│   └── api_url.dart       # API Endpoints
├── features/              # Feature Modules (Screens/Logic)
│   ├── client/            # Client-specific features (Booking, Home)
│   ├── partner/           # Partner-specific features (Orders, Portfolio)
│   ├── common/            # Shared features (Auth, Splash)
│   └── components/        # Shared UI Widgets (Atoms/Molecules)
└── main.dart              # Entry Point
```

### Feature Module Structure (Strict)

Path: `lib/features/<role>/<feature_name>/`

- `controller.dart`: Business logic, state management (`Rx` variables).
- `view.dart`: Main screen UI (extends `GetView<T>`).
- `widgets/`: Local widgets used _only_ in this feature.
- `binding.dart`: Dependency injection for the feature (controllers, services).

---

## 3. Workflow & Automation: Creating Features

Thay vì tạo thủ công từng file, hãy sử dụng **Mason** để đảm bảo tính đồng nhất cấu trúc (Boilerplate).

### Lệnh khởi tạo Feature

```bash
mason make feature
```

### Các tham số cấu hình:

- **name**: Tên tính năng (VD: `login`, `order_history`). Dùng `snake_case`.
- **role**: Thư mục chứa feature (`client`, `partner`, hoặc `common`).
- **use_repository**: `true` (Tự động tạo Repository/Interface trong `data/` và `domain/`) hoặc `false` (Chỉ tạo UI/Controller trong `features/`).

**Ví dụ lệnh nhanh (CLI):**

```bash
mason make feature --name profile_settings --role client --use_repository true
```

> **Note**: Lệnh này tự động sinh ra cấu trúc file chuẩn tại `lib/features/client/profile_settings` và các file data/domain tương ứng theo đúng kiến trúc DDD.

---

## 4. Tech Stack & Toolkit

### Core Libraries

- **State Mngt**: `GetX` (Reactive programming with `.obs`).
- **Networking**: `dio` + `pretty_dio_logger`.
- **Local Storage**: `get_storage` (preferences), `sqflite` (relational data).
- **Utility**: `dartz` (optional, for Either), `intl` (formatting).

### UI & Design System

- **Framework**: `forui` (Primary Design System).
  - Use: `FButton`, `FCard`, `FScaffold`, `FTextField`, `FLabel`.
  - **Constraint**: Do not use Material/Cupertino widgets if a `forui` equivalent exists.
- **Font**: **Lexend** (Google Fonts).
- **Icons**: `cupertino_icons` (primary) or `forui_assets`.
- **Assets**: Use `flutter_gen` or define const paths in `AppAssets`.

## 5. Coding Standards (Critical)

### Dart & Flutter Best Practices

1. **Immutability**: Use `final` for variables and `const` for constructors.
2. **Typing**: Always specify types. Avoid `dynamic`.
3. **Async**: Use `async/await` over raw `.then()`. Handle try-catch in Controllers.
4. **Imports**: Relative imports for internal feature files, absolute imports for core/shared.

### GetX Specific Rules

1. **Memory**: Use `Get.lazyPut(() => Controller())` in Bindings.
2. **Reactive State**: Use `Obx(() => ...)` wrapping only the specific widget that changes.
3. **Controllers**: NEVER pass `BuildContext` to Controllers.

## 6. Error Handling & Logging

### Standardized Error Handling

Sử dụng `ErrorHandler` và `AppSnackbar` (custom wrapper) để hiển thị lỗi cho người dùng.

```dart
try {
  final response = await apiProvider.getData();
} catch (e) {
  ErrorHandler.handle(e);
  AppSnackbar.showError(title: 'Error', message: e.toString());
}
```

## 7. Implementation Checklist (AI Step-by-Step)

1. **Model**: Define data structure.
2. **Repository/Provider**: Define API call logic.
3. **Controller**: Implement business logic & state.
4. **Binding**: Connect Controller to DI.
5. **View**: Build UI using `ForUI`.
6. **Route**: Add to `AppPages`.

## 8. Command Palette

- **Mason Make**: `mason make feature --name <name> --role <role>`

---

_Reminder: Prioritize "Working Code" but strictly adhere to "Clean Architecture"._
