module core(
  input clk,
  input resetn,
  output reg [31:0] address,
  output reg [31:0] data_out,
  input [31:0] data_in,
  output reg we
);

  // Registradores internos
  reg [31:0] PC, IR, A, B, ALUOut, MDR;
  reg [31:0] write_data;

  // Estado atual
  wire [3:0] state;

  // Decodificação da instrução
  wire [6:0] opcode = IR[6:0];
  wire [4:0] rd     = IR[11:7];
  wire [2:0] funct3 = IR[14:12];
  wire [4:0] rs1    = IR[19:15];
  wire [4:0] rs2    = IR[24:20];

  // Imediatos
  wire [1:0] imm_src;
  wire [31:0] imm_i = {{20{IR[31]}}, IR[31:20]};
  wire [31:0] imm_s = {{20{IR[31]}}, IR[31:25], IR[11:7]};

  // Seletor do imm
  wire [31:0] imm = (imm_src == 2'b00) ? imm_i : 
                    (imm_src == 2'b01) ? imm_s : 32'd0;

  // Sinais de controle
  wire mem_read, mem_write, reg_write;
  wire ir_write, pc_write, mem_to_reg;
  wire [1:0] alu_src_a;
  wire [1:0] alu_src_b;
  wire [3:0] alu_control;

  // Dados dos registradores
  wire [31:0] reg_data1, reg_data2;

  // Entradas da ALU
  wire [31:0] alu_in_a = (alu_src_a == 2'b00) ? PC :
                         (alu_src_a == 2'b10) ? A : 32'd0;
  wire [31:0] alu_in_b = (alu_src_b == 2'b00) ? B :
                         (alu_src_b == 2'b01) ? imm :
                         (alu_src_b == 2'b10) ? 32'd4 : 32'd0;

  wire [31:0] alu_result;

  // Banco de registradores
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

  // ALU
  alu alu0(
    .a(alu_in_a),
    .b(alu_in_b),
    .alu_control(alu_control),
    .result(alu_result)
  );

  // Unidade de controle (FSM)
  control_unit cu(
    .clk(clk),
    .resetn(resetn),
    .opcode(opcode),
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

// Lógica sequencial principal
  always @(posedge clk) begin
    if (!resetn) begin
      PC <= 0;
    end else begin
      if (pc_write)
        PC <= alu_result;

      if (ir_write) begin
        IR <= data_in;
        $display("IR loaded: %h", data_in);
      end

      if (mem_to_reg)
        write_data <= MDR;
      else
        write_data <= ALUOut;

      A <= reg_data1;
      B <= reg_data2;
      ALUOut <= alu_result;
      MDR <= data_in;

      if (mem_write) begin
        data_out <= B;
        address <= ALUOut;
        we <= 1;
      end else begin
        we <= 0;
        address <= PC;
      end
    end
end

endmodule