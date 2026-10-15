# Day 10 — UVM RAL, reset, callbacks, and regression debug

## Q1. What problem does the UVM register model solve?

**What the interviewer is testing:** Abstraction, prediction, and reuse.

**Answer:** RAL describes registers, fields, access policies, reset values, maps, and address translation once, then supports reusable frontdoor/backdoor access, prediction, mirroring, and standard tests. It does not verify itself; the model and adapter must match the RTL specification.

**Example:** A W1C interrupt-status field needs the correct access policy and prediction behavior, not ordinary read/write mirroring.

**Common wrong answer:** “RAL replaces the register scoreboard.” It provides modeling services; checking still needs correct observation/prediction.

**Spoken answer:** “RAL is the executable register specification used by sequences and checking. I validate addresses, policies, reset values, adapter mapping, and prediction against the real bus and RTL.”

## Q2. What is frontdoor versus backdoor access?

**What the interviewer is testing:** Access path semantics.

**Answer:** Frontdoor accesses travel through the bus and exercise protocol, decode, side effects, and timing. Backdoor accesses directly read/write HDL state, often faster but potentially bypassing side effects. Use each for a stated purpose and compare them when validating the model.

**Example:** Use frontdoor for APB protocol verification; use backdoor to initialize a large memory quickly only if bypassed behavior is acceptable.

**Common wrong answer:** “Backdoor is equivalent to a zero-wait frontdoor transfer.”

**Spoken answer:** “Frontdoor verifies the real access path; backdoor manipulates implementation state directly. I never use backdoor evidence to claim the bus or access side effects were tested.”

## Q3. What is explicit versus implicit RAL prediction?

**What the interviewer is testing:** Mirror update ownership.

**Answer:** Implicit prediction updates the mirror based on operations initiated through the register model/map. Explicit prediction uses a bus monitor plus predictor/adapter to update the model from observed traffic, including accesses initiated elsewhere. Running both carelessly can double-predict.

**Example:** At SoC level, explicit prediction keeps the mirror correct when firmware or another master accesses the register bus.

**Common wrong answer:** “Auto-predict observes DUT pins.” It predicts from model-initiated operations, not independent monitor evidence.

**Spoken answer:** “I choose one prediction path deliberately. For shared buses I prefer monitor-based explicit prediction so the mirror follows actual accepted traffic, not only RAL intent.”

## Q4. What does a register adapter do?

**What the interviewer is testing:** Translation and response handling.

**Answer:** The adapter converts a generic `uvm_reg_bus_op` into a protocol sequence item and converts the bus response back into status/data. It defines byte-enable, response, and whether the driver provides responses. Incorrect mapping can make RAL tests fail even when DUT and VIP are correct.

**Example:** `reg2bus` maps kind/address/data/byte-enables; `bus2reg` maps observed read data and response status.

**Common wrong answer:** “The adapter drives pins.” The bus driver does that.

**Spoken answer:** “The adapter is the translation layer between RAL operations and the bus item's abstraction. I verify both directions, status mapping, and byte lanes with a known register access.”

## Q5. How should a UVM environment handle reset during traffic?

**What the interviewer is testing:** Coordinated state cleanup.

**Answer:** Define which in-flight transactions are aborted or completed, stop or reset drivers/sequences, flush scoreboard expectations according to the spec, reset reference/RAL state, and wait for interfaces to return to idle before resuming. Merely driving reset is not enough.

**Example:** On reset, the monitor announces a reset event; scoreboard discards only transactions architecturally canceled and records that decision.

**Common wrong answer:** “Drop and raise the run-phase objection around reset.” Objections do not reset component state.

**Spoken answer:** “Reset is a coordinated protocol event. I define in-flight policy, reset every model and outstanding tracker consistently, and restart only after the DUT and interfaces meet their post-reset contract.”

## Q6. What are UVM callbacks useful for?

**What the interviewer is testing:** Controlled behavior extension.

**Answer:** Callbacks allow registered extensions at defined hook points without factory-replacing the whole component. They suit orthogonal actions such as error injection or observation. Too many callbacks obscure control flow, so hook ownership and ordering must be documented.

**Example:** A driver callback corrupts parity for one negative test while the normal driver timing stays unchanged.

**Common wrong answer:** “Callbacks are always better than inheritance.”

**Spoken answer:** “I use a callback for a small optional behavior at a stable hook; I use factory inheritance when the component's main behavior changes. I keep callbacks sparse so debug flow remains visible.”

## Q7. How do objections control phase end?

**What the interviewer is testing:** End-of-test lifecycle.

**Answer:** Components or sequences raise objections while time-consuming activity is required and drop them when their responsibility—including drain policy—is complete. Objections do not start threads, wait for DUT idle automatically, or replace scoreboards. Leaked objections hang; early drops truncate checking.

**Example:** A test raises before starting its top sequence, waits for scoreboard drain after sequence completion, then drops.

**Common wrong answer:** “Every driver and monitor should keep a run-phase objection raised forever.”

**Spoken answer:** “Objections decide when a task phase may finish. I centralize ownership, drain observable work, use timeouts, and drop exactly what I raised.”

## Q8. What is phase jumping, and why should it be used carefully?

**What the interviewer is testing:** Advanced phasing judgment.

**Answer:** Phase jumping changes the normal phase progression, often for reset/restart flows. Components must be designed to stop, clean, and re-enter consistently; otherwise old processes and model state survive. A local reset coordination mechanism is often simpler.

**Example:** Jumping back to reset phase while a driver task remains blocked can create duplicate processes on re-entry.

**Common wrong answer:** “A phase jump automatically kills every thread and reconstructs the testbench.”

**Spoken answer:** “I use phase jumping only when the whole environment has a defined re-entry contract. For many block benches, an explicit reset sequence plus model cleanup is clearer and safer.”

## Q9. How do you debug a failure that appears only in one random seed?

**What the interviewer is testing:** Reproducible regression workflow.

**Answer:** Preserve test name, seed, simulator/version, commit, parameters, and first error. Re-run exactly, reduce transaction count/scenario while keeping the failure, inspect monitor/scoreboard events around the first divergence, and add a focused assertion or directed reproduction before fixing.

**Example:** Binary-search the sequence length or disable unrelated sequences while retaining the failing seed and timing relationship.

**Common wrong answer:** “Run many new seeds until it disappears, then treat it as flaky.”

**Spoken answer:** “I freeze the environment, reproduce the first failure, minimize it, and determine whether intent, transactor, checker, or DUT diverged first. The fix includes a regression that would have caught the bug.”

## Q10. What should a trustworthy regression summary contain?

**What the interviewer is testing:** Sign-off evidence quality.

**Answer:** Include exact commit, tool/version, test/seed/configuration, pass/fail counts, UVM severity totals, assertion results, coverage database identity, exclusions, known limitations, and links to logs/artifacts. A green badge without reproducible context is weak evidence.

**Example:** Separate portable Verilator RTL/SVA smoke evidence from a licensed Xcelium UVM/coverage run instead of implying they are the same.

**Common wrong answer:** “List only `UVM_ERROR: 0` and overall coverage.” A test can do no useful work and still report zero errors.

**Spoken answer:** “My regression report ties results to code, tool, seed, configuration, checks, and coverage. I also state what was not run, so another engineer can reproduce the claim and see the sign-off boundary.”
