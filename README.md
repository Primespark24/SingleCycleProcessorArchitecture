# Computer Architecture
## MIPS 3 - VHDL MIPS Single Cycle Processor - Individual Assignment

### MIPS 3 Overview
* Fill in the answers to the questions in this document and submit it back to your whitgit folder
* Learn how the VHDL hardware for a MIPS single cycle processor works
* Learn how to implement new instructions for the MIPS single cyle processor

### Grade Break Down
| Part                                              |   | Points  |
|---------------------------------------------------|---|---------|
| MIPS_3-1 - Change MIPS Program (Individual)       |   | 20 pts  |    
| MIPS_3-2 - Compare Sim to Prediction (Individual) |   | 20 pts  |   
| MIPS_3-3 - Run MIPS on BASYS 3 (Individual)       |   | 10 pts  |   
| Total                                             |   | 50 pts  |

NOTE: The MIPS_3 group project will be graded separately and will be worth 50 points as well. 


# Introduction
In this lab you will expand the MIPS single-cycle processor using VHDL. You will also turn in this document on blackboard with your answers pasted into the document. Each individual will turn in the document separately.
* You will load a test program and check that the instructions work in both the simulator and on a FPGA.  
* Next, you will implement two new MIPS instructions, XORI and BNE. You will then write a new test program that confirms the new MIPS instructions work. In order to implement BNE you will have to make changes to the VHDL for the processor.  
* By the end of this lab, you should understand the internal operation of the MIPS single-cycle processor.
* _Please read and follow the instructions in this lab carefully.  In the past, many students have lost points for silly errors like failing to include screen snips of the simulation signal traces requested in the lab._

# MIPS Single-Cycle Processor
Before starting this lab, you should review the single-cycle implementation of the MIPS processor described in Section 7.3 of your text, covered in class lectures and supplied in this folder. The single-cycle processor schematic from the text is repeated here for your convenience:

![mips schematic](./img/mips_schematic.png)



This version of the MIPS single-cycle processor can execute the following instructions:  
```
add, addi, and, beq, j, lw, or, slt, sub, and sw
```

The VHDL for the single-cycle MIPS entity is given in Section 7.6.1 of the text and also in this project folder.  Although the VHDL in the text is very close to being correct, there have been changes made to the code so that it will work for both synthesis and simulation.  The most significant changes to the code are in the way the initial program loads into the FPGA’s internal RAM as we covered in class.


# Steps to Generate the MIPS Simulation and MIPS bitstream

1. At the bash terminal in vscode run the ./gen.sh command to generate the vivado simulation and bitstream.
2. Open the ./generated/ subfolder and find the ```MIPS_3_INDIVIDUAL.xpr``` file. Double-click on this file to open the generated project in vivado.

# Organization of MIPS 3

The highest-level entity for the mips processor itself is called mips_top, it contains the instruction memories and data memories and the processor itself.  Each of the memories is a 64-word × 32-bit array. The instruction memory needs to contain some initial values that represent the program to execute.  Go ahead an open the elaborated design then double click on the mips1 component. It should look like the following image at the top level.  

![mips top](./img/mips_top.jpg)

Notice that there is a data memory (dmem1), an instruction memory (imem1) and a mips processor (mips1). These are drawn in reverse order by Vivado (reverse from our original schematic) since mips also wires the output of _imem_ to the input of the hex display. The output of imem (carries the instruction read from imem) on a data bus that wraps back around and feeds into the instruction input of mips1.  Sadly, Vivado also draws the data memory on the left side of the image rather than the right. 

Now, expand the mips1 component. YHou should see this:

![mips1](./img/mips1.jpg)


Our architecture for the single-cycle MIPS processor divides the machine into two major components: 

1. The control unit (cont) and 
2. The datapath unit (dp)

Each of these major components is constructed hierarchically from various structural blocks.  For example, as shown in the first figure in this document, the datapath contains the 32-bit ALU, the register file, the sign extension logic, and five multiplexers that route data signals through the data path unit.

# The MIPS Control Unit

Go ahead and take a look at the _controller_ entity and it's components:

![control unit](./img/control_unit.jpg)

