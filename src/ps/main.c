/*
 * main.c
 *
 *  Created on: 2025年3月16日
 *      Author: dv
 */

#include "xparameters.h"
#include "xplatform_info.h"
#include "xiicps.h"
#include "xil_printf.h"
#include "xgpiops.h"
#include "xstatus.h"
#include "i2c/i2c.h"
#include "ov5640.h"

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */

#define GPIO_DEVICE_ID		XPAR_XGPIOPS_0_DEVICE_ID

/* The slave address to send to and receive from.
 */

#define CMOS_RST 55
#define CMOS_PWDN 54

XGpioPs Gpio;
XIicPs i2c0;

int  initGpio () {
	int status;
	XGpioPs_Config *ConfigPtr;
	ConfigPtr = XGpioPs_LookupConfig(GPIO_DEVICE_ID);
	status = XGpioPs_CfgInitialize(&Gpio, ConfigPtr, ConfigPtr->BaseAddr);
	if(status != XST_SUCCESS) {
		printf("initial GPIO failed\n");
		return XST_FAILURE;
	}
	XGpioPs_SetDirectionPin(&Gpio, CMOS_RST, 1);
	XGpioPs_SetOutputEnablePin(&Gpio, CMOS_RST, 1);
	XGpioPs_SetDirectionPin(&Gpio, CMOS_PWDN, 1);
	XGpioPs_SetOutputEnablePin(&Gpio, CMOS_PWDN, 1);

	XGpioPs_WritePin(&Gpio, CMOS_RST, 0);
	XGpioPs_WritePin(&Gpio, CMOS_PWDN, 0);
}


//s32 writeReg(XIicPs *iicPs, char slaveAddr, u8 *Cfg_Ptr) {
//	s32 status;
//	status = XlicPs_MasterSendPolled(iicPs, Cfg_Ptr, 2, slaveAddr);
//	while(XlicPs_BusIsBusy(iicPs));
//	return status;
//}



int main(void){
	int Status;
	i2c_init(&i2c0, XPAR_XIICPS_0_DEVICE_ID, 40000);
	initGpio();
	XGpioPs_WritePin(&Gpio, CMOS_RST, 1);
	usleep(500000);
	XGpioPs_WritePin(&Gpio, CMOS_RST, 0);
	usleep(500000);
	XGpioPs_WritePin(&Gpio, CMOS_RST, 1);
	usleep(500000);
	sensor_init(&i2c0);
	while (1) {

	}
	return 0;
}


