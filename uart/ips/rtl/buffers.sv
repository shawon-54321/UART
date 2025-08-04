module buffers(
  input logic pclk,
  inout logic presetn,
  
  input logic [7:0] rsr_data,
  input logic [31:0] pwdata,     // pwdata
  
  input logic thr_wr_en,      // write enable for tx fifo/thr
  input logic receive_done,        // write enable for rx fifo/rhr
  input logic tsr_load,       // read enable for tx_fifo/thr
  input logic rbr_rd_en,      // read enable for rx_fifo/rhr
  input logic frame_error,
  input logic parity_error,
  
  input logic fifoen,
  input logic txclr,
  input logic rxclr,
  input logic [1:0] rxfiftl,
  
  
  output logic [7:0] tx_data,
  output logic [9:0] rbr,
  output logic tx_fifo_full,
  output logic rx_fifo_full,
  output logic tx_fifo_empty,
  output logic rx_fifo_empty,
  
  output logic below_level
  
    
);

  logic [7:0] fifo_tx_data;
  logic [9:0] fifo_rbr;
  logic [7:0] tx_fifo_data_in;
  logic [7:0] thr_data_in;
  
  logic [9:0] rx_fifo_data_in;
  

  logic [7:0] thr_data;

  
  logic [3:0] rx_data_cnt;
  logic [3:0] tx_data_cnt;
  logic thr_cnt;
  
  logic [3:0] data_level;
  
  logic fifo_tx_full;
  logic fifo_tx_empty;
  logic thr_empty;
  logic thr_full;

  
  
  // TX side
  fifo_sync  #(
  
    .FIFO_DEPTH(16),
    .DATA_WIDTH(8),
    .FIFO_DEPTH_LOG(4)
    
  ) u_tx_fifo (
    
    .clk        ( pclk          ),
    .rst_n      ( presetn       ),
    .wr_en      ( thr_wr_en & fifoen ),
    .rd_en      ( tsr_load & fifoen  ),
    .data_in    ( tx_fifo_data_in    ),
    .clear      ( txclr         ),

    .data_out   ( fifo_tx_data  ),
    .empty      ( fifo_tx_empty ),
    .data_count ( tx_data_cnt   ),
    .full       ( fifo_tx_full  )

  );
  
//  fifo_sync  #(
//  
//    .FIFO_DEPTH(1),
//    .DATA_WIDTH(8),
//    .FIFO_DEPTH_LOG(1)
//    
//  ) u_thr (
//    
//    .clk        ( pclk          ),
//    .rst_n      ( presetn       ),
//    .wr_en      ( thr_wr_en & ~fifoen    ),
//    .rd_en      ( tsr_load  & ~fifoen    ),
//    .data_in    ( thr_data_in   ),
//    .clear      ( txclr         ),

//    .data_out   ( thr_data  ),
//    .empty      ( thr_empty ),
//    .data_count ( thr_cnt   ),
//    .full       ( thr_full  )

//  );

dff #(
    .FLOP_WIDTH ( 10    ),
    .RESET_VALUE( 10'b0000000000 )
  )u_thr(  
    .clk     ( pclk     ),
    .reset_b ( presetn  ),
    .d       ( thr_data_in    ),
    .q       ( thr_data    )
  );   
  

  
//  always@(*) begin
//    casez(fifoen) 
//      1'b0 : thr_data_in = pwdata;
//      1'b1 : tx_fifo_data_in = pwdata;
//    endcase
//  end
  
  assign thr_data_in[7:0] = fifoen & thr_wr_en ? pwdata[7:0] : thr_data;
  assign tx_fifo_data_in[7:0] = fifoen ? pwdata[7:0] : 8'b0; 


  assign tx_fifo_full = thr_full | fifo_tx_full;
  assign tx_fifo_empty = thr_empty | fifo_tx_empty;
  
  assign tx_data[7:0] = fifoen ? fifo_tx_data[7:0] : thr_data[7:0];
  
  
  
  // RX side-----------------------------------------------------------------
  
   logic [9:0] in_rbr;
    
 /* always@(*) begin
    casez(fifoen) 
      1'b0 : in_rbr[9:0] = {2'b00,rsr_data[7:0]};
      1'b1 : rx_fifo_data_in[9:0] = {frame_error,parity_error,rsr_data[7:0]};
    endcase
  end  
  */

  assign in_rbr[9:0] = fifoen ? 10'b0 : {2'b00,rsr_data[7:0]};
  assign rx_fifo_data_in[9:0] = fifoen ? {frame_error,parity_error,rsr_data[7:0]} : 10'b0; 

  fifo_sync  #(
    .FIFO_DEPTH(16),
    .DATA_WIDTH(10),
    .FIFO_DEPTH_LOG(4)
    
  ) u_rx_fifo (
    
    .clk        ( pclk          ),
    .rst_n      ( presetn       ),
    .wr_en      ( receive_done & fifoen      ),
    .rd_en      ( rbr_rd_en & fifoen    ),
    .data_in    ( rx_fifo_data_in      ),
    .clear      ( rxclr         ),
    
    .data_out   ( fifo_rbr      ),
    .empty      ( fifo_rx_empty ),
    .data_count ( rx_data_cnt   ),
    .full       ( fifo_rx_full  )

  );
 
 /* 
  fifo_sync  #(
    .FIFO_DEPTH(1),
    .DATA_WIDTH(8),
    .FIFO_DEPTH_LOG(1)
  ) u_rhr (
    
    .clk        ( pclk          ),
    .rst_n      ( presetn       ),
    .wr_en      ( receive_done & ~fifoen   ),
    .rd_en      ( rbr_rd_en & ~fifoen ),
    .data_in    ( rhr_data_in      ),
    .clear      ( rxclr         ),
    
    .data_out   ( rhr      ),
    .empty      ( rhr_empty ),
    .data_count ( rhr_d_cnt   ),
    .full       ( rhr_full  )

  );
  */
  logic [9:0] d_just_rbr;
  logic [9:0] just_rbr;
  assign d_just_rbr[9:0] = (receive_done & ~fifoen) ? in_rbr[9:0] : just_rbr[9:0];

  
  dff #(
    .FLOP_WIDTH ( 10    ),
    .RESET_VALUE( 10'b0000000000 )
  )u_rbr(  
    .clk     ( pclk     ),
    .reset_b ( presetn  ),
    .d       ( d_just_rbr    ),
    .q       ( just_rbr    )
  );   
  
  assign rx_fifo_full =  fifo_rx_full;
  assign rx_fifo_empty =  fifo_rx_empty;
  

  assign rbr[9:0] = fifoen ? fifo_rbr[9:0] : just_rbr[9:0];
  
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
  
  assign below_level = fifoen & (rx_data_cnt[3:0] < data_level[3:0]);
  

endmodule