# README #

## What is this repository for? ##

* IOB-SIMPLE-SPI is a pair of simple SPI master and slave cores 
* Version 0.0


## How do I get set up? ##

* Install Icarus Verilog (download a stable version from http://iverilog.icarus.com)
* Install Gtkwave (download a stable version from http://gtkwave.sourceforge.net)
* There is a Quartus project in fpga/altera/cyclone_v_gt/quartus_18.0 featuring qxp netlists

## How do I run Icarus simulation ##

```
    cd rtl
    make
```

## How do I use the cores in software ##

### Master ###

	0. Write 1 to the SPI_INTRRPT_EN address to enable Interrupt if you wish
    1. Write the word to be transmitted to the SPI_TX address
    2. Poll the SPI_READY address until it is 1 or wait for Interrupt from Master
    3. Read the SPI_RX address to get the word received from Slave. This action will reset Interrupt.
	4. Write 0 to the SPI_INTRRPT_EN address to disable Interrupt if you wish


### Slave ###

	0. Write 1 to the SPI_INTRRPT_EN address to enable Interrupt if you wish
    1. Poll the SPI_READY address until it is 1 or wait for Interrupt from Master
    2. Read the SPI_RX address to get the word received from Master. This action will reset Interrupt.
    3. Write the response word to the SPI_TX address to be sent to Master on the next SPI cycle
	4. Write 0 to the SPI_INTRRPT_EN address to disable Interrupt if you wish
 


## How do I instantiate the cores ##

Just refer to file rtl/spi_top.v and you'll see Master and Slave instantiated