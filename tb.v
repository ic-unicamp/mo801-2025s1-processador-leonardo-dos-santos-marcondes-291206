module tb();

reg clk, resetn;
wire we;
wire [31:0] address, data_out, data_in;
wire [3:0] byte_enable;

core dut(
  .clk(clk),
  .resetn(resetn),
  .address(address),
  .data_out(data_out),
  .data_in(data_in),
  .byte_enable(byte_enable),
  .we(we)
);

memory m(
  .clk(clk),
  .address(address),
  .data_in(data_out),
  .data_out(data_in),
  .byte_enable(byte_enable),
  .we(we) 
);

// Clock generator
always #1 clk = (clk===1'b0);

// Inicia a simulação e executa até 2000 unidades de tempo após o reset
initial begin
  $dumpfile("saida.vcd");
  $dumpvars(0, tb);
  resetn = 1'b0;
  #11 resetn = 1'b1;
  $display("*** Starting simulation. ***");
  #4000 $finish;
end

// Verifica se o endereço atingiu 4092 (0xFFC) e encerra a simulação
always @(posedge clk) begin
  if (address == 'hFFC) begin
    $display("Address reached 4092 (0xFFC). Stopping simulation.");
    $finish;
  end
  else if (address[11] == 1)
    if (we == 1)
      $display("=== M[0x%h] <- 0x%h", address, data_out);
    // else
    //   $display("=== M[0x%h] -> 0x%h", address, data_in);
end

endmodule