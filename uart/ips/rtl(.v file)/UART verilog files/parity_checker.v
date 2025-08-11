module parity_checker (
  input  [7:0] rsr_data,
  input        received_parity,
  input        pen,
  input        eps,
  input        sp,
  
  output       parity_error
);

  reg computed_parity;
  reg expected_parity;
  reg parity_match;

  always @(*) begin
    computed_parity = ^rsr_data;
    expected_parity = sp ? ~eps : (eps ? computed_parity : ~computed_parity);
    parity_match = (received_parity == expected_parity);
  end
  
  assign parity_error = pen & (~parity_match);

endmodule
