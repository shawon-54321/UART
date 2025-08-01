module uart_top (
  input  logic        pclk,
  input  logic        presetn,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,

  input  logic        uart_rxd,

  output logic        pready,
  output logic [31:0] prdata,

  output logic        uart_tx,
  output logic        uart_intpt
);

    logic [7:0]  rsr_data;
                 
    logic        thr_wr_en;      
    logic        rx_done;        
    logic        tsr_load;      
    logic        wbr_rd_en;      
                 
    logic        fifoen;
    logic        txclr
    logic        rxclr;
    logic [1:0]  rxfiftl;
                 
                 
    logic [7:0]  tx_data;
    logic [7:0]  rbr;
    logic        tx_fifo_full;
    logic        rx_fifo_full;
    logic        tx_fifo_empty;
    logic        rx_fifo_empty;
                 
    logic        below_level;



  buffers u_buffers (
    .pclk          ( pclk         ),
    .presetn       ( presetn      ),
    
    .rsr_data      ( rsr_data     ),
    .wdata         ( wdata        ),
    
    .thr_wr_en     ( thr_wr_en    ),
    .rx_done       ( rx_done      ),
    .tsr_load      ( tsr_load     ),
    .wbr_rd_en     ( wbr_rd_en    ),
    
    .fifoen        ( fifoen       ),
    .txclr         ( txclr        ),
    .rxclr         ( rxclr        ),
    .rxfiftl       ( rxfiftl      ),
    
    
    .tx_data       ( tx_data      ),
    .rbr           ( rbr          ),
    .tx_fifo_full  ( tx_fifo_full ),
    .rx_fifo_full  ( rx_fifo_full ),
    .tx_fifo_empty ( tx_fifo_empty),
    .rx_fifo_empty ( rx_fifo_empty),
    
    .below_level   ( below_level  )
  );


    logic       urrst;
    logic       sample_edge;
    logic       receive_done;
    logic       loop_txd;
    logic       loop;
    logic [1:0] wls;
    logic       pen;
    logic       eps;
    logic       sp;
                
    logic       frame_error;
    logic       parity_error;
    logic       error_check;


  uart_receiver_top u_uart_receive_top (
    .pckl         ( pckl        ),
    .presetn      ( presetn     ),
    .utrrst       ( urrst       ),
    .sample_edge  ( sample_edge ),
    .receive_done ( receive_done),
    .uart_rxd     ( uart_rxd    ),
    .loop_txd     ( loop_txd    ),
    .loop         ( loop        ),
    .wls          ( wls         ),
    .pen          ( pen         ),
    .eps          ( eps         ),
    .sp           ( sp          ),
    
    .rsr_data     ( rsr_data    ),
    .frame_error  ( frame_error ),
    .parity_error ( parity_error),
    .error_check  ( error_check )
  );


    logic       utrst;
    logic       thre;
    logic       stb;
    logic       transmit_edge;
    logic       transmit_clk_clr;
    logic       shift_cnt_eq;


  uart_transmitter u_uart_transmitter (
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .utrst            ( utrst           ),
    .thre             ( thre            ),
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


    logic       sample_clk_clr;
    logic [7:0] dlh;
    logic [7:0] dll;

  clock_gen u_clock_gen(
    .pclk             ( pclk            ),
    .presetn          ( presetn         ),
    .sample_clk_clr   ( sample_clk_clr  ),
    .transmit_clk_clr ( transmit_clk_clr),
    .dlh              ( dlh             ),
    .dll              ( dll             ),
    
    .sample_edge      ( sample_edge     ),
    .transmit_edge    ( transmit_edge   )
  );



  apb_intfc u_apb_intfc (
    .pclk          ( pclk         ),
    .presetn       ( presetn      ),
    .psel          ( psel         ),
    .pwrite        ( pwrite       ),
    .penable       ( penable      ),
    .paddr         ( paddr        ),
    .pwdata        ( pwdata       ),
    
    .rbr           ( rbr          ),
    .parity_error  ( parity_error ),
    .frame_error   ( frame_error  ),
    .error_check   ( error_check  ),
    .shift_cnt_eq  ( shift_cnt_eq ),
    .rx_fifo_empty ( rx_fifo_empty),
    .tsr_load      ( tsr_load     ),
    
    .loop          ( loop         ),
    .thr_wr_en     ( thr_wr_en    ),
    .wbr_rd_en     ( wbr_rd_en    ),
    .rxfiftl       ( rxfiftl      ),
    .txclr         ( txclr        ),
    .rxclr         ( rxclr        ),
    .fifoen        ( fifoen       ),
    .sp            ( sp           ),
    .esp           ( esp          ),
    .pen           ( pen          ),
    .stb           ( stb          ),
    .wls           ( wls          ),
    .dll           ( dll          ),
    .dlh           ( dlh          ),
    .urrst         ( urrst        ),
    .utrst         ( utrst        ),
    .uart_intpt    ( uart_intpt   ),
    
    .pready        ( pready       ),
    .prdata        ( prdata       )
  ); 

endmodule