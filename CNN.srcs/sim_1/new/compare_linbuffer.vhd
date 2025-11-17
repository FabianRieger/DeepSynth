----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/14/2025 09:42:16 PM
-- Design Name: 
-- Module Name: compare_linbuffer - Behavioral
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

entity compare_linbuffer is
end entity;


architecture sim of compare_linbuffer is


    constant IMAGE_WIDTH  : integer := 8;   -- klein für Test
    constant IMAGE_HEIGHT : integer := 6;
    constant PIXEL_BITS   : integer := 24;
    constant KERNEL_SIZE  : integer := 3;

    -- Clock & Reset
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal valid_in : std_logic := '0';

    -- Pixel Input
    signal pixel_in : std_logic_vector(PIXEL_BITS-1 downto 0) := (others => '0');

    -- Outputs
    signal window_3x3     : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*PIXEL_BITS-1 downto 0);
    signal valid_3x3      : std_logic;
    signal window_generic : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*PIXEL_BITS-1 downto 0);
    signal valid_generic  : std_logic;

begin

    ----------------------------------------------------------------
    -- Clock Generator
    ----------------------------------------------------------------
    clk <= not clk after 5 ns;

    ----------------------------------------------------------------
    -- DUT 1: Original 3x3
    ----------------------------------------------------------------
    uut_orig: entity work.linebuffer_3x3
        generic map (
            IMAGE_WIDTH  => IMAGE_WIDTH,
            IMAGE_HEIGHT => IMAGE_HEIGHT
        )
        port map (
            clk        => clk,
            rst        => rst,
            valid_in   => valid_in,
            pixel_in   => pixel_in,
            window_out => window_3x3,
            valid_out  => valid_3x3
        );

    ----------------------------------------------------------------
    -- DUT 2: Generische NxN Version (KERNEL_SIZE = 3)
    ----------------------------------------------------------------
    uut_gen: entity work.linebuffer
        generic map (
            IMAGE_WIDTH  => IMAGE_WIDTH,
            IMAGE_HEIGHT => IMAGE_HEIGHT,
            KERNEL_SIZE  => KERNEL_SIZE
        )
        port map (
            clk        => clk,
            rst        => rst,
            valid_in   => valid_in,
            pixel_in   => pixel_in,
            window_out => window_generic,
            valid_out  => valid_generic
        );

    ----------------------------------------------------------------
    -- Stimulus Process
    ----------------------------------------------------------------
    stim_proc: process
        variable px_counter : integer := 0;
    begin
        -- Reset für einige Takte
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- Pixel stream generieren: einfach Pixelnummer als Daten
        for row in 0 to IMAGE_HEIGHT-1 loop
            for col in 0 to IMAGE_WIDTH-1 loop
                valid_in <= '1';
                pixel_in <= std_logic_vector(to_unsigned(px_counter, PIXEL_BITS));
                px_counter := px_counter + 1;
                wait for 10 ns;
            end loop;
        end loop;

        -- Nachlauf
        valid_in <= '0';
        wait for 50 ns;
        wait;
    end process;

    ----------------------------------------------------------------
    -- Vergleichsprozess
    ----------------------------------------------------------------
    compare_proc: process(clk)
    begin
        if rising_edge(clk) then
            if valid_3x3 = '1' or valid_generic = '1' then
                if valid_3x3 /= valid_generic then
                    report "VALID mismatch: orig=" & std_logic'image(valid_3x3) &
                           " gen=" & std_logic'image(valid_generic)
                           severity error;
                elsif window_3x3 /= window_generic then
                    report "WINDOW mismatch! " severity error;
                end if;
            end if;
        end if;
    end process;

end architecture;

