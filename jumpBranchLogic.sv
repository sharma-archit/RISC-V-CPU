module jumpBranchLogic (
    input [11:0] offset,
    input [19:0] jal_offset,
    input [31:0] data_in1,
    input [31:0] data_in2,
    input [2:0]  operation,
    input [31:0] address_in, // tie to program counter
    output[31:0] address_out
);

logic [11:0] BRANCH_offset, JALR_offset;
enum {JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU} JBL_OP;

    always_comb begin
        
        //Reordering offset
        BRANCH_offset[11:0] = {offset[11], offset[0], offset[10:6], offset[5:1]};
        JALR_offset = offset; 
        
        case (operation)
            
            JAL: begin
                
                address_out = address_in + {(31-20){jal_offset[20-1]}, jal_offset} + 4;
            end

            JALR: begin
                address_out =  address_in + {(31-20){JALR_offset[20-1]}, JALR_offset} + 4;
                
            end

            BEQ : begin

                if (data_in1 == data_in2) begin
                    
                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}
                    
                end
                else begin
                    address_out = address_in;
                end
                
            end

            BNE: begin
                if (data_in1 != data_in2) begin 

                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}

                end
                else begin
                    address_out = address_in;
                end  

            end

            BLT: begin
                if (data_in1 < data_in2) begin    

                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}

                end
                else begin
                    address_out = address_in;
                end

            end

            BGE: begin
                
                if (unsigned(data_in1) >= unsigned(data_in2)) begin  

                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}

                end
                else begin

                    address_out = address_in;

                end

            end

            BLTU: begin

                if (unsigned(data_in1) < unsigned(data_in2)) begin

                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}

                end
                else begin
                    address_out = address_in;
                end 

            end


            BGEU: begin

                if (unsigned(data_in1) >= unsigned(data_in2)) begin

                    address_out = address_in + {(31-12){BRANCH_offset[12-1]}, BRANCH_offset}

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