module jumpBranchLogic #(parameter OFFSET_SIZE = 12;
                         parameter JAL_OFFSET_SIZE = 20;
                         parameter OPERATION_SIZE = 3;
                         parameter XLEN = 32;)
(
    input [OPERATION_SIZE - 1:0]  operation,
    input [OFFSET_SIZE - 1:0] offset,
    input [JAL_OFFSET_SIZE - 1:0] jal_offset,
    input [XLEN - 1:0] data_in1,
    input [XLEN - 1:0] data_in2,
    input [XLEN - 1:0] address_in, // tie to program counter
    output[XLEN - 1:0] address_out
);

localparam PC_INCREMENT = 4;
logic [11:0] JALR_offset;
enum {JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU} JBL_OP;

    always_comb begin
        
        //Reordering offset
        //offset[11:0] = {offset[11], offset[0], offset[10:6], offset[5:1]};

        case (operation)
            
            JAL: begin
                
                address_out = address_in + {((XLEN - 1) - JAL_OFFSET_SIZE){jal_offset[JAL_OFFSET_SIZE - 1]}, jal_offset} + PC_INCREMENT;

            end

            JALR: begin

                address_out =  address_in + {((XLEN - 1) - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset} + PC_INCREMENT;
                
            end

            BEQ : begin

                if (data_in1 == data_in2) begin
                    
                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}
                    
                end
                else begin

                    address_out = address_in;

                end
                
            end

            BNE: begin
                if (data_in1 != data_in2) begin 

                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}

                end
                else begin

                    address_out = address_in;

                end  

            end

            BLT: begin
                if (data_in1 < data_in2) begin    

                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}

                end
                else begin

                    address_out = address_in;

                end

            end

            BGE: begin
                
                if (unsigned(data_in1) >= unsigned(data_in2)) begin  

                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}

                end
                else begin

                    address_out = address_in;

                end

            end

            BLTU: begin

                if (unsigned(data_in1) < unsigned(data_in2)) begin

                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}

                end
                else begin

                    address_out = address_in;

                end 

            end


            BGEU: begin

                if (unsigned(data_in1) >= unsigned(data_in2)) begin

                    address_out = address_in + {(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}, offset}

                end
                else begin

                    address_out = address_in;

                end 

            end

            default: begin 

                address_out = address_in;
                
            end

        endcase

    end

endmodule