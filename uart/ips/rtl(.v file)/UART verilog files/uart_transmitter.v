module uart_transmitter (
  input pclk,
  input presetn,
  input utrst,
  input thre,
  input pen,
  input eps,
  input sp,
  input stb,
  input loop,
  input transmit_edge,
  input [7:0] tx_data,
  input [1:0] wls,
  output transmit_clk_clr,
  output tsr_load,
  output shift_cnt_eq,
  output loop_txd,
  output uart_txd
);

  wire shift_en;
  wire shift_count_en;
  wire shift_count_clr;
  wire data_cnt_eq;
  wire par;
  wire not_op;
  wire parity;

  // transmit_fsm Block
  transmit_fsm u_tx_fsm (
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .utrst            ( utrst           ),
    .thre             ( thre            ),
    .shift_cnt_eq     ( shift_cnt_eq    ),
    .data_cnt_eq      ( data_cnt_eq     ),
    .pen              ( pen             ),
    .transmit_edge    ( transmit_edge   ),
    .transmit_clk_clr ( transmit_clk_clr),
    .shift_en         ( shift_en        ),
    .shift_count_en   ( shift_count_en  ),
    .shift_count_clr  ( shift_count_clr ),
    .par              ( par             ),
    .not_op           ( not_op          ),
    .tsr_load         ( tsr_load        )
  );

  // tx_count_logic Block
  wire [3:0] tx_cnt;
  wire [3:0] data_cnt;
  wire [3:0] shift_cnt;
  wire [3:0] shift_cnt_i0;
  wire [3:0] shift_cnt_i1;
  wire [3:0] shift_cnt_i2;
  wire [3:0] shift_cnt_i3;

  counter #(.RESET_VALUE(0),
            .COUNTER_WIDTH(4)
  ) u_tx_counter (
    .clk     ( pclk           ),
    .reset_b ( presetn        ),
    .clear   ( shift_count_clr),
    .en      ( shift_count_en ),
    .count   ( tx_cnt         )
  );

  mux4to1 #(.LINE_WIDTH(4)
  ) u_data_cnt_mux (
    .sel ( wls     ),
    .in0 ( 4'b0110 ),
    .in1 ( 4'b0111 ),
    .in2 ( 4'b1000 ),
    .in3 ( 4'b1001 ),
    .out ( data_cnt)
  );

  assign shift_cnt_i0 = data_cnt + 1;
  assign shift_cnt_i1 = data_cnt + 2;
  assign shift_cnt_i2 = data_cnt + 2;
  assign shift_cnt_i3 = data_cnt + 3;

  mux4to1 #(.LINE_WIDTH(4)
  ) u_shift_cnt_mux (
    .sel ( {pen, stb}    ),
    .in0 ( shift_cnt_i0 ),
    .in1 ( shift_cnt_i1 ),
    .in2 ( shift_cnt_i2 ),
    .in3 ( shift_cnt_i3 ),
    .out ( shift_cnt    )
  );

  assign data_cnt_eq = (tx_cnt == data_cnt);
  assign shift_cnt_eq = (tx_cnt == shift_cnt);

  // parity_generator Block
  wire [7:0] data;
  wire odd_parity;
  wire even_parity;
  wire parity_gen;
  wire parity_d;

  mux4to1 #(.LINE_WIDTH(8)
  ) u_data_len_mux (
    .sel ( wls          ),
    .in0 ( {3'b0, tx_data[4:0]} ),
    .in1 ( {2'b0, tx_data[5:0]} ),
    .in2 ( {1'b0, tx_data[6:0]} ),
    .in3 ( tx_data[7:0]        ),
    .out ( data                )
  );

  assign odd_parity = ^{data, 1'b1};
  assign even_parity = ^{data, 1'b0};

  mux4to1 #(.LINE_WIDTH(1)
  ) u_par_type_mux (
    .sel ( {sp, eps}    ),
    .in0 ( odd_parity  ),
    .in1 ( even_parity ),
    .in2 ( 1'b1        ),
    .in3 ( 1'b0        ),
    .out ( parity_gen  )
  );

  assign parity_d = (tsr_load & pen) ? parity_gen : parity;

  dff #( .RESET_VALUE(1'b0),
         .FLOP_WIDTH(1)
  ) u_par_flop (
    .clk     ( pclk    ),
    .reset_b ( presetn ),
    .d       ( parity_d),
    .q       ( parity  )
  );

  // transmit_shift_register Block
  wire [10:0] shift_data;
  wire [10:0] rsr_data_d;
  wire [10:0] rsr_data;

  mux4to1 #(.LINE_WIDTH(11)
  ) u_tx_data_mux (
    .sel ( wls                          ),
    .in0 ( {3'b0, stb, 1'b1, tx_data[4:0], 1'b0} ),
    .in1 ( {2'b0, stb, 1'b1, tx_data[5:0], 1'b0} ),
    .in2 ( {1'b0, stb, 1'b1, tx_data[6:0], 1'b0} ),
    .in3 ( {stb, 1'b1, tx_data[7:0], 1'b0}      ),
    .out ( shift_data                        )
  );

  assign rsr_data_d = tsr_load ? shift_data : (shift_en ? {1'b0, rsr_data[10:1]} : rsr_data);

  dff #( .RESET_VALUE(0),
         .FLOP_WIDTH(11)
  ) u_rsr_flop (
    .clk     ( pclk       ),
    .reset_b ( presetn    ),
    .d       ( rsr_data_d ),
    .q       ( rsr_data   )
  );

  assign uart_txd = (loop | not_op) ? 1'b1 : (par ? parity : rsr_data[0]);
  assign loop_txd = not_op ? 1'b1 : (par ? parity : rsr_data[0]);

endmodule
