module core(
  input clk,
  input resetn,
  output [31:0] address,
  output [31:0] data_out,
  input [31:0] data_in,
  output we
);
  // Registradores internos
  reg [31:0] PC, IR, A, B, ALUOut, MDR;
  wire [31:0] write_data;
  
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
  
  // Atribuições combinacionais para controle datapath
  assign imm    = (imm_src == 2'b00) ? imm_i :
                  (imm_src == 2'b01) ? imm_s :
                  (imm_src == 2'b10) ? imm_j : 32'd0;
  
  assign alu_in_a = (alu_src_a == 2'b00) ? PC :
                   (alu_src_a == 2'b10) ? A : 32'd0;
  
  assign alu_in_b = (alu_src_b == 2'b00) ? B :
                   (alu_src_b == 2'b01) ? imm :
                   (alu_src_b == 2'b10) ? 32'd4 : 32'd0;
  
  // Atribuições combinacionais para interface externa
  assign we = mem_write;
  assign address = (mem_read || mem_write) ? ALUOut : PC;
  assign data_out = B;
  assign write_data = mem_to_reg ? MDR : ALUOut;
  
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
  
  // Lógica combinacional para determinar próximos valores de registradores
  wire [31:0] next_PC = pc_write ? alu_result : PC;
  wire [31:0] next_IR = ir_write ? data_in : IR;
  wire [31:0] next_A = (state == ID) ? reg_data1 : A;
  wire [31:0] next_B = (state == ID) ? reg_data2 : B;
  wire [31:0] next_ALUOut = ((state == EX_R) || (state == EX_I) || (state == EX_S) || (state == EX_J)) ? alu_result : ALUOut;
  wire [31:0] next_MDR = mem_read ? data_in : MDR;
  
  // Atualizações sequenciais dos registradores
  always @(posedge clk) begin
    if (!resetn) begin

      PC <= 0;
      IR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
      MDR <= 0;

      // $display("Waiting reset memory");

    end else begin
    
      PC <= next_PC;
      IR <= next_IR;
      A <= next_A;
      B <= next_B;
      ALUOut <= next_ALUOut;
      MDR <= next_MDR;

      // $display("WRITE_DATA : %h", next_write_data);
      // $display("PC : %h, IR : %h, A : %h, B : %h, ALUout : %h, MDR : %h, write_data : %h", PC, IR, A, B, ALUOut, MDR, write_data);

    end
  end
endmodule