module uart_receive_fsm (
  input  logic pclk,
  input  logic presetn,
  input  logic utrrst,       //uart receive enable
  input  logic uart_rxd,    //uart serial input line
  input  logic all_zero,
  input  logic rx_data,
  input  logic sample_edge,
  input  logic voting_edge,
  input  logic receive_done,

  output logic receive_shift_en,
  output logic voting_shift_en,
  output logic error_check,
  output logic receive_frame_counter_en,
  output logic receive_frame_counter_clear,
  output logic uart_break,
  output logic receive_load_en
);

  localparam [2:0] IDLE    = 3'b000,
                   START   = 3'b001,
                   RECEIVE = 3'b010,
                   WAIT    = 3'b011,
                   BREAK   = 3'b100;

  logic [2:0] pstate;
  logic [2:0] nstate;

  logic receive_st;
  logic start_st;
  logic break_st;
  logic wait_st;

  assign receive_st  = pstate == RECEIVE;
  assign start_st    = pstate == START;
  assign break_st    = pstate == BREAK;
  assign wait_st     = pstate == WAIT;

  //NSL
  always@(*)begin
    casez (pstate)
      IDLE    : nstate = (utrrst & (~ uart_rxd)) ? START : IDLE;
      START   : nstate = utrrst ? (sample_edge ? (rx_data ? IDLE : RECEIVE) : START) : IDLE;
      RECEIVE : nstate = utrrst ? (receive_done ? WAIT : RECEIVE) : IDLE;
      WAIT    : nstate = all_zero ? (sample_edge ? BREAK : WAIT) : (rx_data ? IDLE : WAIT);
      BREAK   : nstate = rx_data ? IDLE : BREAK;
    endcase
  end

  //OL
  assign receive_shift_en            = receive_st & sample_edge;
  assign error_check                 = receive_st & receive_done;
  assign receive_frame_counter_en    = receive_st & sample_edge;
  assign receive_frame_counter_clear = ~ receive_st;
  assign voting_shift_en             = (receive_st | start_st | wait_st | break_st) & voting_edge;
  assign uart_break                  = break_st & (~ rx_data);
  assign receive_load_en             = (wait_st & ((~ all_zero) & rx_data)) | (break_st & rx_data); 

  //PSR
  dff #(
    .FLOP_WIDTH(3)
  ) u_dff (
    .clk     ( pclk   ),
    .reset_b ( presetn),
    .d       ( nstate ),
    .q       ( pstate )
  );

endmodule