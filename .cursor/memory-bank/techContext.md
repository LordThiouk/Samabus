# Tech Context

## Core Technologies
- **Frontend:** Flutter SDK (for cross-platform Mobile & Web)
- **Backend:** Supabase (PostgreSQL DB, Authentication, Storage, Auto-generated REST APIs)
- **Local Storage:** Hive (`hive_flutter` package) for offline data caching (e.g., ticket validation data).

## Key Dependencies (`pubspec.yaml`)
- `flutter`, `flutter_localizations`
- `supabase_flutter` (^1.10.7)
- `provider` (^6.0.5) - State Management
- `intl` (^0.18.0) - Localization
- `qr_flutter` (^4.1.0) - QR Code Generation
- `qr_code_scanner` (^1.0.1) - QR Code Scanning
- `hive_flutter` (^1.1.0) - Local Database
- `connectivity_plus` (^4.0.2) - Network status checking
- `crypto` (^3.0.3) - Cryptographic functions (potentially for data security/hashing)

## Development Dependencies (`pubspec.yaml`)
- `flutter_test`
- `integration_test`
- `flutter_lints` (^3.0.0)
- `mockito` (^5.4.4)
- `build_runner` (^2.4.9) - *Note: Downgraded from >=2.4.10 due to Dart SDK 3.2.3 incompatibility.*

## Development Setup
- **IDE:** VS Code recommended (with Flutter & Dart extensions)
- **Version Control:** Git (repository likely hosted on GitHub)
- **Task Management:** Task Master AI (`task-master-ai` npm package installed locally, run via `npx`)
- **Package Management (Windows):** Scoop (used to install Supabase CLI)
- **Backend CLI:** Supabase CLI (v2.22.6 installed via Scoop)
- **Dart SDK:** 3.2.3 (via Flutter SDK)

## Technical Constraints
- Offline ticket validation must work for up to 24 hours.
- CNI/Personal data retention limited to 30 days post-trip.
- Initial language support: French & English.
- Requires integration with specific payment gateways: PayDunya & CinetPay. 