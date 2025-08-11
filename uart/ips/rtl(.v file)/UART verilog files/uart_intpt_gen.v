module uart_intpt_gen(
    input thre,
    input etbei,
    input pe,
    input elsi,
    input fe,
    input bi, 
    input dr,
    input erbi,
    input below_level, 

    output uart_intpt
);
    
  reg thre_int;
  reg rx_line_st_int;
  reg dr_int;

  // Interrupt logic
  always @(*) begin
    thre_int       = thre & etbei;
    rx_line_st_int = (pe | fe | bi) & elsi;
    dr_int         = dr & erbi & ~below_level;
  end

  assign uart_intpt = thre_int | rx_line_st_int | dr_int;

endmodule
