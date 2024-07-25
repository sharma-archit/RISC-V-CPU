module hazardMitigation #( parameter REGISTER_SIZE = 5,
                           parameter SHIFT_DEPTH = 3) // current and previous two instructions
    (
    input clk,
    input rst,
    input [REGISTER_SIZE-1:0] destination_reg,
    input [REGISTER_SIZE-1:0] source_reg1,
    input [REGISTER_SIZE-1:0] source_reg2,
    input dm_read_enable,
    
    // pipeline flop stall signals
    output logic f_to_d_enable_ff, // fetch to decode ff enable
    output logic d_to_e_enable_ff, // decode to execute ff enable
    output logic [1:0] [1:0] pipeline_forward_sel // data fwd source mux select
);

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
        if (instr_reg_info[i].destination == instr_reg_info[0].source1) begin
            
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
        if (instr_reg_info[i].destination == instr_reg_info[0].source2) begin
            
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

end : pipeline_data_hazard_detection

endmodule
