# TS Intelligence — Top Thumb Stoppers by Offer

When the user says **"Run TS analysis"**, **"Run TS analysis for [offer]"**, or **"Run TS analysis last [N] days"**, follow this procedure exactly. Use the Rill MCP tools (`query_metrics_view`) and Jira MCP tools (`getJiraIssue`). Optionally use Slack MCP (`slack_send_message`) if `--slack` flag is present.

**What this harness does:** Surfaces the top-performing Thumb Stoppers across one or all pet offer accounts, ranks them using a composite TS Score, classifies hook angles from Jira headlines, checks creative rule compliance, and delivers per-offer creative briefs with actionable next-TS recommendations.

**What this harness is NOT:** This is not a single-ticket deep dive. For full funnel diagnosis of a specific ticket, use `gpb_ad_performance_analyzer.md` ("Analyze [TICKET]").

## Run Modes

- **All offers (default):** `"Run TS analysis"` — queries all 9 pet offer accounts, last 90 days.
- **Single offer:** `"Run TS analysis for [offer]"` — one account, last 90 days.
- **Custom time range:** `"Run TS analysis last [N] days"` or `"Run TS analysis --all-time"`.
- **`--slack` flag:** Appending `--slack` sends the report as a Slack DM. Default recipient: Carter Dawson (`U044BSXELMC`). To DM someone else: `--slack @Name`.

## Constants

### Shared Constants (DO NOT DUPLICATE)

The following constants are authoritative in `gpb_ad_performance_analyzer.md`. Reference them — do not copy:

