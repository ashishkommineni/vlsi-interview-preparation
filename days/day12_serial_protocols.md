# Day 12 — SPI, UART, and I²C

## Q1. How do CPOL and CPHA define an SPI mode?

**What the interviewer is testing:** Edge-level SPI timing.

**Answer:** CPOL defines the idle SCLK level. CPHA defines whether data is sampled on the first active edge or shifted on that edge and sampled on the second. Modes 0–3 are the four CPOL/CPHA combinations, and both endpoints must agree.

**Example:** For CPHA=0 the first transmit bit must be valid before the first sampling edge; CPHA=1 allows the first edge to launch it.

**Common wrong answer:** “CPHA selects rising versus falling sampling by itself.” The edge also depends on CPOL.

**Spoken answer:** “CPOL gives clock idle polarity; CPHA gives first-edge versus second-edge sampling. I derive launch/sample edges from both and verify the first and final bit carefully.”

## Q2. Why is SPI considered full duplex?

**What the interviewer is testing:** Simultaneous shift behavior.

**Answer:** On each clock bit period, MOSI carries one master-to-slave bit while MISO carries one slave-to-master bit. Both shift registers progress during the same transfer even if one direction is dummy data.

**Example:** Sending an 8-bit command simultaneously receives an 8-bit response/dummy byte.

**Common wrong answer:** “Full duplex means SPI has independent transmit and receive clocks.”

**Spoken answer:** “SPI shifts MOSI and MISO at the same time on one SCLK. A transaction always exchanges bits in both directions, though one side may ignore or send dummy data.”

## Q3. What should be checked around SPI chip select?

**What the interviewer is testing:** Framing and multi-slave safety.

**Answer:** Assert exactly the intended active-low CS, meet setup before the first sampling edge, keep it active for the full word/frame, deassert after the final required edge, and return SCLK to CPOL. Other targets must remain deselected.

**Example:** Assert `$onehot0(~cs_n)` and cover every selected target in every supported mode.

**Common wrong answer:** “Only SCLK edges matter; CS can change with the final edge.”

**Spoken answer:** “CS frames the transfer and selects ownership. I verify one-hot selection, timing around first/last edges, and idle clock restoration.”

## Q4. What fields make up a UART frame?

**What the interviewer is testing:** Asynchronous serial framing.

**Answer:** The line idles high, then a low start bit, usually LSB-first data bits, optional parity, and one or more high stop bits. Both endpoints agree on baud rate, data length, parity, and stop configuration.

**Example:** 8-N-1 is one start, eight data bits, no parity, and one stop bit.

**Common wrong answer:** “UART transmits MSB first like SPI.”

**Spoken answer:** “UART uses a start edge to establish timing, then samples LSB-first data, optional parity, and stop. Because there is no shared clock, sampling point and baud tolerance are central.”

## Q5. Why does a UART receiver sample near the bit center?

**What the interviewer is testing:** Jitter and baud mismatch tolerance.

**Answer:** The start edge is asynchronous to the receiver clock. Waiting half a bit validates the start near its center, then sampling at full-bit intervals maximizes distance from transitions. Oversampling improves start detection and noise tolerance.

**Example:** At 16× oversampling, detect a falling edge, verify around count 8, then sample subsequent bits every 16 ticks.

**Common wrong answer:** “Sample immediately on every detected edge.” Data bits may have no edges.

**Spoken answer:** “The receiver recovers timing from the start edge and samples in each bit's eye center. That gives margin for clock mismatch and edge jitter.”

## Q6. How are UART parity and framing errors detected?

**What the interviewer is testing:** Negative-path verification.

**Answer:** Recompute expected parity from received data and compare the parity bit; a mismatch raises parity error. Sample the stop bit and raise framing error if it is low. Errors must be associated with the correct received word and clear according to the interface contract.

**Example:** Inject one flipped parity bit and one forced-low stop bit in separate frames; check both data and error flags.

**Common wrong answer:** “A parity error means the receiver should discard the byte automatically.” The specification decides data/flag behavior.

**Spoken answer:** “I verify error detection independently from payload reception and define whether bad data is reported, discarded, or flagged. Negative injection is essential; clean loopback cannot prove it.”

## Q7. Why are I²C SDA and SCL open-drain?

**What the interviewer is testing:** Electrical behavior and arbitration.

**Answer:** Participants either pull the line low or release it; pull-ups create high. This wired-AND behavior lets multiple devices share lines safely, supports ACK/arbitration, and allows a target to stretch SCL. Driving a strong one would cause contention.

**Example:** RTL outputs `sda_drive_low`; the top models the shared line with a pull-up and resolved net.

**Common wrong answer:** “Open-drain means the signal is tri-stated only during reset.”

**Spoken answer:** “I²C never actively drives high. Devices pull low or release, which enables shared-bus arbitration, ACK, and clock stretching without push-pull contention.”

## Q8. What are I²C START, repeated START, and STOP conditions?

**What the interviewer is testing:** Bus conditions relative to SCL.

**Answer:** START is SDA falling while SCL is high; STOP is SDA rising while SCL is high. A repeated START issues another START without a preceding STOP, keeping bus ownership while changing direction/address phase.

**Example:** A register read often writes the register index, issues repeated START, then reads data.

**Common wrong answer:** “START and STOP are just normal data-bit transitions.” Data should be stable while SCL is high except these conditions.

**Spoken answer:** “START and STOP are special SDA transitions while SCL is high. My monitor distinguishes them from data and handles repeated START as a new address phase without bus release.”

## Q9. How does I²C ACK/NACK timing work?

**What the interviewer is testing:** Ninth-clock ownership.

**Answer:** After eight data bits, the transmitter releases SDA for the ninth clock. The receiver pulls SDA low for ACK or leaves it high for NACK. The master must release rather than drive the response and sample it while SCL is high.

**Example:** Test address NACK and data NACK separately because they imply different progress through the transaction.

**Common wrong answer:** “The sender drives zero to request an ACK.”

**Spoken answer:** “ACK is receiver-owned on the ninth clock. The transmitter releases SDA, samples low for ACK or high for NACK, and responds according to which byte was rejected.”

## Q10. How would you build trustworthy serial-protocol monitors?

**What the interviewer is testing:** Pin-level reconstruction.

**Answer:** Observe real pins and protocol edges, maintain a framing state machine, shift bits in specified order, and publish only completed transfers with mode/status metadata. Do not shortcut internal DUT state. Add watchdogs for incomplete frames and reset rules.

**Example:** An SPI monitor derives sample edges from CPOL/CPHA; UART derives bit centers from start; I²C decodes START/address/ACK/data/STOP on resolved lines.

**Common wrong answer:** “Sample all serial pins on the system clock and group every eight samples.”

**Spoken answer:** “A serial monitor is a protocol decoder. It follows the real edge rules and bus ownership, then publishes a transaction only when framing is complete.”
