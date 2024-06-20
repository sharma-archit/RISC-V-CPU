module loadUpperImmediate #(parameter DATA_IN_SIZE = 20,
                            parameter XLEN = 32)
(
    input [DATA_IN_SIZE - 1:0] data_in,
    output [XLEN - 1:0] data_out
);

    assign data_out = {data_in, (XLEN - DATA_IN_SIZE)'d0};
 
endmodule