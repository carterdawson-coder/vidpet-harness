#!/bin/bash

# VIDPET Harness Installer
# Install individual harnesses into Claude Code
#
# Usage — pick the one you need:
#   curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s analyzer
#   curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s alerts
#   curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s tickets
#   curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s ts
#   curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s all

set -e

REPO="https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main"
RULES_DIR="$HOME/.claude/rules"
HARNESS="${1:-}"

mkdir -p "$RULES_DIR"

install_analyzer() {
  curl -sL "$REPO/harnesses/gpb_ad_performance_analyzer.md" -o "$RULES_DIR/analyze_ad_performance.md"
  echo "  + Ad Performance Analyzer"
  echo "    Try: Analyze VIDPET-458"
}

install_alerts() {
  curl -sL "$REPO/harnesses/creative_performance_alerts.md" -o "$RULES_DIR/creative_performance_alerts.md"
  echo "  + Creative Performance Alerts"
  echo "    Try: Run creative performance check"
}

install_tickets() {
  curl -sL "$REPO/harnesses/create_vidpet_ticket.md" -o "$RULES_DIR/create_vidpet_ticket.md"
  curl -sL "$REPO/harnesses/update_vidpet_ticket.md" -o "$RULES_DIR/update_vidpet_ticket.md"
  echo "  + Create & Update VIDPET Tickets"
  echo "    Try: Create a new VIDPET ticket"
}

install_ts() {
  curl -sL "$REPO/harnesses/ts_intelligence.md" -o "$RULES_DIR/ts_intelligence.md"
  echo "  + Thumb Stopper Intelligence"
  echo "    Try: Run TS analysis"
}

echo ""

case "$HARNESS" in
  analyzer)
    echo "  Installing Ad Performance Analyzer..."
    echo ""
    install_analyzer
    ;;
  alerts)
    echo "  Installing Creative Performance Alerts..."
    echo ""
    install_alerts
    ;;
  tickets)
    echo "  Installing VIDPET Ticket Management..."
    echo ""
    install_tickets
    ;;
  ts)
    echo "  Installing Thumb Stopper Intelligence..."
    echo ""
    install_ts
    ;;
  all)
    echo "  Installing all VIDPET harnesses..."
    echo ""
    install_analyzer
    install_alerts
    install_tickets
    install_ts
    ;;
  *)
    echo "  VIDPET Harness Installer"
    echo ""
    echo "  Pick a harness to install:"
    echo ""
    echo "  Ad Performance Analyzer (\"Analyze VIDPET-458\"):"
    echo "    curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s analyzer"
    echo ""
    echo "  Creative Performance Alerts:"
    echo "    curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s alerts"
    echo ""
    echo "  VIDPET Ticket Management (create + update):"
    echo "    curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s tickets"
    echo ""
    echo "  Thumb Stopper Intelligence:"
    echo "    curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s ts"
    echo ""
    echo "  All harnesses:"
    echo "    curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash -s all"
    echo ""
    exit 0
    ;;
esac

echo ""
echo "  Done! Installed $(date +%Y-%m-%d)"
echo "  To update later, just run the same command again."
echo ""
