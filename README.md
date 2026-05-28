# SGT-WATCH

**Real-time `main.dart` monitoring with military-themed feedback for Dart developers.**

SGT-WATCH is a Bash-based file watcher that monitors `main.dart` and provides real-time military-style feedback for file changes, errors, empty files, and successful runs. Built to make learning Dart more engaging for beginners while keeping the development workflow simple and fun.

---

## Features

* **Real-time file watching** for `main.dart`
* **Military-style feedback** for:

  * Empty files
  * Compilation/runtime errors
  * Successful execution
* **Helpful debugging tips** for common Dart exceptions such as `NoSuchMethodError` and `FormatException`
* Detects **interactive programs** and provides manual run instructions for `stdin.readLineSync()`
* Optional **Believing Soldier mode** for motivational messages
* Idle chatter after periods of inactivity
* Fully customizable dialogue via files inside `sgt_tmp/`
* Simple username-based access control
* VS Code extension currently in development: **`sgt-watch-vscode`**

---

## Quick Start

Create a `main.dart` file:

```dart
void main() {
  print('Hello, Dart programmers!');
}
```

Then install **SGT-WATCH** using one of the options below.

---

## Installation

### Option 1 — Clone Repository

```bash
git clone https://github.com/BiqqMax/sgt-watch.git
cd sgt-watch
chmod +x sgt-watch.sh
./sgt-watch.sh
```

Recommended for full access to all project files.

---

### Option 2 — Download with curl

```bash
curl -O https://raw.githubusercontent.com/BiqqMax/sgt-watch/main/sgt-watch.sh
chmod +x sgt-watch.sh
./sgt-watch.sh
```

---

### Option 3 — Download with wget

```bash
wget https://raw.githubusercontent.com/BiqqMax/sgt-watch/main/sgt-watch.sh
chmod +x sgt-watch.sh
./sgt-watch.sh
```

---

### Option 4 — Sparse Checkout (script only)

```bash
git clone --no-checkout https://github.com/BiqqMax/sgt-watch.git
cd sgt-watch
git sparse-checkout init --cone
git sparse-checkout set sgt-watch.sh
git checkout main
chmod +x sgt-watch.sh
./sgt-watch.sh
```

---

### Option 5 — One-line Install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/BiqqMax/sgt-watch/main/sgt-watch.sh)"
```

> Review downloaded scripts before executing remote install commands.

---

## Requirements

### Required

* **Dart SDK**
  Verify installation:

```bash
dart --version
```

* **Git**

```bash
git --version
```

### Linux

Install dependencies:

```bash
sudo apt-get install inotify-tools coreutils
```

### macOS

Install:

```bash
brew install fswatch
```

Then update the watcher command inside `sgt-watch.sh` to use `fswatch`.

### Windows

Run through **WSL2** with Linux dependencies installed.

---

## Usage

Start the watcher:

```bash
./sgt-watch.sh
```

Then edit and save `main.dart`.

Depending on the file state, SGT-WATCH responds with:

* **Empty file** → sarcastic sergeant warnings
* **Errors** → debugging feedback and tips
* **Interactive code** → manual execution instructions
* **Successful run** → celebratory messages
* **Idle mode** → chatter after inactivity

---

## Configuration

Configuration values are located at the top of `sgt-watch.sh`.

| Variable                    |         Default | Description                        |
| --------------------------- | --------------: | ---------------------------------- |
| `DART_FILE`                 |     `main.dart` | File to monitor                    |
| `IDLE_DELAY`                |           `600` | Seconds before idle chatter starts |
| `IDLE_INTERVAL`             |            `10` | Delay between idle messages        |
| `IDLE_CHATTER_COUNT`        |             `3` | Maximum idle messages              |
| `BELIEVING_SOLDIER_ENABLED` |          `true` | Enable motivational messages       |
| `AUTH_USERS`                | predefined list | Allowed usernames                  |

---

## Custom Dialogue (`sgt_tmp/`)

On first run, SGT-WATCH creates an `sgt_tmp/` directory containing editable text files used for all system dialogue.

Examples:

* `output_chatters_line1.txt`
* `output_chatters_line2.txt`
* `error_chatters_line1.txt`
* `error_chatters_line2.txt`
* `empty_chatter_line1.txt`
* `idle_chatters.txt`
* `believing_soldier_chatters.txt`

You can customize messages freely.

Supported placeholders:

* `$USERNAME`
* `$RANDOM_USER`

---

## Limitations

* Linux-first by default (`inotify-tools` required)
* Monitors a single file (`main.dart`)
* Error detection focuses on common Dart exceptions
* Long-running programs may be interrupted due to execution timeout

---

## Contributing

Contributions are welcome.

```bash
git checkout -b feature-name
git commit -m "Add feature"
git push origin feature-name
```

Then open a pull request.

Bug reports and suggestions can be submitted through **GitHub Issues**.

---

## License

MIT License

---

## Contact

Questions, feedback, or ideas:

**X (Twitter):** `@BiqqMax`
Tag: **#SGTWatch**

---

## Roadmap

* VS Code extension (`sgt-watch-vscode`)
* Improved multi-file support
* Additional Dart error handling
* More configurable chatter packs

---

Built for Dart beginners who like fast feedback, command-line tools, and a little chaos.
