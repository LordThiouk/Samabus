
/// Represents the authentication state of the user.
enum AuthStatus {
  uninitialized, // Initial state, before checking session
  authenticating, // Waiting for Supabase auth response (e.g., during sign-in/sign-up call)
  loadingProfile, // Authenticated with Supabase, but fetching user profile/role data
  authenticated, // Fully authenticated, user profile loaded
  unauthenticated, // No user session found or user signed out
  error // An error occurred during an authentication process
} 