`include "alu.v"
`include "controller.v"
`include "data_mem.v"
`include "hazard_unit.v"
`include "instruction_mem.v"
`include "register_file.v"
`include "sign_extender.v"

module rv_pl (
    input clk,
    input rst_n
);
    wire stall_F, stall_D, flush_D, flush_E;
    wire [1:0] forward_a_E, forward_b_E;

    reg [31:0] PC;
    wire [31:0] PC_Next, PC_Plus4, PC_Target_E, Instr;
    wire pc_src_E, jump_E; 

    assign PC_Plus4 = PC + 4;
    assign PC_Next = (pc_src_E || jump_E) ? PC_Target_E : PC_Plus4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PC <= 0;
        else if (!stall_F) PC <= PC_Next;
    end

    instruction_mem IMEM (.addr(PC), .inst(Instr));

    reg [31:0] ID_PC, ID_Instr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            ID_PC <= 0; 
            ID_Instr <= 0; 
        end
        else if (flush_D) begin 
            ID_PC <= 0; 
            ID_Instr <= 0; 
        end
        else if (!stall_D) begin 
            ID_PC <= PC; 
            ID_Instr <= Instr; 
        end
    end

    wire [31:0] Reg_RD1, Reg_RD2, Imm_Ext;
    wire ctrl_rf_we, ctrl_mem_we, ctrl_alu_src, ctrl_branch, ctrl_jump;
    wire [1:0] ctrl_wb_sel;
    wire [2:0] ctrl_imm_sel;
    wire [3:0] ctrl_alu_ctrl;

    controller CTRL (
        .opcode(ID_Instr[6:0]), .funct3(ID_Instr[14:12]), .funct7(ID_Instr[31:25]),
        .rf_we(ctrl_rf_we), .mem_we(ctrl_mem_we), .wb_sel(ctrl_wb_sel),
        .alu_src(ctrl_alu_src), .imm_sel(ctrl_imm_sel), .alu_ctrl(ctrl_alu_ctrl),
        .branch(ctrl_branch), .jump(ctrl_jump)
    );

    register_file RF (
        .clk(clk), .rst_n(rst_n), .we(WB_rf_we),
        .rs1(ID_Instr[19:15]), .rs2(ID_Instr[24:20]), .rd(WB_rd),
        .wd(WB_Write_Back_Data), .rd1(Reg_RD1), .rd2(Reg_RD2)
    );

    sign_extender SEXT (.inst(ID_Instr), .imm_sel(ctrl_imm_sel), .imm(Imm_Ext));

    reg EX_rf_we, EX_mem_we, EX_alu_src, EX_branch, EX_jump;
    reg [1:0] EX_wb_sel;
    reg [3:0] EX_alu_ctrl;
    reg [31:0] EX_PC, EX_RD1, EX_RD2, EX_Imm;
    reg [4:0] EX_rd, EX_rs1, EX_rs2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_E) begin
            EX_rf_we<=0; 
            EX_mem_we<=0; 
            EX_wb_sel<=0; 
            EX_alu_src<=0; 
            EX_alu_ctrl<=0;
            EX_branch<=0; 
            EX_jump<=0; 
            EX_PC<=0; 
            EX_RD1<=0; 
            EX_RD2<=0; 
            EX_Imm<=0;
            EX_rd<=0; 
            EX_rs1<=0; 
            EX_rs2<=0;
        end else begin
            EX_rf_we<=ctrl_rf_we; 
            EX_mem_we<=ctrl_mem_we; 
            EX_wb_sel<=ctrl_wb_sel;
            EX_alu_src<=ctrl_alu_src; 
            EX_alu_ctrl<=ctrl_alu_ctrl;
            EX_branch<=ctrl_branch; 
            EX_jump<=ctrl_jump;
            EX_PC<=ID_PC; 
            EX_RD1<=Reg_RD1; 
            EX_RD2<=Reg_RD2; 
            EX_Imm<=Imm_Ext;
            EX_rd<=ID_Instr[11:7]; 
            EX_rs1<=ID_Instr[19:15]; 
            EX_rs2<=ID_Instr[24:20];
        end
    end

    wire [31:0] SrcA_Fwd, SrcB_Fwd, ALU_B, ALU_Result;
    wire Zero;
    reg  [31:0] MA_ALU_Result;

    assign SrcA_Fwd = (forward_a_E == 2'b10) ? MA_ALU_Result : 
                      (forward_a_E == 2'b01) ? WB_Write_Back_Data : EX_RD1;
    assign SrcB_Fwd = (forward_b_E == 2'b10) ? MA_ALU_Result : 
                      (forward_b_E == 2'b01) ? WB_Write_Back_Data : EX_RD2;

    assign ALU_B = (EX_alu_src) ? EX_Imm : SrcB_Fwd;

    alu ALU (.a(SrcA_Fwd), .b(ALU_B), .alu_ctrl(EX_alu_ctrl), .result(ALU_Result), .zero(Zero));

    assign PC_Target_E = EX_PC + EX_Imm;
    assign pc_src_E = (EX_branch && Zero);
    assign jump_E = EX_jump;

    reg MA_rf_we, MA_mem_we;
    reg [1:0] MA_wb_sel;
    reg [31:0] MA_Write_Data, MA_PC_Plus4;
    reg [4:0] MA_rd;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            MA_rf_we<=0; 
            MA_mem_we<=0; 
            MA_wb_sel<=0; 
            MA_ALU_Result<=0; 
            MA_Write_Data<=0; 
            MA_rd<=0; 
            MA_PC_Plus4<=0;
        end else begin
            MA_rf_we<=EX_rf_we; 
            MA_mem_we<=EX_mem_we; 
            MA_wb_sel<=EX_wb_sel;
            MA_ALU_Result<=ALU_Result; 
            MA_Write_Data<=SrcB_Fwd; 
            MA_rd<=EX_rd; 
            MA_PC_Plus4<=EX_PC+4;
        end
    end

    wire [31:0] Mem_Read_Data;
    data_mem DMEM (.clk(clk), .we(MA_mem_we), .addr(MA_ALU_Result), .wd(MA_Write_Data), .rd(Mem_Read_Data));

    reg WB_rf_we;
    reg [1:0] WB_wb_sel;
    reg [31:0] WB_Mem_Data, WB_ALU_Result, WB_PC_Plus4;
    reg [4:0] WB_rd;
    wire [31:0] WB_Write_Back_Data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            WB_rf_we<=0; 
            WB_wb_sel<=0; 
            WB_Mem_Data<=0; 
            WB_ALU_Result<=0; 
            WB_rd<=0; 
            WB_PC_Plus4<=0;
        end else begin
            WB_rf_we<=MA_rf_we; 
            WB_wb_sel<=MA_wb_sel; 
            WB_Mem_Data<=Mem_Read_Data;
            WB_ALU_Result<=MA_ALU_Result; 
            WB_rd<=MA_rd; 
            WB_PC_Plus4<=MA_PC_Plus4;
        end
    end

    assign WB_Write_Back_Data = (WB_wb_sel == 2'b01) ? WB_Mem_Data : 
                                (WB_wb_sel == 2'b10) ? WB_PC_Plus4 : WB_ALU_Result;

    hazard_unit HAZARD (
        .rs1_E(EX_rs1), .rs2_E(EX_rs2), .rd_M(MA_rd), .rd_W(WB_rd),
        .reg_write_M(MA_rf_we), .reg_write_W(WB_rf_we),
        .rs1_D(ID_Instr[19:15]), .rs2_D(ID_Instr[24:20]), .rd_E(EX_rd),
        .wb_sel_E(EX_wb_sel), .pc_src_E(pc_src_E), .jump_E(jump_E),
        .forward_a_E(forward_a_E), .forward_b_E(forward_b_E),
        .stall_F(stall_F), .stall_D(stall_D), .flush_D(flush_D), .flush_E(flush_E)
    );

endmodule