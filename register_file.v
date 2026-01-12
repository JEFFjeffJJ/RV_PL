module register_file (
    input clk,
    input rst_n,
    input we,
    input [4:0] rs1, rs2, rd,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];
    integer i;

    assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
        end else if (we && (rd != 5'b0)) begin
            regs[rd] <= wd;
        end
    end
endmodule