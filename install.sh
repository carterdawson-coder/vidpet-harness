#!/bin/bash

# VIDPET Harness Installer
# Installs Golden Hippo creative harnesses into Claude Code
# Usage: curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash

set -e

REPO="https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main"
RULES_DIR="$HOME/.claude/rules"

echo ""
echo "  Installing VIDPET harnesses..."
echo ""

# Create rules directory if needed
mkdir -p "$RULES_DIR"

# Download each harness
curl -sL "$REPO/harnesses/gpb_ad_performance_analyzer.md" -o "$RULES_DIR/analyze_ad_performance.md"
echo "  + Ad Performance Analyzer"

curl -sL "$REPO/harnesses/creative_performance_alerts.md" -o "$RULES_DIR/creative_performance_alerts.md"
echo "  + Creative Performance Alerts"

curl -sL "$REPO/harnesses/create_vidpet_ticket.md" -o "$RULES_DIR/create_vidpet_ticket.md"
echo "  + Create VIDPET Ticket"

curl -sL "$REPO/harnesses/update_vidpet_ticket.md" -o "$RULES_DIR/update_vidpet_ticket.md"
echo "  + Update VIDPET Ticket"

curl -sL "$REPO/harnesses/ts_intelligence.md" -o "$RULES_DIR/ts_intelligence.md"
echo "  + Thumb Stopper Intelligence"

echo ""
echo "  Done! Installed $(date +%Y-%m-%d)"
echo ""
echo "  Open Claude Code and try:"
echo "    Analyze VIDPET-458"
echo "    Create a new VIDPET ticket"
echo "    Run TS analysis"
echo ""
echo "  To update later, just run this command again."
echo ""
