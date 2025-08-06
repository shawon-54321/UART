module buffers(
  input  logic        pclk,
  input  logic        presetn,
                      
  input  logic [7:0]  rsr_data,
  input  logic [31:0] pwdata,     
                      
  input  logic        thr_wr_en,     
  input  logic        receive_done,      
  input  logic        tsr_load,       
  input  logic        rbr_rd_en,      
  input  logic        frame_error,
  input  logic        parity_error,
  input  logic        uart_break,
                      
  input  logic        fifoen,
  input  logic        txclr,
  input  logic        rxclr,
  input  logic [1:0]  rxfiftl,
                      
                      
  output logic [7:0]  tx_data,
  output logic [10:0] rbr,
  output logic        tx_fifo_full,
  output logic        rx_fifo_full,
  output logic        tx_fifo_empty,
  output logic        rx_fifo_empty,
  output logic        rbrf,
                      
  output logic        below_level    
);

    logic [7:0]  fifo_tx_data;
    logic [10:0] fifo_rbr;
    logic [7:0]  tx_fifo_data_in;
    logic [7:0]  thr_data_in;                
    logic [10:0] rx_fifo_data_in;                            
    logic [7:0]  thr_data;                                  
    logic [3:0]  rx_data_cnt;
    logic [3:0]  tx_data_cnt;                
    logic [3:0]  data_level;                
    logic        fifo_tx_full;
    logic        fifo_tx_empty;
    logic wr_en_tx_fifo;
    logic rd_en_tx_fifo; 
    logic wr_en_rx_fifo;
    logic rd_en_rx_fifo;

    assign wr_en_tx_fifo = thr_wr_en & fifoen;
    assign rd_en_tx_fifo = tsr_load & fifoen;
    assign wr_en_rx_fifo = receive_done & fifoen;
    assign rd_en_rx_fifo = rbr_rd_en & fifoen;

    

  
  
  // TX side
  fifo_sync  #(
  
    .FIFO_DEPTH(16),
    .DATA_WIDTH(8),
    .FIFO_DEPTH_LOG(4)
    
  ) u_tx_fifo (  
    .clk        ( pclk            ),
    .rst_n      ( presetn         ),
    .wr_en      ( wr_en_tx_fifo   ),                
    .rd_en      ( rd_en_tx_fifo   ),                
    .data_in    ( tx_fifo_data_in ),
    .clear      ( txclr           ),

    .data_out   ( fifo_tx_data    ),
    .empty      ( fifo_tx_empty   ),
    .data_count ( tx_data_cnt     ),
    .full       ( fifo_tx_full    )

  );
  


dff #(
    .FLOP_WIDTH  ( 8              ),
    .RESET_VALUE ( 8'b0000000000  )
  )u_thr(  
    .clk         ( pclk           ),
    .reset_b     ( presetn        ),
    .d           ( thr_data_in    ),
    .q           ( thr_data       )
  );   
 
  
  assign thr_data_in[7:0]     = ~fifoen & thr_wr_en ? pwdata[7:0] : thr_data;
  assign tx_fifo_data_in[7:0] = fifoen ? pwdata[7:0] : 8'b0; 


  assign tx_fifo_full         = fifo_tx_full;
  assign tx_fifo_empty        = fifo_tx_empty;
  
  assign tx_data[7:0]         = fifoen ? fifo_tx_data[7:0] : thr_data[7:0];
  
  
  
  // RX side-----------------------------------------------------------------
  
   logic [10:0] in_rbr;
    

  

  assign in_rbr[10:0]          = fifoen ? 11'b0 : {3'b000,rsr_data[7:0]};
  assign rx_fifo_data_in[10:0] = fifoen ? {uart_break,frame_error,parity_error,rsr_data[7:0]} : 11'b0; 

  fifo_sync  #(
    .FIFO_DEPTH(16),
    .DATA_WIDTH(11),
    .FIFO_DEPTH_LOG(4)
    
  ) u_rx_fifo (  
    .clk        ( pclk               ),
    .rst_n      ( presetn            ),
    .wr_en      ( wr_en_rx_fifo      ),                
    .rd_en      ( rd_en_rx_fifo      ),                
    .data_in    ( rx_fifo_data_in    ),
    .clear      ( rxclr              ),
    
    .data_out   ( fifo_rbr           ),
    .empty      ( fifo_rx_empty      ),
    .data_count ( rx_data_cnt        ),
    .full       ( fifo_rx_full       )
  );
 
 
  logic [10:0] d_just_rbr;
  logic [10:0] just_rbr;
  assign d_just_rbr[10:0] = (receive_done & ~rbrf & ~fifoen) ? in_rbr[10:0] : just_rbr[10:0];

  
  dff #(
    .FLOP_WIDTH ( 11    ),
    .RESET_VALUE( 11'b00000000000 )
  )u_rbr(  
    .clk     ( pclk       ),
    .reset_b ( presetn    ),
    .d       ( d_just_rbr ),
    .q       ( just_rbr   )
  );   
  
  assign rx_fifo_full  = fifo_rx_full;
  assign rx_fifo_empty = fifo_rx_empty;
  
  logic d_rbrf;
  
  assign d_rbrf = ( receive_done | rbrf ) & (~rbr_rd_en); 
  
  dff #(
    .FLOP_WIDTH ( 1    ),
    .RESET_VALUE( 0 )
  )u_rbrf(  
    .clk     ( pclk     ),
    .reset_b ( presetn  ),
    .d       ( d_rbrf   ),
    .q       ( rbrf     )
  );   

  assign rbr[10:0] = fifoen ? fifo_rbr[10:0] : just_rbr[10:0];
  
  // Level Detection
  always @(*) begin
    casez(rxfiftl)
      2'b00   : data_level[3:0] = 4'b0001;
      2'b01   : data_level[3:0] = 4'b0100;
      2'b10   : data_level[3:0] = 4'b1000;
      2'b11   : data_level[3:0] = 4'b1110;
      default : data_level[3:0] = 'bx; 
    endcase
  end
  
  assign below_level =  (rx_data_cnt[3:0] < data_level[3:0]);
  

endmodule