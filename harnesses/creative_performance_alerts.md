# Rule: Creative Performance Slack Alerts

When triggered, follow this procedure exactly. Use the Rill MCP tools (query_metrics_view), Slack MCP tools (slack_send_message, slack_search_users), and Jira MCP tools (getJiraIssue).

## Run Modes

- **`"Run creative performance check --all"`** — Team-wide run. Checks ALL pet offer ads in Testing, sends Slack DMs to all opted-in roster members. This is what scheduled tasks use.
- **`"Run creative performance check"`** — Personal mode for the default user (Carter Dawson). Filters to just that person's ads. Prints results but does NOT send Slack messages unless `--all` is specified.
- **`"Run creative performance check for [Name]"`** — Personal mode for a specific person. Same as above but for the named person.
- **`"Run creative performance check --test"`** — Test mode (personal). Lower thresholds, no Slack, no state updates.
- **`"Run creative performance check --test --all"`** — Test mode (team-wide). Lower thresholds, no Slack, no state updates, checks all opted-in users.

## Overview

This automation monitors **individual ads** across Facebook and YouTube that are currently in **Testing** status. It checks each ad's rolling 7-day spend and CAC against offer-specific targets, then sends Slack DMs to the producer, editor, and creative director when milestones are reached.

Each alert is for a **specific ad creative** (identified by its ad/file name), not an aggregated ticket.

**Important context:** Rill's data pipeline has a known gap — VIDPET Jira tickets are not recognized as a project key. This means:
- **Legacy creatives (STOR/ACT/VTD tickets):** Rill has `ticket`, `producer`, `editor`, `ticket_status` populated.
- **VIDPET creatives:** Rill has `ticket = null`, `producer = null`, `editor = null`, `ticket_status = null`. The VIDPET number only appears in the `ad_name` field.

To catch both, this automation uses a **two-prong query strategy** (see Step 2).

## Configuration

### Opted-In Roster

This automation only sends alerts to people who have opted in. To subscribe, add your name and Slack ID below.

**Alert rule:** You receive a DM when an ad you are **producer, editor, or CD** on (per the Jira ticket) hits a spend milestone with CAC at or below target.

| Name               | Slack ID     | Subscribed | Notes                    |
|--------------------|--------------|------------|--------------------------|
| Carter Dawson      | U044BSXELMC  | ✅ yes     | Producer/Editor          |

**To opt in:** Add a row with your name, Slack ID, and set Subscribed to ✅ yes.
**To opt out:** Change your row to ❌ no. Your ads still get tracked; you just don't get DMs.

**Name matching:** The roster name must match the Jira `displayName` for producer/editor/CD fields. Case-insensitive.

### Rill Metrics Views

```
FACEBOOK  → fb_campaigns      (spend measure: sum_spend)
YOUTUBE   → youtube_dashboard  (spend measure: spend)
```

### Milestone Tiers (rolling 7-day spend at or below target CAC)

```
$5,000    → "This one looks promising"
$15,000   → "Pay attention here"
$30,000   → "Getting closer"
$50,000   → "WINNER"
$100,000  → "SUPER WINNER"
$250,000  → "MEGA WINNER"
$500,000  → "UNICORN"
```

### Allowed Pet Offers (ONLY monitor these)

This automation is **pets team only**. Only ads whose Rill `offer` matches one of these 8 offers are monitored. All other offers are skipped — do not query Jira, do not alert. Log skipped count in summary.

```
Nature's Blend        (DMP — Marty & Cesar variants)
Nature's Feast        (DMP)
Nutra Complete        (UPN)
Mobility Renew        (UPN — new, may have no Rill data yet)
Super Food Complete   (BLR)
Dental Chews          (DMP)
Power Foods Complete  (LW)
```

**Offer name matching** — case-insensitive. Resolve aliases before matching (see below).

### Offer Name Aliases

Before every offer lookup (allowlist check AND CAC lookup), resolve these aliases (case-insensitive):

```
Natures Blend          → Nature's Blend
Natures Feast          → Nature's Feast
Superfood Complete     → Super Food Complete
Powerfoods Complete    → Power Foods Complete
```

### Target CAC by Offer (blended 30-day Rill averages)

#### Facebook Target CAC
```
Nature's Blend            → $160
Nature's Feast            → $122
Nutra Complete            → $134
Super Food Complete       → $133
Power Foods Complete      → $127
Dental Chews              → $174  (30-day blended, 2026-03-08 to 2026-04-07)
Mobility Renew            → $150  ⚠️ placeholder — no Rill conversion data yet
```

