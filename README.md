

# SGT-WATCH

A fun Bash script for Dart programmers! Monitors `main.dart` with real-time, military-themed feedback. Sergeants deliver dramatic and sarcastic chatter for empty files, errors, or successes, while the Believing Soldier offers encouragement. Perfect for Dart beginners!

## Features
- Watches `main.dart` for changes (Linux).
- Military-style chatter for:
  - Empty files (sarcastic remarks).
  - Errors (with debug tips for `NoSuchMethodError`, `FormatException`, etc.).
  - Interactive code (manual run instructions for `readLineSync`).
  - Successful runs (celebratory messages).
- **Believing Soldier**: Optional encouraging messages to keep you motivated.
- Idle chatter after 10 minutes of inactivity.
- Customize chatter in `sgt_tmp/` files.
- Username authentication.

## Prerequisites
- **Dart SDK**: [Install](https://dart.dev/get-dart)
  ```bash
  dart --version
  ```
- **Linux**: Install `inotify-tools` and `coreutils`:
  ```bash
  sudo apt-get install inotify-tools coreutils
  ```
- **macOS**: Install `fswatch`:
  ```bash
  brew install fswatch
  ```
  Edit script to use `fswatch -o "$DART_FILE" | while read -r; do ...`.
- **Windows**: Use WSL2 with Linux dependencies.
- **Git**: [Install](https://git-scm.com/downloads)
  ```bash
  git --version
  ```

## Installation
1. Clone the repo:
   ```bash
   git clone https://github.com/BiqqMax/sgt-watch.git
   cd sgt-watch
   ```
2. Make script executable:
   ```bash
   chmod +x sgt-watch.sh
   ```
3. Create or edit `main.dart`.
4. Run:
   ```bash
   ./sgt-watch.sh
   ```

## Usage
1. Enter username (e.g., `admin`, `commander`).
2. Edit and save `main.dart` to see feedback:
   - **Empty file**: Sarcastic sergeant remarks.
   - **Errors**: Debug tips (e.g., "💡 Use try-catch with int.parse()").
   - **Interactive code**: Instructions to run `dart main.dart` manually.
   - **Success**: Celebratory messages with Believing Soldier encouragement (if enabled).
3. Idle chatter triggers after 10 minutes.
4. Customize chatter in `sgt_tmp/` files.

## Example
Create `main.dart`:
```dart
void main() {
  print('Hello, Dart programmers!');
}
```

Run:
```bash
./sgt-watch.sh
```

Output:
```
[BASE COMMS // WAR ROOM MSGS] 📡
💂 Sgt_Vortex: Chief, commander, what sorcery is this? main.dart just... worked?!
💂 Sgt_Blaze: Oh, sure, commander, beginner's luck strikes again. Whatever.
💂 Believing Soldier: You've got this, commander! main.dart's cheering for you!
----
[RADIO REPORT BOARD] 🎙
💂 Sgt_Storm relaying live fire reports:
-------------------------------------------------------------
Hello, Dart programmers!
-------------------------------------------------------------
```

## Configuration
Edit `sgt-watch.sh` variables:
- `DART_FILE`: File to monitor (default: `main.dart`).
- `IDLE_DELAY`: Seconds before idle chatter (default: 600).
- `IDLE_INTERVAL`: Seconds between idle messages (default: 10).
- `IDLE_CHATTER_COUNT`: Max idle messages (default: 3).
- `BELIEVING_SOLDIER_ENABLED`: Enable/disable Believing Soldier (default: `true`).
- `AUTH_USERS`: Allowed usernames (default: `admin`, `commander`, `general`, `captain`, `lieutenant`).
- `SERGEANTS`: Sergeant names (default: `Sgt_Vortex`, `Sgt_Blaze`, `Sgt_Iron`, `Sgt_Storm`, `Sgt_Hawk`).

## Customizable Chatters
Edit files in `sgt_tmp/` (created on first run):
- `output_chatters_line1.txt`, `output_chatters_line2.txt`: Success messages.
- `error_chatters_line1.txt`, `error_chatters_line2.txt`: Error messages.
- `empty_chatter_line1.txt`, `empty_chatter_line2.txt`: Empty file messages.
- `hush_chatters.txt`, `hush_instructions.txt`: Interactive code messages.
- `idle_chatters.txt`, `idle_notices.txt`: Idle messages.
- `believing_soldier_chatters.txt`: Encouraging messages (if enabled).

Use `$USERNAME` or `$RANDOM_USER` (random authorized user) in chatter files for personalization.

## Limitations
- Linux-only by default (`inotify-tools`). macOS/Windows need tweaks.
- Monitors one file (configurable).
- Covers common Dart errors; may miss rare ones.
- 2-second timeout may interrupt long programs.

## Contributing
1. Fork the repo.
2. Create a branch: `git checkout -b my-feature`.
3. Commit: `git commit -m "Add feature"`.
4. Push: `git push origin my-feature`.
5. Open a pull request.

Report issues: [GitHub Issues](https://github.com/BiqqMax/sgt-watch/issues).

## License
[MIT License](LICENSE)

## Contact
Open an issue or ping me on [Twitter/X](https://x.com/BiqqMax) with #SGTWatch.

