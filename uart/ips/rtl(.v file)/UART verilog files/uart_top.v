module uart_top (
  input pclk,
  input presetn,
  input psel,
  input penable,
  input pwrite,
  input [31:0] paddr,
  input [31:0] pwdata,

  input uart_rxd,

  output pready,
  output [31:0] prdata,
  output sl,
 

  output uart_txd,
  output uart_intpt
);

  assign sl = 1'b0;

  wire [7:0] rsr_data;
  
  wire thr_wr_en;      
  wire tsr_load;      
  wire rbr_rd_en;      
  
  wire fifoen;
  wire txclr;
  wire rxclr;
  wire [1:0] rxfiftl;
  
  wire [7:0] tx_data;
  wire [10:0] rbr;
  wire tx_fifo_full;
  wire rx_fifo_full;
  wire tx_fifo_empty;
  wire rx_fifo_empty;
  
  wire bi;    
  wire below_level;
  wire frame_error;
  wire parity_error;
  wire receive_done;
  wire rbrf;
  wire uart_break;


  // Buffers module instance
  buffers u_buffers (
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .rsr_data      ( rsr_data      ),
    .pwdata        ( pwdata        ),
    .thr_wr_en     ( thr_wr_en     ),
    .receive_done  ( receive_done  ),
    .tsr_load      ( tsr_load      ),
    .rbr_rd_en     ( rbr_rd_en     ),
    .frame_error   ( frame_error   ),
    .parity_error  ( parity_error  ),
    .uart_break    ( uart_break    ),
    .fifoen        ( fifoen        ),
    .txclr         ( txclr         ),
    .rxclr         ( rxclr         ),
    .rxfiftl       ( rxfiftl       ),
    .dr            ( dr            ),
    .tx_data       ( tx_data       ),
    .rbr           ( rbr           ),
    .tx_fifo_full  ( tx_fifo_full  ),
    .rx_fifo_full  ( rx_fifo_full  ),
    .tx_fifo_empty ( tx_fifo_empty ),
    .rx_fifo_empty ( rx_fifo_empty ),
    .below_level   ( below_level   ),
    .rbrf          ( rbrf          )
  );

  // UART Receiver Top Module instance
  wire urrst;
  wire sample_edge;
  wire loop_txd;
  wire loop;
  wire [1:0] wls;
  wire pen;
  wire eps;
  wire sp;
  
  wire error_check;
  wire voting_edge;

  uart_receiver_top u_uart_receive_top (
    .pclk            ( pclk         ),
    .presetn         ( presetn      ),
    .utrrst          ( urrst        ),
    .sample_edge     ( sample_edge  ),
    .voting_edge     ( voting_edge  ),
    .uart_rxd        ( uart_rxd     ),
    .loop_txd        ( loop_txd     ),
    .loop            ( loop         ),
    .wls             ( wls          ),
    .pen             ( pen          ),
    .eps             ( eps          ),
    .sp              ( sp           ),
    .rsr_data        ( rsr_data     ),
    .frame_error     ( frame_error  ),
    .parity_error    ( parity_error ),
    .error_check     ( error_check  ),
    .receive_load_en ( receive_done ),
    .uart_break      ( uart_break   )
  );

  // UART Transmitter Module instance
  wire utrst;
  wire thre;
  wire stb;
  wire transmit_edge;
  wire transmit_clk_clr;
  wire shift_cnt_eq;

  uart_transmitter u_uart_transmitter (
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .utrst            ( utrst           ),
    .thre             ( thre            ),
    .pen              ( pen             ),
    .eps              ( eps             ),
    .sp               ( sp              ),
    .stb              ( stb             ),
    .loop             ( loop            ),
    .transmit_edge    ( transmit_edge   ),
    .tx_data          ( tx_data         ),
    .wls              ( wls             ),
    .transmit_clk_clr ( transmit_clk_clr),
    .tsr_load         ( tsr_load        ),
    .shift_cnt_eq     ( shift_cnt_eq    ),
    .loop_txd         ( loop_txd        ),
    .uart_txd         ( uart_txd        )
  );

  // Clock Generation Module instance
  wire [7:0] dlh;
  wire [7:0] dll;

  clock_gen u_clock_gen (
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .sample_clk_clr   ( ~urrst  ),
    .transmit_clk_clr ( transmit_clk_clr),
    .dlh              ( dlh             ),
    .dll              ( dll             ),
    .sample_edge      ( sample_edge     ),
    .voting_edge      ( voting_edge     ),
    .transmit_edge    ( transmit_edge   )
  );

  // UART Interrupt Generation Module instance
  uart_intpt_gen u_uart_intpt_gen (
    .thre        ( thre        ),
    .etbei       ( etbei       ),
    .pe          ( pe          ),
    .elsi        ( elsi        ),
    .bi          ( bi          ),
    .fe          ( fe          ),
    .dr          ( dr          ),
    .erbi        ( erbi        ),
    .below_level ( below_level ),
    .uart_intpt  ( uart_intpt  )
  );

  // APB Interface Module instance
  apb_intfc u_apb_intfc (
    .pclk          ( pclk          ),
    .presetn       ( presetn       ),
    .psel          ( psel          ),
    .pwrite        ( pwrite        ),
    .penable       ( penable       ),
    .paddr         ( paddr         ),
    .pwdata        ( pwdata        ),
    .rbr           ( rbr           ),
    .parity_error  ( parity_error  ),
    .frame_error   ( frame_error   ),
    .error_check   ( error_check   ),
    .shift_cnt_eq  ( shift_cnt_eq  ),
    .tx_fifo_empty ( tx_fifo_empty ),
    .rx_fifo_empty ( rx_fifo_empty ),
    .tsr_load      ( tsr_load      ),
    .receive_done  ( receive_done  ),
    .uart_break    ( uart_break    ),
    .rx_fifo_full  ( rx_fifo_full  ),
    .rbrf          ( rbrf          ),
    .uart_intpt    ( uart_intpt    ),
    .loop          ( loop          ),
    .thr_wr_en     ( thr_wr_en     ),
    .rbr_rd_en     ( rbr_rd_en     ),
    .rxfiftl       ( rxfiftl       ),
    .txclr         ( txclr         ),
    .rxclr         ( rxclr         ),
    .fifoen        ( fifoen        ),
    .sp            ( sp            ),
    .eps           ( eps           ),
    .pen           ( pen           ),
    .stb           ( stb           ),
    .wls           ( wls           ),
    .dll           ( dll           ),
    .dlh           ( dlh           ),
    .urrst         ( urrst         ),
    .utrst         ( utrst         ),
    .thre          ( thre          ),
    .etbei         ( etbei         ),
    .pe            ( pe            ),
    .elsi          ( elsi          ),
    .bi            ( bi            ),
    .fe            ( fe            ),
    .dr            ( dr            ),
    .erbi          ( erbi          ),
    .pready        ( pready        ),
    .prdata        ( prdata        )
  ); 

endmodule
