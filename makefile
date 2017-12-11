# Main Program
NAME=ca_final
MAIN=main
OUT_DIR_DEF=mk_def
${NAME}.hex: src/${MAIN}.asm
		avra.exe -I include/ -l ${NAME}.lss -m ${NAME}.mapl src/${MAIN}.asm

		mv ${NAME}.lss ${OUT_DIR_DEF}/
		mv ${NAME}.mapl ${OUT_DIR_DEF}/

		mv src/${MAIN}.cof ${OUT_DIR_DEF}/
		mv src/${MAIN}.eep.hex ${OUT_DIR_DEF}/
		mv src/${MAIN}.hex ${OUT_DIR_DEF}/
		mv src/${MAIN}.obj ${OUT_DIR_DEF}/

clean:
		rm ${OUT_DIR_DEF}/${MAIN}.hex ${OUT_DIR_DEF}/${MAIN}.eep.hex

load: ${NAME}.hex
		# avrdude.exe -p m328p -c xplainedmini -U flash:w:${OUT_DIR_DEF}/${NAME}.hex
		atprogram.exe -v -t medbg -i debugWIRE -d atmega328p program -f ${OUT_DIR_DEF}/${MAIN}.hex --verify