#### YouTube Target CAC
```
Nature's Blend            → $142
Nature's Feast            → $179
Nutra Complete            → $132
Super Food Complete       → $202
Power Foods Complete      → $152
Dental Chews              → $150  ⚠️ placeholder — no YouTube data yet
Mobility Renew            → $150  ⚠️ placeholder — no Rill conversion data yet
```

If an allowed offer is not in the platform-specific table above, use $150 as the default target CAC. If an ad's offer is null or empty, use $150 default and show `(unknown offer)` in the alert. Log in summary: `Unknown offer: [N] ads`.

### Jira Constants

```
CLOUD_ID = "972e7666-58b6-4e89-87f4-6c0f672f67bd"
```

### Custom Field IDs (Jira)

```
Creative Director  → customfield_17103  (multi-user array)
Producer           → customfield_11056  (multi-user array)
Editor             → customfield_11148  (single user object)
```

### Alert State File

```
STATE_FILE → /Users/carterdawson/Downloads/vidpet-harness-main/.claude/alert_state.json
```

Structure — keyed by **platform + ad_name** (each individual ad is tracked separately):

```json
{
  "fb::VIDPET-450_DMP_NB_CesarRanks2.0_OPT-4_CesarSoloVSL-no-MM_4x5_260331_vB-WL": {
    "vidpet_number": "VIDPET-450",
    "milestones_alerted": [5000],
    "last_checked": "2026-04-03T14:30:00"
  }
}
```

**State key format:** `{platform}::{ad_name}` — each individual ad creative is tracked independently.

## Schedule

- **Frequency:** Twice per day — 9:00 AM and 2:30 PM PST
- **Days:** Monday through Friday only
- **Quiet hours:** No alerts outside 9 AM – 6 PM PST (enforced by Step 0)

## Procedure

### Step 0: Business hours check

Check the current time in `America/Los_Angeles` (PST/PDT).

- **If outside Mon–Fri, 9 AM – 6 PM PST:** Print `"Outside business hours ([current time PST]) — aborting. No Slack messages sent."` and stop. Do not query Rill, do not send alerts.
- **Exception:** `--test` mode always proceeds regardless of time.

### Step 1: Load alert state

Read the alert state file. If it doesn't exist, start with an empty `{}` object.

### Step 2: Query Rill (two prongs)

Query **both** `fb_campaigns` and `youtube_dashboard`. For each platform, run TWO queries:

#### Prong 1: Legacy creatives (has producer/editor in Rill)

Catches STOR-, ACT-, VTD- tickets in Testing status. In `--all` mode, returns ALL Testing ads (no per-person filter). In personal mode, add the user filter.

**Team-wide (`--all`) query:**
```
metrics_view: fb_campaigns (or youtube_dashboard)
dimensions: [ad_name, ticket, offer, producer, editor, ticket_status, project_key]
measures: [sum_spend (or spend for YT), cac, total_new_customers]
time_range: { start: <7 days ago 00:00:00Z>, end: <tomorrow 00:00:00Z> }
time_zone: "America/Los_Angeles"
where: ticket_status = "Testing"
sort: [sum_spend desc]
limit: 500
```

**Personal mode query:** Same as above but add: `AND (producer = "<user_name>" OR editor = "<user_name>")`

**Post-filter:** Keep only ads whose `offer` (after alias resolution) is in the pet offer allowlist.

Filter results: spend > $0.

#### Prong 2: VIDPET creatives (null producer/editor in Rill)

Catches VIDPET ads where Rill has no ticket/producer/editor data. Status filtering happens after Jira lookup (Step 3).

```
metrics_view: fb_campaigns (or youtube_dashboard)
dimensions: [ad_name, offer]
measures: [sum_spend (or spend for YT), cac, total_new_customers]
time_range: { start: <7 days ago 00:00:00Z>, end: <tomorrow 00:00:00Z> }
time_zone: "America/Los_Angeles"
where: (ad_name ILIKE "%VIDPET%" OR ad_name ILIKE "%VIDEPT%")
sort: [sum_spend desc]
limit: 200
```

**Note:** If the result count is exactly 200, log a warning: `"Prong 2 hit query limit (200) — some ads may have been truncated."` Raise the limit if this becomes frequent.

Filter results: spend > $0.

### Step 3: Process Prong 2 results — Jira lookup and filtering

For each ad from Prong 2:

