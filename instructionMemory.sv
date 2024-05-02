module instructionMemory #(parameter XLEN = 32;)
(
    input [XLEN - 1:0] addr,
    output logic [XLEN - 1:0] instruction
);

logic [2^(XLEN - 1)-1:0][7:0] intruction_memory; // instruction memory is half the address-space

always_comb begin

    for (int i=0; i < (XLEN/8) ; i++) begin //Transfer 8 bit data sets in 4 steps, totalling 32 bits

        instruction[8*i + 7:8*i] = instruction_memory[addr + i];

    end

end

endmodule