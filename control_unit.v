module control_unit (
  input clk,
  input resetn,
  input [6:0] opcode,
  input [6:0] funct7,
  input [2:0] funct3,
  output reg [3:0] state,
  output mem_read,
  output mem_write,
  output reg_write,
  output [1:0] alu_src_a,
  output [1:0] alu_src_b,
  output [3:0] alu_control,
  output ir_write,
  output pc_write,
  output mem_to_reg,
  output [1:0] imm_src
);
  // Definição dos estados
  parameter IF       = 4'd0;  // Instruction Fetch
  parameter ID       = 4'd1;  // Instruction Decode
  parameter EX_R     = 4'd2;  // Execute R-type
  parameter EX_I     = 4'd3;  // Execute I-type
  parameter EX_S     = 4'd4;  // Execute S-type
  parameter EX_J     = 4'd5;  // Execute J-type
  parameter MEM_RD   = 4'd6;  // Memory Read
  parameter MEM_WR   = 4'd7;  // Memory Write
  parameter WB_ALU   = 4'd8;  // Write Back from ALU
  parameter WB_MEM   = 4'd9;  // Write Back from Memory
  parameter HALT     = 4'd10; // Halt on EBREAK

  // Definição dos opcodes
  parameter LW      = 7'b0000011;
  parameter SW      = 7'b0100011;
  parameter ALUIMM  = 7'b0010011;
  parameter ALUREG  = 7'b0110011;
  parameter LUI     = 7'b0110111;
  parameter JAL     = 7'b1101111;
  parameter EBREAK  = 7'b1110011;

  // Definição dos formatos de imediato
  parameter IMM_I = 2'b00;
  parameter IMM_S = 2'b01;
  parameter IMM_J = 2'b10;

  // Registrador para o próximo estado
  reg [3:0] next_state;
  
  // Detectores combinacionais de instrução
  wire is_lw      = (opcode == LW);
  wire is_sw      = (opcode == SW);
  wire is_aluimm  = (opcode == ALUIMM);
  wire is_alureg  = (opcode == ALUREG);
  wire is_jal     = (opcode == JAL);
  wire is_lui     = (opcode == LUI);
  wire is_ebreak  = (opcode == EBREAK);

  // Lógica de transição de estados
  always @(posedge clk) begin
    if (!resetn) begin
      state <= IF;
    end else begin
      state <= next_state;
    end
  end

  // Lógica de próximo estado (depende do estado atual e entradas)
  always @(*) begin
    // Valor padrão para evitar latches
    next_state = state;

    case (state)
      IF: begin
        next_state = ID;
      end
      
      ID: begin
        if (is_lw)
          next_state = EX_I;
        else if (is_sw)
          next_state = EX_S;
        else if (is_aluimm)
          next_state = EX_I;
        else if (is_alureg)
          next_state = EX_R;
        else if (is_jal)
          next_state = EX_J;
        else if (is_lui)
          next_state = IF;
        else if (is_ebreak)
          next_state = HALT;
        else
          next_state = IF;
      end
      
      EX_R: begin
        next_state = WB_ALU;
      end
      
      EX_I: begin
        if (is_lw)
          next_state = MEM_RD;
        else
          next_state = WB_ALU;
      end
      
      EX_S: begin
        next_state = MEM_WR;
      end
      
      EX_J: begin
        next_state = WB_ALU;
      end
      
      MEM_RD: begin
        next_state = WB_MEM;
      end
      
      MEM_WR: begin
        next_state = IF;
      end
      
      WB_ALU: begin
        next_state = IF;
      end
      
      WB_MEM: begin
        next_state = IF;
      end
      
      HALT: begin
        next_state = HALT; // Permanece no estado HALT
      end
      
      default: begin
        next_state = IF;
      end
    endcase
  end

  // Lógica combinacional para sinais de controle
  // Declarações de sinais para controle
  reg mem_read_reg, mem_write_reg, reg_write_reg;
  reg ir_write_reg, pc_write_reg, mem_to_reg_reg;
  reg [1:0] alu_src_a_reg, alu_src_b_reg, imm_src_reg;
  reg [3:0] alu_control_reg;
  
  // Atribuições combinacionais para saídas
  assign mem_read = mem_read_reg;
  assign mem_write = mem_write_reg;
  assign reg_write = reg_write_reg;
  assign ir_write = ir_write_reg;
  assign pc_write = pc_write_reg;
  assign mem_to_reg = mem_to_reg_reg;
  assign alu_src_a = alu_src_a_reg;
  assign alu_src_b = alu_src_b_reg;
  assign alu_control = alu_control_reg;
  assign imm_src = imm_src_reg;

  // Lógica combinacional para gerar sinais de controle baseados no estado atual
  always @(*) begin
    // Inicializa todos os sinais com valores padrão
    mem_read_reg = 0;
    mem_write_reg = 0;
    reg_write_reg = 0;
    ir_write_reg = 0;
    pc_write_reg = 0;
    mem_to_reg_reg = 0;
    alu_src_a_reg = 2'b00;
    alu_src_b_reg = 2'b00;
    alu_control_reg = 4'b0000;
    imm_src_reg = 2'b00;
    
    // Define os sinais com base no estado atual
    case (state)
      IF: begin
        ir_write_reg = 1;
        alu_src_a_reg = 2'b00; // PC como primeiro operando
        alu_src_b_reg = 2'b10; // Constante 4 como segundo operando
        alu_control_reg = 4'b0010; // Adição
        pc_write_reg = 1;
      end
            
      EX_R: begin

        alu_src_a_reg = 2'b10; // Registrador A como primeiro operando
        alu_src_b_reg = 2'b00; // Registrador B como segundo operando

        // Decodificação de todas as instruções tipo R
        case ({funct7, funct3})
          // Operações aritméticas
          {7'h00, 3'h0}: alu_control_reg = 4'b0010; // ADD
          {7'h20, 3'h0}: alu_control_reg = 4'b0110; // SUB
          
          // Operações de comparação
          {7'h00, 3'h2}: alu_control_reg = 4'b0111; // SLT
          {7'h00, 3'h3}: alu_control_reg = 4'b1001; // SLTU
          
          // Operações lógicas
          {7'h00, 3'h4}: alu_control_reg = 4'b0011; // XOR
          {7'h00, 3'h6}: alu_control_reg = 4'b0001; // OR
          {7'h00, 3'h7}: alu_control_reg = 4'b0000; // AND
          
          // Operações de deslocamento
          {7'h00, 3'h1}: alu_control_reg = 4'b0100; // SLL
          {7'h00, 3'h5}: alu_control_reg = 4'b0101; // SRL
          {7'h20, 3'h5}: alu_control_reg = 4'b1000; // SRA
          
          // Comportamento padrão
          default: alu_control_reg = 4'b0000;
        endcase
      end
      
      EX_I: begin

        alu_src_a_reg = 2'b10; // Registrador A como primeiro operando
        alu_src_b_reg = 2'b01; // Imediato como segundo operando

        if (opcode == 7'b0000011) // Opcode para instruções Load (LW, LH, LB)
          alu_control_reg = 4'b0010; // Adição para cálculo de endereço
        else
          case (funct3)
            3'h0: alu_control_reg = 4'b0010; // ADDI
            3'h2: alu_control_reg = 4'b0111; // SLTI
            3'h3: alu_control_reg = 4'b1001; // SLTIU
            3'h4: alu_control_reg = 4'b0011; // XORI
            3'h6: alu_control_reg = 4'b0001; // ORI
            3'h7: alu_control_reg = 4'b0000; // ANDI
            3'h1: alu_control_reg = 4'b0100; // SLLI
            3'h5: alu_control_reg = (funct7 == 7'b0100000) ? 4'b1000 : 4'b0101; // SRAI or SRLI
            default: alu_control_reg = 4'b0000;
          endcase

        imm_src_reg = IMM_I;

      end
      
      EX_S: begin
        alu_src_a_reg = 2'b10; // Registrador A como primeiro operando
        alu_src_b_reg = 2'b01; // Imediato como segundo operando
        alu_control_reg = 4'b0010; // Adição
        imm_src_reg = IMM_S;
      end
      
      EX_J: begin
        alu_src_a_reg = 2'b00; // PC como primeiro operando
        alu_src_b_reg = 2'b01; // Imediato como segundo operando
        alu_control_reg = 4'b0010; // Adição
        imm_src_reg = IMM_J;
        pc_write_reg = 1;
      end
      
      MEM_RD: begin
        mem_read_reg = 1;
        //$display("Estado MEM_RD: mem_read=%b", mem_read_reg);
      end
      
      MEM_WR: begin
        mem_write_reg = 1;
      end
      
      WB_ALU: begin
        reg_write_reg = 1;
        mem_to_reg_reg = 0; // Seleciona ALUOut
      end
      
      WB_MEM: begin
        reg_write_reg = 1;
        mem_to_reg_reg = 1; // Seleciona MDR
      end
      
      HALT: begin
        // Nenhum sinal ativo
      end
    endcase
  end
endmodule