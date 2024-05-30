module ALU #(parameter SEL_SIZE = 4;
             parameter SHIFT_SIZE = 5;
             parameter XLEN = 32;)
(
    input  enable;
    input  [SEL_SIZE - 1:0]  sel,
    input  [SHIFT_SIZE:0]  shift_amt,
    input  [XLEN - 1:0] data_in_a,
    input  [XLEN - 1:0] data_in_b,
    output logic [XLEN - 1:0] data_out    
    );

enum {ADD, SUB, SLT, SLTU, AND, OR, XOR, SLL, SRL, SRA, LUI, AUIPC, LOAD, STORE} ALU_OP;

always_comb begin

if (enable) begin

    case (sel)

        ADD: begin

            data_out = data_in_a + data_in_b;

        end

        SUB: begin

            data_out = data_in_b - data_in_a;

        end
        
        SLT: begin

            if (data_in_a < data_in_b) begin

                data_out = 1;

            end
            else begin 

                data_out = 0;

            end

        end

        SLTU: begin

             if (unsigned(data_in_a) < unsigned(data_in_b)) begin

                data_out = 1;

            end
            else begin 

                data_out = 0;
                
            end
        end
        
        AND: begin

            data_out = data_in_a & data_in_b;

        end

        OR: begin
            
            data_out = data_in_a | data_in_b;

        end

        XOR: begin
            
            data_out = data_in_a ^ data_in_b;

        end

        SLL: begin
            
            data_out = data_in_a << shift_amt;

        end
        
        SRL: begin
            
            data_out = data_in_a >> shift_amt;

        end

        SRA: begin

            data_out = data_in_a >>> shift_amt;
            
        end

        LUI: begin

            data_out = {data_in_a[19:0], 12'd0}; // data_in_a = 20 bit U-immediate
            
        end

        AUIPC: begin

            data_out = {data_in_a[19:0], 12'd0} + data_in_b; // data_in_a = 20 bit u-immediate, data_in_b = 32-bit addr of AUIPC instruction

        end

        LOAD | STORE: begin

            data_out = data_in_a + {(20){data_in_b[12 - 1]}, data_in_b}; // data_in_a = base address, data_in_b = 12 bit offset, data_out = target address

        end

    default:
        data_out = 0;

end else begin
    
    data_out = '0;

end

endcase

end

endmodule