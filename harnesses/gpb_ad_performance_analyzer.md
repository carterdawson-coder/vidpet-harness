# GPB Ad Performance Analyzer

When the user says **"Analyze [TICKET]"**, **"Analyze [TICKET] on the [Account] account"**, or **"Pull performance for all [pattern] ads on the [Account] account last [N] days"**, follow this procedure exactly. Use the Rill MCP tools (`query_metrics_view`). Optionally use Slack MCP (`slack_send_message`) if `--slack` flag is present.

## Run Modes

- **Single ticket**: `"Analyze VIDPET-381"` — pulls all-time data for that ticket, scores, diagnoses, delivers verdict.
- **Single ticket + account override**: `"Analyze STOR-3169 on the Nature's Blend CM account"` — bypasses auto-detection, uses the specified account.
- **Multi-ad**: `"Pull performance for all CesarRanks ads on the CM account last 90 days"` — broader filter, scores each ad individually.
- **`--slack` flag**: Appending `--slack` to any mode also sends the final report as a Slack DM. Default recipient: Carter Dawson (`U044BSXELMC`). To DM someone else: `--slack @Name`.

### Role Flags (optional — change the report lens)

Append a role flag to any command to get a report tailored to that role. **Same data, same queries, different output focus.**

| Flag | Role | Core Question | Report Focus |
|---|---|---|---|
| *(no flag)* | **Producer** (default) | "Which creative angle is winning and what do I make next?" | Hook angle psychology, variant comparison, TS headline analysis, pack history, what to create next |
| `--editor` | **Editor** | "Where exactly in the timeline do I cut?" | Timestamp-heavy retention waterfall, specific edit points with seconds, B-roll/editorial section diagnosis, pacing recommendations |
| `--offer-manager` | **Offer Manager** | "Is this offer's unit economics healthy?" | CAC vs. blended CAC, NCR, continuity opt-in, AOV, refund rate, offer-level health vs. creative-level health, split test results |
| `--media-buyer` | **Media Buyer** | "Where do I put the budget and when do I scale?" | ROI/CAC scoring, spend velocity, budget allocation, CPM trends, audience fatigue signals, scaling thresholds, pacing plan |

Examples:
- `"Analyze VIDPET-458"` → producer report (default)
- `"Analyze VIDPET-458 --editor"` → editor report
- `"Analyze VIDPET-458 --offer-manager"` → offer manager report
- `"Analyze VIDPET-458 --media-buyer"` → media buyer report
- `"Analyze VIDPET-458 --editor --slack"` → editor report, sent to Slack

## Constants

### Brand-to-Account Lookup Table

| Brand | Account Name (exact Rill value) | Offer Filter |
|---|---|---|
| Dr. Marty Nature's Blend (Cesar Millan) | `Dr. Marty - Nature's Blend - CM` | `offer = 'Nature's Blend'` |
| Dr. Marty Nature's Blend (Marty) | `Dr Marty - Nature's Blend (Created May21)` | `offer = 'Nature's Blend'` |
| Dr. Marty Nature's Blend Quiz | `Dr. Marty - Nature's Blend - Quiz` | `offer = 'Nature's Blend'` |
| Dr. Marty Nature's Feast | `Dr. Marty - Nature's Feast` | `offer = 'Nature's Feast'` |
| Dr. Marty Dental Chews | `Dr. Marty - Dental Chews` | `offer = 'Dental Chews'` |
| Nutra Complete | `Nutra Complete - 2024` | `offer = 'Nutra Complete'` |
| Mobility Renew | `UPN - Mobility Renew` | `offer = 'Mobility Renew'` |
| Badlands Ranch Superfood Complete | `Badlands Ranch by Katherine Heigl - Superfood Complete` | `offer = 'Super Food Complete'` |
| Lone Wolf Power Foods Complete | `Lone Wolf Ranch - Power Foods Complete - Quiz` | `offer = 'Power Foods Complete'` |

**Account shorthand aliases** (for user convenience in prompts):

```
"CM account" or "Cesar account"       → Dr. Marty - Nature's Blend - CM
"Marty account"                        → Dr Marty - Nature's Blend (Created May21)
"Quiz account" or "NB Quiz"            → Dr. Marty - Nature's Blend - Quiz
"Feast account"                        → Dr. Marty - Nature's Feast
"Dental account" or "Dental Chews"     → Dr. Marty - Dental Chews
"Nutra account" or "NC account"        → Nutra Complete - 2024
"Mobility account" or "MR account"     → UPN - Mobility Renew
"Badlands account" or "BLR account"    → Badlands Ranch by Katherine Heigl - Superfood Complete
"Lone Wolf account" or "LW account"    → Lone Wolf Ranch - Power Foods Complete - Quiz
```

### Rill Configuration

```
FACEBOOK   → fb_campaigns                (spend measure: sum_spend)
YOUTUBE    → youtube_dashboard            (spend measure: spend)
SPLIT TEST → split_testing_model_metrics  (dimension: initial_split, format: ST-XXXXXXX)
```

### Rill Measure Names (exact)

These are the exact measure names to use in queries. Never guess or abbreviate.

**Facebook (`fb_campaigns`) measures:**
```
sum_spend
revenue
roi
cac
bcac
cpa
cvr
ctr
cpm
ncr
continuity_opt_in
imp-3sec
three-TP
25-watched
50-watched
75-watched
100-watched
avg_time_watched
total_customers
total_new_customers
```

**YouTube (`youtube_dashboard`) measures:**
```
spend              (equivalent to FB sum_spend)
revenue
roi
cac
bcac
cpa
cvr
ctr
cpm
ncr
total_customers
total_new_customers
```

**YouTube retention measures (different names from FB):**
```
watched_25_rate    (equivalent to FB 25-watched)
watched_50_rate    (equivalent to FB 50-watched)
watched_75_rate    (equivalent to FB 75-watched)
watched_100_rate   (equivalent to FB 100-watched)
average_duration   (equivalent to FB avg_time_watched)
view_rate          (YouTube-specific — % of impressions that became a video view)
```

**YouTube does NOT have these FB measures** — omit from YouTube queries:
```
continuity_opt_in  (not tracked on YouTube)
imp-3sec           (use view_rate instead for top-of-funnel)
three-TP           (no thruplay concept on YouTube)
```

### Offer Name Aliases

Before every offer lookup (brand identification AND benchmark selection), resolve these aliases (case-insensitive):

```
Natures Blend          → Nature's Blend
Natures Feast          → Nature's Feast
Superfood Complete     → Super Food Complete
Powerfoods Complete    → Power Foods Complete
```

### Rill Dashboard Links

```
Facebook: https://rill.goldenhippo.com/goldenhippo-rill/fb_campaigns
YouTube:  https://rill.goldenhippo.com/goldenhippo-rill/youtube_dashboard
```

### Performance Benchmarks by Brand

#### Dr. Marty Nature's Blend (Cesar Millan account)

