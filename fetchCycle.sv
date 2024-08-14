module fetchCycle #(parameter XLEN = 32)           
(   
    input clk,
    input rst,
    input  [XLEN-1:0] PC_in,
    output logic [XLEN-1:0] PC_out,
    output [XLEN-1:0] instruction,
    // debug ports to write into instruction memory during testing
    input dbg_wr_en,
    input [XLEN-1:0] dbg_addr,
    input [XLEN-1:0] dbg_instr
);

// assign PC_out = rst ? 0 : PC_in + 4;

always_ff @(posedge clk) begin 
    if (rst) begin
        PC_out <= '0;
    end
    else begin
        PC_out <= PC_in + 4;
    end
end

instructionMemory instruction_memory (
    .addr(PC_in),
    .instruction(instruction),
    .dbg_wr_en(dbg_wr_en),
    .dbg_addr(dbg_addr),
    .dbg_instr(dbg_instr)
    );

endmodule
