# VLSI Design and Verification Interview Preparation

A fourteen-day, question-first revision path for entry-level RTL design and
design-verification interviews. Every study day contains exactly ten questions,
but the goal is not to memorize 140 definitions. The goal is to explain behavior
at a clock edge, connect it to a real verification problem, and defend the answer
when the interviewer asks a follow-up.

## What makes this bank practical

Each question includes:

- **What the interviewer is testing** — the skill behind the wording;
- **Answer** — the precise technical explanation;
- **Example** — code, protocol timing, or a concrete scenario;
- **Common wrong answer** — a tempting but incomplete response;
- **Spoken answer** — a short version that sounds natural in an interview.

The questions are paired with executable work in these repositories:

- [14 Days of RTL](https://github.com/ashishkommineni/7-days-of-rtl)
- [SystemVerilog DV Learning Lab](https://github.com/ashishkommineni/systemverilog-dv-learning-lab)
- [UVM Verification Learning Series](https://github.com/ashishkommineni/uvm-verification-learning-series)
- the AXI4-Lite, AHB-Lite, APB3, SPI, UART, I²C, synchronous-FIFO, and
  asynchronous-FIFO verification repositories on this profile.

## Fourteen-day plan

| Day | Focus | Outcome |
|---:|---|---|
| 01 | Digital combinational and sequential foundations | Reason about logic, storage, and arithmetic |
| 02 | Timing, reset, metastability, and CDC | Explain failures that simulation alone cannot prove away |
| 03 | Verilog/SystemVerilog RTL semantics | Write race-free, synthesizable RTL |
| 04 | FSMs, pipelines, and ready/valid | Reason cycle by cycle under stalls |
| 05 | SystemVerilog types, arrays, interfaces, and packages | Choose safe abstractions |
| 06 | OOP, randomization, constraints, and concurrency | Build controlled testbench stimulus |
| 07 | SVA and functional coverage | Turn requirements into measurable checks |
| 08 | UVM architecture, factory, and configuration | Explain component construction and ownership |
| 09 | UVM sequences, monitors, TLM, and scoreboards | Trace one transaction end to end |
| 10 | UVM RAL, reset, callbacks, and regression debug | Handle realistic environment problems |
| 11 | AXI4-Lite, AHB-Lite, and APB | Compare AMBA timing and verification traps |
| 12 | SPI, UART, and I²C | Verify pin-level serial behavior |
| 13 | Synchronous and asynchronous FIFOs | Prove ordering, boundaries, and CDC safety |
| 14 | Integration, debug, sign-off, and project defense | Present engineering evidence clearly |

Start at [the study method](docs/study_method.md), then open the matching file
under [`days/`](days). One day is designed for a focused 60–90 minute session.

## Evidence rule

An interview answer must separate three things:

1. what the specification requires;
2. what the implementation intends to do;
3. what the available simulation, assertions, coverage, lint, CDC, or formal
   evidence actually proves.

This repository never treats compilation as functional proof and never quotes a
coverage percentage without a saved run from the named simulator.

## Automated structure check

```bash
make check
```

The check verifies that all fourteen day files exist and each contains exactly
ten numbered questions with the required explanation fields.

## License

MIT — see [LICENSE](LICENSE).
