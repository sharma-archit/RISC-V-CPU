module cpuCore #(parameter XLEN = 32,
                 parameter ALU_SEL_SIZE = 4,
                 parameter SHIFT_SIZE = 5,
                 parameter FUNCT3_SIZE = 3,
                 parameter JALR_OFFSET_SIZE = 12,
                 parameter JAL_OFFSET_SIZE = 20,
                 parameter LOAD_OFFSET = 12,
                 parameter REGISTER_SIZE = 5) (
    input clk,
    input rst,
    // debug ports to write instruction memory for testing
    input dbg_wr_en,
    input [XLEN-1:0] dbg_addr,
    input [XLEN-1:0] dbg_instr
);

const logic A = 0;
const logic B = 1;
enum logic [2:0] {FETCH, DECODE, EXECUTE, MEMORY_ACCESS, WRITEBACK} CPU_PIPELINE_STAGES;
enum logic [1:0] {DECODE_RF_OPERAND, MEM_ACCESS_DM_OPERAND, EXECUTE_ALU_OPERAND, MEM_ACCESS_ALU_OPERAND} DATA_FWD_SOURCE;

// combinational signals
logic [XLEN - 1: 0] instruction;
logic [WRITEBACK:0] [XLEN-1:0] PC_i; // rename this back to PC when done testing

logic alu_enable;
logic [ALU_SEL_SIZE - 1: 0] alu_sel;
logic [SHIFT_SIZE - 1: 0] alu_shift_amt;
logic [XLEN - 1: 0] alu_data_in_a;
logic [XLEN - 1: 0] alu_data_in_b;
logic [XLEN - 1: 0] alu_data_out;

logic rf_writeback_enable;
logic [REGISTER_SIZE - 1: 0] rf_writeback_addr;
logic [XLEN - 1: 0] rf_writeback_data;
    
logic rf_write_enable;
logic [XLEN - 1: 0] rf_write_addr;
logic [1:0] rf_write_data_sel;
    
logic dm_read_enable;
logic dm_write_enable;
logic [XLEN - 1: 0] dm_write_data;
logic [2:0] dm_load_type;
logic [XLEN - 1: 0] dm_read_data;
logic [XLEN - 1: 0] dm_data_bypass;

// pipelined signals
logic [DECODE:0] [XLEN - 1: 0] instruction_d;
logic [WRITEBACK:0] [XLEN - 1: 0] PC_d;

logic [EXECUTE:0] alu_enable_d;
logic [EXECUTE:0] [ALU_SEL_SIZE - 1: 0] alu_sel_d;
logic [EXECUTE:0] [SHIFT_SIZE - 1: 0] alu_shift_amt_d;
logic [EXECUTE:0] [XLEN - 1: 0] alu_data_in_a_d;
logic [EXECUTE:0] [XLEN - 1: 0] alu_data_in_b_d;
logic [WRITEBACK:0] [XLEN - 1: 0] alu_data_out_d;

logic [WRITEBACK:0] rf_writeback_enable_d;
logic [WRITEBACK:0] [XLEN - 1: 0] rf_writeback_addr_d;
    
logic [WRITEBACK:0] rf_write_enable_d;
logic [WRITEBACK:0] [XLEN - 1: 0] rf_write_addr_d;
logic [WRITEBACK:0] [1:0]rf_write_data_sel_d;
    
logic [MEMORY_ACCESS:0] dm_read_enable_d;
logic [MEMORY_ACCESS:0] dm_write_enable_d;
logic [MEMORY_ACCESS:0] [XLEN - 1: 0]dm_write_data_d;
logic [MEMORY_ACCESS:0] [2:0]dm_load_type_d;
logic [WRITEBACK:0]    [XLEN - 1: 0]dm_read_data_d;
logic [MEMORY_ACCESS:0] [XLEN - 1: 0]dm_data_bypass_d;

// data hazard control signals
logic f_to_d_enable_ff, f_to_d_enable_ff_prev;
logic d_to_e_enable_ff, d_to_e_enable_ff_prev;
logic [1:0][1:0] pipeline_forward_sel;

logic [XLEN - 1:0] dec_alu_data_in_a;
logic [XLEN - 1:0] dec_alu_data_in_b;


/////////////// Fetch Cycle ///////////////

fetchCycle fetch_cycle (
    .PC_in(PC_i[DECODE]),
    .PC_out(PC_i[FETCH]),
    .instruction(instruction),
    .dbg_wr_en(dbg_wr_en),
    .dbg_addr(dbg_addr),
    .dbg_instr(dbg_instr)
);

