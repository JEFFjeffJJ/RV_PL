module alu (
    input [31:0] a, b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output reg zero
);

    always @(*) begin
        case (alu_ctrl)
            4'h0: result = a + b;
            4'h1: result = a - b;
            4'h2: result = a << b[4:0];
            4'h3: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'h4: result = (a < b) ? 32'd1 : 32'd0;
            4'h5: result = a ^ b;
            4'h6: result = a >> b[4:0];
            4'h7: result = $signed(a) >>> b[4:0];
            4'h8: result = a | b;
            4'h9: result = a & b;
            default: result = 32'b0;
        endcase
        zero = (result == 0);
    end
endmodule