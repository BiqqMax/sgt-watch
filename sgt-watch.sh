#!/bin/bash

# Configuration Section
DART_FILE="main.dart"  # Default file to watch
TMP_DIR="./sgt_tmp"  # Temporary directory for chatter files
IDLE_DELAY=600  # Seconds before idle chatter starts (10 minutes)
IDLE_INTERVAL=10  # Seconds between idle messages
IDLE_CHATTER_COUNT=3  # Number of idle chatter messages
BELIEVING_SOLDIER_ENABLED=true  # Whether to include believing soldier messages in idle chatter
AUTH_USERS=("admin" "commander" "general" "captain" "lieutenant")  # Authorized users - sergeants can mention these
SERGEANTS=("Sgt_Vortex" "Sgt_Blaze" "Sgt_Iron" "Sgt_Storm" "Sgt_Hawk")  # Sergeant names
# Colors
ORANGE='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
GREY='\033[1;90m'
NC='\033[0m'

# Inline welcome chatters - SHORTENED to maintain single line
WELCOME_CHATTERS=(
    "Welcome, Commander! $DART_FILE's your battlefield!"
    "Commander! $DART_FILE awaits your orders!"
    "Finally showed up, hotshot? Check the [RADIO REPORT BOARD]!"
    "$USERNAME graces us? [RADIO REPORT BOARD]'s calling, genius!"
    "$USERNAME the hero? Prove it at [RADIO REPORT BOARD]!"
)

# Function to randomly pick an authorized user
pick_random_user() {
    echo "${AUTH_USERS[$((RANDOM % ${#AUTH_USERS[@]}))]}"
}

# Function to generate chatter content with random user mentions
generate_chatter_content() {
    local template="$1"
    local random_user
    random_user=$(pick_random_user)
    echo "${template//\$RANDOM_USER/$random_user}"
}

# Function to check if file is empty or entirely commented - FIXED VERSION
is_file_empty_or_commented() {
    local file="$1"
    
    # Check if file is empty (0 bytes)
    if [ ! -s "$file" ]; then
        return 0
    fi
    
    # Read entire file content
    local content
    content=$(cat "$file")
    
    # Check if file contains only whitespace
    if [[ "$content" =~ ^[[:space:]]*$ ]]; then
        return 0
    fi
    
    # Remove comments and whitespace, then check if anything remains
    # This handles both single-line (//) and multi-line (/* */) comments
    local cleaned_content
    cleaned_content=$(echo "$content" | sed -E '
        # Remove multi-line comments /* ... */
        :a
        /\/\*.*\*\// {
            s/\/\*.*\*\///g
            ba
        }
        # Remove single-line comments // ...
        s|//.*$||g
        # Remove empty lines and whitespace-only lines
        /^\s*$/d
        # Remove lines that are now just whitespace after comment removal
        s/^[[:space:]]*$//
        /^\s*$/d
    ')
    
    # If cleaned content is empty, the file was all comments/whitespace
    if [[ -z "$cleaned_content" ]]; then
        return 0
    fi
    
    return 1  # Has actual code
}

# Function to check if readLineSync is actively used (not commented)
check_active_readlinesync() {
    local file="$1"
    # Strip multi-line comments first
    local stripped=$(sed ':a; s/\/\*.*?\*\///g; ta' "$file" | sed 's/\/\/.*//g')
    # Check if readLineSync is present in stripped content
    echo "$stripped" | grep -q "readLineSync"
}

# Function to detect common Dart errors
detect_dart_error() {
    local output="$1"
    # Common Dart error patterns
    if echo "$output" | grep -q -E "(Error:|Exception:|NoSuchMethodError|FormatException|TypeError|CastError|ArgumentError|StateError|RangeError|UnsupportedError|UnimplementedError|FormatException)"; then
        return 0  # Error detected
    else
        return 1  # No error
    fi
}

