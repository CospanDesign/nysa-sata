`timescale 1ns/1ps

`include "sata_defines.v"

module tb_cocotb (

//Parameters
//Registers/Wires
input               rst,            //reset
input               clk,

output              linkup,           //link is finished
output              sata_ready,
output              busy,

input               write_data_en,
input               read_data_en,

input               soft_reset_en,
input       [15:0]  sector_count,
input       [47:0]  sector_address,

output              d2h_interrupt,
output              d2h_notification,
output      [3:0]   d2h_port_mult,
output      [7:0]   d2h_device,
output      [47:0]  d2h_lba,
output      [15:0]  d2h_sector_count,
output      [7:0]   d2h_status,
output      [7:0]   d2h_error,


input       [31:0]  user_din,
input               user_din_stb,
output      [1:0]   user_din_ready,
input       [1:0]   user_din_activate,
output      [23:0]  user_din_size,

output      [31:0]  user_dout,
output              user_dout_ready,
input               user_dout_activate,
input               user_dout_stb,
output      [23:0]  user_dout_size,


output              transport_layer_ready,
output              link_layer_ready,
output              phy_ready,

input               prim_scrambler_en,
input               data_scrambler_en,

//Data Interface
output              tx_set_elec_idle,
output              rx_is_elec_idle,
output              hd_ready,
input               platform_ready,

//Debug
input               hold,

input               single_rdwr

);
reg     [31:0]      test_id = 0;

wire    [31:0]      tx_dout;
wire                tx_isk;
wire                tx_comm_reset;
wire                tx_comm_wake;
wire                tx_elec_idle;

wire    [31:0]      rx_din;
wire    [3:0]       rx_isk;
wire                rx_elec_idle;
wire                comm_init_detect;
wire                comm_wake_detect;

wire                rx_byte_is_aligned;

reg                 r_rst;
reg                 r_write_data_en;
reg                 r_read_data_en;
reg                 r_soft_reset_en;
reg                 r_sector_count;
reg                 r_sector_address;
reg                 r_user_din;
reg                 r_user_din_stb;
reg                 r_user_din_activate;
reg                 r_user_dout_activate;
reg                 r_user_dout_stb;
reg                 r_prim_scrambler_en;
reg                 r_data_scrambler_en;
reg                 r_platform_ready;
reg                 r_dout_count;
reg                 r_hold;
reg                 r_single_rdwr;


//There is a bug in COCOTB when stiumlating a signal sometimes it can be corrupted if not registered
always @ (*) r_rst                = rst;
always @ (*) r_write_data_en      = write_data_en;
always @ (*) r_read_data_en       = read_data_en;
always @ (*) r_soft_reset_en      = soft_reset_en;
always @ (*) r_sector_count       = sector_count;
always @ (*) r_sector_address     = sector_address;
always @ (*) r_user_din           = user_din;
always @ (*) r_user_din_stb       = user_din_stb;
always @ (*) r_user_din_activate  = user_din_activate;
always @ (*) r_user_dout_activate = user_dout_activate;
always @ (*) r_user_dout_stb      = user_dout_stb;
always @ (*) r_prim_scrambler_en  = prim_scrambler_en;
always @ (*) r_data_scrambler_en  = data_scrambler_en;
always @ (*) r_platform_ready     = platform_ready;
always @ (*) r_hold               = hold;
always @ (*) r_single_rdwr        = single_rdwr;



//Submodules

