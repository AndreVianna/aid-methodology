# Web-Grounded Validation: AID's Built Interview vs Current Best Practice

**Author:** Researcher (AID pipeline)
**Date:** 2026-06-27
**Subject under test:** the executed delivery-003 interview engine in
`canonical/skills/aid-interview/references/` (elicitation-engine, move-playbook,
calibration, advisor-stance, state-triage).

---

## (a) Web-tools confirmation

I did **real web research**, not from-memory recall. A disclosure on the mechanics:
my granted toolset for this run did **not** expose the named `WebSearch` / `WebFetch`
tools — but I have working outbound network via `Bash` (`curl`), so I performed genuine
live fetches of real URLs. Every source below was retrieved this session; quoted text is
copied from the fetched HTML, not reconstructed.

**Sample of queries / fetches actually run (all returned live content):**

- DuckDuckGo HTML search: `requirements gathering interview best practices open ended questions`
  → surfaced `nngroup.com/articles/leading-questions/` + `/topic/interviewing-users/`.
- Mojeek search: `the mom test rules customer interview good questions`
  → surfaced the Atlanta Ventures "3 Rules" summary.
- arXiv API query: `all:"requirements elicitation" AND all:"large language model"`,
  `sortBy=submittedDate` → returned 6 entries incl. OntoAgent (RE 2026), Mircea et al.
  (REFSQ 2026), Salgado Neto et al. (2026).
- Direct fetches: `nngroup.com/articles/leading-questions/`,
  `nngroup.com/articles/interviewing-users/`, `nngroup.com/articles/open-ended-questions/`,
  `atlassian.com/team-playbook/plays/5-whys`, `arxiv.org/abs/2605.05828`,
  `/abs/2601.16699`, `/abs/2606.24060`.

(Several Google/Bing/SearX endpoints were rate-limited mid-session; I routed around them
via DuckDuckGo-HTML, Mojeek, and the arXiv API, all of which returned real results.)

---

## (b) Sourced best-practice principles

Each principle is grounded in a fetched source (full URLs in the Sources list, section e).
Access date for all: **2026-06-27**.

| # | Principle | Source (one-line evidence) |
|---|-----------|----------------------------|
| **P1** | **Prefer open-ended questions** — they yield deeper, unexpected insight; closed questions only clarify. Use "walk me through…", "tell me about the last time…". | NN/g, *Open-Ended vs. Closed Questions*: "Open-ended questions result in deeper insights. Closed questions provide clarification and detail, but no unexpected insights." |
| **P2** | **Do not lead or anchor** — a leading question "includes or implies the desired answer… in the phrasing itself"; participants "mimic the words of the interviewer," especially when the interviewer is the perceived authority. Don't rephrase the user's words, name elements for them, or assume their feelings. | NN/g, *Avoid Leading Questions*: leading Qs "result in biased or false answers… they rob us of the opportunity to hear an insight we weren't expecting." |
| **P3** | **Talk less, listen more; reflect back, don't inject.** Active listening "prevents you from leading customers towards a certain answer." | Mom Test (Atlanta Ventures summary), Rule 3: "listen more than you talk… let customers speak… without interruption or influence." |
| **P4** | **Ask for concrete specifics / real instances, not generic or hypothetical opinions** (people fabricate opinions on demand — the "query effect"). | Mom Test Rule 2: "ask about specifics in the past instead of generics or opinions about the future." NN/g *Interviewing Users*: "the query effect: people can make up an opinion about anything." |
| **P5** | **Climb to the underlying "why"/root cause — but the count is not magic.** Ask "why" until you reach the real driver; "it may take fewer or more than five 'whys.'" | Atlassian, *5 Whys*: "Identifies root causes, not symptoms… It may take fewer or more than five 'Whys' to reach the root cause." |
| **P6** | **Don't pitch / anchor on a solution.** Focus on the person's problem and context, not your proposed answer, or you "lock the customer into agreeing politely." | Mom Test Rule 1: "Talk about their life instead of your idea." |
| **P7** | **Experienced analysts follow an implicit *structured cognitive framework*, not free-form chat.** Free-form LLM elicitation "leads to the omission of implicit requirements and redundant questions"; a structured, ontology-guided next-concern selector outperforms it. | arXiv 2605.05828 (OntoAgent, RE 2026). |
| **P8** | **Know when you have enough; question *efficiently*.** Over-asking manufactures noise (query effect); efficient elicitation reaches sufficiency without redundant questions. | OntoAgent reports gains in "questioning efficiency" (TKQR) by pruning; NN/g query-effect warns against asking for opinions that don't matter. |
| **P9** | **Stakeholders often *cannot articulate* their requirements** (articulation barriers from limited domain knowledge / cognitive constraints); good elicitation actively helps them express and surface tacit detail, calibrated to their context. | arXiv 2601.16699 (Mircea et al., REFSQ 2026): LLM revisions "surfaced tacit details… and helped them better understand their own requirements," rated higher by participants with limited domain expertise. |
| **P10** | **AI may act as an articulation aid, but the human must stay the decider/validator.** Keep stakeholders in the validation loop; AI-plus-human synthesis beats either alone while "preserving the value of stakeholder participation." | Mircea et al. ("keeping stakeholders in the validation loop… responsible and trustworthy use of AI"); Salgado Neto et al. arXiv 2606.24060. |
| **P11** | **Passive/free-form capture is insufficient** — elicitation must actively draw out implicit requirements, not transcribe what the user volunteers. | OntoAgent (free-chat "omits implicit requirements"); reinforced by P9. |
| **P12** | **Beware say-vs-do; triangulate.** What users say differs from what they do; interviews are weak for predicting future behavior and should be triangulated with other evidence. | NN/g *Interviewing Users*: "What users say and what they do are different… the present: what the user is doing right now [is] the only spot [that] generates valid data." |

