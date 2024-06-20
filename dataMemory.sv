module dataMemory #(parameter XLEN = 32)
(
    input  read_enable,
    input  write_enable,
    input  [XLEN - 1:0] read_addr,
    input  [XLEN - 1:0] write_addr,
    input  [XLEN - 1:0] write_data,
    output logic [XLEN - 1:0] read_data
);

logic [2^(XLEN - 1) - 1:0][7:0] data_memory; // data memory is half the address-space

always_comb begin

    if (read_enable == 1) begin
    
        for (int i = 0; i < (XLEN/8) ; i++) begin // Transfer 8 bit data sets in 4 steps, totalling 32 bits

            read_data[8*i + 7:8*i] = data_memory[read_addr + i];

        end

    end
    else begin 

        read_data = '0;

    end 

    if (write_enable == 1) begin

        read_data = '0;
        for (int i = 0; i < (XLEN/8) ; i++) begin // Transfer 8 bit data sets in 4 steps, totalling 32 bits

            data_memory[write_addr + i] = write_data[8*i + 7:8*i];

        end

    end
    else begin

        read_data = '0;

    end
    
end

endmodule