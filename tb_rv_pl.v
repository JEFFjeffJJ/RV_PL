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

        $readmemh("fibo.mem", DUT.IMEM.RAM);

        rst_n = 0;
        #20 rst_n = 1;

        #2000;
        $display("FINAL RESULT (x10) = %d", DUT.RF.regs[10]);
        
        $finish;
    end
endmodule