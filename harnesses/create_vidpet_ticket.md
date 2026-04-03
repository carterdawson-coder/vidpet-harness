# VIDPET Ticket Creator Harness

## Trigger

When the user says **"Create a new VIDPET ticket"** and provides ticket info, follow this procedure exactly.

## Required Info (from the user's prompt)

The user's prompt has two sections of people fields. Parse them correctly:

**Jira role fields** (set as custom fields on the ticket):
- **Ticket name** (e.g., CD-TS-Pack-12)
- **VSL** (defaults to "Cesar Solo VSL - no MM")
- **Assignee**
- **Creative Director**
- **Producer** (Jira field)
- **Editor** (Jira field)
- **Writer** (Jira field)

**Description body people** (appear as @mentions in the ticket description — these are the SECOND set of Producer/Editor/VSL Producer/VSL Editor lines):
- **Producer** — the second "Producer:" line after Writer
- **Editor** — the second "Editor:" line after that Producer
- **VSL Producer(s)** — may have multiple names separated by "+"
- **VSL Editor**

**Other fields:**
- **Thumb stoppers** (TS1, TS2, etc. — hook headlines, all go to the VSL listed above)
- **Status** (defaults to "Editing")
- **Open Materials folder** (Google Drive URL, optional)
- **Final Exports folder** (Google Drive URL, optional)

If any required field is missing, ask for it before proceeding.

**How to tell the two people sections apart:** The first block (Assignee through Writer) sets Jira custom fields. The second block (Producer, Editor, VSL Producer(s), VSL Editor) comes after Writer and before "Thumb stoppers:" — these go into the description body as @mentions.

## Constants

```
CLOUD_ID = "972e7666-58b6-4e89-87f4-6c0f672f67bd"
PROJECT_KEY = "VIDPET"
ISSUE_TYPE = "Video"
```

### Team Roster (name → accountId)

```
Carter Dawson    → 634f3b5776b91b62562ba04d
Jordonna Grace   → 712020:0de65788-907e-4ac6-8555-5b02c1557959
Jennifer Sabih   → 557058:d8360e7b-afd4-4311-b91e-cfc20cc7bca0
Mariia Hladkova  → 712020:87eee935-ea59-41ed-bfee-f0db4da7d204
Meghan Gavin     → 5d38ae3430951f0c8bd68146
Andrew Hong      → 633b575088ed2ebef97dc291
```

### Workflow Transition IDs

```
Writing            → 2
Production         → 3
Needs an Editor    → 4
Editing            → 5
Creative Review    → 6
Submitted          → 7
Ready for Testing  → 8
Testing            → 9
Results Review     → 10
PAUSED             → 11
Backlog            → 12
To Do              → 21
Done               → 41
```

### Custom Field IDs

```
# Required on create
Pets Brand          → customfield_14829   (value: {"id": "23032"} = Dr. Marty Pets)
Pets Offer          → customfield_14830   (value: {"id": "23040"} = Nature's Blend - Cesar)
Testing Platform    → customfield_10945   (value: {"id": "11401"} = Internal)
Video Type          → customfield_10795   (value: {"id": "10880"} = New Ad Creative)
Delivery Specs      → customfield_16284   (value: [{"id": "24621"}] = 4x5)
Offer Manager       → customfield_16485   (value: [{"accountId": "5d38ae3430951f0c8bd68146"}] = Meghan Gavin)

# Set via edit after create
Creative Director   → customfield_17103   (multi-user: [{"accountId": "..."}])
Producer            → customfield_11056   (multi-user: [{"accountId": "..."}])
Editor              → customfield_11148   (single user: {"accountId": "..."})
Writer              → customfield_14752   (multi-user: [{"accountId": "..."}])
Whitelist           → customfield_14935   (value: [{"id": "23113"}] = Yes)
Ad Type             → customfield_15003   (value: {"id": "23185"} = topTS)
Start Date          → customfield_10554   (value: "YYYY-MM-DD" = today)
Open Materials      → customfield_10972   (rich text ADF with inlineCard)
Final Exports       → customfield_10591   (rich text ADF with inlineCard)
```

## Procedure

### Step 1: Build the title

Format: `DMP | NB | {ticket_name} | {vsl_name} | {YYMMDD}`

Use today's date for YYMMDD.

### Step 2: Build the ADF description

