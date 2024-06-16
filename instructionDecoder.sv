module instructionDecoder #(parameter XLEN = 32;
                            parameter UIMMEDIATE = 20; //bit location if there is uimmediate in the opcode
                            parameter REGISTER_SIZE = 5; //bit size of register address in opcode
                            parameter DESTINATION_REGISTER_LOC = 12; // bit location of destination register address in opcode
                            parameter ALU_SEL_SIZE = 4; //bit size of alu selection
                            parameter JALR_OFFSET_SIZE = 12; //bit size of jalr offset in opcode
                            parameter JAL_OFFSET_SIZE = 20;
                            parameter SOURCE_REGISTER1_LOC = 20; // bit location of source register 1 address in opcode
                            parameter SOURCE_REGISTER2_LOC = 25; // bit location of source register 2 address in opcode
                            parameter LOAD_OFFSET = 12; //bit size of load offset in opcode
                            parameter BYTE = 8;
                            parameter HALFWORD = 16;
                            parameter IRII_IMMEDIATE = 12; //bit location of immediate value in irii opcode
                            parameter SHIFT_SIZE = 5; //bit size of shift amount in opcode
                            parameter FUNCT3 = 15; //bit location of funct3 in opcode
                            parameter FUNCT3_SIZE = 3; //bit size of funct3 value in opcode
                            parameter FUNCT12 = 12;) //bit size of funct12 value in opcode
(
    input logic [XLEN - 1:0] instruction,
    input logic [XLEN - 1:0] PC_in,

    output logic alu_enable,
    output logic [ALU_SEL_SIZE - 1:0] alu_sel,
    output logic [SHIFT_SIZE - 1: 0] alu_shift_amt,
    output logic [XLEN-1:0] alu_data_in_a,
    output logic [XLEN-1:0] alu_data_in_b,
    
    output logic [FUNCT3_SIZE - 1:0] jbl_operation,
    output logic [JALR_OFFSET_SIZE - 1:0] jbl_offset,
    output logic [JAL_OFFSET_SIZE-1:0] jbl_jal_offset,
    output logic [XLEN-1:0] jbl_data_in1,
    output logic [XLEN-1:0] jbl_data_in2,
    output logic [XLEN-1:0] jbl_address_in,

    output logic rf_read_enable1,
    output logic rf_read_enable2,
    output logic [REGISTER_SIZE-1:0] rf_read_addr1,
    output logic [REGISTER_SIZE-1:0] rf_read_addr2,
    input logic [XLEN-1:0] rf_read_data1,
    input logic [XLEN-1:0] rf_read_data2,

    output logic rf_write_enable,
    output logic [1:0] rf_write_data_sel,
    output logic [REGISTER_SIZE-1:0] rf_write_addr,
    
    output logic dm_read_enable,
    output logic dm_write_enable,
    output logic [XLEN-1:0] dm_write_data,
    output logic [2:0] dm_load_type
); 