---

## (c) Assessment — alignment, divergences, gaps

### 1. Alignment (where AID follows current best practice)

**STRONGEST alignment — structured next-move selection (P7, P11).** AID's central design
decision (D2: "the opener is the only fixed question; everything after is engine-guided")
and its deterministic five-step selector — STOP CHECK → GAP SELECTION → MOVE SELECTION →
CALIBRATION SHAPING → ENVELOPE+EMIT (`elicitation-engine.md` §Adaptive Loop) — is an
almost one-to-one match with the **2026 peer-reviewed** OntoAgent result (arXiv 2605.05828):
"experienced analysts implicitly follow a structured cognitive framework," operationalized
there as ParseUser → ScoreOnto → ReRankOnto → GatePrune. AID independently arrived at the
same architecture (gap inventory + priority ranking + gap-type→move firing table), and for
the same stated reason — free-form chat "omits implicit requirements." This is convergence
with the research frontier, not just folklore. **Confidence: CONFIRMED.**

**Bounded why-probe vs the five-whys ritual (P5).** Move 7 (`move-playbook.md`) explicitly
rejects the rote count — "climb 2-3 whys… stop at the terminal value; NEVER the rote 'five
whys'" — citing the arbitrariness of the number. This matches Atlassian's own caveat
("fewer or more than five"). AID is actually *more* disciplined than the popular technique.
**CONFIRMED.**

**Calibrating to the non-expert / unsure stakeholder (P9).** `calibration.md` (READ every
turn + an explicit early ASK, four-state `Unknown|Expert|Mixed|Novice`, depth-shaping table)
plus the advisor-stance "I don't know" handler directly implement what Mircea et al. found
matters most: support tailored to users with limited domain expertise, surfacing tacit
detail. AID's "heavier drawing-out, teaching scaffolds, proactive recommendations" for
novices is exactly the articulation-aid behavior the study validated. **CONFIRMED.**

**AI as articulation aid with the human as decider (P10).** `advisor-stance.md` makes every
one of the five user-move handlers defer the final call to the user, and Invariant 7 states
the engine "never decides silently." This is precisely Mircea's "keep stakeholders in the
validation loop" and Salgado Neto's "preserve stakeholder participation." **CONFIRMED.**

**Concrete-example probing (P4).** Move 8 (concrete-example probe) — "a term the user cannot
illustrate with an example is not yet load-bearing" — is the generative-interview analogue
of the Mom Test's "ask for specifics" and NN/g's critical-incident method. **CONFIRMED.**

