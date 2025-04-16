# OpenStack Health Check System

A comprehensive health check system for OpenStack environments that generates an interactive HTML report.

## Features

- Automatic discovery and execution of health check scripts
- Interactive HTML report with:
  - Success/Failure status for each check
  - Execution time tracking
  - Search functionality
  - Export options (PDF, CSV)
  - Table of Contents
- Customizable check scripts
- Real-time progress indicators

## Directory Structure

```
.
├── daily-report.sh          # Main report generator script
├── setup.sh           # Setup script
└── checks/            # Directory containing health check scripts
    ├── 01-*.sh       # Check scripts (numbered for ordering)
    ├── 02-*.sh
    └── ...
```

## Installation

1. Clone this repository or copy the files to your desired location
   ```bash
   git clone https://github.com/richardsmnjtk/Daily-Check-OSP.git
   ```
2. Run the setup script:
   ```bash
   bash setup.sh
   ```

## Creating Check Scripts

1. Create a new script in the `checks` directory
2. Name format: `XX-name.sh` (where XX is a number for ordering)
3. Make the script executable
4. Script requirements:
   - Must output meaningful text to stdout
   - Return 0 for success, non-zero for failure
   - Include error messages when relevant
   - Optional: Add a comment on first line for custom check name

Example check script:
```bash
# My Custom Check Name >> Change to service/resources name
#!/bin/bash

# Your check logic here
if some_condition; then
    echo "Check passed"
    exit 0
else
    echo "Check failed: reason"
    exit 1
fi
```

## Running Health Checks

To generate a health check report:

```bash
bash daily-report.sh
```

The report will be generated as `report.html` in the current directory.
![image](https://github.com/user-attachments/assets/4d3e9829-1a66-48e4-95af-f46dcba94008)

## Report Features

- **Status Summary**: Total, passed, and failed checks
- **Search**: Search through check results (minimum 3 characters)
- **Export**: Export results as PDF or CSV
- **Navigation**: Table of contents and back-to-top button
- **Timing**: Execution time for each check and total duration

## Requirements

- Bash shell
- Standard Unix utilities (find, grep, sed, etc.)
- Web browser for viewing reports

## Troubleshooting

1. If scripts aren't executing:
   ```bash
   chmod +x daily-report.sh
   chmod +x checks/*.sh
   ```

2. If temporary files remain:
   ```bash
   rm -f /tmp/output_*
   ```

## Contributing

To add new health checks:

1. Create a new script in the `checks` directory
2. Follow the naming convention: `XX-descriptive-name.sh`
3. Make it executable: `chmod +x XX-descriptive-name.sh`
4. Test it independently before adding to the suite

## GENERATED HTML
![image](https://github.com/user-attachments/assets/ba0bf5fd-c43f-46fb-9576-7f7ae693919a)