| Metric | 🟢 Green | 🟡 Yellow | 🔴 Red |
|---|---|---|---|
| ROI | ≥ 107% annualized | 80–107% | < 80% |
| CAC | $130–$145 | $145–$165 | > $165 or < $100 |
| CVR | ≥ 1.5% | 1.0–1.5% | < 1.0% |
| Hook Rate (imp-3sec) | ≥ 15% | 10–15% | < 10% |
| 3sec→TP Retention | 38–57% | 30–38% | < 30% |
| NCR | ≥ 60% | 45–60% | < 45% |
| Continuity Opt-In | ≥ 35% | 25–35% | < 25% |

#### Dr. Marty Nature's Feast

Use same ROI/CAC targets as Nature's Blend until brand-specific benchmarks are established.

#### Nutra Complete

- ROI target: ≥ 107% annualized
- CAC: $130–$160 range (slightly wider — newer funnel)

#### Mobility Renew

- ROI target: ≥ 107% annualized
- CAC: benchmark against account average (query account-level blended CAC for reference)

#### Badlands Ranch / Power Foods Complete

- ROI target: ≥ 107% annualized
- CAC: use account-level CAC average as reference point (query account-level blended CAC)

#### Dental Chews (launched 2/1 — limited data)

Do **not** score against hard benchmarks yet. Report trajectory only — show the numbers and trend direction without Green/Yellow/Red flags.

### Hook Angle Types

When analyzing TS headlines, classify each by its dominant angle. This explains WHY different hooks perform differently — not just that they do.

| Angle | Pattern | Hook Behavior | Commitment Behavior | Example |
|---|---|---|---|---|
| **Curiosity/Emotional** | Question or emotional trigger, no specifics revealed | Lower 3sec (35-45%) — filters casual scrollers | Higher thruplay — self-selects committed viewers | "Your Dog Is Trying to Tell You Something" |
| **Shock/Urgency** | ALL CAPS, exclamation, "WATCH THIS" energy | Higher 3sec (50%+) — grabs eyeballs | Lower thruplay — attracts attention but not commitment | "WATCH WHAT Just a FEW DROPS CAN DO!" |
| **Authority** | Celebrity/expert name + directive | Mid-range 3sec (40-50%) — name recognition pulls | Mid thruplay — Cesar's credibility carries | "Cesar Millan Says, Do This" |
| **Fear/Loss** | Warning, "watch out", loss aversion | Mid-high 3sec (45-55%) — anxiety trigger | Variable thruplay — depends if fear converts to curiosity or bounces | "Watch Out! Cesar Millan Wants You to Hear This" |
| **UGC/Social Proof** | User-generated content feel, testimonial | Variable — different visual language | Variable — authenticity can hook or confuse | "UGC Intro" |
| **Listicle/Recipe** | Promise of specific info or method | Mid 3sec (40-50%) — info-seekers click | Higher thruplay — they came for the recipe, they'll watch | "Cesar Millan's Recipe for Dog Longevity" |

**Key insight:** A low-hook + high-conversion variant isn't broken — it's **filtering for buyers.** Curiosity hooks self-select committed viewers who watch longer and convert more. Shock hooks grab more eyeballs but attract casual scrollers who bounce. Always interpret hook rate TOGETHER with thruplay and conversion, not in isolation.

**Hybrid angles:** Some headlines combine angles (e.g., "Watch Out! Cesar Millan Wants You to Hear This" is Fear + Authority). Classify by the DOMINANT angle but note the secondary.

### Creative Structure — How Ads Work

Every ad in this system is a **full-length VSL** (15–30 minutes) uploaded directly to Facebook/YouTube. Rill's retention metrics measure viewers watching through the actual VSL, not a short clip. The structure:

```
┌─────────────┐   ┌──────────────────────┐   ┌──────────────────────────────────┐
│  0–3 sec    │   │  3–50 sec            │   │  50 sec → 15-30 min             │
│  THUMBSTOPPER│──▸│  CONNECTOR (ad body) │──▸│  VSL (primary conversion driver) │
│  (TS)       │   │  (new creative angle)│   │  Product mention at ~15+ min    │
└─────────────┘   └──────────────────────┘   └──────────────────────────────────┘
```

**Two creative formats** (detect from ad_name):
- **TS-only** — ad_name contains a TS token at a word boundary: `_TS_`, `-TS-`, `_TS-`, `-TS_`, or `_TS` at end of name. Do NOT match "TS" as a substring inside other words (e.g., "CesarRanks_Results" should NOT match). Use regex: `[_-]TS([_-]|$)` (case-insensitive).
- **Ad body** — no TS token found. Has a 30–60 second connector (new creative angle) between the hook and the VSL.

**What Rill retention checkpoints measure** (for a ~20 min VSL):

| Rill Metric | Approx Timestamp | Creative Segment | What It Tells You |
|---|---|---|---|
| `imp-3sec` | 0–3 sec | **Thumbstopper** | Is the hook stopping thumbs? |
| `three-TP` | 3sec → ~15sec | **Early connector / VSL entry** | Does the viewer commit past the hook? |
| `25-watched` | ~5 min mark | **Early VSL** | Story setup / problem-agitation holding? |
| `50-watched` | ~10 min mark | **Mid VSL** | Building the case — is viewer still engaged? |
| `75-watched` | ~15 min mark | **Product reveal zone** | Viewer reaches product mention — critical gate |
| `100-watched` | ~20 min mark | **VSL close / CTA** | Full VSL completion — strongest buy signal |

**Key insight:** The product is NOT mentioned until ~15+ minutes in (~75% mark). Any viewer who reaches 75-watched has heard the pitch. If they don't convert after that, it's a pitch/offer/price issue — not a creative issue.

**Computing actual timestamps:** `actual_timestamp = retention_percentage × vsl_duration`. Default VSL duration = 20 minutes unless known otherwise. For a 20-min VSL: 25% = ~5:00, 50% = ~10:00, 75% = ~15:00, 100% = ~20:00. **Always show BOTH the percentage AND the computed timestamp in the report** — editors think in timestamps, not percentages.

### Funnel Diagnosis Patterns

Read the retention curve as a **segment-by-segment dropoff map.** Each drop tells you which creative segment to fix.

| Pattern | Where the Drop Is | Signals | Root Cause | Fix |
|---|---|---|---|---|
| **TS problem** | imp→3sec | Low imp→3sec (<15%) | Thumbstopper not stopping | New hook visual, first-frame change |
| **Connector problem** | 3sec→TP or 3sec→25% | Good 3sec, big drop before 25-watched. Connector is 30-60s; healthy TP rate is 38-57% of 3sec viewers. Below 30% = connector is losing them. | Ad body / connector loses them before VSL kicks in | If connector >45s, cut to 25-30s. If already short, the creative angle isn't bridging to the VSL — test TS-only format (skip connector entirely) |
| **Early VSL dropout** | 25%→50% | Good entry but 50-watched drops sharply from 25-watched | Story/problem-agitation section loses momentum | Pacing issue — tighten the problem section, add more Cesar talking (not editorial) |
| **Pre-pitch dropout** | 50%→75% | 50-watched holds but 75-watched drops | Viewers leave RIGHT BEFORE product reveal | The case-building section is too long or loses urgency — they're bored before the payoff |
| **Pitch failure** | 75%→CVR | 75-watched is healthy but CVR is low (<1%) | They heard the pitch but didn't buy | Offer/price/CTA issue, not creative. VSL audit needed. |
| **Audience problem** | CVR→NCR | Good CVR, low NCR (<45%) | Converting existing customers, not new | Audience targeting or exclusion list issue |
| **Fatigue** | Trend over time | Good early metrics, declining ROI/CVR in daily data | Creative exhausted — audience saturated | Rotate new variants |
| **Scaling signal** | Nowhere — all green | All metrics green + upward daily trend | Working — needs fuel | Increase budget |

