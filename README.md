# FPGA-for-Robotics-Education-code_examples

Eric Schwarz Iglesias
ECE 484/485 Senior Design
Team 4: FPGA for Robotics Education

This directory is the software packet that contains all the software examples to interface the TI-RSLK-MAX with the WebFPGA. In this directory there are folders for each individual example as well as a file containing the official pinmap and instructions on how to use it. In every example folder there are two verilog files and a bitstream. 

One of the verilog files contains the top module while the other one has aiding modules that get instantiated. If using the WEB IDE, these need to be copied and pasted together. If using the CLI, these files can be synthesized together. The bitstream is a file that contains the presented verilog files pre synthesized and ready to flash.
