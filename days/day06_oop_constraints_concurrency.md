# Day 06 — OOP, randomization, constraints, and concurrency

## Q1. What is the difference between an object and an object handle?

**What the interviewer is testing:** Aliasing and lifetime.

**Answer:** `new` creates an object; a class variable holds a handle to it. Assigning one handle to another does not copy fields—it makes both handles refer to the same object. Mutating through either handle changes the same instance.

**Example:** `b = a; b.data = 5;` also makes `a.data` read 5 unless a separate object was cloned/copied.

**Common wrong answer:** “Class assignment performs a shallow copy.” It copies only the handle.

**Spoken answer:** “A class variable is a reference-like handle. Handle assignment aliases the same object, so I use explicit copy or clone rules when ownership must be independent.”

## Q2. What is shallow copy versus deep copy?

**What the interviewer is testing:** Nested object ownership.

**Answer:** A shallow copy duplicates scalar fields but copies nested handles, so sub-objects remain shared. A deep copy creates independent nested objects and recursively copies their meaningful state. The correct choice depends on ownership and immutability.

**Example:** A packet copy that shares its payload object can be corrupted if the generator later edits that payload.

**Common wrong answer:** “`clone()` is always automatically deep.” The class's copy implementation decides nested behavior.

**Spoken answer:** “I define copy depth from ownership. If the receiver may mutate nested data, I deep-copy it; if data is immutable and shared intentionally, I document that contract.”

## Q3. What is polymorphism in SystemVerilog?

**What the interviewer is testing:** Base handles, virtual methods, and extensibility.

**Answer:** A base-class handle can refer to a derived object. Calls to virtual methods dispatch to the derived override, allowing behavior to change without changing the caller. A cast is needed to access derived-only fields.

**Example:** A base transaction handle may point to an error-injection transaction whose virtual `describe()` method prints extra error metadata.

**Common wrong answer:** “Inheritance alone guarantees polymorphic method dispatch.” The relevant method must be virtual.

**Spoken answer:** “Polymorphism means code can use a base contract while the actual derived object supplies specialized behavior. I use virtual methods for that behavior and avoid unnecessary downcasts.”

## Q4. Why must every `randomize()` return value be checked?

**What the interviewer is testing:** Constraint failure handling.

**Answer:** Randomization returns zero when enabled constraints have no solution. Continuing may reuse stale fields and create a test that appears random but violates scenario intent. A failed solve should be a clear error or an expected negative-test result checked explicitly.

**Example:** `if (!tr.randomize() with { address == 'h3; address[1:0] == 0; })` must fail because the constraints conflict.

**Common wrong answer:** “The simulator picks the closest legal value.”

**Spoken answer:** “Constraint solving is not guaranteed to succeed. I check every call, print the seed and object state, and treat unexpected failure as a testbench bug.”

## Q5. What is the difference between `:=` and `:/` in a `dist` constraint?

**What the interviewer is testing:** Distribution semantics.

**Answer:** With `:=`, the stated weight applies to each value in a range. With `:/`, the stated weight is divided across the whole range. Neither guarantees exact percentages in a finite sample.

**Example:** `[0:3] := 2` gives each of four values weight 2; `[0:3] :/ 2` gives the entire range total weight 2.

**Common wrong answer:** “Both forms assign the same probability to a range.”

**Spoken answer:** “Colon-equals weights each value; colon-slash weights the range as a group. I measure the observed distribution with coverage instead of assuming weights prove it.”

## Q6. What does `solve ... before` do?

**What the interviewer is testing:** Legal set versus probability distribution.

**Answer:** It influences solve ordering and therefore distribution when variables are related; it does not change the set of legal solutions and cannot resolve contradictory constraints. Use it only when the desired probabilistic intent depends on choosing one variable first.

**Example:** Choose an opcode first, then choose a length from the legal range for that opcode so common opcodes are not distorted by having more length solutions.

**Common wrong answer:** “`solve before` gives one constraint higher priority.”

**Spoken answer:** “Solve-before affects selection order, not legality or hard-constraint priority. I use it to control distributions and still check coverage to see what was generated.”

## Q7. What is a soft constraint?

**What the interviewer is testing:** Reusable defaults versus scenario overrides.

**Answer:** A soft constraint supplies a default that may be dropped when a conflicting hard constraint is added, often inline by a test. It makes base items reusable without forcing tests to disable named constraints for normal overrides.

**Example:** `soft length == 4;` allows a test to randomize with `length == 16` while all other legality constraints remain active.

**Common wrong answer:** “Soft means the solver may ignore it randomly.” It is used unless a conflict requires removal.

**Spoken answer:** “I use soft constraints for defaults and hard constraints for specification legality. A test can override the default, but it cannot silently violate the protocol contract.”

## Q8. How do `fork...join`, `join_any`, and `join_none` differ?

**What the interviewer is testing:** Process lifetime and cleanup.

**Answer:** `join` waits for all children, `join_any` returns after one child finishes while others continue, and `join_none` returns immediately. Outstanding children must be deliberately terminated or allowed to complete; careless `disable fork` can kill unrelated descendant work.

**Example:** A timeout wrapper uses `join_any`, then disables only the named fork containing the operation and timeout threads.

**Common wrong answer:** “`join_any` automatically cancels the remaining processes.”

**Spoken answer:** “The join keyword controls when the parent continues, not automatically what happens to children. I use named forks and explicit cleanup so timeout logic cannot leak or kill unrelated processes.”

## Q9. When would you use an event, semaphore, or mailbox?

**What the interviewer is testing:** IPC semantics.

**Answer:** An event signals occurrence but carries no payload and can be missed if waiting begins late. A semaphore controls access to a limited resource through keys. A mailbox transfers queued messages, optionally with a bounded capacity and typed payload.

**Example:** Use a semaphore for two shared bus slots, a mailbox for generator-to-driver transactions, and an event for a simple phase notification whose timing is controlled.

**Common wrong answer:** “An event remembers every trigger until consumed.”

**Spoken answer:** “I choose by contract: occurrence, resource count, or queued data. If loss is unacceptable, I avoid a bare event and use a persistent state or mailbox/handshake.”

## Q10. What is the danger of publishing the same mutable transaction handle repeatedly?

**What the interviewer is testing:** Analysis-port ownership and temporal aliasing.

**Answer:** Subscribers may retain the handle, so reusing and modifying it changes their previously observed transaction. A monitor should create a fresh object per completed transfer or clone before publication. The publication time should be after all semantic fields are final.

**Example:** Reusing one monitor item can make every scoreboard queue entry appear to contain the last bus transaction.

**Common wrong answer:** “`analysis_port.write(tr)` automatically copies `tr`.”

**Spoken answer:** “Analysis ports pass handles. I publish a fresh or intentionally cloned immutable transaction and never modify it afterward, so subscribers see stable historical data.”