The controller contains two main components:
* Main decoder (md) this entity produces all control signals except those for the ALU.  
* ALU decoder (ad) This entity produces the controls signals, alucontrol[2:0], for the ALU.  
  
Make sure you thoroughly understand how the controller entity operates.  **Find and match the signal names given in the VHDL code for the control unit's port with the wires shown on the mips schematic (see the first MIPS schematic).**

Finally, take a look at the **datapath (dp)** VHDL entity.  The datapath has a lot of components.  You may find it easier look at the schematic given at the start of this document than at the elaborated design in Vivado, however, you still should be able to locate the same signals in both renderings.  

Make sure you understand the role of each component in the datapath unit, and where it resides on the MIPS single-cycle processor hardware schematic.  
# 
# Initial Test Program
# 

The MIPS project comes with the instruction memory preloaded with a memfile.dat that is contains the machine code for the following assembly language program called mipstest.asm.  
```
NOTE: This is very important to understand. The test program stored in memfile.dat has ONLY 8 digits per line. Each line consists of a hex number that can only contain digits and the lower case letters a,b,c,d,e,f.  In the future, when writing your own program, DO NOT put anything other than exactly 8 lower case hex digits on a line. If you don’t follow these rules, your program will not work and you may become confused as to why things won’t work correctly.
```

The current simulation project automatically reads and loads the machine code from the memfile.dat into the MIPS instruction memory **during the synthesis process**.  This allows students to run small programs directly on the FPGA without requiring them to implement a complex SDRAM interface.  The current code is stored in an array of STD_LOGIC_VECTOR that forms the instruction memory for the machine.  
 
![mips test program](./img/mips_program.png)

# The Memory Model Used for the MIPS 3 VHDL Processor
Because this simple mips processor was designed to run entirely on a single FPGA, we have used an extremely simple memory model for both the instruction memory and the data memory. 

The first instruction memory location starts at address 0x00000000. The same is true for the data memory. This differs from the actual MIPS architecture where the first instructions typically start at address 0x00400000. In the future, if you are able to integrate a memory controller into your processor you may wish to change this.    

# How the HEX Code Machine Language Program is loaded at Synthesis Time

To understand how loading hex code from memfile.dat into memory works, you need to examine the code in the ```mips_mem_instructions.vhd``` file  (double-click on the **imem** component in our VHDL project). The instruction memory consists of an array of 64 locations, each of which can store 32 bits. In this file we first define a hardware data type called ramtype:

```vhdl
   type ramtype is array (63 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
```

We then use this data type to initialize the ram array object during synthesis as follows:

```vhdl
  -- use the impure function to read RAM from a file and 
  -- store in the FPGA's ram memory
  signal mem: ramtype := InitRamFromFile("memfile_2.dat");
```
The function,  ```InitRamFromFile("memfile.dat")``` returns a RAM array to initialize the signal ```mem```. It does this by reading the data file ```memfile.dat```. The function creates 32 bit words in the mem array by reading one character at a time from the memfile.dat file. Each character represents a 4 bit hexadecimal value and after reading, is converted to a four bit integer. Each 4 bit integer is shifted into its correct position and added to a temporary result.  After constructing an entire temporary result (a 32 bit word) for each instruction, the code writes that instruction to the next instruction memory location in the RAM. After being initialized, the RAM is returned to initialize the ```mem```. Here is the code to initialize the instruction memory:

```vhdl
  -- function to initialize the instruction memory from a data file
  impure function InitRamFromFile ( RamFileName : in string ) return RamType is
  variable ch: character;
  variable index : integer;
  variable result: signed((width-1) downto 0);
  variable tmpResult: signed(63 downto 0);
  file mem_file: TEXT is in RamFileName;
  variable L: line;
  variable RAM : ramtype;
  begin
    -- initialize memory from a file
    for i in 0 to 63 loop -- set all contents low
      RAM(i) := std_logic_vector(to_unsigned(0, width));
    end loop;
    index := 0;
    while not endfile(mem_file) loop
      -- read the next line from the file
      readline(mem_file, L);
      result := to_signed(0,width);
      for i in 1 to 8 loop
        -- read character from the line just read
        read(L, ch);
        --  convert character to a binary value from a hex value
        if '0' <= ch and ch <= '9' then
          tmpResult := result*16 + character'pos(ch) - character'pos('0') ;
          result := tmpResult(31 downto 0);
        elsif 'a' <= ch and ch <= 'f' then
          tmpResult := result*16 + character'pos(ch) - character'pos('a')+10 ;
          result := tmpResult(31 downto 0);
        else report "Format error on line " & integer'image(index)
          severity error;
        end if;
      end loop;
      -- set the width bit binary value in ram
      RAM(index) := std_logic_vector(result);
      index := index + 1;
    end loop;
    -- return the array of instructions loaded in RAM
    return RAM;
  end function;
```

