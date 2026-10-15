# Day 08 — UVM architecture, factory, and configuration

## Q1. Why does UVM separate objects from components?

**What the interviewer is testing:** Lifetime and hierarchy.

**Answer:** `uvm_object` represents dynamic data or behavior such as items and sequences; it has no component hierarchy or phases. `uvm_component` represents long-lived structural elements such as agents and scoreboards; it has a parent, hierarchy, phases, and reporting context.

**Example:** A transaction is created many times during run phase; one driver component is built under an agent and remains for the test.

**Common wrong answer:** “Components are objects that simply run longer.” Hierarchy and phasing are fundamental differences.

**Spoken answer:** “Objects model temporary transaction-level data; components model the persistent testbench structure. That separation lets UVM phase and configure the hierarchy while creating items cheaply as traffic flows.”

## Q2. What is the difference between `new()` and `type_id::create()`?

**What the interviewer is testing:** Factory substitution.

**Answer:** `new()` directly constructs the named type. `type_id::create()` asks the UVM factory to construct it, so a registered type or instance override may substitute a derived type. Components also need parent context during creation.

**Example:** `drv = my_driver::type_id::create("drv", this);` allows a test to override `my_driver` without editing the agent.

**Common wrong answer:** “Never use `new()` in UVM.” Internal helper objects that should not be overridden may reasonably use `new()`.

**Spoken answer:** “I use factory create at intended extension points and `new` for direct construction with no substitution requirement. Factory use is deliberate dependency injection, not a ritual.”

## Q3. What must be registered with the UVM factory?

**What the interviewer is testing:** Registration mechanics.

**Answer:** Types that will be created or overridden through the factory must be registered, typically with `uvm_object_utils` or `uvm_component_utils` and the correct parameterized variant. Registration alone does not create the object or guarantee fields are automated correctly.

**Example:** A parameterized class commonly uses `uvm_object_param_utils#(item#(WIDTH))`.

**Common wrong answer:** “The utils macro automatically calls `create()` for every instance.”

**Spoken answer:** “Registration gives the factory a wrapper for the type. I still call `type_id::create`, check parameterized macros, and test the override with factory debug output.”

## Q4. How do type and instance overrides differ?

**What the interviewer is testing:** Factory resolution scope.

**Answer:** A type override replaces every factory request for one type within the relevant factory state. An instance override applies only to matching hierarchical instance paths and has higher specificity. Paths must match the creation context and name exactly.

**Example:** Replace all base drivers with an error-aware driver using a type override, or only `env.agent1.drv` using an instance override.

**Common wrong answer:** “Instance overrides use the SystemVerilog module hierarchy.” They use UVM factory creation paths.

**Spoken answer:** “Type overrides are broad; instance overrides target a path. If an override does not take effect, I inspect the factory, actual type name, and full component/object creation context.”

## Q5. Why is `build_phase` used for construction and `connect_phase` for connections?

**What the interviewer is testing:** Phase ordering and hierarchy readiness.

**Answer:** Top-down build gives parents a chance to configure and create children. After construction is complete, bottom-up connect wires TLM ports/exports/imps and resolves peer handles. Connecting before endpoints exist creates null-handle and ordering problems.

**Example:** An environment creates its agent and scoreboard in build, then connects the monitor analysis port to scoreboard analysis export in connect.

**Common wrong answer:** “Connect phase is only style; connections in run phase work the same.”

**Spoken answer:** “Build creates the hierarchy after configuration is available; connect wires the completed hierarchy. Keeping that order makes structural errors fail early, before time-consuming stimulus starts.”

## Q6. How does `uvm_config_db` lookup work?

**What the interviewer is testing:** Context, path, field name, and type matching.

**Answer:** A set stores a typed value under context, instance pattern, and field name. A get searches from the caller's context according to UVM precedence and matching rules. Type, spelling, and hierarchical path must all match; overly broad wildcards can configure unintended instances.

**Example:** Top sets a virtual interface for `uvm_test_top.env.agent*`; the driver gets it in build and calls `uvm_fatal` on failure.

**Common wrong answer:** “Config DB is a global string dictionary.” Values are typed and lookup is hierarchical.

**Spoken answer:** “Config DB combines a typed value with scope and field name. I set from a known parent, use the narrowest useful path, get early, and fail immediately if required configuration is missing.”

## Q7. What belongs in an agent configuration object?

**What the interviewer is testing:** Reusable environment design.

**Answer:** Put policy and resources needed to construct/configure the agent: active/passive mode, virtual interface, protocol timing options, coverage enable, and selected error behavior. Avoid duplicating transaction stimulus that belongs in sequences.

**Example:** A passive AXI monitor uses the same agent config but does not create a sequencer or driver.

**Common wrong answer:** “Store every test knob as a separate config-db entry.”

**Spoken answer:** “I bundle related agent settings into one typed config object. That reduces wildcard mistakes, lets the agent validate its contract once, and makes active/passive reuse clean.”

## Q8. What does active versus passive agent mean?

**What the interviewer is testing:** Agent topology.

**Answer:** An active agent contains sequencer, driver, and monitor and participates in stimulus. A passive agent contains only observational parts such as monitor and coverage. The mode should be selected during build so unused active components are not created.

**Example:** A master VIP is active when driving a DUT slave, but passive when observing the same bus at SoC level.

**Common wrong answer:** “Passive means its monitor is disabled.”

**Spoken answer:** “Passive removes stimulus generation, not observation. I design the monitor as always useful and conditionally create driver/sequencer only for an active role.”

## Q9. Why should a test not reach deeply into components to configure fields directly?

**What the interviewer is testing:** Encapsulation and reuse.

**Answer:** Deep hierarchical assignments couple the test to one internal structure and may run before components exist. Typed config objects and factory overrides expose intentional extension points and allow the environment to validate settings locally.

**Example:** Configure `env_cfg.axi_cfg.is_active` before env build rather than writing `env.axi_agent.is_active` after construction.

**Common wrong answer:** “Direct hierarchy is simpler, so it is preferable for small benches.” It becomes fragile as soon as the agent is reused.

**Spoken answer:** “Tests should select policy, not manipulate internals. I pass typed configuration and overrides so the environment can change structure without breaking every test.”

## Q10. How would you explain the complete UVM hierarchy in an interview?

**What the interviewer is testing:** Whether you understand data flow rather than memorizing a diagram.

**Answer:** The test creates/configures an environment. The environment contains agents and checking components. In an active agent, a sequence creates items through a sequencer; the driver converts them to pin activity. The monitor independently reconstructs accepted transfers and publishes fresh items to scoreboard and coverage.

**Example:** The mini-bus repository implements test → env → agent → sequencer/driver/monitor, with monitor analysis feeding scoreboard and subscriber.

**Common wrong answer:** “The scoreboard compares what the sequence sent with what the driver returned.” That can reproduce driver intent instead of observing the DUT.

**Spoken answer:** “Stimulus flows sequence to sequencer to driver to pins. Observation flows pins to monitor to scoreboard and coverage. Keeping those paths independent is what lets the bench catch driver, DUT, and timing bugs.”
