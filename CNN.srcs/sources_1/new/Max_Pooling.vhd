----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 10:35:56 AM
-- Design Name: 
-- Module Name: Max_Pooling - Behavioral
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

entity MaxPooling is
    generic (
        DATA_WIDTH  : integer := 8;   -- Bits pro Farbkanal
        KERNEL_SIZE : integer := 2    -- Fenstergröße (z.B. 2x2, 3x3, ...)
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid_in   : in  std_logic;

        -- Fenster vom Linebuffer: KERNEL_SIZE*KERNEL_SIZE Pixel * 24 Bit
        window_in  : in  std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*24 - 1 downto 0);

        -- Ausgabe: ein Pixel (24 Bit: R,G,B)
        pixel_out  : out std_logic_vector(23 downto 0);
        valid_out  : out std_logic
    );
end MaxPooling;

architecture Behavioral of MaxPooling is

    -- Hilfsfunktion: Maximum zweier Werte
    function vmax(a, b : std_logic_vector) return std_logic_vector is
    begin
        if unsigned(a) > unsigned(b) then
            return a;
        else
            return b;
        end if;
    end function;

    -- Maximum über ein Array von std_logic_vector
    function vmax_array(vec : std_logic_vector; num_elems : integer; elem_width : integer)
        return std_logic_vector is
        variable maxval : std_logic_vector(elem_width-1 downto 0);
        variable temp   : std_logic_vector(elem_width-1 downto 0);
    begin
        maxval := vec(elem_width-1 downto 0);
        for i in 1 to num_elems-1 loop
            temp := vec((i+1)*elem_width-1 downto i*elem_width);
            if unsigned(temp) > unsigned(maxval) then
                maxval := temp;
            end if;
        end loop;
        return maxval;
    end function;

    signal r_max, g_max, b_max : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    process(clk, rst)
        variable r_vec : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH - 1 downto 0);
        variable g_vec : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH - 1 downto 0);
        variable b_vec : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH - 1 downto 0);
        variable pix   : std_logic_vector(23 downto 0);
    begin
        if rst = '1' then
            r_max     <= (others => '0');
            g_max     <= (others => '0');
            b_max     <= (others => '0');
            valid_out <= '0';

        elsif rising_edge(clk) then
            if valid_in = '1' then
                -- Fenster in R/G/B zerlegen
                for i in 0 to KERNEL_SIZE*KERNEL_SIZE-1 loop
                    pix := window_in((i+1)*24-1 downto i*24);
                    r_vec((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) := pix(23 downto 16); -- R
                    g_vec((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) := pix(15 downto 8);  -- G
                    b_vec((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) := pix(7 downto 0);   -- B
                end loop;

                -- Kanalweise Maximum
                r_max <= vmax_array(r_vec, KERNEL_SIZE*KERNEL_SIZE, DATA_WIDTH);
                g_max <= vmax_array(g_vec, KERNEL_SIZE*KERNEL_SIZE, DATA_WIDTH);
                b_max <= vmax_array(b_vec, KERNEL_SIZE*KERNEL_SIZE, DATA_WIDTH);

                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;

    -- RGB zu einem 24-Bit Pixel zusammenfassen
    pixel_out <= r_max & g_max & b_max;

end Behavioral;


