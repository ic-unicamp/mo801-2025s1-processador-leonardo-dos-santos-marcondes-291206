module memory(
  input [31:0] address,
  input [31:0] data_in,
  output reg [31:0] data_out,
  input we
);

  reg [31:0] mem[0:1023]; // 4KB de memória (1024 palavras de 32 bits)
  integer i;

  always @(*) begin
    if (we)
      mem[address[13:2]] = data_in;
    data_out = mem[address[13:2]];
  end

  initial begin
    for (i = 0; i < 1024; i = i + 1)
      mem[i] = 32'h00000000;

    $readmemh("memory.mem", mem); // Carrega programa
  end

endmodule
