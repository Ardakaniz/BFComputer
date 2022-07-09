# BFComputer
 BFComputer is an architecture for running [Brainf*ck](https://en.wikipedia.org/wiki/Brainfuck) programs directly on hardware. It is a 12-bit computer using only 8 assembly instructions to manipulate memory, loop and interact with I/O.

| Instruction | Description                                                           |
| :---------: | --------------------------------------------------------------------- |
|    **+**    | Increment current cell value                                          |
|    **-**    | Decrement current cell value                                          |
|    **>**    | Increment cell cursor                                                 |
|    **<**    | Decrement cell cursor                                                 |
|    **[**    | If the current cell value is zero, jump to the associated `]`         |
|    **]**    | If the current cell value is nonzero, jump back to the associated `[` |
|    **.**    | Output the current cell value                                         |
|    **,**    | Write the input into the current cell value                           |

You can find in this repo the different parts of this project :
- The description of the hardware architecture, see [architecture (en) (not available yet)]() or [architecture (fr)](architecture/architecture_fr.md)
- The "compiler", from BF to binary (actually just a Python script converting the 8 instructions `+-<>[].,` to a binary value from 0 to 7)
- Simulation using [Digital](https://github.com/hneemann/Digital) and VHDL code in `simulation/VHDL`

Some ressources that got me interested in computer architecture and that helper me design this one:
- Ben Eater video series : https://eater.net/8bit
- The Elements of Computing Systems book