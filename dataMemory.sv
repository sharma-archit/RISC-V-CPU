module dataMemory #(parameter XLEN = 32
                    parameter BYTE_SIZE = 8
                    parameter MEM_STEPS = 4)
(
    input  read_enable,
    input  write_enable,
    input  [XLEN - 1:0] read_addr,
    input  [XLEN - 1:0] write_addr,
    //input  [XLEN - 1:0] write_data,
    input [3:0][7:0] write_data,
    //output logic [XLEN - 1:0] read_data
    output logic [3:0][7:0] read_data
);

logic [2^(XLEN - 1) - 1:0][7:0] data_memory; // data memory is half the address-space
logic [XLEN - 1:0] memory_read_addr;
logic [XLEN - 1:0] memory_write_addr;

always_comb begin

    read_data = '0;

    if (read_enable == 1) begin

        memory_read_addr = MEM_STEPS * read_addr - MEM_STEPS;
    
        for (int i = 0; i < (XLEN/BYTE_SIZE) ; i++) begin // Transfer 8 bit data sets in 4 steps, totalling 32 bits

            read_data[i] = data_memory[memory_read_addr + i];

        end

    end

    if (write_enable == 1) begin

        memory_write_addr = MEM_STEPS * write_addr - MEM_STEPS;

        for (int i = 0; i < (XLEN/BYTE_SIZE) ; i++) begin // Transfer 8 bit data sets in 4 steps, totalling 32 bits

            data_memory[memory_write_addr + i] = write_data[i];

        end

    end
    
end

endmodule