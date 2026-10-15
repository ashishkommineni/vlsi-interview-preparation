# Day 02 — Timing, reset, metastability, and CDC

## Q1. What is metastability, and can simulation show its probability?

**What the interviewer is testing:** Physical sampling awareness and simulator limits.

**Answer:** Metastability occurs when a receiving storage element samples near its setup/hold aperture and temporarily resolves neither cleanly high nor low. RTL simulation normally models ideal digital values and cannot establish MTBF. CDC structure, library characterization, clock/data rates, and physical implementation determine the risk.

**Example:** A two-flop synchronizer gives the first flop nearly a full destination cycle to resolve before the synchronized value is used.

**Common wrong answer:** “A two-flop synchronizer removes metastability.” It reduces propagation probability; it does not make the first flop immune.

**Spoken answer:** “Metastability is an analog resolution event caused by sampling near an edge. RTL simulation cannot prove MTBF, so I use recognized CDC structures, mark synchronizer flops, constrain implementation, and run structural CDC analysis.”

## Q2. Why is a two-flop synchronizer suitable for a level but not every pulse?

**What the interviewer is testing:** Event observability across unrelated clocks.

**Answer:** A stable single-bit level remains present long enough for the destination to sample it. A narrow pulse may begin and end entirely between destination edges and disappear. For events, stretch the pulse, toggle a bit, or use a request/acknowledge handshake depending on event rate and loss requirements.

**Example:** A source toggle changes once per event; the destination synchronizes the toggle and XORs two delayed samples to recreate a one-cycle pulse.

**Common wrong answer:** “Any single-bit signal is safe through two flops.”

**Spoken answer:** “Two flops address metastability propagation, not pulse capture. For a level they are enough; for an event I also prove the event remains observable, usually with a toggle or handshake and a stated minimum spacing.”

## Q3. Why can each bit of a multi-bit bus not be synchronized independently?

**What the interviewer is testing:** Coherency and reconvergence.

**Answer:** Each bit may resolve on a different destination cycle, producing a word that never existed in the source domain. Multi-bit transfers need a coherence protocol: hold data stable while synchronizing a control handshake, use Gray code for monotonic counters, or use an asynchronous FIFO for a stream.

**Example:** An async FIFO synchronizes Gray pointers, while payload data is stored in dual-port memory and read only after pointer/empty logic says it is available.

**Common wrong answer:** “Use two flops on every bit and then register the bus once more.”

**Spoken answer:** “Independent bit synchronizers solve metastability locally but lose word coherence. I cross multi-bit data with a handshake, Gray-coded state, or an async FIFO so the destination knows when a complete stable value is valid.”

## Q4. Why is Gray code used for asynchronous FIFO pointers?

**What the interviewer is testing:** Understanding the benefit and its limits.

**Answer:** Consecutive Gray values differ by one bit, so an asynchronously sampled transition cannot combine several changing pointer bits into an arbitrary binary value. The local pointer remains binary for addressing and arithmetic, then is converted to Gray for crossing. Gray coding still requires synchronizer flops and physical skew constraints.

**Example:** `gray = (binary >> 1) ^ binary`. Full detection compares the next write Gray pointer with the synchronized read pointer using the required top-bit inversion.

**Common wrong answer:** “Gray code guarantees the destination sees every pointer value.” It may skip values; safety relies on monotonic progress and conservative flags.

**Spoken answer:** “Gray code limits each pointer transition to one changing bit, which makes asynchronous sampling safer. It does not replace the synchronizer or skew constraints, and the destination may legally observe a later pointer value.”

## Q5. What does asynchronous assertion and synchronous deassertion of reset mean?

**What the interviewer is testing:** Recovery/removal and coherent restart.

**Answer:** Assertion may force state immediately, independent of the clock. Deassertion is passed through a small synchronizer in each clock domain so local flops leave reset on a clean clock edge. This avoids different flops releasing around an unsafe edge.

**Example:** A reset synchronizer shifts in ones after external reset rises; the local reset remains active until the synchronizer stages have safely sampled release.

