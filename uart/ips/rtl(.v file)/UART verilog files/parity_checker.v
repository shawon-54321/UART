module parity_checker (
  input  [7:0] rsr_data,
  input        received_parity,
  input        pen,
  input        eps,
  input        sp,
  
  output       parity_error
);

  wire computed_parity;
  wire expected_parity;
  wire parity_match;

  assign computed_parity = ^ rsr_data;
  assign expected_parity = sp ? ~ eps : (eps ? computed_parity : ~ computed_parity);
  assign parity_match    = (received_parity == expected_parity);
  assign parity_error    = pen & (~parity_match);
  
  assign parity_error = pen & (~parity_match);

endmodule
