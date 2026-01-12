module controller (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg rf_we,
    output reg mem_we,
    output reg [1:0] wb_sel,
    output reg alu_src,
    output reg [2:0] imm_sel,
    output reg [3:0] alu_ctrl,
    output reg branch,
    output reg jump
);
    always @(*) begin
        rf_we = 0; 
        mem_we = 0; 
        wb_sel = 0; 
        alu_src = 0; 
        imm_sel = 0; 
        alu_ctrl = 0;
        branch =0;
        jump = 0;

        case (opcode)
            7'b0110011: begin
                rf_we = 1; alu_src = 0; wb_sel = 0;
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'h1 : 4'h0;
                    3'b001: alu_ctrl = 4'h2;
                    3'b010: alu_ctrl = 4'h3;
                    3'b100: alu_ctrl = 4'h5;
                    3'b101: alu_ctrl = (funct7[5]) ? 4'h7 : 4'h6;
                    3'b110: alu_ctrl = 4'h8;
                    3'b111: alu_ctrl = 4'h9;
                    default: alu_ctrl = 4'h0;
                endcase
            end
            7'b0010011: begin
                rf_we = 1; alu_src = 1; wb_sel = 0; imm_sel = 3'b000;
                case (funct3)
                    3'b000: alu_ctrl = 4'h0;
                    3'b010: alu_ctrl = 4'h3;
                    3'b100: alu_ctrl = 4'h5;
                    3'b110: alu_ctrl = 4'h8;
                    3'b111: alu_ctrl = 4'h9;
                    default: alu_ctrl = 4'h0;
                endcase
            end
            7'b1100011: begin
                rf_we   = 0;
                mem_we  = 0;
                alu_src = 0;
                wb_sel  = 0;
                imm_sel = 3'b010;
                alu_ctrl = 4'h1;
                branch  = 1;
                jump    = 0;
            end
            7'b1101111: begin
                rf_we   = 1;
                mem_we  = 0;
                alu_src = 0;
                wb_sel  = 2'b10;
                imm_sel = 3'b100;
                alu_ctrl = 4'h0;
                branch  = 0;
                jump    = 1;
            end
            7'b0000011: begin
                rf_we = 1; 
                alu_src = 1; 
                wb_sel = 2'b01; 
                imm_sel = 3'b000;
                mem_we = 0; 
                alu_ctrl = 4'h0;
            end
            7'b0100011: begin
                rf_we = 0; 
                alu_src = 1; 
                imm_sel = 3'b001;
                mem_we = 1; 
                alu_ctrl = 4'h0;
            end
            7'b0110111: begin
                 rf_we = 1; 
                 alu_src = 1; 
                 wb_sel = 2'b00; 
                 imm_sel = 3'b011;
            end
        endcase
    end
endmodule