# RISC-V CPU (WIP)

This is a custom design of a CPU based on RISC-V. The design implements the RV32I base instruction set using the Harvard architecture.
The CPU is a 5-stage pipelined processor with the stages: 

Fetch
- The Fetch stage contains the instruction memory and the program counter.

Decode
- The Decode stage contains the instruction decoder, register file, jump branch logic, and data hazard mitigation logic.

Execute
- The Execute stage contains the arithmetic logic unit.

Memory Access
- The Memory Access stage contains the data memory.

Writeback
- The Writeback stage contains a mux to the register file.

![RISCV CPU µArchitecture  drawio](https://github.com/user-attachments/assets/6a806403-03e5-4bf4-ac10-359d1ab195e3)


Currently, the initial design is complete. The project is now in the simulation phase.

