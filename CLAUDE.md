# VIDPET Ticket Harness

This harness lets anyone on the Golden Hippo video production team create and update VIDPET Jira tickets by pasting a simple prompt into Claude Code.

## Requirements

You need the **Atlassian MCP server** connected to your Claude Code. If you can already use Jira tools in Claude Code, you're good.

## Commands

- **"Create a new VIDPET ticket"** — Follow `harnesses/create_vidpet_ticket.md` EXACTLY. Use the Jira MCP tools (createJiraIssue, editJiraIssue, getTransitionsForJiraIssue, transitionJiraIssue). NEVER use a Python script.
- **"Update VIDPET-XXX"** — Follow `harnesses/update_vidpet_ticket.md` EXACTLY. Only change fields the user filled in — blank means don't touch.
