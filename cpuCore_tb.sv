module cpuCore_tb #( parameter XLEN = 32)();

logic clk = 0;
logic rst;
logic dbg_wr_en;
logic [XLEN-1:0] dbg_addr;
logic [XLEN-1:0] dbg_instr;

const time CLK_PERIOD = 8;

cpuCore cpu_core(.*);

    initial begin

    end
    
    // clock generator
    always #(CLK_PERIOD/2) clk = !clk;

endmodule