# Vivado Tips: Missing Files
* Sometimes files may end up “missing” in Vivado and you need to remove them from your project. 
* If this happens to you, right click on the hierachy and try to refresh it. 

# VHDL Data Conversion Tips
* When you examine the code, you will notice the various data type conversions and typecasts. 
* The next figure demonstrates how to convert (and typecast) between various data types in VHDL.

![mips test program](./img/vhdl_conversions.png)

# VHDL Test Bench Simulation

Inspect the testbench code: ```./sim_testbench/mips_testbench.vhd``` This is for simulation testing only and cannot be synthesized into hardware. It generates a simulated clock input and a simulated reset input for the device under test, ```mips_top```.  

1. Now run the simulation using vivado.  
2. Find Simulation Sources, browses to ```mips_testbench```, select it, and then run the Simulation. 
3. If you zoom the output window as shown below you should be able to verify the hex codes of the instructions as they are read from memory and displayed on the output port (that would connect to a hex display on the BASYS 3 board). 
4. Remember that the program has a "jump to main" at the end of the program and thus will continue to repeat over and over.   

![mips simulation program](./img/simulation.jpg)

# Use Vivado to Inspect the MIPS Instruction Memory

To verify that the correct hex machine code program was loaded into memory you should inspect the mips ```imem1``` memory in the simulator.  This should be one of the first things you do if you change the "program" you want to run on the VHDL processor.

### Steps to Inspect MIPS Memory
1. Start the Vivado simulator test bench.
2. At the top of te simulator window, set the run time to 10 ns.
3. Reset the simulation.
4. Run for 10 ns.
5. Use the *Scope* window of the Vivado simulator to drill down to the the ```imem1`` component and click to select it.
6. In the *Objects* windows, expand the ```mem`` object. Scroll to the bottom of the memory to see that your hex instructions were loaded correctly from the data file!
7. Don't forget that the instructions will start at 0 and proceed upwards in memory.

![inspect instruction memory in vivado mips simulation](./img/inspect_mips_instructions.png)

### Steps to Check Other Signals During Simulation
Start the Vivado simulator test bench then proceed as follows:
1. Drill down to the Data Path Unit (DP) and click on ```mainalu``` to select it.
2. Click and drag each one of ```alucontrol, a[31:0], b[31:0], and result[31:0]``` to the simulation trace window.
3. Now, each time you run the simulation, you will see these additional signals on the signal trace window.
   
![Adding other signals to signal trace window](./img/trace_instructions.png)


# MIPS_3-1 - Change MIPS Program (Individual) 

### Steps to Change the Machine Code for MIPS 3 
1. Create a machine code file and add the following machine code to it. I recommed using .dat as the extension. Do not leave any empty lines in the file!
   
    ```memfile_2.dat```
    ```
    20020005
    20070003
    2003000c
    00e22025
    00642824
    00a42820
    10a70008
    0064302a
    10c00001
    2005000a
    00e2302a
    00c53820
    00e23822
    0800000f
    8c070000
    ac470047
    ```