**How to read the retention curve:**
1. Evaluate `imp-3sec` as a standalone hook rate (different denominator from the rest — see Step 5b warning)
2. Calculate the **drop ratio** between each consecutive video_view-denominated checkpoint: `three-TP → 25-watched → 50-watched → 75-watched → 100-watched`
3. The **biggest percentage drop** between two consecutive checkpoints = the segment where viewers are leaving
4. Name that segment using the creative structure table above
5. The fix targets THAT specific segment — not the whole creative

**Nature's Blend CM account note:** A connector/early-VSL dropout in this account traces most commonly to a **cadence break** — any section where Cesar stops talking and shifts to editorial footage (e.g., the 0:12–0:18 fresh food pouches section in STOR-3169). Always check if a retention drop maps to a known editorial section before diagnosing. The fix is usually cutting/shortening the editorial and keeping Cesar on screen.

## Procedure

### Step 1 — Parse Input & Resolve Account

1. Extract the ticket number, ad pattern, or identifier from the user's prompt.
2. Extract account name if provided (resolve shorthand aliases from the table above).
3. Extract time range if provided (e.g., "last 90 days"). Default: all available data (`2021-01-01` to today) for single ticket mode; last 30 days for multi-ad mode.

**VIDPET typo handling:** Real ad names sometimes contain `VIDEPT` (transposed letters). When querying for any VIDPET ticket, ALWAYS search for both spellings:
- `ad_name ILIKE '%VIDPET-XXX%' OR ad_name ILIKE '%VIDEPT-XXX%'`
- If results come back with the VIDEPT spelling, note it in the report: `"Note: Ad name uses VIDEPT typo — normalized to VIDPET-XXX."`