sata_stack ss (
  .rst                   (r_rst                ),  //reset
  .clk                   (clk                  ),  //clock used to run the stack
  .data_in_clk           (clk                  ),
  .data_in_clk_valid     (1'b1                 ),
  .data_out_clk          (clk                  ),
  .data_out_clk_valid    (1'b1                 ),

  .platform_ready        (platform_ready       ),  //the underlying physical platform is
  .linkup                (linkup               ),  //link is finished
  .sata_ready            (sata_ready           ),

  .busy                  (busy                 ),

  .write_data_en         (r_write_data_en      ),
  .single_rdwr           (r_single_rdwr        ),
  .read_data_en          (r_read_data_en       ),

  .send_user_command_stb (1'b0                 ),
  .soft_reset_en         (r_soft_reset_en      ),
  .command               (1'b0                 ),

  .sector_count          (r_sector_count       ),
  .sector_address        (r_sector_address     ),

  .d2h_interrupt         (d2h_interrupt        ),
  .d2h_notification      (d2h_notification     ),
  .d2h_port_mult         (d2h_port_mult        ),
  .d2h_device            (d2h_device           ),
  .d2h_lba               (d2h_lba              ),
  .d2h_sector_count      (d2h_sector_count     ),
  .d2h_status            (d2h_status           ),
  .d2h_error             (d2h_error            ),

  .user_din              (r_user_din           ),   //User Data Here
  .user_din_stb          (r_user_din_stb       ),   //Strobe Each Data word in here
  .user_din_ready        (user_din_ready       ),   //Using PPFIFO Ready Signal
  .user_din_activate     (r_user_din_activate  ),   //Activate PPFIFO Channel
  .user_din_size         (user_din_size        ),   //Find the size of the data to write to the device

  .user_dout             (user_dout            ),
  .user_dout_ready       (user_dout_ready      ),
  .user_dout_activate    (r_user_dout_activate ),
  .user_dout_stb         (r_user_dout_stb      ),
  .user_dout_size        (user_dout_size       ),

  .transport_layer_ready (transport_layer_ready),
  .link_layer_ready      (link_layer_ready     ),
  .phy_ready             (phy_ready            ),

  .tx_dout               (tx_dout              ),
  .tx_isk                (tx_isk               ),
  .tx_comm_reset         (tx_comm_reset        ),
  .tx_comm_wake          (tx_comm_wake         ),
  .tx_elec_idle          (tx_elec_idle         ),

  .rx_din                (rx_din               ),
  .rx_isk                (rx_isk               ),
  .rx_elec_idle          (rx_elec_idle         ),
  .comm_init_detect      (comm_init_detect     ),
  .comm_wake_detect      (comm_wake_detect     ),
  .rx_byte_is_aligned    (rx_byte_is_aligned   ),


  .prim_scrambler_en     (r_prim_scrambler_en  ),
  .data_scrambler_en     (r_data_scrambler_en  )
);

faux_sata_hd  fshd   (
  .rst                   (r_rst                ),
  .clk                   (clk                  ),
  .tx_dout               (rx_din               ),
  .tx_isk                (rx_isk               ),

  .rx_din                (tx_dout              ),
  .rx_isk                ({3'b000, tx_isk}     ),
  .rx_is_elec_idle       (tx_elec_idle         ),
  .rx_byte_is_aligned    (rx_byte_is_aligned   ),

  .comm_reset_detect     (tx_comm_reset        ),
  .comm_wake_detect      (tx_comm_wake         ),

  .tx_comm_reset         (comm_init_detect     ),
  .tx_comm_wake          (comm_wake_detect     ),

  .hd_ready              (hd_ready             ),
//  .phy_ready             (phy_ready            ),


  .dbg_data_scrambler_en (r_data_scrambler_en  ),

  .dbg_hold              (r_hold               ),

  .dbg_ll_write_start    (0                    ),
  .dbg_ll_write_data     (0                    ),
  .dbg_ll_write_size     (0                    ),
  .dbg_ll_write_hold     (0                    ),
  .dbg_ll_write_abort    (0                    ),

  .dbg_ll_read_ready     (0                    ),
  .dbg_t_en              (0                    ),

  .dbg_send_reg_stb      (0                    ),
  .dbg_send_dma_act_stb  (0                    ),
  .dbg_send_data_stb     (0                    ),
  .dbg_send_pio_stb      (0                    ),
  .dbg_send_dev_bits_stb (0                    ),

  .dbg_pio_transfer_count(0                    ),
  .dbg_pio_direction     (0                    ),
  .dbg_pio_e_status      (0                    ),

  .dbg_d2h_interrupt     (0                    ),
  .dbg_d2h_notification  (0                    ),
  .dbg_d2h_status        (0                    ),
  .dbg_d2h_error         (0                    ),
  .dbg_d2h_port_mult     (0                    ),
  .dbg_d2h_device        (0                    ),
  .dbg_d2h_lba           (0                    ),
  .dbg_d2h_sector_count  (0                    ),

  .dbg_cl_if_data        (0                    ),
  .dbg_cl_if_ready       (0                    ),
  .dbg_cl_if_size        (0                    ),
  .dbg_cl_of_ready       (0                    ),
  .dbg_cl_of_size        (0                    ),
  .hd_data_to_host       (hd_data_to_host      )


);

//Asynchronous Logic
assign  hd_data_to_host               = 32'h01234567;


//Synchronous Logic
//Simulation Control
initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_cocotb);
end

endmodule
