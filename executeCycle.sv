module executeCycle #(
    parameter SEL_SIZE = 4;
    parameter SHIFT_SIZE = 5;
    parameter XLEN = 32;
) (
    input alu_enable,
    input  [SEL_SIZE - 1:0]  alu_sel,
    input  [SHIFT_SIZE - 1:0]  alu_shift_amt,
    input  [XLEN - 1:0] alu_data_in_a,
    input  [XLEN - 1:0] alu_data_in_b,
    output logic [XLEN - 1:0] alu_data_out
);
    
    arithmeticLogicUnit ALU (
        .enable(alu_enable),
        .sel(alu_sel),
        .shift_amt(alu_shift_amt),
        .data_in_a(alu_data_in_a),
        .data_in_b(alu_data_in_b),
        .data_out(alu_data_out)
    );


endmodule