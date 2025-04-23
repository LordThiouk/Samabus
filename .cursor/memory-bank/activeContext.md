# Active Context

## Current Focus
- **Task 1.3 (In Progress):** Implement Authentication UI and Role-Based Navigation.

## Recent Changes
- **Completed Subtask 1.1 (`SignupScreen` UI):**
    - Resolved numerous linter errors and warnings.
    - Code passes `flutter analyze` with only info-level suggestions.
- **Completed Subtask 1.2 (DB Schema / Models):**
    - Created initial schema migration file.
    - Created RLS policy migration file.
    - Created/Updated all Dart model files (`User`, `Profile`, `Bus`, `Trip`, `Booking`, `Passenger`, `Payment`, `Notification`, `ScanLog`).
- Marked Task 1.2 as done.
- Marked Task 1.3 as in-progress.

## Current State
- Project structure initialized.
- Basic Auth UI (`SignupScreen`, `LoginScreen`) implemented.
- Database schema and Dart models defined.
- Initial RLS policies defined.
- Code is free of critical errors and warnings.
- Task 1.3 (Auth UI / Navigation) is now in progress.

## Blocking Issues / Known Issues
- **Analyzer Info Messages:** Several `const` suggestions remain (non-blocking).
- **Placeholders:** UI text uses placeholder strings; localization not yet implemented.
- **Incomplete Backend Integration:** Auth UI logic exists but needs full testing and refinement.
- **Migrations:** DB migration files need timestamps updated and must be applied to Supabase.

## Next Steps
1. Begin detailed implementation of **Task 1.3 (Auth UI / Navigation)**:
    - Create `ForgotPasswordScreen` UI.
    - Determine need for/create Verification Screen UI.
    - Connect Auth UI screens fully to `AuthProvider`/`AuthService`.
    - Implement role-based navigation.
2. Apply DB migrations to Supabase project. 