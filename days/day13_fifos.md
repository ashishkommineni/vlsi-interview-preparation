# Day 13 — Synchronous and asynchronous FIFOs

## Q1. How are synchronous FIFO full and empty usually computed?

**What the interviewer is testing:** Pointer wrap and occupancy.

**Answer:** Empty occurs when read and write positions are equal with matching wrap state. Full occurs when positions are equal with opposite wrap state, or from an occupancy counter equal to depth. Pointer width must include wrap information and parameter assumptions must be explicit.

**Example:** For power-of-two depth, use address bits plus one extra wrap bit in local binary pointers.

**Common wrong answer:** “Read pointer equals write pointer means both full and empty.” Extra state distinguishes them.

**Spoken answer:** “Equal addresses are ambiguous without wrap or count. I include wrap information or occupancy and verify transitions around depth-1, full, and empty.”

## Q2. What should happen on simultaneous read and write?

**What the interviewer is testing:** Boundary policy and occupancy update.

**Answer:** In the normal nonempty/nonfull case both operations occur and occupancy is unchanged. At empty or full, whether one operation enables the other in the same cycle is a design-specific look-ahead policy. RTL, scoreboard, and assertions must use the same accepted-operation definitions.

**Example:** Define `write_fire = wr_en && !full` and `read_fire = rd_en && !empty`; update count by `{write_fire,read_fire}`.

**Common wrong answer:** “Simultaneous operations always cancel even at the boundaries.”

**Spoken answer:** “I define accepted read and write first. In steady state both preserve occupancy; at full/empty I follow the documented fall-through or conservative policy and test those exact cycles.”

## Q3. What is overflow versus underflow?

**What the interviewer is testing:** Illegal request handling.

**Answer:** Overflow is a write request when no capacity exists; underflow is a read request when no data exists. The design may ignore the operation, raise a pulse/sticky flag, or treat it as forbidden. Pointers and stored data must not corrupt.

**Example:** Assert that write pointer stays stable on `wr_en && full` and read pointer stays stable on `rd_en && empty`, if that is the contract.

**Common wrong answer:** “Full prevents the request signal from being asserted.” The requester may still violate the interface.

**Spoken answer:** “The flag tells the requester what is legal, but I still define behavior for an illegal request. Verification proves no state advances and checks the specified error indication.”

## Q4. What is first-word fall-through versus registered-read FIFO behavior?

**What the interviewer is testing:** Output timing contract.

**Answer:** In first-word fall-through, the front item appears at output when available without an explicit read advancing it; read consumes it. In a registered-read FIFO, a read request causes data to appear according to a defined latency. The monitor/scoreboard must sample the correct event.

**Example:** FWFT often uses `out_valid/out_ready`; a classic FIFO may use `rd_en`, `rd_valid`, and a one-cycle response.

**Common wrong answer:** “All FIFOs return data in the same cycle as `rd_en`.”

**Spoken answer:** “FIFO ordering is common, but output timing is architectural. I state FWFT or registered latency and build checks around the actual consume and data-valid events.”

## Q5. Why does an asynchronous FIFO keep binary and Gray pointers?

**What the interviewer is testing:** Separation of local arithmetic and CDC encoding.

**Answer:** Binary pointers are convenient for memory addresses and increment arithmetic. Gray pointers change one bit per increment and are safer to synchronize. Each domain computes its next binary/Gray pointer locally and compares against a synchronized opposite-domain Gray pointer.

**Example:** Write domain stores with binary address, synchronizes read Gray, and computes full locally.

**Common wrong answer:** “The Gray pointer is used directly as the RAM address.”

**Spoken answer:** “Binary is for local address/arithmetic; Gray is for crossing. I never perform remote-domain arithmetic directly on unsynchronized binary pointers.”

## Q6. How is asynchronous FIFO full detected?

**What the interviewer is testing:** Gray wrap comparison.

**Answer:** For the standard power-of-two design, compare the next write Gray pointer with the synchronized read Gray pointer after inverting the required most-significant wrap bits. Exact equations depend on pointer encoding/width and must not be copied without deriving them.

**Example:** Compute `wgray_next` from `wbin_next`, then compare with transformed `rgray_sync` to register the next full flag.

**Common wrong answer:** “Full is simply next write Gray equal to read Gray.” That describes empty-like equality, not one-lap separation.

**Spoken answer:** “Full means the next write would catch the read pointer one buffer lap ahead. In Gray space that becomes a specific wrap-bit inversion comparison, registered in the write domain.”

## Q7. Why are full and empty considered conservative after remote movement?

**What the interviewer is testing:** Synchronizer latency implications.

**Answer:** Each domain sees the opposite pointer several local clocks late. Therefore full may remain asserted briefly after a remote read frees space, and empty may remain asserted briefly after a remote write adds data. This reduces throughput temporarily but prevents unsafe early access.

**Example:** The write side deasserts full only after updated read Gray passes through its synchronizer.

**Common wrong answer:** “Flags should change immediately when either pointer changes.” That would require unsafe combinational CDC.

**Spoken answer:** “Remote information is delayed by synchronization, so flags clear conservatively. Safe pessimism is expected; an early optimistic flag would allow overflow or underflow.”

## Q8. What reset problem is unique to an asynchronous FIFO?

**What the interviewer is testing:** Independent domain reset assumptions.

**Answer:** Each pointer/flag lives in its own clock domain while synchronized copies arrive later. Independent assertion/deassertion can make one side interpret stale state unless the architecture defines flush/restart coordination. Reset release should be synchronized per domain and traffic blocked until the contract is safe.

**Example:** Resetting only the write side while unread data remains requires an explicit policy; many simple FIFOs specify that reset flushes the whole FIFO.

**Common wrong answer:** “Resetting both pointers in RTL proves simultaneous reset in silicon.”

**Spoken answer:** “Async FIFO reset is a CDC protocol of its own. I define whether reset is coordinated, whether data is flushed, synchronize release per domain, and verify no traffic starts on stale remote state.”

## Q9. How do you scoreboard an async FIFO with unrelated clocks?

**What the interviewer is testing:** Cross-domain event modeling.

**Answer:** Push expected data on each accepted write-domain event and pop/compare on each accepted read-domain event. Protect the testbench queue from concurrent access or funnel monitor streams through a single scoreboard process. Never compare by wall-clock latency.

**Example:** Dual monitors publish `write_fire` and `read_fire` transactions to a centralized ordered model; end test waits for both domains and an empty model.

**Common wrong answer:** “Predict a fixed two-clock delay from write to read.” Clock phase, empty latency, and consumer request make it variable.

**Spoken answer:** “The invariant is order and conservation, not latency. I model accepted events from both clocks, serialize scoreboard updates safely, and drain before checking final counts.”

## Q10. What evidence is needed beyond RTL simulation for an async FIFO?

**What the interviewer is testing:** CDC sign-off boundaries.

**Answer:** Structural CDC analysis must recognize synchronizers and report no unsafe multi-bit crossings/reconvergence. STA/implementation must constrain Gray-bus skew and synchronizer placement; memory implementation and reset topology need review. Formal properties can strengthen pointer/flag proofs.

**Example:** Simulation verifies ordering and flags under clock ratios; CDC verifies topology; implementation checks ensure Gray transitions reach synchronizer inputs within the intended skew bound.

**Common wrong answer:** “Random unrelated-clock simulation proves the FIFO is CDC safe.”

**Spoken answer:** “Simulation proves functional scenarios, not metastability MTBF or physical skew. Async FIFO sign-off combines simulation, assertions/formal, CDC analysis, timing constraints, and implementation review.”
