module uart_receive_fsm (
  input  logic pclk,
  input  logic presetn,
  input  logic utrrst,       //uart receive enable
  input  logic uart_rxd,    //uart serial input line
  input  logic sample_edge,
  input  logic receive_done,

  output logic receive_shift_en,
  output logic error_check,
  output logic receive_frame_counter_en,
  output logic receive_frame_counter_clear
);

  localparam [1:0] IDLE    = 2'b00,
                   START   = 2'b01,
                   RECEIVE = 2'b10;

  logic [1:0] pstate;
  logic [1:0] nstate;

  logic receive_st;

  assign receive_st  = pstate == RECEIVE;

  //NSL
  always@(*)begin
    casez (pstate)
      IDLE    : nstate = (utrrst & (~ uart_rxd)) ? START : IDLE;
      START   : nstate = utrrst ? (sample_edge ? ((~ uart_rxd) ? RECEIVE : IDLE) : START) : IDLE;
      RECEIVE : nstate = (~ receive_done & utrrst) ? IDLE : RECEIVE;
    endcase
  end

  //OL
  assign receive_shift_en            = receive_st;
  assign error_check                 = receive_st & receive_done;
  assign receive_frame_counter_en    = receive_st & sample_edge;
  assign receive_frame_counter_clear = ~ receive_st;

  //PSR
  dff #(
    .FLOP_WIDTH(2)
  ) u_dff (
    .clk     ( pclk   ),
    .reset_b ( presetn),
    .d       ( nstate ),
    .q       ( pstate )
  );

endmodule