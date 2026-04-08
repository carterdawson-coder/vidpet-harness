# GPB Ad Performance Analyzer

When the user says **"Analyze [TICKET]"**, **"Analyze [TICKET] on the [Account] account"**, or **"Pull performance for all [pattern] ads on the [Account] account last [N] days"**, follow this procedure exactly. Use the Rill MCP tools (`query_metrics_view`). Optionally use Slack MCP (`slack_send_message`) if `--slack` flag is present.

## Run Modes

- **Single ticket**: `"Analyze VIDPET-381"` — pulls all-time data for that ticket, scores, diagnoses, delivers verdict.
- **Single ticket + account override**: `"Analyze STOR-3169 on the Nature's Blend CM account"` — bypasses auto-detection, uses the specified account.
- **Multi-ad**: `"Pull performance for all CesarRanks ads on the CM account last 90 days"` — broader filter, scores each ad individually.
- **`--slack` flag**: Appending `--slack` to any mode also sends the final report as a Slack DM to the requesting user (Carter Dawson, `U044BSXELMC`).

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

### Funnel Diagnosis Patterns

Read the retention curve as a **segment-by-segment dropoff map.** Each drop tells you which creative segment to fix.

| Pattern | Where the Drop Is | Signals | Root Cause | Fix |
|---|---|---|---|---|
| **TS problem** | imp→3sec | Low imp→3sec (<15%) | Thumbstopper not stopping | New hook visual, first-frame change |
| **Connector problem** | 3sec→TP or 3sec→25% | Good 3sec, big drop before 25-watched | Ad body / connector loses them before VSL kicks in | Tighten connector, cut to VSL faster, or test TS-only format |
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

1. **Thumb stopper headlines** — from the description's "Creative Versions" section. Map each variant letter (vA, vB, vC...) to its TS headline. Example: `vD = "Cesar Millan's Recipe for Dog Longevity"`, `vE = "Cesar Millan: Your Dog Is Trying to Tell You Something"`.
2. **VSL name** — which VSL all variants route to (e.g., "Cesar Solo VSL - no MM").
3. **Team** — producer, editor, assignee from the Jira fields.
4. **Ticket status** — Testing, Editing, Done, etc.
5. **Delivery specs** — 4x5, 16x9, etc.

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

**For multi-ad mode:** Replace the ticket filter with the user's pattern (e.g., `ad_name ilike '%CesarRanks%'`) and use the user-specified time range.

### Step 3 — Query Rill: Daily Trend

Run a daily breakdown for trend analysis. Query both platforms.

**Facebook query:**
```
metrics_view: fb_campaigns
dimensions: [date]
measures: [sum_spend, roi, cac, cvr]
time_range: { start: "<90 days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: ad_name ilike '%[TICKET]%'
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
time_range: { start: "<180 days ago>", end: "<tomorrow>" }
time_zone: "America/Los_Angeles"
where: account_name = '<same account>' AND sum_spend > 500
sort: [roi desc]
limit: 10
```

This gives you the **top 10 performing ads on the same account in the last 6 months** (with meaningful spend). Use this to:
- Frame the current pack's performance: "vD's 221% ROI puts it in the top 3 of all Nature's Blend CM ads in the last 6 months"
- Or provide reality check: "vD's ROI looks strong but the account median is 95% — this pack is performing above average"
- Identify what the best recent ads have in common (retention shape, hook rates) vs. this pack

**If this query fails or returns no data, skip it.** It's context, not core analysis.

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

| Checkpoint | Rate | Segment | Drop | |
|---|---|---|---|---|
| imp→3sec | [X]% | Thumbstopper | — | [🟢/🟡/🔴 or "standalone"] |
| three-TP | [X]% | Connector/VSL entry | — | |
| TP→25% | [X]% | Early VSL | **[X]% drop** | ⚠️ biggest cliff |
| 25→50% | [X]% | Mid VSL | [X]% drop | |
| 50→75% | [X]% | Product reveal | [X]% drop | |
| 75→100% | [X]% | VSL close | [X]% drop | |

[If systemic pattern: "⚠️ Systemic: [N/total] variants show the same cliff at [segment]. This is a structural issue with the [VSL/connector], not the thumb stoppers."]

**What the curve tells you:**
[2-3 sentences connecting the retention shape to specific creative moments. Example:]
"Viewers are hooked by the TS and commit through the connector — but they're bailing in the first 5 minutes of the VSL. At the ~5 min mark on a 20-minute VSL, that's typically the problem-agitation section. If there's an editorial segment here (B-roll without Cesar talking), that's likely where they leave. The fix is keeping Cesar on screen through this section."

---

## 📊 How This Compares

[Use data from Step 3.5 comparative benchmark query:]
- "**Account context:** The top 10 CM account ads in the last 6 months average [X]% ROI and $[X] CAC. vD's 221% ROI would rank [#X] if it holds at scale."
- "**Retention context:** The best-performing ads on this account have TP→25% ratios of [X-Y]%. This pack's [X]% is [above/below/in line with] that range."
- "**Pack-stage context:** At $369 total spend, this pack is in early testing. Typical packs don't stabilize until $2K-5K total spend."

[If benchmark query failed or returned no data, skip this section.]

---

## 🎯 Where to Go from Here

[Numbered action items. Written in producer/editor language — these are things the user can actually DO in their next edit session or in Ads Manager.]

1. **Let vD run to $500-1K before making any calls.** 221% ROI at $159 is a strong early signal but the sample is tiny (likely 1-2 conversions). It needs 5-10x more spend to confirm.
2. **Watch vE closely — it could overtake vD.** Higher hook rate (53.8% vs 37.9%) with decent thruplay. If it starts converting, the combo of broad hook + conversions could beat vD's efficiency at scale.
3. **Investigate the TP→25% cliff.** This is the #1 issue across the entire pack. Pull up the VSL timeline — what happens in the first 3-5 minutes after the hook? If there's an editorial/B-roll section without Cesar, that's your likely culprit. Consider: [specific editing suggestion based on the pattern].
4. **Don't kill any variants yet.** Everything under $50 spend is noise. Let the pack run to $1K+ total before cutting.

[If the analysis can't fully explain a pattern, ASK for more context:]
"**To go deeper:** Can you share a screenshot of vD's first frame? The low 3sec rate + high thruplay is unusual — I want to see if the visual is intentionally filtering (bold text hook) or if the thumbnail just isn't compelling and the viewers who DO click are self-selected committed."

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
2. Send via `slack_send_message` to `U044BSXELMC` (Carter Dawson) as a DM.
3. Confirm: `"Report sent to Slack."`

If `--slack` is NOT present, skip this step. Console output only.

## Important Rules

- **Never display `initial_st_variant` or `initial_st_control`** — these are internal Salesforce system fields.
- **The `ticket` dimension in Rill is unreliable** — always filter by `ad_name ilike '%TICKET%'`.
- **All Rill queries require a `time_range` parameter** — never omit it.
- **Facebook uses `sum_spend`; YouTube uses `spend`** — never mix them up.
- **Always cite the `open_url` from the Rill query response** in the report so the team can drill into the data themselves. Every `query_metrics_view` response includes an `open_url` field — use it.
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

> "Analyze STOR-3169 on the Nature's Blend CM account"

> "Pull performance for all CesarRanks ads on the CM account last 90 days"

> "Analyze VIDPET-450 --slack"
