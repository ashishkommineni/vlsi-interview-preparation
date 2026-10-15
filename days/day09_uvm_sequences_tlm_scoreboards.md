# Day 09 — UVM sequences, monitors, TLM, and scoreboards

## Q1. What happens during the sequencer-driver handshake?

**What the interviewer is testing:** Request ownership and blocking behavior.

**Answer:** The driver calls `get_next_item(req)` and blocks until a sequence item is arbitrated. It drives that request to completion, fills response fields if the item contract permits, then calls `item_done()` exactly once. The sequence's `start_item/finish_item` brackets arbitration and randomization timing.

**Example:** Randomize between `start_item(req)` and `finish_item(req)`, not long before, so arbitration and late constraints remain consistent.

**Common wrong answer:** “`finish_item` means the DUT has completed the transaction.” It means the item is offered to the sequencer/driver flow.

**Spoken answer:** “The sequence negotiates an item with the sequencer; the driver gets it, performs the pin-level transfer, and acknowledges completion with item-done. I keep one clear owner and one completion per request.”

## Q2. What is the difference between `get_next_item/item_done` and `get`?

**What the interviewer is testing:** Pull-port handshake variants.

**Answer:** `get_next_item` peeks/locks the request until `item_done`, so the driver must not fetch another prematurely. `get` removes the item in one call, transferring ownership immediately; response handling then needs a deliberate mechanism. Mixing protocols incorrectly can deadlock or double-complete.

**Example:** Most simple drivers use `get_next_item` then `item_done`; a pipelined driver may use other APIs with explicit outstanding tracking.

**Common wrong answer:** “They are interchangeable aliases.”

**Spoken answer:** “Get-next-item creates an explicit request-completion handshake; get transfers the item immediately. I choose one model from the driver pipeline and never call item-done after a plain get.”

## Q3. Why should a monitor reconstruct transactions from pins?

**What the interviewer is testing:** Checker independence.

**Answer:** Driver or sequence intent may differ from what the DUT actually accepted because of ready/valid, wait states, reset, or a driver bug. The monitor must observe handshake conditions and collect fields at the protocol-defined cycles. It then publishes a fresh, complete transaction.

**Example:** An AHB monitor captures address/control in one phase and associates write data from the later data phase.

**Common wrong answer:** “The monitor can clone the sequence item to save code.”

**Spoken answer:** “The monitor is my independent witness. It samples only accepted pin activity, handles the protocol pipeline, creates a fresh item, and publishes it after completion.”

## Q4. What are TLM port, export, and implementation roles?

**What the interviewer is testing:** Connection direction and method ownership.

**Answer:** A port is the caller's required interface; an implementation (`imp`) terminates the connection and provides the method body. An export forwards or exposes an implementation through another component boundary. Connectivity is checked during elaboration.

**Example:** A monitor's analysis port calls `write`; a scoreboard analysis imp implements `write`.

**Common wrong answer:** “A port sends data and an export receives it.” Direction is defined by the TLM interface and call relationship, not the English words alone.

**Spoken answer:** “The port initiates a TLM call, the imp implements it, and an export forwards the interface. I explain who owns the method and the transaction handle rather than memorizing arrows.”

## Q5. Why is an analysis port nonblocking and one-to-many?

**What the interviewer is testing:** Broadcast observation semantics.

**Answer:** `write()` immediately broadcasts a handle to all connected subscribers without returning flow-control status. Observers must not stall the protocol monitor, and they must treat the item as immutable or copy it if retaining/mutating it. Ordering between different subscribers should not encode functional dependence.

**Example:** One monitor analysis port can feed scoreboard, coverage, and transaction logging.

**Common wrong answer:** “The monitor waits until every subscriber finishes later in time.” `write` is a zero-time function call, though subscriber code still executes in that call stack.

**Spoken answer:** “Analysis ports broadcast completed observations without backpressure. I keep subscriber `write` methods short, avoid mutation, and move longer processing into queues or FIFOs.”

## Q6. When is a `uvm_tlm_analysis_fifo` useful?

**What the interviewer is testing:** Decoupling function-based publication from task-based processing.

**Answer:** It receives analysis `write()` calls and stores transactions so a consumer can later block on `get()`. This decouples monitor timing from a scoreboard task and can pair streams. Depth/overflow and end-of-test drain still need explicit handling.

**Example:** Separate request and response monitor streams can enter two analysis FIFOs, and the scoreboard can block until matching data is available.

**Common wrong answer:** “An analysis FIFO automatically matches transactions by ID.”

**Spoken answer:** “I use an analysis FIFO when publication must remain nonblocking but checking naturally waits for another stream. The scoreboard still owns matching, timeout, and drain policy.”

## Q7. How should an in-order scoreboard work?

**What the interviewer is testing:** Reference-model independence and conservation.

**Answer:** Convert accepted inputs into independently predicted results and enqueue them. On each observed output, assert the queue is nonempty, compare against its front, and pop. At end, require empty expected/actual queues and equal accepted/delivered counts.

**Example:** A FIFO scoreboard pushes written data only on legal writes and pops/compares only on legal reads.

**Common wrong answer:** “Compare the monitor output against the driver request in the same cycle.”

**Spoken answer:** “My scoreboard is transaction-based: model accepted input, queue the expected result, compare when output is accepted, and prove the queue drains. That survives variable latency and stalls.”

## Q8. How do you score out-of-order transactions?

**What the interviewer is testing:** ID-based matching and completion rules.

**Answer:** Store expected transactions in associative arrays or per-ID queues keyed by protocol identity. On response, validate the ID exists, apply the protocol's per-ID ordering rule, compare, then retire the entry. Detect duplicate, unknown, missing, and timed-out responses.

**Example:** AXI allows completion ordering rules based on IDs; AXI4-Lite has no IDs and is simpler.

**Common wrong answer:** “Sort all responses by address before comparing.” Addresses may repeat and are not transaction identities.

**Spoken answer:** “For out-of-order traffic I match by the protocol's real ID and maintain any required per-ID order. I track outstanding lifetime and flag unknown, duplicate, and missing completions.”

## Q9. How are sequence responses returned safely?

**What the interviewer is testing:** Response ID routing and object mutation.

**Answer:** The driver can create a response, copy the request ID information with `set_id_info(req)`, and send it through `put_response`/`item_done(rsp)` according to the chosen API. The sequence retrieves it with `get_response`. Reusing the request as a response must be an intentional ownership contract.

**Example:** A read sequence receives a response containing observed read data and status, correlated to the originating request.

**Common wrong answer:** “Set the response sequence ID manually to zero for every request.”

**Spoken answer:** “I preserve routing metadata from request to response and use a distinct response object when ownership could overlap. That prevents responses from reaching the wrong sequence.”

## Q10. What should happen when a scoreboard receives an unexpected output?

**What the interviewer is testing:** Failure classification and useful diagnostics.

**Answer:** Report an error/fatal with observed item, time, relevant DUT state, queue/outstanding summary, and seed; do not silently drop it. Continue only if doing so yields useful additional diagnostics without corrupting the model. Preserve the first failure for reproduction.

**Example:** If the expected queue is empty, print the output transaction and recent accepted-input history before stopping.

**Common wrong answer:** “Ignore the first unexpected output because reset pipelines can produce one.” Reset behavior must be specified and modeled.

**Spoken answer:** “An unexpected output is a conservation failure. I report enough state to reproduce it, distinguish reset-policy exceptions explicitly, and never modify the model just to make the test continue.”
