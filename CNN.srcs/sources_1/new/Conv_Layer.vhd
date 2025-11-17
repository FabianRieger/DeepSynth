----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/06/2025 05:42:06 PM
-- Design Name: 
-- Module Name: Conv_Layer - Behavioral
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




-- Kernelwerte müssen vorher in  22 Bit Festkomma 1.5.16 kovnvertiert werden
entity Conv_Layer is

generic (
        WIDTH  : integer := 640;
        HEIGHT : integer := 480;
        KERNEL_SIZE: integer :=3;         --Kernel Size
        Stride: integer := 1;
        CHANNELS: integer := 3;           -- Anzahl channels (rgb = 3) Funktioniert momentan nur mit 3
        
        TOTAL_BITS_WEIGHT : integer := 25;        --Auflösung der Werte
        FRAC_BITS_WEIGHT : integer := 16;       -- Nachkommastellen
        INT_BITS_WEIGHT : integer := 8;         -- Ganzzahlstellen (ohne Vorzeichen)
        
        TOTAL_BITS_IN : integer := 8;
        INT_BITS_IN: integer := 8;
        FRAC_BITS_IN : integer := 0;
        
         -- Convolution Parameter
        MAX_KERNEL_VALUE: integer := integer(ceil(log2(real(9))))  -- Maximale Wert Eines Kernel Inhalts
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        pixel_in   : in  std_logic_vector(CHANNELS*TOTAL_BITS_IN - 1 downto 0);
        valid_in   : in  std_logic;
        valid_in_kernel: in std_logic;
        kernel_in  : in std_logic_vector(TOTAL_BITS_WEIGHT*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0);
        pixel_out  : out std_logic_vector(integer(ceil(log2(real(2**(INT_BITS_WEIGHT*2)*KERNEL_SIZE**2*CHANNELS))))+FRAC_BITS_WEIGHT +1 -1 downto 0);
        valid_out  : out std_logic;
        ctrl_in    : in std_logic;
        --ctrl_out   : out std_logic;
        valid_linebuffer: out std_logic;
        row_ptr         : in unsigned(integer(ceil(log2(real(HEIGHT)))) downto 0);
        col_ptr         : in unsigned(integer(ceil(log2(real(WIDTH)))) downto 0)
    );

end Conv_Layer;

architecture Behavioral of Conv_Layer is


-- Signals to connect internal modules
    signal window_out : std_logic_vector(TOTAL_BITS_IN*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0); -- 3x3 Fenster (9 Pixel à 24bit)
    signal valid_window : std_logic;

    signal window_in : std_logic_vector(TOTAL_BITS_IN*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0); -- 3x3 Fenster (9 Pixel à 24bit)
    signal valid_window_in : std_logic;
    
begin

    window_in <= window_out;
    valid_window_in <= valid_window;
    valid_linebuffer <= valid_window;

    -- Linebuffer instanzieren
    u_linebuffer : entity work.linebuffer_same_padding
        generic map (
            IMAGE_WIDTH => WIDTH,
            IMAGE_HEIGHT => HEIGHT,
            KERNEL_SIZE => kernel_size,
            CHANNELS => CHANNELS,
            TOTAL_BITS => TOTAL_BITS_IN,
            STRIDE => Stride
        )
        port map (
            clk          => clk,
            rst          => rst,
            pixel_in     => pixel_in,
            valid_in     => valid_in,
            ctrl_in      => ctrl_in,
            --ctrl_out     => ctrl_out,
            row_ptr     => row_ptr,
            col_ptr     => col_ptr,
            window_out   => window_out,
            valid_out => valid_window
        );

    -- Convolution Core instanzieren
    u_conv_core : entity work.conv2d_core
        generic map(
            kernel_size => kernel_size,
            TOTAL_BITS_IN => TOTAL_BITS_IN,
            INT_BITS_IN => INT_BITS_IN,
            FRAC_BITS_IN => FRAC_BITS_IN,
            channels => CHANNELS,
            FRAC_BITS =>  FRAC_BITS_WEIGHT,    
            INT_BITS =>   INT_BITS_WEIGHT,    
            TOTAL_BITS => TOTAL_BITS_WEIGHT,
            MAX_KERNEL_VALUE => MAX_KERNEL_VALUE
        )
        port map (
            clk         => clk,
            rst         => rst,
            window_in   => window_in,
            kernel_in   => kernel_in,
            valid_in    => valid_window_in,
            valid_in_kernel => valid_in_kernel,
            pixel_out   => pixel_out,
            valid_out   => valid_out
        );
        
end Behavioral;
