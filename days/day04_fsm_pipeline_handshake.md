# Day 04 — FSMs, pipelines, and ready/valid flow control

## Q1. How do Moore and Mealy state machines differ?

**What the interviewer is testing:** Output timing and glitch awareness.

**Answer:** A Moore output depends only on registered state; a Mealy output depends on state and current inputs. Mealy logic can respond within the cycle but may have a longer combinational path or glitches if its inputs are not stable. Protocol outputs should be chosen from the actual timing contract, not from a preference for one label.

**Example:** A `done` pulse registered on entry to a completion state is Moore-like; `ready = idle && downstream_ready` is Mealy-like.

**Common wrong answer:** “Moore always takes one extra cycle and Mealy is always better.”

**Spoken answer:** “Moore ties outputs to state, while Mealy also uses current inputs. I choose based on required latency, combinational path, and interface stability, then verify transitions and outputs at exact edges.”

## Q2. What are the advantages of a two-process FSM style?

**What the interviewer is testing:** Separation of state storage and combinational intent.

**Answer:** One `always_ff` stores state; one `always_comb` calculates next state and outputs. Defaults make hold behavior visible and reduce accidental latches. A one-process FSM can also be correct, so the important point is deterministic assignment and readable transition logic.

**Example:** Start the combinational block with `next_state = state;` and safe output defaults, then override in each state.

**Common wrong answer:** “Two-process FSMs synthesize better in all tools.”

**Spoken answer:** “I prefer two-process FSMs because storage and decision logic are easy to review separately. I still define outputs, illegal states, reset entry, and all transition priorities explicitly.”

## Q3. What is the ready/valid transfer rule?

**What the interviewer is testing:** Fundamental flow-control semantics.

**Answer:** A transfer occurs only on a clock edge where `valid && ready` are both high. The source controls `valid` and payload; the sink controls `ready`. A source must not wait for `ready` before asserting `valid`, and it must hold `valid` and payload stable while stalled.

**Example:** If `valid=1` and `ready=0` for three cycles, the same payload remains presented; it transfers on the first later edge with `ready=1`.

**Common wrong answer:** “The transaction begins when `valid` rises and completes when `ready` rises.” Edges are irrelevant; the sampled conjunction matters.

**Spoken answer:** “Ready/valid is an edge-based contract: transfer equals `valid && ready`. Under backpressure the source holds the item stable, and the sink may assert ready independently to avoid deadlock.”

## Q4. Why must a source not make `valid` depend combinationally on `ready`?

**What the interviewer is testing:** Deadlock and combinational-loop prevention.

**Answer:** If the source waits for ready and the sink waits for valid, neither asserts and the channel deadlocks. Combinational dependencies across module boundaries can also form a long or circular timing path. A source asserts valid whenever it owns an item and keeps it asserted until transfer.

**Example:** Register pending data and drive `valid=pending`; clear pending only on `valid && ready`.

**Common wrong answer:** “Assert valid for one cycle only when ready is already high.”

**Spoken answer:** “Valid means the source has an item; it is not permission from the sink. I derive valid from source state and hold it, while ready comes from sink capacity.”

## Q5. What problem does a skid buffer solve?

**What the interviewer is testing:** Timing closure without losing a beat.

**Answer:** A skid buffer breaks or shortens a combinational ready path while capturing the one item that may arrive when downstream readiness changes. It provides elastic one-entry storage and preserves payload under backpressure. The design must correctly handle simultaneous dequeue and enqueue.

**Example:** Day-04 accepts a replacement item on the same cycle the stored item transfers, maintaining throughput without reordering.

**Common wrong answer:** “A skid buffer is just a register added to data.” Registering data without adjusting ready/valid can drop a transaction.

**Spoken answer:** “A skid buffer adds one elastic slot so I can register the backpressure path without losing the beat already in flight. I verify conservation, stable payload under stall, and simultaneous pop/push.”

## Q6. How do you verify that a pipeline preserves order under stalls?

**What the interviewer is testing:** Scoreboard modeling of accepted and delivered events.

**Answer:** Push an expected result only when the input handshake occurs and pop/compare only when the output handshake occurs. Randomize bubbles and backpressure, hold source data correctly, and drain at end of test. Assert output stability while stalled and accepted-count equals delivered-count.

**Example:** A queue of reference results is independent of pipeline latency; it checks data order even when internal stages stop.

**Common wrong answer:** “Compare output exactly N cycles after input.” That fails for an elastic pipeline whose latency changes under stall.

**Spoken answer:** “I model transactions, not fixed cycles: enqueue on accepted input and compare on accepted output. Then I stress stalls, bubbles, reset, and simultaneous stage movement and prove no loss, duplication, or reordering.”

## Q7. What is pipeline latency versus throughput?

**What the interviewer is testing:** Performance terminology.

**Answer:** Latency is the time or cycles from accepting one item to producing it. Throughput is the sustained rate of completed items. A deep pipeline may increase latency while achieving one result per cycle once full.

**Example:** A three-stage MAC can have three-cycle latency and one-result-per-cycle throughput if each stage accepts every cycle.

**Common wrong answer:** “More pipeline stages always make the operation faster.” They may raise clock frequency but add cycle latency and control complexity.

**Spoken answer:** “Latency answers how long one item takes; throughput answers how often results emerge. Pipelining trades registers and latency for a shorter critical path and potentially higher sustained rate.”

## Q8. How should an FSM recover from an illegal state?

**What the interviewer is testing:** Safety behavior and coding realism.

**Answer:** Define a safe destination and safe outputs, and assert that the illegal state is never reached during normal operation. A `default` recovery branch helps simulation and some fault cases, but synthesis may optimize unreachable encodings; safety-critical flows need explicit encoding and fault analysis.

**Example:** Drive controls inactive and set `next_state=IDLE`, while `$onehot(state)` or `state inside {...}` flags the occurrence.

**Common wrong answer:** “A default case guarantees hardware recovery from any bit upset.”

**Spoken answer:** “I specify safe outputs, a recovery state, and an assertion that exposes the fault. For safety claims I also verify the synthesized encoding and fault assumptions instead of relying only on RTL default syntax.”

## Q9. How do you avoid dropping the final pipeline result when ending a test?

**What the interviewer is testing:** End-of-test correctness.

**Answer:** Stop creating new input, keep the sink able to accept, and wait until the scoreboard is empty and all DUT valid/busy indicators are inactive. Then allow any analysis callbacks to finish before dropping the UVM objection. A fixed delay is not a proof of drain.

**Example:** `while (expected_count != 0 || out_valid) run_cycle(ready=1);` followed by accepted-versus-delivered equality.

**Common wrong answer:** “Wait ten clocks after the sequence ends.”

**Spoken answer:** “Sequence completion is not DUT completion. I drain based on observable state and scoreboard occupancy, use a watchdog, and only end when every accepted transaction has a checked result.”

## Q10. What assertions are most useful for ready/valid channels?

**What the interviewer is testing:** Translating protocol obligations into properties.

**Answer:** Assert payload and `valid` stability while stalled, no output without stored/accepted data, correct reset values, and any bounded-response promise that the architecture truly guarantees. Conservation and ordering usually need a scoreboard or tagged formal abstraction rather than a single local property.

**Example:** `valid && !ready |=> valid && $stable(payload)` checks a source hold rule, with reset disabled explicitly.

**Common wrong answer:** “Assert that ready is always high within a fixed number of cycles.” Backpressure may be intentionally unbounded.

**Spoken answer:** “I assert local invariants—hold under stall, legal reset, and no impossible output—and use a scoreboard for data/order conservation. I add liveness bounds only when the specification provides a real bound.”
