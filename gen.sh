#!/bin/bash

if ! command -v vivado &> /dev/null
then
    echo "Please add the vivado folder to the system path!"
    echo "It should look similar to this in the windows path: C:\Xilinx\Vivado\2020.1\bin\ "
    echo "It should look similar to this in your .bash_profile: /c/Xilinx/Vivado/2020.1/bin/"
else
    vivado -mode batch -source ./setup_project.tcl
fi