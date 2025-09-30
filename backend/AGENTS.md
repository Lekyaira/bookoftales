# Repository Guidelines

## Project Structure & Modules
- `src/main.rs`: Rocket entrypoint; mounts routes and `/docs` (Swagger UI).
- `src/routes.rs`: Public HTTP routes (`/test`, etc.).
- `src/config.rs`: Loads settings via Figment + dotenv; reads `BOOK_*` and `SECRET`.
- `src/db.rs`: Postgres pool (`BookDB`) using `rocket_db_pools`/`sqlx`.
- `src/auth/*`: Auth modules (login, cookies, JWT, roles, users).
- `.env` / `env_example`: Local configuration (database URLs, pool sizes, timeouts).
- `shell.nix` + `.direnv/`: Nix-based dev environment (optional).

## Build, Test, Run
- Build: `cargo build` — compiles the backend.
- Run (dev): `cargo run` (example: `ROCKET_PORT=8080 cargo run`).
- Tests: `cargo test` — runs unit/integration tests (add as needed).
- Lint: `cargo clippy -- -D warnings` — fail on warnings.
- Format: `cargo fmt --all` — apply standard formatting.
- Nix (optional): `direnv allow` then `nix-shell` to enter a pinned toolchain.

## Coding Style & Naming
- Use Rust 2024 edition idioms; 4-space indentation; snake_case for files/functions, PascalCase for types, SCREAMING_SNAKE_CASE for consts/env.
- Keep modules focused and small; prefer `mod.rs` re-exports for clean APIs.
- Always run `cargo fmt` and `cargo clippy` before pushing.

## Testing Guidelines
- Unit tests: colocate with code using `#[cfg(test)] mod tests { ... }`.
- Integration tests: place in `tests/` (e.g., `tests/routes_test.rs`).
- Prefer table-driven tests; cover auth flows and DB queries with realistic data.
- Run with a test database; never point tests at production.

## Commit & PR Guidelines
- Commits: imperative, concise subjects (<= 72 chars). Example: `Add login endpoint validation`.
- Scope changes logically; one topic per commit.
- PRs: clear description, linked issues, how-to-test steps, and notes on config (`.env` keys) or DB impacts. Add screenshots or cURL examples for new endpoints.

## Security & Configuration
- Secrets: never commit real `.env`. Copy `env_example` and fill local values (e.g., `BOOK_HOST`, `SECRET`).
- Cookies/JWT: defaults are strict (`HttpOnly`, `Secure`, `SameSite=Strict`); adjust with caution.
- DB: ensure Postgres is reachable before `cargo run`.
