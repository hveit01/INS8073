# INS8073
 SC/MP-3 NIBL Tiny BASIC documentation

This repo contains the datasheet for the INS 8070/2/3 microprocessor, aka National Semiconductor SC/MP-3.
Note this is a different system than the well-known ISP8A-500/600 processors known as SC/MP-1 and -2.

So far, only incomplete docs wcould be found from the Internet (mainly lacking the complete instruction set.

The INS8073 is a version with a 2,5k internal ROM containing a Tiny BASIC which is documented for the first time here.

The application note AN-0280 is to my knowledge the only known schematic which uses the SC/MP-3 in some application.
From that I derived a simple circuit (the INS8070, two 2114, a 7404, a 7805 and a MAX232) to read out the ROM content
with a simple Tiny BASIC program, resulting in scmp3-list.txt.

I wrote a simple disassembler to convert the list file to some assembler and commented it manually (scmp3.asm).

The schematic, the BASIC extraction program, and the disassembler are lost, but are rather obvious.
In the circuit, the 7404 is basically only necessary to complement the polarity of the F1 serial output.
Everything else is completely identical to the core circuit from the application note.