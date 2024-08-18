# 32-Bit RISC-V CPU

This is a custom design of a 32-bit CPU based on RISC-V. The design implements the RV32I base instruction set using the Harvard architecture.
The CPU is a 4-stage pipelined processor with the Memory Access and Writeback stages merged into one pipeline cycle but denoted as separate stages:

Fetch
- The Fetch stage contains the instruction memory and the program counter.
- The instruction memory stores instructions for the system to complete, and the program counter simply keeps track of which instruction to work on at the current moment.

Decode
- The Decode stage contains the instruction decoder, register file (RF), jump branch logic (JBL), and data hazard mitigation logic (DHML).
- The instruction decoder generates the control signals for the datapath. The RF stores recent data. The JBL looks at the current instruction to determine if it is a jump instruction or branch instruction, and to take it or not. The DHML looks at the current and previous two instructions to determine if there is a data hazard. If action is required it freezes pipeline stages and/or forwards data.

Execute
- The Execute stage contains the arithmetic logic unit (ALU).
- The ALU computes arithmetic and bitwise logic operations.

Memory Access
- The Memory Access stage contains the data memory.
- The data memory stores specific data from the register file, and loads data from the data memory to the RF

Writeback
- The Writeback stage contains a mux to the register file.
- The mux in the Writeback stage determines which data to pass into the RF.

![RISCV CPU µArchitecture](https://github.com/user-attachments/assets/0b1ec73a-0e41-4508-8529-d7dde3b9d479)
