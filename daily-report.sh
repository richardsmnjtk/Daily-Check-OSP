#!/bin/bash

# Script location and checks directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="${SCRIPT_DIR}/checks"
output_file="report.html"

# Initialize counters
total_checks=0
passed_checks=0
failed_checks=0
start_time=$(date +%s)

# Ensure checks directory exists
if [ ! -d "$CHECKS_DIR" ]; then
    echo "Creating checks directory at: $CHECKS_DIR"
    mkdir -p "$CHECKS_DIR"
fi

# Function to discover and sort check scripts
get_check_scripts() {
    find "$CHECKS_DIR" -type f -name "*.sh" | sort
}

# Function to get check name from script
get_check_name() {
    local script="$1"
    # Try to get name from first line comment, fallback to filename
    local name=$(head -n1 "$script" | grep '^#.*' | sed 's/^#\s*//')
    if [ -z "$name" ]; then
        name=$(basename "$script" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | sed 's/.*/\u&/')
    fi
    echo "$name"
}

# Function to get check ID from script
get_check_id() {
    local script="$1"
    local id=$(basename "$script" .sh | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
    echo "$id"
}

# Simple loading indicator function
show_loading() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local text=$2
    local current=$3
    local total=$4
    local progress=$((current * 100 / total))
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r[%c] %s [%d%%] (%d/%d)" "$spinstr" "$text" "$progress" "$current" "$total"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r[✓] %s [100%%] (%d/%d)\n" "$text" "$current" "$total"
}

# Function to write section to HTML with status
write_to_html() {
    local section_name="$1"
    local script="$2"
    local section_id="$3"
    local check_start_time=$(date +%s)
    
    # Show loading indicator
    (bash "$script" > /tmp/output_$$) &
    show_loading $! "Checking $section_name..." "$((total_checks + 1))" "$total_script_count"
    
    local section_output=$(cat /tmp/output_$$)
    rm /tmp/output_$$
    local check_end_time=$(date +%s)
    local check_duration=$((check_end_time - check_start_time))

    # Determine status
    if echo "$section_output" | grep -i "failed" || echo "$section_output" | grep -i "error"; then
        status="failure"
        ((failed_checks++))
    else
        status="success"
        ((passed_checks++))
    fi
    ((total_checks++))

    # Add section to HTML
    echo "<h2 id='$section_id'>$section_name</h2>
    <div class='timing'>Execution time: ${check_duration}s</div>
    <table>
        <tr><th>Status</th><th>Details</th></tr>
        <tr><td class='$status'>$status</td><td><div class='pre-container'><pre>$section_output</pre></div></td></tr>
    </table>" >> $output_file
}

