module uart_receive_fsm (
  input pclk,
  input presetn,
  input utrrst,        // UART receive enable
  input uart_rxd,     // UART serial input line
  input all_zero,
  input rx_data,
  input sample_edge,
  input voting_edge,
  input receive_done,

  output receive_shift_en,
  output voting_shift_en,
  output error_check,
  output receive_frame_counter_en,
  output receive_frame_counter_clear,
  output uart_break,
  output receive_load_en
);

  // State encoding
  localparam [2:0] IDLE    = 3'b000,
                   START   = 3'b001,
                   RECEIVE = 3'b010,
                   WAIT    = 3'b011,
                   BREAK   = 3'b100;

  wire [2:0] pstate;
  reg [2:0] nstate;

  wire receive_st;
  wire start_st;
  wire break_st;
  wire wait_st;

  assign receive_st  = pstate == RECEIVE;
  assign start_st    = pstate == START;
  assign break_st    = pstate == BREAK;
  assign wait_st     = pstate == WAIT;

  //NSL
  always@(*)begin
    casez (pstate)
      IDLE    : nstate = (utrrst) ? START : IDLE;
      START   : nstate = utrrst ? (sample_edge ? (rx_data ? IDLE : RECEIVE) : START) : IDLE;
      RECEIVE : nstate = utrrst ? (receive_done ? WAIT : RECEIVE) : IDLE;
      WAIT    : nstate = all_zero ? (sample_edge ? BREAK : WAIT) : (rx_data ? IDLE : WAIT);
      BREAK   : nstate = rx_data ? IDLE : BREAK;
    endcase
  end

  //OL
  assign receive_shift_en            = receive_st & sample_edge;
  //assign error_check                 = receive_st & receive_done;
  assign error_check                 = (wait_st & (~ all_zero & rx_data)) | (break_st & rx_data); 
  assign receive_frame_counter_en    = receive_st & sample_edge;
  assign receive_frame_counter_clear = ~ receive_st;
  assign voting_shift_en             = (receive_st | start_st | wait_st | break_st) & voting_edge;
  assign uart_break                  = break_st & (~ rx_data);
  //assign receive_load_en             = (receive_st & (utrrst & receive_done)) | (break_st & rx_data); 
  assign receive_load_en             = (wait_st & (~ all_zero & rx_data)) | (break_st & rx_data); 

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