module fsm_apb_protocol (
  input  logic pclk,
  input  logic preset_n,
  input  logic psel,
  input  logic pwrite,
  input  logic penable,
  output logic pready,
  output logic rd_en,
  output logic wr_en
);

  localparam IDLE   = 1'b0,
             ACCESS = 1'b1;

  logic pstate;
  logic nstate;

  always@(*) begin
    case (pstate)
      IDLE   : nstate = psel ? ACCESS : IDLE;
      ACCESS : nstate = IDLE;
    endcase
  end
  

  assign rd_en  = (pstate == ACCESS) ? (penable & (~pwrite)) : 0;
  assign wr_en  = (pstate == ACCESS) ? (penable & (pwrite)) : 0;
  assign pready = 1'b1;
  
  //PSR
    dff #(
    .FLOP_WIDTH(1)
  )u_dff(
    .clk(pclk),
    .reset_b(preset_n),
    .q (pstate),
    .d (nstate)
  );

endmodule