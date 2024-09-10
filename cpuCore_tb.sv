module cpuCore_tb #( parameter XLEN = 32)();

logic clk = 0;
logic rst;
logic dbg_wr_en;
logic [XLEN-1:0] dbg_addr;
logic [XLEN-1:0] dbg_instr;

const time CLK_PERIOD = 8;

cpuCore cpu_core(.*);

    initial begin

    rst = 1;
    dbg_wr_en = 0;
    dbg_addr = 0;
    dbg_instr = 32'b00000000000000000000000010010011;
    #(2*CLK_PERIOD)
    dbg_wr_en = 1;
    #CLK_PERIOD
    dbg_wr_en = 0;
    #CLK_PERIOD
    dbg_addr = 4;
    dbg_instr = 32'b00000000110000000000000010010011;
    #(2*CLK_PERIOD)
    dbg_wr_en = 1;
    #CLK_PERIOD
    dbg_wr_en = 0;
    #CLK_PERIOD
    dbg_addr = 8;
    dbg_instr = 32'b00000000000100000010000010100011;
    #(2*CLK_PERIOD)
    dbg_wr_en = 1;
    #CLK_PERIOD
    dbg_wr_en = 0;
    #CLK_PERIOD
    rst = 0;

    end
    
    // clock generator
    always #(CLK_PERIOD/2) clk = !clk;

endmodule