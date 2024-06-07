module instructionDecoder #(parameter XLEN=32;
                            parameter UIMMEDIATE = 20;
                            parameter REGISTER_SIZE = 5;
                            parameter DESTINATION_REGISTER = 12;
                            parameter JALR_OFFSET = 12;
                            parameter SOURCE_REGISTER1 = 20;
                            parameter SOURCE_REGISTER2 = 25;
                            parameter FUNCT3 = 15;
                            parameter LOAD_OFFSET = 12;
                            parameter BYTE = 8;
                            parameter HALFWORD = 16;
                            parameter IRII_IMMEDIATE = 12;
                            parameter SHIFT_AMOUNT = 5;
                            parameter FUNCT3 = 15;
                            parameter FUNCT3_SIZE = 3;
                            parameter FUNCT12 = 12;)
(
    input logic [XLEN - 1:0] instruction,
    input logic [XLEN - 1:0] PC,
    output logic [XLEN - 1:0] computed_PC
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

enum {ADD, SUB, SLT, SLTU, AND, OR, XOR, SLL, SRL, SRA, LUI, AUIPC, LOAD, STORE} ALU_OP;
enum {JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU} JBL_OP;

always_comb begin

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

    ls_load_enable = 0;
    ls_store_enable = 0;
    ls_base_addr = '0;
    ls_offset = 0;
    ls_width = 0;
    ls_data_in_memory = 0;
    ls_data_in_register = 0;
    ls_target_addr = 0;

    rf_read_enable1 = '0;
    rf_read_enable2 = '0;
    rf_read_addr1 = '0;
    rf_read_addr2 = '0;
    
    rf_write_enable = 0;
    rf_write_addr = '0;
    rf_write_data = '0;
    
    dm_read_enable = '0;
    dm_write_enable = '0;
    dm_read_addr = '0;
    dm_write_addr = '0;
    dm_write_data = '0;

    im_addr = '0;


// decode each instruction
case (instruction[6:0])
    LUI: begin

        alu_enable = 1;
        alu_sel = LUI;
        alu_data_in_a = instruction[XLEN - 1:XLEN - UIMMEDIATE];
        
        rf_write_enable = 1;
        rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE]; //which CPU reg to write to
        rf_write_data = alu_data_out; //rf write data to be computed in the execute cycle
        
    end

    AUIPC: begin
        
        alu_enable = 1;
        alu_sel = AUIPC;
        alu_data_in_a = instruction[XLEN - 1:XLEN - UIMMEDIATE];
        alu_data_in_b = PC; //Make sure PC value is the value to the AUIPC instruction

        rf_write_enable = 1;
        rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE]; //which CPU reg to write to
        rf_write_data = alu_data_out; //rf write data to be computed in the execute cycle

    end

    JAL: begin
        
        jbl_operation = JAL;
        jbl_jal_offset = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
        jbl_address_in = PC; //Make sure the PC value is the value of the JAL instruction
        computed_PC = jbl_address_out;

        rf_write_enable = 1;
        rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE];
        rf_write_data = PC + 4;

    end

    JALR: begin
        
        jbl_operation = JALR;
        jbl_offset = instruction[XLEN-1:XLEN - JALR_OFFSET];
        jbl_address_in = rf_read_data1;
        computed_PC = jbl_address_out;

        // read register rs1, write PC+4 to register rd
        rf_read_enable1 = 1;
        rf_read_addr1 = instruction[SOURCE_REGISTER1 - 1:SOURCE_REGISTER1 - REGISTER_SIZE];
        rf_write_enable = 1;
        rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE];
        rf_write_data = PC + 4;

    end

    FENCE: begin
    end

    BRANCH: begin

            jbl_offset = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]}; //Reordered immediate value
            jbl_data_in1 = rf_read_data1;
            jbl_data_in2 = rf_read_data2;
            jbl_address_in = PC; //PC value of the branch instruction being decoded
            computed_PC = jbl_address_out //New PC value to branch to

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[SOURCE_REGISTER1 - 1:SOURCE_REGISTER1 - REGISTER_SIZE];
            rf_read_addr2 = instruction[SOURCE_REGISTER2 - 1:SOURCE_REGISTER2 - REGISTER_SIZE];

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
            rf_read_addr1 = instruction[SOURCE_REGISTER1:SOURCE_REGISTER1 - REGISTER_SIZE]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER:DESTINATION_REGISTER - REGISTER_SIZE]; //address of destination cpu register to load data into

            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b000) begin : LB

            rf_write_data = { {(XLEN - BYTE){dm_read_data[BYTE - 1]}}, dm_read_data[BYTE - 1:0]};

        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b001) begin : LH

            rf_write_data = { {(XLEN - HALFWORD){dm_read_data[HALFWORD - 1]}}, dm_read_data[HALFWORD - 1:0]}; // sign extended data from memory

        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b010) begin : LW

            rf_write_data = dm_read_data;

        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b100) begin : LBU

            rf_write_data = { {(XLEN - BYTE){0}}, dm_read_data[BYTE - 1:0]}; //zero extended data from memory

        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101) begin : LHU

            rf_write_data = {{(XLEN - HALFWORD){0}}, dm_read_data[HALFWORD - 1:0]}; //zero extended data from memory

        end
    end

    STORE: begin
 
            alu_enable = 1;
            alu_sel = ADD;

            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:25], instruction[11:7]}; // target address offset 
            alu_data_in_b = rf_read_data1; // target base address

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[SOURCE_REGISTER1 - 1:SOURCE_REGISTER1 - REGISTER_SIZE]; // cpu register where target base addr is stored
            rf_read_addr2 = instruction[SOURCE_REGISTER2 - 1:SOURCE_REGISTER2 - REGISTER_SIZE]; // data value to store into data memory

            dm_write_enable = 1;
            dm_write_addr = alu_data_out;

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
            rf_read_addr1 = instruction[SOURCE_REGISTER1 - 1:SOURCE_REGISTER1 - REGISTER_SIZE];

            rf_write_enable = 1;
            rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE];
            rf_write_data = alu_data_out;

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
            alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_AMOUNT - 1:XLEN - IRII_IMMEDIATE]; //Shift amount is lower 5 bits of immediate value
            alu_data_in_a = rf_read_data1;
        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 & instruction[XLEN - 1:XLEN - 7] == 7'b0000000) begin : SRLI

            alu_sel = SRL;
            alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_AMOUNT - 1:XLEN - IRII_IMMEDIATE];
            alu_data_in_a = rf_read_data1;

        end
        if (instruction[FUNCT3 - 1:FUNCT3 - FUNCT3_SIZE] == 3'b101 & instruction[XLEN - 1:XLEN - 7] == 7'b0100000) begin : SRAI

            alu_sel = SRA;
            alu_shift_amt = instruction[XLEN - IRII_IMMEDIATE + SHIFT_AMOUNT - 1:XLEN - IRII_IMMEDIATE];
            alu_data_in_a = rf_read_data1;

        end
    end

    IRRO: begin

        alu_enable = 1;

        rf_read_enable1 = 1;
        rf_read_enable2 = 1;
        rf_read_addr1 = instruction[SOURCE_REGISTER1 - 1:SOURCE_REGISTER1 - REGISTER_SIZE];
        rf_read_addr2 = instruction[SOURCE_REGISTER2 - 1:SOURCE_REGISTER2 - REGISTER_SIZE];

        rf_write_enable = 1;
        rf_write_addr = instruction[DESTINATION_REGISTER - 1:DESTINATION_REGISTER - REGISTER_SIZE];
        rf_write_data = alu_data_out;
        
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

end

endmodule