# Start HTML structure
cat > $output_file << EOL
<!DOCTYPE html>
<html>
<head>
    <title>OpenStack Daily Check Report</title>
    <style>
        :root {
            --primary-color: #3498db;
            --success-color: #2ecc71;
            --failure-color: #e74c3c;
            --text-color: #2c3e50;
            --bg-color: #f8f9fa;
            --border-color: #e0e0e0;
        }
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 20px;
            line-height: 1.6;
            overflow-x: hidden;
        }
        .container {
            max-width: 100%;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
            overflow-x: auto;
        }
        .content-wrapper {
            min-width: 1200px;
            padding: 0 20px;
        }
        .summary {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border: 1px solid var(--border-color);
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
        }
        .summary-item {
            text-align: center;
            padding: 15px;
            border-radius: 5px;
        }
        .summary-total {
            background-color: var(--primary-color);
            color: white;
        }
        .summary-success {
            background-color: var(--success-color);
            color: white;
        }
        .summary-failure {
            background-color: var(--failure-color);
            color: white;
        }
        .search-box {
            margin: 20px 0;
            padding: 10px;
            width: 100%;
            border: 1px solid var(--border-color);
            border-radius: 5px;
            font-size: 16px;
        }
        .search-box:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 5px rgba(52, 152, 219, 0.5);
        }
        .highlight {
            background-color: rgba(255, 255, 0, 0.3);
            padding: 2px;
            border-radius: 2px;
        }
        .highlight.current {
            background-color: rgba(255, 165, 0, 0.5);
            border: 1px solid orange;
        }
        .search-info {
            color: #7f8c8d;
            font-size: 0.9em;
            margin-top: 5px;
            display: none;
        }
        .search-navigation {
            display: none;
            align-items: center;
            gap: 10px;
            margin-top: 5px;
        }
        .search-navigation.visible {
            display: flex;
        }
        .search-nav-button {
            padding: 5px 10px;
            border: 1px solid var(--border-color);
            border-radius: 3px;
            background: white;
            cursor: pointer;
        }
        .search-nav-button:hover {
            background: #f5f5f5;
        }
        .search-nav-count {
            color: var(--text-color);
            font-size: 0.9em;
        }
        .export-buttons {
            margin: 20px 0;
            display: flex;
            gap: 10px;
        }
        .export-button {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            background-color: var(--primary-color);
            color: white;
            cursor: pointer;
            text-decoration: none;
            font-size: 14px;
        }
        .export-button:hover {
            background-color: #2980b9;
        }
        .timing {
            color: #7f8c8d;
            font-size: 0.9em;
            margin: 5px 0;
        }
        h1 {
            color: var(--primary-color);
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--primary-color);
        }
        h2 {
            color: var(--primary-color);
            margin-top: 30px;
            padding-left: 10px;
            border-left: 4px solid var(--primary-color);
            scroll-margin-top: 20px;
        }
        .toc {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border: 1px solid var(--border-color);
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            position: sticky;
            top: 20px;
            z-index: 100;
        }
        .toc h3 {
            color: var(--primary-color);
            margin-top: 0;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
        }
        .toc ul {
            list-style-type: none;
            padding: 0;
            margin: 0;
            columns: 2;
            column-gap: 20px;
        }
        .toc li {
            margin-bottom: 10px;
        }
        .toc a {
            color: var(--primary-color);
            text-decoration: none;
            transition: color 0.3s;
            display: block;
            padding: 5px 0;
        }
        .toc a:hover {
            color: #2980b9;
            text-decoration: underline;
        }
        table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin: 20px 0;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            min-width: 800px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        th {
            background-color: var(--primary-color);
            color: white;
            font-weight: 600;
            position: sticky;
            top: 0;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .success {
            color: var(--success-color);
            font-weight: bold;
        }
        .failure {
            color: var(--failure-color);
            font-weight: bold;
        }
        pre {
            background-color: var(--bg-color);
            padding: 15px;
            border-radius: 5px;
            border: 1px solid var(--border-color);
            overflow-x: auto;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            white-space: pre;
            max-width: 100%;
            margin: 0;
        }
        .pre-container {
            overflow-x: auto;
            margin: 0;
            padding: 0;
            background-color: var(--bg-color);
            border-radius: 5px;
        }
        .timestamp {
            text-align: center;
            color: #7f8c8d;
            font-size: 0.9em;
            margin-bottom: 20px;
        }
        .back-to-top {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background-color: var(--primary-color);
            color: white;
            padding: 10px 15px;
            border-radius: 5px;
            text-decoration: none;
            opacity: 0;
            transition: opacity 0.3s;
            z-index: 1000;
        }
        .back-to-top.visible {
            opacity: 1;
        }
        .back-to-top:hover {
            background-color: #2980b9;
        }
        @media (max-width: 1200px) {
            .container {
                padding: 10px;
            }
            .content-wrapper {
                min-width: 1000px;
                padding: 0 10px;
            }
        }
        @media print {
            .export-buttons, .search-box, .back-to-top {
                display: none;
            }
            body {
                background: white;
            }
            .container {
                box-shadow: none;
            }
        }
    </style>
    <script>
        window.onscroll = function() {
            var backToTop = document.querySelector('.back-to-top');
            if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
                backToTop.classList.add('visible');
            } else {
                backToTop.classList.remove('visible');
            }
        };

        let currentMatchIndex = 0;
        let matches = [];

        function debounceSearch() {
            clearTimeout(window.searchTimeout);
            window.searchTimeout = setTimeout(searchContent, 300);
        }

        function searchContent() {
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            const searchInfo = document.getElementById('searchInfo');
            const searchNavigation = document.getElementById('searchNavigation');
            
            // Reset matches
            matches = [];
            currentMatchIndex = 0;
            
            // Remove previous highlights
            document.querySelectorAll('.highlight').forEach(el => {
                const parent = el.parentNode;
                parent.replaceChild(document.createTextNode(el.textContent), el);
            });
            
            if (searchText.length < 3) {
                searchInfo.textContent = 'Type at least 3 characters to search';
                searchInfo.classList.add('visible');
                searchNavigation.classList.remove('visible');
                return;
            }
            
            const content = document.querySelectorAll('pre, td, th, h2');
            
            content.forEach(el => {
                const text = el.textContent.toLowerCase();
                if (text.includes(searchText)) {
                    // Only highlight the specific matching text, not the entire element
                    const regex = new RegExp(searchText, 'gi');
                    const newText = el.innerHTML.replace(regex, function(match) {
                        matches.push(null); // Will be replaced with actual element reference after rendering
                        return '<span class="highlight" data-match-index="' + (matches.length - 1) + '">' + match + '</span>';
                    });
                    el.innerHTML = newText;
                }
            });
            
            // Store references to highlight elements
            matches = Array.from(document.querySelectorAll('.highlight'));
            
            const matchCount = matches.length;
            searchInfo.textContent = matchCount > 0 
                ? 'Found ' + matchCount + ' matches' 
                : 'No matches found';
            searchInfo.classList.add('visible');
            
            if (matchCount > 0) {
                searchNavigation.classList.add('visible');
                document.getElementById('totalMatches').textContent = matchCount;
                highlightCurrentMatch();
            } else {
                searchNavigation.classList.remove('visible');
            }
        }

        function highlightCurrentMatch() {
            // Remove current highlight from all matches
            matches.forEach(el => el.classList.remove('current'));
            
            // Add current highlight to current match
            if (matches.length > 0) {
                const currentMatch = matches[currentMatchIndex];
                currentMatch.classList.add('current');
                currentMatch.scrollIntoView({
                    behavior: 'smooth',
                    block: 'center'
                });
                document.getElementById('currentMatch').textContent = currentMatchIndex + 1;
            }
        }

        function nextMatch() {
            if (matches.length === 0) return;
            currentMatchIndex = (currentMatchIndex + 1) % matches.length;
            highlightCurrentMatch();
        }

        function previousMatch() {
            if (matches.length === 0) return;
            currentMatchIndex = (currentMatchIndex - 1 + matches.length) % matches.length;
            highlightCurrentMatch();
        }

        function exportToPDF() {
            window.print();
        }

        function exportToCSV() {
            const tables = document.querySelectorAll('table');
            let csvContent = '';
            
            tables.forEach(table => {
                const rows = table.querySelectorAll('tr');
                rows.forEach(row => {
                    const cells = row.querySelectorAll('td, th');
                    const rowData = Array.from(cells).map(cell => cell.textContent);
                    csvContent += rowData.join(',') + '\n';
                });
                csvContent += '\n';
            });
            
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'openstack_report.csv';
            a.click();
            window.URL.revokeObjectURL(url);
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            if (e.key === '?' && !e.ctrlKey && !e.altKey && !e.metaKey) {
                const shortcuts = document.getElementById('keyboardShortcuts');
                shortcuts.classList.toggle('visible');
            }
            
            if (e.key === 'f' && (e.ctrlKey || e.metaKey)) {
                e.preventDefault();
                document.getElementById('searchInput').focus();
            }
            
            if (e.key === 'Enter') {
                if (e.shiftKey) {
                    previousMatch();
                } else {
                    nextMatch();
                }
            }
            
            if (e.key === 'Escape') {
                const searchInput = document.getElementById('searchInput');
                searchInput.value = '';
                searchContent();
                searchInput.blur();
            }
        });
    </script>
