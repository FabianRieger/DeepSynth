----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/26/2025 02:52:34 PM
-- Design Name: 
-- Module Name: Conv_Block - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Conv_Block is
    generic (
            WIDTH  : integer := 640;
            HEIGHT : integer := 480;
            KERNEL_SIZE: integer :=3;         
            STRIDE: integer := 1;
            CHANNELS: integer := 3;   
            CHANNELS_PER_BLOCK: integer := 3;   
            FILTERS: integer := 1;     
            
            TOTAL_BITS_WEIGHT : integer := 25;        --Auflösung der Werte
            FRAC_BITS_WEIGHT : integer := 16;       -- Nachkommastellen
            INT_BITS_WEIGHT : integer := 8;         -- Ganzzahlstellen (ohne Vorzeichen)
            
            TOTAL_BITS_IN : integer := 8;
            INT_BITS_IN: integer := 8;
            FRAC_BITS_IN : integer := 0;
            
            ACC_WIDTH: integer := 64;               -- Weite nach aufaddierung aller channels
            
             -- Convolution Parameter
            MAX_KERNEL_VALUE: integer := integer(ceil(log2(real(9))))  -- Maximale Wert Eines Kernel Inhalts
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            valid_in   : in  std_logic;
            pixel_in   : in  std_logic_vector(CHANNELS*TOTAL_BITS_IN - 1 downto 0);           
            --valid_in_kernel: in std_logic;
            kernel_pool     : in  std_logic_vector(FILTERS*CHANNELS*KERNEL_SIZE*KERNEL_SIZE*TOTAL_BITS_WEIGHT-1 downto 0);
            valid_out  : out std_logic;
            pixel_out  : out std_logic_vector(ACC_WIDTH-1 downto 0);
            ctrl_in_buffer: in std_logic;
            ctrl_out_buffer: out std_logic
        );
end Conv_Block;

architecture Behavioral of Conv_Block is

constant ADD_WIDTH: integer := integer(ceil(log2(real(2**INT_BITS_WEIGHT*2**INT_BITS_IN*KERNEL_SIZE**2*CHANNELS))))+FRAC_BITS_WEIGHT +1;
--Noch falsch:
--constant ACC_WIDTH: integer :=  integer((ceil(log2(real(CHANNELS/CHANNELS_PER_BLOCK)*2**ADD_WIDTH))));

signal kernel : std_logic_vector(TOTAL_BITS_WEIGHT*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0);
signal linebuffer: std_logic;
signal valid_kernel: std_logic;
signal valid_acc: std_logic;
signal data_acc: std_logic_vector(ADD_WIDTH -1 downto 0); -- ADD_WIDTH berechnen
signal last_acc: std_logic;
signal filter_sel: unsigned(integer(ceil(log2(real(FILTERS)))) downto 0);
signal channel_block: unsigned(integer(ceil(log2(real(CHANNELS/CHANNELS_PER_BLOCK)))) downto 0);
signal ctrl_in_conv: std_logic;
signal ctrl_out_conv: std_logic;
signal row_ptr         : unsigned(integer(ceil(log2(real(HEIGHT)))) downto 0);
signal col_ptr         : unsigned(integer(ceil(log2(real(WIDTH)))) downto 0);

begin
    
    u_conv_layer : entity work.Conv_Layer
        generic map(
            WIDTH => WIDTH,
            HEIGHT => HEIGHT,
            KERNEL_SIZE => KERNEL_SIZE,
            STRIDE => STRIDE,
            CHANNELS => CHANNELS_PER_BLOCK,
            TOTAL_BITS_IN => TOTAL_BITS_IN,
            INT_BITS_IN => INT_BITS_IN,
            FRAC_BITS_IN => FRAC_BITS_IN,
            FRAC_BITS_WEIGHT =>  FRAC_BITS_WEIGHT,    
            INT_BITS_WEIGHT =>   INT_BITS_WEIGHT,    
            TOTAL_BITS_WEIGHT => TOTAL_BITS_WEIGHT,
            MAX_KERNEL_VALUE => MAX_KERNEL_VALUE
        )
        port map (
            clk         => clk,
            rst         => rst,
            kernel_in   => kernel,
            pixel_in    => pixel_in,
            valid_in    => valid_in,
            valid_linebuffer => linebuffer,
            valid_in_kernel => valid_kernel,
            pixel_out   => data_acc,
            valid_out   => valid_acc,
            ctrl_in => ctrl_out_conv, 
            --ctrl_out => ctrl_in_conv,
            row_ptr     => row_ptr,
            col_ptr     => col_ptr
        );


    u_akkumulator : entity work.accumulator_pingpong
        generic map(
            WIDTH       => ADD_WIDTH,
            ACC_WIDTH   => ACC_WIDTH
          )
        port map(
            clk         => clk,
            rst         => rst,
            tvalid      => valid_acc,
            tlast       => last_acc,
            tdata       => data_acc,
            out_valid   => valid_out,
            out_data    => pixel_out
          );
          
    u_kernel_mux : entity work.kernel_block_mux
        generic map(
            DATA_WIDTH         => TOTAL_BITS_WEIGHT,
            KERNEL_SIZE        => KERNEL_SIZE,
            CHANNELS_TOTAL     => CHANNELS,
            CHANNELS_PER_BLOCK => CHANNELS_PER_BLOCK,
            FILTERS_TOTAL      => FILTERS
          )
          port map(
            clk           => clk,
            rst           => rst,
            valid_out     => valid_kernel,
            filter_sel    => filter_sel,
            channel_block => channel_block,
            kernel_pool   => kernel_pool,
            kernel_out    => kernel
          );
  
    u_conv_control : entity work.conv_control
        generic map(
            CHANNELS_TOTAL     => CHANNELS,
            CHANNELS_PER_BLOCK => CHANNELS_PER_BLOCK,
            FILTERS_TOTAL      => FILTERS,
            WIDTH => WIDTH,
            HEIGHT => HEIGHT,
            STRIDE => STRIDE,
            KERNEL_SIZE => KERNEL_SIZE
          )      
        port map( 
            clk             => clk,
            rst             => rst,
            row_ptr         => row_ptr,
            col_ptr         => col_ptr,
            ctrl_out_conv   => ctrl_out_conv,
            ctrl_in_buffer  => ctrl_in_buffer,
            ctrl_out_buffer => ctrl_out_buffer,
            valid_in_write => valid_in,
            t_last          => last_acc,
            valid_buffer    => linebuffer,
            filter_sel      => filter_sel,
            channel_block   => channel_block
            );

end Behavioral;
