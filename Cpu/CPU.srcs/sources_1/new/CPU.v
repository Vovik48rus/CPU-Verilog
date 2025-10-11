`timescale 1ns / 1ps

module CPU(
    input clk, reset
);

localparam CMD_SIZE = 24;
localparam CMD_MEM_SIZE = 1024;
localparam LIT_SIZE = 10;
localparam DATA_MEM_SIZE = 1024;
localparam RF_SIZE = 16;
localparam ADDR_CMD_MEM_SIZE = $clog2(CMD_MEM_SIZE);
localparam ADDR_DATA_MEM_SIZE = $clog2(DATA_MEM_SIZE);
localparam ADDR_RF_SIZE = $clog2(RF_SIZE);
localparam KOP_SIZE = 4;

localparam NOP = 0, LTM = 1, MTR = 2, RTR = 3, SUB = 4, JUMP_LESS = 5, MTRK = 6, RTMK = 7, JMP = 8, SUM = 9;

/*
    NOP
    КОП
    --------------------
    LTM
    КОП literal adr_m_1
    --------------------
    MTR
    КОП adr_r_1 00000000 adr_m_1
    --------------------
    RTR
    КОП adr_r1 adr_r2 00000000 
    --------------------
    SUB
    КОП adr_r_1 adr_r_2 adr_r_3 00000000 
    --------------------
    
    КОП 
    --------------------


*/

reg [CMD_SIZE - 1: 0] cmd_mem [0: CMD_MEM_SIZE - 1];
reg [LIT_SIZE - 1: 0] mem [0:DATA_MEM_SIZE - 1];
reg [CMD_SIZE - 1: 0] cmd_reg;
reg [LIT_SIZE - 1: 0] RF [0: RF_SIZE - 1];
reg [ADDR_CMD_MEM_SIZE - 1: 0] pc;
reg [2: 0] stage_counter;
reg [LIT_SIZE - 1: 0] op1, op2;
reg [LIT_SIZE - 1: 0] res;

integer i;
initial begin
    $readmemb("program.mem", cmd_mem);
    for (i = 0; i < DATA_MEM_SIZE ; i = i + 1)
    begin
        mem[i] <= 0;    
    end
    for (i = 0; i < RF_SIZE ; i = i + 1)
    begin
        RF[i] <= 0;    
    end
end

wire [KOP_SIZE - 1: 0] cop = cmd_reg[CMD_SIZE - 1 -: KOP_SIZE];
wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE -: ADDR_DATA_MEM_SIZE];
wire [LIT_SIZE - 1: 0] literal = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - ADDR_DATA_MEM_SIZE -: LIT_SIZE];
wire [ADDR_RF_SIZE - 1: 0] adr_r_1 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE -: ADDR_RF_SIZE];
wire [ADDR_RF_SIZE - 1: 0] adr_r_2 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];
wire [ADDR_RF_SIZE - 1: 0] adr_r_3 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE];

wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jmp = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - 2*ADDR_RF_SIZE - 2 -: ADDR_CMD_MEM_SIZE];

always @(posedge clk)
begin
    if (reset)
    begin
        stage_counter <= 0;    
    end
    else begin
        if (stage_counter == 4)
        begin
            stage_counter <= 0;    
        end
        else begin
            stage_counter <= stage_counter + 1;
        end
    end
end


always @(posedge clk)
begin
    if (reset) 
    begin
        cmd_reg <= 0;
    end
    else begin
        if (stage_counter == 0)
        begin
            cmd_reg <= cmd_mem[pc];    
        end
    end
end


always @(posedge clk)
begin
    if (reset) 
    begin
        op1 <= 0;
    end
    else begin
        if (stage_counter == 1)
        begin
            case (cop)
                LTM: op1 <= literal;
                MTR: op1 <= mem[adr_m_1];
                RTR, MTRK: op1 <= RF[adr_r_2];
                SUB, JUMP_LESS, RTMK: op1 <= RF[adr_r_1];
                JMP: op1 <= adr_to_jmp;
            endcase  
        end
    end
end

always @(posedge clk)
begin
    if (reset) 
    begin
        op2 <= 0;
    end
    else begin
        if (stage_counter == 2)
        begin
            case (cop)
                SUB, SUM, JUMP_LESS: op2 <= RF[adr_r_2];
            endcase  
        end
    end
end

always @(posedge clk)
begin
    if (reset) 
    begin
        res <= 0;
    end
    else begin
        if (stage_counter == 3)
        begin
            case (cop)
                LTM, MTRK, MTR, RTR, RTMK, JMP: res <= op1;
                SUB: res <= op1 - op2;
                SUM: res <= op1 + op2;
                JUMP_LESS: res <= op1 < op2;
            endcase  
        end
    end
end

always @(posedge clk)
begin
    if (reset) 
    begin
        pc <= 0;
    end
    else begin
        if (stage_counter == 4)
        begin
            case (cop)
                JUMP_LESS:
                begin
                    if (res != 0)
                    begin
                        pc <= adr_to_jmp;
                    end
                    else begin
                        pc <= pc + 1;
                    end
                end
                JMP: pc <= res;
                default: pc <= pc + 1;
            endcase  
        end
    end
end

always @(posedge clk)
begin
    if (stage_counter == 4)
    begin
        case (cop)
            LTM: mem[adr_m_1] <= res;
            MTR, RTR: RF[adr_r_1] <= res;
            SUB: RF[adr_r_3] <= res;
            MTRK: RF[adr_r_1] <= mem[res];
            RTMK: mem[res] <= RF[adr_r_2];
        endcase    
    end
end

endmodule