0. **Allowlist check first.** Resolve the ad's `offer` field through alias mapping, then check it against the pet offer allowlist. If the offer is not in the allowlist (including null/empty), skip the ad immediately. Do not proceed to Jira lookup. Log in summary: `Skipped (non-pet offer): [N] ads`.

1. **Extract VIDPET number from ad_name.** Search for the pattern `VID[EP]{2}T[-_ ]?(\d+)` (case-insensitive). This also catches the known "VIDEPT" typo. Normalize to `VIDPET-{number}`.
   - `VIDPET-157_DMP_NB_...` → VIDPET-157
   - `...cerealVIDPET122A-v01...` → VIDPET-122
   - `dvp-NC-VIDPET270;Honey...` → VIDPET-270
   - `VIDPET 225 UPN NC...` → VIDPET-225
   - `VIDEPT-310_DMP_...` → VIDPET-310 (typo corrected)

   **Multi-match:** If multiple VIDPET numbers appear in one ad name, extract ALL of them. Look up each in Jira. In `--all` mode, use the one where ANY opted-in roster member is producer/editor/CD. In personal mode, use the one matching the specified user. If multiple match, use the first.

   **No match:** If the ad name contains "VIDPET" but no extractable number (e.g., `VIDPET_Best + Worst Foods`), log: `"[ad_name] — contains VIDPET but no ticket number, skipped."` and skip.

