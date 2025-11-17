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
entity Max_Pooling_Layer is

generic (
        WIDTH  : integer := 640;
        HEIGHT : integer := 480;
        kernel_size: integer :=3;         --Kernel Size
        pixeldeepth: integer := 8;         -- Pixeltiefe
        Stride: integer := 1
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        pixel_in   : in  std_logic_vector(3*pixeldeepth-1 downto 0);
        valid_in   : in  std_logic;
        pixel_out  : out std_logic_vector(3*pixeldeepth-1 downto 0);
        valid_out  : out std_logic
    );

end Max_Pooling_Layer;

architecture Behavioral of Max_Pooling_Layer is


-- Signals to connect internal modules
    signal window_out : std_logic_vector(kernel_size*kernel_size*pixeldeepth*3 - 1 downto 0); -- 3x3 Fenster (9 Pixel à 24bit)
    signal valid_window : std_logic;

    signal window_in : std_logic_vector(kernel_size*kernel_size*pixeldeepth*3 - 1 downto 0); -- 3x3 Fenster (9 Pixel à 24bit)
    signal valid_window_in : std_logic;
    
begin

    window_in <= window_out;
    valid_window_in <= valid_window;

    -- Linebuffer instanzieren
    u_linebuffer : entity work.linebuffer
        generic map (
            IMAGE_WIDTH => WIDTH,
            IMAGE_HEIGHT => HEIGHT,
            KERNEL_SIZE => kernel_size,
            Stride => Stride
        )
        port map (
            clk          => clk,
            rst          => rst,
            pixel_in     => pixel_in,
            valid_in     => valid_in,
            window_out   => window_out,
            valid_out => valid_window
        );

    -- Convolution Core instanzieren
    u_max_pooling : entity work.MaxPooling
        generic map(
            KERNEL_SIZE => kernel_size,
            DATA_WIDTH => pixeldeepth           
        )
        port map (
            clk         => clk,
            rst         => rst,
            window_in   => window_in,
            valid_in    => valid_window_in,
            pixel_out   => pixel_out,
            valid_out   => valid_out
        );


end Behavioral;

