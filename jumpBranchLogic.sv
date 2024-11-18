module jumpBranchLogic #(parameter OFFSET_SIZE = 12,
                         parameter JAL_OFFSET_SIZE = 20,
                         parameter OPERATION_SIZE = 3,
                         parameter XLEN = 32)
(
    input [OPERATION_SIZE - 1:0]  operation,
    input signed [OFFSET_SIZE - 1:0] offset,
    input signed [JAL_OFFSET_SIZE - 1:0] jal_offset,
    input signed [XLEN - 1:0] data_in1,
    input signed [XLEN - 1:0] data_in2,
    input [XLEN - 1:0] address_in, // tie to program counter
    output logic [XLEN - 1:0] address_out
);

enum {JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU} JBL_OP;

    always_comb begin

        case (operation)
            
            JAL: begin
                
                address_out = address_in + {{(XLEN - JAL_OFFSET_SIZE){jal_offset[JAL_OFFSET_SIZE - 1]}}, jal_offset};

            end

            JALR: begin

                address_out =  address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};
                
            end

            BEQ : begin

                if (data_in1 == data_in2) begin
                    
                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};
                    
                end
                else begin

                    address_out = address_in;

                end
                
            end

            BNE: begin
                if (data_in1 != data_in2) begin 

                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};

                end
                else begin

                    address_out = address_in;

                end  

            end

            BLT: begin
                if (data_in1 < data_in2) begin    

                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};

                end
                else begin

                    address_out = address_in;

                end

            end

            BGE: begin
                
                if (unsigned'(data_in1) >= unsigned'(data_in2)) begin  

                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};

                end
                else begin

                    address_out = address_in;

                end

            end

            BLTU: begin

                if (unsigned'(data_in1) < unsigned'(data_in2)) begin

                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};

                end
                else begin

                    address_out = address_in;

                end 

            end


            BGEU: begin

                if (unsigned'(data_in1) >= unsigned'(data_in2)) begin

                    address_out = address_in + {{(XLEN - OFFSET_SIZE){offset[OFFSET_SIZE - 1]}}, offset};

                end
                else begin

                    address_out = address_in;

                end 

            end

            default: begin 

                address_out = address_in;
                
            end

        endcase

        if (address_out < 0) begin
            
            address_out = address_in;

        end

    end

endmodule