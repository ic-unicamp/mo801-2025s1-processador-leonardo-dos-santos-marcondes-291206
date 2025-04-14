module core(
  input clk,
  input resetn,
  input [31:0] data_in,
  output [31:0] address,
  output [31:0] data_out,
  output [3:0] byte_enable,
  output we
);

  // Parâmetros para estados
  parameter IF       = 4'd0;
  parameter ID       = 4'd1;
  parameter EX_R     = 4'd2;
  parameter EX_I     = 4'd3;
  parameter EX_S     = 4'd4;
  parameter EX_J     = 4'd5;
  parameter MEM_RD   = 4'd6;
  parameter MEM_WR   = 4'd7;
  parameter WB_ALU   = 4'd8;
  parameter WB_MEM   = 4'd9;
  parameter HALT     = 4'd10;
  parameter EX_B     = 4'd11;

  // Registradores internos
  reg [31:0] PC, IR, A, B, ALUOut, MDR;
  
  // Declaração dos wires
  wire [6:0] opcode;
  wire [4:0] rd;
  wire [2:0] funct3;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [6:0] funct7;
  wire [31:0] imm_i;
  wire [31:0] imm_s;
  wire [31:0] imm_j;
  wire [31:0] imm_b;
  wire [31:0] imm_u;
  wire [31:0] imm;
  wire [3:0] state;
  wire mem_read, mem_write, reg_write;
  wire ir_write, pc_write, mem_to_reg;
  wire [1:0] alu_src_a, alu_src_b, imm_src;
  wire [3:0] alu_control;
  wire zero;
  wire [31:0] alu_result;
  wire [31:0] reg_data1, reg_data2;
  wire [31:0] alu_in_a;
  wire [31:0] alu_in_b;
  wire [31:0] load_data;
  wire [7:0] byte_data;
  wire [2:0] load_type; 
  wire [2:0] store_type;
  wire [31:0] store_data;
  wire [31:0] write_data;
  wire [15:0] half_data;
  wire [31:0] next_PC;
  wire [31:0] next_IR;
  wire [31:0] next_A;
  wire [31:0] next_B;
  wire [31:0] next_ALUOut;
  wire [31:0] next_MDR;
  wire branch_equal;
  wire branch_taken;
  wire [31:0] branch_target;

  // Atribuições combinacionais para parse de instrução
  assign opcode = IR[6:0];
  assign rd     = IR[11:7];
  assign funct3 = IR[14:12];
  assign rs1    = IR[19:15];
  assign rs2    = IR[24:20];
  assign funct7 = IR[31:25];
  assign imm_i  = {{20{IR[31]}}, IR[31:20]};
  assign imm_s  = {{20{IR[31]}}, IR[31:25], IR[11:7]};
  assign imm_j  = {{12{IR[31]}}, IR[19:12], IR[20], IR[30:21], 1'b0};
  assign imm_b  = {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};
  assign imm_u  = {IR[31:12], 12'b0};
  assign load_type = funct3;
  assign store_type = funct3;
  
  // Atribuições combinacionais para controle datapath
  assign imm = (imm_src == 2'b00) ? imm_i :
               (imm_src == 2'b01) ? imm_s :
               (imm_src == 2'b10) ? imm_j :
               (imm_src == 2'b11) ? imm_b :
               (opcode == 7'b0110111) ? imm_u : 32'd0; // Adiciona suporte para imm_u
  
  
  assign alu_in_a = (alu_src_a == 2'b00) ? PC :
                   (alu_src_a == 2'b10) ? A : 32'd0;
  
  assign alu_in_b = (alu_src_b == 2'b00) ? B :
                   (alu_src_b == 2'b01) ? imm :
                   (alu_src_b == 2'b10) ? 32'd4 : 32'd0;
  
  // Atribuições combinacionais para interface externa
  assign we = mem_write;
  assign address = (mem_read || mem_write) ? ALUOut : PC;
  
  assign store_data = (store_type == 3'b000)   ? // SB
                      ((ALUOut[1:0] == 2'b00)  ? {data_in[31:8], B[7:0]} :
                      (ALUOut[1:0] == 2'b01)   ? {data_in[31:16], B[7:0], data_in[7:0]} :
                      (ALUOut[1:0] == 2'b10)   ? {data_in[31:24], B[7:0], data_in[15:0]} :
                      {B[7:0], data_in[23:0]}) : (store_type == 3'b001) ? // SH
                      ((ALUOut[1:0] == 2'b00)  ? {data_in[31:16], B[15:0]} :
                      (ALUOut[1:0] == 2'b10)   ? {B[15:0], data_in[15:0]} : data_in) : B; // SW 
    
  assign data_out = ((opcode == 7'b0100011) && (funct3 == 3'b000 || funct3 == 3'b001)) ? store_data : B;

  assign byte_enable = (store_type == 3'b000)   ? // SB
                       (4'b0001 << ALUOut[1:0]) : 
                       (store_type == 3'b001)   ? // SH
                       ((ALUOut[1:0] == 2'b00)  ? 4'b0011 :
                       (ALUOut[1:0] == 2'b10)   ? 4'b1100 : 4'b0000) : // Endereço não alinhado
                       4'b1111; // SW (todos os bytes)
  
  // MODIFICAÇÃO: Usar imm_u diretamente para LUI                     
  assign write_data = (opcode == 7'b0110111) ? imm_u :                // LUI
                   (opcode == 7'b0010111) ? (PC + imm_u) :          // AUIPC
                   mem_to_reg ? MDR : ALUOut;

  assign byte_data = (ALUOut[1:0] == 2'b00) ? data_in[7:0]:
                     (ALUOut[1:0] == 2'b01) ? data_in[15:8]:
                     (ALUOut[1:0] == 2'b10) ? data_in[23:16]:
                                              data_in[31:24];

  // Para operações LH
  assign half_data = (ALUOut[1:0] == 2'b00) ? data_in[15:0]:
                     (ALUOut[1:0] == 2'b10) ? data_in[31:16]:
                                              data_in[15:0]; 

  assign load_data = (load_type == 3'b000) ? {{24{byte_data[7]}}, byte_data} :  // LB (extensão de sinal)
                     (load_type == 3'b001) ? {{16{half_data[15]}}, half_data} : // LH (extensão de sinal)
                     (load_type == 3'b010) ? data_in :                          // LW
                     (load_type == 3'b100) ? {24'b0, byte_data} :               // LBU (extensão com zeros)
                     (load_type == 3'b101) ? {16'b0, half_data} :               // LHU (extensão com zeros)
                     data_in;  // Caso padrão

  assign branch_taken = (state == EX_B && opcode == 7'b1100011 && 
                        ((funct3 == 3'b000 && zero) ||         // BEQ
                         (funct3 == 3'b001 && !zero) ||        // BNE
                         (funct3 == 3'b100 && !zero && alu_control == 4'b0111) || // BLT (SLT result != 0)
                         (funct3 == 3'b101 && zero && alu_control == 4'b0111) ||  // BGE (SLT result == 0)
                         (funct3 == 3'b110 && !zero && alu_control == 4'b1001) || // BLTU (SLTU result != 0)
                         (funct3 == 3'b111 && zero && alu_control == 4'b1001)));  // BGEU (SLTU result == 0)
  
  // Calcula o target do branch
  assign branch_target = PC + imm_b;

  // Na atribuição de next_PC
  assign next_PC = branch_taken ? branch_target : 
                  pc_write ? alu_result : PC;

  // Demais atribuições para os próximos valores dos registradores
  assign next_IR = ir_write ? data_in : IR;
  assign next_A = (state == ID) ? reg_data1 : A;
  assign next_B = (state == ID) ? reg_data2 : B;
  assign next_ALUOut = ((state == EX_R) || (state == EX_I) || (state == EX_S) || 
                     (state == EX_J) || (state == EX_B) || 
                     (opcode == 7'b0110111) || (opcode == 7'b0010111)) ? alu_result : ALUOut;
  assign next_MDR = mem_read ? load_data : MDR;
  
  // Instanciação dos módulos
  register_file rf(
    .clk(clk),
    .reg_write(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(write_data),
    .read_data1(reg_data1),
    .read_data2(reg_data2)
  );
  
  alu alu0(
    .A(alu_in_a),
    .B(alu_in_b),
    .ALUControl(alu_control),
    .ALUResult(alu_result),
    .Zero(zero)
  );
  
  control_unit cu(
    .clk(clk),
    .resetn(resetn),
    .opcode(opcode),
    .funct7(funct7),
    .funct3(funct3),
    .branch_taken(branch_taken),
    .zero(zero),           
    .state(state),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .reg_write(reg_write),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .alu_control(alu_control),
    .ir_write(ir_write),
    .pc_write(pc_write),
    .mem_to_reg(mem_to_reg),
    .imm_src(imm_src)
  );

  always @(posedge clk) begin
    if (opcode == 7'b0010111) begin // AUIPC
      $display("AUIPC EXECUTION: PC=%h, rd=x%d, imm_u=%h, alu_in_a=%h, alu_in_b=%h", 
              PC, rd, imm_u, alu_in_a, alu_in_b);
      $display("alu_result=%h, ALUOut=%h, write_data=%h", 
              alu_result, ALUOut, write_data);
    end
  end
    
  // Atualizações sequenciais dos registradores
  always @(posedge clk) begin
  
    if (!resetn) begin

      PC <= 0;
      IR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
      MDR <= 0;

    end else begin

      PC <= next_PC;
      IR <= next_IR;
      A <= next_A;
      B <= next_B;
      ALUOut <= next_ALUOut;
      MDR <= next_MDR;
      
    end
  end
endmodule