2. **Look up each unique VIDPET number in Jira** (cache — don't re-fetch the same ticket):
   ```
   getJiraIssue(cloudId: CLOUD_ID, issueIdOrKey: "VIDPET-XXX",
     fields: ["customfield_11056", "customfield_11148", "customfield_17103", "status"])
   ```
   - Producer = **ALL entries** in `customfield_11056` array (not just [0]). Collect all `displayName` values.
   - Editor = `customfield_11148.displayName` (single user)
   - CD = **ALL entries** in `customfield_17103` array (not just [0]). Collect all `displayName` values.

   **Always iterate the full array for multi-user fields.** A ticket may have multiple producers or CDs — checking only [0] will silently miss anyone listed second or later.
   - Status = `status.name`

3. **Filter — keep only ads where ALL of these are true:**
   - The Jira ticket status is **"Testing"** (case-insensitive)
   - **`--all` mode:** At least one of the ad's producer, editor, or CD is in the Opted-In Roster with Subscribed = ✅ yes (name match, case-insensitive). Tag each matched roster member as an alert recipient for this ad.
   - **Personal mode:** The specified user matches the Jira producer OR editor.

   Discard ads where the ticket is in any other status (Done, Results Review, Editing, etc.).
   In `--all` mode, also log: `"[ticket] — no opted-in users (producer: X, editor: Y)"` for ads with no roster matches.

4. **Deduplicate against Prong 1:** If a Prong 2 ad also appeared in Prong 1 results (same ad_name), keep the Prong 1 version. Skip the duplicate.

### Step 4: Compute spend velocity

For each qualifying ad, run a **daily breakdown query** to calculate spend velocity and milestone projection.

Query the same metrics view with the **date dimension** to get daily granularity for the last 7 days, filtered to that specific ad_name:

```
metrics_view: fb_campaigns (or youtube_dashboard)
dimensions: [date]
measures: [sum_spend (or spend for YT), total_new_customers]
time_range: { start: <7 days ago 00:00:00Z>, end: <tomorrow 00:00:00Z> }
time_zone: "America/Los_Angeles"
where: ad_name = "<exact_ad_name>"
sort: [date asc]
limit: 7
```

**Note:** Both FB and YouTube use `date` as the time dimension. YouTube's spend measure is `spend` (not `sum_spend`).

**Batch this:** To avoid excessive queries, only run daily breakdowns for ads that have spend > $0 AND CAC <= target (i.e., ads that could potentially trigger a milestone). Skip velocity queries for ads that have already failed the CAC check.

From the daily results, compute:
- **Daily avg spend** = total 7-day spend / number of days with data
- **Last 3-day avg** = sum of last N days / N, where N = min(3, number of days with spend data). Never divide by 3 if fewer than 3 days have data.
- **Spend velocity** = last 3-day avg (more recent = more representative of current trajectory)
- **Velocity direction:**
  - If last 3-day avg > daily avg → `↑` (accelerating)
  - If last 3-day avg < daily avg × 0.8 → `↓` (decelerating)
  - Otherwise → `→` (steady)
- **Days to next milestone** = (next_milestone_threshold − current_spend) / spend_velocity. Round up. If velocity ≤ 0, show "—".

### Step 5: Evaluate milestones

For each qualifying ad:

1. **7-day spend** = the ad's spend value from the query (each row is already a single ad).

2. **CAC** = from the `cac` measure. If null (no new customers), skip milestone evaluation. Log: `"[ad_name] — $X spend, no conversions yet."`

3. **New customers** = from the `total_new_customers` measure. Include in alert message.

4. **Target CAC** = look up by offer name and platform. Case-insensitive. Default $150.

5. **Highest milestone reached:** Walk from $500K down to $5K. Spend must be >= threshold AND CAC must be <= target.

6. **Next milestone** = the next threshold above the highest reached. Used for projection.

7. **Check state:** Look up `{platform}::{ad_name}` in state. Only alert for milestones HIGHER than any previously alerted.

### Step 6: Resolve Slack users to notify

For each ad that needs an alert, collect the people to DM:

- **`--all` mode:** All opted-in roster members who are producer, editor, or CD on that ad's Jira ticket.
- **Personal mode:** Just the specified user (+ CD if opted in).

Deduplicate — if someone is both producer and editor on a ticket, one DM.

**Slack ID resolution (in order):**

1. **Check the Opted-In Roster first.** If the person's name matches a roster entry, use the Slack ID from the roster. This is the fastest and most reliable path.
2. **If not in roster (e.g., CD who hasn't opted in):** Skip — do NOT send DMs to people who haven't opted in.
3. **If roster entry has no Slack ID:** Try `slack_search_users` with the person's full name, then email fallback from Jira user object.

**Known name mismatches (for Slack search fallback only):**
- Jira "Mariia Hladkova" = Slack "Maria Gladkova" (maria.gladkova@goldenhippo.com → U05LXLREW7N)
- Jira "Jennifer Sabih" = Slack "jennifer" (jennifer.sabih@goldenhippo.com → U2UPKEY7N)
- Jira "Carter Dawson" = Slack "Carter Dawson" (carter.dawson@goldenhippo.com → U044BSXELMC)

**Cache all Slack lookups** within the same run.

### Step 7: Send Slack alerts

**Only in `--all` mode (or non-test personal mode).** Send a **DM to each opted-in person** using `slack_send_message` with their Slack user ID as `channel_id`.

**⚠️ First-run note:** `slack_send_message` is called with a Slack user ID (e.g., `U044BSXELMC`) as the `channel_id`. If the MCP requires a DM channel ID (`D...`) instead, the send will fail with a channel-not-found error. On the first real run, verify that at least one DM was actually received in Slack. If not, the MCP may need `slack_open_dm` called first to get a DM channel ID, then pass that to `slack_send_message`.

#### Alert Message Format (Slack markdown)

Use this exact Slack markdown layout. The message uses emoji milestone icons, bold numbers, code blocks for the ad file name, and inline links.

**Milestone emoji mapping:**
- "This one looks promising" → 👀
- "Pay attention here" → 🔥
- "Getting closer" → 🚀
- "WINNER" → 🏆
- "SUPER WINNER" → 💎
- "MEGA WINNER" → ⚡
- "UNICORN" → 🦄

**Template:**

```
[emoji] *[MILESTONE LABEL]*
`[VIDPET_NUMBER]` · [Offer] · [Facebook / YouTube]

`[full ad_name / file name]`

💰 *$[spend]* spend (7-day)
📉 *$[CAC]* CAC · target $[target]
👥 *[N]* new customers
[velocity_arrow] *$[daily_avg]/day* avg · [next_milestone] in ~[N] days

Producer: [name] · Editor: [name]
<jira_url|[VIDPET_NUMBER] on Jira> · <rill_url|View in Rill>
```

**Velocity arrow:** `↑` accelerating, `→` steady, `↓` decelerating.
- If already at $500K (UNICORN): `🦄 *UNICORN status* — no higher milestone`
- If velocity ≤ 0: `→ spending paused`

**Rill dashboard links:**
- Facebook: `https://rill.goldenhippo.com/goldenhippo-rill/fb_campaigns`
- YouTube: `https://rill.goldenhippo.com/goldenhippo-rill/youtube_dashboard`

**Notes:**
- If producer or editor is null in Jira, omit that role entirely. Never show "null" or "(none)".
- Use Slack link format `<url|display text>` for Jira and Rill links.
- Separate items on the same line with ` · ` (space-dot-space).

**Examples:**

```
👀 *This one looks promising*
`VIDPET-450` · Nature's Blend · Facebook

`VIDPET-450_DMP_NB_CesarRanks2.0_OPT-4_CesarSoloVSL-no-MM_4x5_260331_vB-WL`

💰 *$5,420* spend (7-day)
📉 *$148* CAC · target $160
👥 *37* new customers
↑ *$850/day* avg · $15K in ~11 days

Producer: Carter Dawson · Editor: Carter Dawson
<https://goldenhippomedia.atlassian.net/browse/VIDPET-450|VIDPET-450 on Jira> · <https://rill.goldenhippo.com/goldenhippo-rill/fb_campaigns|View in Rill>
```

```
🏆 *WINNER*
`VIDPET-342` · Nature's Blend · Facebook

`VIDPET-342_DMP_NB_CesarRanks-2.0_V-1_OPT-2_CesarSoloVSL-no-MM_4x5_260316_vA-WL-`

💰 *$52,100* spend (7-day)
📉 *$146* CAC · target $160
👥 *357* new customers
↑ *$8,200/day* avg · $100K in ~6 days

Producer: Carter Dawson · Editor: Carter Dawson
<https://goldenhippomedia.atlassian.net/browse/VIDPET-342|VIDPET-342 on Jira> · <https://rill.goldenhippo.com/goldenhippo-rill/fb_campaigns|View in Rill>
```

For legacy tickets (Prong 1, no VIDPET number), use the Rill ticket as the identifier:

```
🔥 *Pay attention here*
`STOR-4205` · Nature's Blend · Facebook

`DMP_NB_CesarRanks_CesarSoloVSL-no-MM_STOR-4205_251231C_-WL-.mp4`

💰 *$2,185* spend (7-day)
📉 *$156* CAC · target $160
👥 *14* new customers
→ *$310/day* avg · $5K in ~9 days

Producer: Carter Dawson · Editor: Carter Dawson
<https://goldenhippomedia.atlassian.net/browse/STOR-4205|STOR-4205 on Jira> · <https://rill.goldenhippo.com/goldenhippo-rill/fb_campaigns|View in Rill>
```

### Step 8: Update alert state

After sending all alerts, update the state file for every qualifying ad checked.

**Pruning:** Before writing, remove any state entries where `last_checked` is more than 30 days ago. These are stale entries for ads that are no longer active. Log: `"Pruned [N] stale state entries."` (only if N > 0).

```json
{
  "fb::VIDPET-450_DMP_NB_CesarRanks2.0_OPT-4_CesarSoloVSL-no-MM_4x5_260331_vB-WL": {
    "vidpet_number": "VIDPET-450",
    "milestones_alerted": [5000],
    "last_checked": "2026-04-03T14:30:00"
  }
}
```

### Step 9: Print summary

**Team-wide (`--all`) summary:**
```
Creative performance check complete — [timestamp PST]
Mode: Team-wide (all opted-in users)
─────────────────────────────────────
Opted-in roster: [N] people ([list names])
Prong 1 (legacy, Testing):    [N] ads ([N] FB, [N] YT)
Prong 2 (VIDPET, all):        [N] ads → [N] Jira lookups
  Matched opted-in user: [N]
  No opted-in user:      [N] (skipped)
  Not Testing:           [N] (skipped)
─────────────────────────────────────
Alerts sent: [N] milestone alerts to [N] people
  [list each: "WINNER — VIDPET-342 → DM to Carter, Jennifer"]
Skipped (CAC above target): [N] ads
Skipped (no conversions):   [N] ads
Skipped (no ticket number in ad name): [N] ads
Skipped (VIDEPT typo corrected): [N] ads
Skipped (non-pet offer): [N] ads
Used default CAC ($150): [N] ads ([list offer names])
Unknown offer: [N] ads
Slack lookup failures: [N]
```

**Personal mode summary:**
```
Creative performance check complete — [timestamp PST]
Mode: Personal — [user_name]
─────────────────────────────────────
Prong 1 (legacy tickets, Testing): [N] ads ([N] FB, [N] YT)
Prong 2 (VIDPET ads, Testing):     [N] ads matched user ([N] Jira lookups)
Filtered out: [N] (wrong user), [N] (not Testing status)
─────────────────────────────────────
[same detail lines as team-wide]
```

## Weekly Digest

When the user says **"Run creative performance digest"** or this is triggered on **Friday at 2:30 PM PST**, send a personalized summary DM to each opted-in roster member covering the full week.

### Digest Procedure

1. Run the standard Steps 1–5 in `--all` mode (query, filter, evaluate) but do NOT send milestone alerts.
2. Collect ALL qualifying ads (Testing status) across both platforms.
3. Group ads by opted-in roster member (each person's digest includes only ads where they are producer, editor, or CD).
4. Build and send a personalized digest DM to each opted-in person.

### Digest Message Format

```
📊 Weekly Creative Digest — [Monday date] to [Friday date]
Monitoring: [user_name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 Milestone hits this week: [N]
[list each: "WINNER — VIDPET-342 (Nature's Blend) — $52K / $146 CAC"]

📈 Top performers (by 7-day spend, CAC at or below target):
1. [ad_name_truncated_to_60_chars]... — $[spend] | $[CAC] CAC | [velocity_arrow] $[daily]/day
2. ...
3. ...
(up to top 5)

⏳ On the radar (spending but CAC above target):
1. [ad_name_truncated]... — $[spend] | $[CAC] CAC (target: $[target]) — [X]% over
(up to top 3)

📊 Week totals:
Ads in Testing: [N] (FB: [N], YT: [N])
Total 7-day spend (your ads): $[sum]
Total new customers: [sum]
Blended CAC: $[weighted_avg]

[Rill FB link]
[Rill YT link]
```

### Digest Rules

- **Only sent on Fridays** (or when manually triggered with "Run creative performance digest").
- **One message per user** — everything in a single DM, not one per ad.
- **Truncate ad names** to 60 chars in the digest to keep it readable. Full names are in the milestone alerts.
- **"On the radar" section** shows ads that are spending but haven't hit CAC target yet — these are worth watching because a small CAC improvement could push them into milestone territory.
- **Week totals** give the user a high-level snapshot of their testing portfolio.
- The digest does NOT replace milestone alerts. Both can fire on Friday — milestones first, then digest at the scheduled time.

## Test Mode

When the user says **"Run creative performance check --test"**, use reduced thresholds and don't send real messages:

### Test Thresholds
```
$500      → "This one looks promising"
$1,500    → "Pay attention here"
$3,000    → "Getting closer"
$5,000    → "WINNER"
$10,000   → "SUPER WINNER"
$25,000   → "MEGA WINNER"
$50,000   → "UNICORN"
```

In test mode:
- **DO NOT send Slack messages.** Print what WOULD be sent.
- **DO NOT update the alert state file.** Use temporary in-memory state.
- **DO print every ad evaluated** with its spend, CAC, target CAC, milestone, and pass/fail reason.

## Important Rules

- **Track INDIVIDUAL ADS, not aggregated tickets.** Each ad_name is its own entity with its own milestones. Two ads from the same VIDPET ticket are tracked and alerted separately.
- **Only track "Testing" status.** Ignore ads where the ticket status is Done, Results Review, Editing, or any other status. Only "Testing" (case-insensitive) qualifies.
- **NEVER send duplicate alerts.** Check state first. One alert per milestone per ad, ever.
- **Rolling 7-day window** — query exactly the last 7 days. NOT lifetime spend.
- **CAC must be at or below target** for a milestone to count.
- **If CAC is null** (zero new customers), do NOT trigger milestone alerts.
- **Platform-specific target CAC** — Facebook table for FB, YouTube table for YT.
- **Evaluate each platform independently.** Same ad name on FB and YT = separate tracking.
- **DM each person individually.** Deduplicate — if producer = editor, send ONE DM, not two.
- **Only DM opted-in users.** Never send alerts to someone not in the roster with Subscribed = ✅ yes.
- **Roster name must match Jira displayName** (case-insensitive). If someone's Jira name is "Mariia Hladkova", their roster name must be "Mariia Hladkova".
- **Use roster Slack IDs first.** Only fall back to Slack search if the roster ID is missing.
- **Business hours only** — Mon-Fri, 9 AM – 6 PM PST.
- **Show the full ad/file name** in every alert message. This tells the producer/editor exactly which creative is performing.
- **Cache all Jira and Slack lookups** within a single run.
- **Resolve offer aliases before any offer check.** Always run alias resolution first — before the allowlist check AND before CAC lookup.
- **Pets team only — allowlist enforced.** Only the 8 listed pet offers are monitored. Skip everything else. Don't waste Jira lookups on non-pet products.
- **Null offer = $150 default.** Log it, don't crash.
- **Offer name matching** — case-insensitive. Handle variations (e.g., "Nature's Blend" = "Natures Blend").
- **Graceful failures** — if a single Slack/Jira lookup fails, log and continue. Never crash the entire run.
