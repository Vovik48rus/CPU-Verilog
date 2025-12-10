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
     if (CPU_pipeline.pc == 100)
     begin
         $finish;
     end
end

CPU_pipeline cpu(
    .clk(clk), 
    .reset(1'b0)
);

endmodule
