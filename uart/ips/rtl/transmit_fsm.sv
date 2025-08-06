module transmit_fsm (
  input  logic pclk,
	input  logic presetn,
  input  logic utrst,
  input  logic thre,
  input  logic shift_cnt_eq,
  input  logic data_cnt_eq,
  input  logic pen,
  input  logic transmit_edge,
  output logic transmit_clk_clr,
  output logic shift_en,
  output logic shift_count_en,
  output logic shift_count_clr,
  output logic par,
  output logic not_op,
  output logic tsr_load
);

  parameter STATE_WIDTH = 2;

  logic [STATE_WIDTH-1:0] pstate,
                          nstate;
  
  localparam  IDLE      = 2'b00,
              START     = 2'b01,
              TRANSMIT  = 2'b10,
              PARITY    = 2'b11;

  always @(*) begin : NSL
    case(pstate)
      IDLE     : nstate[STATE_WIDTH-1:0] = (utrst & ~thre)? START : IDLE ;
      START    : nstate[STATE_WIDTH-1:0] = (transmit_edge)? TRANSMIT : START;
      TRANSMIT : nstate[STATE_WIDTH-1:0] = (shift_cnt_eq)? (thre? (transmit_edge? IDLE : TRANSMIT) : (START)) : (data_cnt_eq & transmit_edge & pen)? PARITY : TRANSMIT ;
      PARITY   : nstate[STATE_WIDTH-1:0] = transmit_edge? TRANSMIT : PARITY; 
      default  : nstate[STATE_WIDTH-1:0] = 2'bx ; 
    endcase
  end
  
  assign transmit_clk_clr = (pstate == IDLE);
  assign shift_en         = (pstate == TRANSMIT) & (transmit_edge & ~(data_cnt_eq|shift_cnt_eq)) | (pstate == PARITY) & transmit_edge  ;
  assign shift_count_en   = (pstate == START) & transmit_edge | (pstate == TRANSMIT) & (transmit_edge & ~shift_cnt_eq) | (pstate == PARITY) & transmit_edge ;
  assign par              = (pstate == PARITY);
  assign not_op           = (pstate == IDLE) | (pstate == START);
  assign shift_count_clr  = (pstate == TRANSMIT) & (thre? shift_cnt_eq & transmit_edge : shift_cnt_eq) ;
  assign tsr_load         = (pstate == START) & transmit_edge ;

  
  dff #(.RESET_VALUE(IDLE),
	      .FLOP_WIDTH(STATE_WIDTH)
  ) u_psr (
    .clk     ( pclk   ),
    .reset_b ( presetn),
    .d       ( nstate ),
    .q       ( pstate )
  );

endmodule