**If the account is ambiguous** (no account specified and ticket prefix doesn't clearly map):
- Run a discovery query: `ad_name ilike '%TICKET%'` (include VIDEPT variant if applicable) across all accounts on `fb_campaigns` with `account_name` as a dimension.
- Identify which account the ticket lives in from the results.
- If found on multiple accounts, report all and ask the user to clarify.

### Step 1.5 — Pull Creative Context from Jira (single-ticket mode only)

For VIDPET tickets, use `getJiraIssue` (Jira MCP) to pull the ticket and extract:

1. **Thumb stopper headlines** — from the description's "Creative Versions" section. Map each variant letter to its TS headline using **positional order**: the first TS line in the description = vA, second = vB, third = vC, etc. The variant letter in the Rill ad_name (`_vA-`, `_vB-`, etc.) corresponds to the order they appear in the Jira ticket description.
   - TS1 → vA, TS2 → vB, TS3 → vC, TS4 → vD, TS5 → vE, TS6 → vF, and so on.
   - **Verify by checking the Rill ad_name** — if the ad_name contains a recognizable TS headline fragment, confirm the mapping. If the mapping seems wrong, note the uncertainty.
   - Example: If Jira lists TS4 = "Cesar Millan's Recipe for Dog Longevity", then `vD = "Cesar Millan's Recipe for Dog Longevity"`.
2. **VSL name** — which VSL all variants route to (e.g., "Cesar Solo VSL - no MM").
3. **Team** — producer, editor, assignee from the Jira fields.
4. **Ticket status** — Testing, Editing, Done, etc.
5. **Delivery specs** — 4x5, 16x9, etc.
6. **VSL duration** — estimate from ticket context (description, VSL name) or default to 20 minutes for standard Cesar Solo VSLs. Store as `vsl_duration_minutes` for timestamp computation in the retention waterfall. Other known durations: Fast/Super Cesar VSL = ~12 minutes, Meghan Cut VSL = ~15 minutes.

For STOR/ACT/VTD tickets, Rill already has producer/editor/ticket_status — skip the Jira lookup unless you need TS headlines (which older tickets may not have in Jira).

**Why this matters:** The whole point of the analysis is connecting DATA to CREATIVE DECISIONS. "vD has the highest thruplay retention" is useless. "vD — 'Cesar Millan's Recipe for Dog Longevity' — has the highest thruplay retention, suggesting the longevity/lifespan angle hooks committed viewers better than the curiosity angles in vE and vF" is actionable.

**If the Jira lookup fails**, continue without it — degrade gracefully. Just note "Creative context unavailable — Jira lookup failed."

### Step 2 — Query Rill: Aggregate Totals (all time for this ticket)

Run this query on **both** `fb_campaigns` and `youtube_dashboard`. If one platform returns no results, report that and continue with the other.

**Facebook query:**
```
metrics_view: fb_campaigns
dimensions: [ad_name, account_name, offer, ticket, producer, editor, ticket_status]
measures: [sum_spend, revenue, roi, cac, bcac, cpa, cvr, ctr, cpm, ncr, continuity_opt_in, imp-3sec, three-TP, 25-watched, 50-watched, 75-watched, 100-watched, avg_time_watched, total_customers, total_new_customers]
time_range: { start: "2021-01-01T00:00:00Z", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: ad_name ilike '%[TICKET]%' (for VIDPET tickets: ad_name ILIKE '%VIDPET-XXX%' OR ad_name ILIKE '%VIDEPT-XXX%')
sort: [sum_spend desc]
limit: 250
```

**YouTube query:**
```
metrics_view: youtube_dashboard
dimensions: [ad_name, account_name, offer, ticket, producer, editor, ticket_status]
measures: [spend, revenue, roi, cac, bcac, cpa, cvr, ctr, cpm, ncr, watched_25_rate, watched_50_rate, watched_75_rate, watched_100_rate, average_duration, view_rate, total_customers, total_new_customers]
time_range: { start: "2021-01-01T00:00:00Z", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: ad_name ilike '%[TICKET]%' (for VIDPET tickets: ad_name ILIKE '%VIDPET-XXX%' OR ad_name ILIKE '%VIDEPT-XXX%')
sort: [spend desc]
limit: 250
```

**YouTube does NOT have:** `continuity_opt_in`, `imp-3sec`, `three-TP`, `25-watched`, `50-watched`, `75-watched`, `100-watched`, `avg_time_watched`. Use the YouTube equivalents listed in the measures reference above.

**Metadata dimensions:** The `ticket`, `producer`, `editor`, and `ticket_status` dimensions are populated for legacy tickets (STOR/ACT/VTD) but will be null for VIDPET tickets (known Rill gap). When available, include them in the report header. When null, omit — never show "null".

**Post-filter:** Remove any ad variants with spend = $0 from results before proceeding to scoring. Note in the report: `"Excluded N zero-spend variants."` if any were removed.

**Limit warning:** If result count equals 250, log a warning: `"Query hit limit (250) — some ads may be truncated. Consider narrowing the filter or adding an account override."`

**For single ticket + account override:** Add `AND account_name = '<exact account name>'` to the where clause.

**For multi-ad mode:** Replace the ticket filter with the user's pattern (e.g., `ad_name ilike '%CesarRanks%'`) and use the user-specified time range. **Skip Steps 1.5 (Jira pull), 3.75 (pack-vs-pack), and the "To Go Deeper" asset requests** — these are single-ticket features that don't apply to broad multi-ad queries.

### Step 3 — Query Rill: Daily Trend

Run a daily breakdown for trend analysis. Query both platforms.

**Facebook query:**
```
metrics_view: fb_campaigns
dimensions: [date]
measures: [sum_spend, roi, cac, cvr]
time_range: { start: "<90 days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: ad_name ilike '%[TICKET]%' (for VIDPET tickets: ad_name ILIKE '%VIDPET-XXX%' OR ad_name ILIKE '%VIDEPT-XXX%')
sort: [date asc]
limit: 90
```

**YouTube query:** Same but `metrics_view: youtube_dashboard` and replace `sum_spend` with `spend` in the measures list. Sort remains `[date asc]`.

If the ad has been running less than 90 days, this will return the full run — that's fine.

**Compute spend velocity from daily results:**
1. **Daily avg spend** = total spend across all days / number of days with spend > $0
2. **Last 3-day avg** = sum of last 3 active days (days with spend > $0) / N, where N = min(3, active days). Never divide by 3 if fewer than 3 days have data.
3. **Velocity direction:**
   - `↑` (accelerating) if last-3-day avg > daily avg
   - `↓` (decelerating) if last-3-day avg < daily avg × 0.8
   - `→` (steady) otherwise
4. Include velocity in the Daily Trend section of the report: e.g., `"↑ $850/day avg (accelerating)"`

### Step 3.5 — Comparative Benchmark Query

To give context on how this pack compares to other recent ads on the same account, run a quick benchmark query:

```
metrics_view: fb_campaigns
dimensions: [ad_name]
measures: [sum_spend, roi, cac, cvr, imp-3sec, three-TP]
time_range: { start: "<180 days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: account_name = '<same account>'
having: sum_spend > 500
sort: [roi desc]
limit: 10
```

**Note:** The `having` parameter filters AFTER aggregation — use it for aggregate measures like `sum_spend`. The `where` parameter filters raw rows BEFORE aggregation — use it for dimensions like `account_name`. Never put aggregate measures in `where`.

This gives you the **top 10 performing ads on the same account in the last 6 months** (with meaningful spend). Use this to:
- Frame the current pack's performance: "vD's 221% ROI puts it in the top 3 of all Nature's Blend CM ads in the last 6 months"
- Or provide reality check: "vD's ROI looks strong but the account median is 95% — this pack is performing above average"
- Identify what the best recent ads have in common (retention shape, hook rates) vs. this pack

**If this query fails or returns no data, skip it.** It's context, not core analysis.

### Step 3.75 — Pack-vs-Pack Comparison (single-ticket mode, VIDPET only)

For VIDPET tickets, query other recent packs on the same account to provide stage-appropriate context. This answers: "Is my pack performing well FOR ITS AGE?"

```
metrics_view: fb_campaigns
dimensions: [ad_name]
measures: [sum_spend, roi, cac, cvr]
time_range: { start: "<90 days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: ad_name ILIKE '%VIDPET-%' AND account_name = '<same account>'
having: sum_spend > 50
sort: [sum_spend desc]
limit: 100
```

**Note:** Use `having` (not `where`) for the `sum_spend > 50` filter — it's an aggregate measure.

**Post-process:**
1. Extract ticket number from each ad_name (e.g., "VIDPET-450" from the full name). Group all ad_name rows by ticket number.
2. For each ticket, compute: `total_spend` (sum across variants), `lead_variant_roi` (ROI of highest-spend variant), `variant_count`.
3. Exclude the current ticket from the comparison set.
4. Filter to packs at a comparable spend stage — within 2x of the current pack's total spend. This prevents comparing a $400 pack against a $50K pack.
5. If fewer than 2 comparable packs found, broaden to all VIDPET packs on the account and note the spend difference.

**Use in report:** Include in the "How This Compares" section. Frame the current pack's performance relative to other packs at the same stage.

**If query fails or returns no other VIDPET packs, skip gracefully:** "First VIDPET pack on this account in the last 90 days — no direct comparison available."

### Step 4 — Score Against Benchmarks

For each variant (each `ad_name` row from Step 2):

1. **Resolve the offer name** through alias mapping (see Offer Name Aliases table). Then identify the brand from the account or resolved offer to select the correct benchmark table.
2. **Null offer handling:** If the offer field is null or empty, use $150 as the default CAC benchmark. Show `(unknown offer)` in the report header and note it.
3. **Low-sample-size check:** If `total_new_customers < 10` or `total_customers < 15` for a variant, flag all derived rate metrics (NCR, CVR, continuity) as **directional only** — do NOT assign Green/Yellow/Red flags to rates. State: `"Low sample size (N customers) — treat rates as directional, not diagnostic."` Still score spend-based metrics (ROI, CAC) normally.
4. **Score each metric** against the brand's thresholds:
   - 🟢 Green = at or above target
   - 🟡 Yellow = in the yellow zone
   - 🔴 Red = below red threshold
5. **For brands without hard benchmarks** (Dental Chews, or any brand not in the tables): report the raw numbers and trend direction only. Do not assign Green/Yellow/Red flags. State: "No established benchmarks — reporting trajectory only."
6. **For brands with partial benchmarks** (Mobility Renew, Badlands, Power Foods — only ROI + CAC): score those two metrics, report the rest without flags.

### Step 5 — Diagnose Funnel Shape (Segment-by-Segment)

This is the most important step. Read the retention curve as a **segment-by-segment dropoff map**, not just aggregate numbers.

**5a. Detect creative format from ad_name:**
- If ad_name matches TS at a word boundary (`[_-]TS([_-]|$)`, case-insensitive) → **TS-only format** (thumbstopper straight to VSL, no connector)
- Otherwise → **Ad body format** (has 30-60s connector between hook and VSL)
- Do NOT match "TS" as a substring inside other words (e.g., "Results", "CesarRanks_TS2" DOES match but "CesarRanks_Results" does NOT).
- Note the format in the diagnosis.

**5b. Build the retention waterfall (Facebook):**

**⚠️ DENOMINATOR WARNING:** `imp-3sec` and `three-TP` through `100-watched` use DIFFERENT denominators and CANNOT be compared as a ratio.
- `imp-3sec` = video_view / impressions (denominator: **impressions**)
- `three-TP` through `100-watched` = thruplay or % watched / video_view (denominator: **video_view**)

**Therefore:** Report `imp-3sec` as a **standalone hook rate** — do NOT compute `three-TP / imp-3sec`. Step-to-step ratios only start from `three-TP` onward.

```
imp-3sec (standalone — hook rate, % of impressions that watched 3s)
   ↓ [NO RATIO — different denominators]
three-TP  →  25-watched  →  50-watched  →  75-watched  →  100-watched
Connector     Early VSL      Mid VSL       Product        VSL Close
/ VSL entry                                Reveal
```

Compute step-to-step ratios for the **video_view-denominated** checkpoints only:
- `25-watched / three-TP` = VSL entry retention (are they committing to the long video?)
- `50-watched / 25-watched` = mid-VSL retention (is the story holding?)
- `75-watched / 50-watched` = pre-pitch retention (do they make it to product mention?)
- `100-watched / 75-watched` = close retention (do they finish after hearing the pitch?)

Separately evaluate `imp-3sec` against benchmark (Green ≥ 15%, Yellow 10-15%, Red < 10%). A low imp-3sec is a TS problem regardless of what happens downstream.

**5c. Identify the biggest drop:**

1. First check `imp-3sec` — if below 10%, flag as a **TS problem** before looking downstream.
2. Then among the video_view-denominated ratios (`25/TP`, `50/25`, `75/50`, `100/75`), find the transition with the **lowest ratio** (biggest percentage loss). That's where the creative is failing.
3. Name the specific segment using the Creative Structure table.

**5d. Map to diagnosis pattern:**

Match the drop location to the Funnel Diagnosis Patterns table. Be specific:
- Don't say "hold problem" — say "**connector dropout at 3sec→TP** — viewers aren't making it past the ad body into the VSL. The connector angle may not be bridging effectively."
- Don't say "VSL problem" — say "**pre-pitch dropout at 50%→75%** — viewers are engaged through the mid-VSL but leaving before the product reveal at ~15 min. The case-building section is losing urgency."

**5e. Check CVR relative to 75-watched:**

This is critical. If 75-watched is healthy (viewers ARE reaching the product pitch) but CVR is still low:
- The problem is NOT the creative. It's the **VSL pitch, offer, price, or landing page.**
- State this clearly: "Viewers are reaching the product reveal — the creative is doing its job. Low CVR points to a pitch/offer issue, not a creative issue."

**5f. YouTube equivalent:**

YouTube doesn't have `imp-3sec` or `three-TP`. Use this waterfall instead:
```
view_rate  →  watched_25_rate  →  watched_50_rate  →  watched_75_rate  →  watched_100_rate
   Hook        Early VSL           Mid VSL             Product Reveal      VSL Close
```
Same logic — find the biggest drop, name the segment.

**5g. Final check — NCR + Continuity (FB only):**
- **NCR** — Are conversions coming from new customers? Low NCR (<45%) = audience problem.
- **Continuity** — Are customers opting into subscriptions? Low continuity (<25%) = offer/funnel issue downstream.

**5h. Systemic pattern detection (multi-variant only):**

When analyzing multiple variants of the same ticket or multiple ads in multi-ad mode:
1. For each variant, identify the biggest-drop segment (from 5c).
2. If **≥ 70% of variants** show the same biggest-drop segment (e.g., all drop at TP→25%), flag it as a **systemic issue**: `"⚠️ Systemic pattern: [N] of [total] variants show [segment] dropout — this is a structural issue with the [VSL/connector/TS], not variant-specific."`
3. A systemic issue means variant swaps won't fix it — the underlying creative segment needs rework.
4. If no systemic pattern exists (drops are scattered across different segments), note: "No systemic pattern — variant-specific issues."

**5i. Generate asset request list (REQUIRED when triggered):**

Check these conditions. If ANY fire, you MUST include a "🔍 To Go Deeper" section in the report:

1. **Hook anomaly** — A variant has low 3sec (<40%) but leads in conversion OR high 3sec (>50%) but zero conversions → request **first-frame screenshot** of the anomalous variant(s). Ask: "Is the thumbnail intentionally filtering? What's the opening visual?"
2. **Unexplained retention cliff** — The biggest drop can't be mapped to a known creative moment (e.g., it's not at a known editorial break) → ask **what happens at that VSL timestamp**. Be specific: "What's happening at ~5:00 in the VSL? That's where [X]% of remaining viewers leave."
3. **Variant divergence** — Two variants with similar hook rates (within 5%) have >2x difference in thruplay or CVR → request **creative assets for both** to compare. Ask: "These hooks perform similarly but the downstream numbers diverge — what's different about the visuals or first 10 seconds?"

