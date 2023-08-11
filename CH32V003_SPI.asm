include ch32v003_reg1.asm
########
# Default mapping (NSS/PC1, CK/PC5, MISO/PC7, MOSI/PC6).Push-pull multiplexed output for full duplex master mode, hardware NSS
# MSB first ,CPL0,CHPA1,full duplex,hardware SS control
##########
sp_init:
    li sp, STACK		# initialize stack pointer


#Enable GPIO clocks & AFIO in APB2 clock register
        
    	li x10,R32_RCC_APB2PCENR	# load address of APB2PCENR register to x10 ,for enabling GPIO A,D,C peripherals
	lw x11,0(x10)			# load contents from peripheral register R32_RCC_APB2PCENR pointed by x10
	li x7,((1<<2)|(1<<4)|(1<<5)|(1<<0)|(1<<12))	# 1<<IOPA_EN,1<<IOPC_EN,1<<IOPD_EN,1<<AFIOEN,1<<SPI enable port A,C,D and AFIO functions
	or x11,x11,x7			# or values 
	sw x11,0(x10)			# store modified enable values in R32_RCC_APB2PCENR



#configure GPIO PortC as multiplex push-pull output for SPI
	li x10,R32_GPIOC_CFGLR		# load pointer x10 with address of R32_GPIOC_CFGLR , I2C SDA & SCL is on portC PC1,PC2
	lw x11,0(x10)			# load contents from register pointed by x10
	li x7,~((0xf<<4)|(0xf<<20)|(0xf<<24)|(0xf<<28))	# clear pc1,pc5,pc6,pc7. we need to setup PC1 ,PC5,PC6,PC7 for SPI
	and x11,x11,x7			# clear  mode and cnf bits for selected pin C1,C2
	li x7,((0xB<<4)|(0xB<<20)|(0xB<<24)|(0xB<<28))		# PC1,PC5,PC6,PC7 = multiplex pushpull output 50mhz , 0b1011
	or x11,x11,x7			# OR value to register
	sw x11,0(x10)			# store in R32_GPIOC_CFGLR

SPI_CONFIG:
	li x10,R32_RCC_APB1PRSTR	# set pointer to clock control  peripheral reset register 
	lw x11,0(x10)			# load contents to x11
	li x7,(1<<12)			# shift 1 to 12th bit position
	or x11,x11,x7			# OR with x11
	sw x11,0(x10)			# set bit 12 of R32_RCC_APB1PRSTR to reset SPI peripheral
	not x7,x7			# invert values in x7
	and x11,x11,x7			# and x11 to write a 0 in 21st bit
	sw x11,0(x10)			# store 0 in 12th bit to restart SPI engine


	li x10,R16_SPI_CTLR1
	lw x11,0(x10)
	li x7,((1<<2)|(1<<3)|(1<<8))	# MSTR,BR,SSI
	or x11,x11,x7
	sw x11,0(x10)

	
	li x10,R16_SPI_CTLR2
	lw x11,0(x10)
	li x7,(1<<2)			# SSOE bit
	or x11,x11,x7
	sw x11,0(x10)

	li x10,R16_SPI_CTLR1
	lw x11,0(x10)
	li x7,(1<<6)			# SPE , enable SPI
	or x11,x11,x7
	sw x11,0(x10)
###########################

main:
	li x15,0xAA
	call SPI_WRITE
	li x15,0x01
	call SPI_WRITE
	li x15,0x02
	call SPI_WRITE
	li x15,0x03
	call SPI_WRITE
	li x15,0x04
	call SPI_WRITE
here:
	j here

#SPI_SUBROUTINES:
########################
SPI_WRITE:
	addi sp,sp,-12			# move stack pointer 3 words
	sw ra,0(sp)			# push return address
	sw x10,4(sp)			# push x10
	sw x11,8(sp)			# push x11
SPIW_LOOP:
	li x10,R16_SPI_STATR		# set pointer x10 to SPI status register
	lw x11,0(x10)			# copy contents to x11
	andi x11,x11,(1<<1)		# TXE bit , AND x11 with TXE,transmission buffer empty bit mask
	beqz x11,SPIW_LOOP		# if TXE bit not set wait in a tight loop
	li x10,R16_SPI_DATAR		# once TXE bit is set ,point SPI data register with x10
	sw x15,0(x10)			# store data in x15 to SPI data register

	lw x11,8(sp)			# pop x11
	lw x10,4(sp)			# pop x10
	lw ra,0(sp)			# pop return address register
	addi sp,sp,12			# restore stack pointer to old position
	ret				# return to caller
#####################	
SPI_READ:
	addi sp,sp,-12			# move stack pointer 3 words
	sw ra,0(sp)			# push return address
	sw x10,4(sp)			# push x10
	sw x11,8(sp)			# push x11
SPIR_LOOP:
	li x10,R16_SPI_STATR		# set pointer x10 to SPI status register
	lw x11,0(x10)			# copy contents to x11
	andi x11,x11,(1<<0)		# RXNE bit, AND with RXNE bit mask , receive buffer not empty bit mask
	beqz x11,SPIR_LOOP		# if RXNE bit not set wait in a tight loop, wait till data arrive in receive register
	li x10,R16_SPI_DATAR		# x10 points to SPI data register
	lw x15,0(x10)			# load data to x15 from address pointed by x10(SPI data register)

	lw x11,8(sp)			# pop x11
	lw x10,4(sp)			# pop x10
	lw ra,0(sp)			# pop return address register
	addi sp,sp,12			# restore stack pointer to old position
	ret				# return to caller
###########################






