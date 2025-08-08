module tb_uart_top;

  logic pclk = 0;
  logic presetn;
  logic psel;
  logic penable;
  logic pwrite;
  logic [31:0] paddr;
  logic [31:0] pwdata;
  
  logic uart_rxd;
  
  logic pready;
  logic [31:0] prdata;
  
  logic uart_txd;

  int idx;

  always #5 pclk = ~ pclk;

  uart_top u_uart_top (
   .pclk       ( pclk       ),
   .presetn    ( presetn    ),
   .psel       ( psel       ),
   .penable    ( penable    ),
   .pwrite     ( pwrite     ),
   .paddr      ( paddr      ),
   .pwdata     ( pwdata     ),
   
   .uart_rxd   ( uart_rxd   ),
   
   .pready     ( pready     ),
   .prdata     ( prdata     ),
   
   .uart_txd   ( uart_txd   ),
   .uart_intpt ( uart_intpt )
  );



// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> || Stimuli || <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  initial begin

    reset;
    delay(10);
    dll_wr(8'b010);
    int_en_wr(1,1,1);
    line_control(1,0,0,0,1,0,2'b00);
    single_transmit(8'b10101010);
    //delay(100);
    //single_transmit(8'b10111001);
    //delay(1000);

    //single_receive(11'b00000000000);
    //break_data;
   // delay(100);
    //read(32'h0);

    //read(32'h0);
    //continuos_fifo_tx(5);
    //delay(20000);
//    read(32'h0);
//    delay(2);
//    read(32'h0);
//    delay(2);
//    read(32'h0);
    delay(2000);
    $finish;

  end
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> oooooooooooo <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




// Basic Tasks 
  // delay
  task delay (integer d);
    repeat(d) @(posedge pclk);
  endtask


  //..............reset...................
  task reset;
    presetn  = 0;
    psel     = 0;
    penable  = 0;
    pwrite   = 0;
    paddr    = 32'h0;
    pwdata   = 32'h0;
    uart_rxd = 1;

    presetn = 1'b0;
    delay(1);
    presetn = 1'b1;
  endtask
  //......................................
 //write........
  task write (input [31:0] adr, input [31:0] data );
    begin 
      @(posedge pclk);
      psel = 1;
      pwrite = 1;
      paddr = adr;
      pwdata = data;
      @(posedge pclk);  
      penable = 1;   
      @(posedge pclk);
      psel = 0;
      pwrite = 0;
      penable = 0; 
    end
  endtask
  //Read
  task read (input [31:0] adr);
    begin 
      @(posedge pclk);
      psel = 1;
      pwrite = 0;
      paddr = adr;
      @(posedge pclk);  
      penable = 1;   
      @(posedge pclk);
      psel = 0;
      pwrite = 0;
      penable = 0; 
    end
  endtask

  task fifo_enable(input en); //0 to disable
    write (32'h8, {31'b0, en});
  endtask

  task tx_rx_en (input tx, input rx); //0 to disable
    write (32'h30, {17'b0, tx, rx, 13'b0});
  endtask

  task dll_wr (input [7:0] divisor_l);
    write (32'h20, {24'b0,divisor_l});
  endtask

  task line_control (input loop, input bc, input sp, input eps, input pen, input stb, input [1:0]wls);
    write (32'hC, {24'b0,loop,bc,sp,eps,pen,stb,wls[1:0]});
  endtask

  task int_en_wr (input elsi, input etbei, input erbi);
    write (32'h4, {29'b0,elsi,etbei,erbi});
  endtask


  // Test Case Tasks----------------------------------------------------

  //1 byte transmit
  task single_transmit(input [7:0] tx_data);
    tx_rx_en (1,0);
    fifo_enable(0);
    write (32'b0 , {24'b0, tx_data});
    tx_rx_en (0,0);
  endtask
  
  //1 byte receive
  task single_receive(input [9:0] data);
    fifo_enable(0);
    //tx_rx_en (1,1);
    @(posedge tb_uart_top.u_uart_top.u_uart_receive_top.u_uart_receive_fsm.start_st);
    delay(1);
    uart_rxd = 1'b0;
    for(int i=0;i<10;i++) begin
      idx = i;
      delay(64);
      uart_rxd = data[i];
    end
    delay(64);
    uart_rxd = 1'b1;
    delay(50);
     tx_rx_en (0,0);
  endtask

  task break_data;
    fifo_enable(0);
    tx_rx_en (0,1);
    @(posedge tb_uart_top.u_uart_top.u_uart_receive_top.u_uart_receive_fsm.start_st);
    delay(1);
    uart_rxd = 1'b0;
    for(int i=0;i<11;i++) begin
      idx = i;
      delay(64);
      uart_rxd = 0;
    end
    delay(64);
    uart_rxd = 1'b1;
    delay(50);
     tx_rx_en (0,0);
  endtask

  task overrun;
    single_receive(10'b1110101010);

    delay(50);
    //read(32'h0);

    single_receive(10'b1111001100);

    delay(50);
    //read(32'h0);
    single_receive(10'b1110110000);

    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b0111001010);
    delay(50);
    //read(32'h0);
    single_receive(10'b1101011111);
    

    delay(52);
  endtask

    task continuos_fifo_tx(int n);
      fifo_enable(1);
      tx_rx_en (1,1);
      for(int i=0;i<n;i++) begin 
          write (32'b0 , {24'b0, 8'hAA+i});
      delay(20);
      end

    endtask

endmodule