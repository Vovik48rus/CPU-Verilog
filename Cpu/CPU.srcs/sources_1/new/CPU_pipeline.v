`timescale 1ns / 1ps

module CPU_pipeline(
    input clk, reset
);

localparam LIT_SIZE = 10; // длина переменной котору записываем в MEM
localparam CMD_SIZE = 24; // общая длина командной строки
localparam CMD_MEM_SIZE = 1024; // максимальное количество строк в программе, максимальное количество команд
localparam RF_SIZE = 16; // количество RF в процессоре 
localparam ADDR_RF_SIZE = $clog2(RF_SIZE); // длина адреса RF 
localparam DATA_MEM_SIZE = 1024; // максимальное количество переменных хранимых в MEM памяти  
localparam ADDR_DATA_MEM_SIZE = $clog2(DATA_MEM_SIZE); // длина адреса числа хранящегося в MEM 
localparam COP_SIZE = 4; // длина представления команды в двоичном виде, без аргументов
localparam ADDR_CMD_MEM_SIZE = $clog2(CMD_MEM_SIZE); // длина номера строки в файле

localparam 
    NOP = 0, LTM = 1, MTR = 2, RTR = 3, SUB = 4, 
    JUMP_LESS = 5, MTRK = 6, RTMK = 7, JUMP = 8,
    SUM = 9;

reg [LIT_SIZE - 1 : 0] RF [0 : RF_SIZE - 1];
reg [LIT_SIZE - 1 : 0] MEM_DATA [0 : DATA_MEM_SIZE - 1];
reg [CMD_SIZE  - 1 : 0] MEM [0 : CMD_MEM_SIZE - 1]; // Загружаемая программа 

reg [ADDR_CMD_MEM_SIZE - 1 : 0] pc, pc_prev, pc_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_0, cmd_reg_0_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_1, cmd_reg_1_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_2, cmd_reg_2_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_3, cmd_reg_3_next;

reg [LIT_SIZE - 1 : 0] opA_1, opA_1_next;
reg [LIT_SIZE - 1 : 0] opA_2, opA_2_next;
reg [LIT_SIZE - 1 : 0] opB_2, opB_2_next;
reg [LIT_SIZE - 1 : 0] opB_3, opB_3_next;
reg [LIT_SIZE - 1 : 0] res, res_next;

//initialization
integer i;
initial
begin
    $readmemb("program.mem", MEM);
    for(i = 0; i < DATA_MEM_SIZE; i = i + 1)
        MEM_DATA[i] <= 0;
    for(i = 2; i < RF_SIZE; i = i + 1)
        RF[i] <= 0;
    RF[0] <= 0; RF[1] <= 1;
    
    cmd_reg_0 <= 0; cmd_reg_0_next <= 0;
    cmd_reg_1 <= 0; cmd_reg_1_next <= 0;
    cmd_reg_2 <= 0; cmd_reg_2_next <= 0;
    cmd_reg_3 <= 0; cmd_reg_3_next <= 0;
    
    opA_1 <= 0; opA_1_next <= 0;
    opA_2 <= 0; opA_2_next <= 0;
    opB_2 <= 0; opB_2_next <= 0;
    opB_3 <= 0; opB_3_next <= 0;
    
    pc <= 0; pc_next <= 0; pc_prev <= 0;
    
    res <= 0; res_next <= 0;
    cmd_1_can_move_st_2 <= 0; // ?

    cmd_1_can_move_st_3 <= 0; // ?
    cmd_2_can_move <= 0; // ?
    
end

//------------------
// PC
//------------------
wire jump_cond = cop_4 == JUMP || (cop_4 == JUMP_LESS && res == 0); // Если на WriteBack пришла команда JMP или сработал JUMP_LESS

always@(posedge clk)
    if (reset)
        pc <= 0;
    else
        pc <= pc_next;
   

always@*
    if (jump_cond)
        pc_next <= adr_to_jmp_4;
    else if (!cmd_1_can_move || !cmd_2_can_move)
        pc_next <= pc;
    else
        pc_next <= pc + 1;

//----------------
// Fetch
//----------------
always@*
    cmd_reg_0_next <= MEM[pc];

always@(posedge clk)
    if (reset)
        cmd_reg_0 <= 0;
    else if(jump_cond)
        cmd_reg_0 <= 0;
    else if(cmd_1_can_move && cmd_2_can_move)
        cmd_reg_0 <= cmd_reg_0_next;

// always@*
//     cmd_reg_0_next <= MEM[pc];

//----------------
// Decode 1
//----------------

wire [COP_SIZE - 1: 0] cop_1 = cmd_reg_0[CMD_SIZE - 1 -: COP_SIZE];
wire [LIT_SIZE - 1: 0] literal = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE -: LIT_SIZE];
wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1_1 = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
wire [ADDR_RF_SIZE - 1: 0] adr_r_1_1 = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];
wire [ADDR_RF_SIZE - 1: 0] adr_r_2_1 = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];
wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jmp_1 = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];

// wire [COP_SIZE - 1: 0] cop = cmd_reg[CMD_SIZE - 1 -: COP_SIZE]; // +
// wire [LIT_SIZE - 1: 0] literal = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: LIT_SIZE]; // +
// wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
// wire [ADDR_RF_SIZE - 1: 0] adr_r_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_2 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_3 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE]; //

// wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jump = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];


always@(posedge clk)
    if (reset)
        cmd_reg_1 <= 0;
    else
        cmd_reg_1 <= cmd_reg_1_next;

reg cmd_1_can_move_st_2 = 0;
reg cmd_1_can_move_st_3 = 0;
wire cmd_1_can_move = cmd_1_can_move_st_2 && cmd_1_can_move_st_3;
always@*
    case(cop_1)
        RTR, MTRK:
            begin
                case(cop_2)
                    MTR, RTR, MTRK: 
                        if (adr_r_2_1 == adr_res_1_2)
                            cmd_1_can_move_st_2 <= 0;  
                        else
                            cmd_1_can_move_st_2 <= 1;                              
                    SUB, SUM: 
                        if (adr_r_2_1 == adr_res_2_2)
                            cmd_1_can_move_st_2 <= 0;  
                        else
                            cmd_1_can_move_st_2 <= 1; 
                    default:
                        cmd_1_can_move_st_2 <= 1;            
                endcase  
                case(cop_3)
                    MTR, RTR, MTRK: 
                        if (adr_r_2_1 == adr_res_1_3)
                            cmd_1_can_move_st_3 <= 0;  
                        else
                            cmd_1_can_move_st_3 <= 1;                              
                    SUB, SUM: 
                        if (adr_r_2_1 == adr_res_2_3)
                            cmd_1_can_move_st_3 <= 0;  
                        else
                            cmd_1_can_move_st_3 <= 1; 
                    default:
                        cmd_1_can_move_st_3 <= 1;            
                endcase
            end      
        SUB, JUMP_LESS, RTMK, SUM:
            begin
                case(cop_2)
                    MTR, RTR, MTRK: 
                        if (adr_r_1_1 == adr_res_1_2)
                            cmd_1_can_move_st_2 <= 0;  
                        else
                            cmd_1_can_move_st_2 <= 1;                              
                    SUB, SUM: 
                        if (adr_r_1_1 == adr_res_2_2)
                            cmd_1_can_move_st_2 <= 0;  
                        else
                            cmd_1_can_move_st_2 <= 1; 
                    default:
                        cmd_1_can_move_st_2 <= 1;            
                 endcase 
                 
                 case(cop_3)
                    MTR, RTR, MTRK: 
                        if (adr_r_1_1 == adr_res_1_3)
                            cmd_1_can_move_st_3 <= 0;  
                        else
                            cmd_1_can_move_st_3 <= 1;                              
                    SUB, SUM: 
                        if (adr_r_1_1 == adr_res_2_3)
                            cmd_1_can_move_st_3 <= 0;  
                        else

                            cmd_1_can_move_st_3 <= 1; 
                    default:
                        cmd_1_can_move_st_3 <= 1;            
                endcase   
            end  
        default:
            begin
                cmd_1_can_move_st_2 <= 1;
                cmd_1_can_move_st_3 <= 1;    
            end                             
    endcase

always@*
    if (jump_cond)
        cmd_reg_1_next <= 0;
    else
        begin
            if (!cmd_2_can_move)
                cmd_reg_1_next <= cmd_reg_1; 
            else if (!cmd_1_can_move)
                cmd_reg_1_next <= 0;   
            else         
                cmd_reg_1_next <= cmd_reg_0;
        end


always@(posedge clk)
    if (reset)
        opA_1 <= 0;
    else if (cmd_1_can_move && cmd_2_can_move)
        opA_1 <= opA_1_next;

always@*
    case(cop_1)
        LTM: opA_1_next <= literal;        
        RTR, MTRK: 
            if(RF_en && adr_r_2_1 == RF_adr)  
                opA_1_next <= RF_data;
            else  
                opA_1_next <= RF[adr_r_2_1];
        SUB, JUMP_LESS, RTMK, SUM: 
            if(RF_en && adr_r_1_1 == RF_adr)  
                opA_1_next <= RF_data;
            else  
                opA_1_next <= RF[adr_r_1_1];
        JUMP: opA_1_next <= adr_to_jmp_1;
        default: opA_1_next <= opA_1;
    endcase

//----------------
// Decode 2
//----------------

wire [COP_SIZE - 1 : 0] cop_2 = cmd_reg_1[CMD_SIZE - 1 -: COP_SIZE];
wire [ADDR_DATA_MEM_SIZE - 1 : 0] adr_m_1_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_r_2_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_res_1_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE]; //adr_r_
wire [ADDR_RF_SIZE - 1 : 0] adr_res_2_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE]; //adr_r_3

// wire [COP_SIZE - 1: 0] cop = cmd_reg[CMD_SIZE - 1 -: COP_SIZE]; // +
// wire [LIT_SIZE - 1: 0] literal = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: LIT_SIZE]; // +
// wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
// wire [ADDR_RF_SIZE - 1: 0] adr_r_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_2 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_3 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE]; //

// wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jump = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];

always@(posedge clk)
    if (reset)
        cmd_reg_2 <= 0;
    else
        cmd_reg_2 <= cmd_reg_2_next;

always@*
    if (jump_cond)
        cmd_reg_2_next <= 0;    
    else
        begin
            if (!cmd_2_can_move)
                cmd_reg_2_next <= 0;     
            else        
                cmd_reg_2_next <= cmd_reg_1;
        end    

reg cmd_2_can_move;
always@*
    case(cop_2)
        MTR:  
            case(cop_3)
                LTM: 
                    if (adr_m_1_2 == adr_res_m_1_3)
                        cmd_2_can_move <= 0;
                    else 
                        cmd_2_can_move <= 1;        
                RTMK:
                    cmd_2_can_move <= 0;  
                default:
                    cmd_2_can_move <= 1;                                 
            endcase
        SUB, JUMP_LESS, SUM, RTMK: 
            case(cop_3)
                MTR, RTR, MTRK: 
                    if (adr_r_2_2 == adr_res_1_3)
                        cmd_2_can_move <= 0;  
                    else
                        cmd_2_can_move <= 1;                              
                SUB, SUM: 
                    if (adr_r_2_2 == adr_res_2_3)
                        cmd_2_can_move <= 0;  
                    else
                        cmd_2_can_move <= 1; 
                default:
                    cmd_2_can_move <= 1;     
            endcase
        MTRK: 
            case(cop_3)
                LTM, RTMK: 
                    cmd_2_can_move <= 0;            
                default:
                    cmd_2_can_move <= 1;   
            endcase
        default:
            cmd_2_can_move <= 1;      
    endcase


always@(posedge clk)
    if (reset)
        opA_2 <= 0;
    else

        opA_2 <= opA_2_next;

always@*
    if (!cmd_2_can_move)
        opA_2_next <= 0;  
    else
        opA_2_next <= opA_1;


always@(posedge clk)
    if (reset)
        opB_2 <= 0;
    else if (cmd_2_can_move)
        opB_2 <= opB_2_next;
            
always@*
    case(cop_2)
        MTR:
            if(data_mem_en && adr_m_1_2 == data_mem_adr)  
                opB_2_next <= data_mem_data; 
            else
                opB_2_next <= MEM_DATA[adr_m_1_2];
        SUB, JUMP_LESS, SUM, RTMK: 
            if(RF_en && adr_r_2_2 == RF_adr)
                opB_2_next <= RF_data; 
            else
                opB_2_next <= RF[adr_r_2_2];
        MTRK: 
            if(data_mem_en && opA_1 == data_mem_adr)  
                opB_2_next <= data_mem_data; 
            else
                opB_2_next <= MEM_DATA[opA_1];
        default: opB_2_next <= opB_2;
    endcase

//----------------
// Execute
//----------------
wire [COP_SIZE - 1 : 0] cop_3 = cmd_reg_2[CMD_SIZE - 1 -: COP_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_res_1_3 = cmd_reg_2[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];
wire [ADDR_DATA_MEM_SIZE - 1 : 0] adr_res_m_1_3 = cmd_reg_2[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_res_2_3 = cmd_reg_2[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE];

always@(posedge clk)
    if (reset)
        cmd_reg_3 <= 0;
    else
        cmd_reg_3 <= cmd_reg_3_next;

always@*
    if (jump_cond)
        cmd_reg_3_next <= 0;    
    else
        cmd_reg_3_next <= cmd_reg_2;  
    
always@(posedge clk)
    if (reset)
        res <= 0;
    else
        res <= res_next;


always@*
    case(cop_3)
        LTM, RTR, MTRK, RTMK, JUMP: res_next <= opA_2;
        MTR: res_next <= opB_2;
        SUB: res_next <= opA_2 - opB_2;
        JUMP_LESS: res_next <= opA_2 < opB_2;
        SUM: res_next <= opA_2 + opB_2;
        default: res_next <= res;
    endcase

always@(posedge clk)
    if (reset)
        opB_3 <= 0;
    else
        opB_3 <= opB_3_next;

always@*
    opB_3_next <= opB_2;

//----------------
// WriteBack
//----------------
wire [COP_SIZE - 1 : 0] cop_4 = cmd_reg_3[CMD_SIZE - 1 -: COP_SIZE];
wire [ADDR_DATA_MEM_SIZE - 1 : 0] adr_m_1_4 = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
wire [ADDR_CMD_MEM_SIZE - 1 : 0] adr_to_jmp_4 = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_r_1_4 = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];
wire [ADDR_RF_SIZE - 1 : 0] adr_r_3_4 = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE];
reg  [LIT_SIZE - 1 : 0] data_mem_data = 0;
reg  [ADDR_DATA_MEM_SIZE - 1 : 0] data_mem_adr = 0;
reg data_mem_en = 0;

// wire [COP_SIZE - 1: 0] cop = cmd_reg[CMD_SIZE - 1 -: COP_SIZE]; // +
// wire [LIT_SIZE - 1: 0] literal = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: LIT_SIZE]; // +
// wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
// wire [ADDR_RF_SIZE - 1: 0] adr_r_1 = cmd_reg[CMD_SIZE - 1 - COP_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_2 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];  // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_3 = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE]; //

// wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jump = cmd_reg[CMD_SIZE - 1 - COP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];

reg [LIT_SIZE         - 1 : 0] RF_data = 0;
reg [ADDR_RF_SIZE       - 1 : 0] RF_adr = 0;
reg RF_en = 0;

always@*
    case(cop_4)
        LTM: data_mem_data <= res;
        RTMK: data_mem_data <= opB_3;
        default: data_mem_data <= 0;
    endcase
always@*
    case(cop_4)
        LTM: data_mem_adr <= adr_m_1_4;
        RTMK: data_mem_adr <= res;
        default: data_mem_adr <= 0;
    endcase
always@*
    case(cop_4)
        LTM, RTMK: data_mem_en <= 1;
        default: data_mem_en <= 0;
    endcase

always@(posedge clk)
    if(data_mem_en)
        MEM_DATA[data_mem_adr] <= data_mem_data;

always@*
    case(cop_4)

        MTR, RTR, SUB, SUM: RF_data <= res;
        MTRK: RF_data <= opB_3;
        default: RF_data <= 0;
    endcase
always@*
    case(cop_4)
        MTR, RTR, MTRK: RF_adr <= adr_r_1_4;
        SUB, SUM: RF_adr <= adr_r_3_4;
        default: RF_adr <= 0;
    endcase
always@*
    case(cop_4)
        MTR, RTR, MTRK, SUB, SUM: RF_en <= 1;
        default: RF_en <= 0;
    endcase

always@(posedge clk)
    if(RF_en)
        RF[RF_adr] <= RF_data;

endmodule
