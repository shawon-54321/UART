module uart_receiver_top (
  input pclk,
  input presetn,
  input utrrst,
  input sample_edge,
  input voting_edge,
  input uart_rxd,
  input loop_txd,
  input loop,
  input [1:0] wls,
  input pen,
  input eps,
  input sp,

  output [7:0] rsr_data,
  output frame_error,
  output parity_error,
  output error_check,
  output receive_load_en,
  output uart_break
);

  wire received_parity;

  // Parity checker instance
  parity_checker u_parity_checker (
    .rsr_data        (rsr_data),
    .received_parity (received_parity),
    .pen             (pen),
    .eps             (eps),
    .sp              (sp),
    .parity_error    (parity_error)
  );

  wire receive_shift_en;
  wire receive_frame_counter_en;
  wire receive_frame_counter_clear;
  wire voting_shift_en;
  wire receive_done;
  wire all_zero;
  wire rx_data;

  // UART receive FSM instance
  uart_receive_fsm u_uart_receive_fsm (
    .pclk                        (pclk),
    .presetn                     (presetn),
    .utrrst                      (utrrst),
    .uart_rxd                    (uart_rxd),
    .sample_edge                 (sample_edge),
    .voting_edge                 (voting_edge),
    .receive_done                (receive_done),
    .all_zero                    (all_zero),
    .rx_data                     (rx_data),
    .receive_shift_en            (receive_shift_en),
    .voting_shift_en             (voting_shift_en),
    .error_check                 (error_check),
    .receive_frame_counter_en    (receive_frame_counter_en),
    .receive_frame_counter_clear (receive_frame_counter_clear),
    .receive_load_en             (receive_load_en),
    .uart_break                  (uart_break)
  );

  // Receive frame detector instance
  receive_frame_detector u_receive_frame_detector (
    .pclk                        (pclk),
    .presetn                     (presetn),
    .receive_frame_counter_en    (receive_frame_counter_en),
    .receive_frame_counter_clear (receive_frame_counter_clear),
    .sample_edge                 (sample_edge),
    .wls                         (wls),
    .pen                         (pen),
    .receive_done                (receive_done)
  );

  // UART receiver shift block instance
  uart_receiver_shift_block u_uart_receiver_shift_block (
    .pclk             (pclk),
    .presetn          (presetn),
    .receive_shift_en (receive_shift_en),
    .voting_shift_en  (voting_shift_en),
    .uart_rxd         (uart_rxd),
    .error_check      (error_check),
    .loop_txd         (loop_txd),
    .loop             (loop),
    .wls              (wls),
    .pen              (pen),
    .received_parity  (received_parity),
    .frame_error      (frame_error),
    .rsr_data         (rsr_data),
    .all_zero         (all_zero),
    .rx_data          (rx_data)
  );

endmodule
