module instructionDecoder (
    input logic [31:0] instruction_decoder,
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


always_comb begin

// decode each instruction
case (instruction_decoder[6:0])
    LUI: begin
        
        immediate_decoder = instruction_decoder[31:12]
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:0];
        fill_zero_decoder = 1;
        memory_input_decoder = 1;
        
    end

    AUIPC: begin
        
        immediate_decoder = instruction_decoder[31:12]
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:0];
        fill_zero_decoder = 1;
        memory_input_decoder = 1;
        pc_decoder = pc_input_decoder;

    end

    JAL: begin
        
        immediate_decoder = instruction_decoder[31:12];
        sign_extend_decoder = 1;
        pc_decoder = pc_input_decoder;
        control_transfer_adder_decoder = 1;
        reg_address_decoder = instruction_decoder[11:7];

    end

    JALR: begin

        immediate_decoder = instruction_decoder[20:31];
        reg_read1_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        sign_extend_decoder = 1;
        control_transfer_adder_decoder = 1;
        pc_decoder = pc_input_decoder;
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

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
    
    LOADS: begin
        if (instruction_decoder[14:12] == 3'b000) begin : LB

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_write_enable_decoder = 1;
            data_memory_read_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            data_memory_bit_length = 0;

        end
        if (instruction_decoder[14:12] == 3'b001) begin : LH

            immediate_decoder = instruction_decoder[31:20];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_write_enable_decoder = 1;
            data_memory_read_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            data_memory_bit_length = 1;

        end
        if (instruction_decoder[14:12] == 3'b010) begin : LW

            immediate_decoder = instruction_decoder[31:20];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_write_enable_decoder = 1;
            data_memory_read_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            data_memory_bit_length = 2;

        end
        if (instruction_decoder[14:12] == 3'b100) begin : LBU

            immediate_decoder = instruction_decoder[31:20];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_write_enable_decoder = 1;
            data_memory_read_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            data_memory_bit_length = 3;

        end
        if (instruction_decoder[14:12] == 3'b101) begin : LHU

            immediate_decoder = instruction_decoder[31:20];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_write_enable_decoder = 1;
            data_memory_read_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            data_memory_bit_length = 4;

        end
    end

    STORE: begin
        if (instruction_decoder[14:12] == 3'b000) begin : SB

            immediate_decoder = instruction_decoder[31:25];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[11:7];
            data_memory_input_decoder = 1
            data_memory_write_enable_decoder = 1;
            data_memory_bit_length = 0;

        end
        if (instruction_decoder[14:12] == 3'b001) begin : SH

            immediate_decoder = instruction_decoder[31:25];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[11:7];
            data_memory_input_decoder = 1
            data_memory_write_enable_decoder = 1;
            data_memory_bit_length = 1;

        end
        if (instruction_decoder[14:12] == 3'b010) begin : SW

            immediate_decoder = instruction_decoder[31:25];
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 1;
            reg_read2_enable_decoder = 1;
            reg_read2_address_decoder = instruction_decoder[11:7];
            data_memory_input_decoder = 1
            data_memory_write_enable_decoder = 1;
            data_memory_bit_length = 2;

        end
    end

    IRII: begin 
        if (instruction_decoder[14:12] == 3'b000) begin : ADDI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b000;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];
            
        end
        if (instruction_decoder[14:12] == 3'b010) begin : SLTI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b010;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b011) begin : SLTIU

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b011;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b100) begin : XORI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b100;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b110) begin : ORI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b110;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b111) begin : ANDI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b111;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 & instruction_decoder[31:25] == 7'b0000000) begin : SLLI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b001;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b101 & instruction_decoder[31:25] == 7'b0000000) begin : SRLI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b101;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b101 & instruction_decoder[31:25] == 7'b0100000) begin : SRAI

            immediate_decoder = instruction_decoder[31:20];
            sign_extend_decoder = 1;
            reg_read1_enable_decoder = 1;
            reg_read1_address_decoder = instruction_decoder[19:15];
            alu_function_decoder = 3'b001;
            reg_write_enable_decoder = 1;
            reg_write_address_decoder = instruction_decoder[11:7];

        end
    end

    IRRO: begin
        
        if (instruction_decoder[14:12] == 3'b000 && instruction_decoder[31:25] == 7'b0000000) begin : ADD

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b000 && instruction_decoder[31:25] == 7'b0100000) begin : SUB

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLL

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLT

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SLTU

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : XOR

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : SRL

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0100000) begin : SRA

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : OR

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end
        if (instruction_decoder[14:12] == 3'b001 && instruction_decoder[31:25] == 7'b0000000) begin : AND

        reg_read1_enable_decoder = 1;
        reg_read2_enable_decoder = 1;
        reg_read1_address_decoder = instruction_decoder[19:15];
        reg_read2_address_decoder = instruction_decoder[24:20];
        alu_function_decoder = instruction_decoder[14:12];
        reg_write_enable_decoder = 1;
        reg_write_address_decoder = instruction_decoder[11:7];

        end

    end
    
    ECB: 
    
    default: 
    // check if riscv requires us to raise an exception if invalid instruction 
endcase

end

endmodule