If NONE of these conditions fire, omit the section entirely.

Output 2–3 sentences explaining:
1. What the retention curve shape tells you (where the biggest drop is)
2. Which specific creative segment is responsible
3. Whether the problem is creative (TS/connector/VSL pacing) or non-creative (pitch/offer/audience)

### Step 6 — Compare Variants

If the aggregate query returned **multiple `ad_name` rows** (variants of the same ticket):

1. Compare each variant on: ROI, CAC, retention (3sec→TP), CVR, and spend.
2. Identify the **clear winner** — best funnel shape overall.
3. Flag any variants **dragging the aggregate down** (significantly worse metrics).
4. Recommend per variant: scale it, pause it, or kill it.

**For split tests:** If the ticket uses split testing (format: ST-XXXXXXX), also query `split_testing_model_metrics`:
```
metrics_view: split_testing_model_metrics
dimensions: [initial_split, initial_funnel_type]
measures: [total_clicks_measure, total_conversions, cvr, revenue, aov, continuity_opt_in, refund_rate]
time_range: { start: "2021-01-01T00:00:00Z", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: initial_split = 'ST-XXXXXXX'
sort: [total_conversions desc]
limit: 50
```
Note: The split test view uses `visit_date` as its time dimension, and `initial_funnel_type` distinguishes Control vs Variant. It does NOT have spend/ROI/CAC — those come from `fb_campaigns`. Use split test data for CVR lift, AOV, and continuity comparisons only.

If only one variant exists, skip this section entirely.

### Step 7 — Deliver Verdict & Output Report

**This is not a data dump. This is a creative brief.** The report should read like a senior media buyer sitting down with the producer/editor and walking them through exactly what's happening, why, and what to do about it. Every number should connect to a creative decision.

**Multi-ad summary mode:** If the query returned **more than 10 ad variants**, do NOT produce individual full reports for each. Instead:
1. Produce a **ranked summary table** sorted by ROI (or spend if ROI is null): top 10 performers, bottom 5 performers, with columns: ad_name | spend | ROI | CAC | CVR | verdict.
2. Below the table, add an **aggregate patterns** section: most common funnel shape issue across all variants, account-level blended metrics, and any systemic patterns (see Step 5h).
3. Then produce a **full individual report** only for the top 3 performers and worst 2 performers. This keeps output manageable.
4. If the user wants a full report on a specific ad from the summary, they can ask: "Analyze [ad_name] on the [account]"

