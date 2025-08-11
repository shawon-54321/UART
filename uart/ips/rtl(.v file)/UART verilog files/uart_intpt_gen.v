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
    
  wire thre_int;
  wire rx_line_st_int;
  wire dr_int;

  // Interrupt logic
  assign thre_int       = thre & etbei;
  assign rx_line_st_int = (pe|fe|bi)& elsi;
  assign dr_int         = dr & erbi & ~below_level;

  assign uart_intpt = thre_int | rx_line_st_int | dr_int ;

endmodule
