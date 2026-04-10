# VIDPET Harness Suite

This project contains harnesses for the Golden Hippo video production team: Jira ticket management, creative performance alerts, and ad performance analysis.

## Team Setup

Paste this into your terminal to install all harnesses:

```
curl -sL https://raw.githubusercontent.com/carterdawson-coder/vidpet-harness/main/install.sh | bash
```

Then open Claude Code and try: `Analyze VIDPET-458`

To update harnesses later, run the same command again.

## Requirements

You need the **Atlassian MCP server**, **Rill MCP server**, and **Slack MCP server** connected to your Claude Code.

## Command Routing — READ THIS FIRST

**"Analyze" = Rill performance data. "Create"/"Update" = Jira ticket.**

When the user says **"Analyze [anything]"**, ALWAYS follow `harnesses/gpb_ad_performance_analyzer.md`. This queries **Rill** for ad spend/revenue/retention data. NEVER look up the Jira ticket — the analyzer doesn't need Jira. Go straight to Rill.

When the user says **"Create a new VIDPET ticket"** or **"Update VIDPET-XXX"**, THEN use the Jira MCP tools.

**These are completely different operations. Do not confuse them.**

## Commands

### Jira Ticket Management
- **"Create a new VIDPET ticket"** — Follow `harnesses/create_vidpet_ticket.md` EXACTLY. Use the Jira MCP tools (createJiraIssue, editJiraIssue, getTransitionsForJiraIssue, transitionJiraIssue). NEVER use a Python script.
- **"Update VIDPET-XXX"** — Follow `harnesses/update_vidpet_ticket.md` EXACTLY. Only change fields the user filled in — blank means don't touch.

### Creative Performance Alerts
- **"Run creative performance check --all"** — Follow `harnesses/creative_performance_alerts.md` EXACTLY. Team-wide run: queries ALL pet offer ads in Testing, sends Slack DMs to all opted-in roster members when their ads hit milestones. This is what scheduled tasks use.
- **"Run creative performance check"** — Personal mode for the default user (Carter Dawson). Prints results for your ads only. No Slack messages unless `--all` is specified.
- **"Run creative performance check for [Name]"** — Personal mode for a specific person.
- **"Run creative performance check --test"** — Test mode (personal). Lower thresholds ($500/$1.5K/$3K/$5K/$10K/$25K/$50K), NO Slack messages, NO state updates.
- **"Run creative performance check --test --all"** — Test mode (team-wide). Lower thresholds, no Slack, checks all opted-in users.
- **"Run creative performance digest"** — Follow `harnesses/creative_performance_alerts.md` Weekly Digest section. Sends personalized summary DMs to each opted-in roster member with top performers, milestone hits, on-the-radar ads, and week totals. Automatically runs Fridays at 2:30 PM PST.

### Thumb Stopper Intelligence (Rill)
- **"Run TS analysis"** — Follow `harnesses/ts_intelligence.md` EXACTLY. Cross-offer TS performance ranking with hook angle classification, creative psychology insights, and per-offer creative briefs. Default: all offers, last 90 days. VIDPET tickets only.
- **"Run TS analysis for [offer]"** — Single-offer mode.
- **"Run TS analysis last [N] days"** — Custom time range.
- **"Run TS analysis --all-time"** — All available data.
- **"Run TS analysis --slack"** — Send report to Slack DM.

### Ad Performance Analyzer (Rill)
- **"Analyze [TICKET]"** — Follow `harnesses/gpb_ad_performance_analyzer.md` EXACTLY. Queries **Rill** (NOT Jira) for ad performance data, scores against GPB benchmarks, diagnoses funnel shape, and delivers a SCALE/OPTIMIZE/PAUSE/KILL verdict. Default: producer report.
- **"Analyze [TICKET] on the [Account] account"** — Same as above, with explicit account override.
- **"Analyze [TICKET] --editor"** — Editor-focused report: timestamp-heavy retention waterfall, specific edit points with seconds, pacing recommendations.
- **"Analyze [TICKET] --offer-manager"** — Offer manager report: CAC/NCR/continuity scoring, offer health diagnosis, split test analysis.
- **"Analyze [TICKET] --media-buyer"** — Media buyer report: budget allocation, scaling plan, CPM trends, fatigue signals.
- **"Pull performance for all [pattern] ads on the [Account] account last [N] days"** — Same harness, multi-ad mode. Scores each matching ad individually.
