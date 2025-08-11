module uart_receiver_shift_block (
  input pclk,             // UART clock
  input presetn,          // Active-low reset
  input receive_shift_en, // Enable shift register
  input voting_shift_en,
  input uart_rxd,         // Serial data input
  input error_check,
  input loop_txd,
  input loop,
  input [1:0] wls,
  input pen,
  
  output received_parity,
  output frame_error,     // Frame error flag
  output [7:0] rsr_data,
  output all_zero,
  output rx_data
);

  reg [1:0] shift_mode_voting_reg;
  reg serial_in;
  reg [2:0] rx_data_for_sample;

  // Set shift_mode_voting_reg based on voting_shift_en
  always @(*) begin
    shift_mode_voting_reg = voting_shift_en ? 2'b01 : 2'b00;
    serial_in = loop ? loop_txd : uart_rxd; // Choose between loop or UART RXD
  end

  // Voting shift register instance
  wire [2:0] rx_data_for_sample_int;
  universal_shift_reg #(
    .DATA_WIDTH(3)
  ) voting_shift_inst (
    .clk          (pclk),
    .rst          (presetn),
    .select       (shift_mode_voting_reg),
    .p_din        (10'b0),
    .s_left_din   (1'b0),
    .s_right_din  (serial_in),
    .p_dout       (rx_data_for_sample_int),
    .s_left_dout  (),
    .s_right_dout ()
  );

  assign rx_data = (rx_data_for_sample_int[0] & rx_data_for_sample_int[1]) | 
                   (rx_data_for_sample_int[1] & rx_data_for_sample_int[2]) | 
                   (rx_data_for_sample_int[0] & rx_data_for_sample_int[2]);

  // Receiver shift register instance
  wire [9:0] shift_reg_out;
  wire [1:0] shift_mode_rx_reg;

  
   assign shift_mode_rx_reg = receive_shift_en ? 2'b01 : 2'b00;
  

  universal_shift_reg #(
    .DATA_WIDTH(10)
  ) receiver_shift_inst (
    .clk          (pclk),
    .rst          (presetn),
    .select       (shift_mode_rx_reg),
    .p_din        (10'b0),
    .s_left_din   (1'b0),
    .s_right_din  (rx_data),
    .p_dout       (shift_reg_out),
    .s_left_dout  (),
    .s_right_dout ()
  );

  // Data with and without parity based on word length select (wls)
  reg [7:0] data_with_parity;
  reg [7:0] data_without_parity;

  always @(*) begin
    casez (wls)
      2'b00 : data_with_parity = {3'b0, shift_reg_out[7:3]};
      2'b01 : data_with_parity = {2'b0, shift_reg_out[7:2]};
      2'b10 : data_with_parity = {1'b0, shift_reg_out[7:1]};
      2'b11 : data_with_parity = {shift_reg_out[7:0]};
      default : data_with_parity = 8'bx;
    endcase
  end

  always @(*) begin
    casez (wls)
      2'b00 : data_without_parity = {3'b0, shift_reg_out[8:4]};
      2'b01 : data_without_parity = {2'b0, shift_reg_out[8:3]};
      2'b10 : data_without_parity = {1'b0, shift_reg_out[8:2]};
      2'b11 : data_without_parity = {shift_reg_out[8:1]};
      default : data_without_parity = 8'bx;
    endcase
  end

  // Output assignments
  assign rsr_data = pen ? data_with_parity : data_without_parity;
  assign received_parity = shift_reg_out[8];
  assign frame_error = (error_check & (~shift_reg_out[9]));
  assign all_zero = ~(|shift_reg_out);

endmodule
