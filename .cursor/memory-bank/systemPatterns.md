# System Patterns

## Architecture Overview
- **Unified Codebase:** Flutter project targeting Mobile (Android/iOS) and Web.
- **Backend:** Leverages Supabase for BaaS (Backend as a Service), including Auth, Database (Postgres), and Storage.
- **Frontend Structure:** Standard Flutter feature-based directories observed in `lib/`: `config`, `models`, `providers`, `screens`, `services`, `utils`.
- **State Management:** Uses the `provider` package (`^6.0.5`).
- **Local Storage:** Utilizes `hive_flutter` for offline data caching, primarily for the ticket validation feature.

## Key Design Patterns
- **Provider Pattern:** Employed for state management and dependency injection.
- **Repository Pattern:** Likely intended (implied by rules/structure) for abstracting data access logic (Supabase, Hive) - needs verification in `repositories` directory if it exists/is created.
- **Service Layer:** Used for encapsulating business logic and third-party integrations (e.g., Payments, Notifications) - `services` directory exists.
- **Model Classes:** Data structures defined in `models/` (contents need verification).

## Data Flow
- UI (Screens) interacts with Providers.
- Providers orchestrate calls to Services and/or Repositories.
- Services handle business logic and external API calls (Supabase, Payments).
- Repositories manage data persistence (Supabase DB, Hive local cache).

## Offline Functionality
- Ticket validation data (QR/CNI hashes/references) is cached locally using Hive.
- `connectivity_plus` likely used to detect network status.
- Background sync mechanism (details TBD) needed to push offline validation logs to Supabase upon reconnection. 