# Day 03 — Verilog and SystemVerilog RTL semantics

## Q1. What do `always_comb`, `always_ff`, and `always_latch` add over `always`?

**What the interviewer is testing:** Intent-driven RTL and tool checking.

**Answer:** They document the intended hardware and allow tools to enforce useful restrictions. `always_comb` builds complete sensitivity and should have a single procedural driver; `always_ff` represents state driven by one event control; `always_latch` explicitly permits level-sensitive storage. They improve diagnostics but do not repair incomplete or incorrect logic.

**Example:** `always_ff @(posedge clk or negedge reset_n)` with nonblocking assignments makes register intent clear.

**Common wrong answer:** “Using `always_comb` guarantees combinational hardware.” Missing assignments can still infer storage.

**Spoken answer:** “The specialized blocks encode intent and give the compiler more opportunities to catch multiple drivers and illegal timing controls. I still have to write complete combinational assignments and correct sequential behavior.”

## Q2. What is the difference between a net and a variable?

**What the interviewer is testing:** Signal resolution and procedural assignment rules.

**Answer:** A net represents a connection driven by one or more continuous/module outputs and may use resolution when drivers conflict. A variable stores the last procedural assignment until changed. SystemVerilog `logic` is a variable type and removes the old `reg` naming confusion, but it does not itself permit arbitrary multiple drivers.

**Example:** Use `wire`/a net for a true multi-driver open-drain line; use `logic` for a state register or a single-driver combinational output.

**Common wrong answer:** “`logic` is a four-state replacement for both `wire` and `reg` in every situation.”

**Spoken answer:** “A net models connectivity and resolution; a variable models a procedural value. I use `logic` for most single-driver RTL signals and a net type when the hardware genuinely has resolved multiple drivers.”

## Q3. What race occurs when the testbench drives on the same edge as the DUT samples?

**What the interviewer is testing:** Scheduler regions and deterministic testbenches.

**Answer:** DUT and testbench active-region blocks can execute in either order, so the DUT may sample the old or new value depending on scheduling. A clocking block separates drive and sample skews, or the driver can change inputs on the opposite edge while the monitor samples accepted activity consistently.

**Example:** Drive a positive-edge DUT through a clocking block output before the next posedge and sample monitor inputs through clocking block inputs after the edge.

**Common wrong answer:** “Adding `#1` everywhere fixes races.” It hides assumptions and breaks portability across time units and clocks.

**Spoken answer:** “If stimulus and RTL both act on the same edge in the active region, order is nondeterministic. I use clocking blocks or a documented opposite-edge scheme so driving and sampling have an explicit timing contract.”

## Q4. Why are `casex` and careless `casez` dangerous in synthesizable control logic?

**What the interviewer is testing:** X masking and wildcard semantics.

**Answer:** `casex` treats X and Z in both expression and items as don't-cares, so an unknown control can match a valid branch and hide a reset or initialization bug. `casez` is narrower but can still hide Z/wildcard mistakes. Prefer plain `case`, `inside`, or explicit masks, and assert unknown-free controls.

**Example:** A state value `2'bx1` may match a `casex` item and produce a seemingly valid output instead of exposing the illegal state.

**Common wrong answer:** “Wildcards are only a synthesis optimization.”

**Spoken answer:** “I avoid `casex` in control paths because it can convert an X bug into a legal match. I prefer explicit decode and use assertions such as `!$isunknown(state)` to expose initialization problems.”

## Q5. What is the effect of an unsized literal in an expression?

**What the interviewer is testing:** Width propagation and portability.

**Answer:** An unsized literal has language-defined integer sizing and signedness that can widen or sign-extend an expression unexpectedly. Explicitly sized constants and casts make truncation and comparison intent clear, especially in parameterized arithmetic.

**Example:** Prefer `8'd1`, `WIDTH'(1)`, or `'d1` as appropriate instead of assuming plain `1` always behaves like one target-width bit.

**Common wrong answer:** “Synthesis automatically chooses the smallest width needed.”

