module hazardMitigation #( parameter XLEN = 32,
                           parameter REGISTER_SIZE = 5,
                           parameter SHIFT_DEPTH = 3) // current and previous two instructions
    (
    input clk,
    input rst,
    input [XLEN - 1:0] instruction,
    input [REGISTER_SIZE-1:0] destination_reg,
    input [REGISTER_SIZE-1:0] source_reg1,
    input [REGISTER_SIZE-1:0] source_reg2,
    input dm_read_enable,
    input dm_write_enable,
    input [XLEN - 1:0] dm_read_data,

    //Signals coming from the instruction decoder
    input logic [XLEN - 1:0] dec_alu_data_in_a,
    input logic [XLEN - 1:0] dec_alu_data_in_b,
    input logic [XLEN - 1:0] alu_data_out,
    input logic [XLEN - 1:0] dec_jbl_data_in1,
    input logic [XLEN - 1:0] dec_jbl_data_in2,
    input logic [XLEN - 1:0] dec_jbl_address_in,
    input logic [XLEN - 1:0] dec_dm_write_data,
    input logic [XLEN - 1:0] dm_data_bypass,


    //Signals to go to the pipeline register
    output logic [XLEN - 1:0] alu_data_in_a,
    output logic [XLEN - 1:0] alu_data_in_b,
    output logic [XLEN - 1:0] jbl_data_in1,
    output logic [XLEN - 1:0] jbl_data_in2,
    output logic [XLEN - 1:0] jbl_address_in,
    output logic [XLEN - 1:0] dm_write_data,
    
    // pipeline flop stall signals
    output logic f_to_d_enable_ff, // fetch to decode ff enable
    output logic d_to_e_enable_ff // decode to execute ff enable 
);

logic [1:0] [1:0] pipeline_forward_sel; // data fwd source mux select

const logic A = 0;
const logic B = 1;

enum logic [1:0] {DECODE_RF_OPERAND, MEM_ACCESS_DM_OPERAND, EXECUTE_ALU_OPERAND, MEM_ACCESS_ALU_OPERAND} DATA_FWD_SOURCE;

typedef struct packed {
    logic [REGISTER_SIZE-1:0] destination;
    logic [REGISTER_SIZE-1:0] source1;
    logic [REGISTER_SIZE-1:0] source2;
} instr_registers_t;

// internally storing dest/source registers for current and previous two instructions
// NOTE: instr_reg_info[0] = current instruction
//       instr_reg_info[1] = previous instruction
//       instr_reg_info[2] = previous previous instruction
instr_registers_t [SHIFT_DEPTH-1:0] instr_reg_info;

logic [SHIFT_DEPTH-1:0] dm_read_enable_d;

// push current instruction into shift reg
assign instr_reg_info[0].destination = destination_reg;
assign instr_reg_info[0].source1 = source_reg1;
assign instr_reg_info[0].source2 = source_reg2;

always_ff @(posedge(clk)) begin : instr_shift_reg

    if (rst) begin

        for (int i = 0; i < SHIFT_DEPTH-1; i = i+1) begin
            
            instr_reg_info[i + 1] <= '0;
            
        end

    end
    else begin

        // cycle instructions 
        for (int i = 0; i < SHIFT_DEPTH-1; i = i + 1) begin
            
            instr_reg_info[i + 1].destination <= instr_reg_info[i].destination;
            instr_reg_info[i + 1].source1 <= instr_reg_info[i].source1;
            instr_reg_info[i + 1].source2 <= instr_reg_info[i].source2;
            
        end

    end

end : instr_shift_reg

assign dm_read_enable_d[0] = dm_read_enable;

always_ff @(posedge(clk)) begin : load_check_shift_reg

    if (rst) begin

        for (int i = 0; i < SHIFT_DEPTH-1; i = i+1) begin
            
            dm_read_enable_d[i + 1] <= '0;
            
        end

    end
    else begin

        for (int i = 0; i < SHIFT_DEPTH-1; i = i+1) begin
            
            dm_read_enable_d[i + 1] <= dm_read_enable_d[i];
            
        end
    
    end

end : load_check_shift_reg

