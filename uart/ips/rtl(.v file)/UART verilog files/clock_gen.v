module clock_gen(
  input        pclk,
  input        presetn,
  input        sample_clk_clr,
  input        transmit_clk_clr,
  input [7:0]  dlh,
  input [7:0]  dll,
  
  output       voting_edge,
  output       sample_edge,
  output       transmit_edge
);

  wire        comp_out_tx;
  wire        comp_out_rx;
  
  reg        bclk_tx;
  reg        bclk_rx;
  
  reg [3:0]  sample_edge_cnt;
  reg [3:0]  transmit_edge_cnt;
  
  wire [14:0] comp_value;
  
  reg [14:0] counter_rx;
  reg [14:0] counter_tx;
  
  wire [4:0]  d_edge_detection;
  wire [4:0]  q_edge_detection;

  // Final edge detection flops
  dff #(
      .RESET_VALUE(1'b0),
      .FLOP_WIDTH(5)
  ) u_flops (
   .clk     ( pclk ),
   .reset_b ( presetn ),
   .d       ( d_edge_detection ),
   .q       ( q_edge_detection )
  );

  always @(posedge pclk or negedge presetn) begin
    if (~presetn) begin
      bclk_tx           <= 1'b0;
      bclk_rx           <= 1'b0;
      
      sample_edge_cnt   <= 4'b0;
      transmit_edge_cnt <= 4'b0;
      
      counter_rx        <= 16'b1;
      counter_tx        <= 16'b1;
    end else begin
      bclk_tx           <= comp_out_tx ? ~bclk_tx : bclk_tx;
      bclk_rx           <= comp_out_rx ? ~bclk_rx : bclk_rx;

      sample_edge_cnt   <= (bclk_rx & comp_out_rx) + sample_edge_cnt;
      transmit_edge_cnt <= (bclk_tx & comp_out_tx) + transmit_edge_cnt;

      counter_rx        <= (sample_clk_clr | comp_out_rx) ? 16'b1 : counter_rx + 1'b1;
      counter_tx        <= (transmit_clk_clr | comp_out_tx) ? 16'b1 : counter_tx + 1'b1;
    end
  end

  assign comp_out_rx = counter_rx == comp_value;
  assign comp_out_tx = counter_tx == comp_value;
  assign comp_value  = {dlh[7:0], dll[7:1]};
  
  assign d_edge_detection[0] = (sample_edge_cnt == 4'b0110);  // 6th cycle
  assign d_edge_detection[1] = (sample_edge_cnt == 4'b0111);  // 7th cycle
  assign d_edge_detection[2] = (sample_edge_cnt == 4'b1000);  // 8th cycle
  assign d_edge_detection[3] = (transmit_edge_cnt == 4'b1111);  // transmit in the middle
  assign d_edge_detection[4] = (sample_edge_cnt == 4'b1001);  // 9th cycle for shift register

  // Output
  assign voting_edge    = ((~q_edge_detection[0] & d_edge_detection[0]) | 
                           (~q_edge_detection[1] & d_edge_detection[1]) | 
                           (~q_edge_detection[2] & d_edge_detection[2])) & ~sample_clk_clr;
  assign transmit_edge  = ~q_edge_detection[3] & d_edge_detection[3] & ~transmit_clk_clr;
  assign sample_edge    = ~q_edge_detection[4] & d_edge_detection[4] & ~sample_clk_clr;

endmodule
