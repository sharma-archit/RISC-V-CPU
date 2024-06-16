module hazardMitigation #( parameter REGISTER_SIZE = 5;
                           parameter FIFO_DEPTH = 3;) 
    (
    input clk,
    input rst,
    input [REGISTER_SIZE-1:0] destination_reg,
    input [REGISTER_SIZE-1:0] source_reg1,
    input [REGISTER_SIZE-1:0] source_reg2,
    
    // pipeline flop stall signals
    output logic f_to_d_enable_ff, // fetch to decode ff enable
    output logic d_to_e_enable_ff, // decode to execute ff enable
    output logic [1:0] [2:0] pipeline_forward_sel
);

typedef struct packed {
    logic [REGISTER_SIZE-1:0] destination;
    logic [REGISTER_SIZE-1:0] source1;
    logic [REGISTER_SIZE-1:0] source2;
} instr_registers_t;

// internally storing dest/source registers for current and previous two instructions
// NOTE: instr_reg_info[0] = current instruction
//       instr_reg_info[1] = previous instruction
//       instr_reg_info[2] = previous previous instruction
instr_registers_t [FIFO_DEPTH-1:0] instr_reg_info;


always_ff @(posedge(clk)) begin : fifo

    if (rst) begin

        instr_reg_info <= '0;

    end
    else begin

        for (int i = 0; i < FIFO_DEPTH-1; i = i+1) begin
            
            instr_reg_info[i + 1] <= instr_reg_info[i];
            
        end
        
        // push current instruction into fifo
        instr_reg_info[0].destination <= destination_reg;
        instr_reg_info[0].source1 <= source_reg1;
        instr_reg_info[0].source2 <= source_reg2;

    end


end : fifo

always_comb begin : pipeline_data_hazard_detection

    f_to_d_enable_ff = 1;
    d_to_e_enable_ff = 1;

    dm_operand_forward = '0;
    alu_operand_forward = '0;
    mem_access_alu_operand_forward = '0;

    for (int i = 1; i < 3 ; i++) begin
    
        // if a past instruction's destination reg is a source reg for the current instruction
        if (instr_reg_info[i].destination == instr_reg_info[0].source1) begin
            
            if (dm_read_enable) begin // if current instruction is a load NOT previous which is what we want

                if (i == 1) begin

                    // order a stall since the previous load instruction must be in the memory access cycle to produce the operand that will be forwarded to the decode stage
                    f_to_d_enable_ff = '0;
                    d_to_e_enable_ff = '0;

                end
                else if (i == 2) begin

                    pipeline_forward_sel[A] = MEM_ACCESS_DM_OPERAND;

                end
            else if (i == 1) begin
                
                //forward alu_data_out from execute cycle to decode cycle
                pipeline_forward_sel[A]= EXECUTE_ALU_OPERAND;
                
            end
            else begin
                
                //forward alu_data_out from memory access cycle to decode cycle
                pipeline_forward_sel[A] = MEM_ACCESS_ALU_OPERAND;

            end
                
            end
                
        end
        if (instr_reg_info[i].destination == instr_reg_info[0].source2) begin
            
            if (dm_read_enable) begin // if current instruction is a load NOT previous which is what we want

                if (i == 1) begin

                    // order a stall since the previous load instruction must be in the memory access cycle to produce the operand that will be forwarded to the decode stage
                    f_to_d_enable_ff = '0;
                    d_to_e_enable_ff = '0;

                end
                else if (i == 2) begin

                    pipeline_forward_sel[B] = MEM_ACCESS_DM_OPERAND;

                end
            else if (i == 1) begin
                
                //forward alu_data_out from execute cycle to decode cycle
                pipeline_forward_sel[B]= EXECUTE_ALU_OPERAND;
                
            end
            else begin
                
                //forward alu_data_out from memory access cycle to decode cycle
                pipeline_forward_sel[B] = MEM_ACCESS_ALU_OPERAND;

            end
                
            end

        end

    end

end : pipeline_data_hazard_detection

endmodule
