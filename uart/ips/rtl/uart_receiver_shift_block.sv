module uart_receiver_shift_block (
  input  logic       pclk,             // UART clock
  input  logic       presetn,          // Active-low reset
  input  logic       receive_shift_en, // Enable shift register
  input  logic       uart_rxd,        // Serial data input
  input  logic       error_check,
  input  logic       loop_txd,
  input  logic       loop,
  input  logic [1:0] wls,
  input  logic       pen,
  
  output logic       received_parity,
  output logic       frame_error,       // Frame error flag
  output logic [7:0] rsr_data
);

  logic [9:0] shift_reg_out;
  logic       stop_bit_value;
  logic [1:0] shift_mode;
  logic       serial_in;

  assign shift_mode = receive_shift_en ? 2'b01 : 2'b00;
  assign serial_in  = loop ? loop_txd : uart_rxd; 

  universal_shift_reg #(
    .DATA_WIDTH(10)
  ) receiver_shift_inst (
    .clk          ( pckl         ),
    .rst          ( presetn      ),      
    .select       ( shift_mode   ),
    .p_din        ( 10'b0           ),
    .s_left_din   ( 1'b0           ),
    .s_right_din  ( serial_in    ),
    .p_dout       ( shift_reg_out),
    .s_left_dout  (              ), 
    .s_right_dout (              )
  );

  logic [7:0] data_with_parity;
  logic [7:0] data_without_parity;

  always @ (*) begin
    casez (wls)
      2'b00   : data_with_parity = {3'b0, shift_reg_out[7:3]};
      2'b01   : data_with_parity = {2'b0, shift_reg_out[7:2]};
      2'b10   : data_with_parity = {1'b0, shift_reg_out[7:1]};
      2'b11   : data_with_parity = {shift_reg_out[7:0]};
      default : data_with_parity = 8'bx;
    endcase
  end

  always @ (*) begin
    casez (wls)
      2'b00   : data_without_parity = {3'b0, shift_reg_out[8:4]};
      2'b01   : data_without_parity = {2'b0, shift_reg_out[8:3]};
      2'b10   : data_without_parity = {1'b0, shift_reg_out[8:2]};
      2'b11   : data_without_parity = {shift_reg_out[8:1]};
      default : data_without_parity = 8'bx;
    endcase
  end

  assign rsr_data        = pen ? data_with_parity : data_without_parity;
  assign received_parity = shift_reg_out[8];
  assign frame_error     = (error_check  & (~ shift_reg_out[0]));

endmodule