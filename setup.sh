#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="${SCRIPT_DIR}/checks"

# Print with color
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if directory exists, create if not
create_dir_if_not_exists() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "$GREEN" "✓ Created directory: $dir"
    else
        print_status "$YELLOW" "→ Directory already exists: $dir"
    fi
}

# Make script executable
make_executable() {
    local file=$1
    if [ -f "$file" ]; then
        chmod +x "$file"
        print_status "$GREEN" "✓ Made executable: $file"
    else
        print_status "$RED" "✗ File not found: $file"
    fi
}

# Main setup
echo "Setting up OpenStack Health Check System..."
echo "----------------------------------------"

# Create necessary directories
create_dir_if_not_exists "$CHECKS_DIR"

# Make scripts executable
make_executable "${SCRIPT_DIR}/daily-report.sh"

# Create example check script if checks directory is empty
if [ -z "$(ls -A "$CHECKS_DIR" 2>/dev/null)" ]; then
    cat > "${CHECKS_DIR}/01-example.sh" << 'EOL'
#!/bin/bash
# Example Health Check

# This is an example health check script
# Replace this with your actual check logic

# Simulate a check
echo "Running example health check..."
sleep 2
echo "Example check completed successfully!"
exit 0
EOL
    make_executable "${CHECKS_DIR}/01-example.sh"
    print_status "$GREEN" "✓ Created example check script: ${CHECKS_DIR}/01-example.sh"
fi

# Check for required commands
REQUIRED_COMMANDS="find grep sed date"
MISSING_COMMANDS=0

echo -e "\nChecking required commands..."
for cmd in $REQUIRED_COMMANDS; do
    if ! command -v $cmd >/dev/null 2>&1; then
        print_status "$RED" "✗ Missing required command: $cmd"
        MISSING_COMMANDS=$((MISSING_COMMANDS + 1))
    else
        print_status "$GREEN" "✓ Found required command: $cmd"
    fi
done

if [ $MISSING_COMMANDS -gt 0 ]; then
    print_status "$RED" "\n✗ Setup incomplete. Please install missing commands and run setup again."
    exit 1
fi

# Setup complete
print_status "$GREEN" "\n✓ Setup complete! You can now run health checks with: bash daily-report.sh"
echo -e "\nTo add new checks:"
echo "1. Create scripts in: $CHECKS_DIR"
echo "2. Name format: XX-name.sh (XX for ordering)"
echo "3. Make them executable: chmod +x script.sh"
echo -e "\nSee README.md for more information." 