**Common wrong answer:** “Because reset is asynchronous, both assertion and deassertion can happen at any time.”

**Spoken answer:** “I may assert reset asynchronously for immediate safety, but I release it synchronously per domain. That protects recovery/removal timing and gives each clock domain a coherent restart point.”

## Q6. What is the difference between a CDC synchronizer and an asynchronous FIFO?

**What the interviewer is testing:** Choosing an architecture from throughput and data requirements.

**Answer:** A synchronizer transfers a control level or encoded event with limited bandwidth. An async FIFO transfers an ordered stream with independent clocks and absorbs rate differences. Its correctness depends on dual-port storage, local pointers, synchronized Gray pointers, and conservative full/empty generation.

**Example:** Cross an enable bit with two flops; cross a sequence of 32-bit samples through an async FIFO.

**Common wrong answer:** “An async FIFO is just many two-flop synchronizers.”

**Spoken answer:** “I use a synchronizer for one bit whose observation contract is simple. I use an async FIFO for coherent multi-bit traffic and rate decoupling, then verify ordering, no overflow/underflow, flags, reset, and CDC structure.”

## Q7. How does clock skew affect setup and hold?

**What the interviewer is testing:** Sign convention and timing intuition.

**Answer:** If the capture clock arrives later than the launch clock, the same-cycle setup budget generally increases but the hold margin generally decreases. Early capture has the opposite effect. Exact analysis includes clock uncertainty, launch/capture delays, cell delays, and the selected timing edge relationship.

**Example:** Useful skew can improve a critical setup path, but adding it carelessly may create a short-path hold violation.

**Common wrong answer:** “Positive skew is always good.”

**Spoken answer:** “Skew redistributes timing margin. A later capture edge can help setup but hurt hold, so I never discuss a skew fix without checking both max and min timing views.”

## Q8. What are recovery and removal checks?

**What the interviewer is testing:** Asynchronous control timing.

**Answer:** Recovery is analogous to setup for deasserting an asynchronous control before a clock edge; removal is analogous to hold after the edge. Violating either can make flops release inconsistently or metastably. Reset synchronization addresses release, while physical STA still checks the implementation.

**Example:** An active-low async reset may assert at any time, but its rising deassertion is synchronized before reaching functional state machines.

**Common wrong answer:** “Asynchronous reset pins have no timing checks.”

**Spoken answer:** “Recovery and removal are the setup/hold-like checks on asynchronous reset release. That is why I synchronize deassertion and verify the reset tree and timing rather than treating reset as timing-free.”

## Q9. How would you verify a pulse synchronizer?

**What the interviewer is testing:** Whether you verify the environmental contract as well as outputs.

**Answer:** Use unrelated clocks and phase offsets; create valid source pulses at minimum legal spacing; count accepted source events and destination pulses; assert one-cycle destination width and no duplicate or missing events. Also test reset during idle and according to the documented in-flight reset policy.

**Example:** The Day-05 RTL project uses a toggle crossing and compares six source events against six destination pulses under unrelated clocks.

**Common wrong answer:** “Randomize both clocks and check that some destination pulse appears.”

**Spoken answer:** “I build an event scoreboard: every legal source event must produce exactly one destination pulse. I vary phase and clock ratio, assert pulse width and spacing assumptions, and separately analyze metastability structure with CDC tools.”

## Q10. What is reconvergence in CDC analysis?

**What the interviewer is testing:** Subtle CDC hazards beyond individual synchronizers.

**Answer:** Reconvergence occurs when separately synchronized signals later combine in destination logic. Even if each path is individually synchronized, differing latency can create illegal combinations or glitches. Related controls may need encoding, bundling, a handshake, or a single synchronized state representation.

**Example:** Crossing two one-hot mode bits through separate synchronizers can briefly produce `00` or `11`; crossing one encoded mode plus a valid handshake avoids that ambiguity.

**Common wrong answer:** “If the CDC report shows two-flop synchronizers, downstream combination is safe.”

**Spoken answer:** “I check not only each crossing but also where synchronized paths reconverge. Independent latency can create a destination state that never existed, so related information must cross with a coherence scheme.”