2. Modify ```mips_mem_instructions.vhd``` to load ```memfile_2.dat``` rather than ```memfile.dat```.
3. Here is a copy of the MIPS instructions that were assembled to machine code for ```memfile_2.dat```:
    ```mips
    #
    # Test MIPS instructions mipstest_2.asm
    # Assembly Code             # Machine Code
    main:	addi $2, $0, 5	    # 20020005
            addi $7, $0, 3	    # 20070003
            addi $3, $0, 0xc    # 2003000c
            or   $4, $7, $2     # 00e22025
            and  $5, $3, $4     # 00642824
            add  $5, $5, $4     # 00a42820
            beq  $5, $7, end    # 10a70008
            slt  $6, $3, $4     # 0064302a
            beq  $6, $0, around # 10c00001
            addi $5, $0, 10     # 2005000a
    around: slt  $6, $7, $2     # 00e2302a
            add  $7, $6, $5     # 00c53820
            sub  $7, $7, $2     # 00e23822
            j    end            # 0800000f
            lw   $7, 0($0)      # 8c070000
    end:    sw   $7, 71($2)     # ac470047

    ```
4. Run ```gen.sh`` to re-generate the simulation and bitstream. 
5. BEFORE running the simulation OR running the hardware vivado program,complete the following prediction task. 
   
In a complex system, if you don’t know what answer the system should produce, you won’t be able to debug the system. 
Begin by predicting what will happen for each instruction when running the program.  This means that you should follow any 
branches or jumps in your prediction! 

Here are some hints to help you. You will still need to study the architecture diagram and VHDL code to trace what is happening. 
* ```branch``` is asserted (1) when the instruction is a ```branch (beq)``` instruction. 
*  ```aluout``` is the output of the ALU at each cycle.  
* ```zero``` is high (1) only if ```aluout``` is 0.  
* ```pcsrc```, a signal in the datapath, is low (0) when the next value of the program counter ```nextpc``` should be the next instruction ```pc+4```.  
* ```pcsrc``` is high (1) when the ```nextpc``` should be set to the branch target address ```pcbranch```.

You will notice that all of these signals are not available from the top-level entity (mips).  For checking your answeers by simulation, 
you will need to drill down and look at these signals (and possibly others) and drag them to the simulation trace window in vivado.


### Complete the following 12 rows of the table and predict each of the following signals (look at the VHDL code and mips schematic to predict the program signals)

NOTE: Do NOT Correct this table after you make the predictions. You will have a chance to make the correct table later in this document.
   

| TIME | RESET | PCSRC | PC       | BRANCH | INSTR    | SRCA     | SRCB     | ALUOUT   | ZERO | WRITEDATA | MEMWRITE | READDATA |
| ---- | ----- | ----- | -------- | ------ | -------- | -------- | -------- | -------- | -----| --------- | -------- | -------- |
|  0 ns| 1     | 0     | 00000000 | 0      | 20020005 | 00000000 | 00000005 | 00000005 | 0    | UUUUUUUU  | 0        | UUUUUUUU |
| 20 ns| 1     | 0     | 00000000 | 0      | 20020005 | 00000000 | 00000005 | 00000005 | 0    | 00000005  | 0        | UUUUUUUU |
| 40 ns| 0     | 0     | 00000004 | 0      | 20070003 | 00000000 | 00000003 | 00000003 | 0    | UUUUUUUU  | 0        | UUUUUUUU |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|300 ns| 0     | 0     | 00000040 | 0      | 00000000 | 00000000 | 00000000 | 00000000 | 1    | 00000007  | 0        | UUUUUUUU |


# MIPS_3-2 - Compare Sim to Prediction (Individual)

Now, you will run the program in simulation and record the actual control signal values. You will compare your predictions to what actually happens. 
When running the simulation, you will not be able to see the resulting value in a destination register until the clock cycle AFTER the instruction has run! For example:
    ```
    Assume $4 has 3 in it. 
    Assume $5 has 4 in it.
    Assume that the microprocessor is currently running the instruction ```add $6, $5, $4``` 
    Then, on the signal trace you won't be able to see that $6 has 7 in it until the clock cycle immediately following the instruction.
    ```

A help in understanding what is going on is that you can drag any signal you want to see to the signal trace window. For example, you could, if you want 
drag the register memory location 4 to the signal trace and watch it change during the simulation run.


### Exercise MIPS_3-2 Steps. Read these carefully!

For debugging, you will need to make other signals from sub-components visible in the trace window of the ISIM simulator.  To do this, expand the testbench entity in the Instance and Process Name window by clicking on the triangle beside it.  Now, expand the dut (device under test) entity, followed by the mips1 entity, followed by the cont (controller) entity.  Within the cont entity you will see the ad (alu decoder) entity and the md (main decoder) entity.  Click and drag the md (main decoder) entity to the waveform window. Also click and drag the ad (alu decoder) entity to the waveform window as well.  

Now that you have the controller entity signals on the waveform window, you will need to restart the simulation to update the waveform.  Run the simulation in 20ns steps. Make sure your signals are appearing correctly.

* You can remove signals from the waveform window by right-clicking on them.  
* You can also change how signals are displayed on the waveform window by right-clicking and selecting a hexadecimal radix.
* You can change the order of the signals on the waveform by dragging them to a new position. 

For this assignment must have the exact signals in the order described below. 

1. Setup the Waveform Trace with the Required Signals for Exercise MIPS3_2. To do this, add the following signals in this exact order:  
   ```
   clk,  reset, pcsrc,  pc,  branch, instr, srca, srcb,  aluout,  zero, writedata,  memwrite, readdata
   ```

2. Screen Snip the Waveform Trace Displays:
For multi-bit signal values, make sure the signal trace shows these as hexadecimal values. They must also be readable to be awarded full credit! 

A.	Screen snip and insert a waveform trace from  0 ns to 60 ns here:

B.	Screen snip and insert a waveform trace from  60 ns to 120 ns here:

C.	Screen snip and insert a waveform trace from 120 ns to 180 ns here:

D.	Screen snip and insert a waveform trace from 180 ns to 240 ns here:

E.	Screen snip and insert a waveform trace from 240 ns to 300 ns here:

3.  Use the signals from the screen snips (or from the simulator) to complete the follow table 
   
| TIME | RESET | PCSRC | PC       | BRANCH | INSTR    | SRCA     | SRCB     | ALUOUT   | ZERO | WRITEDATA | MEMWRITE | READDATA |
| ---- | ----- | ----- | -------- | ------ | -------- | -------- | -------- | -------- | -----| --------- | -------- | -------- |
|  0 ns| 1     | 0     | 00000000 | 0      | 20020005 | 00000000 | 00000005 | 00000005 | 0    | UUUUUUUU  | 0        | UUUUUUUU |
| 20 ns| 1     | 0     | 00000000 | 0      | 20020005 | 00000000 | 00000005 | 00000005 | 0    | 00000005  | 0        | UUUUUUUU |
| 40 ns| 0     | 0     | 00000004 | 0      | 20070003 | 00000000 | 00000003 | 00000003 | 0    | UUUUUUUU  | 0        | UUUUUUUU |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|      |       |       |          |        |          |          |          |          |      |           |          |          |
|300 ns| 0     | 0     | 00000040 | 0      | 00000000 | 00000000 | 00000000 | 00000000 | 1    | 00000007  | 0        | UUUUUUUU |


### Discussion of Prediction vs Simulation

```

