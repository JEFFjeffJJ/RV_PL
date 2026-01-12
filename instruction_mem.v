module instruction_mem (
    input [31:0] addr,
    output [31:0] inst
);
    reg [31:0] RAM [0:1023];
    assign inst = RAM[addr[11:2]];
endmodule