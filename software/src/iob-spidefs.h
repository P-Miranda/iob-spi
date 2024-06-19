
// TYPECODES identify type of operation to be executed by flash controller

#define COMM 0
#define COMMANS 1
#define COMMADDR_ANS 2
#define COMM_DTIN 3
#define COMMADDR_DTIN 4
#define COMMADDR 5
#define XIP_ADDRANS 6
#define RECOVER_SEQ 7

//
#define ACTIVEXIP 2
#define TERMINATEXIP 3

// SPI MODES ENCODING
#define SIMPLEMODE 0
#define DUALMODE 1
#define QUADMODE 2

// FLASH MEM internal command codes
#define RESET_ENABLE 0x66
#define RESET_MEM 0x99
#define READ 0x03
#define WRITE_ENABLE 0x06
#define WRITE_DISABLE 0x04
#define WRITE_VOLCFGREG 0x81
#define PAGE_PROGRAM 0x02
#define SUB_ERASE 0x20
#define SEC_ERASE 0xD8
#define READ_STATUSREG 0x05
#define READ_VOLCFGREG 0x85
#define READ_NONVOLCFGREG 0xB5
#define READ_ID 0x9f
#define READ_FLPARAMS 0x5A
#define READ_FLAGREG 0x70
#define READ_LOCKREG 0xE8
#define READ_EXTADDRREG 0xC8

#define READENHANCEDREG 0x65
#define WRITEENHANCEDREG 0x61

// Fast Read Commands
#define READFAST_DUALOUT 0x3B
#define READFAST_QUADOUT 0x6B
#define READFAST_DUALINOUT 0xbb
#define READFAST_QUADINOUT 0xeb

// Program Commands
#define PROGRAMFAST_DUALIN 0xa2
#define PROGRAMFAST_DUALINEXT 0xd2
#define PROGRAMFAST_QUADIN 0x32
#define PROGRAMFAST_QUADINEXT 0x12

// DTR Read Commands
#define READFAST_DTR 0x0D
#define READFAST_DUALOUTDTR 0x3D
#define READFAST_DUALIODTR 0xBD
#define READFAST_QUADOUTDTR 0x6D
#define READFAST_QUADIODTR 0xED

#define ENTER4BYTEADDR 0xB7
#define EXIT4BYTEADDR 0xE9

// COMMAND FIELD OFFSETS
#define CMD_COMMAND 0
#define CMD_NDATA_BITS 8
#define CMD_DUMMY_CYCLES 16
#define CMD_FRAME_STRUCT 20
#define CMD_XIPBIT_EN 30

// COMMANDTP FIELD OFFSETS
#define CTP_COMMTYPE 0
#define CTP_DTR_EN 20
#define CTP_FOURBYTEADDRON 21
#define CTP_SPIMODE 30

// FRAME STRUCTURE FIELD OFFSETS
#define FSTRUCT_ALT 0
#define FSTRUCT_RX 2
#define FSTRUCT_TX 4
#define FSTRUCT_ADDR 6
#define FSTRUCT_CMD 8

// NON-VOLATILE CONFIG REGISTER FIELD OFFSETS
#define NONVOLCFG_ADDRBYTES 0
#define NONVOLCFG_128MBSEGMENT 1
#define NONVOLCFG_DUALIOPROT 2
#define NONVOLCFG_QUADIOPROT 3
#define NONVOLCFG_RSTHOLD 4
#define NONVOLCFG_RESERVED 5
#define NONVOLCFG_OUTDRIVER 6
#define NONVOLCFG_XIPATPOWERON 9
#define NONVOLCFG_DUMMYCYCLES 12

// VOLATILE CONFIG REGISTER FIELD OFFSETS
#define VOLCFG_WRAP 0
#define VOLCFG_RESERVED 2
#define VOLCFG_XIP 3
#define VOLCFG_DUMMYCYCLES 0

// MEMORY MAP MACROS
#define SECTOR_SIZE 65536 // 0x10000
#define SUBSECTOR_SIZE 4096 // 0x1000
#define NUM_SECTORS 512
#define NUM_SUBSECTORS 8192
#define SUBSECTOR_PER_SECTOR 16