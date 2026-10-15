# Day 05 — SystemVerilog types, arrays, interfaces, and packages

## Q1. What is the difference between two-state and four-state types?

**What the interviewer is testing:** X/Z semantics and performance tradeoffs.

**Answer:** Four-state types represent `0`, `1`, `X`, and `Z`, which exposes unknown initialization, contention, and tri-state behavior. Two-state types collapse unknowns to 0/1 and can simulate faster. Use four-state signals at RTL and protocol boundaries unless unknown information is intentionally irrelevant.

**Example:** `logic` is four-state; `bit` is two-state. A two-state scoreboard key can be fine, but a two-state sampled reset may hide an X bug.

**Common wrong answer:** “`bit` and `logic` differ only in memory usage.”

**Spoken answer:** “Four-state data preserves X and Z information; two-state data does not. I use four-state types where unknown behavior is meaningful and two-state types for abstract testbench data only when collapsing X is safe.”

## Q2. How do packed and unpacked arrays differ?

**What the interviewer is testing:** Layout, slicing, and port compatibility.

**Answer:** Dimensions before the variable name are packed into one vector and support arithmetic and bit slicing. Dimensions after the name create arrays of elements. A memory is typically an unpacked array of packed words.

**Example:** `logic [31:0] mem [0:255];` is 256 unpacked elements, each a packed 32-bit word.

**Common wrong answer:** “Packed means contiguous physical memory after synthesis.” It is primarily a language layout and operation rule.

**Spoken answer:** “Packed dimensions form one bit vector; unpacked dimensions form a collection of elements. I check both sides of a port carefully because the same numbers in a different position describe a different type.”

## Q3. When would you use a dynamic array, queue, or associative array?

**What the interviewer is testing:** Testbench data-structure selection.

**Answer:** A dynamic array has runtime size but contiguous integer indexing. A queue supports efficient ordered push/pop behavior. An associative array is sparse and indexed by an integral/string key. Choose from access pattern and ownership, not habit.

**Example:** Use a queue for in-order expected transactions, and an associative array keyed by transaction ID for out-of-order AXI responses.

**Common wrong answer:** “A queue is always the best scoreboard container.”

**Spoken answer:** “I use queues for ordered streams, associative arrays for sparse or ID-based matching, and dynamic arrays when the collection has a known runtime size and indexed processing.”

## Q4. What is a virtual interface?

**What the interviewer is testing:** Connecting class-based code to static signals.

**Answer:** Classes cannot directly contain module/interface hierarchy, so a virtual interface is a handle to an elaborated interface instance. The top puts it into configuration; the driver and monitor retrieve it and use clocking blocks/modports to access pins.

**Example:** `uvm_config_db#(virtual bus_if)::set(null, "uvm_test_top.env.agent*", "vif", bus_if_inst);` followed by a checked `get` in build phase.

**Common wrong answer:** “The virtual interface creates a new interface object.”

**Spoken answer:** “The interface instance is static hardware-side structure; the virtual interface is just the class-side handle to it. I set it from top, get it early, fail on null, and restrict access with a modport.”

## Q5. What problem do clocking blocks solve?

**What the interviewer is testing:** Race-free drive/sample timing.

**Answer:** Clocking blocks define a clock event, signal directions, and sampling/driving skews. They separate testbench operations from DUT scheduler races and document when values are observed. They do not generate the clock or replace the interface.

**Example:** A driver uses `vif.drv_cb.req <= tr.req;` and a monitor samples `vif.mon_cb.ready` through its declared input skew.

**Common wrong answer:** “A clocking block is only shorthand for `@(posedge clk)`.”

**Spoken answer:** “A clocking block is the timing contract between testbench and pins. It states what I drive, what I sample, and with what skew, so the environment is deterministic across simulators.”

## Q6. What is the purpose of a modport?

**What the interviewer is testing:** Interface role separation.

**Answer:** A modport exposes a role-specific view of interface signals and tasks, including directions and clocking blocks. It prevents a monitor from accidentally driving a signal and makes module connections self-documenting.

**Example:** Define `modport dut(input req, ..., output ready)` and `modport monitor(clocking mon_cb)`.

**Common wrong answer:** “Modport directions synthesize hardware direction changes.”

**Spoken answer:** “A modport restricts how one participant sees an interface. I use separate DUT, driver, and monitor views so ownership mistakes become compile-time errors.”

## Q7. Why use packages, and what package dependency mistake is common?

**What the interviewer is testing:** Compilation organization and namespace discipline.

**Answer:** Packages hold shared types, parameters, functions, and classes without hierarchy. They must be compiled before users, and wildcard imports can create name collisions or hide ownership. Packages should not depend cyclically on one another.

**Example:** Put transaction enums/types in a protocol package; import selected names with `pkg::type_t` or controlled `import`.

**Common wrong answer:** “A package can contain an interface instance shared by every test.”

**Spoken answer:** “Packages organize shared declarations at compile scope. I keep dependencies one-directional, compile them first, and qualify important names so it is clear which package owns a type.”

## Q8. What is a tagged union, and why can it be safer?

**What the interviewer is testing:** Type-safe variant modeling.

**Answer:** A tagged union stores one of several member types together with information about which member is active. Access to the wrong member can be diagnosed, unlike a plain union where bits are reinterpreted without an active-type contract.

**Example:** A request may carry either a read payload or a write payload, with the tag identifying the legal view.

**Common wrong answer:** “Tagged unions are required for all protocol transactions.” Classes and enums may be clearer in many testbenches.

**Spoken answer:** “A tagged union models mutually exclusive representations and carries the active choice, so it is safer than blindly reinterpreting the same bits. I use it when the variant itself is part of the data contract.”

## Q9. What does `typedef` improve besides shorter syntax?

**What the interviewer is testing:** Type intent and parameterized maintainability.

**Answer:** A typedef gives a semantic name to width, signedness, array layout, or enum type. It keeps interfaces consistent and allows type checking to catch accidental mixing. It also centralizes parameter-derived type definitions.

**Example:** `typedef logic [ADDR_W-1:0] addr_t;` and `typedef enum logic [1:0] {IDLE, BUSY, ERR} state_t;`.

**Common wrong answer:** “Typedef is only a text macro.” It creates a language type alias, unlike textual substitution.

**Spoken answer:** “A typedef names the contract, not just the bits. It makes signedness and layout consistent across RTL and testbench and lets enums and structs carry stronger intent than raw vectors.”

## Q10. When should a struct be packed?

**What the interviewer is testing:** Transaction layout versus abstract data.

**Answer:** Use a packed struct when fields must form one contiguous bit vector for ports, slicing, comparison, or serialization. Use an unpacked struct when members are an abstract collection and may include unpacked data. Packed member order defines bit positions and must match the protocol.

**Example:** A packed request `{opcode, address, data}` can be registered or sent through a FIFO as one vector.

**Common wrong answer:** “Packed structs automatically remove padding in software-compatible layouts.” HDL packing rules must still be matched explicitly to any external ABI.

**Spoken answer:** “I pack a struct when the record must behave like one vector in hardware. I document field order and widths because a clean type name does not remove the need to verify the actual bit layout.”