# Function to check if output indicates interactive program (contains prompts)
is_interactive_output() {
    local output="$1"
    # Check for common interactive prompts
    if echo "$output" | grep -q -E "(Enter|Input|Name|Password|Press|Type|stdout\.write)"; then
        return 0  # Interactive output detected
    else
        return 1  # Normal output
    fi
}

# Function to generate concise error instructions
generate_error_instructions() {
    local error_type="$1"
    local output="$2"
    
    case "$error_type" in
        "NoSuchMethodError")
            echo "💡 Check method names - Dart is case-sensitive!"
            ;;
        "FormatException")
            echo "💡 Input parsing issue - use try-catch with int.parse()"
            ;;
        "TypeError"|"CastError")
            echo "💡 Type mismatch - use 'as' keyword or 'is' checking"
            ;;
        "ArgumentError")
            echo "💡 Wrong number of arguments - check function calls"
            ;;
        "RangeError")
            echo "💡 Index out of bounds - check list.length first"
            ;;
        "StateError")
            echo "💡 Invalid stream operation - check stream state"
            ;;
        *)
            echo "💡 Check error above - add print() statements to debug"
            ;;
    esac
}

# Function to install dependencies
install_dependencies() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check for inotify-tools and coreutils
        if ! command -v inotifywait &> /dev/null || ! command -v timeout &> /dev/null; then
            echo "Installing required dependencies (inotify-tools, coreutils)..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y inotify-tools coreutils
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y inotify-tools coreutils
            elif command -v yum &> /dev/null; then
                sudo yum install -y inotify-tools coreutils
            else
                echo "Error: No supported package manager found (apt-get, dnf, yum). Install 'inotify-tools' and 'coreutils' manually."
                exit 1
            fi
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS detected. This script requires 'fswatch'. Install it with 'brew install fswatch'."
        echo "Then, modify the script to use 'fswatch -o \"$DART_FILE\" | while read -r; do ...' instead of inotifywait."
        exit 1
    else
        echo "Unsupported OS or WSL2 detected. Please use WSL2 on Windows with 'inotify-tools' and 'coreutils' installed."
        echo "Run 'sudo apt-get install inotify-tools coreutils' in WSL2."
        exit 1
    fi

    # Check if dart is installed
    if ! command -v dart &> /dev/null; then
        echo "Error: Dart SDK is not installed. Install it from https://dart.dev/get-dart."
        exit 1
    fi
}

# Function to check user authentication
check_user_auth() {
    echo -n "Who are you, Commander? "
    read -r USERNAME
    authorized=0
    for user in "${AUTH_USERS[@]}"; do
        if [ "$USERNAME" = "$user" ]; then
            authorized=1
            break
        fi
    done
    if [ "$authorized" -eq 0 ]; then
        echo -e "${RED}Access denied. 🚫${NC}"
        exit 1
    fi
}

