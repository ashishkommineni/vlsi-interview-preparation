# Day 14 — Integration, debug, sign-off, and project defense

## Q1. How do you start verification from a specification?

**What the interviewer is testing:** Planning before coding.

**Answer:** Extract interfaces, legal/illegal behavior, state, timing, reset, errors, performance, and assumptions. Convert each requirement and risk into stimulus, a checker, and coverage goal; identify ambiguous items and resolve them. Define exit criteria and tool boundaries before running tests.

**Example:** A register block plan maps byte strobes to scoreboard modeling, response stability to SVA, and address/error classes to coverage.

**Common wrong answer:** “Start by writing random sequences and see what breaks.”

**Spoken answer:** “I turn the spec into a traceable verification plan: requirement, risk, stimulus, checker, coverage, and exit criterion. That prevents activity without evidence.”

## Q2. How do you decide whether a failure is in DUT, testbench, or specification?

**What the interviewer is testing:** Disciplined triage.

**Answer:** Find the earliest divergence from a written contract. Confirm clock/reset/configuration, reproduce with the same seed, compare monitor-observed pins against the reference model, and inspect whether the driver obeyed protocol. If two plausible interpretations remain, treat it as a spec ambiguity, not an assumption.

**Example:** An AXI mismatch may originate from driver payload changing under stall, monitor AW/W pairing, scoreboard strobe merging, or slave RTL.

**Common wrong answer:** “If the waveform looks wrong, the DUT is wrong.”

**Spoken answer:** “I debug from first divergence and assign blame only after validating stimulus, observation, prediction, and the requirement. A good testbench is also a design that can contain bugs.”

## Q3. What makes a reference model independent?

**What the interviewer is testing:** Avoiding common-mode bugs.

**Answer:** It implements externally observable rules at a higher abstraction, without copying DUT state machines, helper functions, or the same algorithmic shortcuts. It consumes accepted transactions and predicts required behavior. Shared constants are fine; shared flawed logic defeats comparison.

**Example:** A byte-write model updates a software array per strobe rather than calling the RTL merge function.

**Common wrong answer:** “Reuse the DUT function in the scoreboard so both stay consistent.”

**Spoken answer:** “The model should agree on the specification, not on implementation code. I keep it simpler, transaction-level, and independently derived.”

## Q4. How should a design-verification project repository be structured?

**What the interviewer is testing:** Reproducibility and communication.

**Answer:** Include a scoped specification, synthesizable RTL, interfaces, assertions, UVM or self-checking testbench, filelists/run commands, verification plan, expected and executed results, tool requirements, CI, limitations, and license. Generated outputs should not bury source; evidence should identify commit/tool/seed.

**Example:** Separate `rtl/`, `tb/interfaces`, `tb/assertions`, `tb/uvm`, `sim/`, and `docs/` with one top-level quick-start.

**Common wrong answer:** “Source files and a waveform screenshot are enough.”

**Spoken answer:** “A reviewer should reproduce the project without asking me how it works. I provide contract, source, automated run, checks, results, limitations, and a short technical defense.”

## Q5. What is a useful CI pipeline for RTL/DV?

**What the interviewer is testing:** Automation and evidence boundaries.

**Answer:** Run formatting/structure checks, lint, elaboration, portable smoke simulation with assertions, and targeted parameter configurations on every change. Licensed UVM/coverage regressions may run elsewhere; record them separately. CI must fail on simulator errors and pipe failures, not only command launch.

**Example:** `bash -o pipefail` prevents a simulation failure hidden by `tee` from producing a green job.

**Common wrong answer:** “CI is successful if compilation passes.”

**Spoken answer:** “My CI gives fast deterministic evidence—lint, build, executable self-check, assertions, and configuration coverage. I label commercial-simulator results separately and preserve logs.”

## Q6. How do you present a project in a technical interview?

**What the interviewer is testing:** Ownership and engineering judgment.

**Answer:** Explain the problem and scope, key architecture, hardest correctness risk, verification strategy, one real bug and root cause, measured evidence, known limitation, and next improvement. Be precise about what you personally implemented and what tools actually ran.

**Example:** For async FIFO, discuss Gray pointers, dual agents, order scoreboard, reset assumption, CDC limitation, and one boundary bug.

**Common wrong answer:** “List every file and UVM component without describing a design decision.”

**Spoken answer:** “I frame the project around one risk and its evidence. I can trace a transaction through RTL and testbench, show the bug I found, and state honestly what remains for sign-off.”

## Q7. What is the difference between verification and validation?

**What the interviewer is testing:** Product-level context.

**Answer:** Verification asks whether the implementation meets its specification, often pre-silicon through simulation, formal, emulation, and static analysis. Validation asks whether the realized product satisfies intended user/system needs, often involving FPGA/prototype or post-silicon behavior. Organizations may use the words differently, so clarify context.

**Example:** UVM verifies UART register/protocol requirements; board-level testing validates communication with real devices and software.

**Common wrong answer:** “Verification is simulation and validation is hardware.” The distinction is purpose, though tools often correlate.

**Spoken answer:** “Verification checks implementation against spec; validation checks the product against intended use. I clarify the team's terminology and connect pre-silicon checks to system evidence.”

## Q8. Why is formal verification a valuable portfolio addition?

**What the interviewer is testing:** Awareness of exhaustive proof use cases.

**Answer:** Formal can prove invariants across all legal input sequences within assumptions, find deep corner cases, and expose missing environmental constraints. It is especially effective for FIFOs, arbiters, protocol rules, and control logic. Proof convergence, assumption review, and coverage remain necessary.

**Example:** Prove an arbiter grant is one-hot and only granted to a requester; use cover to show each requester can win.

**Common wrong answer:** “Formal replaces simulation because it tests every input.” State-space and abstraction limits still apply.

**Spoken answer:** “I use formal where invariants matter and the state space is manageable. A proof is only as good as its assumptions, so I review constraints and add covers to avoid over-constraining behavior away.”

## Q9. How would you design a modern capstone for an RTL/DV portfolio?

**What the interviewer is testing:** System integration and market relevance.

**Answer:** Build a small subsystem with an AXI4-Lite or APB control plane, streaming datapath, DMA, interrupt controller, CDC boundary, and register model. Provide synthesizable RTL, UVM agents/virtual sequence, SVA, reference model, coverage, CI smoke, and synthesis or FPGA evidence. Keep scope small enough to finish honestly.

**Example:** An INT8 dot-product accelerator controlled by AXI4-Lite, fed by AXI-Stream, with DMA and performance counters.

**Common wrong answer:** “A bigger CPU is automatically a stronger project.” Incomplete complexity is weaker than closed evidence.

**Spoken answer:** “My capstone should integrate control, data, interrupts, and one hard boundary such as CDC. I prioritize a finished spec-to-coverage story over a huge design with no verification closure.”

## Q10. What would you improve next in this portfolio?

**What the interviewer is testing:** Self-awareness and roadmap quality.

**Answer:** Consolidate existing protocol blocks into one subsystem, add formal properties and CDC/RDC reports, execute and preserve Xcelium coverage results, add synthesis/PPA or FPGA evidence, and contribute one meaningful fix upstream. Keep the profile concise and pin only the strongest reproducible repositories.

**Example:** Turn separate AXI/APB/DMA/interrupt examples into one verified accelerator subsystem rather than adding another isolated counter.

**Common wrong answer:** “Add more repositories with every interview question.” Quantity without integration and proof reduces signal.

**Spoken answer:** “The next step is depth: one integrated subsystem, commercial regression evidence, formal/CDC sign-off, and implementation results. That shows I can close a project, not only create examples.”
