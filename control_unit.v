module control_unit (
  input clk,
  input resetn,
  input [6:0] opcode,     // opcode da instrução atual
  output reg [3:0] state,
  output reg mem_read,
  output reg mem_write,
  output reg reg_write,
  output reg [1:0] alu_src_a,
  output reg [1:0] alu_src_b,
  output reg [3:0] alu_control,
  output reg [1:0] imm_src,
  output reg ir_write,
  output reg pc_write,
  output reg mem_to_reg
);

  // Definição dos estados
  parameter IF = 4'd0,
            ID = 4'd1,
            EX = 4'd2,
            MEM_RD = 4'd3,
            MEM_WR = 4'd4,
            WB = 4'd5,
            IMM_I = 2'b00,
            IMM_S = 2'b01;

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state <= IF;
    end else begin
      $display("state = %0d, opcode = %b", state, opcode);
      case (state)
        // 1. Busca a instrução
        IF: begin
          ir_write <= 1;
          pc_write <= 1;
          alu_src_a <= 2'b00;      // PC
          alu_src_b <= 2'b10;      // constante 4
          alu_control <= 4'b0010;  // ADD
          state <= ID;
        end

        // 2. Decodifica e lê registradores
        ID: begin
          ir_write <= 0;
          pc_write <= 0;
          alu_src_a <= 2'b10;
          alu_src_b <= 2'b01;     // offset imediato
          alu_control <= 4'b0010;      // ADD
          if (opcode == 7'b0000011) begin       // lw
            imm_src <= IMM_I;
            state <= MEM_RD;
          end else if (opcode == 7'b0100011) begin // sw
            imm_src <= IMM_S;
            state <= MEM_WR;
          end else if (opcode == 7'b0110111) begin  // 
            state <= IF; // pula o LUI (sem implementar por enquanto)
          end else begin
            state <= IF; // fallback para evitar travamento
          end
        end

        // 3. Acesso à memória (leitura)
        MEM_RD: begin
          mem_read <= 1;
          state <= WB;
        end

        // 4. Acesso à memória (escrita)
        MEM_WR: begin
          mem_write <= 1;
          state <= IF;
        end

        // 5. Write-back para lw
        WB: begin
          mem_read <= 0;
          reg_write <= 1;
          mem_to_reg <= 1;
          state <= IF;
        end

        default: state <= IF;
      endcase
    end
  end
endmodule
