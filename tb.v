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

// No módulo tb (testbench)
reg ebreak_detected = 0;

// Adicione este bloco para detectar o EBREAK baseado no endereço
always @(posedge clk) begin
  // Assumindo que o EBREAK é a última instrução no seu programa
  // e está no endereço 0x30 (ou qualquer endereço correto para o seu caso)
  if (address == 32'h30 && !ebreak_detected) begin
    ebreak_detected = 1;
    $display("\n--- Final register values ---");
    $display("x2 = %h", tb.dut.rf.regs[2]);
    $display("x3 = %h", tb.dut.rf.regs[3]);
    $display("x4 = %h", tb.dut.rf.regs[4]);
    $display("x5 = %h", tb.dut.rf.regs[5]);
    $display("x20 = %h", tb.dut.rf.regs[20]);
    $display("Memory[0x800] = %h", tb.m.mem[32'h800 >> 2]);
  end
end

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