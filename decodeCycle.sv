module decodeCycle #(
    parameter XLEN = 32,
    parameter ALU_SEL_SIZE = 4,
    parameter SHIFT_SIZE = 5,
    parameter FUNCT3_SIZE = 3,
    parameter JALR_OFFSET_SIZE = 12,
    parameter JAL_OFFSET_SIZE = 20,
    parameter LOAD_OFFSET = 12,
    parameter REGISTER_SIZE = 5
   ) 
(   input clk, 
    input rst, 
    
    input logic [XLEN - 1:0] instruction,
    input logic [XLEN - 1:0] PC_in,
    output logic [XLEN - 1:0] PC_out,

    // outputs to ALU
    output logic alu_enable,
    output logic [ALU_SEL_SIZE - 1:0] alu_sel,
    output logic [SHIFT_SIZE - 1: 0] alu_shift_amt,
    output logic [XLEN-1:0] dec_alu_data_in_a,
    output logic [XLEN-1:0] dec_alu_data_in_b,

    // incoming write signals from writeback stage
    input logic rf_writeback_enable,
    input logic [REGISTER_SIZE-1:0] rf_writeback_addr,
    input logic [XLEN-1:0] rf_writeback_data,
    
    // outgoing write signals to writeback stage (note that these signals do not directly write into the register file to prevent writing in the same clk cycle as their decode cycle)
    output logic rf_write_enable,
    output logic [REGISTER_SIZE-1:0] rf_write_addr,
    output logic [1:0] rf_write_data_sel,
    
    // outputs to data memory access
    output logic dm_read_enable,
    output logic dm_write_enable,
    output logic [XLEN-1:0] dm_write_data, 
    output logic [2:0] dm_load_type,

    // pipeline hazard control signals
    output logic f_to_d_enable_ff, // fetch to decode ff enable
    output logic d_to_e_enable_ff, // decode to execute ff enable
    output logic [1:0] [1:0] pipeline_forward_sel // to forward data via pipeline bypassing
);

    // internal registers
    logic [REGISTER_SIZE-1:0] destination_reg;
    logic [REGISTER_SIZE-1:0] source_reg1;
    logic [REGISTER_SIZE-1:0] source_reg2;

    logic [FUNCT3_SIZE - 1:0] jbl_operation;
    logic [JALR_OFFSET_SIZE - 1:0] jbl_offset;
    logic [JAL_OFFSET_SIZE-1:0] jbl_jal_offset;
    logic [XLEN-1:0] jbl_data_in1;
    logic [XLEN-1:0] jbl_data_in2;
    logic [XLEN-1:0] jbl_address_in;
    logic [XLEN - 1:0] jbl_address_out;

    logic rf_read_enable1;
    logic rf_read_enable2;
    logic [XLEN - 1:0] rf_read_data1;
    logic [XLEN - 1:0] rf_read_data2;
    logic [REGISTER_SIZE-1:0] rf_read_addr1;
    logic [REGISTER_SIZE-1:0] rf_read_addr2;
    

regFile register_file (
    .clk(clk),
    .rst(rst),
    .write_enable(rf_writeback_enable),
    .read_enable1(rf_read_enable1),
    .read_enable2(rf_read_enable2),
    .read_addr1(rf_read_addr1),
    .read_addr2(rf_read_addr2),
    .write_addr(rf_writeback_addr),
    .write_data(rf_writeback_data),
    .read_data1(rf_read_data1),
    .read_data2(rf_read_data2)
    );

instructionDecoder instruction_decoder (.*);

jumpBranchLogic jump_branch_logic (
    .operation(jbl_operation),
    .offset(jbl_offset),
    .jal_offset(jbl_jal_offset),
    .data_in1(jbl_data_in1),
    .data_in2(jbl_data_in2),
    .address_in(jbl_address_in),
    .address_out(jbl_address_out)
    );

hazardMitigation hazard_mitigation(
    .destination_reg(destination_reg),
    .source_reg1(source_reg1),
    .source_reg2(source_reg2),
    .f_to_d_enable_ff(f_to_d_enable_ff),
    .d_to_e_enable_ff(d_to_e_enable_ff),
    .pipeline_forward_sel(pipeline_forward_sel)
);
    
    // use PC value computed by JBL block if the current instruction is a jump/branch instruction, otherwise increment PC normally 
    assign PC_out = (instruction[6:0] == 7'b1100011 || instruction[6:0] == 7'b1100111 || instruction[6:0] == 7'b1101111) ? jbl_address_out : PC_in + 4;

endmodule