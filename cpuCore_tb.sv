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
        dbg_instr = {1'b0, 10'b0000001100, 1'b0, 8'b0, 5'b00010, 7'b1101111}; //immediate value = 12, source reg = 2, dest reg = 2, opcode = JAL
        #(2*CLK_PERIOD)
        dbg_wr_en = 1;
        #CLK_PERIOD
        dbg_wr_en = 0;
        // #CLK_PERIOD
        // dbg_addr = 8;
        // dbg_instr = {7'b0000000, 5'b00010, 5'b00000, 3'b010, 5'b00001, 7'b0100011}; //immediate value = 1, data source reg = 2, mem base addr = 0, STORE WORD, opcode = STORE
        // #(2*CLK_PERIOD)
        // dbg_wr_en = 1;
        // #CLK_PERIOD
        // dbg_wr_en = 0;
        // #CLK_PERIOD
        // dbg_addr = 24;
        // dbg_instr = {12'b000000000001, 5'b00000, 3'b010, 5'b00011, 7'b0000011}; //immediate value = 1, base register = 0, LOAD WORD, dest reg = 3, opcode = LOAD
        // #(2*CLK_PERIOD)
        // dbg_wr_en = 1;
        // #CLK_PERIOD
        // dbg_wr_en = 0;
        #CLK_PERIOD
        rst = 0;

    end
    
    // clock generator
    always #(CLK_PERIOD/2) clk = !clk;

endmodule