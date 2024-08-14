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
        dbg_instr = {12'b000000001100, 5'b00000, 3'b000, 5'b00001, 7'b0010011}; //immediate value = 12, source register = 0, dest reg = 1, opcode = ADDI
        #(2*CLK_PERIOD)
        dbg_wr_en = 1;
        #CLK_PERIOD
        dbg_wr_en = 0;
        #CLK_PERIOD
        dbg_addr = 8;
        dbg_instr = {12'b000000000010, 5'b00000, 3'b000, 5'b00010, 7'b0010011}; //immediate value = 2, source register = 0, dest reg = 2, opcode = ADDI
        #(2*CLK_PERIOD)
        dbg_wr_en = 1;
        #CLK_PERIOD
        dbg_wr_en = 0;
        #CLK_PERIOD
        dbg_addr = 12;
        dbg_instr = {1'b0, 6'b000000, 5'b00000, 5'b00001, 3'b101, 4'b1100, 1'b0, 7'b1100011}; //immediate value = 12, source reg 2 = 0, source reg 1 = 2, dest reg = 3, opcode = BGE
        #(2*CLK_PERIOD)
        dbg_wr_en = 1;
        #CLK_PERIOD
        dbg_wr_en = 0;
        #(1.5*CLK_PERIOD)
        rst = 0;

    end
    
    // clock generator
    always #(CLK_PERIOD/2) clk = !clk;

endmodule