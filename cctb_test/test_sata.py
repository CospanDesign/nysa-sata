# Simple tests for an adder module
import cocotb
from cocotb.result import TestFailure
#from cocotb.triggers import Timer, RisingEdge
from sata_model import SataController
#import random

CLK_PERIOD = 1000

@cocotb.test()
def initial_test(dut):
    sata = SataController(dut, CLK_PERIOD)
    yield(sata.reset())

    yield(sata.wait_clocks(10000))
    dut.log.info("Ok!")

