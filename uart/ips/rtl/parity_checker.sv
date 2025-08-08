module parity_checker (
  input  logic [7:0] rsr_data,
  input  logic       received_parity,
  input  logic       pen,
  input  logic       eps,
  input  logic       sp,
                      
  output logic       parity_error
);


  logic computed_parity;
  logic expected_parity;
  logic parity_match;

  assign computed_parity = ^ rsr_data;
  assign expected_parity = sp ? ~ eps : (eps ? computed_parity : ~ computed_parity);
  assign parity_match    = (received_parity == expected_parity);
  assign parity_error    = pen & (~parity_match);

endmodule