In this area discuss if your predictions matched reality. Did you predict correctly? What mistakes did you make (if any)?


```


### Exercise MIPS_3-3 MIPS Running on BASYS 3

This folder has a MIPS processor wired to the FPGA's 4, 7-segment displays.  The 7-segment displays shows the top 4 bytes of the machine code program that’s currently running. 

•	This has a process that generates a very slow clock (around 1 or 2 secs)
•	Every clock cycle the processor outputs the instruction HEX code to the LEDs.
•	Switch 0 is the reset signal. If you switch it on, the program counter will reset to zero and the first instruction code will be displayed. Switch it off and the program will continue running.
•	It also outputs selected bits to the single LEDs ( these can be changed and are helpful for debugging).

The actual program will eventully run out of instructions. If you wait long enough, it will cycle through all the 00000000 instructions and wrap back around and start at instruction 0 again.

STEP 1: Load the bistream for the current program into the fpga.  Run the program and record the HEX codes here:

STEP 2: Do the instruction HEX codes match those in the simulation? Why or Why not?

STEP 3: Increse the clock speed by a factor of 4. To do this, identify the clock divider VHDL hardware that generates the clock signal for the mips processor. Change the output signal from this clock so that it quadruples the clock speed from its current value. Synthesize and verify that the program runs four times as fast. 

STEP 5: Paste the code you modified to double the clock speed here:

```vhdl

-- Put your VHDL code that you modified here


```