**Spoken answer:** “Unsized constants participate in expression sizing before assignment, so they can change width and signedness. I size constants at arithmetic boundaries and review warnings rather than relying on destination truncation.”

## Q6. How do you code a safe counter with terminal-count behavior?

**What the interviewer is testing:** Boundary semantics and off-by-one reasoning.

**Answer:** Define whether terminal count is inclusive, what event increments, and whether the counter wraps, saturates, or reloads. Compare the current value at the accepted event and assign the next state deliberately. Size the counter with `$clog2` carefully because a maximum value of `N` may need `$clog2(N+1)` bits.

**Example:** A divide-by-N counter commonly toggles or emits a tick when `count == N-1`, then returns to zero.

**Common wrong answer:** “Use `$clog2(N)` bits and compare with `N`.”

**Spoken answer:** “I start from the exact count sequence, derive the required maximum value, and then size the register. I verify N=1 and boundary parameter values because that is where off-by-one and zero-width bugs appear.”

## Q7. What is read-during-write behavior in a register file or memory?

**What the interviewer is testing:** Collision semantics and implementation portability.

**Answer:** When a read and write target the same address in one cycle, the output may be old data, new data, no-change, or unspecified. The RTL contract must choose one, and the code must map predictably to the intended memory resource. A bypass path can guarantee new-data behavior independently of inferred RAM mode.

**Example:** The Day-03 byte-enable register file merges enabled bytes and returns the merged word on a same-address read/write.

**Common wrong answer:** “Nonblocking assignment order defines the hardware memory mode.”

**Spoken answer:** “Same-address read/write is an architectural decision, not an incidental simulator result. I specify old, new, or no-change behavior and verify every byte-enable collision at the cycle boundary.”

## Q8. When should a loop be used in synthesizable RTL?

**What the interviewer is testing:** Elaboration versus runtime thinking.

**Answer:** A bounded loop describes replicated hardware or repeated combinational/sequential assignments; it does not execute over time unless state and clock cycles are explicitly modeled. The bounds must be statically elaboratable for predictable synthesis. Large loops can create large parallel logic and long timing paths.

**Example:** A `for` loop summing four MAC lanes elaborates four multipliers and an adder network, not one multiplier reused for four cycles.

**Common wrong answer:** “A synthesizable `for` loop automatically saves area by iterating.”

**Spoken answer:** “RTL loops usually unroll into hardware. I use them for regular structures, then check the resulting area and timing; if I want resource sharing, I design an explicit multi-cycle controller.”

## Q9. What is the difference between elaboration-time and run-time constructs?

**What the interviewer is testing:** Parameterization and generate semantics.

**Answer:** Parameters, `generate`, and constant functions decide the design structure before simulation begins. Procedural `if`, `case`, and loops operate on signals during simulation and represent active hardware. A generate branch that is not selected does not exist in the elaborated hierarchy.

**Example:** `if (LANES == 1) begin : g_single ... end else begin : g_multi ... end` selects hardware structurally.

**Common wrong answer:** “Generate-if is a faster procedural if.”

**Spoken answer:** “Generate constructs choose which hardware is instantiated at elaboration; procedural constructs describe how existing hardware behaves at run time. That distinction matters for hierarchy, widths, and verification binds.”

## Q10. How do you handle illegal parameters?

**What the interviewer is testing:** Defensive reusable RTL.

**Answer:** State the legal domain, derive widths without zero or negative ranges, and fail early with an elaboration/initial assertion when a configuration is unsupported. Do not silently coerce an invalid value because downstream users may believe they verified a configuration that the RTL changed.

**Example:** An async FIFO that requires a power-of-two depth should check `DEPTH >= 2 && (DEPTH & (DEPTH-1)) == 0`.

**Common wrong answer:** “The synthesis tool will report any bad parameter.” Many invalid combinations elaborate into subtly wrong logic.

**Spoken answer:** “Parameters are part of the module API. I document constraints, guard derived widths, reject illegal settings early, and include non-default elaboration jobs in CI.”
