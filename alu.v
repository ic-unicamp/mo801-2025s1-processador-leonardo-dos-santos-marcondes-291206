module alu(
  input [31:0] A, B,
  input [3:0] ALUControl,
  output reg [31:0] ALUResult,
  output Zero
);

  assign Zero = (ALUResult == 0);

  always @(ALUControl, A, B) begin
    case (ALUControl)
      4'b0000: ALUResult = A & B;
      4'b0001: ALUResult = A | B;
      4'b0010: ALUResult = A + B;
      4'b0110: ALUResult = A - B;
      4'b0111: ALUResult = (A < B) ? 32'b1 : 32'b0;
      4'b1100: ALUResult = ~(A | B); // NOR
      default: ALUResult = 32'b0;
    endcase
  end


endmodule