always_comb begin : pipeline_data_hazard_detection

    f_to_d_enable_ff = 1;
    d_to_e_enable_ff = 1;

    pipeline_forward_sel[A] = DECODE_RF_OPERAND;
    pipeline_forward_sel[B] = DECODE_RF_OPERAND;

    // need to check if the current instruction has a data hazard with the previous two instructions in the pipeline
    for (int i = 1; i < 3 ; i=i+1) begin
    
        // if a past instruction's destination reg is source1 reg for the current instruction
        if (instr_reg_info[i].destination == instr_reg_info[0].source1 && instr_reg_info[i].destination !== 0 && instr_reg_info[0].source1 !== 0) begin
            
            // for previous load instructions
            if (dm_read_enable_d[i]) begin : load_instr_A

                if (i == 1) begin //conflicting load instruction is currently in execute cycle

                    // order a stall since the previous load instruction must be in the memory access cycle to produce the operand that will be forwarded to the decode stage
                    f_to_d_enable_ff = '0;
                    d_to_e_enable_ff = '0;

                end
                else if (i == 2) begin //conflicting load instruction is currently in memory access cycle

                    pipeline_forward_sel[A] = MEM_ACCESS_DM_OPERAND;

                end
            end : load_instr_A
            
            // for non-load previous instructions
            else begin : non_load_instr_A

                if (i == 1) begin
                    //forward alu_data_out from execute cycle to decode cycle
                    pipeline_forward_sel[A] = EXECUTE_ALU_OPERAND;
                end
                else begin
                //forward alu_data_out from memory access cycle to decode cycle
                pipeline_forward_sel[A] = MEM_ACCESS_ALU_OPERAND;

                end

            end : non_load_instr_A

        end

        // if a past instruction's destination reg is source2 reg for the current instruction
        if (instr_reg_info[i].destination == instr_reg_info[0].source2 && instr_reg_info[i].destination !== 0 && instr_reg_info[0].source2 !== 0) begin
            
            // for previous load instructions
            if (dm_read_enable_d[i]) begin : load_instr_B

                if (i == 1) begin //conflicting load instruction is currently in execute cycle

                    // order a stall since the previous load instruction must be in the memory access cycle to produce the operand that will be forwarded to the decode stage
                    f_to_d_enable_ff = '0;
                    d_to_e_enable_ff = '0;

                end
                else if (i == 2) begin //conflicting load instruction is currently in memory access cycle

                    pipeline_forward_sel[B] = MEM_ACCESS_DM_OPERAND;

                end
            end : load_instr_B
            
            // for non-load previous instructions
            else begin : non_load_instr_B

                if (i == 1) begin
                    //forward alu_data_out from execute cycle to decode cycle
                    pipeline_forward_sel[B] = EXECUTE_ALU_OPERAND;
                end
                else if (i == 2) begin
                //forward alu_data_out from memory access cycle to decode cycle
                pipeline_forward_sel[B] = MEM_ACCESS_ALU_OPERAND;

                end

            end : non_load_instr_B

        end

    end

    //Operand forwarding for alu_in_a
    case (pipeline_forward_sel[A])

        MEM_ACCESS_DM_OPERAND: begin

            alu_data_in_a = dm_read_data;

            if (instruction[6:0] == 7'b1100011) begin
            
                jbl_data_in1 = dm_read_data;
                jbl_address_in = dec_jbl_address_in;

            end
            else begin
                
                jbl_data_in1 = dec_jbl_data_in1;
                jbl_address_in = dm_read_data;

            end

        end

        EXECUTE_ALU_OPERAND: begin
            
            alu_data_in_a = alu_data_out;
            
            if (instruction[6:0] == 7'b1100011) begin
            
                jbl_data_in1 = alu_data_out;
                jbl_address_in = dec_jbl_address_in;

            end
            else begin
                
                jbl_data_in1 = dec_jbl_data_in1;
                jbl_address_in = alu_data_out;
            end
        end
        
        MEM_ACCESS_ALU_OPERAND: begin

            alu_data_in_a = dm_data_bypass;

            if (instruction[6:0] == 7'b1100011) begin

                jbl_data_in1 = dm_data_bypass;
                jbl_address_in = dec_jbl_address_in;

            end
            else begin
                
                jbl_data_in1 = dec_jbl_data_in1;
                jbl_address_in = dm_data_bypass;
            end
        end

        default: begin

            alu_data_in_a = dec_alu_data_in_a;
            jbl_data_in1 = dec_jbl_data_in1;
            jbl_address_in = dec_jbl_address_in;

        end
        
    endcase

    //Operand forwarding for alu_in_b/store data source
    case (pipeline_forward_sel[B])

        MEM_ACCESS_DM_OPERAND: begin //Forward operand from mem access cycle into ALU input a

            alu_data_in_b = dm_read_data;
            dm_write_data = dm_read_data;

            jbl_data_in2 = dm_read_data;
            
        end
        
        EXECUTE_ALU_OPERAND: begin //Forward operand from execute cycle

            jbl_data_in2 = alu_data_out;
            
            if (dm_write_enable) begin // if instruction is store
                
                alu_data_in_b = dec_alu_data_in_b;
                dm_write_data = alu_data_out;
                
            end
            else begin
                
                alu_data_in_b = alu_data_out;
                dm_write_data = dec_dm_write_data;

            end
            
        end
        
        MEM_ACCESS_ALU_OPERAND: begin //Forward operand from mem access cycle
            
            jbl_data_in2 = dm_data_bypass;

            if (dm_write_enable) begin // if instruction is store
                
                alu_data_in_b = dec_alu_data_in_b;
                dm_write_data = dm_data_bypass;
                
            end
            else begin
                
                alu_data_in_b = dm_data_bypass;
                dm_write_data = dec_dm_write_data;

            end

        end
        
        default: begin

            alu_data_in_b = dec_alu_data_in_b;
            dm_write_data = dec_dm_write_data;
            jbl_data_in2 = dec_jbl_data_in2;
            
        end

    endcase

end : pipeline_data_hazard_detection

endmodule