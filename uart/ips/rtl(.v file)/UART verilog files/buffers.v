module buffers(
  input        pclk,
  input        presetn,
  
  input [7:0]  rsr_data,
  input [31:0] pwdata,
  
  input        thr_wr_en,
  input        receive_done,
  input        tsr_load,
  input        rbr_rd_en,
  input        frame_error,
  input        parity_error,
  input        uart_break,
  
  input        fifoen,
  input        txclr,
  input        rxclr,
  input [1:0]  rxfiftl,
  input        dr,
  
  output [7:0] tx_data,
  output [10:0] rbr,
  output       tx_fifo_full,
  output       rx_fifo_full,
  output       tx_fifo_empty,
  output       rx_fifo_empty,
  output  reg     rbrf,
  
  output       below_level
);

  wire [7:0]  fifo_tx_data;
  wire [10:0] fifo_rbr;
  wire [7:0]  tx_fifo_data_in;
  wire [7:0]  thr_data_in;
  wire [10:0] rx_fifo_data_in;
  reg [7:0]  thr_data;
  wire [3:0]  rx_data_cnt;
  wire [3:0]  tx_data_cnt;
  reg [3:0]  data_level;
  wire        fifo_tx_full;
  wire        fifo_tx_empty;
  
  wire        fifo_rx_full;
  wire        fifo_rx_empty;
  
  wire wr_en_tx_fifo;
  wire rd_en_tx_fifo; 
  wire wr_en_rx_fifo;
  wire rd_en_rx_fifo;

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
    .clk        ( pclk ),
    .rst_n      ( presetn ),
    .wr_en      ( wr_en_tx_fifo ),
    .rd_en      ( rd_en_tx_fifo ),
    .data_in    ( tx_fifo_data_in ),
    .clear      ( txclr ),
    .data_out   ( fifo_tx_data ),
    .empty      ( fifo_tx_empty ),
    .data_count ( tx_data_cnt ),
    .full       ( fifo_tx_full )
  );

  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      thr_data <= 8'b00000000;
    else
      thr_data <= thr_data_in;
  end
  
  assign thr_data_in[7:0] = ~fifoen & thr_wr_en ? pwdata[7:0] : thr_data;
  assign tx_fifo_data_in[7:0] = fifoen ? pwdata[7:0] : 8'b0;

  assign tx_fifo_full = fifo_tx_full;
  assign tx_fifo_empty = fifo_tx_empty;
  
  assign tx_data[7:0] = fifoen ? fifo_tx_data[7:0] : thr_data[7:0];

  // RX side
  wire [10:0] in_rbr;
  assign in_rbr[10:0] = fifoen ? 11'b0 : {3'b000, rsr_data[7:0]};
  assign rx_fifo_data_in[10:0] = fifoen ? {uart_break, frame_error, parity_error, rsr_data[7:0]} : 11'b0; 

  fifo_sync  #(
    .FIFO_DEPTH(16),
    .DATA_WIDTH(11),
    .FIFO_DEPTH_LOG(4)
  ) u_rx_fifo (
    .clk        ( pclk ),
    .rst_n      ( presetn ),
    .wr_en      ( wr_en_rx_fifo ),
    .rd_en      ( rd_en_rx_fifo ),
    .data_in    ( rx_fifo_data_in ),
    .clear      ( rxclr ),
    .data_out   ( fifo_rbr ),
    .empty      ( fifo_rx_empty ),
    .data_count ( rx_data_cnt ),
    .full       ( fifo_rx_full )
  );

  wire [10:0] d_just_rbr;
  reg [10:0] just_rbr;
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      just_rbr <= 11'b00000000000;
    else
      just_rbr <= d_just_rbr;
  end

  assign d_just_rbr[10:0] = (receive_done & ~rbrf & ~fifoen) ? in_rbr[10:0] : just_rbr[10:0];

  assign rx_fifo_full = fifo_rx_full;
  assign rx_fifo_empty = fifo_rx_empty;
  
  wire d_rbrf;
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      rbrf <= 0;
    else
      rbrf <= d_rbrf;
  end

  assign d_rbrf = (receive_done | rbrf) & (~rbr_rd_en); 

  assign rbr[10:0] = fifoen ? (dr ? fifo_rbr[10:0] : 11'b0) : just_rbr[10:0];

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
  
  assign below_level = (rx_data_cnt[3:0] < data_level[3:0]);

endmodule