// Fetch -> Decode Flop
always_ff @(posedge(clk)) begin : fetch_to_decode_ff

    if (rst) begin

        f_to_d_enable_ff_prev <= '0;
        PC_d[DECODE] <= '0;
        instruction_d[DECODE] <= '0;

    end 
    
    else begin

        f_to_d_enable_ff_prev <= f_to_d_enable_ff;

        // stall decode stage if f_to_d_enable_ff is deasserted and it was asserted the previous cycle
        if (f_to_d_enable_ff || !f_to_d_enable_ff_prev) begin
            
            PC_d[DECODE] <= PC_i[FETCH];
            instruction_d[DECODE] <= instruction;

        end

    end

end : fetch_to_decode_ff

/////////////// Decode Cycle ///////////////

decodeCycle decode_cycle (
    .instruction(instruction_d[DECODE]),
    .PC_in(PC_d[DECODE]),
    .PC_out(PC_i[DECODE]),

    .f_to_d_enable_ff(f_to_d_enable_ff),
    .d_to_e_enable_ff(d_to_e_enable_ff),
    .pipeline_forward_sel(pipeline_forward_sel),

    .alu_enable(alu_enable),
    .alu_sel(alu_sel),
    .alu_shift_amt(alu_shift_amt),
    .dec_alu_data_in_a(dec_alu_data_in_a),
    .dec_alu_data_in_b(dec_alu_data_in_b),

    // rf_writeback input signals passed directly from writeback stage to decode stage
    .rf_writeback_enable(rf_write_enable_d[WRITEBACK]),
    .rf_writeback_addr(rf_write_addr_d[WRITEBACK]),
    .rf_writeback_data(rf_writeback_data),
    
    .rf_write_enable(rf_write_enable),
    .rf_write_addr(rf_write_addr),
    .rf_write_data_sel(rf_write_data_sel),
    
    .dm_read_enable(dm_read_enable),
    .dm_write_enable(dm_write_enable),
    .dm_write_data(dm_write_data),
    .dm_load_type(dm_load_type)
);

always_comb begin : pipeline_data_forward_mux

case (pipeline_forward_sel[A])

    MEM_ACCESS_DM_OPERAND: alu_data_in_a = dm_read_data;

    EXECUTE_ALU_OPERAND: alu_data_in_a = alu_data_out;
    
    MEM_ACCESS_ALU_OPERAND: alu_data_in_a = dm_data_bypass;

    default: alu_data_in_a = dec_alu_data_in_a;
    
endcase

case (pipeline_forward_sel[B])

    MEM_ACCESS_DM_OPERAND: alu_data_in_b = dm_read_data;
    
    EXECUTE_ALU_OPERAND: alu_data_in_b = alu_data_out;
    
    MEM_ACCESS_ALU_OPERAND: alu_data_in_b = dm_data_bypass;
    
    default: alu_data_in_b = dec_alu_data_in_b;

endcase

end: pipeline_data_forward_mux



// Decode -> Execute Flop
always_ff @(posedge(clk)) begin : decode_to_execute_ff

    if (rst) begin

        d_to_e_enable_ff_prev <= '0;
        PC_d[EXECUTE] <= '0;
        alu_enable_d[EXECUTE] <= '0;
        alu_sel_d[EXECUTE] <= '0;
        alu_shift_amt_d[EXECUTE] <= '0;
        alu_data_in_a_d[EXECUTE] <= '0;
        alu_data_in_b_d[EXECUTE] <= '0;
        rf_write_enable_d[EXECUTE] <= '0;
        rf_write_addr_d[EXECUTE] <= '0;
        rf_write_data_sel_d[EXECUTE] <= '0;
        dm_read_enable_d[EXECUTE] <= '0;
        dm_write_enable_d[EXECUTE] <= '0;
        dm_write_data_d[EXECUTE] <= '0;
        dm_load_type_d[EXECUTE] <= '0;

    end
    
    else begin

        d_to_e_enable_ff_prev <= d_to_e_enable_ff;

        // stall execute stage if d_to_e_enable_ff is deasserted and it was asserted the previous cycle
        if (d_to_e_enable_ff || !d_to_e_enable_ff_prev) begin

            PC_d[EXECUTE] <= PC_i[DECODE];
            alu_enable_d[EXECUTE] <= alu_enable;
            alu_sel_d[EXECUTE] <= alu_sel;
            alu_shift_amt_d[EXECUTE] <= alu_shift_amt;
            alu_data_in_a_d[EXECUTE] <= alu_data_in_a;
            alu_data_in_b_d[EXECUTE] <= alu_data_in_b;

            rf_write_enable_d[EXECUTE] <= rf_write_enable;
            rf_write_addr_d[EXECUTE] <= rf_write_addr;
            rf_write_data_sel_d[EXECUTE] <= rf_write_data_sel;

            dm_read_enable_d[EXECUTE] <= dm_read_enable;
            dm_write_enable_d[EXECUTE] <= dm_write_enable;
            dm_write_data_d[EXECUTE] <= dm_write_data;
            dm_load_type_d[EXECUTE] <= dm_load_type;

        end

    end

