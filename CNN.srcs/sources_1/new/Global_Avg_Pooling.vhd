----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 03:52:06 PM
-- Design Name: 
-- Module Name: Global_Avg_Pooling - Behavioral
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

entity Global_Avg_Pooling is
    generic (
        WIDTH  : integer := 640;  -- Bildbreite
        HEIGHT : integer := 480   -- Bildhöhe
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        pixel_in   : in  std_logic_vector(23 downto 0); -- RGB (8+8+8 Bit)
        pixel_valid: in  std_logic;                     -- 1 wenn Pixel gültig

        avg_out    : out std_logic_vector(23 downto 0); -- RGB Durchschnitt
        avg_valid  : out std_logic                      -- 1 wenn Ergebnis gültig
    );
end entity;

architecture rtl of Global_Avg_Pooling is

    constant NUM_PIXELS : integer := WIDTH * HEIGHT;

    signal count     : integer range 0 to NUM_PIXELS := 0;
    signal sum_r     : unsigned(31 downto 0) := (others => '0');
    signal sum_g     : unsigned(31 downto 0) := (others => '0');
    signal sum_b     : unsigned(31 downto 0) := (others => '0');

    signal avg_r     : unsigned(7 downto 0);
    signal avg_g     : unsigned(7 downto 0);
    signal avg_b     : unsigned(7 downto 0);

    signal done      : std_logic := '0';

begin

    process(clk, rst)
    begin
        if rst = '1' then
            count    <= 0;
            sum_r    <= (others => '0');
            sum_g    <= (others => '0');
            sum_b    <= (others => '0');
            done     <= '0';
        elsif rising_edge(clk) then
            if pixel_valid = '1' then
                -- R, G, B extrahieren
                sum_r <= sum_r + unsigned(pixel_in(23 downto 16));
                sum_g <= sum_g + unsigned(pixel_in(15 downto 8));
                sum_b <= sum_b + unsigned(pixel_in(7 downto 0));

                if count = NUM_PIXELS-1 then
                    -- Letztes Pixel
                    done  <= '1';
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Durchschnitt berechnen, wenn fertig
    process(clk, rst)
    begin
        if rst = '1' then
            avg_r    <= (others => '0');
            avg_g    <= (others => '0');
            avg_b    <= (others => '0');
        elsif rising_edge(clk) then
            if done = '1' then
                avg_r <= resize(sum_r / NUM_PIXELS, 8);
                avg_g <= resize(sum_g / NUM_PIXELS, 8);
                avg_b <= resize(sum_b / NUM_PIXELS, 8);
                done  <= '0'; -- zurücksetzen
            end if;
        end if;
    end process;

    avg_out   <= std_logic_vector(avg_r & avg_g & avg_b);
    avg_valid <= done;

end rtl;

