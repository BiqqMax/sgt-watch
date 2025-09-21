# SGT-WATCH

**A fun Bash watcher for Dart — military-flavored feedback for beginners**

Monitors `main.dart` for changes and responds with dramatic, sarcastic, and encouraging chatter. Great teaching tool for new Dart programmers.

---

## Features

- Watches `main.dart` for changes (Linux by default).
- Military-style chatter for:
  - **Empty files** (sarcastic sergeants).
  - **Errors** (debug tips for common Dart exceptions such as `NoSuchMethodError`, `FormatException`, etc.).
  - **Successful runs** (celebratory messages).
- Detects interactive programs and prints manual-run instructions (for `stdin.readLineSync()`-style code).
- Optional **Believing Soldier** — encouraging messages to keep you motivated.
- Idle chatter after 10 minutes of inactivity.
- Customize all chatter via files in `sgt_tmp/`.
- Username authentication for playful access control.
- VS Code extension in development: **sgt-watch-vscode**.

---

## Quick example

Create `main.dart`:

```dart
void main() {
  print('Hello, Dart programmers!');
}
```

Make the script executable and run the watcher:

```bash
chmod +x sgt-watch.sh
./sgt-watch.sh
```

You will see sergeant-style messages, a radio-style report of program output, and an encouraging message from the Believing Soldier if enabled.

---

## Prerequisites

- **Dart SDK** — verify with `dart --version`.
- **Linux:** `inotify-tools` and `coreutils` (e.g. `sudo apt-get install inotify-tools coreutils`).
- **macOS:** install `fswatch` (`brew install fswatch`) and replace the watch command with `fswatch -o "$DART_FILE" | while read -r; do ...` in the script.
- **Windows:** run under WSL2 and install the Linux dependencies.
- **Git** — `git --version`.

---

## Installation

```bash
# Clone the repo
git clone https://github.com/BiqqMax/sgt-watch.git
cd sgt-watch
# Make script executable
chmod +x sgt-watch.sh
# Edit or create main.dart then run
./sgt-watch.sh
```

---

## Usage

1. Run `./sgt-watch.sh` and enter a username when prompted (default allowed users include `admin`, `commander`, `general`, `captain`, `lieutenant`).
2. Edit and save your `main.dart` to trigger feedback:
   - **Empty file:** sarcastic sergeant lines.
   - **Errors:** error chatter with debug tips (e.g. “💡 Use try-catch with `int.parse()`”).
   - **Interactive code:** instructions to run `dart main.dart` manually.
   - **Success:** celebratory messages and Believing Soldier encouragement (if enabled).
3. Idle chatter starts after the configured delay (default 600 seconds / 10 minutes).

---

## Configuration

Edit variables at the top of `sgt-watch.sh`:

| Variable | Default | Description |
|---|---:|---|
| `DART_FILE` | `main.dart` | File to monitor |
| `IDLE_DELAY` | `600` | Seconds before idle chatter |
| `IDLE_INTERVAL` | `10` | Seconds between idle messages |
| `IDLE_CHATTER_COUNT` | `3` | Max idle messages |
| `BELIEVING_SOLDIER_ENABLED` | `true` | Toggle encouraging messages |
| `AUTH_USERS` | `admin, commander, general, captain, lieutenant` | Allowed usernames |

---

## Customizable chatter files (`sgt_tmp/`)

On first run the script creates `sgt_tmp/` with these files. Edit them to change the messages used by the watcher.

- `output_chatters_line1.txt`, `output_chatters_line2.txt` — success messages
- `error_chatters_line1.txt`, `error_chatters_line2.txt` — error messages
- `empty_chatter_line1.txt`, `empty_chatter_line2.txt` — empty file messages
- `hush_chatters.txt`, `hush_instructions.txt` — interactive-code messages
- `idle_chatters.txt`, `idle_notices.txt` — idle messages
- `believing_soldier_chatters.txt` — encouraging messages (if enabled)

You can use `$USERNAME` or `$RANDOM_USER` in these files to personalize messages.

---

## Limitations

- Linux-only by default (requires `inotify-tools`). macOS and Windows need adjustments.
- Monitors a single file by default.
- Covers common Dart errors but might miss rare cases.
- The watcher uses a 2-second timeout for runs; long-running programs may be interrupted.

---

## Contributing

1. Fork the repo and create a branch: `git checkout -b my-feature`
2. Commit your changes: `git commit -m "Add feature"`
3. Push and open a pull request: `git push origin my-feature`

Report issues via GitHub Issues.

---

## License

MIT License

---

## Contact

Open an issue or ping on X (Twitter): [@BiqqMax](https://x.com/BiqqMax) — tag `#SGTWatch`.

---

*VS Code extension `sgt-watch-vscode` is in development for seamless IDE integration.*
