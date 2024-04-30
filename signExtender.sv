module signExtender #(parameter INPUT_SIZE=12;
                      parameter OUTPUT_SIZE=32;)
(input enable,
 input [INPUT_SIZE-1:0]  data_in,
 output [OUTPUT_SIZE-1:0] data_out
);

logic [OUTPUT_SIZE-1:0] extended_data;

    always_comb begin
        
        extended_data = {(OUTPUT_SIZE-INPUT_SIZE){data_in[INPUT_SIZE-1]}, data_in};

    end

// Bypass if enable=0 when sign extension not needed
assign data_out = (enable == 1) ? extended_data : data_in;

endmodule