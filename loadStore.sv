module loadStore #(parameter OFFSET_SIZE = 12;
                   parameter DATA_WIDTH = 3;
                   parameter XLEN = 32;)
(
    input load_enable,
    input store_enable,
    input [XLEN - 1:0] base_addr,
    input [OFFSET_SIZE - 1:0] offset,
    input [DATA_WIDTH - 1:0] width,
    input [XLEN - 1:0] data_in_memory,          // data read from data memory
    input [XLEN - 1:0] data_in_register,        // data read from register file
    output logic [XLEN - 1:0] target_addr,
    output logic [XLEN - 1:0] data_out_memory,  // data to store into data memory
    output logic [XLEN - 1:0] data_out_register // data to load into register file
);

enum {WORD, HALFWORD, BYTE, BYTE_UNSIGNED, HALFWORD_UNSIGNED} SIZE;

always_comb begin

    target_addr = base_addr + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset};

    if (load_enable) begin

        case(width)

            WORD : begin

                data_out_register = data_in_memory;

            end

            HALFWORD : begin

                data_out_register = {(XLEN - 16){data_in_memory[15]}, data_in_memory[15:0]}; // Data sign-extended

            end

            HALFWORD_UNSIGNED : begin

                data_out_register = {(XLEN - 16){1'b0}, data_in_memory[15:0]}; // Unsigned data zero extended

            end

            BYTE : begin

                data_out_register = {(XLEN - 8){data_in_memory[7]}, data_in_memory[7:0]};

            end

            BYTE_UNSIGNED : begin

                 data_out_register = {(XLEN - 8){1'b0}, data_in_memory[7:0]};

            end
            
            default : begin

                data_out_register = '0;

            end

        endcase
    end
    else begin

        target_addr = '0;
        data_out_register = '0;

    end
    
    if (store_enable) begin
        
        case (width)

            WORD : begin

                data_out_memory = data_in_register;

            end

            HALFWORD : begin

                data_out_memory = {(XLEN - 16){data_in_register[15]}, data_in_register[15:0]}; // Data sign-extended

            end

            BYTE : begin

                data_out_memory = {(XLEN - 8){data_in_register[7]}, data_in_register[7:0]};

            end
            
            default : begin

                data_out_memory = '0;

            end

        endcase

    end
    else begin

        target_addr = '0;
        data_out_memory = '0;

    end
    
end

endmodule