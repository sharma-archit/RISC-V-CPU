module instructionMemory #(parameter XLEN = 32)
(
    input [XLEN - 1:0] addr,
    //output logic [XLEN - 1] instruction,
    output logic [3:0][7:0] instruction, //Hack to make this work in vivado

    // debug ports to write into instruction memory during testing
    input dbg_wr_en,
    input [XLEN-1:0] dbg_addr,
    //input [XLEN-1:0] dbg_instr
    input [3:0][7:0] dbg_instr
);

logic [2^(XLEN - 1)-1:0][7:0] instruction_memory = '0; // instruction memory is half the address-space

always_comb begin : read

    for (int i=0; i < (XLEN/8); i++) begin //Transfer 8 bit data sets in 4 steps, totalling 32 bits

        //instruction[8*i + 7:8*i] = instruction_memory[addr + i];
        instruction[i] = instruction_memory[addr + i]; //Hack to make this work in vivado

    end

end : read

always_comb begin : dbg_write
    
    if (dbg_wr_en) begin
        
        for (int i=0; i < (XLEN/8); i++) begin // write 8 bit data sets in 4 steps, totalling 32 bits

        //instruction_memory[dbg_addr + i] = dbg_instr[8*i + 7:8*i];
        instruction_memory[dbg_addr + i] = dbg_instr[i];

        end

    end

end : dbg_write

endmodule