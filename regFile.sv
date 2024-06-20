module regFile #(parameter ADDR_SIZE = 6,
                  parameter XLEN = 32)
(
    input clk,
    input rst,
    input write_enable,
    input read_enable1,
    input read_enable2,
    input [ADDR_SIZE - 1:0] read_addr1,
    input [ADDR_SIZE - 1:0] read_addr2,
    input [ADDR_SIZE - 1:0] write_addr,
    input [XLEN - 1:0]      write_data,
    output logic [XLEN - 1:0] read_data1,
    output logic [XLEN - 1:0] read_data2
);

//Register data storage
localparam NUM_REGISTERS = 32; // Number of registers in the register file
logic [NUM_REGISTERS - 1:0][XLEN - 1:0] cpu_register;

assign cpu_register[0] = '0; // register x0 hardwired to 0

always_ff @(posedge clk) begin

    //Reset reg file
    if (rst == 1) begin

        for (int i = 1; i < NUM_REGISTERS; i++) begin

            cpu_register[i] <= '0;

        end

        read_data1 = '0;
        read_data2 = '0;
        
    end
    //Check if read or write action
    else if (rst == 0) begin

        if (write_enable) begin
            
            if (write_addr != 0) begin // register x0 can not be written to
                cpu_register[write_addr] <= write_data;
            end

        end
        if (read_enable1) begin

            read_data1 <= cpu_register[read_addr1];

        end
        if (read_enable2) begin

            read_data2 <= cpu_register[read_addr2];

        end
        else begin
            
            read_data1 = '0;
            read_data2 = '0;
        end

    end
    
end

endmodule