**Null CAC/CVR handling in ranking:** Ads with zero conversions will have null CAC and null CVR. When ranking:
- Sort null-CAC/null-CVR ads to the **bottom** of the table.
- Display "no conversions" instead of blank or zero.
- These ads should receive ⏸️ PAUSE or 🔴 KILL verdicts — never 🟢 SCALE.

Assign one of four verdicts **per variant**. Be decisive — the team needs a call, not a list of possibilities.

**Verdict definitions:**

- **🟢 SCALE** — All core metrics green. ROI at or above target, CAC in range, retention healthy. Recommend increasing spend.
- **🟡 OPTIMIZE** — Good bones but one specific fixable problem identified. **Name the exact creative segment** (TS, connector, early VSL, mid-VSL, pre-pitch, pitch) and what to change. Example: "Connector dropout — cut the ad body from 45s to 25s and go to VSL faster." Do NOT recommend pausing — give the fix first.
- **⏸️ PAUSE** — Mixed signals or insufficient data (< $2,000 spend). Specify what trigger metric to watch and when to recheck.
- **🔴 KILL** — Below floor on ROI + CAC simultaneously with no clear fixable cause. Reallocate budget.

**Output the report in this exact structure:**

```
# Performance Analysis: [TICKET NAME]
**Account:** [Account Name] | **Platform:** Facebook [/ YouTube] | **Status:** [ticket_status]
**Producer:** [name] | **Editor:** [name] | **VSL:** [VSL name from Jira]
**Spend:** $[total] across [N] variants | **Date range:** [range]
**Data:** [open_url link]

---

## 📋 The Pack at a Glance

[If Jira context available, list each variant with its TS headline:]

| Variant | Thumb Stopper Headline | Spend | ROI | CAC | Verdict |
|---|---|---|---|---|---|
| vD | "Cesar Millan's Recipe for Dog Longevity" | $159 | 221% 🟢 | $79 🟢 | ⏸️ PAUSE — early but promising |
| vE | "Your Dog Is Trying to Tell You Something" | $93 | — | — | ⏸️ testing |
| ... | ... | ... | ... | ... | ... |

[If Jira context NOT available, use variant letters only — still show the table]
[If zero-spend variants excluded: "Excluded N zero-spend variants."]
[If low sample size: "⚠️ Low sample size — only N customers. All rates are directional, not diagnostic."]

---

## ✅ What's Working

[2-4 bullet points. Be specific. Connect data to creative decisions. Examples:]
- "**vD's hook is selecting for committed viewers.** Lowest 3sec rate (37.9%) but highest thruplay carry-through (68.5%) — the 'Recipe for Dog Longevity' headline filters out casual scrollers and pulls in people who actually want to watch. That's exactly what you want for a 20-minute VSL."
- "**The VSL is converting when people reach it.** 221% ROI on vD with only $159 spend. CAC at $79 is well below the $130-145 target range — early signal but strong."
- "**Multiple variants hooking above 49%.** vE (53.8%), vA (50.0%), vB (49.5%) — the pack has broad hook strength."

[Every bullet must reference a specific metric AND explain WHY it matters for the creative. No orphaned numbers.]

**REQUIRED: Hook angle analysis.** For each variant with Jira TS headline data, classify the headline by angle type (see Hook Angle Types table). Explain performance differences through hook psychology — don't just say "vD has higher thruplay," say WHY: "vD's curiosity hook ('Your Dog Is Trying to Tell You Something') self-selects committed viewers — lower 3sec (38%) but higher thruplay (26%). vE's shock hook (caps-lock 'WATCH WHAT...') grabs more eyeballs (54%) but fewer commit past the TS. This is the classic quality-vs-quantity hook tradeoff — for a 20-minute VSL, you want quality."

---

## ❌ What's Not Working

[2-4 bullet points. Be specific about WHERE the problem is and WHAT creative segment causes it.]
- "**Massive TP→25% cliff across all variants.** vD drops from 25.9% thruplay to 4.3% at the 25% mark. vE is worse: 24% → 1.7%. This is the VSL handoff — viewers commit past the hook but bail in the first few minutes of the long-form content. This is a systemic VSL issue, not variant-specific."
- "**6 of 7 variants have zero conversions.** Only vD has converted. The pack is too early to judge most variants — but the universal TP→25% cliff suggests even scaled spend won't fix the downstream."

[Name the creative segment. Name the pattern from the diagnosis table. Don't just say "retention is low" — say WHERE it breaks and what that means for the edit.]

---

## 🔬 Retention Deep Dive

**Creative format:** [TS-only / Ad body — detected from ad_name]
**VSL:** [name from Jira] (~[X] minutes)

**Lead variant ([vX] — "[TS headline]"):**

| Checkpoint | Rate | ~Timestamp | Segment | Drop | |
|---|---|---|---|---|---|
| imp→3sec | [X]% | 0-3s | Thumbstopper | — | [🟢/🟡/🔴] |
| three-TP | [X]% | 3-15s | Connector/VSL entry | — | |
| TP→25% | [X]% | ~[computed] | Early VSL (problem-agitation) | **-[X]%** | ⚠️ biggest cliff |
| 25→50% | [X]% | ~[computed] | Mid VSL (case-building) | -[X]% | |
| 50→75% | [X]% | ~[computed] | Product reveal zone | -[X]% | |
| 75→100% | [X]% | ~[computed] | VSL close/CTA | -[X]% | |

[Compute timestamps: percentage × vsl_duration_minutes. For 20-min VSL: 25%=5:00, 50%=10:00, 75%=15:00, 100%=20:00]

[If systemic pattern: "⚠️ Systemic: [N/total] variants show the same cliff at [segment]. This is a structural issue with the [VSL/connector], not the thumb stoppers."]

**YouTube variant (if YouTube data exists):** Use the same table structure but substitute YouTube measure names:
- `view_rate` instead of `imp→3sec` (standalone hook rate)
- `watched_25_rate` → `watched_50_rate` → `watched_75_rate` → `watched_100_rate` for the waterfall
- No `three-TP` equivalent — start step-to-step ratios from `watched_25_rate`
- Present as a separate table under "**YouTube Retention:**" — never blend FB and YT in the same table.

**⏱️ Editor question:** "What's happening in the VSL at ~[timestamp of biggest cliff]? That's where [X]% of remaining viewers leave across [all/most] variants. [If Nature's Blend CM account: Check if there's an editorial B-roll section here where Cesar stops talking — that's the most common cause of retention drops in this account.]"

**What the curve tells you:**
[2-3 sentences connecting the retention shape to specific creative moments at specific timestamps. Don't say "25% watched drops" — say "At the ~5:00 mark (the problem-agitation section), viewers are leaving. This is typically where the VSL transitions from hook to story — if there's a pacing lull or editorial cutaway here, that's your fix." Always reference the actual timestamp, not just the percentage.]

---

## 📊 How This Compares

**Account benchmarks** (from Step 3.5 — top 10 ads on same account, last 6 months):
- "The top performers on this account average [X]% ROI and $[X] CAC. vD's [X]% ROI would rank [#X] if it holds at scale."
- "Best-performing ads have TP→25% ratios of [X-Y]%. This pack's [X]% is [above/below/in line]."

**Pack-vs-Pack** (from Step 3.75 — other VIDPET packs at similar spend stage):
- "VIDPET-[XXX] at ~$[similar] spend: lead variant had [X]% ROI — yours is tracking [above/below/similarly]"
- "VIDPET-[YYY] at ~$[similar] spend: [X]% ROI on lead variant"
- "Account average for packs under $[threshold] total: ~[X]% ROI — vD's [X]% is [well above / in line / below]"

[If no comparable packs: "First VIDPET pack on this account in the last 90 days — no direct comparison available."]
[If either sub-section's query failed or returned no data, skip that sub-section gracefully — don't leave blanks or show errors.]

---

## 🎯 Where to Go from Here

[Numbered action items. Written in producer/editor language — these are things the user can actually DO in their next edit session or in Ads Manager.]

1. **Let vD run to $500-1K before making any calls.** 221% ROI at $159 is a strong early signal but the sample is tiny (likely 1-2 conversions). It needs 5-10x more spend to confirm.
2. **Watch vE closely — it could overtake vD.** Higher hook rate (53.8% vs 37.9%) with decent thruplay. If it starts converting, the combo of broad hook + conversions could beat vD's efficiency at scale.
3. **Investigate the TP→25% cliff.** This is the #1 issue across the entire pack. Pull up the VSL timeline — what happens in the first 3-5 minutes after the hook? If there's an editorial/B-roll section without Cesar, that's your likely culprit. Consider: [specific editing suggestion based on the pattern].
4. **Don't kill any variants yet.** Everything under $50 spend is noise. Let the pack run to $1K+ total before cutting.

### 📊 Budget Allocation

Based on current performance and spend velocity ($[last-3-day avg from Step 3]/day across all variants):

| Variant | Allocation | Daily Target | Rationale |
|---|---|---|---|
| [best performer] | 50-60% | ~$[computed]/day | Clear winner — needs scale confirmation |
| [strong signal] | 20-25% | ~$[computed]/day | Strong hook or retention, watching for conversions |
| [promising] | 10-15% | ~$[computed]/day | Best [metric], needs spend to test |
| [early/low spend] | Min (~$5/day each) | ~$5/day | Too early to cut |
| [duplicates/dead] | PAUSE | $0 | [reason — duplicate, splitting budget, etc.] |

[Compute: variant_daily = allocation_pct × total_daily_budget. Total daily budget = last-3-day average spend velocity from Step 3.]

### 📍 Milestone Checkpoints

| Milestone | Est. Date | What to Watch | Decision Trigger |
|---|---|---|---|
| **$500 total** | ~[computed] | Does lead variant maintain ROI? Any other converters? | If yes → confirm SCALE on lead |
| **$1,000 total** | ~[computed] | Secondary variant conversion data, 3sec→TP stability | If 2+ variants converting → healthy pack |
| **$2,000 total** | ~[computed] | Enough data for confident scoring. **Re-run full analysis.** | Graduate from "early testing" caveats |
| **$5,000 total** | ~[computed] | First reliable NCR/continuity read | If pack ROI holds → graduate from Testing status |

[Compute est. dates: `days_to_milestone = (threshold - current_total_spend) / daily_avg_spend`. Add to today's date. If current spend already exceeds a milestone, mark it "✅ passed" and note what the data showed at that point.]

### 🔍 To Go Deeper (share these if available)

[REQUIRED if Step 5i triggered ANY condition. Otherwise omit this section.]

[Numbered list. Each item names the specific variant, the specific asset needed, and why:]
1. **[Variant]'s first frame** — [Observation that can't be explained by data alone]. "[Specific question]"
2. **VSL at ~[timestamp]** — [What the data shows at this point]. "[Question about what's happening in the edit at this moment]"
3. **[Variant A] vs [Variant B] creative comparison** — [Data shows divergence]. "[What to look for in the assets]"

[This section turns the analysis into a conversation. The goal is to get the producer/editor to share assets so the NEXT analysis run can go deeper.]

---

## Verdict: [per variant]

| Variant | Verdict | One-line reason |
|---|---|---|
| vD | ⏸️ PAUSE — promising, needs spend | 221% ROI early signal — let it run to $1K |
| vE | ⏸️ PAUSE — testing | Highest hook rate, no conversions yet |
| vB | ⏸️ PAUSE — testing | Good hook, needs spend |
| ... | ... | ... |

**Pack-level verdict:** [SCALE / OPTIMIZE / PAUSE / KILL] — [one sentence summary]

---
*Analyzed by GPB Ad Performance Analyzer · Powered by Rill + Claude*
*[If Jira context was used: "Creative context pulled from VIDPET-XXX"]*
```

