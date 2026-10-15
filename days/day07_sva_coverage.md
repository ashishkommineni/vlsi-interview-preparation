# Day 07 — Assertions and functional coverage

## Q1. What is the difference between immediate and concurrent assertions?

**What the interviewer is testing:** Procedural versus temporal checking.

**Answer:** Immediate assertions evaluate an expression when procedural execution reaches them. Concurrent assertions sample on a clocking event and evaluate temporal relationships across cycles using sequences and properties. Use immediate checks for local procedural invariants and concurrent SVA for protocol timing.

**Example:** Immediately assert a function argument is legal; concurrently assert that a request is followed by a response under the specified timing rule.

**Common wrong answer:** “Concurrent assertions run continuously without a sampling clock.”

**Spoken answer:** “Immediate assertions check now in a procedure; concurrent assertions check sampled behavior over time. I choose based on whether the requirement is a point condition or a temporal contract.”

## Q2. What is overlapped versus non-overlapped implication?

**What the interviewer is testing:** Exact SVA cycle alignment.

**Answer:** `|->` starts the consequent in the same sampled cycle where the antecedent completes. `|=>` starts it on the next sampled cycle. If the antecedent is a multi-cycle sequence, alignment is relative to its final match.

**Example:** `req |=> ack` requires `ack` next cycle; `req |-> ready` checks `ready` in the same cycle.

**Common wrong answer:** “They differ only when a delay operator is present.”

**Spoken answer:** “Overlapped starts the consequent now; non-overlapped starts next sample. I draw the edge timeline before coding because one operator can move the check by a full cycle.”

## Q3. Why does SVA sample in the preponed region?

**What the interviewer is testing:** Race-free assertion semantics.

**Answer:** Concurrent assertions sample stable values just before active-region updates at the clock event, then evaluate later in the assertion regions. This gives a consistent view independent of procedural execution order. It also means a same-edge continuous/NBA update is not visible until a later sample.

**Example:** Checking a combinational gated clock at the source `posedge` can see its pre-transition value; trigger the safety property on the gated-clock transition instead.

**Common wrong answer:** “An assertion at posedge sees all registers after their nonblocking updates.”

**Spoken answer:** “SVA samples before same-edge RTL updates, which avoids races but matters for alignment. I account for NBA and combinational propagation rather than assuming the property sees the waveform after the edge.”

## Q4. What is the difference between `disable iff` and an antecedent reset condition?

**What the interviewer is testing:** Assertion abort semantics.

**Answer:** `disable iff` asynchronously aborts and suppresses an active property attempt when its condition is true. Putting reset in the antecedent merely prevents new matches at sampled edges and may leave an existing attempt alive. Choose based on the reset contract.

**Example:** `@(posedge clk) disable iff (!reset_n) req |=> ack;` cancels an in-flight request obligation during reset.

**Common wrong answer:** “`reset_n && req |=> ack` is always equivalent.”

**Spoken answer:** “Disable-iff controls the lifetime of property attempts; an antecedent only controls matching. I use disable-iff when reset invalidates in-flight protocol obligations.”

## Q5. What does vacuous pass mean?

**What the interviewer is testing:** Whether a passing assertion was actually exercised.

**Answer:** An implication can pass because its antecedent never occurs, not because the consequent behavior was proven under real stimulus. Add cover properties or antecedent counters to show activation, and connect assertion goals to the verification plan.

**Example:** `req |=> ack` passes every cycle when `req` is always zero; `cover property(req)` exposes the missing stimulus.

**Common wrong answer:** “A green assertion proves both trigger and response behavior.”

**Spoken answer:** “A property can pass vacuously when its trigger never happens. I pair key assertions with cover properties or activation statistics so a PASS also has meaningful exercise evidence.”

## Q6. What is the difference between code coverage and functional coverage?

**What the interviewer is testing:** Coverage intent.

**Answer:** Code coverage measures which implementation structures executed—lines, branches, toggles, FSM states. Functional coverage measures specification scenarios chosen by the verification plan. High code coverage does not prove protocol corner cases, and high functional coverage does not prove every RTL branch was exercised.

**Example:** Toggle coverage may show an error bit changed; functional coverage can distinguish address-error versus alignment-error with wait-state crossings.

**Common wrong answer:** “100% code coverage means verification is complete.”

**Spoken answer:** “Code coverage asks what RTL ran; functional coverage asks whether planned behaviors occurred. I review both with assertions and bug history, then justify exclusions rather than chasing a number alone.”

## Q7. What are bins, illegal bins, and ignore bins?

**What the interviewer is testing:** Coverage-model correctness.

**Answer:** Normal bins count desired observations. Illegal bins flag values the environment should never observe, but they are not a substitute for assertions. Ignore bins remove irrelevant or unreachable values from the coverage denominator with a documented reason.

**Example:** In an APB legal-traffic coverpoint, aligned addresses are normal bins; reserved encodings may be ignore bins if a separate negative-test model covers them.

**Common wrong answer:** “Put hard-to-hit legal cases in ignore bins to close coverage.”

**Spoken answer:** “Bins represent planned scenarios. I use illegal bins as coverage diagnostics, assertions for real protocol violations, and ignore bins only for justified out-of-scope space.”

## Q8. Why can a cross coverage explode?

**What the interviewer is testing:** Coverage scalability.

**Answer:** The Cartesian product of coverpoint bins grows multiplicatively, producing many meaningless or unreachable combinations. Cross only relationships tied to a risk or requirement, merge bins thoughtfully, and ignore impossible combinations with justification.

**Example:** Crossing 256 addresses, 256 data values, 16 lengths, and four responses creates millions of bins with little actionable value.

**Common wrong answer:** “More cross bins always mean stronger verification.”

**Spoken answer:** “A cross is useful only when the interaction matters. I reduce values to meaningful classes—boundary, aligned, error, mode—and cross those risk categories instead of raw data space.”

## Q9. Should coverage be sampled from the driver or monitor?

**What the interviewer is testing:** Intent versus observed behavior.

**Answer:** Protocol functional coverage should normally sample reconstructed accepted transactions from the monitor, because driver intent may be stalled, rejected, reset, or changed before completion. Separate stimulus-intent coverage can be useful, but it must be labeled differently.

**Example:** AXI write skew coverage should use actual AW and W handshake cycles observed on pins, not sequence item timestamps.

**Common wrong answer:** “Sampling the sequence item proves the DUT saw the case.”

**Spoken answer:** “I sample functional coverage from monitor-observed accepted behavior. If I also cover generated intent, I keep it separate so I can diagnose filtering between generator and DUT.”

## Q10. How do you decide that verification is complete?

**What the interviewer is testing:** Closure judgment rather than metric worship.

**Answer:** Completion requires planned tests passing, scoreboards drained, required assertions exercised and passing, functional/code coverage goals met or exclusions reviewed, known bugs resolved or accepted, and simulator/tool limitations recorded. The exit criteria must trace back to requirements and risks.

**Example:** A protocol block is not signed off merely because five random seeds pass if error response, reset under traffic, or coverage holes remain untested.

**Common wrong answer:** “Verification is complete at 100% functional coverage.”

**Spoken answer:** “Closure is an evidence review: requirements, checks, coverage, regressions, bugs, and tool limits all agree. I can explain every exclusion and every unverified assumption instead of presenting one percentage as proof.”
