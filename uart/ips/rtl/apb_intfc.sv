module apb_intfc(
  input  logic        pclk,
  input  logic        presetn,
  input  logic        psel,
  input  logic        pwrite,
  input  logic        penable,
  input  logic[31:0]  paddr,
  input  logic[31:0]  pwdata,
                      
  input  logic[10:0]  rbr,
  input  logic        parity_error,
  input  logic        frame_error,
  input  logic        error_check,
  input  logic        shift_cnt_eq,
  input  logic        rx_fifo_empty,
  input  logic        tsr_load,
  input  logic        receive_done,
  input  logic        tx_fifo_empty,
  input  logic        uart_intpt,
  input  logic        uart_break,
  input  logic        rx_fifo_full,
  input  logic        rbrf,
                      
  output logic        loop,
  output logic        thr_wr_en,
  output logic        rbr_rd_en,
  output logic[1:0]   rxfiftl,
  output logic        txclr,
  output logic        rxclr,
  output logic        fifoen,
  output logic        sp,
  output logic        eps,
  output logic        pen,
  output logic        stb,
  output logic [1:0]  wls,
  output logic [7:0]  dll,
  output logic [7:0]  dlh,
  output logic        urrst,
  output logic        utrst,
                      
                      
  output logic        thre,
  output logic        etbei,
  output logic        pe,
  output logic        elsi,
  output logic        fe,
  output logic        dr,
  output logic        erbi,
                      
  output logic        pready,
  output logic[31:0]  prdata

);
  
  logic ier_wr_en;
  logic fcr_wr_en;
  logic lcr_wr_en;
  logic lsr_wr_en;
  logic dll_wr_en;
  logic dlh_wr_en;
  logic pwremu_mgmt_wr_en;


  //APB FSM
  logic wr_en;
  logic rd_en;

  fsm_apb_protocol i_fsm_apb_protocol (
    .pclk    (pclk    ),
    .preset_n(presetn),
    .psel    (psel    ),
    .pwrite  (pwrite  ),
    .penable (penable ),
    .pready  (pready  ),
    .rd_en   (rd_en   ),
    .wr_en   (wr_en   )
  );


  //comparator
  assign thr_wr_en = (paddr[7:0] == 8'b0) & wr_en;
  assign ier_wr_en = (paddr[7:0] == 8'h4) & wr_en;
  assign fcr_wr_en = (paddr[7:0] == 8'h8) & wr_en;
  assign lcr_wr_en = (paddr[7:0] == 8'hC) & wr_en;
  assign lsr_wr_en = (paddr[7:0] == 8'h14) & wr_en;
  assign dll_wr_en = (paddr[7:0] == 8'h20) & wr_en;
  assign dlh_wr_en = (paddr[7:0] == 8'h24) & wr_en;
  assign pwremu_mgmt_wr_en = (paddr[7:0] == 8'h30) & wr_en;
  

  //Interrupt enable register
  logic[2:0] ier_d;
  logic[2:0] ier_q;

  assign ier_d = ier_wr_en ? pwdata[2:0] : ier_q;
  assign erbi  = ier_q[0];
  assign etbei = ier_q[1];
  assign elsi  = ier_q[2];

  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 3       )
  )u_ier(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( ier_d   ),
   .q           ( ier_q   )
  );
  
  //FIFO control register
  //
  logic[4:0] fcr_d;
  logic[4:0] fcr_q;

  assign fcr_d   = fcr_wr_en ? {pwdata[7:6], pwdata[2:0]} : fcr_q;
  assign fifoen  = fcr_q[0];
  assign rxclr   = fcr_q[1];
  assign txclr   = fcr_q[2];
  assign rxfiftl = fcr_q[3];
  
  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 5       )
  )u_fcr(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( fcr_d   ),
   .q           ( fcr_q   )
  );

  //Line control register
  logic[7:0] lcr_q;
  logic[7:0] lcr_d;
  

  assign lcr_d = lcr_wr_en ? pwdata[7:0] : lcr_q ;
  assign wls   = lcr_q[1:0];
  assign stb   = lcr_q[2];
  assign pen   = lcr_q[3];
  assign eps   = lcr_q[4];
  assign sp    = lcr_q[5];
  assign bc    = lcr_q[6];
  assign loop  = lcr_q[7];

  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 8       )
  )u_lcr(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( lcr_d   ),
   .q           ( lcr_q   )
  );



  //Status control  
  logic parity_st_d;
  logic frame_st_d;
  logic de_st_d;
  logic thre_st_d;
  logic temt_st_d;
  logic bi_st_d;
  logic oe_st_d;
  logic rxfifoe_st_d;
  //logic pe;
  //logic fe;
  logic temt;
  //logic dr;

  logic paddr_eq_rbr_thr;

  logic[7:0] lsr_d;
  logic[7:0] lsr_q;

  assign rbr_rd_en        = (paddr_eq_rbr_thr & rd_en);  
  assign paddr_eq_rbr_thr = (paddr[7:0] == 8'b0);

  assign parity_st_d      = fifoen ? (((rbr[8]) | pe)  & ( ~ (rd_en & paddr_eq_rbr_thr))) : ((parity_error & error_check) | pe) & ( ~ (rd_en & paddr_eq_rbr_thr));
  assign frame_st_d       = fifoen ? ((rbr[9] | fe) & ( ~ (rd_en & paddr_eq_rbr_thr))) : ((frame_error & error_check) | fe) & ( ~ (rd_en & paddr_eq_rbr_thr));
  assign de_st_d          = fifoen ? ~rx_fifo_empty : ((receive_done | dr) & ( ~ (rd_en & paddr_eq_rbr_thr)));
  assign thre_st_d        = ~thr_wr_en & ((~fifoen & tsr_load) | ((fifoen & tx_fifo_empty) | thre));
  assign temt_st_d        = shift_cnt_eq ? thre : temt;
  assign bi_st_d          = fifoen ? (rbr[10] & ( ~ (rd_en & paddr_eq_rbr_thr))) : (uart_break & ( ~ (rd_en & paddr_eq_rbr_thr)));
  assign oe_st_d          = fifoen ? (rx_fifo_full & receive_done) : (rbrf & receive_done);
  assign rxfifoe_st_d     = |(lsr_d[4:0]);





  assign lsr_d = {temt_st_d, thre_st_d, bi_st_d, frame_st_d, parity_st_d, oe_st_d ,de_st_d};
  assign pe    = lsr_q[2];
  assign fe    = lsr_q[3];
  assign temt  = lsr_q[6];
  assign thre  = lsr_q[5];
  assign dr    = lsr_q[0];
  
  
  dff #(
   .RESET_VALUE ( 8'b01100000),
   .FLOP_WIDTH  ( 8       )
  )u_lsr(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( lsr_d   ),
   .q           ( lsr_q   )
  );
  

  //DLL
  logic[7:0] dll_d;
  assign dll_d = dll_wr_en ? pwdata[7:0] : dll;

  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 8       )
  )u_dll(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( dll_d   ),
   .q           ( dll     )
  );

  //DLH
  logic[7:0] dlh_d;
  assign dlh_d = dlh_wr_en ? pwdata[7:0] : dlh;

  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 8       )
  )u_dlh(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( dlh_d   ),
   .q           ( dlh     )
  );

  //Power and emulation
  logic[1:0] pwr_d;
  logic[1:0] pwr_q;
  assign pwr_d = pwremu_mgmt_wr_en ? pwdata[14:13] : pwr_q;
  assign utrst = pwr_q[1];
  assign urrst = pwr_q[0];

  dff #(
   .RESET_VALUE ( 1'b0    ),
   .FLOP_WIDTH  ( 2       )
  )u_pwr(
   .clk         ( pclk    ),
   .reset_b     ( presetn ),
   .d           ( pwr_d   ),
   .q           ( pwr_q   )
  );
  

  logic[31:0] rd_data;
  //Read logic
  always@(*)begin
    case(paddr[5:0])
      32'h0   : rd_data = {24'b0, rbr};
      32'h4   : rd_data = {29'b0, ier_q[2:0]};
      32'h8   : rd_data = {24'b0, fifoen, fifoen, 5'b0, ~ uart_intpt};
      32'h8   : rd_data = {26'b0, lcr_q [5:0]};
      32'h8   : rd_data = {17'b0, temt, thre, 1'b0, fe, pe, 1'b0, dr};
      32'h8   : rd_data = {24'b0, dll};
      32'h8   : rd_data = {24'b0, dlh};
      32'h8   : rd_data = {17'b0, pwr_q[1:0], 13'b0};
      default : rd_data = 32'bx;
    endcase
  end

  assign prdata = rd_en ? rd_data : 32'b0;


endmodule