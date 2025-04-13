module alu(
  input [31:0] A, B,
  input [3:0] ALUControl,
  output reg [31:0] ALUResult,
  output Zero
);
  assign Zero = (ALUResult == 0);
  always @(ALUControl, A, B) begin
    // $display("A : %h, B : %h, ALUResult : %h, ALUControl : %h", A, B, ALUResult, ALUControl);
    case (ALUControl)
      4'b0000: ALUResult = A & B;                     // AND
      4'b0001: ALUResult = A | B;                     // OR
      4'b0010: ALUResult = A + B;                     // ADD
      4'b0110: ALUResult = A - B;                     // SUB
      4'b0111: ALUResult = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT (signed)
      4'b1100: ALUResult = ~(A | B);                  // NOR
      4'b0011: ALUResult = A ^ B;                     // XOR
      4'b0100: ALUResult = A << B[4:0];               // SLL (shift left logical)
      4'b0101: ALUResult = A >> B[4:0];               // SRL (shift right logical)
      4'b1000: ALUResult = $signed(A) >>> B[4:0];     // SRA (shift right arithmetic)
      4'b1001: ALUResult = (A < B) ? 32'b1 : 32'b0;   // SLTU (unsigned)
      4'b1010: ALUResult = B;                         // LUI helper (pass B)
      4'b1011: ALUResult = A + (B << 12);             // AUIPC helper
      default: ALUResult = 32'b0;
    endcase
  end
  //always @(ALUControl, A, B) begin
  //  $display("ALU: A=%h, B=%h, ALUControl=%b, Result=%h", A, B, ALUControl, ALUResult);
  //end
endmodule