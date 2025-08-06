module uart_receiver_top (
  input  logic       pclk,
  input  logic       presetn,
  input  logic       utrrst,
  input  logic       sample_edge,
  input  logic       voting_edge,
  input  logic       uart_rxd,
  input  logic       loop_txd,
  input  logic       loop,
  input  logic [1:0] wls,
  input  logic       pen,
  input  logic       eps,
  input  logic       sp,

  output logic [7:0] rsr_data,
  output logic       frame_error,
  output logic       parity_error,
  output logic       error_check,
  output logic       receive_load_en,
  output logic       uart_break
);

  logic received_parity;

  parity_checker u_parity_checker (
    .rsr_data        ( rsr_data       ),
    .received_parity ( received_parity),
    .pen             ( pen            ),
    .eps             ( eps            ),
    .sp              ( sp             ),
    
    .parity_error    ( parity_error   )
  );

  logic receive_shift_en;
  logic receive_frame_counter_en;
  logic receive_frame_counter_clear;
  logic voting_shift_en;
  logic receive_done;
  logic all_zero;
  logic rx_data;


  uart_receive_fsm u_uart_receive_fsm (
    .pclk                        ( pclk                        ),
    .presetn                     ( presetn                     ),
    .utrrst                      ( utrrst                      ),
    .uart_rxd                    ( uart_rxd                    ),
    .sample_edge                 ( sample_edge                 ),
    .voting_edge                 ( voting_edge                 ),
    .receive_done                ( receive_done                ),
    .all_zero                    ( all_zero                    ),
    .rx_data                     ( rx_data                     ),
    
    .receive_shift_en            ( receive_shift_en            ),
    .voting_shift_en             ( voting_shift_en             ),
    .error_check                 ( error_check                 ),
    .receive_frame_counter_en    ( receive_frame_counter_en    ),
    .receive_frame_counter_clear ( receive_frame_counter_clear ),
    .receive_load_en             ( receive_load_en             ),
    .uart_break                  ( uart_break                  )
  );
  
  receive_frame_detector u_receive_frame_detector (

    .pclk                        ( pclk                       ),
    .presetn                     ( presetn                    ),
    .receive_frame_counter_en    ( receive_frame_counter_en   ),
    .receive_frame_counter_clear ( receive_frame_counter_clear),
    .sample_edge                 ( sample_edge                ),
    
    .receive_done                ( receive_done               )
  );

  uart_receiver_shift_block u_uart_receiver_shift_block (
    .pclk             ( pclk             ),
    .presetn          ( presetn          ),
    .receive_shift_en ( receive_shift_en ),
    .voting_shift_en  ( voting_shift_en  ),
    .uart_rxd         ( uart_rxd         ),
    .error_check      ( error_check      ),
    .loop_txd         ( loop_txd         ),
    .loop             ( loop             ),
    .wls              ( wls              ),
    .pen              ( pen              ),
    
    .received_parity  ( received_parity  ),
    .frame_error      ( frame_error      ),
    .rsr_data         ( rsr_data         ),
    .all_zero         ( all_zero         ),
    .rx_data          ( rx_data          )
  );

endmodule