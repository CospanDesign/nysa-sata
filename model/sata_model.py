import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge

CLK_PERIOD = 4

class SataController(object):

    def __init__(self, dut, period = CLK_PERIOD):
        self.dut = dut
        self.dut.log.warning("Setup Sata")
        cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
        self.dut.rst = 0

    @cocotb.coroutine
    def wait_clocks(self, num_clks):
        for i in range(num_clks):
            yield RisingEdge(self.dut.clk)

    @cocotb.coroutine
    def reset(self):
        self.dut.rst = 0
        yield(self.wait_clocks(10))
        self.dut.rst = 1

        self.dut.write_data_en = 0
        self.dut.read_data_en = 0
        self.dut.soft_reset_en = 0
        self.dut.sector_count = 0
        self.dut.sector_address = 0

        self.dut.user_din = 0
        self.dut.user_din_stb = 0
        self.dut.user_din_activate = 0

        self.dut.user_dout_activate = 0
        self.dut.user_dout_stb = 0

        self.dut.sin_count = 0
        self.dut.dout_count = 0
        self.dut.hold = 0
        self.dut.single_rdwr = 0
        self.dut.platform_ready = 0

        yield(self.wait_clocks(10))
        self.dut.rst = 0

        yield(self.wait_clocks(100))
        self.dut.platform_ready = 1

        yield(self.wait_clocks(10))
        self.dut.soft_reset_en = 1
        yield(self.wait_clocks(10))
        self.dut.soft_reset_en = 0

    def ready(self):
        if self.dut.sata_ready == 1:
            return True
        return False

    @cocotb.coroutine
    def wait_for_idle(self):
        cocotb.triggers.RisingEdge(self.dut.sata_ready)
