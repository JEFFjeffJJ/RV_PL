module hazard_unit (
    input [4:0] rs1_E, rs2_E,
    input [4:0] rs1_D, rs2_D,
    input [4:0] rd_M, rd_W,
    input reg_write_M, reg_write_W,
    input [1:0] wb_sel_E,
    input pc_src_E,
    input jump_E,
    input [4:0] rd_E,
    
    output reg [1:0] forward_a_E, forward_b_E,
    output stall_F, stall_D,
    output flush_D, flush_E
);
    wire lw_stall;

    always @(*) begin
        if ((rs1_E == rd_M) && reg_write_M && (rs1_E != 0)) 
            forward_a_E = 2'b10;
        else if ((rs1_E == rd_W) && reg_write_W && (rs1_E != 0)) 
            forward_a_E = 2'b01;
        else 
            forward_a_E = 2'b00;

        if ((rs2_E == rd_M) && reg_write_M && (rs2_E != 0)) 
            forward_b_E = 2'b10;
        else if ((rs2_E == rd_W) && reg_write_W && (rs2_E != 0)) 
            forward_b_E = 2'b01;
        else 
            forward_b_E = 2'b00;
    end
    
    assign lw_stall = (wb_sel_E == 2'b01) && (rd_E != 0) &&
                      ((rs1_D == rd_E) || (rs2_D == rd_E));
    
    assign stall_F = lw_stall;
    assign stall_D = lw_stall;

    assign flush_D = pc_src_E || jump_E; 
    assign flush_E = lw_stall || pc_src_E || jump_E;

endmodule