# Function to create temporary chatter files with line-specific structure and random user mentions
create_tmp_files() {
    mkdir -p "$TMP_DIR"
    # Ensure directory is writable
    if [ ! -w "$TMP_DIR" ]; then
        echo "Error: Cannot write to $TMP_DIR. Check permissions."
        exit 1
    fi
    
    # OUTPUT CHATTERS - Line 1: Dramatically confused and asking (mentions random authorized users)
    cat << 'EOF' > "$TMP_DIR/output_chatters_line1.txt"
Chief, $RANDOM_USER, what sorcery is this? $DART_FILE just... worked?!
$RANDOM_USER, hold on—did $DART_FILE actually do what it was supposed to?!
Wait, $RANDOM_USER, are you seeing this? $DART_FILE output looks... legitimate?!
$RANDOM_USER, explain yourself! How did you make $DART_FILE behave like that?!
Hold the phone, $RANDOM_USER—did $DART_FILE just solve the unsolvable?!
$RANDOM_USER, I need backup! $DART_FILE just gave us perfect output!
Is this real life, $RANDOM_USER? $DART_FILE actually succeeded?!
$RANDOM_USER, call the brass! $DART_FILE just pulled off a miracle!
EOF

    # OUTPUT CHATTERS - Line 2: Undermining sarcasm to hide resentment or jealousy (mentions random users)
    cat << 'EOF' > "$TMP_DIR/output_chatters_line2.txt"
Oh, sure, $RANDOM_USER, beginner's luck strikes again. Whatever.
Well, $RANDOM_USER, I guess even a broken clock is right twice a day.
Congratulations, $RANDOM_USER. You accidentally stumbled into competence.
Must be nice, $RANDOM_USER, having $DART_FILE carry you like that.
Yeah, $RANDOM_USER, we see your little $DART_FILE magic trick. Cute.
$RANDOM_USER's $DART_FILE output? Probably copied from Stack Overflow.
Oh look, $RANDOM_USER actually made something work. Alert the media!
$RANDOM_USER, your $DART_FILE success is giving me second-hand embarrassment.
EOF

    # ERROR CHATTERS - Line 1: Dramatically confused and asking (mentions random authorized users)
    cat << 'EOF' > "$TMP_DIR/error_chatters_line1.txt"
$RANDOM_USER, what fresh hell is this? $DART_FILE just imploded!
Hold up, $RANDOM_USER—why is $DART_FILE screaming in binary?!
$RANDOM_USER, did you just declare war on $DART_FILE? It's fighting back!
What did you DO, $RANDOM_USER? $DART_FILE looks like it saw a ghost!
$RANDOM_USER, $DART_FILE is having an existential crisis over here!
$RANDOM_USER, abort mission! $DART_FILE just went full panic mode!
Did $RANDOM_USER just break reality? $DART_FILE's throwing a tantrum!
$RANDOM_USER, $DART_FILE's error messages need their own zip code!
EOF

    # ERROR CHATTERS - Line 2: Mocking with huge sarcasm (mentions random users)
    cat << 'EOF' > "$TMP_DIR/error_chatters_line2.txt"
Oh, BRILLIANT work, $RANDOM_USER. $DART_FILE thanks you for the entertainment.
Well played, $RANDOM_USER. Truly the Picasso of runtime exceptions.
Another masterpiece from $RANDOM_USER! $DART_FILE should frame that stack trace.
Wow, $RANDOM_USER, you really outdid yourself. $DART_FILE is in AWE of your genius.
Standing ovation, $RANDOM_USER! $DART_FILE's error log just became modern art.
$RANDOM_USER, your $DART_FILE debugging skills deserve their own Hall of Shame.
Perfect, $RANDOM_USER! $DART_FILE's now fluent in exception handling.
$RANDOM_USER, $DART_FILE's error rate just hit escape velocity. Nice shot!
EOF

    # EMPTY CHATTERS - Line 1: Dramatically confused about empty file (mentions random authorized users)
    cat << 'EOF' > "$TMP_DIR/empty_chatter_line1.txt"
$RANDOM_USER, what is this void? $DART_FILE is a barren wasteland!
Hold up, $RANDOM_USER—where's the code in $DART_FILE? It's AWOL!
$RANDOM_USER, did you ghost us? $DART_FILE is emptier than a demilitarized zone!
What happened, $RANDOM_USER? $DART_FILE looks like it deserted the battlefield!
$RANDOM_USER, $DART_FILE is silent—did you forget to load the ammo?
$RANDOM_USER, abort the silence! $DART_FILE is a blank slate!
Did $RANDOM_USER abandon ship? $DART_FILE's got nothing but echoes!
$RANDOM_USER, $DART_FILE's a no-show! Where's the code, soldier?
EOF

    # EMPTY CHATTERS - Line 2: Mocking with huge sarcasm about empty file (mentions random users)
    cat << 'EOF' > "$TMP_DIR/empty_chatter_line2.txt"
Oh, stellar work, $RANDOM_USER. $DART_FILE's emptiness is truly inspiring.
Well done, $RANDOM_USER. $DART_FILE's blank page deserves a medal.
Masterpiece, $RANDOM_USER! $DART_FILE's void is a modern art classic.
Wow, $RANDOM_USER, $DART_FILE's silence speaks louder than words.
Impressive, $RANDOM_USER! $DART_FILE's emptiness is a strategic genius move.
$RANDOM_USER, $DART_FILE's blankness is your magnum opus. Bravo.
Great job, $RANDOM_USER! $DART_FILE's nothing is really... something.
$RANDOM_USER, $DART_FILE's empty state? A bold minimalist statement!
EOF

    # HUSH CHATTERS - Now just atmospheric whispers about the waiting program
    cat << 'EOF' > "$TMP_DIR/hush_chatters.txt"
*whispers* The code's listening... it's waiting for the right command.
*whispers* Silence on the wire... $DART_FILE's poised for action.
*whispers* The program's holding its breath... something's about to happen.
*whispers* Static on the line... $DART_FILE's ready for the signal.
*whispers* All quiet on the digital front... the code awaits orders.
EOF

    # IDLE CHATTERS - Complaining about random authorized users being inactive
    cat << 'EOF' > "$TMP_DIR/idle_chatters.txt"
Oh, $RANDOM_USER, snoozing on the job? Save that code before we all desert!
Seriously, $RANDOM_USER? The war's raging and you're AWOL? Save something!
$RANDOM_USER, you planning to nap through the apocalypse? Hit save, soldier!
$RANDOM_USER, the code's gathering dust while you admire the scenery!
Where's $RANDOM_USER? $DART_FILE's about to stage a mutiny!
EOF

    # BELIEVING SOLDIER CHATTERS - Encouraging random authorized users
    cat << 'EOF' > "$TMP_DIR/believing_soldier_chatters.txt"
Keep at it, $RANDOM_USER! Your code'll win this war yet!
$RANDOM_USER, you're close! One more save to glory!
I believe in you, $RANDOM_USER! Push that code forward!
$RANDOM_USER, your $DART_FILE's got potential—don't give up now!
You've got this, $RANDOM_USER! $DART_FILE's cheering for you!
EOF

    # IDLE NOTICES - Field Marshal calling out random users
    cat << 'EOF' > "$TMP_DIR/idle_notices.txt"
Still waiting for action, $RANDOM_USER...
$RANDOM_USER, the code's getting dusty!
No saves yet, $RANDOM_USER. What's the plan?
$RANDOM_USER, your $DART_FILE's on standby—wake it up!
Field Marshal to $RANDOM_USER: Report for coding duty!
EOF

    # HUSH INSTRUCTIONS - Clear instructions for interactive programs (SHORTENED)
    cat << 'EOF' > "$TMP_DIR/hush_instructions.txt"
Run 'dart $DART_FILE' in your terminal NOW!
Field Marshal's orders: Open a new terminal and run 'dart $DART_FILE' immediately!
Code's waiting for manual input - execute 'dart $DART_FILE' in separate terminal!
Priority Alpha: Launch 'dart $DART_FILE' manually to provide program input!
Battle stations! Run 'dart $DART_FILE' in your terminal to feed the code!
EOF

    # Verify all critical files were created
    local critical_files=(
        "$TMP_DIR/output_chatters_line1.txt"
        "$TMP_DIR/output_chatters_line2.txt"
        "$TMP_DIR/error_chatters_line1.txt"
        "$TMP_DIR/error_chatters_line2.txt"
        "$TMP_DIR/empty_chatter_line1.txt"
        "$TMP_DIR/empty_chatter_line2.txt"
        "$TMP_DIR/hush_chatters.txt"
        "$TMP_DIR/hush_instructions.txt"
    )
    
    for file in "${critical_files[@]}"; do
        if [ ! -f "$file" ] || [ ! -s "$file" ]; then
            echo "Error: Failed to create or populate $file."
            exit 1
        fi
    done
    
    echo "-1000000" > "$TMP_DIR/last_activity.txt"
    echo "0" > "$TMP_DIR/has_saved.txt"
    
    echo "🎖 All chatter files created successfully!"
    echo "💡 Pro tip: Customize your lines in:"
    echo "   • $TMP_DIR/output_chatters_line1.txt (Dramatic confusion about random users)"
    echo "   • $TMP_DIR/output_chatters_line2.txt (Sarcastic jealousy toward random users)"
    echo "   • $TMP_DIR/error_chatters_line1.txt (Dramatic confusion about random users)"
    echo "   • $TMP_DIR/error_chatters_line2.txt (Mocking sarcasm at random users)"
    echo "   • $TMP_DIR/empty_chatter_line1.txt (Dramatic confusion about empty $DART_FILE)"
    echo "   • $TMP_DIR/empty_chatter_line2.txt (Sarcastic mockery about empty $DART_FILE)"
    echo ""
    echo "👥 Authorized users sergeants can mention: ${AUTH_USERS[*]}"
    echo "   Use \$RANDOM_USER in chatter files for random user mentions"
}

