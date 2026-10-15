# Day 01 — Digital combinational and sequential foundations

## Q1. What is the practical difference between combinational and sequential logic?

**What the interviewer is testing:** Whether you reason from state and timing instead of repeating a definition.

**Answer:** Combinational outputs are functions of current inputs, allowing only propagation delay. Sequential logic also depends on stored state, normally updated at a clock edge. A feedback path does not automatically make good sequential logic; storage must be intentional and its timing contract must be defined.

**Example:** An adder is combinational. A counter is sequential because its next value is `count + 1`, but its visible value changes only on the active clock edge.

**Common wrong answer:** “Combinational logic has no clock, sequential logic has a clock.” Latches are sequential even without an edge-triggered clock.

**Spoken answer:** “Combinational logic maps present inputs directly to outputs, while sequential logic includes stored history. I identify the state elements, define their next-state equations, and then check setup, hold, reset, and output timing.”

## Q2. Why does an incomplete combinational assignment infer a latch?

**What the interviewer is testing:** Whether you understand retention implied by missing assignments.

**Answer:** If a variable is not assigned on every path, its old value must be preserved for the unspecified path. Preserving an old value requires storage, so synthesis infers a level-sensitive latch. A default assignment followed by conditional overrides usually makes the intended combinational behavior explicit.

**Example:** In `always_comb`, set `next = current;` first, then override `next` in selected branches. If the intended output is purely decoded, assign a real default such as `'0` instead.

**Common wrong answer:** “`always_comb` prevents latches.” It improves checks and sensitivity handling, but it cannot invent a value for an unassigned branch.

**Spoken answer:** “A latch appears because an uncovered branch says keep the previous value. I avoid accidental storage by assigning every output on every path and I use defaults that match the specification, not just defaults that silence a warning.”

## Q3. What are setup time and hold time?

**What the interviewer is testing:** Whether you can describe the sampling aperture around a clock edge.

**Answer:** Setup time is how long data must be stable before the capturing edge; hold time is how long it must remain stable afterward. A setup violation is mainly a maximum-delay problem, while a hold violation is a minimum-delay problem. Both can drive the receiving flop metastable.

**Example:** Reducing clock frequency can help setup because it increases the cycle budget, but it does not fix a hold violation because the data may still arrive too soon after the same edge.

**Common wrong answer:** “Lowering frequency fixes both setup and hold.”

**Spoken answer:** “Setup protects the interval before capture and hold protects the interval after capture. Setup depends on the long path and period; hold depends on the short path and clock skew, so the fixes are different.”

## Q4. How do blocking and nonblocking assignments model hardware differently?

**What the interviewer is testing:** Event scheduling and correct RTL coding style.

**Answer:** A blocking assignment updates immediately within the procedural thread. A nonblocking assignment evaluates its right-hand side now and schedules the left-hand-side update for the NBA region, so all flops observe the old state at an edge. Use nonblocking assignments for clocked state and blocking assignments for local combinational calculation.

**Example:** `q1 <= d; q2 <= q1;` creates a two-stage pipeline. Using blocking assignments in that clocked block can make simulation incorrectly show `q2` receiving the new `d` immediately.

**Common wrong answer:** “Blocking is synthesizable only for combinational logic.” Both forms can synthesize; the concern is simulation semantics and race-free intent.

**Spoken answer:** “Blocking executes in order, while nonblocking defers updates so registers sample old values together. I use `always_ff` plus nonblocking for state and `always_comb` plus blocking for combinational next-state logic.”

## Q5. What is the difference between a latch and a flip-flop?

**What the interviewer is testing:** Storage timing and time-borrowing awareness.

**Answer:** A latch is level-sensitive and transparent while its enable is active; a flip-flop samples at an edge. Latches can borrow time across stage boundaries but make timing and verification more complex. Flip-flops provide a clearer single-edge contract and are the usual default for synchronous RTL.

**Example:** An active-high latch follows `d` for the entire high enable window, whereas a positive-edge flip-flop ignores changes after the edge until the next edge.

**Common wrong answer:** “A latch is always a design error.” Intentional latch-based designs exist, but accidental latch inference is a serious bug.

**Spoken answer:** “A latch has a transparent level window; a flip-flop has an edge-based sample point. I use flops by default and use a latch only when the architecture and timing flow explicitly require it.”

