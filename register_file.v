module register_file(
  input clk,
  input reg_write,                // sinal para escrita
  input [4:0] rs1, rs2, rd,       // registradores fonte e destino
  input [31:0] write_data,        // dado a ser escrito
  output [31:0] read_data1,       // saída de rs1
  output [31:0] read_data2        // saída de rs2
);
  reg [31:0] regs[0:31];
  integer i;
  
  // Inicialização dos registradores
  initial begin
    for (i = 0; i < 32; i = i + 1)
      regs[i] = 32'h00000000;
  end
  
  // leitura assíncrona
  assign read_data1 = (rs1 != 0) ? regs[rs1] : 32'b0;
  assign read_data2 = (rs2 != 0) ? regs[rs2] : 32'b0;
  
  // escrita síncrona
  always @(posedge clk) begin
    //$display("reg_write: %b, rs1 : %d, rs2 : %d, write_data : %h", reg_write, rs1, rs2, write_data);
    // $display("read_data1 : %h, read_data2 : %h", read_data1, read_data2);
    if (reg_write && rd != 0)
      regs[rd] <= write_data;
    //$display("X0 : %h, X1 : %h, X2 : %h, X3 : %h, X4 : %h, X5 : %h", regs[0], regs[1], regs[2], regs[3], regs[4], regs[5]);
  end
endmodule