# Follow-Up Planner

## 1. Project Overview

Follow-Up Planner is a Flutter application designed to help sales teams manage and schedule follow-up calls with leads.

The application automatically schedules calls based on business working hours, call priorities, holidays, lunch breaks, and daily call limits.

It also provides call management, day blocking, automatic rescheduling, and undo/redo functionality.

## 2. Main Features

* Weekly calendar-style view from Monday to Saturday.
* Add new follow-up calls.
* Edit existing calls.
* Delete follow-up calls.
* Automatic call scheduling.
* Hot, Warm, and Cold call priorities.
* Automatic rescheduling when a day is blocked.
* Daily call limit of 6 calls.
* 30-minute call duration.
* IST-based date and time handling.
* Company holiday management.
* Weekly deal value and call summary.
* Undo and redo functionality with a maximum of 20 steps.
* SQLite database for persistent storage.
* Indian currency formatting.

## 3. Scheduling Rules

### Working Days

* Monday to Saturday are considered working days.
* Sundays are non-working days.
* The second and fourth Saturdays of each month are non-working days.
* Company holidays are treated as non-working days.

### Working Hours

* Working hours are from 09:30 AM to 06:30 PM IST.
* Each follow-up call has a duration of 30 minutes.
* Calls can start only at :00 or :30.
* The last call can start at 06:00 PM.
* Lunch break is from 01:00 PM to 02:00 PM.

### Daily Call Limit

* A maximum of 6 calls can be scheduled per day.
* The same phone number cannot have two calls on the same day.

### Automatic Scheduling

* If the requested time is unavailable, the scheduler searches forward for the next available slot.
* Calls are never moved backward.
* Hot calls receive scheduling priority.
* Hot calls must be scheduled within one working day of the requested date.
* If necessary, the latest Cold call can be moved to make room for a Hot call.
* If a day is blocked, all its calls are moved to subsequent working days.
* During day blocking, calls are rescheduled in Hot, Warm, and Cold priority order.
* Original time order is preserved within the same priority.

### Undo and Redo

* A maximum of 20 undo steps are maintained.
* Blocking a day and rescheduling its calls count as one undo action.
* A new action after undo clears the redo history.

## 4. Architecture

The application follows a layered architecture to separate business logic, data handling, and presentation.

### Core

Contains shared application constants, utilities, and exception handling.

### Domain Layer

Contains the main business entities, repository contracts, and scheduling services.

### Data Layer

Handles SQLite database operations, local data sources, models, and repository implementations.

### Presentation Layer

Contains Flutter screens, reusable widgets, and Provider-based state management.

### Main Scheduling Services

* SchedulingSlotGenerator: Generates valid call slots.
* NextAvailableSlotFinder: Finds the next available slot.
* NormalCallScheduler: Schedules Warm and Cold calls.
* HotCallScheduler: Handles Hot call scheduling rules.
* DayBlockingService: Reschedules calls when a day is blocked.
* UndoRedoManager: Manages undo and redo history.

## 5. Database and Persistence

* SQLite is used for local data storage.
* Follow-up call information is persisted.
* Blocked dates are persisted.
* Schedule changes are saved to the database.
* Calls remain available after closing or restarting the application.
* Undo and redo history does not need to persist after application restart.

## 6. State Management

Provider is used for application state management.

FollowUpProvider handles:

* Loading calls and blocked dates.
* Adding calls.
* Editing calls.
* Deleting calls.
* Blocking days.
* Undo and redo operations.
* Updating the UI when application data changes.

## 7. Running the Application

### Prerequisites

* Flutter SDK installed.
* Dart SDK.
* Android Studio or VS Code.
* Android emulator or physical Android device.

### Install Dependencies

Run:

```bash
flutter pub get
```

### Run the Application

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

## 8. Running Tests

Run all unit and widget tests:

```bash
flutter test
```

Run tests with detailed output:

```bash
flutter test --reporter expanded
```

Check code quality:

```bash
flutter analyze
```

Format Dart files:

```bash
dart format .
```

## 9. Test Coverage

The project includes tests for:

* Indian currency formatting.
* IST date and working-day calculations.
* Repository operations.
* Normal call scheduling.
* Hot call scheduling.
* Available time-slot generation.
* Day blocking and automatic rescheduling.
* Undo and redo functionality.
* Application widget loading.

The latest test execution completed successfully with **71 passing tests**.