// 7-bit opcodes //
// stand-alone instructions
`define LUI    7'b0110111
`define AUIPC  7'b0010111
`define JAL    7'b1101111
`define JALR   7'b1100111
`define FENCE  7'b0001111
// instruction groups
`define BRANCH 7'b1100011
`define LOADS  7'b0000011
`define STORE  7'b0100011
`define IRII   7'b0010011
`define IRRO   7'b0110011
`define ECB    7'b1110011

enum {ADD, SUB, SLT, SLTU, AND, OR, XOR, SLL, SRL, SRA, LUI, AUIPC, LOAD, STORE} ALU_OP_E;
enum {JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU} JBL_OP_E;
enum {LOAD_B, LOAD_H, LOAD_W, LOAD_BU, LOAD_HU} LOAD_OP_E; // to size load data in the mem_access cycle
enum {ALU, DATA_MEM, PC} WRITEBACK_DATA_SEL_E; // to select the source of write data in the writeback cycle


typedef struct packed {
    logic [4:0] destination;
    logic [4:0] source1;
    logic [4:0] source2;  
} instr_registers_t;

// internally storing instruction opcode registers
instr_registers_t [2:0] instr_reg_info;

always_comb begin : decoder

    // default all control signals to 0
    alu_enable = 0;
    alu_sel = 0;
    alu_shift_amt = '0;
    alu_data_in_a = '0;
    alu_data_in_b = '0;
    
    jbl_operation = '0;
    jbl_offset = '0;
    jbl_jal_offset = '0;
    jbl_data_in1 = '0;
    jbl_data_in2 = '0;
    jbl_address_in = '0;

    rf_read_enable1 = '0;
    rf_read_enable2 = '0;
    rf_read_addr1 = '0;
    rf_read_addr2 = '0;
    
    rf_write_enable = 0;
    rf_write_addr = '0;
    rf_write_data_sel = '0;
    
    dm_read_enable = '0;
    dm_write_enable = '0;
    dm_write_data = '0;
    dm_load_type = '0;

    // decode each instruction
    case (instruction[6:0])
    
        LUI: begin

            alu_enable = 1;
            alu_sel = LUI;
            alu_data_in_a = instruction[XLEN - 1:XLEN - UIMMEDIATE];
            
            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE]; //which CPU reg to write to
            rf_write_data_sel = ALU; //rf write data to be computed in the execute cycle
            
            instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            instr_reg_info[0].source1 = X;
            instr_reg_info[0].source2 = X;
            
        end

        AUIPC: begin
            
            alu_enable = 1;
            alu_sel = AUIPC;
            alu_data_in_a = instruction[XLEN - 1:XLEN - UIMMEDIATE];
            alu_data_in_b = PC_in; //Make sure PC value is the value to the AUIPC instruction

            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE]; //which CPU reg to write to
            rf_write_data_sel= ALU; //rf write data to be computed in the execute cycle

            instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            instr_reg_info[0].source1 = X;
            instr_reg_info[0].source2 = X;

        end

        JAL: begin
            
            jbl_operation = JAL;
            jbl_jal_offset = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
            jbl_address_in = PC_in; //Make sure the PC value is the value of the JAL instruction

            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            rf_write_data_sel = PC; //current PC + 4;

            instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            instr_reg_info[0].source1 = X;
            instr_reg_info[0].source2 = X;

        end

        JALR: begin
            
            jbl_operation = JALR;
            jbl_offset = instruction[XLEN-1:XLEN - JALR_OFFSET];
            jbl_address_in = rf_read_data1;

            // read register rs1, write PC+4 to register rd
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC - 1:SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            rf_write_data_sel = PC; //current PC + 4

            instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            instr_reg_info[0].source2 = X;

        end

        FENCE: begin
        end

        BRANCH: begin

            jbl_offset = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]}; //Reordered immediate value
            jbl_data_in1 = rf_read_data1;
            jbl_data_in2 = rf_read_data2;
            jbl_address_in = PC_in; //PC value of the branch instruction being decoded

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC - 1:SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            rf_read_addr2 = instruction[SOURCE_REGISTER2_LOC - 1:SOURCE_REGISTER2_LOC - REGISTER_SIZE];

            instr_reg_info[0].destination = X;
            instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            instr_reg_info[0].source2 = instruction[SOURCE_REGISTER2_LOC: SOURCE_REGISTER2_LOC - REGISTER_SIZE];

            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000) begin : BEQ
            
                jbl_operation = BEQ;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001) begin : BNE

                jbl_operation = BNE;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b100) begin : BLT

                jbl_operation = BLT;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101) begin : BGE

                jbl_operation = BGE;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b110) begin : BLTU

                jbl_operation = BLTU;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b111) begin : BGEU

                jbl_operation = BGEU;

            end
        end
        
        LOAD: begin

                alu_enable = 1;
                alu_sel = ADD;
                alu_data_in_a = {{(XLEN - LOAD_OFFSET){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - LOAD_OFFSET]}; // target address offset
                alu_data_in_b = rf_read_data1; //target base address
                
                rf_read_enable1 = 1;
                rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC:SOURCE_REGISTER1_LOC - REGISTER_SIZE]; // address of cpu register holding base address
                
                rf_write_enable = 1;
                rf_write_addr = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE]; //address of destination cpu register to load data into

                dm_read_enable = 1;
                
                rf_write_data_sel = DATA_MEM;

                instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
                instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
                instr_reg_info[0].source2 = X;

                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000) begin : LB
                    dm_load_type = LOAD_B;
                end
                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001) begin : LH
                    dm_load_type = LOAD_H;
                end
                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b010) begin : LW
                    dm_load_type = LOAD_W;
                end
                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b100) begin : LBU
                    dm_load_type = LOAD_BU;
                end
                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101) begin : LHU
                    dm_load_type = LOAD_HU;
                end
        end

        STORE: begin
    
                alu_enable = 1;
                alu_sel = ADD;

                alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:25], instruction[11:7]}; // target address offset 
                alu_data_in_b = rf_read_data1; // target base address

                rf_read_enable1 = 1;
                rf_read_enable2 = 1;
                rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC - 1:SOURCE_REGISTER1_LOC - REGISTER_SIZE]; // cpu register where target base addr is stored
                rf_read_addr2 = instruction[SOURCE_REGISTER2_LOC - 1:SOURCE_REGISTER2_LOC - REGISTER_SIZE]; // data value to store into data memory

                dm_write_enable = 1;

                instr_reg_info[0].destination = X;
                instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
                instr_reg_info[0].source2 = instruction[SOURCE_REGISTER2_LOC: SOURCE_REGISTER2_LOC - REGISTER_SIZE];

                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000) begin : SB
                    dm_write_data = {{(XLEN - BYTE){rf_read_data2[BYTE - 1]}}, rf_read_data2[BYTE - 1:0]}; // data byte sign extended to 32 bits
                end

                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001) begin : SH
                    dm_write_data = {{(XLEN - HALFWORD){rf_read_data2[HALFWORD - 1]}}, rf_read_data2[HALFWORD - 1:0]};
                end

                if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b010) begin : SW
                    dm_write_data = rf_read_data2;
                end
        end

        IRII: begin 

                alu_enable = 1;

                rf_read_enable1 = 1;
                rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC - 1:SOURCE_REGISTER1_LOC - REGISTER_SIZE];

                rf_write_enable = 1;
                rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
                rf_write_data = ALU;

                instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
                instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
                instr_reg_info[0].source2 = X;

            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000) begin : ADDI

                alu_sel = ADD;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b010) begin : SLTI

                alu_sel = SLT;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b011) begin : SLTIU

                alu_sel = SLTU;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b100) begin : XORI

                alu_sel = XOR;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b110) begin : ORI

                alu_sel = OR;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b111) begin : ANDI

                alu_sel = AND;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = {{(XLEN - IRII_IMMEDIATE){instruction[XLEN - 1]}}, instruction[XLEN - 1:XLEN - IRII_IMMEDIATE]}; //Sign extended immediate value

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001 & instruction[XLEN - 1:XLEN - 7] == 7'b0000000) begin : SLLI

                alu_sel = SLL;
                alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_SIZE - 1:XLEN - IRII_IMMEDIATE]; //Shift amount is lower 5 bits of immediate value
                alu_data_in_a = rf_read_data1;
            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 & instruction[XLEN - 1:XLEN - 7] == 7'b0000000) begin : SRLI

                alu_sel = SRL;
                alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_SIZE - 1:XLEN - IRII_IMMEDIATE];
                alu_data_in_a = rf_read_data1;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 & instruction[XLEN - 1:XLEN - 7] == 7'b0100000) begin : SRAI

                alu_sel = SRA;
                alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_SIZE - 1:XLEN - IRII_IMMEDIATE];
                alu_data_in_a = rf_read_data1;

            end
        end

        IRRO: begin

            alu_enable = 1;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[SOURCE_REGISTER1_LOC - 1:SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            rf_read_addr2 = instruction[SOURCE_REGISTER2_LOC - 1:SOURCE_REGISTER2_LOC - REGISTER_SIZE];

            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER_LOC - 1:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            rf_write_data = ALU;

            instr_reg_info[0].destination = instruction[DESTINATION_REGISTER_LOC:DESTINATION_REGISTER_LOC - REGISTER_SIZE];
            instr_reg_info[0].source1 = instruction[SOURCE_REGISTER1_LOC: SOURCE_REGISTER1_LOC - REGISTER_SIZE];
            instr_reg_info[0].source2 = instruction[SOURCE_REGISTER2_LOC: SOURCE_REGISTER2_LOC - REGISTER_SIZE];
            
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000 && instruction[XLEN - 1:XLEN - 7] == 7'b0000000) begin : ADD

                alu_sel = XOR;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000 && instruction[XLEN - 1:XLEN - 7] == 7'b0100000) begin : SUB

                alu_sel = SUB;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001) begin : SLL

                alu_sel = SLL;
                alu_shift_amt = rf_read_data2[4:0]; //Shift amount is lower 5 bits of register value
                alu_data_in_a = rf_read_data1;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b010) begin : SLT

                alu_sel = SLT;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b011) begin : SLTU

                alu_sel = SLTU;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b100) begin : XOR

                alu_sel = XOR;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 && instruction[XLEN - 1:XLEN - 7] == 7'b0000000) begin : SRL

                alu_sel = SRL;
                alu_shift_amt = rf_read_data2[4:0];
                alu_data_in_a = rf_read_data1;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 && instruction[XLEN - 1:XLEN - 7] == 7'b0100000) begin : SRA

                alu_sel = SRA;
                alu_shift_amt = rf_read_data2[4:0];
                alu_data_in_a = rf_read_data1;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b110) begin : OR

                alu_sel = OR;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end
            if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b111) begin : AND

                alu_sel = ADD;
                alu_data_in_a = rf_read_data1;
                alu_data_in_b = rf_read_data2;

            end

        end
        
        ECB: begin
            
            if(instruction[XLEN - 1:XLEN - FUNCT12] == 12'b000000000000) begin : ECALL
            end
            if(instruction[XLEN - 1:XLEN - FUNCT12] == 12'b000000000001) begin : EBREAK
            end
        end
        
        default: 
        // check if riscv requires us to raise an exception if invalid instruction
    endcase

end : decoder



always_comb begin : pipeline_data_hazard_detection

            // if a past instruction's destination reg is a source reg for the current instruction
            if (instr_reg_info[i].destination == instr_reg_info[0].source1 || instr_reg_info[i].destination == instr_reg_info[0].source2) begin
                
                if (dm_read_enable) begin // if current instruction is a load NOT previous which is what we want

                    if (i == 1) begin
                        
                        // order a stall since the previous load instruction must be in the memory access cycle to produce the operand that will be forwarded to the decode stage
                        fetch2decode_flop_enable = '0;
                        decode2execute_flop_enable = '0;
                    end
                    else if (i == 2) begin

                        dm_operand_forward = 1;

                    end
                else if (i == 1) begin
                    
                    //forward alu_data_out from execute cycle to decode cycle
                    alu_operand_forward = 1;
                    
                end
                else begin
                    
                    //forward alu_data_out from memory access cycle to decode cycle
                    mem_access_alu_operand_forward = 1;

                end
                   
                end
                    
            end

end : pipeline_data_hazard_detection


endmodule