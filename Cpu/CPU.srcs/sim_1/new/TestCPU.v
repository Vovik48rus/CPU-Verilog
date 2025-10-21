`timescale 1ns / 1ps

module TestCPU;

reg clk;
always #5 clk <= ~clk;

initial 
begin
    clk = 0;
end

always@ (posedge clk)
begin
    if (cpu_1.pc == 28)
    begin
        $finish;
    end
end

CPU cpu_1(
    .clk(clk),
    .reset(0)
);


endmodule
