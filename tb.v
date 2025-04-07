module tb();

reg clk, resetn;
wire we;
wire [31:0] address, data_out, data_in;

// Instancia o processador
core dut(
  .clk(clk),
  .resetn(resetn),
  .address(address),
  .data_out(data_out),
  .data_in(data_in),
  .we(we)
);

// Instancia a memória
memory m(
  .address(address),
  .data_in(data_out),
  .data_out(data_in),
  .we(we) 
);

// Geração do clock: alterna a cada 1 unidade de tempo
always #1 clk = (clk === 1'b0);

// Início da simulação
initial begin
  // Inicializa o dump de sinais (para análise com GTKWave)
  $dumpfile("saida.vcd");
  $dumpvars(0, tb);

  // Reset ativo baixo: inicia zerado por 11 unidades de tempo
  resetn = 1'b0;
  #11 resetn = 1'b1;

  $display("*** Starting simulation. ***");

  // Para a simulação após 4000 unidades de tempo (2000 ciclos)
  #4000 $finish;
end

// Monitora acessos à memória (endereço com bit 11 igual a 1)
always @(posedge clk) begin
  // Condição para encerrar caso chegue na posição 0xFFC
  if (address == 'hFFC) begin
    $display("Address reached 4092 (0xFFC). Stopping simulation.");
    $finish;
  end
  // Impressão de acessos à memória mapeada (bit 11 do endereço = 1)
  else if (address[11] == 1) begin
    if (we == 1)
      $display("M[0x%h] <- 0x%h (escrita na memória)", address, data_out);
    else
      $display("M[0x%h] -> 0x%h (leitura da memória)", address, data_in);
  end
end

endmodule
