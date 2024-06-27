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
        dbg_addr = 4;
        dbg_instr = {12'b111001110101, 5'b00001, 3'b000, 5'b00010, 7'b0010011};
        #(2*CLK_PERIOD)
        dbg_wr_en = 1;
        #CLK_PERIOD
        dbg_wr_en = 0;
        #CLK_PERIOD
        dbg_addr = 8;
        dbg_instr = {12'b010101011001, 5'b00010, 3'b000, 5'b00011, 7'b0010011};
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