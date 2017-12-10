# Test Makes

default: choose_a_test_src.fault

NAME=div
${NAME}.hex: ${NAME}.asm
		avra.exe -I ../../include -l ${NAME}.lss -m ${NAME}.mapl ${NAME}.asm

clean:
		rm ${NAME}.hex ${NAME}.eep.hex

load: ${NAME}.hex
		atprogram.exe -v -t medbg -i debugWIRE -d atmega328p program -f ${NAME}.hex --verify
