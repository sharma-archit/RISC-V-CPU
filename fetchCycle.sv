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

logic count_start; //Force PC to start incrementing after PC = 0 for only one clock cycle starting at the first rising edge after reset deasserted 

always_ff @(posedge clk) begin

    if (rst) begin

        PC_out <= '0;
        count_start <= '0;

    end
    else begin

        count_start <= '1;
        
    end
    
end

assign PC_out = count_start ? PC_in + 4 : '0;


instructionMemory instruction_memory (
    .addr(PC_out),
    .instruction(instruction),
    .dbg_wr_en(dbg_wr_en),
    .dbg_addr(dbg_addr),
    .dbg_instr(dbg_instr)
    );

endmodule