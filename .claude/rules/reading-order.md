# Mandatory Reading Order

Every session — no exceptions — must read these files before making any decision, writing any code, or answering any design question:

1. `CLAUDE.md` — stack, architecture, commands, don'ts
2. `AGENT.md` — design tokens, screen specs, MoSPAMS domain, vibe coding rules
3. `SCREENS.md` — full route map and per-screen component spec
4. `Mobile reference image/` — visual reference images (1.jpg through 13.5.jpg)

## Hard Rules

- Do not mention, comment, or use any other app or project name anywhere in code, strings, comments, or documentation. The only app name is **DC Motorcycle Inventory**.
- All UI decisions must trace back to the approved reference images in `Mobile reference image/` or an explicit user instruction — not from personal knowledge of other apps.
- If a screen is not covered in `SCREENS.md`, ask the user before inventing it.
- Track all changes in CHANGELOG.md (create it if missing) — one line per feature completed, format: `[YYYY-MM-DD] feature: description`.
- After completing any screen or feature, update the Build Order checkboxes in `SCREENS.md`.