- **Brand-to-Account Lookup Table** — 9 pet offer accounts with exact Rill `account_name` values
- **Account Shorthand Aliases** — "CM account", "Nutra account", etc.
- **Rill Configuration** — `fb_campaigns` (Facebook), `youtube_dashboard` (YouTube)
- **Rill Measure Names** — exact measure names for each platform
- **Offer Name Aliases** — resolve before any lookup (Natures Blend → Nature's Blend, etc.)
- **Rill Dashboard Links** — open_url base URLs

### TS Score Composite Model

A weighted composite that balances five factors. Weights are tuned for pet supplement VSL advertising where the goal is getting a **committed viewer** into a 20-minute video, not just grabbing eyeballs.

| Factor | Weight | Metric (FB) | Metric (YT) | Rationale |
|---|---|---|---|---|
| Hook Rate | 20% | `imp-3sec` | `view_rate` | Important but overvalued in isolation. High hook rate with low carry-through is a vanity metric for long-form VSLs. |
| Carry-Through | 25% | `25-watched / three-TP` (capped at 1.0) | `watched_25_rate` (absolute rate) | Most predictive metric for VSL success. A TS that gets viewers INTO the VSL is worth more than one that just stops thumbs. |
| Conversion Efficiency | 25% | `cvr` | `cvr` | The ultimate measure — did the TS-initiated funnel produce buyers? |
| ROI Contribution | 20% | `roi` | `roi` | Revenue efficiency. A TS that converts at high CVR but low AOV may still underperform. |
| Platform Confidence | 10% | `log10(sum_spend) / log10(50000)`, capped at 1.0 | `log10(spend) / log10(50000)`, capped at 1.0 | Facebook/YouTube algorithms allocate budget to winners. High spend = platform trusts this creative. Log scale prevents mega-spenders from dominating. |

**Scoring rules:**
- **Minimum spend threshold:** $200 total spend to be scored. TSs below this appear in results but are labeled **"Insufficient Data"** and excluded from scoring, angle averages, and pattern analysis.
- **Normalization:** Each factor is min-max normalized to 0–100 **within the offer's TS set**. The best TS on a given offer always scores near 100.
- **Scores are relative within an offer, NOT comparable across offers.** An 87 on CM and a 65 on Nutra does NOT mean the CM TS is better — it means it's more dominant within its offer's competitive set. State this in every report.
- **Null handling:** If CVR or ROI is null (zero conversions), those factors score 0. The TS can still score on hook rate, carry-through, and spend.
- **Carry-through null handling:** If `three-TP` is 0 or null, carry-through scores 0 and is flagged: "Zero thruplay — no viewers committing past the hook."

### Hook Angle Classification Rules

Auto-classify from Jira TS headlines. Applied in priority order — if a headline matches multiple angles, the **first match** is primary, subsequent matches are noted as secondary.

**Priority order:** Curiosity > Shock > Authority > Fear > Listicle > UGC

| Angle | Headline Patterns (case-insensitive) | Psychology |
|---|---|---|
| **Curiosity/Emotional** | Question mark present; contains "trying to tell", "something", "secret", "hidden", "what if", "did you know", "the truth about", "no one tells you" | Creates an open loop only closable by watching. Lower hook (35-45%) but dramatically higher carry-through. Ideal for 20-min VSLs. |
| **Shock/Urgency** | 2+ consecutive ALL CAPS words; contains "WATCH"; 2+ exclamation marks; "immediately", "right now", "just a few" | Exploits the brain's orienting response. 50%+ hook but shallow commitment — viewers stopped from surprise, not an open question. Many bounce when surprise wears off. |
| **Authority** | Celebrity name (Cesar, Millan, Katherine, Heigl, Dr. Marty) + directive verb (says, wants, recommends, reveals, warns, tells) | Leverages existing trust in a recognized figure. Mid-range hook (40-50%) because it depends on recognition. Solid carry-through because celebrity credibility sustains attention. |
| **Fear/Loss** | Contains "watch out", "warning", "danger", "before it's too late", "stop doing", "never do", "mistake", "killing", "destroying" | Activates the brain's threat-detection system (stronger than reward system). High hook (45-55%), variable carry-through — works if fear converts to genuine concern about the viewer's dog, fails if it feels manipulative. |
| **Listicle/Recipe** | Number + noun pattern ("3 signs", "5 foods", "7 reasons"); contains "recipe", "list", "steps", "ingredients", "formula for" | Activates the info-seeking drive. Self-selects information-seekers who are more likely to watch a long video. Higher carry-through because they came for the promised information. |
| **UGC/Social Proof** | Contains "I tried", "my dog", "my vet said", "real owner", "testimonial", "customer story", "you won't believe what happened" | Breaks the "produced content" pattern with authentic-feeling footage. Highly variable — depends entirely on execution quality. |

**If no patterns match:** Mark as **"Unclassified"**. This is fine — not every headline fits neatly.

**Hybrid angles:** If 2+ patterns match, classify by the FIRST in priority order as primary. Note the secondary: e.g., "Fear + Authority" for "Watch Out! Cesar Millan Wants You to Hear This" (primary: Fear because "Watch Out" matches first in scan order of the headline, secondary: Authority because Cesar Millan + "Wants" matches).

### Three Cardinal Rules of Pet Supplement Thumb Stoppers

These rules are checked against **every TS headline**. Violations are flagged in the report **regardless of performance** — even a high-scoring TS that violates a rule gets flagged, because the violation indicates it would perform even better without it.

#### Rule 1: NEVER Mention Kibble

**The rule:** The word "kibble" (case-insensitive) must not appear in a TS headline.

**Why:** "Kibble" instantly frames the ad as a pet food commercial. The viewer's brain categorizes it as "someone selling me dog food" — a commodity purchase they already have a brand for. The VSL is selling a premium supplement, not food. The first 3 seconds must NOT trigger the "pet food ad" schema. The VSL spends 15+ minutes building the case for WHY this is different from regular food — the TS must not undermine that by framing it as food from the start.

**Detection:** Scan headline for `kibble` (case-insensitive, whole word or substring).

**Flag text:** `"⚠️ RULE VIOLATION: Mentions 'kibble' — frames the product as a pet food alternative rather than a premium supplement. The VSL spends 15+ minutes building the case for why this is different. The TS is undermining that in the first 3 seconds."`

#### Rule 2: NEVER Allude to Selling a Product

**The rule:** The TS must not hint that a product pitch is coming.

**Why:** The entire VSL model works because the content feels like information, not advertising, for the first 15+ minutes. The product isn't even mentioned until the ~75% mark. If the TS signals "this is an ad selling something," the viewer's ad-detection instinct fires and they scroll. The TS must feel like the start of content they WANT to watch — a story, a revelation, a warning — not an ad they're being sold.

**Detection:** Scan headline for: "product", "supplement", "buy", "order", "try this", "new formula", "get yours", "on sale", "discount", "limited time", "available now".

**Flag text:** `"⚠️ RULE VIOLATION: Alludes to selling a product — this triggers the viewer's ad-detection instinct. The VSL's power is that it feels like content, not an ad, for 15+ minutes. The TS must protect that framing."`

#### Rule 3: NEVER Reveal the VSL Topic

**The rule:** The TS must not tell the viewer what they're about to watch.

**Why:** The curiosity gap is the engine that drives viewthrough. If the TS says "Learn about the best dog supplement for joint health," the viewer has two options: (1) they're not interested and scroll, or (2) they already know enough and scroll. Either way, the information asymmetry that makes them NEED to watch is gone. The best TSs create tension: "something is wrong / something important / something surprising" — and the ONLY way to resolve that tension is to keep watching.

**Detection:** Scan headline for: "dog food", "dog supplement", "pet nutrition", "superfood", "the best [food/supplement/nutrition]", "learn about", "find out about [product category]", "introducing".

**Flag text:** `"⚠️ RULE VIOLATION: Reveals the VSL topic — this closes the curiosity gap before the viewer enters the VSL. The TS should create tension that can ONLY be resolved by watching, not summarize what the video is about."`

### Hook Psychology Knowledge Base

Claude uses this knowledge base when generating per-offer insights and creative brief recommendations. This is the WHY behind the data patterns.

#### Curiosity Gap Theory

The most powerful TS mechanism for long-form VSLs. Creates an open loop in the viewer's mind that can only be closed by watching. "Your dog is trying to tell you something" — what? The viewer must watch to find out.

**Expected performance shape:** Lower hook rate (35-45%) because the headline doesn't promise instant gratification — it filters out casual scrollers. But dramatically higher carry-through because the viewers who DO stop are psychologically committed to resolving the gap. For a 20-minute VSL, this is the ideal funnel shape: fewer but better viewers.

**When it works best:** When the curiosity is emotionally specific to the viewer's dog. "Something" is weaker than "trying to tell you something" because the second version implies the viewer is MISSING a signal from their own pet.

**When it fails:** When the curiosity is too vague ("Did you know this?") or when it's been overused and viewers recognize the pattern.

#### Pattern Interrupt (Shock/Urgency)

Exploits the brain's orienting response to unexpected stimuli — ALL CAPS, exclamation marks, sudden visual energy.

**Expected performance shape:** Very high hook rate (50%+) because the pattern interrupt overrides the scroll reflex. But shallow commitment — the viewer stopped because of surprise, not because they have an open question. Many bounce once the surprise wears off (~3-15 seconds). The TP→25% ratio is typically worse than curiosity hooks.

**When it works:** When paired with an ad body connector that can convert the interrupt into genuine curiosity. But since TS-format ads go straight to VSL (no connector), shock hooks are generally LESS effective in the TS-only format.

**The quality-vs-quantity tradeoff:** Shock hooks optimize for VOLUME (more eyeballs). Curiosity hooks optimize for QUALITY (more committed viewers). For a 20-minute VSL where you need viewers to stay for 15+ minutes before the product pitch, quality almost always wins.

#### Authority Transfer

Leverages existing trust in a recognized figure. "Cesar Millan says do this" — the viewer's pre-existing relationship with Cesar provides instant credibility.

**Expected performance shape:** Mid-range hook rate (40-50%) because it depends on celebrity recognition (only works if the viewer knows the celebrity). Solid carry-through because the celebrity's credibility sustains attention — "if Cesar says it's important, I'll listen."

**Per-offer variation:** Authority hooks perform differently per offer based on the celebrity association:
- **Dr. Marty / Nature's Blend:** Cesar Millan is the anchor. Authority hooks are typically the strongest angle.
- **Badlands Ranch:** Katherine Heigl is the anchor. Authority works but the celebrity-to-product association is weaker.
- **Nutra Complete / Mobility Renew:** No celebrity anchor. Authority hooks are weaker — there's no recognized face to leverage.

#### Loss Aversion (Fear)

Activates the brain's threat-detection system, which is neurologically stronger than the reward system. "Watch out" or "warning" creates urgency.

**Expected performance shape:** High hook rate (45-55%) because threat signals are hard to ignore — the brain is wired to prioritize danger over scrolling. Variable carry-through: if the fear converts into genuine concern about the viewer's own dog, it sustains attention through the VSL. If it feels manipulative or the "threat" is just clickbait, viewers bounce with negative sentiment.

**Risk:** Fear hooks can attract viewers who are anxious but not buying-ready. High engagement, lower conversion. Use sparingly.

#### Information Promise (Listicle/Recipe)

Activates the brain's information-seeking drive. "5 foods killing your dog" or "Cesar's recipe for dog longevity" promises specific, actionable knowledge.

**Expected performance shape:** Mid hook rate (40-50%) — attracts information-seekers specifically. Higher carry-through because they came for the promised information, and the VSL delivers that information (slowly, over 20 minutes). Works especially well for health-conscious pet owners who actively seek nutrition guidance.

**Synergy with authority:** Listicle + Authority ("Cesar Millan's 3 Signs...") is often the strongest hybrid because it combines the info promise with the credibility anchor.

#### Social Proof (UGC)

Breaks the "produced content" pattern with authentic-feeling footage. A real dog owner's testimonial or reaction.

**Expected performance shape:** Highly variable. High-quality UGC can outperform polished hooks because it triggers "someone like me" identification. Low-quality UGC confuses viewers who don't understand what they're watching. No reliable baseline performance.

**Format note:** UGC hooks often look visually different from the VSL that follows (handheld vs. produced), which can create a jarring transition. This makes the TS→VSL carry-through less predictable.

#### The Hook-to-VSL Alignment Principle

**The most important principle for TS selection:** The TS must set the right EXPECTATION for 20 minutes of content.

A shock hook that promises "WATCH THIS AMAZING THING" sets up an expectation of short, payoff-driven content. When the viewer instead gets a 20-minute educational VSL with a celebrity vet, there is a **frame mismatch**. This is why shock hooks often show high 3sec but low 25-watched: the viewers who stopped for a "quick payoff" leave when they realize it's long-form content.

The best TSs set the right frame:
- **Curiosity:** "This is going to be a journey of discovery" → aligns with a 20-min educational VSL
- **Authority:** "A trusted expert is going to teach you something" → aligns with a Cesar-led VSL
- **Listicle:** "There's specific information here worth learning" → aligns with an informational VSL
- **Shock:** "Something amazing/urgent is happening RIGHT NOW" → misaligns with 20 min of slow-build content

**This is why carry-through is weighted higher (25%) than hook rate (20%) in the TS Score.** A TS that sets the right frame for the VSL is worth more than one that just stops thumbs.

## Procedure

### Step 1 — Parse Input & Determine Scope

1. Extract offer name if provided. Resolve aliases per the Offer Name Aliases table (in `gpb_ad_performance_analyzer.md`).
2. Extract time range. Default: 90 days. Options: `last [N] days`, `--all-time` (uses `2021-01-01` to today).
3. **Determine scope:**
   - No offer specified → query all 9 accounts.
   - Offer specified → resolve to account(s). **Some offers map to multiple accounts:**
     - "Nature's Blend" → 3 accounts: CM, Marty, Quiz. Query ALL 3 and report each separately in its own Per-Offer Breakdown section.
     - All other offers → 1 account each.
   - If the user says a specific account alias ("CM account", "Quiz account"), query ONLY that account even if the offer has multiple.
4. If `--slack` flag present, note Slack recipient (default: Carter Dawson `U044BSXELMC`). If `--slack @Name`, resolve via `slack_search_users`.

**Account iteration order** (when querying all 9):
1. Dr. Marty - Nature's Blend - CM
2. Dr Marty - Nature's Blend (Created May21)
3. Dr. Marty - Nature's Blend - Quiz
4. Dr. Marty - Nature's Feast
5. Dr. Marty - Dental Chews
6. Nutra Complete - 2024
7. UPN - Mobility Renew
8. Badlands Ranch by Katherine Heigl - Superfood Complete
9. Lone Wolf Ranch - Power Foods Complete - Quiz

### Step 2 — Query Rill: TS Performance Data

For each account in scope, query **both** `fb_campaigns` and `youtube_dashboard`.

**Facebook query:**
```
metrics_view: fb_campaigns
dimensions: [ad_name, account_name, offer]
measures: [sum_spend, revenue, roi, cac, cvr, imp-3sec, three-TP, 25-watched, 50-watched, 75-watched, 100-watched, total_customers, total_new_customers, ncr, continuity_opt_in]
time_range: { start: "<N days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: account_name = '<exact account name>' AND ad_name ILIKE '%TS%' AND (ad_name ILIKE '%VIDPET%' OR ad_name ILIKE '%VIDEPT%')
having: sum_spend > 0
sort: [sum_spend desc]
limit: 500
```

**YouTube query:**
```
metrics_view: youtube_dashboard
dimensions: [ad_name, account_name, offer]
measures: [spend, revenue, roi, cac, cvr, view_rate, watched_25_rate, watched_50_rate, watched_75_rate, watched_100_rate, total_customers, total_new_customers, ncr]
time_range: { start: "<N days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: account_name = '<exact account name>' AND ad_name ILIKE '%TS%' AND (ad_name ILIKE '%VIDPET%' OR ad_name ILIKE '%VIDEPT%')
having: spend > 0
sort: [spend desc]
limit: 500
```

**⚠️ Why the `where` clause pre-filters:** Without `ad_name ILIKE '%TS%'`, the query returns the top 500 ads by spend on the account — which on a mature account like CM could be ALL legacy STOR/ACT ads with zero VIDPET TS results. The pre-filter ensures the 500-row limit is spent on relevant ads. The `ILIKE '%TS%'` is intentionally broad (will catch "Results", "TStest", etc.) — the post-filter below applies the precise regex.

**Post-filter (apply to results after the Rill query):**

Keep only rows where `ad_name` contains a TS token — meaning "TS" appears as a **creative format marker**, not as a substring inside an unrelated word.

**TS detection regex (case-insensitive):** Match if ANY of these patterns exist in ad_name:
1. `[_-]TS([_-]|$)` — classic separator-bounded: `_TS_`, `-TS-`, `_TS` at end
2. `[_-]TS\d` — TS followed by a number: `_TS2`, `-TS1`, `_TS12`
3. `TS[_-]` — TS at start of a token: `TS_Pack`, `TS-Set`
4. `[a-z]TS([_-]|$)` — TS at end of a word (camelCase naming): `HoneyTS_`, `MagicTS-`, `BlueberriesTS` at end
5. `TSPack|TSSet|TSThumbs` — known compound TS naming patterns

**Explicit exclusion list (case-insensitive):** Discard rows where "TS" only appears inside these words: `Results`, `Tests`, `Contests`, `Osts`, `Bests`, `Lists`, `Costs`, `Highlights`, `Assets`, `Adjustments`. Apply exclusions BEFORE the inclusion regex — if the only "TS" match in the ad_name is inside an excluded word, discard the row.

**In practice:** Run the inclusion regex on ad_name. If it matches at least one TS token that isn't inside an excluded word, keep the row. This catches real-world naming conventions (DelaneyHoneyTS, MagicTS, TSPack2, TSSet_6, BlueberriesTS) while still filtering out false positives.

**Duplicate removal:** If two ad_names differ only by a trailing " - Copy", "- Copy", or "Copy" suffix, keep the higher-spend original and flag the copy: `"Duplicate detected: [copy name] — excluded from analysis."`

**VIDPET typo handling:** When checking for VIDPET in ad_name, always match both `VIDPET` and `VIDEPT` (transposed letters). If a result uses the VIDEPT spelling, note it but normalize to VIDPET in the report.

**Limit warning:** If either query returns exactly 500 rows, warn: `"Query hit 500-row limit — some TSs may be missing. Consider narrowing to a single offer."` This is unlikely with the pre-filter but possible on very active accounts.

**Account-level baseline query (per account):**
```
metrics_view: fb_campaigns
measures: [three-TP, 25-watched, 50-watched, 75-watched, 100-watched, sum_spend]
time_range: { start: "<180 days ago 00:00:00Z>", end: "<tomorrow 00:00:00Z>" }
time_zone: "America/Los_Angeles"
where: account_name = '<exact account name>'
having: sum_spend > 500
```
No dimensions — returns a single aggregated row. Compute baseline step-to-step ratios:
- `baseline_TP_25` = 25-watched / three-TP
- `baseline_25_50` = 50-watched / 25-watched
- `baseline_50_75` = 75-watched / 50-watched
- `baseline_75_100` = 100-watched / 75-watched

Use these to contextualize each TS's retention in the report.

**Zero-result handling:** If an account returns zero VIDPET TS ads after filtering, note: `"No VIDPET TS data found for [offer] in the last [N] days."` and skip to the next account. Do NOT error out.

**Progress notes (all-offer mode):** Print progress as you go: `"Querying Nature's Blend CM... [N] TSs found. Querying Marty account..."` so the user knows the harness is working.

### Step 3 — Enrich with Jira TS Headlines

For each unique VIDPET ticket number found in the Rill results:

1. Extract ticket number from ad_name using regex: `VID[EP]{2}T-?(\d+)` (catches both VIDPET and VIDEPT spellings, with or without hyphen).
2. Group all ad_name rows by ticket number.
3. Sort tickets by total spend (sum across all their variants) descending.
4. **Cap at top 10 tickets per offer** to limit Jira API calls. If more than 10 tickets exist for an offer, note: `"Showing top 10 tickets by spend. [N] additional tickets excluded."`
5. For each ticket, call `getJiraIssue` with `issueIdOrKey: "VIDPET-[number]"` and `cloudId: "972e7666-58b6-4e89-87f4-6c0f672f67bd"`.
6. From the Jira response, extract TS headlines from the description's "Creative Versions" section.
7. Map positionally: TS1→vA, TS2→vB, TS3→vC, TS4→vD, TS5→vE, TS6→vF, and so on.
8. Match each Rill ad_name's variant letter back to its TS headline using this regex on the ad_name:
   `[_-]v([A-Z])[_\-.]` or `[_-]v([A-Z])$` (case-insensitive)
   This captures the single letter after "v" from patterns like `_vD-`, `_vD_`, `-vA-`, `_vB.`, or `_vC` at end of string.
   Map the letter: A→TS1, B→TS2, C→TS3, D→TS4, E→TS5, F→TS6, etc.
   If no variant letter is found, note: `"Variant letter not detected in ad_name — headline mapping unavailable."` The TS is still scored on metrics, just without headline context.

**Also extract from Jira:**
- VSL name (which VSL all variants route to)
- Producer, Editor, Creative Director from custom fields
- Ticket status

**Graceful degradation:** If `getJiraIssue` fails for a ticket (404, timeout, rate limit), skip it and note: `"Jira unavailable for VIDPET-[XXX] — headline and angle classification omitted."` Continue with remaining tickets. Never abort the entire analysis because one Jira call failed.

### Step 4 — Classify Hook Angles

For each TS that has a Jira headline from Step 3:

1. Scan the headline against the Hook Angle Classification Rules table, checking patterns **in priority order**: Curiosity > Shock > Authority > Fear > Listicle > UGC.
2. The **first match** is the primary angle.
3. Continue scanning — any additional matches are secondary angles.
4. If no patterns match: mark as **"Unclassified"**.
5. Record: `{ primary_angle, secondary_angle (or null), headline, confidence: "High" }`

For TSs without Jira headlines (Jira lookup failed): mark as **"Unclassified"**, confidence: **"N/A — no headline available"**.

### Step 5 — Check Cardinal Rules

For each TS with a known headline, check against all three cardinal rules:

**Rule 1 — Kibble check:** Scan for `kibble` (case-insensitive).

**Rule 2 — Product allusion check:** Scan for (case-insensitive): `product`, `supplement`, `buy`, `order`, `try this`, `new formula`, `get yours`, `on sale`, `discount`, `limited time`, `available now`.

**Rule 3 — Topic reveal check:** Scan for (case-insensitive): `dog food`, `dog supplement`, `pet nutrition`, `superfood`, `the best food`, `the best supplement`, `learn about`, `find out about`, `introducing`.

For each violation found, store the rule number and the matched phrase. These appear in the report's "Cardinal Rule Violations" section for that offer, regardless of the TS's performance score.

### Step 6 — Compute TS Scores

For each offer that has qualifying TSs:

1. **Filter:** Only TSs with total spend ≥ $200 are scored. TSs below $200 are listed at the bottom as "Insufficient Data — needs more spend."

2. **Compute raw values** for each of the 5 factors:
   - **Hook Rate:** `imp-3sec` (FB) or `view_rate` (YT). If null, = 0.
   - **Carry-Through (FB):** `25-watched / three-TP`. If `three-TP` is 0 or null, carry-through = 0. **Sanity cap:** if the ratio exceeds 1.0, cap at 1.0 (this can happen due to Rill aggregation artifacts across time windows). Values > 1.0 are meaningless — they indicate a data quirk, not 100%+ retention.
   - **Carry-Through (YT):** Use `watched_25_rate` as an absolute rate (0-100%). Do NOT divide by `view_rate` — YouTube's `view_rate` (% of impressions → view) and `watched_25_rate` (% that watched to 25%) are not on the same denominator chain, making the ratio unreliable. Instead, use `watched_25_rate` directly and normalize it like all other factors.
   - **CVR:** `cvr`. If null (zero conversions), CVR = 0.
   - **ROI:** `roi`. If null, ROI = 0. **Floor:** if ROI is below -100%, floor at -100%. This prevents extreme negative outliers (e.g., -500% ROI on a $200-spend TS with zero revenue) from distorting normalization for the entire offer. A TS at -100% and one at -500% are both failures — the difference between them shouldn't dominate the scoring.
   - **Platform Confidence:** `min(1.0, log10(spend) / log10(50000))`. For spend = $200 this yields ~0.46. For spend = $50K this yields 1.0.

3. **Normalize:** For each factor, apply min-max normalization within the offer's TS set:
   `normalized = (value - min) / (max - min) × 100`
   If all values are identical (max = min), all normalize to 50.
   
   **Note on negative values:** Min-max normalization handles negatives correctly (e.g., ROI range of -100% to +200% normalizes -100% → 0, +200% → 100). The ROI floor ensures the range isn't dominated by extreme outliers.

4. **Weight and sum:**
   `TS_Score = (Hook × 0.20) + (CarryThrough × 0.25) + (CVR × 0.25) + (ROI × 0.20) + (Confidence × 0.10)`

5. **Rank** TSs within the offer by TS Score descending.

6. **If only 1 qualifying TS exists for an offer:** Score it at 50 (normalization baseline) and note: "Only 1 qualifying TS — score is a baseline, not comparative."

**Facebook vs. YouTube:** If a TS has data on both platforms, compute separate scores and report both. Do NOT blend platforms. Label clearly: "FB Score: 87 | YT Score: 72".

### Step 7 — Detect Per-Offer Patterns

For each offer with 3+ scored TSs, compute:

1. **Angle distribution:** Count of TSs per angle type. Average TS Score per angle type. Only include angles with 2+ TSs in the average (1 TS is anecdotal). **Sample size warnings:**
   - 2-3 TSs in an angle: include in table but append `(low n)` to the verdict. Example: `"Top performer (low n — only 2 TSs)"`
   - 4-9 TSs: report normally.
   - 10+ TSs: high confidence — note `(strong signal)`.

2. **Winning angle:** The angle type with the highest average TS Score (minimum 2 TSs to qualify). **Prefer angles with more TSs when scores are close** — if two angles are within 5 score points, the one with more data wins the tiebreak. If no angle has 2+ TSs, state: "No dominant angle — too few TSs per angle for pattern detection."

3. **Hook rate vs. carry-through relationship:** For each TS, note its hook rate and carry-through. Does this offer show the expected inverse relationship (high hook = low carry-through, per the Shock vs. Curiosity theory)? Or are there TSs that break the pattern (high hook AND high carry-through)?

4. **Temporal patterns:** Bucket TSs by the **ticket number** as a proxy for recency — higher VIDPET numbers are newer tickets. (Rill's aggregate query doesn't return a date per ad.) Group TSs:
   - **Recent:** top third of ticket numbers
   - **Mid:** middle third
   - **Older:** bottom third
   
   Compare average TS Score per bucket. Are newer tickets' TSs outperforming older ones? This is a rough proxy — if you need precise date-based trend analysis on a specific TS, use `"Analyze [TICKET]"` which queries daily data.

5. **Headline de-duplication for angle analysis:** Before computing angle averages, check if any TS headline appears on multiple tickets (common — proven headlines get recycled across packs). If the same headline (case-insensitive, ignoring minor punctuation differences) appears on 2+ tickets:
   - In the **Top Thumb Stoppers table:** show each instance separately (they have different spend/ROI).
   - In the **Angle Performance Map:** count the headline as ONE data point using the **highest-spend instance's metrics**. This prevents a recycled headline from inflating its angle's average. Note in the table: `"[Angle] count includes [N] de-duplicated headlines."`
   - In the **Creative Brief:** note which headlines are being recycled: `"'[Headline]' appears on [N] tickets — it's a proven hook being reused."`

6. **Top performer profile:** For the #1 ranked TS, describe its complete profile: angle, hook rate, carry-through, CVR, ROI, and what makes it work using the Hook Psychology Knowledge Base.

### Step 8 — Cross-Offer Insights (all-offer mode only)

When analyzing all 9 offers, compute:

1. **Winning angle per offer:** Create a summary table showing which angle wins on each offer. Look for patterns:
   - Do celebrity-anchored offers (CM, Marty, Badlands) favor Authority?
   - Do non-celebrity offers (Nutra, Mobility) favor Curiosity or Listicle?

2. **Universal vs. offer-specific patterns:** Are any angles universally strong or weak across all offers? Are certain angles offer-specific?

3. **Offer creative strength ranking:** Rank the 9 offers by their top TS Score. Which offers have the strongest creative? Which need new TS angles urgently?

4. **Cross-offer rule violations:** How many total cardinal rule violations across all offers? Which rule is violated most often?

### Step 9 — Deliver Report

**This is a creative brief, not a data dump.** Every number must connect to a creative decision. Every insight must be actionable.

**Output the report in this structure:**

```
# TS Intelligence Report
**Scope:** [All pet offers / Single offer name] | **Period:** Last [N] days
**Data as of:** [today's date] | **TSs analyzed:** [N] across [N] offers ([N] accounts)
**Scoring note:** TS Scores are relative within each offer (0-100). They are NOT comparable across offers.
**Data:** [open_url links from Rill queries]

---

## Executive Summary

[3-5 bullet points. The most important findings. Written for a creative director deciding what to make next.]

Examples:
- "Authority hooks (Cesar-led) dominate Nature's Blend CM with a 78 avg TS Score vs. 52 for curiosity hooks — Cesar's face is the strongest thumb stopper on this account."
- "Across all offers, curiosity hooks have 23% higher carry-through than shock hooks — confirming that quality > quantity for 20-minute VSLs."
- "Nutra Complete has no TS above a 55 TS Score in the last 90 days — this offer needs fresh creative angles."
- "2 cardinal rule violations found: VIDPET-XXX mentions kibble, VIDPET-YYY alludes to a product."

---

## Per-Offer Breakdown

### [Offer Name] ([Account Name])
**TSs analyzed:** [N] | **Winning angle:** [Angle] (avg score: [X]) | **Top TS Score:** [X]
**Account baseline TP→25%:** [X]% (context for retention interpretation)

#### Top Thumb Stoppers

| Rank | Score | Ticket | Variant | Headline | Angle | Hook | Carry-Through | CVR | ROI | Spend |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 87 | VIDPET-381 | vD | "Cesar's Recipe for Dog Longevity" | Listicle | 42% | 68% | 1.8% | 185% | $12.4K |
| 2 | 79 | VIDPET-458 | vA | "Your Dog Is Trying to Tell You Something" | Curiosity | 38% | 71% | 1.5% | 165% | $8.2K |
| 3 | 65 | VIDPET-450 | vC | "Cesar Millan Says, Do This" | Authority | 45% | 55% | 1.2% | 140% | $5.1K |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

[Show all scored TSs. TSs with < $200 spend listed at bottom as "Insufficient Data".]

#### Angle Performance Map

| Angle | Count | Avg Score | Avg Hook | Avg Carry-Through | Avg CVR | Verdict |
|---|---|---|---|---|---|---|
| Listicle | 4 | 78 | 41% | 65% | 1.6% | Top performer — info-seeking hooks pull committed viewers |
| Authority | 8 | 72 | 46% | 58% | 1.4% | Reliable workhorse — Cesar's face stops scrolls |
| Curiosity | 6 | 65 | 36% | 70% | 1.3% | Highest carry-through but lowest hook — quality play |
| Shock | 3 | 42 | 54% | 33% | 0.7% | Vanity metric — grabs eyeballs, doesn't convert for long-form |

[Only show angles with 2+ TSs. Angles with 1 TS: note in text, not table.]

#### Offer Insights

[2-3 paragraphs grounded in the data AND the Hook Psychology Knowledge Base. Explain WHY the winning angle works for this specific offer. Reference the celebrity anchor (or lack of one), the VSL type, and the audience.]

Example:
"Nature's Blend CM's TS performance is anchored by Cesar Millan recognition. Authority hooks dominate (avg score 72) because Cesar's face triggers instant credibility for pet owners — they stop not because of curiosity or shock, but because a trusted expert is speaking. However, Listicle hooks are quietly outperforming (avg score 78) by combining information promise with authority transfer: 'Cesar's Recipe for Dog Longevity' activates both the info-seeking drive AND the Cesar credibility. This hybrid is the sweet spot for this account."

"Shock hooks underperform dramatically on this account (avg score 42 vs. 72 for Authority). The CM audience expects educational content from Cesar, not clickbait energy. A 'WATCH THIS!' hook sets up the wrong expectation for a 20-minute VSL — viewers who stopped for a quick payoff leave when they realize it's long-form. The hook-to-VSL alignment principle explains this perfectly."

#### Cardinal Rule Violations

[Only show if violations were found for this offer. Otherwise omit this section.]

| Ticket | Variant | Headline | Violation | Impact |
|---|---|---|---|---|
| VIDPET-XXX | vB | "The Best Kibble Alternative" | Rule 1: mentions kibble | Frames as food ad, undermines supplement positioning |

[Include the full flag text from the Cardinal Rules section + a recommendation.]

#### 🎯 Creative Brief: What to Make Next

[3-5 specific, data-grounded TS concepts for this offer. Each one references the angle performance data and psychology.]

1. "**Test Listicle + Authority hybrid:** 'Cesar Millan's 3 Signs Your Dog Needs This' — Listicle is your top angle (78 avg) and hybridizing with Cesar's authority (your second-best at 72) combines the info-seeking drive with the credibility anchor."
2. "**Double down on curiosity hooks that are emotionally specific:** 'Your Dog Is Trying to Tell You Something' outperforms generic curiosity ('Did You Know?') by 15 score points. The emotional specificity — implying the viewer is missing a signal from THEIR dog — is the key."
3. "**Retire shock angles on this account.** The data is clear: shock hooks average 42 vs. 72 for authority. The 20-minute VSL format punishes shock hooks because the frame mismatch causes early dropout."
4. "**Test a Fear + Authority hybrid:** 'Watch Out — Cesar Millan Warns About This Common Mistake' — Fear hooks have high hook rate (55%) and combining with Cesar's authority could sustain carry-through better than standalone fear."

[Every recommendation must reference specific data from this offer's analysis.]

---

[REPEAT the entire Per-Offer Breakdown section for each offer in scope]

---

## Cross-Offer Patterns (all-offer mode only)

### Angle Leaderboard

| Angle | Best Offer (Avg Score) | Worst Offer (Avg Score) | Universal Insight |
|---|---|---|---|
| Authority | CM (72) | Nutra (34) | Works where celebrity is recognized; fails without celebrity anchor |
| Curiosity | Nutra (65) | Dental (40) | Best default angle when no celebrity; requires emotional specificity |
| Listicle | CM (78) | — | Underused across most offers; highest carry-through when used |
| Shock | — | CM (42) | Consistently underperforms for 20-min VSLs; avoid for long-form |

### Format Insight

All TSs in this analysis are TS-only format (straight to VSL, no connector). Performance comparison with ad body formats is outside this harness's scope — use the analyzer for that.

### Universal Rules Confirmed by Data

[Bullet points connecting the cardinal rules + psychology to actual data patterns across all offers.]

- "Curiosity hooks average [X]% higher carry-through than shock hooks across all offers — confirming that self-selected viewers outperform attention-grabbed viewers for long-form VSLs."
- "Authority hooks are the most reliable angle on celebrity-anchored accounts but underperform on non-celebrity accounts — the hook-to-VSL alignment principle explains this: celebrity recognition provides the sustained attention that long-form requires."
- "[N] cardinal rule violations found across [N] offers. Rule [X] is the most common violation."

### Offers Needing Creative Attention

[List any offers where the top TS Score is below 55 or where no dominant angle exists — these offers need new creative angles urgently.]

---
*Analyzed by TS Intelligence Harness · Powered by Rill + Claude*
*Creative context pulled from [N] VIDPET tickets via Jira*
```

### Step 10 — Slack Report (only if `--slack` flag)

If the user included `--slack` in their prompt:

1. Format the report for Slack markdown (replace `#` headers with `*bold*`, use code blocks for tables).
2. **Resolve recipient:** If `--slack @Name` was specified, look up that person's Slack ID using `slack_search_users`. If just `--slack` with no name, default to Carter Dawson (`U044BSXELMC`).
3. Send via `slack_send_message` to the resolved Slack user ID as a DM.
4. Confirm: `"Report sent to [Name] on Slack."`

If `--slack` is NOT present, skip this step. Console output only.

## Important Rules

- **All Rill queries require a `time_range` parameter** — never omit it.
- **All Rill queries use `time_zone: "America/Los_Angeles"`** — always include it.
- **Facebook uses `sum_spend`; YouTube uses `spend`** — never mix them up.
- **Always cite the `open_url` from Rill query responses** so the team can drill into the data themselves.
- **TS detection uses a multi-pattern regex** (see Step 2 Post-filter). Catches `_TS_`, `_TS2`, `HoneyTS`, `TSPack`, etc. Excludes "TS" inside words like "Results", "Tests", "Contests". "CesarRanks_Results" does NOT match. "DelaneyHoneyTS" DOES match.
- **VIDPET tickets only.** Filter for `VIDPET-` or `VIDEPT-` in ad_name. Skip all STOR/ACT/VTD ads.
- **VIDPET typo handling:** Always search for both `VIDPET` and `VIDEPT` spellings.
- **Minimum $200 spend to score.** Below = "Insufficient Data", excluded from angle averages and pattern analysis.
- **TS Scores are relative within an offer.** NEVER compare scores across offers. State this in the report header.
- **Carry-through uses `25-watched / three-TP`, NOT `three-TP / imp-3sec`.** The `imp-3sec` and `three-TP` metrics have different denominators (impressions vs. video_view) and CANNOT be compared as a ratio.
- **Resolve offer name aliases before any lookup** — see the Offer Name Aliases table in the analyzer.
- **Graceful failures:** If a Rill query fails or times out, log the error and continue with available data. If Jira fails for a ticket, skip and note it. Never abort the entire analysis because one query or lookup failed.
- **Cap Jira calls at 10 tickets per offer.** If an offer has more than 10 VIDPET tickets in the results, only enrich the top 10 by spend.
- **Creative Brief recommendations must be data-grounded.** Never recommend "try curiosity hooks" without referencing the offer's actual angle performance data. Every recommendation must point to a specific data pattern.
- **Be decisive in the Creative Brief.** The team needs specific TS concepts to test, not vague suggestions. "Test a Listicle + Authority hybrid: 'Cesar's 3 Signs Your Dog Needs This'" is good. "Consider trying different angles" is useless.
- **For brands without established benchmarks** (Dental Chews, or any new brand): score and rank normally (the composite model is relative, not absolute), but note: "Benchmarks not yet established — scoring is relative to other TSs on this account only."
