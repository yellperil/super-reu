module chameleon2 (
// Clocks
		   input clk50m,
		   input phi2_n,
		   input dotclk_n,

// Buttons
		   input usart_cts,  // Left button
		   input freeze_btn, // Middle button
		   input reset_btn,  // Right

// PS/2, IEC, LEDs
		   input iec_present,

		   output ps2iec_sel,
		   input[3:0] ps2iec,

		   output ser_out_clk,
		   output ser_out_dat,
		   output ser_out_rclk,

		   output iec_clk_out,
		   output iec_srq_out,
		   output iec_atn_out,
		   output iec_dat_out,

// SPI, Flash and SD-Card
		   output flash_cs,
		   output rtc_cs,
		   output mmc_cs,
		   input mmc_cd,
		   input mmc_wp,
		   output spi_clk,
		   input spi_miso,
		   output spi_mosi,

// Clock port
		   output clock_ior,
		   output clock_iow,

// C64 bus
		   input reset_in,

		   input ioef,
		   input romlh,

		   output dma_out,
		   output game_out,
		   output exrom_out,

		   input irq_in,
		   output irq_out,
		   input nmi_in,
		   output nmi_out,
		   input ba_in,
		   input rw_in,
		   output rw_out,

		   output sa_dir,
		   output sa_oe,
		   output sa15_out,
		   inout[15:0] low_a,

		   output sd_dir,
		   output sd_oe,
		   inout[7:0] low_d,

// SDRAM
		   output ram_clk,
		   output ram_ldqm,
		   output ram_udqm,
		   output ram_ras,
		   output ram_cas,
		   output ram_we,
		   output[1:0] ram_ba,
		   output[12:0] ram_a,
		   inout[15:0] ram_d,

// IR eye
		   input ir_data,

// USB micro
		   input usart_clk,
		   input usart_rts,
		   output usart_rx,
		   input usart_tx,

// Video output
		   output[4:0] red,
		   output[4:0] grn,
		   output[4:0] blu,
		   output hsync_n,
		   output vsync_n,

// Audio output
		   output sigma_l,
		   output sigma_r
		   );

   // inout defaults
   assign low_a = 16'bZZZZZZZZZZZZZZZZ;
   assign low_d = 8'bZZZZZZZZ;
   assign ram_d = 16'bZZZZZZZZZZZZZZZZ;

   // output defaults
   assign ps2iec_sel = 1'b0;
   assign ser_out_clk = 1'b0;
   assign ser_out_dat = 1'b0;
   assign ser_out_rclk = 1'b1;
   assign iec_clk_out = 1'b0;
   assign iec_srq_out = 1'b0;
   assign iec_atn_out = 1'b0;
   assign iec_dat_out = 1'b0;
   assign flash_cs = 1'b1;
   assign rtc_cs = 1'b0;
   assign mmc_cs = 1'b1;
   assign spi_clk = 1'b0;
   assign spi_mosi = 1'b0;
   assign clock_ior = 1'b1;
   assign clock_iow = 1'b1;
   assign dma_out = 1'b0;
   assign game_out = 1'b0;
   assign exrom_out = 1'b0;
   assign irq_out = 1'b0;
   assign nmi_out = 1'b0;
   assign rw_out = 1'b0;
   assign sa_dir = 1'b0;
   assign sa_oe = 1'b0;
   assign sa15_out = 1'b0;
   assign sd_dir = 1'b0;
   assign sd_oe = 1'b0;
   assign ram_clk = 1'b0;
   assign ram_ldqm = 1'b0;
   assign ram_udqm = 1'b0;
   assign ram_ras = 1'b0;
   assign ram_cas = 1'b0;
   assign ram_we = 1'b0;
   assign ram_ba = 2'b00;
   assign ram_a = 13'b0000000000000;
   assign usart_rx = 1'b1;
   assign red = 5'b00000;
   assign grn = 5'b00000;
   assign blu = 5'b00000;
   assign hsync_n = 1'b0;
   assign vsync_n = 1'b0;
   assign sigma_l = 1'b0;
   assign sigma_r = 1'b0;

endmodule // chameleon2
