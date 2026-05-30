import os
import re
import glob
import sys
from datetime import datetime

# Path to the application logs on Windows
LOGS_DIR = os.path.expandvars(r"%LOCALAPPDATA%\Volchay\VolchayWallpapers\logs")
OUTPUT_FILE = "filtered_logs.md"

def analyze_logs():
    if not os.path.exists(LOGS_DIR):
        print(f"Log directory not found: {LOGS_DIR}")
        return

    # Find all volchay log files
    log_files = glob.glob(os.path.join(LOGS_DIR, "volchay-*.log"))
    if not log_files:
        print("No log files found in Volchay directory.")
        return

    # Sort files by name/date
    log_files.sort()
    latest_log = log_files[-1]
    print(f"Analyzing latest log file: {latest_log}")

    errors = []
    warnings = []
    engine_events = []
    startup_info = []

    # Simple count for repeated QML warnings to avoid clutter
    qml_warnings_count = {}

    with open(latest_log, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # Check for startup lines
            if "starting;" in line or "session started" in line:
                startup_info.append(line)
                continue

            # Identify logging level
            if "[ERROR]" in line or "[FATAL]" in line:
                errors.append(line)
            elif "[WARN ]" in line:
                # Group repeated QML style warnings
                if "style does not support customization" in line:
                    match = re.search(r"qrc:/src/qml/\S+:\d+:\d+", line)
                    loc = match.group(0) if match else "QML Customization"
                    qml_warnings_count[loc] = qml_warnings_count.get(loc, 0) + 1
                else:
                    warnings.append(line)
            elif "[Engine]" in line or "[Mpv]" in line:
                # Keep track of key playback & window embedding steps
                if any(x in line for x in ["attach", "detach", "geometry", "First render", "Replaying", "start-file", "file-loaded"]):
                    engine_events.append(line)

    # Write clean markdown report
    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write(f"# Filtered Application Logs\n\n")
        out.write(f"* **Source File**: `{os.path.basename(latest_log)}`\n")
        out.write(f"* **Generated At**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}`\n\n")

        out.write("## 🚀 Session Startup Info\n")
        if startup_info:
            for s in startup_info:
                out.write(f"- `{s}`\n")
        else:
            out.write("*No startup events in this log session.*\n")
        out.write("\n")

        out.write("## 🔴 Errors & Fatals\n")
        if errors:
            for e in errors:
                out.write(f"- `{e}`\n")
        else:
            out.write("*No errors logged! 🎉*\n")
        out.write("\n")

        out.write("## 🟡 Warnings\n")
        if warnings or qml_warnings_count:
            # List normal warnings
            for w in warnings:
                out.write(f"- `{w}`\n")
            # List summarized QML warnings
            for loc, count in qml_warnings_count.items():
                out.write(f"- `[WARN] [QML Style] {loc} (occurred {count} times)`\n")
        else:
            out.write("*No warnings logged! 🎉*\n")
        out.write("\n")

        out.write("## 🎬 Engine & Playback Actions\n")
        if engine_events:
            for ev in engine_events:
                out.write(f"- `{ev}`\n")
        else:
            out.write("*No engine actions registered yet.*\n")
        out.write("\n")

    print(f"Filtered log summary saved successfully to {os.path.abspath(OUTPUT_FILE)}")

if __name__ == "__main__":
    analyze_logs()
