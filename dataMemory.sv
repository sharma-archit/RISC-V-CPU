module moduleName (
    input  read_en,
    input  write_en,
    input  [31:0] read_addr,
    input  [31:0] write_addr,
    input  [31:0] write_data,
    output [31:0] read_data
);

logic [2^31-1:0][7:0] data_memory; // data memory is half the address-space

always_comb begin

    if (read_en == 1) begin
    
        for (int i=0; i < 4 ; i++) begin //Transfer 8 bit data sets in 4 steps, totalling 32 bits

            read_data[8*i+7:8*i] = data_memory[read_addr + i];

        end
    end
    if (write_en == 1) begin
        
        for (int i=0; i < 4 ; i++) begin //Transfer 8 bit data sets in 4 steps, totalling 32 bits

            data_memory[write_addr + i] = write_data[8*i+7:8*i];

        end
    end
    
end

endmodule