end : decode_to_execute_ff

/////////////// Execute  Cycle ///////////////

executeCycle execute_cycle (
    .alu_enable(alu_enable_d[EXECUTE]),
    .alu_sel(alu_sel_d[EXECUTE]),
    .alu_shift_amt(alu_shift_amt_d[EXECUTE]),
    .alu_data_in_a(alu_data_in_a_d[EXECUTE]),
    .alu_data_in_b(alu_data_in_b_d[EXECUTE]),
    .alu_data_out(alu_data_out)
);

// Execute -> Memory Access Flop
always_ff @(posedge(clk)) begin : execute_to_memaccess_ff

    if (rst) begin
        
        alu_data_out_d[MEMORY_ACCESS] <= '0;
        PC_d[MEMORY_ACCESS] <= '0;
        rf_write_enable_d[MEMORY_ACCESS] <= '0;
        rf_write_addr_d[MEMORY_ACCESS] <= '0;
        rf_write_data_sel_d[MEMORY_ACCESS] <= '0;
        dm_read_enable_d[MEMORY_ACCESS] <= '0;
        dm_write_enable_d[MEMORY_ACCESS] <= '0;
        dm_write_data_d[MEMORY_ACCESS] <= '0;
        dm_load_type_d[MEMORY_ACCESS] <= '0;
        
    end
    
    else begin
    
        alu_data_out_d[MEMORY_ACCESS] <= alu_data_out;

        //All signals below simply flopped to next stage
        PC_d[MEMORY_ACCESS] <= PC_d[EXECUTE];

        rf_write_enable_d[MEMORY_ACCESS] <= rf_write_enable_d[EXECUTE];
        rf_write_addr_d[MEMORY_ACCESS] <= rf_write_addr_d[EXECUTE];
        rf_write_data_sel_d[MEMORY_ACCESS] <= rf_write_data_sel_d[EXECUTE];

        dm_read_enable_d[MEMORY_ACCESS] <= dm_read_enable_d[EXECUTE];
        dm_write_enable_d[MEMORY_ACCESS] <= dm_write_enable_d[EXECUTE];
        dm_write_data_d[MEMORY_ACCESS] <= dm_write_data_d[EXECUTE];
        dm_load_type_d[MEMORY_ACCESS] <= dm_load_type_d[EXECUTE];
        
    end

end : execute_to_memaccess_ff

/////////////// Memory Access Cycle ///////////////

memoryAccessCycle memory_access_cycle (
    .dm_read_enable(dm_read_enable_d[MEMORY_ACCESS]),
    .dm_write_enable(dm_write_enable_d[MEMORY_ACCESS]),
    .alu_data_out(alu_data_out_d[MEMORY_ACCESS]),
    .dm_write_data(dm_write_data_d[MEMORY_ACCESS]),
    .dm_load_type(dm_load_type_d[MEMORY_ACCESS]),
    .dm_read_data(dm_read_data),
    .dm_data_bypass(dm_data_bypass)
);

// Memory Access -> Writeback Flop
always_ff @(posedge(clk)) begin : memaccess_to_writeback_FF

    if (rst) begin
        alu_data_out_d[WRITEBACK] <= '0;
        dm_read_data_d[WRITEBACK] <= '0;
        rf_write_enable_d[WRITEBACK] <= '0;
        rf_write_data_sel_d[WRITEBACK] <= '0;
        rf_write_addr_d[WRITEBACK] <= '0;
        PC_d[WRITEBACK] <= '0;
    end

    else begin
        alu_data_out_d[WRITEBACK] <= dm_data_bypass;
        dm_read_data_d[WRITEBACK] <= dm_read_data;
        //All signals below simply flopped to next stage
        rf_write_enable_d[WRITEBACK] <= rf_write_enable_d[MEMORY_ACCESS];
        rf_write_data_sel_d[WRITEBACK] <= rf_write_data_sel_d[MEMORY_ACCESS];
        rf_write_addr_d[WRITEBACK] <= rf_write_addr_d[MEMORY_ACCESS];
        PC_d[WRITEBACK] <= PC_d[MEMORY_ACCESS];
    end

end : memaccess_to_writeback_FF

/////////////// Writeback Cycle ///////////////

writeBackCycle write_back_cycle (
    .writeback_data_sel(rf_write_data_sel_d[WRITEBACK]),
    .writeback_data(rf_writeback_data),
    .alu_data_out(alu_data_out_d[WRITEBACK]),
    .PC_in(PC_d[WRITEBACK]),
    .dm_read_data(dm_read_data_d[WRITEBACK])
);

endmodule