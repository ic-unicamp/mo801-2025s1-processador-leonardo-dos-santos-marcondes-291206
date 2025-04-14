module memory(
  input clk,
  input [31:0] address,
  input [31:0] data_in,
  output [31:0] data_out,
  input we,
  input [3:0] byte_enable  // Novo sinal: um bit para cada byte
);
  reg [31:0] mem[0:1023]; // 16KB de memória
  integer i;
  
  assign data_out = mem[address[13:2]];

  always @(posedge clk) begin
    if (we) begin
      if (byte_enable[0]) mem[address[13:2]][7:0] <= data_in[7:0];
      if (byte_enable[1]) mem[address[13:2]][15:8] <= data_in[15:8];
      if (byte_enable[2]) mem[address[13:2]][23:16] <= data_in[23:16];
      if (byte_enable[3]) mem[address[13:2]][31:24] <= data_in[31:24];
    end
  end
  
  initial begin
    for (i = 0; i < 1024; i = i + 1) begin
      mem[i] = 32'h00000000;
    end
    $readmemh("memory.mem", mem);
  end
endmodule