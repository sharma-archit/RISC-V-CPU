module reg_file (
    input clk,
    input rst,
    input write_en,
    input read_en1,
    input read_en2,
    input [5:0] read_addr1,
    input [5:0] read_addr2,
    input [5:0] write_addr,
    input [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,
);

//Registor data storage
logic [31:0][31:0] cpu_register;

always_ff @(posedge clk) begin

//Reset reg file
    if (rst == 1) begin

        for (int i = 0; i < 32; i++) begin

            cpu_register[i] <= '0;

        end

        read_data1 = '0;
        read_data2 = '0;
        
    end
    //Check if read or write action
    else if (rst == 0) begin

        if (write_en) begin 

            cpu_register[write_addr] <= write_data;

        end
        if (read_en1) begin 

            read_data1 <= cpu_register[read_addr1];

        end
        if (read_en2) begin 

            read_data2 <= cpu_register[read_addr2];

        end

    end
    
end

endmodule