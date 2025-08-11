module fsm_apb_protocol (
  input  pclk,
  input  preset_n,
  input  psel,
  input  pwrite,
  input  penable,
  output pready,
  output rd_en,
  output wr_en
);

  localparam IDLE   = 1'b0,
             ACCESS = 1'b1;

  wire pstate;
  reg nstate;

  always @(*) begin
    case (pstate)
      IDLE   : nstate = psel ? ACCESS : IDLE;
      ACCESS : nstate = IDLE;
    endcase
  end

  assign rd_en  = (pstate == ACCESS) ? (penable & (~pwrite)) : 0;
  assign wr_en  = (pstate == ACCESS) ? (penable & (pwrite)) : 0;
  assign pready = 1'b1;

  // PSR
  dff #(
    .FLOP_WIDTH(1)
  ) u_dff (
    .clk(pclk),
    .reset_b(preset_n),
    .q(pstate),
    .d(nstate)
  );

endmodule
