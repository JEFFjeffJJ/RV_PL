`include "rv_pl.v"

`timescale 1ns/1ps

module tb_rv_pl;
    reg clk, rst_n;

    rv_pl DUT (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("wave_pl.vcd");
        $dumpvars(0, tb_rv_pl);

        $readmemh("test.mem", DUT.IMEM.RAM);

        rst_n = 0;
        #20 rst_n = 1;

        #200;
        
        $display("x1 = %d", DUT.RF.regs[1]);
        $display("x2 = %d", DUT.RF.regs[2]);
        $display("x3 = %d", DUT.RF.regs[3]);
        
        $finish;
    end
endmodule