module cpuCore #() (
    input clk,
    input rst
);

enum logic [2:0] {FETCH, DECODE, EXECUTE, MEMORY_ACCESS, WRITEBACK} CPU_PIPELINE_STAGES;
enum logic {A,B};

logic [DECODE:0]    [] instruction, instruction_d;
logic [WRITEBACK:0] [] PC_in, PC_in_d;
logic [WRITEBACK:0] [] PC_out, PC_out_d;

logic [EXECUTE:0] [] alu_enable, alu_enable_d;
logic [EXECUTE:0] [] alu_sel, alu_sel_d;
logic [EXECUTE:0] [] alu_shift_amt, alu_shift_amt_d;
logic [EXECUTE:0] [] alu_data_in_a, alu_data_in_a_d;
logic [EXECUTE:0] [] alu_data_in_b, alu_data_in_b_d;
logic [WRITEBACK:0] [] alu_data_out, alu_data_out_d;

logic [WRITEBACK:0] [] rf_writeback_enable, rf_writeback_enable_d;
logic [WRITEBACK:0] [] rf_writeback_addr, rf_writeback_addr_d;
logic [WRITEBACK:0] [] rf_writeback_data, rf_writeback_data_d;
    
logic [WRITEBACK:0] [] rf_write_enable, rf_write_enable_d;
logic [WRITEBACK:0] [] rf_write_addr, rf_write_addr_d;
logic [WRITEBACK:0] [] rf_write_data_sel, rf_write_data_sel_d;
    
logic [MEMORYACCESS:0] [] dm_read_enable, dm_read_enable_d;
logic [MEMORYACCESS:0] [] dm_write_enable, dm_write_enable_d;
logic [MEMORYACCESS:0] [] dm_write_data, dm_write_data_d;
logic [MEMORYACCESS:0] [] dm_load_type, dm_load_type_d;
logic [WRITEBACK:0]    [] dm_read_data, dm_read_data_d;
logic [MEMORYACCESS:0] [] dm_data_bypass, dm_data_bypass_d;

logic f_to_d_enable_ff, f_to_d_enable_ff_prev;
logic d_to_e_enable_ff, d_to_e_enable_ff_prev;


/////////////// Fetch Cycle ///////////////

fetchCycle temp (
    .PC_in(PC_out[DECODE]),
    .PC_out(PC_out[FETCH]),
    .instruction(instruction[FETCH])
);

// Fetch -> Decode Flop
always_ff @(posedge(clk)) begin : fetch_to_decode_ff

    f_to_d_enable_ff_prev <= f_to_d_enable_ff;

    // stall decode stage if f_to_d_enable_ff is deasserted and it was asserted the previous cycle
    if (f_to_d_enable_ff || !f_to_d_enable_ff_prev) begin
        
        PC_in_d[DECODE] <= PC_in[FETCH];
        PC_out_d[DECODE] <= PC_out[FETCH];
        instruction_d[DECODE] <= instruction[FETCH];

    end

end : fetch_to_decode_ff

/////////////// Decode Cycle ///////////////

decodeCycle temp (
    .instruction(instruction_d[DECODE]),
    .PC_in(PC_in_d[DECODE]),
    .PC_out(PC_out[DECODE]),

    .f_to_d_enable_ff(f_to_d_enable_ff),
    .d_to_e_enable_ff(d_to_e_enable_ff),
    .pipeline_forward_sel(pipeline_forward_sel),

    .alu_enable(alu_enable[DECODE]),
    .alu_sel(alu_sel[DECODE]),
    .alu_shift_amt(alu_shift_amt[DECODE]),
    .dec_alu_data_in_a(dec_alu_data_in_a[DECODE]),
    .dec_alu_data_in_b(dec_alu_data_in_b[DECODE]),

    // rf_writeback input signals passed directly from writeback stage to decode stage
    .rf_writeback_enable(rf_write_enable_d[WRITEBACK]),
    .rf_writeback_addr(rf_write_addr_d[WRITEBACK]),
    .rf_writeback_data(rf_write_data[WRITEBACK]),
    
    .rf_write_enable(rf_write_enable[DECODE]),
    .rf_write_addr(rf_write_addr[DECODE]),
    .rf_write_data_sel(rf_write_data_sel[DECODE]),
    
    .dm_read_enable(dm_read_enable[DECODE]),
    .dm_write_enable(dm_write_enable[DECODE]),
    .dm_write_data(dm_write_data[DECODE]),
    .dm_load_type(dm_load_type[DECODE])
);

always_comb begin : pipeline_data_forward_mux

case (pipeline_forward_sel[A])

    MEM_ACCESS_DM_OPERAND: alu_data_in_a[DECODE] = dm_read_data[MEMORY_ACCESS];

    EXECUTE_ALU_OPERAND: alu_data_in_a[DECODE] = alu_data_out[EXECUTE];
    
    MEM_ACCESS_ALU_OPERAND: alu_data_in_a[DECODE] = dm_data_bypass[MEMORY_ACCESS];

    default: alu_data_in_a[DECODE] = dec_alu_data_in_a[DECODE];
    
endcase

case (pipeline_forward_sel[B])

    MEM_ACCESS_DM_OPERAND: alu_data_in_b[DECODE] = dm_read_data[MEMORY_ACCESS];
    
    EXECUTE_ALU_OPERAND: alu_data_in_b[DECODE] = alu_data_out[EXECUTE];
    
    MEM_ACCESS_ALU_OPERAND: alu_data_in_b[DECODE] = dm_data_bypass[MEMORY_ACCESS];
    
    default: alu_data_in_b[DECODE] = dec_alu_data_in_b[DECODE];

