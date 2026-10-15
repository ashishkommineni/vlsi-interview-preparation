# Day 11 — AXI4-Lite, AHB-Lite, and APB

## Q1. What is the key difference between AXI4-Lite and full AXI4?

**What the interviewer is testing:** Protocol scope, not signal memorization.

**Answer:** AXI4-Lite keeps five independent ready/valid channels but removes bursts and transaction IDs, typically allowing a simpler outstanding model. Full AXI4 supports bursts, IDs, and greater concurrency/reordering. AXI4-Lite still permits read/write channel decoupling and backpressure.

**Example:** One AXI4-Lite write uses AW, W, and B handshakes; address and data may arrive in either order.

**Common wrong answer:** “AXI4-Lite completes every transfer in one cycle.”

**Spoken answer:** “AXI4-Lite is the register-control subset: no bursts or IDs, but it retains independent ready/valid channels. I still verify skew, stalls, and response holding on every channel.”

## Q2. Can AXI write address and write data be accepted in different cycles?

**What the interviewer is testing:** Channel independence.

**Answer:** Yes. AW and W are independent channels and either may handshake first. A slave must retain each accepted part until it can commit the write and must not assume simultaneous valid/ready. It also must not issue B before the required write information is accepted.

**Example:** Cover AW-before-W, W-before-AW, and same-cycle acceptance, each with response backpressure.

**Common wrong answer:** “The master must assert AWVALID and WVALID together.”

**Spoken answer:** “Address and data are independent. My slave has separate capture state, joins them only after both handshakes, applies strobes, then holds BVALID until BREADY.”

## Q3. What rule applies when AXI `VALID=1` and `READY=0`?

**What the interviewer is testing:** Payload stability under backpressure.

**Answer:** The source must keep VALID asserted and keep every payload/control signal for that channel stable until a handshake. READY may change independently. This applies to AW, W, B, AR, and R with the corresponding payload.

**Example:** `RVALID && !RREADY |=> RVALID && $stable({RDATA,RRESP})`.

**Common wrong answer:** “The source can retry later with a different payload because no transfer occurred.”

**Spoken answer:** “Once valid is asserted, that item is committed to the channel until accepted. I assert valid and payload stability through any stall.”

## Q4. Why is AHB-Lite described as pipelined?

**What the interviewer is testing:** Address/data phase overlap.

**Answer:** The address/control phase of transfer N+1 can overlap the data/response phase of transfer N. Therefore write data belongs to the previously accepted address phase, and wait states extend the current data phase while controlling when the next address advances.

**Example:** A monitor stores HADDR/HWRITE/HSIZE/HTRANS when an address phase is accepted, then associates HWDATA at that transfer's data-phase completion.

**Common wrong answer:** “HADDR and HWDATA visible in one cycle always form one transfer.”

**Spoken answer:** “AHB overlaps next address with current data. I track pipeline phase explicitly, qualify transfers with HTRANS and HREADY, and bind HWDATA to the prior accepted control.”

## Q5. What do IDLE, BUSY, NONSEQ, and SEQ mean on AHB `HTRANS`?

**What the interviewer is testing:** Valid-transfer qualification.

**Answer:** IDLE means no transfer; BUSY inserts a bubble within a burst; NONSEQ starts a transfer not sequential to the previous one; SEQ continues a burst. AHB-Lite slaves act on NONSEQ/SEQ when selected and accepted, not on IDLE/BUSY.

**Example:** A scoreboard that treats any HSEL-high cycle as a transfer will count BUSY cycles incorrectly.

**Common wrong answer:** “BUSY is a transfer that returns no data.”

**Spoken answer:** “Only NONSEQ and SEQ represent active transfers. I qualify address capture with selection, transfer type, and readiness so IDLE/BUSY never modify state.”

## Q6. Why does an AHB ERROR response take two cycles?

**What the interviewer is testing:** Response timing detail.

**Answer:** The protocol uses a two-cycle error response so the master can observe error while the transfer is extended before completion. The slave first drives ERROR with not-ready, then completes with ERROR and ready, according to the AHB-Lite timing contract.

**Example:** An unaligned or out-of-range access enters first-error then final-error response state.

**Common wrong answer:** “Set HRESP and HREADYOUT high together for one cycle.”

**Spoken answer:** “AHB error is a defined two-stage response, not just a status bit. I verify both cycles, stability, and correct return to normal traffic.”

## Q7. What are APB setup and access phases?

**What the interviewer is testing:** APB state sequencing.

**Answer:** In setup, PSEL is asserted and address/control/data are established while PENABLE is low. On the next cycle, access begins with PENABLE high. The transfer completes when PREADY is high; while PREADY is low, access signals must remain stable.

**Example:** Every transfer has at least one setup and one access cycle, even for a zero-wait slave.

**Common wrong answer:** “PENABLE can rise in the same cycle as a new PSEL.”

**Spoken answer:** “APB is a two-phase non-pipelined protocol. Setup presents the transfer; access asserts PENABLE and may stretch until PREADY, with all request signals held stable.”

## Q8. When is `PSLVERR` valid?

**What the interviewer is testing:** APB response sampling.

**Answer:** PSLVERR is meaningful on the completing access cycle, when PSEL, PENABLE, and PREADY are high. Outside completion it may be ignored. The master/monitor must sample it with completion, not during setup.

**Example:** An invalid address can wait two cycles and then complete with PREADY=1 and PSLVERR=1.

**Common wrong answer:** “PSLVERR should stay high from setup until the next transfer.”

**Spoken answer:** “APB error is sampled only at transfer completion. I bind response status to the PSEL/PENABLE/PREADY handshake and verify both zero-wait and wait-state errors.”

## Q9. How would you compare AXI4-Lite, AHB-Lite, and APB in one answer?

**What the interviewer is testing:** Architectural communication.

**Answer:** AXI4-Lite has five independent ready/valid channels and supports decoupled read/write progress. AHB-Lite has pipelined address and data phases on a shared bus. APB is simple, non-pipelined, and uses setup/access phases for low-complexity peripherals.

**Example:** A SoC may use AXI for system interconnect, bridge to AHB for some subsystems, and APB for low-bandwidth control registers.

**Common wrong answer:** “APB is always lower power only because it is slower.” Selection/toggle behavior and implementation also matter.

**Spoken answer:** “I compare the transfer models: independent channels for AXI-Lite, overlapped phases for AHB-Lite, and two-phase non-pipelined access for APB. The verification architecture must reflect those timing differences.”

## Q10. What is the most important scoreboard trap for each of these buses?

**What the interviewer is testing:** Protocol-aware transaction reconstruction.

**Answer:** For AXI-Lite, do not pair AW and W by same-cycle assumption. For AHB-Lite, do not pair current address with current write data. For APB, do not complete a transfer before PREADY in the access phase. In all cases the monitor, not driver intent, defines observed transactions.

**Example:** Maintain independent AXI pending AW/W state, an AHB phase pipeline, and an APB setup/access state tracker.

**Common wrong answer:** “One generic bus monitor can sample all three at every posedge.”

**Spoken answer:** “The checker must model each protocol's acceptance point. If transaction reconstruction is wrong, a sophisticated scoreboard will confidently compare the wrong operations.”
