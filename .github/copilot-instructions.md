# Copilot Instructions — Çetele

## Scope discipline
- Keep changes strictly minimal: only touch what the task requires. Don't refactor, rename, reformat, or "improve" unrelated code.
- Never remove or restructure an existing working UI layout unless the task explicitly asks for it. Preserve existing widget trees, spacing, and navigation structure.
- Don't add dependencies, abstractions, or helpers for a one-off need.

## Layout & text overflow
- Any `Text` that can render a variable-length or user/locale-provided string (amounts, names, labels in `Row`/fixed-width containers) must be overflow-safe: wrap in `Flexible`/`Expanded`, or set `maxLines` + `overflow: TextOverflow.ellipsis`, or use `FittedBox` when shrinking is preferred over truncation.
- Never place a `Text` or unconstrained widget directly inside a `Row`/`Column` where it could overflow available space — always constrain it.
- When adding buttons/labels to bottom navigation or action bars, verify they fit at the narrowest supported phone width before considering the change done.

## Supabase auth null-safety
- Never assume `SupabaseService.currentUser` (or `client.auth.currentUser`) is non-null. Always null-check before use.
- Any operation requiring a logged-in user must fail gracefully (return empty/default state or a clear message) instead of throwing when there is no session.
- Auth-dependent initialization (e.g. RevenueCat identify, data fetches) must only run when a user id is present, and must also react to `supabase.auth.onAuthStateChange` for later logins — never only at app startup.
- Third-party SDK initialization (RevenueCat, analytics, etc.) must never throw uncaught during app startup; wrap in `try/catch` so a misconfiguration cannot block `runApp()` or Supabase session recovery.

## Validation
- After any change, run `flutter analyze` and ensure 0 errors before considering the task done.
