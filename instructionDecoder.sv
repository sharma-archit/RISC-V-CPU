module instructionDecoder #(parameter XLEN=32;)
(
    input logic [XLEN-1:0] instruction,
    output 
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

wire register_source_2_data;
wire register_write_data;
wire computed_PC;

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
        alu_data_in_a = instruction[31:12];
        alu_data_in_b = register_source_2_data;
        
        rf_write_enable = 1;
        rf_write_addr = instruction[11:7]; //which CPU reg to write to
        rf_write_data = alu_data_out; //rf write data to be computed in the execute cycle
        
    end

    AUIPC: begin
        
        alu_enable = 1;
        alu_sel = AUIPC;
        alu_shift_amt = '0;
        alu_data_in_a = instruction[31:12];
        alu_data_in_b = PC; //Make sure PC value is the value to the AUIPC instruction

        rf_write_enable = 1;
        rf_write_addr = instruction[11:7]; //which CPU reg to write to
        rf_write_data = alu_data_out; //rf write data to be computed in the execute cycle

    end

    JAL: begin
        
        jbl_operation = JAL;
        jbl_jal_offset = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
        jbl_address_in = PC; //Make sure the PC value is the value of the JAL instruction
        computed_PC = jbl_address_out;

        rf_write_enable = 1;
        rf_write_addr = instruction[11:7];
        rf_write_data = PC + 4;

    end

    JALR: begin
        
        jbl_operation = JALR;
        jbl_offset = instruction[31:20];
        jbl_address_in = rf_read_data1;
        computed_PC = jbl_address_out;

        // read register rs1, write PC+4 to register rd
        rf_read_enable1 = 1;
        rf_read_addr1 = instruction[19:15];
        rf_write_enable = 1;
        rf_write_addr = instruction[11:7];
        rf_write_data = PC + 4;

    end

    FENCE: begin
    end

    BRANCH: begin
        if (instruction_decoder[14:12] == 3'b000) begin : BEQ
        
            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 1;

        end
        if (instruction_decoder[14:12] == 3'b001) begin : BNE

            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 2;

        end
        if (instruction_decoder[14:12] == 3'b100) begin : BLT

            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 3;

        end
        if (instruction_decoder[14:12] == 3'b101) begin : BGE

            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 4;

        end
        if (instruction_decoder[14:12] == 3'b110) begin : BLTU

            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 5;

        end
        if (instruction_decoder[14:12] == 3'b111) begin : BGEU

            immediate_decoder = {instruction_decoder[31:25], instruction_decoder[11:7]};
            sign_extend_decoder = 1;
            pc_decoder = pc_input_decoder;
            control_transfer_adder_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[24:20];
            constrol_transfer_comparator_decoder = 6;

        end
    end
    
    LOAD: begin
        if (instruction_decoder[14:12] == 3'b000) begin : LB

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:20]}; // target address offset
            alu_data_in_b = rf_read_data1; //target base address
            
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:5]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[11:7]; //address of destination cpu register to load data into
            rf_write_data = { {(32-8){dm_read_data[7]}}, dm_read_data[7:0]};
            
            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001) begin : LH

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:20]}; // target address offset
            alu_data_in_b = rf_read_data1; //target base address
            
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:5]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[11:7]; //address of destination cpu register to load data into
            rf_write_data = { {(32-16){dm_read_data[15]}}, dm_read_data[15:0]}; // sign extended data from memory
            
            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b010) begin : LW

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:20]}; // target address offset
            alu_data_in_b = rf_read_data1; //target base address
            
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:5]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[11:7]; //address of destination cpu register to load data into
            rf_write_data = dm_read_data;
            
            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b100) begin : LBU

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:20]}; // target address offset
            alu_data_in_b = rf_read_data1; //target base address
            
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:5]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[11:7]; //address of destination cpu register to load data into
            rf_write_data = { {(32-8){0}}, dm_read_data[7:0]}; //zero extended data from memory
            
            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b101) begin : LHU

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:20]}; // target address offset
            alu_data_in_b = rf_read_data1; //target base address
            
            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:5]; // address of cpu register holding base address
            
            rf_write_enable = 1;
            rf_write_addr = instruction[11:7]; //address of destination cpu register to load data into
            rf_write_data = {{(32-16){0}}, dm_read_data[15:0]}; //zero extended data from memory
            
            dm_read_enable = 1;
            dm_read_addr = alu_data_out;

        end
    end

    STORE: begin
        if (instruction_decoder[14:12] == 3'b000) begin : SB
            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:25], instruction[11:7]}; // target address offset 
            alu_data_in_b = rf_read_data1; // target base address

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15]; // cpu register where target base addr is stored
            rf_read_addr2 = instruction[24:20]; // data value to store into data memory

            dm_write_enable = 1;
            dm_write_addr = alu_data_out;
            dm_write_data = {{(32-8){rf_read_data2[7]}, rf_read_data2[7:0]}; // data byte sign extended to 32 bits

        end
        if (instruction_decoder[14:12] == 3'b001) begin : SH

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:25], instruction[11:7]};
            alu_data_in_b = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            dm_write_enable = 1;
            dm_write_addr = alu_data_out;
            dm_write_data = {{(32-16){rf_read_data2[15]}}, rf_read_data2[15:0]};

        end
        if (instruction_decoder[14:12] == 3'b010) begin : SW

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = {{(32-12){instruction[32-1]}}, instruction[31:25], instruction[11:7]};
            alu_data_in_b = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            dm_write_enable = 1;
            dm_write_addr = alu_data_out;
            dm_write_data = rf_read_data2;

        end
    end

    IRII: begin 
        if (instruction_decoder[14:12] == 3'b000) begin : ADDI

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;
            
        end
        if (instruction_decoder[14:12] == 3'b010) begin : SLTI

            alu_enable = 1;
            alu_sel = SLT;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b011) begin : SLTIU

            alu_enable = 1;
            alu_sel = SLTU;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b100) begin : XORI

            alu_enable = 1;
            alu_sel = XOR;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b110) begin : ORI

            alu_enable = 1;
            alu_sel = OR;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b111) begin : ANDI

            alu_enable = 1;
            alu_sel = AND;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = {{(32 - 12){instruction[32 - 1]}}, instruction[31:20]}; //Sign extended immediate value

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 & instruction_decoder[31:25] == 7'b0000000) begin : SLLI

            alu_enable = 1;
            alu_sel = SLL;
            alu_shift_amt = instruction[24:20];
            alu_data_in_a = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;
        end
        if (instruction_decoder[14:12] == 3'b101 & instruction_decoder[31:25] == 7'b0000000) begin : SRLI

            alu_enable = 1;
            alu_sel = SRL;
            alu_shift_amt = instruction[24:20];
            alu_data_in_a = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b101 & instruction_decoder[31:25] == 7'b0100000) begin : SRAI

            alu_enable = 1;
            alu_sel = SRA;
            alu_shift_amt = instruction[24:20];
            alu_data_in_a = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_addr1 = instruction[19:15];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
    end

    IRRO: begin
        
        if (instruction_decoder[14:12] == 3'b000 && instruction_decoder[31:25] == 7'b0000000) begin : ADD

            alu_enable = 1;
            alu_sel = XOR;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b000 && instruction_decoder[31:25] == 7'b0100000) begin : SUB

            alu_enable = 1;
            alu_sel = SUB;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLL

            alu_enable = 1;
            alu_sel = SLL;
            alu_shift_amt = rf_read_data2[4:0];
            alu_data_in_a = rf_read_data1;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLT

            alu_enable = 1;
            alu_sel = SLT;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLTU

            alu_enable = 1;
            alu_sel = SLTU;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : XOR

            alu_enable = 1;
            alu_sel = XOR;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SRL

            alu_enable = 1;
            alu_sel = SRL;
            alu_shift_amt = rf_read_data2[4:0];
            alu_data_in_a = rf_read_data1;
            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0100000) begin : SRA

            alu_enable = 1;
            alu_sel = SRA;
            alu_shift_amt = rf_read_data2[4:0];
            alu_data_in_a = rf_read_data1;
            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : OR

            alu_enable = 1;
            alu_sel = OR;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : AND

            alu_enable = 1;
            alu_sel = ADD;
            alu_data_in_a = rf_read_data1;
            alu_data_in_b = rf_read_data2;

            rf_read_enable1 = 1;
            rf_read_enable2 = 1;
            rf_read_addr1 = instruction[19:15];
            rf_read_addr2 = instruction[24:20];

            rf_write_enable = 1;
            rf_write_addr = instruction[11:7];
            rf_write_data = alu_data_out;

        end

    end
    
    ECB: begin
        
        if(instruction_decoder[31:20] == 12'b000000000000) begin : ECALL
        end
        if(instruction_decoder[31:20] == 12'b000000000001) begin : EBREAK
        end
    end
    
    default: 
    // check if riscv requires us to raise an exception if invalid instruction
endcase

end

endmodule