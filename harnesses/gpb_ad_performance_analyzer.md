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

### Funnel Diagnosis Patterns

| Pattern | Signals | Root Cause | Recommended Fix |
|---|---|---|---|
| **Hook problem** | Low imp→3sec (<15%), spend inefficiency | Thumb stopper not stopping | New hook / visual |
| **Hold problem** | Good 3sec, drop at thruplay (<30% 3sec→TP) | Ad body loses attention, pacing break | Cut the drag section, tighten cadence |
| **VSL problem** | Good thruplay, low CVR (<1%) | Hook delivered, VSL not converting | VSL audit, not creative |
| **Audience problem** | Good CVR, low NCR (<45%) | Converting existing customers, not new | Audience targeting or exclusion issue |
| **Fatigue** | Good early metrics, declining ROI/CVR trend | Creative exhausted | Rotate new variants |
| **Scaling signal** | All metrics green + upward trend | Working — needs fuel | Increase budget |

**Nature's Blend CM account note:** A hold problem in this account traces most commonly to a **cadence break** — any section where Cesar stops talking and shifts to editorial (e.g., the 0:12–0:18 fresh food pouches section in STOR-3169). Always check if a retention drop maps to a known editorial section before diagnosing as a hook issue.

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

### Step 5 — Diagnose Funnel Shape

Read the shape of the funnel data, not just the numbers. Walk through the metrics in order:

**Facebook funnel (use these measures):**
1. **imp→3sec (`imp-3sec`)** — Is the hook catching attention?
2. **3sec→TP (`three-TP`)** — Is the ad holding through the thruplay?
3. **CVR** — Are viewers converting?
4. **NCR** — Are conversions coming from new customers?
5. **Continuity (`continuity_opt_in`)** — Are customers opting in to subscriptions?

**YouTube funnel (use these measures instead):**
1. **View rate (`view_rate`)** — Is the hook catching attention? (equivalent to imp→3sec)
2. **Retention curve (`watched_25_rate` → `watched_50_rate` → `watched_75_rate` → `watched_100_rate`)** — Is the ad holding?
3. **CVR** — Are viewers converting?
4. **NCR** — Are conversions coming from new customers?
5. Continuity is not available on YouTube — skip this metric.

Match the pattern of Green/Yellow/Red flags to one of the 6 diagnostic categories from the Funnel Diagnosis Patterns table.

**If on the Nature's Blend CM account:** Check for cadence break patterns before diagnosing hold problems. Note this in the diagnosis.

Output 2–3 sentences explaining what the funnel shape is telling you, then name the specific pattern and root cause.

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

Assign one of four verdicts **per variant**. Be decisive — the team needs a call, not a list of possibilities.

**Verdict definitions:**

- **🟢 SCALE** — All core metrics green. ROI at or above target, CAC in range, retention healthy. Recommend increasing spend.
- **🟡 OPTIMIZE** — Good bones but one specific fixable problem identified. State exactly what to fix and what outcome to expect. Do NOT recommend pausing — give the fix first.
- **⏸️ PAUSE** — Mixed signals or insufficient data (< $2,000 spend). Specify what trigger metric to watch and when to recheck.
- **🔴 KILL** — Below floor on ROI + CAC simultaneously with no clear fixable cause. Reallocate budget.

**Output the report in this exact structure:**

```
# Performance Analysis: [TICKET NAME]
**Account:** [Account Name]
**Platform:** [Facebook / YouTube / Both]
**Date Range:** [Range of data pulled]
**Total Spend:** $[X]
**Producer:** [name from Rill or "—"] | **Editor:** [name or "—"] | **Status:** [ticket_status or "—"]
**Data Source:** [open_url from Rill query response — this is a direct link to the filtered data]
[If zero-spend variants were excluded: "Excluded N zero-spend variants."]

---

## Aggregate Performance
[Table: variant | spend | ROI | CAC | CVR | 3sec→TP (FB) or view_rate (YT) | NCR | continuity (FB only)]
[🟢/🟡/🔴 flag per metric where benchmarks exist]
[If low sample size: "⚠️ Low sample size (N customers) — rates are directional only."]

## Funnel Diagnosis
[2–3 sentences on what the funnel shape is telling you]
[Name the specific pattern from the diagnosis table]

## Variant Comparison
[If multiple variants — clear winner identified, per-variant recommendation]
[If single variant — "Single variant — no comparison needed."]

## Daily Trend
[1–2 sentences on trajectory — improving, declining, stable, fatiguing]
[Spend velocity: "↑ $X/day avg (accelerating)" or "→ $X/day avg (steady)" or "↓ $X/day avg (decelerating)"]

## Verdict
[🟢 SCALE / 🟡 OPTIMIZE / ⏸️ PAUSE / 🔴 KILL]
[One specific action to take]
[Expected outcome if action is taken]

---
*Analyzed by GPB Ad Performance Analyzer · Powered by Rill + Claude*
```

**Report field notes:**
- **Producer/Editor/Status:** Populated from Rill `producer`, `editor`, `ticket_status` dimensions. These are available for legacy tickets (STOR/ACT/VTD) but null for VIDPET tickets. If null, show "—" — never print "null".
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
