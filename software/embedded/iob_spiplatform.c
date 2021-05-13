#include <stddef.h>
#include "iob_spiplatform.h"
#include "SPIsw_reg.h"
#include "interconnect.h"
#include "iob_spidefs.h"
#include "stdint.h"

static unsigned int base;
//create another static variable for upper addresses
//SET
void spifl_reset()
{
	IO_SET(base, FL_RESET, 1);//soft reset
	IO_SET(base, FL_RESET, 0);
}

void spifl_setDATAIN(unsigned int datain)
{
	IO_SET(base, FL_DATAIN, datain);

}

void spifl_setADDRESS(unsigned int address)
{
	IO_SET(base, FL_ADDRESS, address);
}

void spifl_setCOMMAND(unsigned int command)
{
	IO_SET(base, FL_COMMAND, command);
}

void spifl_setCOMMTYPE(unsigned int commtype)
{
	IO_SET(base, FL_COMMANDTP, commtype);
}

void spifl_setVALIDIN(unsigned int validin)
{
	IO_SET(base, FL_VALIDFLG, validin);
}

//GET
unsigned int spifl_getDATAOUT()
{
	unsigned int dataout;
	dataout = (unsigned int) IO_GET(base, FL_DATAOUT);
	return dataout;
}

inline unsigned spifl_getREADY()
{
    return (unsigned int) IO_GET(base, FL_getREADY);
}

unsigned int spifl_getVALIDOUT()
{
	unsigned int validout;
	validout = (unsigned int) IO_GET(base, FL_VALIDFLGOUT);
	return validout;
}

//Higher functions
void spifl_init(int base_address)
{
	base = base_address;
	spifl_reset();
	//spifl_resetmem();
}
void spifl_waitvalidout()
{
	while(!IO_GET(base, FL_VALIDFLGOUT));//not using wrapper getter
}

void spifl_executecommand(int typecode, unsigned int datain, unsigned int address, unsigned int command, unsigned *dataout)
{
	spifl_setCOMMAND(command);
	spifl_setCOMMTYPE(typecode);
    while(!spifl_getREADY);
	
	switch(typecode)
	{
		case COMM:
				spifl_setVALIDIN(1);
				//spifl_waitvalidout();
				spifl_setVALIDIN(0);
				//deassert valid?
				break;
		case COMMANS:
				spifl_setVALIDIN(1);
				spifl_setVALIDIN(0);
				//spifl_waitvalidout();
                while(!spifl_getREADY);
				*dataout = spifl_getDATAOUT();
				break;
		case COMMADDR_ANS:
				spifl_setADDRESS(address);
				spifl_setVALIDIN(1);
				spifl_setVALIDIN(0);
                while(!spifl_getREADY);
				//spifl_waitvalidout();
				*dataout = spifl_getDATAOUT();
				break;
		case COMM_DTIN:
				spifl_setDATAIN(datain);
				spifl_setVALIDIN(1);
				//spifl_waitvalidout();
				spifl_setVALIDIN(0);
				break;
		case COMMADDR_DTIN:
				spifl_setADDRESS(address);
				spifl_setDATAIN(datain);
				spifl_setVALIDIN(1);
				//spifl_waitvalidout();
				spifl_setVALIDIN(0);
				break;
		case COMMADDR:
				spifl_setADDRESS(address);
				spifl_setVALIDIN(1);
				//spifl_waitvalidout();
				spifl_setVALIDIN(0);
				break;
        case XIP_ADDRANS:
				spifl_setADDRESS(address);
				spifl_setVALIDIN(1);
				spifl_setVALIDIN(0);
                while(!spifl_getREADY);
				*dataout = spifl_getDATAOUT();
                break;
        case RECOVER_SEQ:
				spifl_setDATAIN(datain);
				spifl_setVALIDIN(1);
				spifl_setVALIDIN(0);
                break;
		default:
				spifl_setVALIDIN(1);
				spifl_setVALIDIN(0);

	}
}