### Role-Specific Report Adjustments

The report structure above is the **Producer** (default) view. When a role flag is specified, adjust the output as follows. **Steps 1-6 (data gathering, scoring, diagnosis) are IDENTICAL for all roles** — only the report output changes.

#### `--editor` adjustments:
- **Retention Deep Dive becomes the PRIMARY section** — move it to the top, expand it.
- **Add a "✂️ Edit Points" section** after Retention Deep Dive:
  ```
  ## ✂️ Edit Points
  Based on the retention curve, here are specific edit recommendations:
  1. **~[timestamp]: [Segment]** — [X]% of viewers leave here. [What's likely happening]. 
     Recommendation: [Specific edit action — e.g., "Cut B-roll at 4:30, keep Cesar on camera through 5:15"]
  2. **~[timestamp]: [Segment]** — [description + edit action]
  [Each edit point references the EXACT timestamp, not a percentage]
  ```
- **Pacing analysis** — If the VSL has an identifiable pacing lull (e.g., 50%→75% drop is steeper than 25%→50%), note: "The VSL loses momentum between ~[X]:00 and ~[Y]:00. Consider tightening this section by [X] seconds."
- **De-emphasize:** Hook angle psychology, budget allocation, milestones (editors don't control these). Keep them as a brief "Context" section at the bottom if present.
- **Tone:** Speak in editor language — "cut at", "trim", "tighten", "keep talent on screen", "B-roll section", "pacing", "duration".

#### `--offer-manager` adjustments:
- **Lead with unit economics** — CAC, blended CAC (bcac), NCR, continuity opt-in, CPA. These are the primary scorecard.
- **Add "💰 Offer Health" section** as the PRIMARY section:
  ```
  ## 💰 Offer Health
  **CAC:** $[X] [🟢/🟡/🔴] (target: $130-145) | **Blended CAC:** $[X]
  **NCR:** [X]% [🟢/🟡/🔴] — [X] of [Y] customers are new
  **Continuity:** [X]% [🟢/🟡/🔴] — subscription opt-in rate
  **CPA:** $[X] | **CVR:** [X]%
  
  **Diagnosis:** [Is this a creative problem or an offer/funnel problem?]
  - If 75-watched is healthy but CVR is low → "Creative is delivering viewers to the pitch. Low conversion is an offer/funnel issue — check landing page, pricing, or offer structure."
  - If NCR is low → "Conversions are coming from existing customers. Check audience exclusion lists and targeting."
  - If continuity is low → "Customers are buying but not subscribing. This is a checkout flow or offer packaging issue."
  ```
- **Split test data** — If available, give this section MORE prominence. Show control vs. variant CVR lift, AOV comparison, continuity comparison.
- **De-emphasize:** TS headline analysis, retention waterfall details, edit points. Summarize creative performance in 1-2 lines: "Creative is [working/not working] — [one sentence on why]."
- **Tone:** Speak in offer manager language — "unit economics", "CAC efficiency", "NCR quality", "funnel health", "offer-level", "blended".

#### `--media-buyer` adjustments:
- **Lead with spend efficiency** — ROI, CAC, CPM, CTR, spend velocity.
- **Budget Allocation becomes the PRIMARY section** — move to top, expand with more detail:
  ```
  ## 📊 Budget & Scaling Plan
  **Current velocity:** $[X]/day ([↑/→/↓])
  **Recommended daily budget:** $[X] (up from $[current] — [X]% increase)
  
  | Variant | Current $/day | Recommended $/day | Action | Trigger to Re-evaluate |
  |---|---|---|---|---|
  | vD | $[X] | $[X] | SCALE — increase 50% | If ROI drops below 107% at $1K spend |
  | vE | $[X] | $[X] | HOLD — monitor | If no conversion by $200, pause |
  | ... | ... | ... | ... | ... |
  
  **Scaling thresholds:**
  - At $[X] daily → monitor CPM for audience saturation (CPM increasing >15% week-over-week = fatigue signal)
  - At $[X] daily → check frequency cap and audience overlap
  ```
- **Milestone Checkpoints get MORE detail** — add CPM/frequency milestones alongside spend milestones.
- **Add "📈 Fatigue Signals"** section: compare week-1 vs. current CPM, CTR trend, ROI trend. Flag if metrics are declining.
- **De-emphasize:** TS headline psychology, VSL timestamp details, edit points. Summarize creative quality in 1-2 lines.
- **Tone:** Speak in media buyer language — "scale", "budget", "CPM efficiency", "audience saturation", "frequency", "pacing", "day-over-day".

**Report philosophy — READ THIS:**
- **Every number must connect to a creative decision.** Don't say "ROI is 221%." Say "vD's 'Recipe for Dog Longevity' angle is converting at 221% ROI — the longevity framing is working."
- **Name the thumb stopper headline when discussing variants.** "vD" means nothing. "vD — 'Cesar Millan's Recipe for Dog Longevity'" tells the producer exactly which creative angle is winning.
- **Diagnosis is about WHERE, not WHAT.** Don't say "retention is low." Say "viewers leave at the 5-minute mark, which is the problem-agitation section of the VSL."
- **Recommendations are editing actions.** Not "improve retention" but "cut the B-roll section at 4:30 and keep Cesar on screen through the problem-agitation segment."
- **Ask for what you need.** If the data shows a pattern you can't fully explain without seeing the creative, ASK. "Can you share vD's first frame?" or "What happens in the VSL at the 5-minute mark?" — this turns the analysis into a conversation, not a one-shot report.
- **Use visual formatting.** Tables, bold callouts, emoji section headers, clear separation between sections. This should be scannable — a producer should be able to glance at it and know the verdict in 5 seconds, then read deeper.

**Report field notes:**
- **Producer/Editor/Status:** Pull from Jira first (Step 1.5), fall back to Rill dimensions. If null everywhere, show "—" — never print "null".
- **Zero-spend note:** Only show if variants were actually excluded.
- **Low-sample-size warning:** Only show if `total_new_customers < 10` or `total_customers < 15`.

### Step 8 — Slack Report (only if `--slack` flag)

If the user included `--slack` in their prompt:

1. Format the report for Slack markdown (replace `#` headers with `*bold*`, use code blocks for tables).
2. **Resolve recipient:** If `--slack @Name` was specified, look up that person's Slack ID using `slack_search_users`. If just `--slack` with no name, default to Carter Dawson (`U044BSXELMC`).
3. Send via `slack_send_message` to the resolved Slack user ID as a DM.
4. Confirm: `"Report sent to [Name] on Slack."`

If `--slack` is NOT present, skip this step. Console output only.

## Important Rules

- **"Analyze" = Rill first, Jira second.** When the user says "Analyze [TICKET]", your FIRST action is querying Rill via `query_metrics_view`. Jira enrichment (Step 1.5) comes after. If you find yourself reading a Jira ticket without having queried Rill yet, stop and start over.
- **Never display `initial_st_variant` or `initial_st_control`** — these are internal Salesforce system fields.
- **The `ticket` dimension in Rill is unreliable** — always filter by `ad_name ilike '%TICKET%'`.
- **All Rill queries require a `time_range` parameter** — never omit it.
- **Facebook uses `sum_spend`; YouTube uses `spend`** — never mix them up.
- **Always cite the `open_url` from the Rill query response** in the report so the team can drill into the data themselves. Every `query_metrics_view` response includes an `open_url` field — use it.
- **CTR is context, not a verdict driver.** CTR is queried but has no hard benchmark — it varies by audience, placement, and creative format. Use it as supplementary context (e.g., "CTR is low despite good hook rate — the ad is stopping thumbs but not driving link clicks") but don't score it Green/Yellow/Red.
- **Be decisive.** The team needs a call, not a list of possibilities. Pick a verdict and commit to it.
- **For split tests**, use `split_testing_model_metrics` view with `initial_split` dimension (format: ST-XXXXXXX).
- **If a metric is null** (e.g., no conversions), report it as "—" or "no data", not zero. Note it in the diagnosis.
- **If both platforms return data**, report them separately with separate scorecards and verdicts. Do not blend FB and YT metrics.
- **If one platform returns no data**, state it clearly (e.g., "No YouTube data found for this ticket") and proceed with the platform that has data.
- **Time zone:** Always use `America/Los_Angeles` for all Rill queries.
- **Offer name aliases:** Resolve before any lookup (see Offer Name Aliases table above).
- **Graceful failures:** If a Rill query fails or times out, log the error and continue with available data. If the FB query succeeds but YT fails, report FB-only results — don't abort the entire analysis. If both platforms fail, tell the user: `"Rill queries failed — check connectivity and try again."` Never crash on a single failed query.

## Usage Examples

> "Analyze VIDPET-381"
(Producer report — default)

> "Analyze VIDPET-458 --editor"
(Editor report — timestamp-heavy, edit points)

> "Analyze VIDPET-458 --offer-manager"
(Offer manager report — CAC, NCR, continuity, funnel health)

> "Analyze VIDPET-458 --media-buyer"
(Media buyer report — budget allocation, scaling plan, fatigue signals)

> "Analyze STOR-3169 on the Nature's Blend CM account"

> "Pull performance for all CesarRanks ads on the CM account last 90 days"

> "Analyze VIDPET-450 --slack"

> "Analyze VIDPET-458 --editor --slack @Jordonna Grace"