# Function to pick a random line from a file and process user mentions
pick_random_line() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi
    if [ ! -s "$file" ]; then
        echo "Error: File $file is empty."
        exit 1
    fi
    
    local raw_line
    raw_line=$(shuf -n 1 "$file")
    
    # Process $RANDOM_USER placeholders
    local processed_line
    processed_line=$(generate_chatter_content "$raw_line")
    
    # Process $USERNAME and $DART_FILE placeholders
    processed_line="${processed_line//\$USERNAME/$USERNAME}"
    processed_line="${processed_line//\$DART_FILE/$DART_FILE}"
    
    echo "$processed_line"
}

# Function to pick random sergeants without duplicates
pick_sergeants() {
    local count="$1"
    local selected=()
    while [ ${#selected[@]} -lt "$count" ]; do
        local sgt=${SERGEANTS[$((RANDOM % ${#SERGEANTS[@]}))]}
        if [[ ! " ${selected[*]} " =~ " $sgt " ]]; then
            selected+=("$sgt")
        fi
    done
    echo "${selected[@]}"
}

# Function to handle empty file chatter
handle_empty_file_chatter() {
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    
    # Display structured empty file chatter
    local sgt_names
    read -r -a sgt_names <<< "$(pick_sergeants 2)"
    
    # Line 1: Dramatically confused
    local line1
    line1=$(pick_random_line "$TMP_DIR/empty_chatter_line1.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[0]}" "$line1"
    
    # Line 2: Sarcastic mockery
    local line2
    line2=$(pick_random_line "$TMP_DIR/empty_chatter_line2.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[1]}" "$line2"
    
    echo -e "\n----"
    echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
    echo -e "${GREY}⚠️  BATTLEFIELD REPORT: $DART_FILE IS EMPTY OR FULLY COMMENTED ⚠️${NC}"
    echo -e ""
    echo -e "${ORANGE}5⭐Field Marshal:${NC} $USERNAME, $DART_FILE's a blank slate! Write some code, soldier!"
    echo -e ""
    echo -e "${BLUE}💡 QUICK START: ${NC}Uncomment code or write your first ${GREEN}print('Hello World!');${NC}"
}

# Function to display structured output chatter (2 lines)
display_output_chatter() {
    local sgt_names
    read -r -a sgt_names <<< "$(pick_sergeants 2)"
    
    # Line 1: Dramatically confused
    local line1
    line1=$(pick_random_line "$TMP_DIR/output_chatters_line1.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[0]}" "$line1"
    
    # Line 2: Sarcastic jealousy
    local line2
    line2=$(pick_random_line "$TMP_DIR/output_chatters_line2.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[1]}" "$line2"
}

# Function to display structured error chatter (2 lines)
display_error_chatter() {
    local sgt_names
    read -r -a sgt_names <<< "$(pick_sergeants 2)"
    
    # Line 1: Dramatically confused
    local line1
    line1=$(pick_random_line "$TMP_DIR/error_chatters_line1.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[0]}" "$line1"
    
    # Line 2: Mocking sarcasm
    local line2
    line2=$(pick_random_line "$TMP_DIR/error_chatters_line2.txt")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[1]}" "$line2"
}

# Function to display single-line chatter
display_single_chatter() {
    local chatter_file="$1"
    local sgt_name
    sgt_name=$(pick_sergeants 1)
    local line
    line=$(pick_random_line "$chatter_file")
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt_name" "$line"
}

# Function to handle success chatter (structured 2-line response)
handle_success_chatter() {
    local output="$1"
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    
    # Display structured output chatter
    display_output_chatter
    
    echo -e "\n----"
    echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
    echo -e "💂 ${ORANGE}$(pick_sergeants 1 | head -n1)${NC} relaying live fire reports:"
    echo -e "${GREEN}-------------------------------------------------------------${NC}"
    echo -e "${GREEN}$output${NC}"
    echo -e "${GREEN}-------------------------------------------------------------${NC}"
}

# Function to handle hush chatter (detected ACTIVE readLineSync - provide instructions)
handle_hush_chatter() {
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    
    # Display atmospheric hush chatter (no interaction)
    display_single_chatter "$TMP_DIR/hush_chatters.txt"
    
    echo -e "\n----"
    echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
    echo -e "${GREY}⚠️  PROGRAM DETECTED INTERACTIVE INPUT - MANUAL EXECUTION REQUIRED ⚠️${NC}"
    echo -e ""
    echo -e "${ORANGE}5⭐Field Marshal: $(pick_random_line "$TMP_DIR/hush_instructions.txt")${NC}"
    echo -e ""
    echo -e "${BLUE}💡 MONITOR TIP: ${NC}Press ${GREEN}Ctrl+Shift+5${NC} to open terminal, then run ${GREEN}dart $DART_FILE${NC}"
}

# Function to handle error chatter with streamlined instructions
handle_error_chatter() {
    local output="$1"
    local has_readlinesync="$2"
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    
    # Display structured error chatter
    display_error_chatter
    
    echo -e "\n----"
    echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
    echo -e "${RED}🚨 CODE UNDER FIRE - DEBUGGING REQUIRED 🚨${NC}"
    echo -e ""
    echo -e "${RED}-------------------------------------------------------------${NC}"
    echo -e "${RED}$output${NC}"
    echo -e "${RED}-------------------------------------------------------------${NC}"
    echo -e ""
    
    # Detect specific error type for targeted instructions
    local error_type=""
    if echo "$output" | grep -q "NoSuchMethodError"; then
        error_type="NoSuchMethodError"
    elif echo "$output" | grep -q "FormatException"; then
        error_type="FormatException"
    elif echo "$output" | grep -q -E "(TypeError|CastError)"; then
        error_type="TypeError"
    elif echo "$output" | grep -q "ArgumentError"; then
        error_type="ArgumentError"
    elif echo "$output" | grep -q "RangeError"; then
        error_type="RangeError"
    elif echo "$output" | grep -q "StateError"; then
        error_type="StateError"
    fi
    
    # Display concise fix instruction
    echo -e "$(generate_error_instructions "$error_type" "$output")"
    echo -e ""
    
    # Field Marshal instruction
    if [ "$has_readlinesync" = "true" ]; then
        echo -e "${ORANGE}5⭐Field Marshal:${NC} Fix error first, then run interactively!"
        echo -e "${BLUE}💡 ${NC}Debug code → Press ${GREEN}Ctrl+Shift+5${NC} → ${GREEN}dart $DART_FILE${NC}"
    else
        echo -e "${ORANGE}5⭐Field Marshal:${NC} Fix code and save to test again!"
    fi
}

# Function to print welcome screen - FIELD MARSHAL USES RANDOM USER
print_welcome() {
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    local sgt1 sgt2
    read -r sgt1 sgt2 <<< "$(pick_sergeants 2)"
    
    # Process welcome chatters with random user mentions
    local processed_welcome=()
    for chatter in "${WELCOME_CHATTERS[@]}"; do
        local processed_chatter
        processed_chatter=$(generate_chatter_content "$chatter")
        processed_chatter="${processed_chatter//\$USERNAME/$USERNAME}"
        processed_chatter="${processed_chatter//\$DART_FILE/$DART_FILE}"
        processed_welcome+=("$processed_chatter")
    done
    
    # Select respectful message for Line 1 (first two in array)
    local respectful_chatters=("${processed_welcome[@]:0:2}")
    local selected_respectful="${respectful_chatters[$((RANDOM % ${#respectful_chatters[@]}))]}"
    
    # Select sarcastic message for Line 2 (last three in array)
    local sarcastic_chatters=("${processed_welcome[@]:2:3}")
    local selected_sarcastic="${sarcastic_chatters[$((RANDOM % ${#sarcastic_chatters[@]}))]}"
    
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt1" "$selected_respectful"
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt2" "$selected_sarcastic"
    
    echo -e "\n----"
    echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
    echo -e "📋 REPORT BOARD 🪖: HQ begging: push a move before the field collapses!"
    echo -e "${ORANGE}5⭐Field Marshal: $(generate_chatter_content "SOLDIER $RANDOM_USER, SAVE THE CODE NOW! 💾")${NC}"
    echo -e "\n${BLUE}[BASE OPS]${NC}"
    echo -e "${BLUE}[BASE OPS] 🪖 Logged in as $(whoami)${NC}"
    echo -e "${BLUE}[BASE OPS] 🌍 Current position: $(pwd)${NC}"
}

# Function to run idle feed
run_idle_feed() {
    while true; do
        local current_time=$(date +%s)
        local has_saved=$(cat "$TMP_DIR/has_saved.txt" 2>/dev/null || echo "0")
        local last_activity=$(cat "$TMP_DIR/last_activity.txt" 2>/dev/null || echo "-1000000")
        
        # Only trigger idle chatter if a save has occurred and IDLE_DELAY has passed
        if [ "$has_saved" -eq 1 ] && [ $((current_time - last_activity)) -ge $IDLE_DELAY ]; then
            # Check if a save is currently being processed (within 1 second)
            local last_save_time=$(cat "$TMP_DIR/last_activity.txt" 2>/dev/null || echo "-1000000")
            if [ $((current_time - last_save_time)) -ge 1 ]; then
                clear
                echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
                if [ "$BELIEVING_SOLDIER_ENABLED" = true ]; then
                    # Ensure one believing soldier message and fill rest with idle messages
                    local sgt_names
                    read -r -a sgt_names <<< "$(pick_sergeants "$IDLE_CHATTER_COUNT")"
                    local believing_line
                    believing_line=$(pick_random_line "$TMP_DIR/believing_soldier_chatters.txt")
                    printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[0]}" "$believing_line"
                    # Pick remaining messages from idle_chatters.txt
                    for ((i=1; i<IDLE_CHATTER_COUNT; i++)); do
                        local idle_line
                        idle_line=$(pick_random_line "$TMP_DIR/idle_chatters.txt")
                        printf "💂 ${ORANGE}%s${NC}: %s\n" "${sgt_names[i]}" "$idle_line"
                    done
                else
                    # Display multiple idle messages
                    for ((i=0; i<IDLE_CHATTER_COUNT; i++)); do
                        display_single_chatter "$TMP_DIR/idle_chatters.txt"
                    done
                fi
                echo -e "\n----"
                echo -e "${BLUE}[RADIO REPORT BOARD] 🎙${NC}"
                echo -e "${ORANGE}5⭐Field Marshal: $(pick_random_line "$TMP_DIR/idle_notices.txt")${NC}"
            fi
            sleep $IDLE_INTERVAL
        fi
        sleep 1
    done
}

# Function to cleanup on exit
cleanup() {
    clear
    echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
    local farewell_chatters=(
        "What, $RANDOM_USER, you're bailing already?"
        "Who's gonna watch $DART_FILE now, $RANDOM_USER?"
        "Fine, $RANDOM_USER, abandon ship! We'll just code without you!"
    )
    local processed_farewells=()
    for chatter in "${farewell_chatters[@]}"; do
        local processed_chatter
        processed_chatter=$(generate_chatter_content "$chatter")
        processed_chatter="${processed_chatter//\$DART_FILE/$DART_FILE}"
        processed_farewells+=("$processed_chatter")
    done
    
    local sgt1 sgt2 sgt3
    read -r sgt1 sgt2 sgt3 <<< "$(pick_sergeants 3)"
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt1" "${processed_farewells[0]}"
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt2" "${processed_farewells[1]}"
    printf "💂 ${ORANGE}%s${NC}: %s\n" "$sgt3" "${processed_farewells[2]}"
    rm -rf "$TMP_DIR"
    exit 0
}

# Trap CTRL+C for cleanup
trap cleanup SIGINT

# Install dependencies
install_dependencies

# Check if Dart file exists
if [ ! -f "$DART_FILE" ]; then
    echo "Error: File $DART_FILE does not exist."
    exit 1
fi

# Authenticate user
check_user_auth

# Create temporary files
create_tmp_files

# Show welcome screen
print_welcome

# Start idle feed in background
run_idle_feed &

# Watch the Dart file
inotifywait -q -m "$DART_FILE" -e close_write |
while read -r; do
    echo "1" > "$TMP_DIR/has_saved.txt.tmp"
    mv "$TMP_DIR/has_saved.txt.tmp" "$TMP_DIR/has_saved.txt"
    echo "$(date +%s)" > "$TMP_DIR/last_activity.txt.tmp"
    mv "$TMP_DIR/last_activity.txt.tmp" "$TMP_DIR/last_activity.txt"
    
    # PRIORITY CHECK #1: Check if file is empty or entirely commented
    if is_file_empty_or_commented "$DART_FILE"; then
        handle_empty_file_chatter
    else
        # Always attempt to run the program non-interactively first
        temp_output_file="$TMP_DIR/temp_output.txt"
        timeout --signal=SIGTERM 2s dart "$DART_FILE" > "$temp_output_file" 2>&1
        status=$?
        output=$(cat "$temp_output_file")
        rm -f "$temp_output_file"
        
        # Check if readLineSync is actively used (not commented)
        has_active_readlinesync=false
        if check_active_readlinesync "$DART_FILE"; then
            has_active_readlinesync=true
        fi
        
        clear
        echo -e "${BLUE}[BASE COMMS // WAR ROOM MSGS] 📡${NC}"
        
        # PRIORITY 1: Check for Dart errors FIRST (regardless of readLineSync)
        if detect_dart_error "$output"; then
            # Error detected - show error handling (even with readLineSync)
            handle_error_chatter "$output" "$has_active_readlinesync"
        # PRIORITY 2: If readLineSync is active and NO errors, show hush chatter
        elif [ "$has_active_readlinesync" = true ]; then
            handle_hush_chatter
        # PRIORITY 3: Check if output looks like interactive prompts (no readLineSync, no errors)
        elif is_interactive_output "$output"; then
            # Output contains prompts but no readLineSync - might be stdout.write without sync
            handle_hush_chatter
        # PRIORITY 4: Success case - no errors, no interactive input
        else
            if [ $status -eq 0 ]; then
                handle_success_chatter "$output"
            else
                # Timeout but no error - treat as success (might be normal output)
                handle_success_chatter "$output"
            fi
        fi
    fi
done