endcase

end: pipeline_data_forward_mux



// Decode -> Execute Flop
always_ff @(posedge(clk)) begin : decode_to_execute_ff

    d_to_e_enable_ff_prev <= d_to_e_enable_ff;

    // stall execute stage if d_to_e_enable_ff is deasserted and it was asserted the previous cycle
    if (d_to_e_enable_ff || !d_to_e_enable_ff_prev) begin

        PC_in_d[EXECUTE] <= PC_in[DECODE];
        PC_out_d[EXECUTE] <= PC_out[DECODE];
        alu_enable_d[EXECUTE] <= alu_enable[DECODE];
        alu_sel_d[EXECUTE] <= alu_sel[DECODE];
        alu_shift_amt_d[EXECUTE] <= alu_shift_amt[DECODE];
        alu_data_in_a_d[EXECUTE] <= alu_data_in_a[DECODE];
        alu_data_in_b_d[EXECUTE] <= alu_data_in_b[DECODE];

        rf_write_enable_d[EXECUTE] <= rf_write_enable[DECODE];
        rf_write_addr_d[EXECUTE] <= rf_write_addr[DECODE];
        rf_write_data_sel_d[EXECUTE] <= rf_write_data_sel[DECODE];

        dm_read_enable_d[EXECUTE] <= dm_read_enable[DECODE];
        dm_write_enable_d[EXECUTE] <= dm_write_enable[DECODE];
        dm_write_data_d[EXECUTE] <= dm_write_data[DECODE];
        dm_load_type_d[EXECUTE] <= dm_load_type[DECODE];
        dm_read_data_d[EXECUTE] <= dm_read_data[DECODE];

    end
    
end : decode_to_execute_ff

/////////////// Execute  Cycle ///////////////

executeCycle temp (
    .alu_enable(alu_enable_d[EXECUTE]),
    .alu_sel(alu_sel_d[EXECUTE]),
    .alu_shift_amt(alu_shift_amt_d[EXECUTE]),
    .alu_data_in_a(alu_data_in_a_d[EXECUTE]),
    .alu_data_in_b(alu_data_in_b_d[EXECUTE]),
    .alu_data_out(alu_data_out[EXECUTE])
);

// Execute -> Memory Access Flop
always_ff @(posedge(clk)) begin : execute_to_memaccess_ff
    
    alu_data_out_d[MEMORY_ACCESS] <= alu_data_out[EXECUTE];

    //All signals below simply flopped to next stage
    PC_in_d[MEMORY_ACCESS] <= PC_in_d[EXECUTE];
    PC_out_d[MEMORY_ACCESS] <= PC_out_d[EXECUTE];

    rf_write_enable_d[MEMORY_ACCESS] <= rf_write_enable_d[EXECUTE];
    rf_write_addr_d[MEMORY_ACCESS] <= rf_write_addr_d[EXECUTE];
    rf_write_data_sel_d[MEMORY_ACCESS] <= rf_write_data_sel_d[EXECUTE];

    dm_read_enable_d[MEMORY_ACCESS] <= dm_read_enable_d[EXECUTE];
    dm_write_enable_d[MEMORY_ACCESS] <= dm_write_enable_d[EXECUTE];
    dm_write_data_d[MEMORY_ACCESS] <= dm_write_data_d[EXECUTE];
    dm_load_type_d[MEMORY_ACCESS] <= dm_load_type_d[EXECUTE];
    dm_read_data_d[MEMORY_ACCESS] <= dm_read_data_d[EXECUTE];

end : execute_to_memaccess_ff

/////////////// Memory Access Cycle ///////////////

memoryAccessCycle temp (
    .dm_read_enable(dm_read_enable_d[MEMORY_ACCESS]),
    .dm_write_enable(dm_write_enable_d[MEMORY_ACCESS]),
    .alu_data_out(alu_data_out_d[MEMORY_ACCESS]),
    .dm_write_data(dm_write_data_d[MEMORY_ACCESS]),
    .dm_load_type(dm_load_type_d[MEMORY_ACCESS]),
    .dm_read_data(dm_read_data[MEMORY_ACCESS]),
    .dm_data_bypass(dm_data_bypass[MEMORY_ACCESS])
);

// Memory Access -> Writeback Flop
always_ff @(posedge(clk)) begin : memaccess_to_writeback_FF

    alu_data_out_d[WRITEBACK] <= dm_data_bypass[MEMORY_ACCESS],

    dm_read_data_d[WRITEBACK] <= dm_read_data[MEMORY_ACCESS],

    //All signals below simply flopped to next stage
    rf_write_enable_d[WRITEBACK] <= rf_write_enable_d[MEMORY_ACCESS];
    rf_write_data_sel_d[WRITEBACK] <= rf_write_data_sel_d[MEMORY_ACCESS],
    rf_write_addr_d[WRITEBACK] <= rf_write_addr_d[MEMORY_ACCESS];

    PC_in_d[WRITEBACK] <= PC_in_d[MEMORY_ACCESS];

end : memaccess_to_writeback_FF

/////////////// Writeback Cycle ///////////////

writeBackCycle temp (
    .writeback_data_sel(rf_write_data_sel_d[WRITEBACK]),
    .writeback_data(rf_write_data[WRITEBACK]),
    .alu_data_out(alu_data_out_d[WRITEBACK]),
    .PC_in(PC_in_d[WRITEBACK]),
    .dm_read_data(dm_read_data_d[WRITEBACK])
);

endmodule