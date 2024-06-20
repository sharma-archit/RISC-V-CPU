module moduleName #(parameter XLEN = 32)           
(
    input  [XLEN-1:0] PC_in,
    output [XLEN-1:0] PC_out,
    output [XLEN-1:0] instruction,
    // debug ports to write into instruction memory during testing
    input dbg_wr_en,
    input [XLEN-1:0] dbg_addr,
    output [XLEN-1:0] dbg_instr
);

assign PC_out = PC_in;

instructionMemory instruction_memory (
    .addr(PC_in),
    .instruction(instruction),
    .dbg_wr_en(dbg_wr_en),
    .dbg_addr(dbg_addr),
    .dbg_instr(dbdbg_instr)
    );

endmodule
