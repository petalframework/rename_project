# RenameProject

A lightweight Mix task and Elixir utility for renaming Elixir and Phoenix projects cleanly across all casing conventions and directory structures.

## Features

* **Automatic Casing Derivation:** Pass in any format (`AshPhoenixStarter`, `ash_phoenix_starter`, or `ash-phoenix-starter`) and it automatically updates:
  * **PascalCase:** `AshPhoenixStarter` → `AcmePortal`
  * **snake_case:** `ash_phoenix_starter` → `acme_portal`
  * **kebab-case:** `ash-phoenix-starter` → `acme-portal`
  * **UPPER_SNAKE_CASE:** `ASH_PHOENIX_STARTER` → `ACME_PORTAL`
  * **Title Case:** `Ash Phoenix Starter` → `Acme Portal`
* **Safe Dry Run Mode:** Preview every file edit and path rename before modifying disk.
* **Smart Path Renaming:** Safely renames nested directories and files bottom-up so parent renames never break child paths.

## Installation

Add `rename_project` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rename_project, "~> 0.2.0", only: :dev, runtime: false}
  ]
end
```

## CLI Usage (`mix rename`)

### 1. Preview Changes First (Recommended)

Always run with `--dry-run` (or `-d`) first to verify what will change:

```bash
mix rename AshPhoenixStarter AcmePortal --dry-run
```

### 2. Apply the Rename

Once you're happy with the preview, run the command without `--dry-run`:

```bash
mix rename AshPhoenixStarter AcmePortal
```

### CLI Options

| Flag | Alias | Description |
| :--- | :--- | :--- |
| `--dry-run` | `-d` | Preview all content changes and file renames without writing to disk. |
| `--starting-directory` | | Target directory to run in (defaults to `.`). |
| `--ignore-directories` | | Repeatable flag to append extra directories to ignore. |
| `--ignore-files` | | Repeatable flag to append extra filenames to ignore. |
| `--include-extensions` | | Repeatable flag to append extra file extensions to scan. |
| `--include-files` | | Repeatable flag to force specific filenames to be scanned regardless of extension. |

#### Example with Custom Flags

```bash
mix rename AshPhoenixStarter AcmePortal \
  --starting-directory ./my_project \
  --ignore-directories priv \
  --ignore-directories rel \
  --include-extensions .txt
```

## Programmatic Usage

You can also call `RenameProject` directly in Elixir or IEx:

```elixir
# Preview changes
{:ok, report} = RenameProject.run({"AshPhoenixStarter", "AcmePortal"}, dry_run: true)

# Apply changes
:ok = RenameProject.run({"AshPhoenixStarter", "AcmePortal"})

# Explicit module and OTP names (backwards-compatible)
:ok = RenameProject.run(
  {"AshPhoenixStarter", "AcmePortal"},
  {"ash_phoenix_starter", "acme_portal"},
  ignore_directories: ["custom_dir"]
)
```

## Defaults

* **Included Extensions:** `.ex`, `.exs`, `.eex`, `.heex`, `.leex`, `.md`, `.json`, `.yml`, `.yaml`, `.toml`, `.env`, `.sh` (plus extensionless files like `Dockerfile`)
* **Included Files:** `mix.exs`, `Dockerfile`, `.formatter.exs`
* **Ignored Directories:** `.elixir_ls`, `.vscode`, `.git`, `_build`, `deps`, `assets`, `node_modules`
