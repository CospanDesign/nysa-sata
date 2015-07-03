import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge

CLK_PERIOD = 4
RESET_PERIOD = 100

class SataController(object):

    def __init__(self, dut, period = CLK_PERIOD):
        self.dut = dut
        self.dut.log.warning("Setup Sata")
        cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
        self.dut.rst = 0
        self.dut.prim_scrambler_en = 1
        self.dut.data_scrambler_en = 1

    @cocotb.coroutine
    def wait_clocks(self, num_clks):
        for i in range(num_clks):
            yield RisingEdge(self.dut.clk)

    @cocotb.coroutine
    def reset(self):
        self.dut.rst = 0
        #self.dut.write_data_stb = 0
        self.dut.hard_drive_command = 0x00
        self.dut.execute_command_stb = 0
        #self.dut.read_data_stb = 0
        self.dut.command_layer_reset = 0
        self.dut.sector_count = 0
        self.dut.sector_address = 0
        self.dut.fifo_reset = 0

        self.dut.hold = 0
        self.dut.single_rdwr = 0
        self.dut.platform_ready = 0

        self.dut.u2h_write_enable = 0
        self.dut.u2h_write_count = 0
        self.dut.h2u_read_enable = 0

        self.dut.hd_read_enable = 0;
        self.dut.user_read_enable = 0;


        yield(self.wait_clocks(RESET_PERIOD / 2))
        self.dut.rst = 1

        yield(self.wait_clocks(RESET_PERIOD / 2))
        self.dut.rst = 0

        yield(self.wait_clocks(100))
        self.dut.platform_ready = 1

        yield(self.wait_clocks(10))

    def ready(self):
        if self.dut.sata_ready == 1:
            return True
        return False

    @cocotb.coroutine
    def wait_for_idle(self):
        print "Wait for idle..."
        if self.dut.sata_busy.value == 1:
            yield(cocotb.triggers.FallingEdge(self.dut.sata_busy))
        if self.dut.sata_ready.value == 0:
            yield(cocotb.triggers.RisingEdge(self.dut.sata_ready))
        print "Idle!"

    @cocotb.coroutine
    def write_to_hard_drive(self, length, address):
        #self.dut.u2h_write_enable = 1
        self.dut.u2h_write_count = length
        #self.dut.h2u_read_enable = 1
        self.dut.sector_address = address
        #What does this do?
        self.dut.sector_count = (length / 8192) + 1
        self.dut.hard_drive_command = 0x35
        print "Write!"


        yield(self.wait_clocks(10))
        self.dut.execute_command_stb = 1
        #self.dut.write_data_stb = 1
        yield(self.wait_clocks(1))
        #self.dut.write_data_stb = 0
        self.dut.execute_command_stb = 0
        yield(self.wait_for_idle())
        yield(self.wait_clocks(100))
        #self.dut.h2u_read_enable = 0
        self.dut.hard_drive_command = 0x00

    @cocotb.coroutine
    def read_from_hard_drive(self, length, address):
        self.dut.sector_address = address
        sector_count = (length / 0x800) + 1
        self.dut.sector_count = sector_count
        #Initiate pattern generation within the data generators
        #Also tell the reader to analyze the incomming data
        self.dut.h2u_read_enable = 1
        yield(self.wait_clocks(10))

        print "Read..."
        #self.dut.read_data_stb = 1
        self.dut.hard_drive_command = 0x25
        self.dut.execute_command_stb = 1
        yield(self.wait_clocks(1))
        #self.dut.read_data_stb = 0
        self.dut.execute_command_stb = 0
        yield(self.wait_clocks(100))
        while (self.dut.h2u_read_total_count.value < length):
            if self.dut.sata_ready.value == 1:
                #self.dut.read_data_stb = 1
                self.dut.execute_command_stb = 1
                yield(self.wait_clocks(1))
                #self.dut.read_data_stb = 0
                self.dut.execute_command_stb = 0
                yield(self.wait_clocks(10))

            yield(self.wait_clocks(100))
            self.dut.log.info("count: %d" % self.dut.h2u_read_total_count.value)

        self.dut.h2u_read_enable = 0

