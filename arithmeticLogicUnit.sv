module ALU(
    input  [n:0]  sel,
    input  [4:0]  shift_amt
    input  [31:0] data_in_a,
    input  [31:0] data_in_b,
    output logic [31:0] data_out
    );
endmodule

enum {ADD, SUB, SLT, SLTU, AND, OR, XOR, SLL, SRL, SRA} ALU_OP;

always_comb begin 

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

    default:
        data_out = 0;

endcase

end