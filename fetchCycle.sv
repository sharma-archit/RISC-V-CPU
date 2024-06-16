module moduleName #(parameter XLEN = 32;)           
(
    input  [XLEN-1:0] PC_in,
    output [XLEN-1:0] PC_out,
    output [XLEN-1:0] instruction
);

assign PC_out = PC_in;

instructionMemory instruction_memory (
    .addr(PC_in),
    .instruction(instruction)
                             );

endmodule
