module signExtender #(parameter INPUT_SIZE=12;
                      parameter XLEN=32;)
(input enable,
 input [INPUT_SIZE - 1:0]  data_in,
 output [RV32I - 1:0] data_out
);

logic [RV32I - 1:0] extended_data;

    always_comb begin

        if (enable) begin

            extended_data = {(RV32I - INPUT_SIZE){data_in[INPUT_SIZE - 1]}, data_in};

        end
        else begin
            
            extended_data = '0;
            
        end

    end

// Bypass if enable = 0 when sign extension not needed
assign data_out = (enable == 1) ? extended_data : data_in;

endmodule