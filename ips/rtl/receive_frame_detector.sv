module receive_frame_detector (
  input  logic pclk,
  input  logic presetn,
  input  logic receive_frame_counter_en,
  input  logic receive_frame_counter_clear,
                     
  output logic receive_done
); 

  logic [3:0] receive_cycle_count;

  counter_en #( 
   .COUNTER_WIDTH (4)
) u_frame_counter (

  .clk           ( pclk                       ),
  .reset_b       ( presetn                    ),
  .counter_clear ( receive_frame_counter_clear),
  .en            ( receive_frame_counter_en   ),
  .count         ( receive_cycle_count        )
  );

  assign receive_done = (receive_cycle_count == 4'd10);

endmodule