The description MUST use `contentFormat: "adf"` with proper mention nodes so @names are clickable. Structure:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    // ALWAYS start with Brand and Offer lines:
    // Brand line: bold "Brand: " then plain "Dr Marty Pets"
    // Offer line: bold "Offer: " then plain "Nature's Blend"

    // Then description people block — these are the SECOND set of people fields from the prompt
    // Labels in the description: "Producer:", "Editor:", "VSL Producer(s):", "VSL Editor:"
    // Each person is a mention node: {"type": "mention", "attrs": {"id": "<accountId>", "text": "@Display Name", "accessLevel": ""}}
    // Multiple people on one line joined by " + " text nodes
    // Role label is bold text: {"type": "text", "text": "Producer: ", "marks": [{"type": "strong"}]}

    // Horizontal rule: {"type": "rule"}

    // "Creative Versions" header (bold paragraph)
    // Each TS line: "TS1 - Hook Headline -> " then bold VSL name

    // Horizontal rule (if drive links follow)

    // Drive links as inlineCard: {"type": "inlineCard", "attrs": {"url": "..."}}
    // Label is bold: "Open Materials folder: " then inlineCard
  ]
}
```

### Step 3: Create the issue

Use `createJiraIssue` with:
- `cloudId`: the cloud ID
- `projectKey`: "VIDPET"
- `issueTypeName`: "Video"
- `summary`: the title from Step 1
- `description`: the ADF JSON string from Step 2
- `contentFormat`: "adf"
- `assignee_account_id`: resolved from team roster
- **DO NOT pass a `transition` on create.** Status is handled in Step 5.
- `additional_fields`: all required custom fields (brand, offer, testing platform, video type, delivery specs, offer manager) AND `priority: {"name": "Highest"}`

### Step 4: Edit the issue to set role fields and defaults

Use `editJiraIssue` with:
- `issueIdOrKey`: the key returned from Step 3
- `contentFormat`: "adf"
- `fields`:
  - `customfield_17103` (CD): `[{"accountId": "..."}]`
  - `customfield_11056` (Producer): `[{"accountId": "..."}]`
  - `customfield_11148` (Editor): `{"accountId": "..."}`
  - `customfield_14752` (Writer): `[{"accountId": "..."}]`
  - `customfield_14935` (Whitelist): `[{"id": "23113"}]`
  - `customfield_15003` (Ad Type): `{"id": "23185"}`
  - `customfield_10554` (Start Date): today as `"YYYY-MM-DD"`
  - `customfield_10972` (Open Materials): ADF doc with inlineCard (if URL provided)
  - `customfield_10591` (Final Exports): ADF doc with inlineCard (if URL provided)

### Step 5: Transition to the requested status (REQUIRED — always do this)

Jira transitions are state-dependent. You CANNOT hardcode transition IDs because available transitions depend on the ticket's current state. You MUST walk through transitions dynamically.

**Procedure:**

1. Call `getTransitionsForJiraIssue` on the newly created ticket to see what transitions are available from its current state.
2. Check if the target status (e.g., "Editing") appears as one of the available transitions (match by `transition.to.name`, case-insensitive).
3. **If the target is available:** call `transitionJiraIssue` with that transition's `id`. Done.
4. **If the target is NOT available:** you need to walk through intermediate states:
   a. Pick the transition that gets you closest to the target. Use this general flow order as a guide:
      `Backlog → To Do → Writing → Production → Needs an Editor → Editing → Creative Review → Submitted → Ready for Testing → Testing → Results Review → Done`
      `PAUSED` is reachable from most states.
   b. Execute that intermediate transition.
   c. Call `getTransitionsForJiraIssue` again from the new state.
   d. Repeat until you reach the target status.
   e. **Safety limit:** Stop after 8 transitions. If you haven't reached the target, tell the user: "Reached [current status] but couldn't get to [target]. Please transition manually."

5. After the final transition, call `getTransitionsForJiraIssue` one more time to verify the ticket's current status matches the target. Report the final status to the user.

**Status name matching:** The user might say "Editing", "editing", "EDITING", or "needs an editor" — always match case-insensitively against the transition names from the API response.

**Known statuses from the VIDPET workflow** (from the screenshot):
- BACKLOG
- PAUSED
- TO DO
- CREATIVE REVIEW
- NEEDS AN EDITOR
- PRODUCTION
- READY FOR TESTING
- RESULTS REVIEW
- SUBMITTED
- EDITING
- WRITING
- TESTING
- DONE

### Step 6: Confirm

Print:
```
VIDPET-XXX created — status: [final status]
https://goldenhippomedia.atlassian.net/browse/VIDPET-XXX
```

If the status transition failed or didn't reach the target, say so explicitly.

## Important Rules

- **NEVER use contentFormat "markdown" for the description.** Mentions won't render. Always use ADF.
- **Editor (customfield_11148) is single-user** — pass `{"accountId": "..."}` not an array.
- **All other role fields are multi-user** — pass `[{"accountId": "..."}]` arrays.
- **Drive link fields need the full ADF doc wrapper**: `{"type": "doc", "version": 1, "content": [{"type": "paragraph", "content": [{"type": "inlineCard", "attrs": {"url": "..."}}]}]}`
- **If the user provides a "+" separated name list** (e.g., "Carter Dawson + Jordonna Grace"), resolve each name and include all accountIds.
- **NEVER hardcode transition IDs.** Always query available transitions first with `getTransitionsForJiraIssue`, then use the IDs returned by the API.
- **NEVER skip the status transition step.** Every ticket must end at the user's requested status. If no status is specified, default to "Editing".