**Knowing when you have enough (P8).** Step 1 STOP CHECK ("minimal-but-sufficient, NOT at
the end of a list"), the consumer-supplied stop predicate, and triage's "route-with-confidence"
+ one-turn-common-case directly implement question-efficiency / anti-over-elicitation.
**CONFIRMED.**

**Reflect-back / scribe (partial P3).** Move 4 ("propose the ordered sequence back"), Move 10
(mediate-then-defer & scribe), and the continuous calibration READ implement reflecting-back
and immediate recording. **CONFIRMED** for the reflect-and-confirm half of P3.

### 2. Divergences (and whether better / neutral / worse)

**THE central divergence — NFR-7 "always propose a Suggested answer" vs the anti-leading/
anti-anchoring rule (P2, P3, P6).** This is the one real tension and deserves an honest
verdict. AID *mandates* a straw-man on **every** turn: Move 1 (straw-man-first) fires
"every turn, unconditionally," and `advisor-stance.md` makes `Suggested:` non-optional, with
a bare question declared "structurally unconstructable." NN/g is unambiguous that a question
which "implies the answer in the phrasing" biases the response — and that the effect is
*worst* when the interviewer is the perceived authority and the participant doesn't want to
disagree. The Mom Test's Rule 1 ("don't pitch your idea") and Rule 3 ("don't influence")
point the same way. On its face, "here is my proposed answer, accept or override" is the
textbook anchoring move.

**Verdict: a defensible, mostly NEUTRAL-to-BETTER divergence for AID's use case — with one
residual risk that is real.** Three reasons it is defensible, then the residual risk:

1. **Different interview genre.** NN/g's guidance governs *evaluative* user research — you
   are measuring an authentic reaction to an existing design and must not contaminate it.
   AID runs a *generative co-design* interview: the user is the **author/decider** of work
   that does not yet exist, and the agent has **no competing idea of its own to defend**
   (the specific failure mode the Mom Test's "don't pitch" targets — founder bias — is
   absent). Anchoring on the user's *own* stated intent is materially less hazardous than
   anchoring a research subject.
2. **The newest empirical evidence supports it.** Mircea et al. (REFSQ 2026) found that
   LLM-generated *tailored revisions* of stakeholders' requirements were rated **higher than
   the stakeholders' own original statements** across alignment, readability, and unambiguity,
   and "surfaced tacit details" — i.e., a context-grounded straw-man functions as an
   articulation aid, not merely a bias trap, *for stakeholders who struggle to express
   themselves*. That is exactly AID's NFR-7 intent.
3. **AID actively mitigates the anchoring risk.** Every envelope carries explicit
   `[2] Not applicable` / `[3] Your answer: ___` override options; the `Why:` field exposes
   the rationale so the user can contest it; the "cordially disagree / never yes-man" handler
   models the agent *itself* pushing back; and the defer-to-user invariant is enforced
   structurally. This is a genuinely better-than-naive treatment.

**The residual risk (the honest caveat).** Mircea et al. *also* warn that iterative
reformulation "risk[s] **distorting stakeholders' original intent**." A deferential or novice
user — precisely the cohort AID's calibration says to give *more* straw-mans to — is the most
likely to click `[1] Accept this` on a plausible-but-not-quite-right suggestion, which is the
authority-deference effect NN/g names. AID *softens* this risk but does not *eliminate* it,
and it does not currently treat anchoring as an explicit, named hazard to manage. (See Gap G1.)

**Verbosity vs "talk less, listen more" (P3).** Every AID turn emits context + question +
Suggested + Why + options. That is a lot of analyst talk per turn, in tension with the
Mom-Test "talk less." This is a NEUTRAL trade: AID buys articulation support and NFR-7
transparency at the cost of brevity; given P9/P10 evidence, the trade is reasonable, but it
is a real stylistic divergence from the "let silence do the work" school.

**Say-vs-do / no observation limb (P12).** NN/g's deepest caution — interviews capture what
users *say*, not what they *do* — has no in-interview counterpart in AID (no prototype,
no behavioral observation). This is **largely inherent**: greenfield has nothing to observe.
AID partially answers it *downstream* via feature-005's build-time conformance lifecycle
(design→code divergence reconciled, human-gated), which is a legitimate "validate the claim
against reality later" mechanism. NEUTRAL, with an inherent-limitation honest note.

### 3. Gaps (best practices AID arguably should add)

- **G1 — No explicit anti-anchoring safeguard (most important gap).** Given that NFR-7
  *mandates* the very move classical guidance warns against, the absence of a named
  counter-discipline is the one real miss. Concrete, lightweight additions that would close
  it without abandoning NFR-7: (i) a calibration-sensitive rule that, for high-stakes or
  genuinely-creative gaps with a **Novice/deferential** user, asks the open question *first*
  and offers the straw-man only after an initial unaided answer (or flags accepted defaults
  as lower-confidence assumptions needing later re-confirmation); (ii) an explicit
  "distortion check" echoing Mircea's warning — confirm a straw-man *restates* the user's
  intent rather than *replacing* it; (iii) a note in `advisor-stance.md` naming anchoring as
  a known hazard the `[3] Your answer` path and cordial-disagreement handler exist to counter.
  **Confidence: CONFIRMED gap** (no such safeguard appears in any of the five docs).

- **G2 — No whole-picture read-back / sufficiency confirmation with the user.** AID scribes
  per-decision (Move 10) and stops at minimal-but-sufficient (Step 1), but I found no
  end-of-interview "here is the complete picture I have — is it right?" confirmation turn in
  these five docs (it may live in `state-completion.md`, outside this review's scope).
  Best practice (and Mircea's "validation loop") favors a consolidated play-back of the whole
  before proceeding. **Confidence: LIKELY gap** (scoped to the 5 docs read).

- **G3 — Preserve the user's *exact words* on captured answers.** NN/g warns specifically
  against rephrasing the user's words back to them. Move 2 (term-capture) correctly pins a
  term "as the user uses it," but the `Suggested:` straw-man values throughout are
  agent-worded; there is no rule to prefer the user's verbatim phrasing when recording a
  confirmed answer. Minor. **Confidence: LIKELY.**

---

## (d) Net verdict

**AID's new interview aligns strongly with current web best practice for requirements-gathering
interviews — in places it is ahead of the popular literature and converges with 2026
peer-reviewed research.** The strongest alignment is structural: the deterministic
gap→move→calibrate→emit selector independently reproduces the OntoAgent (RE 2026) finding
that good elicitation is a *structured cognitive framework*, not free-form chat; and the
calibration + articulation-aid + human-as-decider stance matches the newest empirical RE
evidence (Mircea, REFSQ 2026; Salgado Neto 2026) on supporting stakeholders who cannot fully
articulate what they want. The bounded why-probe is more disciplined than the textbook
five-whys, and the minimal-but-sufficient stop check honors question-efficiency.

**The most important divergence/gap** is the NFR-7 "always propose a Suggested answer"
mandate set against the single most emphasized rule in classical interview craft — do not
lead or anchor. AID's straw-man-first approach is **defensible and largely supported** for a
*generative co-design* interview (the agent defends no idea of its own; tailored straw-mans
demonstrably help users articulate; explicit override + cordial-disagreement + defer-to-user
mitigate the risk). It is **not** a clear miss. But the residual anchoring risk on
deferential/novice users is real — and is precisely the cohort AID gives *more* straw-mans —
and AID does not yet name or guard anchoring explicitly (Gap G1). Adding a lightweight,
calibration-sensitive anti-anchoring safeguard (ask-open-first for novices on high-stakes
gaps; flag accepted defaults as re-confirmable assumptions; a "restate-not-replace" check)
would convert the one defensible-but-exposed divergence into a clean strength.

**Bottom line:** aligned and, on the AI-elicitation frontier, ahead of the curve — with one
known sharp edge (anchoring under an always-suggest mandate) that is mitigated but worth one
deliberate, small hardening.

---

## (e) Sources

All accessed **2026-06-27** via live `curl` fetch.

1. NN/g — Amy Schade, *Avoid Leading Questions to Get Better Insights from Participants* —
   https://www.nngroup.com/articles/leading-questions/
2. NN/g — Jakob Nielsen, *Interviewing Users* —
   https://www.nngroup.com/articles/interviewing-users/
3. NN/g — Maria Rosala, *Open-Ended vs. Closed Questions in User Research* —
   https://www.nngroup.com/articles/open-ended-questions/
4. The Mom Test (Rob Fitzpatrick) — *The 3 Rules to Customer Interviews from The Mom Test*,
   Atlanta Ventures —
   https://www.atlantaventures.com/blog/the-3-rules-to-customer-interviews-from-the-mom-test
5. Atlassian Team Playbook — *5 Whys Analysis* —
   https://www.atlassian.com/team-playbook/plays/5-whys
6. Dongming Jin et al., *From Chat to Interview: Agentic Requirements Elicitation with an
   Experience Ontology*, RE 2026 — arXiv:2605.05828 — https://arxiv.org/abs/2605.05828
   (submitted 7 May 2026)
7. Michael Mircea, Emre Gevrek, Elisa Schmid, Kurt Schneider, *Supporting Stakeholder
   Requirements Expression with LLM Revisions: An Empirical Evaluation*, REFSQ 2026 —
   arXiv:2601.16699 — https://arxiv.org/abs/2601.16699 (submitted 23 Jan 2026)
8. Manoel Salgado Neto, Alan Araujo, Ronnie de Souza Santos, *Collaborative and AI-Supported
   Requirements Elicitation: An Empirical Study* — arXiv:2606.24060 —
   https://arxiv.org/abs/2606.24060 (submitted 23 Jun 2026)
