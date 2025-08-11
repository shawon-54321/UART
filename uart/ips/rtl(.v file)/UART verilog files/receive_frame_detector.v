module receive_frame_detector (
  input  pclk,
  input  presetn,
  input  receive_frame_counter_en,
  input  receive_frame_counter_clear,
  input  sample_edge,
  input  [1:0] wls,
  input  pen,
                     
  output receive_done
); 

  wire [3:0] receive_cycle_count;

  counter_en #( 
   .COUNTER_WIDTH (4)
  ) u_frame_counter (

  .clk           ( pclk                       ),
  .reset_b       ( presetn                    ),
  .counter_clear ( receive_frame_counter_clear),
  .en            ( receive_frame_counter_en   ),
  .count         ( receive_cycle_count        )
  );

  reg [3:0] rx_data_width;

  always @ (*) begin
    casez (wls)
      2'b00   : rx_data_width = pen ? 4'd6 : 4'd5;
      2'b01   : rx_data_width = pen ? 4'd7 : 4'd6;
      2'b10   : rx_data_width = pen ? 4'd8 : 4'd7;
      2'b11   : rx_data_width = pen ? 4'd9 : 4'd8;
      default : rx_data_width = 4'bx;
    endcase
  end

  assign receive_done = (receive_cycle_count == rx_data_width) & sample_edge;

endmodule