</head>
<body>
    <div class='container'>
        <div class='content-wrapper'>
            <h1>OpenStack Daily Check Report</h1>
            <p class='timestamp'>Generated on $(date '+%Y-%m-%d %H:%M:%S')</p>

            <div class='summary'>
                <div class='summary-item summary-total'>
                    <h3>Total Checks</h3>
                    <p id='totalChecks'>0</p>
                </div>
                <div class='summary-item summary-success'>
                    <h3>Passed</h3>
                    <p id='passedChecks'>0</p>
                </div>
                <div class='summary-item summary-failure'>
                    <h3>Failed</h3>
                    <p id='failedChecks'>0</p>
                </div>
            </div>

            <input type='text' id='searchInput' class='search-box' placeholder='Search in report... (minimum 3 characters)' onkeyup='debounceSearch()'>
            <div id='searchInfo' class='search-info'>Type at least 3 characters to search</div>
            <div id='searchNavigation' class='search-navigation'>
                <button class='search-nav-button' onclick='previousMatch()'>Previous</button>
                <span class='search-nav-count'><span id='currentMatch'>0</span> of <span id='totalMatches'>0</span></span>
                <button class='search-nav-button' onclick='nextMatch()'>Next</button>
            </div>

            <div class='export-buttons'>
                <button class='export-button' onclick='exportToPDF()'>Export as PDF</button>
                <button class='export-button' onclick='exportToCSV()'>Export as CSV</button>
            </div>

            <div class='toc'>
                <h3>Table of Contents</h3>
                <ul>
EOL

# Discover all check scripts
check_scripts=($(get_check_scripts))
total_script_count=${#check_scripts[@]}

if [ $total_script_count -eq 0 ]; then
    echo "No check scripts found in $CHECKS_DIR"
    echo "Please add your health check scripts in this directory"
    echo "Example script format:"
    echo "------------------------"
    echo "#!/bin/bash"
    echo "# My Check Name"
    echo "# Your check logic here"
    echo "# Return 0 for success, non-zero for failure"
    echo "# Output meaningful text to stdout"
    exit 1
fi

# Generate Table of Contents
for script in "${check_scripts[@]}"; do
    check_name=$(get_check_name "$script")
    check_id=$(get_check_id "$script")
    echo "<li><a href='#$check_id'>$check_name</a></li>" >> $output_file
done

# Close TOC
echo "</ul>
            </div>" >> $output_file

echo "Starting Health Check..."
echo "--------------------------------"

# Process each check script
for script in "${check_scripts[@]}"; do
    check_name=$(get_check_name "$script")
    check_id=$(get_check_id "$script")
    write_to_html "$check_name" "$script" "$check_id"
done

# Calculate total execution time
end_time=$(date +%s)
total_duration=$((end_time - start_time))

# Add summary script and close HTML
cat >> $output_file << EOL
<script>
    document.getElementById('totalChecks').textContent = '$total_checks';
    document.getElementById('passedChecks').textContent = '$passed_checks';
    document.getElementById('failedChecks').textContent = '$failed_checks';
</script>
<div class='timing' style='text-align: center; margin-top: 20px;'>
    Total execution time: ${total_duration}s
</div>
<a href='#' class='back-to-top'>Back to Top</a>
        </div>
    </div>
</body>
</html>
EOL

echo -e "\nReport generated: $output_file"
