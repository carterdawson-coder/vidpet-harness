# VIDPET Ticket Updater Harness

## Trigger

When the user says **"Update VIDPET-XXX"** and provides fields to update, follow this procedure exactly.

## How It Works

The user only fills in what they want to change. **Blank fields mean "don't touch."** Only update what has a value.

## Parsing the Prompt

The prompt has the same two-section structure as the create prompt:

**Jira role fields** (set as custom fields on the ticket):
- **Assignee**
- **Creative Director**
- **Producer** (Jira field)
- **Editor** (Jira field)
- **Writer** (Jira field)

**Description body people** (appear as @mentions in the ticket description — the SECOND set of Producer/Editor/VSL Producer/VSL Editor lines):
- **Producer** — the second "Producer:" line after Writer
- **Editor** — the second "Editor:" line after that Producer
- **VSL Producer(s)** — may have multiple names separated by "+"
- **VSL Editor**

**Other fields:**
- **Thumb stoppers** (TS1, TS2, etc.)
- **Status**
- **Open Materials folder** (Google Drive URL)
- **Final Exports folder** (Google Drive URL)

**Rule: If a field is blank, DO NOT update it.** Only send fields that have values.

## Constants

```
CLOUD_ID = "972e7666-58b6-4e89-87f4-6c0f672f67bd"
PROJECT_KEY = "VIDPET"
```

### Team Roster (name -> accountId)

```
Carter Dawson    → 634f3b5776b91b62562ba04d
Jordonna Grace   → 712020:0de65788-907e-4ac6-8555-5b02c1557959
Jennifer Sabih   → 557058:d8360e7b-afd4-4311-b91e-cfc20cc7bca0
Mariia Hladkova  → 712020:87eee935-ea59-41ed-bfee-f0db4da7d204
Meghan Gavin     → 5d38ae3430951f0c8bd68146
Andrew Hong      → 633b575088ed2ebef97dc291
```

### Custom Field IDs

```
Creative Director   → customfield_17103   (multi-user: [{"accountId": "..."}])
Producer            → customfield_11056   (multi-user: [{"accountId": "..."}])
Editor              → customfield_11148   (single user: {"accountId": "..."})
Writer              → customfield_14752   (multi-user: [{"accountId": "..."}])
Open Materials      → customfield_10972   (rich text ADF with inlineCard)
Final Exports       → customfield_10591   (rich text ADF with inlineCard)
```

## Procedure

### Step 1: Fetch the existing ticket

Use `getJiraIssue` to pull the current ticket. This lets you:
- Confirm it exists
- Read the current description (so you can merge, not overwrite)
- Know the current status (so you know where to transition from)

### Step 2: Build the edit payload (fields only)

Only include fields the user actually filled in. Build a `fields` object for `editJiraIssue`.

**Jira role fields** — only if the user provided a value:
- `assignee`: `{"accountId": "..."}`
- `customfield_17103` (CD): `[{"accountId": "..."}]`
- `customfield_11056` (Producer): `[{"accountId": "..."}]`
- `customfield_11148` (Editor): `{"accountId": "..."}`
- `customfield_14752` (Writer): `[{"accountId": "..."}]`

**Drive links** — only if the user provided a URL:
- `customfield_10972` (Open Materials): ADF doc with inlineCard
- `customfield_10591` (Final Exports): ADF doc with inlineCard

### Step 3: Update the description (only if description people OR thumb stoppers were provided)

If the user provided any of: description people, thumb stoppers, or drive links — **rebuild the full description** using the same ADF format as the create harness.

**Merging logic:**
1. Fetch the existing ticket's description to see what's already there.
2. For any description field the user left blank, **preserve the existing value** from the current description.
3. For any field the user filled in, **use the new value**.
4. Rebuild the full ADF description with the merged data and send it via `editJiraIssue`.

**Description ADF structure** (same as create):
```json
{
  "type": "doc",
  "version": 1,
  "content": [
    // Brand line: bold "Brand: " then plain "Dr Marty Pets"
    // Offer line: bold "Offer: " then plain "Nature's Blend"
    // People block (Producer, Editor, VSL Producer(s), VSL Editor) with @mention nodes
    // Horizontal rule
    // "Creative Versions" header (bold)
    // Each TS line: "TS1 - Hook Headline -> " then bold VSL name
    // Horizontal rule (if drive links)
    // Drive links as inlineCard
  ]
}
```

**If the user only provided role fields or drive links (no description people, no thumb stoppers), skip the description rebuild** — just update the custom fields.

### Step 4: Send the edit

Use `editJiraIssue` with:
- `issueIdOrKey`: the VIDPET ticket key
- `contentFormat`: "adf"
- `fields`: everything from Steps 2 + 3

### Step 5: Transition status (only if the user provided a Status)

If the user specified a status, follow the same transition-walking procedure as the create harness:

1. Call `getTransitionsForJiraIssue` to see available transitions.
2. If the target status is directly available, transition to it.
3. If not, walk through intermediate states using this flow order:
   `Backlog → To Do → Writing → Production → Needs an Editor → Editing → Creative Review → Submitted → Ready for Testing → Testing → Results Review → Done`
   `PAUSED` is reachable from most states.
4. Safety limit: 8 hops max.
5. Verify final status.

**If the user did NOT provide a status, do NOT transition. Leave it where it is.**

### Step 6: Confirm

Print:
```
VIDPET-XXX updated
[list each field that was changed]
Status: [current status] (or "unchanged" if no transition)
https://goldenhippomedia.atlassian.net/browse/VIDPET-XXX
```

## Important Rules

- **Blank fields = don't touch.** Never clear a field because the user left it blank in the prompt.
- **NEVER use contentFormat "markdown".** Always use ADF for descriptions.
- **Editor (customfield_11148) is single-user** — `{"accountId": "..."}` not an array.
- **All other role fields are multi-user** — `[{"accountId": "..."}]` arrays.
- **Drive link fields need the full ADF doc wrapper**: `{"type": "doc", "version": 1, "content": [{"type": "paragraph", "content": [{"type": "inlineCard", "attrs": {"url": "..."}}]}]}`
- **"+" separated names** — split and resolve each.
- **NEVER hardcode transition IDs.** Always query available transitions first.
- **Only transition if the user explicitly provided a Status value.**
