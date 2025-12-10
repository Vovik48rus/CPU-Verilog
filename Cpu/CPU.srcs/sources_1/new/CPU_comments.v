`timescale 1ns / 1ps

module CPU_pipeline_с(
    input clk, reset // тактовый сигнал и асинхронный (или синхронный по сбросу) сброс.
);

localparam WORD_SIZE = 10; // длина переменной которую записываем в MEM (бит ширины данных и регистров)
localparam CMD_SIZE = 24; // общая длина командной строки (в битах)
localparam PROG_SIZE = 1024; // максимальное количество строк в программе, максимальное количество команд
localparam RF_SIZE = 16; // количество регистров в регистр-файле процессора 
localparam RF_ADR_SIZE = $clog2(RF_SIZE); // длина адреса регистра (число бит) для индексирования RF
localparam DATA_MEM_SIZE = 1024; // максимальное количество переменных хранимых в MEM памяти  
localparam DATA_MEM_ADR_SIZE = $clog2(DATA_MEM_SIZE); // длина адреса числа хранящегося в MEM 
localparam COP_SIZE = 4; // длина представления команды в двоичном виде, без аргументов (opcode width)
localparam PROG_ADR_SIZE = $clog2(PROG_SIZE); // длина номера строки в памяти команд (PC width)

localparam 
    NOP = 0, LTM = 1, MTR = 2, RTR = 3, SUB = 4, 
    JUMP_LESS = 5, MTRK = 6, RTMK = 7, JUMP = 8,
    SUM = 9; // перечисление операций (opcode значения). Каждому присвоен числовой код.

// Регистр-файл: RF — массив слов ширины WORD_SIZE, индексы 0..RF_SIZE-1
reg [WORD_SIZE - 1 : 0] RF [0 : RF_SIZE - 1];
// Память данных — MEM_DATA
reg [WORD_SIZE - 1 : 0] MEM_DATA [0 : DATA_MEM_SIZE - 1];
// Память команд (загружаемая программа)
reg [CMD_SIZE  - 1 : 0] PROG [0 : PROG_SIZE - 1]; // Загружаемая программа, каждая строка — CMD_SIZE бит

// Регистры управления ПК (pc), предыдущий и следующий значения
reg [PROG_ADR_SIZE - 1 : 0] pc, pc_prev, pc_next;
// Регистры команд на стадиях конвейера: cmd_reg_0 - IF (fetch), cmd_reg_1 - ID1, cmd_reg_2 - ID2/EX, cmd_reg_3 - MEM/WB
reg [CMD_SIZE  - 1 : 0] cmd_reg_0, cmd_reg_0_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_1, cmd_reg_1_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_2, cmd_reg_2_next;
reg [CMD_SIZE  - 1 : 0] cmd_reg_3, cmd_reg_3_next;

// Операнды и промежуточные значения, каждое имеет "текущее" и "next" версии для синхронизации на фронте
reg [WORD_SIZE - 1 : 0] opA_1, opA_1_next; // operand A на стадии Decode1 (и его next)
reg [WORD_SIZE - 1 : 0] opA_2, opA_2_next; // operand A на стадии Decode2/Execute
reg [WORD_SIZE - 1 : 0] opB_2, opB_2_next; // operand B на стадии Execute (из Decode2)
reg [WORD_SIZE - 1 : 0] opB_3, opB_3_next; // operand B на стадии WriteBack (запомнён для операций типа RTMK/MTRK)
reg [WORD_SIZE - 1 : 0] res, res_next; // результат вычисления на стадии Execute (и next)

// Инициализация — initial блок. Загружаем программу и обнуляем память/регистры.
integer i;
initial
begin
    // Загрузка программы из файла в массив PROG (двоичный формат, readmemb)
    $readmemb("program.mem", PROG);
    // Инициализация памяти данных нулями
    for(i = 0; i < DATA_MEM_SIZE; i = i + 1)
        MEM_DATA[i] <= 0;
    // Инициализация регистров RF: RF[0]=0, RF[1]=1, остальные 0
    for(i = 2; i < RF_SIZE; i = i + 1)
        RF[i] <= 0;
    RF[0] <= 0; RF[1] <= 1;
    
    // Обнуление командных регистров и их "next" версий
    cmd_reg_0 <= 0; cmd_reg_0_next <= 0;
    cmd_reg_1 <= 0; cmd_reg_1_next <= 0;
    cmd_reg_2 <= 0; cmd_reg_2_next <= 0;
    cmd_reg_3 <= 0; cmd_reg_3_next <= 0;
    
    // Обнуление операндов и их next
    opA_1 <= 0; opA_1_next <= 0;
    opA_2 <= 0; opA_2_next <= 0;
    opB_2 <= 0; opB_2_next <= 0;
    opB_3 <= 0; opB_3_next <= 0;
    
    // Инициализация PC
    pc <= 0; pc_next <= 0; pc_prev <= 0;
    
    // Инициализация результата
    res <= 0; res_next <= 0;
    // Флаги, управляющие движением команд в конвейере (стойки/разрешения на движение)
    cmd_1_can_move_st_2 <= 0; // флаг стадии 1 -> 2 (локально, начальное значение)
    cmd_1_can_move_st_3 <= 0; // флаг стадии 1 -> 3 (локально, начальное значение)
    cmd_2_can_move <= 0; // флаг стадии 2 -> 3 (локально, начальное значение)
    
end

//------------------
// PC (Program Counter) и управление переходами
//------------------
// jump_cond — условие для изменения PC: когда на стадии WriteBack пришла команда JUMP
// или JUMP_LESS и условие (res == 0) выполнено (res хранит результат сравнения или арифметики).
wire jump_cond = cop_4 == JUMP || (cop_4 == JUMP_LESS && res == 0); // Если на WriteBack пришла команда JMP или сработал JUMP_LESS

// Обновление регистра pc по фронту clk; при reset pc обнуляется
always@(posedge clk)
    if (reset)
        pc <= 0;
    else
        pc <= pc_next;
   
// Логика генерации pc_next:
// - если jump_cond — переходим на адрес перехода adr_to_jmp_4 (адрес формируется в стадии WriteBack)
// - если команды не могут двигаться (стойка) — держим pc (не фетчим новые команды)
// - иначе — pc + 1 (следующая команда)
always@*
    if (jump_cond)
        pc_next <= adr_to_jmp_4;
    else if (!cmd_1_can_move || !cmd_2_can_move)
        pc_next <= pc;
    else
        pc_next <= pc + 1;

//----------------
// Fetch (IF)
//----------------
// Вычисляем следующую команду, читаем из PROG по адресу pc
always@*
    cmd_reg_0_next <= PROG[pc];

// Сдвиг в регистр cmd_reg_0 по фронту clk:
// - если reset — обнуляем
// - если jump_cond — очищаем (сбрасываем инструкцию на стадии IF), чтобы не допустить "лишней"
//   команды, загруженной раньше чем resolved jump (очистка/флеш конвейера)
// - иначе, если обе последующие стадии разрешают движение — фиксируем cmd_reg_0_next
always@(posedge clk)
    if (reset)
        cmd_reg_0 <= 0;
    else if(jump_cond)
        cmd_reg_0 <= 0;
    else if(cmd_1_can_move && cmd_2_can_move)
        cmd_reg_0 <= cmd_reg_0_next;

//----------------
// Decode 1 (ID1)
//----------------
// Разбор полей команды из cmd_reg_0 (IF stage -> ID1 stage)
// COP_SIZE бит — opcode в старших битах команды.
// Формат команды (биты): [COP (COP_SIZE)][literal/adr_r/...][...][adr_to_jmp (ниже)] — примерный порядок
wire [COP_SIZE          - 1 : 0] cop_1        = cmd_reg_0[CMD_SIZE - 1                          -: COP_SIZE];
// literal — непосредственное число (например для LTM)
wire [WORD_SIZE         - 1 : 0] literal      = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE               -: WORD_SIZE];
// адрес в памяти данных (низкие биты команды)
wire [DATA_MEM_ADR_SIZE - 1 : 0] adr_m_1_1    = cmd_reg_0[DATA_MEM_ADR_SIZE - 1                  : 0];
// адрес регистра (1-й/2-й источник) — расположение зависит от формата команды
wire [RF_ADR_SIZE       - 1 : 0] adr_r_1_1    = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE               -: RF_ADR_SIZE];
wire [RF_ADR_SIZE       - 1 : 0] adr_r_2_1    = cmd_reg_0[CMD_SIZE - 1 - COP_SIZE - RF_ADR_SIZE -: RF_ADR_SIZE];
// адрес для перехода (если команда JUMP/JUMP_LESS) — младшие биты длины PROG_ADR_SIZE
wire [PROG_ADR_SIZE     - 1 : 0] adr_to_jmp_1 = cmd_reg_0[PROG_ADR_SIZE - 1                      : 0];

// (Комментарий: закомментированный код ниже — альтернативные распаковки полей, оставлены для ориентира)
// wire [KOP_SIZE - 1: 0] cop = cmd_reg[CMD_SIZE - 1 -: KOP_SIZE]; // +
// wire [ADDR_DATA_MEM_SIZE - 1: 0] adr_m_1 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - LIT_SIZE -: ADDR_DATA_MEM_SIZE];
// wire [LIT_SIZE - 1: 0] literal = cmd_reg[CMD_SIZE - 1 - KOP_SIZE -: LIT_SIZE]; // +
// wire [ADDR_RF_SIZE - 1: 0] adr_r_1 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE -: ADDR_RF_SIZE];
// wire [ADDR_RF_SIZE - 1: 0] adr_r_2 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - ADDR_RF_SIZE -: ADDR_RF_SIZE];
// wire [ADDR_RF_SIZE - 1: 0] adr_r_3 = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - 2*ADDR_RF_SIZE -: ADDR_RF_SIZE];
// wire [ADDR_CMD_MEM_SIZE - 1: 0] adr_to_jump = cmd_reg[CMD_SIZE - 1 - KOP_SIZE - 2*ADDR_RF_SIZE -: ADDR_CMD_MEM_SIZE];

// Перенос команды на следующую стадию (ID1 -> ID2)
// регистр cmd_reg_1 обновляется по такту
always@(posedge clk)
    if (reset)
        cmd_reg_1 <= 0;
    else
        cmd_reg_1 <= cmd_reg_1_next;

// Флаги разрешения для движения команды 1 (ID1) в следующие стадии.
// cmd_1_can_move_st_2 — проверка зависимостей между полями команды 1 и командой на стадии 2
// cmd_1_can_move_st_3 — проверка зависимостей между полями команды 1 и командой на стадии 3
reg cmd_1_can_move_st_2 = 0;
reg cmd_1_can_move_st_3 = 0;
// Общий флаг — команда 1 может двигаться только если оба подтестируемых флага = 1
wire cmd_1_can_move = cmd_1_can_move_st_2 && cmd_1_can_move_st_3;

// Детекция зависимостей (hazard detection) — для предотвращения конфликтов чтения/записи регистров и памяти.
// CASE по cop_1 — разные типы инструкций имеют разные операнды-источники и разные зависимости.
// Внутри проверяем поля команд, находящиеся в стадиях 2 и 3 (cop_2, cop_3), чтобы решить,
// нужно ли блокировать движение cmd_reg_0 -> cmd_reg_1 (ставить 0 в cmd_reg_1_next) — stall.
always@*
    case(cop_1)
        RTR, MTRK:
            begin
                // Если текущая команда (cop_1 == RTR или MTRK) читает регистр adr_r_2_1,
                // и предыдущая стадия (cop_2) записывает в тот же регистр (adr_res_1_2),
                // то нельзя двигаться — ожидаем, пока запись завершится (столкновение RAW).
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
                // Аналогично сравнение с регистром на стадии 3
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
                // Для этих операций источником может быть adr_r_1_1 — сравниваем с целями предыдущих стадий
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
                 
                 // Сравнение с целью на стадии 3
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
                // Для всех остальных команд — разрешаем движение
                cmd_1_can_move_st_2 <= 1;
                cmd_1_can_move_st_3 <= 1;    
            end                             
    endcase

// Выбор следующей команды в cmd_reg_1_next:
// - если произошёл jump_cond — очищаем стадию (флеш)
// - если стадия 2 не может сдвинуться (cmd_2_can_move == 0) — держим cmd_reg_1 (не фетчим новую в стадию 1?)
// - если команда 1 не может двигаться (cmd_1_can_move == 0) — вставляем NOP (0) в стадию 1 (столкнулись)
// - иначе — переносим команду из cmd_reg_0
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

// Обновление операнда opA_1 по фронту; он берётся из opA_1_next только если команда 1 может двигаться
always@(posedge clk)
    if (reset)
        opA_1 <= 0;
    else if (cmd_1_can_move && cmd_2_can_move)
        opA_1 <= opA_1_next;

// Генерация opA_1_next на основе типа инструкции cop_1:
// - LTM — загружаем literal в opA_1
// - RTR, MTRK — источник — адрес adr_r_2_1 (возможна форвардинг-логика, если RF_en и совпадение адреса)
// - SUB, JUMP_LESS, RTMK, SUM — источник — adr_r_1_1 (и также форвардинг при RF_en)
// - JUMP — opA_1_next хранит адрес перехода adr_to_jmp_1
// - default — сохраняем текущее opA_1 (нет изменений)
always@*
    case(cop_1)
        LTM: opA_1_next <= literal;        
        RTR, MTRK: 
            if(RF_en && adr_r_2_1 == RF_adr)  
                opA_1_next <= RF_data; // форвардинг: если на стадии WB будет запись в тот же регистр, берём её значение напрямую
            else  
                opA_1_next <= RF[adr_r_2_1]; // иначе читаем из RF
        SUB, JUMP_LESS, RTMK, SUM: 
            if(RF_en && adr_r_1_1 == RF_adr)  
                opA_1_next <= RF_data; // форвардинг аналогично
            else  
                opA_1_next <= RF[adr_r_1_1];
        JUMP: opA_1_next <= adr_to_jmp_1; // у JUMP источник — адрес перехода (в младших битах команды)
        default: opA_1_next <= opA_1;
    endcase

//----------------
// Decode 2 (ID2)
//----------------
// Распаковка полей из cmd_reg_1 (вторая стадия декодирования)
wire [COP_SIZE          - 1 : 0] cop_2       = cmd_reg_1[CMD_SIZE - 1         -: COP_SIZE];
// адрес в памяти данных из cmd_reg_1 (низкие биты)
wire [DATA_MEM_ADR_SIZE - 1 : 0] adr_m_1_2   = cmd_reg_1[DATA_MEM_ADR_SIZE - 1 : 0];
// адрес второго регистра-источника для cop_2
wire [RF_ADR_SIZE       - 1 : 0] adr_r_2_2   = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE - RF_ADR_SIZE -: RF_ADR_SIZE];
// предполагаемые адреса регистров-результатов в cmd_reg_1 (они используются для обнаружения конфликтов)
wire [RF_ADR_SIZE       - 1 : 0] adr_res_1_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE               -: RF_ADR_SIZE]; // adr_r_
wire [RF_ADR_SIZE       - 1 : 0] adr_res_2_2 = cmd_reg_1[CMD_SIZE - 1 - COP_SIZE - 2*RF_ADR_SIZE -: RF_ADR_SIZE]; // adr_r_3

// Перенос команды в cmd_reg_2 (стадия Execute)
always@(posedge clk)
    if (reset)
        cmd_reg_2 <= 0;
    else
        cmd_reg_2 <= cmd_reg_2_next;

// Вычисление cmd_reg_2_next:
// - если jump_cond — очищаем
// - если cmd_2_can_move == 0 — не позволяем продвинуть следующую инструкцию (ставим 0)
// - иначе — двигаем команду из cmd_reg_1
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

// Логика cmd_2_can_move — проверка зависимостей между инструкцией на стадии 2 и 3.
// Если есть конфликт чтения/записи между стадиями, блокируем движение.
reg cmd_2_can_move;
always@*
    case(cop_2)
        MTR:  // загрузка из памяти в регистр
            case(cop_3)
                LTM: 
                    // Если адрес памяти, который читает MTR (adr_m_1_2), совпадает
                    // с адресом, который LTM будет записывать в MEM (adr_res_m_1_3),
                    // конфликт — нельзя двигать.
                    if (adr_m_1_2 == adr_res_m_1_3)
                        cmd_2_can_move <= 0;
                    else 
                        cmd_2_can_move <= 1;        
                RTMK:
                    // RTMK может менять адреса/память — резервируем (консервативно блокируем)
                    cmd_2_can_move <= 0;  
                default:
                    cmd_2_can_move <= 1;                                 
            endcase
        SUB, JUMP_LESS, SUM, RTMK: 
            // Для арифметики/сравнений — проверяем, не будет ли запись в регистр, который мы читаем
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
            // MTRK (индиректная загрузка из памяти с адресом в регистре) конфликтует с LTM/RTMK
            case(cop_3)
                LTM, RTMK: 
                    cmd_2_can_move <= 0;            
                default:
                    cmd_2_can_move <= 1;   
            endcase
        default:
            cmd_2_can_move <= 1;      
    endcase

// Обновление opA_2 (operand A на стадии Execute)
// - если reset — обнуление
// - иначе — всегда присваиваем opA_2_next (это перенос opA_1 дальше при разрешении)
always@(posedge clk)
    if (reset)
        opA_2 <= 0;
    else

        opA_2 <= opA_2_next;

// Если cmd_2_can_move == 0 — мы вставляем 0 в opA_2_next (чтобы не проталкивать старую неправильную информацию)
// Иначе — opA_2_next берётся из opA_1 (то есть передаём ранее считанный опA).
always@*
    if (!cmd_2_can_move)
        opA_2_next <= 0;  
    else
        opA_2_next <= opA_1;

// Обновление opB_2 аналогично: он фиксируется на фронте, только если cmd_2_can_move = 1
always@(posedge clk)
    if (reset)
        opB_2 <= 0;
    else if (cmd_2_can_move)
        opB_2 <= opB_2_next;
            
// Генерация opB_2_next: зависит от типа инструкции cop_2.
// - MTR: читаем из MEM_DATA по adr_m_1_2 (с поддержкой форвардинга через data_mem_en/data_mem_adr/data_mem_data)
// - SUB, JUMP_LESS, SUM, RTMK: читаем из RF по adr_r_2_2 (с поддержкой форвардинга через RF_en/RF_adr/RF_data)
// - MTRK: читает из MEM по адресу, находящемуся в opA_1 (индиректная адресация), с поддержкой форвардинга
// - default: сохраняем текущее opB_2
always@*
    case(cop_2)
        MTR:
            if(data_mem_en && adr_m_1_2 == data_mem_adr)  
                opB_2_next <= data_mem_data; // форвардинг из стадии WriteBack в MEM
            else
                opB_2_next <= MEM_DATA[adr_m_1_2]; // чтение из памяти
        SUB, JUMP_LESS, SUM, RTMK: 
            if(RF_en && adr_r_2_2 == RF_adr)
                opB_2_next <= RF_data; // форвардинг из WB в EX
            else
                opB_2_next <= RF[adr_r_2_2]; // чтение из RF
        MTRK: 
            if(data_mem_en && opA_1 == data_mem_adr)  
                opB_2_next <= data_mem_data; // форвардинг в случае индиректной загрузки
            else
                opB_2_next <= MEM_DATA[opA_1];
        default: opB_2_next <= opB_2;
    endcase

//----------------
// Execute (EX)
//----------------
// Распаковка полей из cmd_reg_2 для стадии Execute
wire [COP_SIZE - 1 : 0] cop_3 = cmd_reg_2[CMD_SIZE - 1 -: COP_SIZE];
// adr_res_1_3 — адрес регистра результата (первая целевая позиция) в cmd_reg_2
wire [RF_ADR_SIZE       - 1 : 0] adr_res_1_3   = cmd_reg_2[CMD_SIZE - 1 - COP_SIZE               -: RF_ADR_SIZE];
// adr_res_m_1_3 — адрес памяти, используемый командой на стадии 3 (например LTM)
wire [DATA_MEM_ADR_SIZE - 1 : 0] adr_res_m_1_3 = cmd_reg_2[DATA_MEM_ADR_SIZE - 1 : 0];
// adr_res_2_3 — второй потенциальный адрес регистра результата (используется для SUB/SUM)
wire [RF_ADR_SIZE       - 1 : 0] adr_res_2_3   = cmd_reg_2[CMD_SIZE - 1 - COP_SIZE - 2*RF_ADR_SIZE -: RF_ADR_SIZE];

// Перенос в cmd_reg_3 (следующая стадия — WriteBack/MEM)
always@(posedge clk)
    if (reset)
        cmd_reg_3 <= 0;
    else
        cmd_reg_3 <= cmd_reg_3_next;

// Логика cmd_reg_3_next: если произошёл переход (jump_cond) — очищаем, иначе пропускаем команду из cmd_reg_2
always@*
    if (jump_cond)
        cmd_reg_3_next <= 0;    
    else
        cmd_reg_3_next <= cmd_reg_2;  
    
// Обновление res (результата операции) по фронту; res_next вычисляется ниже
always@(posedge clk)
    if (reset)
        res <= 0;
    else
        res <= res_next;

// Вычисление res_next на основе cop_3 и операндов opA_2/opB_2:
// - Для LTM, RTR, MTRK, RTMK, JUMP результат — opA_2 (например LTM загружает literal/opA, RTR считывает регистр и т.д.)
// - Для MTR результат — opB_2 (MTR читает из памяти -> результат opB_2)
// - SUB, SUM — арифметические операции
// - JUMP_LESS — сравнение (результат логического значения, 1 если opA_2 < opB_2, иначе 0)
always@*
    case(cop_3)
        LTM, RTR, MTRK, RTMK, JUMP: res_next <= opA_2;
        MTR: res_next <= opB_2;
        SUB: res_next <= opA_2 - opB_2;
        JUMP_LESS: res_next <= opA_2 < opB_2;
        SUM: res_next <= opA_2 + opB_2;
        default: res_next <= res;
    endcase

// Обновление opB_3: перенос opB_2 в стадию WB (нужен для инструкций типа RTMK/MTRK)
always@(posedge clk)
    if (reset)
        opB_3 <= 0;
    else
        opB_3 <= opB_3_next;

always@*
    opB_3_next <= opB_2;

//----------------
// WriteBack (WB) и MEM write
//----------------
// Распаковка полей из cmd_reg_3 для стадии WB
wire [COP_SIZE - 1 : 0] cop_4 = cmd_reg_3[CMD_SIZE - 1 -: COP_SIZE];
wire [DATA_MEM_ADR_SIZE - 1 : 0] adr_m_1_4    = cmd_reg_3[DATA_MEM_ADR_SIZE - 1 : 0];
wire [PROG_ADR_SIZE     - 1 : 0] adr_to_jmp_4 = cmd_reg_3[PROG_ADR_SIZE - 1 : 0];
wire [RF_ADR_SIZE       - 1 : 0] adr_r_1_4    = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE               -: RF_ADR_SIZE];
wire [RF_ADR_SIZE       - 1 : 0] adr_r_3_4    = cmd_reg_3[CMD_SIZE - 1 - COP_SIZE - 2*RF_ADR_SIZE -: RF_ADR_SIZE];

// Сигналы для форвардинга в предыдущие стадии и для записи в память/регистр-файл:
reg  [WORD_SIZE         - 1 : 0] data_mem_data = 0; // данные для записи в MEM_DATA (при LTM/RTMK)
reg  [DATA_MEM_ADR_SIZE - 1 : 0] data_mem_adr = 0; // адрес для записи в MEM_DATA
reg data_mem_en = 0; // сигнал разрешения записи в MEM_DATA

reg [WORD_SIZE         - 1 : 0] RF_data = 0; // данные для записи в RF (форвардятся на стадии декодирования)
reg [RF_ADR_SIZE       - 1 : 0] RF_adr = 0; // адрес в RF для записи
reg RF_en = 0; // разрешение записи в RF

// Генерация данных для записи в память (data_mem_data):
// - Если cop_4 == LTM — записываем res (обычно LTM — write to MEM? — здесь логика: LTM помечена как запись в память)
// - Если cop_4 == RTMK — записываем opB_3 (RTMK — возможно запись в память с данными из регистра opB_3)
always@*
    case(cop_4)
        LTM: data_mem_data <= res;
        RTMK: data_mem_data <= opB_3;
        default: data_mem_data <= 0;
    endcase
// Генерация адреса для записи в память (data_mem_adr):
// - Для LTM используем поле adr_m_1_4
// - Для RTMK используем res (возможно резульат вычисления — адрес)
always@*
    case(cop_4)
        LTM: data_mem_adr <= adr_m_1_4;
        RTMK: data_mem_adr <= res;
        default: data_mem_adr <= 0;
    endcase
// Генерация разрешения записи в память: LTM и RTMK активируют запись
always@*
    case(cop_4)
        LTM, RTMK: data_mem_en <= 1;
        default: data_mem_en <= 0;
    endcase

// По фронту тактового сигнала: фактическая запись в память MEM_DATA, если data_mem_en активна
always@(posedge clk)
    if(data_mem_en)
        MEM_DATA[data_mem_adr] <= data_mem_data;

// Формирование RF_data — что будет записано в регистр-файл при WB:
// - Для MTR, RTR, SUB, SUM — результат res записывается в RF
// - Для MTRK — данные для записи берутся из opB_3 (вариант операции)
always@*
    case(cop_4)

        MTR, RTR, SUB, SUM: RF_data <= res;
        MTRK: RF_data <= opB_3;
        default: RF_data <= 0;
    endcase
// Формирование RF_adr — адрес регистра для записи:
// - для MTR, RTR, MTRK — адрес берётся из поля adr_r_1_4
// - для SUB, SUM — адрес берётся из adr_r_3_4 (т.е. третье поле команды)
always@*
    case(cop_4)
        MTR, RTR, MTRK: RF_adr <= adr_r_1_4;
        SUB, SUM: RF_adr <= adr_r_3_4;
        default: RF_adr <= 0;
    endcase
// Генерация разрешения записи в RF: для перечисленных команд RF_en = 1
always@*
    case(cop_4)
        MTR, RTR, MTRK, SUB, SUM: RF_en <= 1;
        default: RF_en <= 0;
    endcase

// По фронту: выполняем запись в RF, если RF_en активен.
// Эта запись также служит источником данных для форвардинга (RF_en/RF_adr/RF_data)
always@(posedge clk)
    if(RF_en)
        RF[RF_adr] <= RF_data;

endmodule
