/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include "xparameters.h"
#include "xuartps.h"
#include <stdio.h>
#include <xparameters_ps.h>
#include <xuartps_hw.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

//Address offset of the UART module in the PL
#define UART_PL_BASEADDR 0x00000000                 //Modify it according to the hardware

//No need to modify these
#define UART_RBR 0x00000000  
#define UART_THR 0x00000000
#define UART_IER 0x00000004
#define UART_IIR 0x00000008
#define UART_FCR 0x00000008
#define UART_LCR 0x00000008
#define UART_LSR 0x00000014
#define UART_DLL 0x00000020
#define UART_DLH 0x00000024
#define UART_PWM 0x00000030

//UART PS function prototypes
int UartPS_Init(XUartPs *uartPS);

//UART PL function prototypes
void UartPL_SetIntpt(u32 intptMask);
void UartPL_SetFifoCtrl(u32 fifoCtrl);
void UartPL_SetLineCtrl(u32 lineCtrl);
void UartPL_BaudRateDivider(u32 divider);
void UartPL_SetEnableState(u32 enable);
void UartPL_SendData(u32 data);
u32 UartPL_ReceiveData();
void UartPL_Init();


int main()
{
    u8 txMessage[] = "howdyyyy";
    u8 rxMessage[8];
    XUartPs uartPS;

    init_platform();
    //Initializing PS side UART
    UartPS_Init(&uartPS);
    //Initializing PL side UART
    UartPL_Init();

    //................................Sending data from PS to PL. Receiving at PL, and reading it using AXI..........

    while(1){
        //Sending data out through UART PS
        printf("Sending message From PS to PL\n");
        XUartPs_Send(&uartPS, txMessage, 8);

        printf("Receiving message @ PL\n");
        for(int i = 0;i < 8; i++)
        {
            //Receiving through the PL side UART
            rxMessage[i] = UartPL_ReceiveData();
        }
        printf("Received message From PS to PL:\n");
        for(int i = 0;i < 8; i++)
        {
            printf("%c", rxMessage[i]);
            //emptying rxMessage array so that we don't get confused with the previously received data
            rxMessage[i] = ' ';
        }
        printf("\n");

        //................................Sending data from PL to PS. Receiving at PL and rading it directly.
        printf("Sending message From PL to PS\n");
        for(int i = 0;i < 8; i++)
        {
            //Sending data through PL side
            UartPL_SendData(txMessage[i]);
        }
        printf("Receiving message @ PS\n");
        //Receiving data at the PS side
        XUartPs_Recv(&uartPS, rxMessage, 8);

        printf("Received message From PL to PS: \n");
        for(int i = 0;i < 8; i++)
        {
            printf("%c", rxMessage[i]);
            //emptying rxMessage array so that we don't get confused with the previously received data
            rxMessage[i] = ' ';
        }
        printf("\n");
    }

    cleanup_platform();
    return 0;
}

                                //////////////////////////////////////////////////////
                                //                                                  //
                                //          Initializes UART in the PS side         //
                                //                                                  //
                                //////////////////////////////////////////////////////

/**
* @param uartPS Driver instantiation of the UART PS
* @return returns 0 if the operation completes successfully
*/                       
int UartPS_Init(XUartPs *uartPS)
{
    XUartPs_Config *uartConfig;
    XUartPsFormat format;
    
    printf("UART-PS: Initializing\n");
    //configure data format, baud rate, parity
    format.DataBits = XUARTPS_FORMAT_8_BITS;
    format.BaudRate = XUARTPS_DFT_BAUDRATE;
    format.StopBits = XUARTPS_FORMAT_1_STOP_BIT;
    format.Parity   = XUARTPS_FORMAT_EVEN_PARITY;

    //Load UART configuration
    uartConfig = XUartPs_LookupConfig(XPAR_XUARTPS_1_BASEADDR);
    printf("UART-PS : Lookup configuration complete\n");
    //Initialize UART based on that configuration
    XUartPs_CfgInitialize(uartPS, uartConfig, XPAR_XUARTPS_1_BASEADDR);
    printf("UART-PS : Initialization complete\n");

    //Set data format for the driver
    XUartPs_SetDataFormat(uartPS, &format);
    printf("UART-PS : Setting data format complete\n");
    printf("UART-PS : Ready\n");

    return 0;
}

                                //////////////////////////////////////////////////////
                                //                                                  //
                                //          Initializes UART in the PL side         //
                                //                                                  //
                                //////////////////////////////////////////////////////

void UartPL_Init()
{
    printf("UART-PL : Initializing\n");
    UartPL_SetIntpt(0x00000000);
    printf("UART-PL : Interrupt set complete\n");
    UartPL_SetFifoCtrl(0x00000001);
    printf("UART-PL : FIFO congifuration complete\n");
    UartPL_SetLineCtrl(0x00000008);
    printf("UART-PL : Line Configuration complete\n");
    UartPL_BaudRateDivider(0x00000100);
    printf("UART-PL : Baud Rate configuration complete\n");
    UartPL_SetEnableState(0x0000F000);
    printf("UART-PL : Enable state asserted\n");
    printf("UART-PL : Ready\n");
}


/**
* @param intptMask Interrupt mask. Usable bits are- [3:0] EDSSI ELSI ETBI ERBI
* @return Void
*/
void UartPL_SetIntpt(u32 intptMask)
{
    Xil_Out32(UART_PL_BASEADDR + UART_IER, intptMask);
}


/**
* @param fifoCtrl FIFO control register value. Usable bits are- RXFIFTL[1:0] 0 0 0 TXCLR RXCLR FIFOEN
* @return Void
*/
void UartPL_SetFifoCtrl(u32 fifoCtrl)
{
    Xil_Out32(UART_PL_BASEADDR + UART_FCR, fifoCtrl);
}

/**
* @param lineCtrl Line control register value. Usable bits are- LOOP SP EPS PEN STB WLS[1:0]
* @return Void
*/
void UartPL_SetLineCtrl(u32 lineCtrl)
{
    Xil_Out32(UART_PL_BASEADDR + UART_LCR, lineCtrl);
}

/**
* @param divider Baud rate divider value. {16'b0, DLH[7:0], DLL[7:0]} 
* @param return Void
*/
void UartPL_BaudRateDivider(u32 divider)
{
    //Writes the Lower part of the divider
    Xil_Out32(UART_PL_BASEADDR + UART_DLL, divider & 0x000000FF);
    //Writes the Higher part of he divider
    Xil_Out32(UART_PL_BASEADDR + UART_DLH, (divider >> 8) & 0x000000FF);
}


/**
* @param enable PWM register value. Usable bits are- PWM[14] - UTRST, PWM[13] - URRST. 
* @param return Void
*/
void UartPL_SetEnableState(u32 enable)
{
    Xil_Out32(UART_PL_BASEADDR + UART_PWM, enable);
}

/**
* @param data Data byte to send.
*/
void UartPL_SendData(u32 data)
{
    Xil_Out32(UART_PL_BASEADDR + UART_THR, data);
}

/**
* @param None
* @return u32 value from the receive buffer
*/
u32 UartPL_ReceiveData()
{
    u32 value = Xil_In32(UART_PL_BASEADDR + UART_LSR);
    return value;
}