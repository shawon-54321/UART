module transmit_fsm (
  input pclk,
  input presetn,
  input utrst,
  input thre,
  input shift_cnt_eq,
  input data_cnt_eq,
  input pen,
  input transmit_edge,
  output transmit_clk_clr,
  output shift_en,
  output shift_count_en,
  output shift_count_clr,
  output par,
  output not_op,
  output tsr_load
);

  parameter STATE_WIDTH = 2;

  reg [STATE_WIDTH-1:0] pstate, nstate;
  
  // State encoding
  localparam IDLE      = 2'b00,
             START     = 2'b01,
             TRANSMIT  = 2'b10,
             PARITY    = 2'b11;

  // Next state logic
  always @(*) begin
    case (pstate)
      IDLE     : nstate = (utrst && ~thre) ? START : IDLE;
      START    : nstate = utrst ? ((transmit_edge) ? TRANSMIT : START) : IDLE;
      TRANSMIT : nstate = utrst ? ((shift_cnt_eq) ? (thre ? (transmit_edge ? IDLE : TRANSMIT) : START) :
                        (data_cnt_eq && transmit_edge && pen) ? PARITY : TRANSMIT) : IDLE;
      PARITY   : nstate = utrst ? (transmit_edge ? TRANSMIT : PARITY) : IDLE;
      default  : nstate = 2'bxx;
    endcase
  end

  // Output logic
  assign transmit_clk_clr = (pstate == IDLE);
  assign shift_en         = (pstate == TRANSMIT && transmit_edge && ~(data_cnt_eq || shift_cnt_eq)) || 
                            (pstate == PARITY && transmit_edge);
  assign shift_count_en   = (pstate == START && transmit_edge) || 
                            (pstate == TRANSMIT && transmit_edge && ~shift_cnt_eq) || 
                            (pstate == PARITY && transmit_edge);
  assign par              = (pstate == PARITY);
  assign not_op           = (pstate == IDLE) || (pstate == START);
  assign shift_count_clr  = (pstate == TRANSMIT) && (thre ? (shift_cnt_eq && transmit_edge) : shift_cnt_eq);
  assign tsr_load         = (pstate == START && transmit_edge);

  // D flip-flop for state register
  always @(posedge pclk or negedge presetn) begin
    if (~presetn)
      pstate <= IDLE;
    else
      pstate <= nstate;
  end

endmodule
