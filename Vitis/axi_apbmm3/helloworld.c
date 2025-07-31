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
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

void test();

int main()
{
    u32 reg_data[4];
    int k = 0;
    init_platform();

   // test();

    printf("Started op\n");
    while(k < 1000){

        for(int i = 0;i < 4;i++){
            reg_data[i] = Xil_In32(XPAR_APB_INTERFACE_1_BASEADDR + 0x00000004 * i);
            printf("push reg %d : %x\n", i, reg_data[i]);

            printf("Writing to LED reg\n");
            Xil_Out32(XPAR_APB_INTERFACE_0_BASEADDR + 0x00000004 * i, reg_data[i]);
        }
        printf("Writing done\n");
        k++;
    }

    cleanup_platform();
    return 0;
}

void test()
{
    u32 temp;
    temp = Xil_In32(XPAR_APB_INTERFACE_1_BASEADDR);
    printf("Test done, data :%x", temp);
}