## Q6. How do signedness and width affect an RTL arithmetic result?

**What the interviewer is testing:** Whether you catch silent truncation and unsigned promotion.

**Answer:** Expression width and signedness determine extension, arithmetic interpretation, and truncation. Mixed signed and unsigned operands can convert an expression to unsigned, and assigning a wider result to a narrow destination drops high bits. Size intermediate values deliberately and cast operands at the boundary.

**Example:** An 8-bit signed multiply needs a 16-bit signed result. Writing `logic signed [15:0] p; p = $signed(a) * $signed(b);` makes the intent visible.

**Common wrong answer:** “Declaring only the output signed makes the entire expression signed.”

**Spoken answer:** “I check both width and signedness at every arithmetic boundary. I explicitly cast mixed operands, provide enough intermediate bits, and decide whether overflow should wrap, saturate, or raise a flag.”

## Q7. What is the difference between priority logic and parallel decode logic?

**What the interviewer is testing:** Mapping code structure to hardware behavior.

**Answer:** Priority logic selects the first true condition, so later conditions matter only when earlier ones are false. Parallel decode evaluates independent conditions without implied priority. `if/else if` naturally expresses priority; a well-formed `case` often expresses mutually exclusive decode.

**Example:** An interrupt encoder must specify which request wins when several bits are high. A one-hot register decoder should assert that simultaneous selections are illegal instead of silently choosing one.

**Common wrong answer:** “Synthesis always optimizes `if` and `case` into identical hardware.” Semantics under overlapping conditions are different.

**Spoken answer:** “I choose the construct from the overlap rule. If multiple conditions may be true and one must win, I code priority explicitly. If they must be exclusive, I decode in parallel and assert the exclusivity assumption.”

## Q8. Why should reset behavior be part of the specification?

**What the interviewer is testing:** Whether you treat reset as functional behavior rather than boilerplate.

**Answer:** Reset defines initial state, assertion/deassertion timing, which state elements are reset, and when outputs become valid. Resetting every data register can hurt area, timing, and memory inference; often valid bits and control state are enough. Deassertion crossing clock domains must also be handled safely.

**Example:** A FIFO can reset pointers and valid/occupancy state without clearing every memory word, because unread memory content is architecturally irrelevant.

**Common wrong answer:** “For safety, reset every register and memory location.”

**Spoken answer:** “I specify reset polarity, synchronous or asynchronous behavior, deassertion rules, and output validity. I reset control state that affects observability, but I do not clear large storage unless the architecture actually requires it.”

## Q9. What does one-hot encoding mean, and when is it useful?

**What the interviewer is testing:** Encoding tradeoffs and illegal-state checking.

**Answer:** A one-hot state vector has exactly one asserted bit for each valid state. It uses more flops than binary encoding but can simplify decode and improve speed on FPGA fabrics or wide control machines. Reset and illegal zero/multi-hot recovery must be defined.

**Example:** A four-state FSM uses four one-hot bits instead of two binary bits. An assertion such as `$onehot(state)` catches illegal overlap after reset.

**Common wrong answer:** “One-hot is always faster and therefore always better.” Technology, state count, power, and routing determine the tradeoff.

**Spoken answer:** “One-hot spends one flop per state to simplify decode. I use it when timing or FPGA mapping benefits, and I add reset and illegal-state assertions because unused encodings are part of the verification problem.”

## Q10. How do you verify a parameterized RTL block?

**What the interviewer is testing:** Whether your tests cover elaboration boundaries, not only one default instance.

**Answer:** Verify representative legal parameter values, boundary values, and invalid combinations. Reference models must derive widths and limits from the same public parameters without copying the DUT algorithm. Add elaboration-time checks for unsupported values and run at least one non-power-of-two case when arithmetic assumptions could hide bugs.

**Example:** For a FIFO, test depth 2, a normal depth, and—if supported—a non-power-of-two depth; verify pointer width, full/empty behavior, and simultaneous operations.

**Common wrong answer:** “If the default parameter passes, the module is parameterized.”

**Spoken answer:** “Parameters change structure, so I treat each meaningful configuration like a separate design point. I compile multiple configurations, target boundaries, and assert illegal settings at elaboration instead of assuming the default proves them all.”
