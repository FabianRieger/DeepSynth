----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 03:57:31 PM
-- Design Name: 
-- Module Name: kernel_mux - Behavioral
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

entity kernel_block_mux is
  generic (
    DATA_WIDTH         : integer := 8;
    KERNEL_SIZE        : integer := 3;
    CHANNELS_TOTAL     : integer := 3;
    CHANNELS_PER_BLOCK : integer := 2;
    FILTERS_TOTAL      : integer := 4
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    valid_out     : out std_logic;
    filter_sel    : in unsigned(integer(ceil(log2(real(FILTERS_TOTAL)))) downto 0);
    channel_block : in unsigned(integer(ceil(log2(real(CHANNELS_TOTAL/CHANNELS_PER_BLOCK)))) downto 0);
    kernel_pool   : in  std_logic_vector(
                       FILTERS_TOTAL*CHANNELS_TOTAL*KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH-1 downto 0
                     );
    kernel_out    : out std_logic_vector(
                       CHANNELS_PER_BLOCK*KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH-1 downto 0
                     )
  );
end entity;



architecture Behavioral of kernel_block_mux is
begin
  process(clk)
    variable start_idx : integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        kernel_out <= (others => '0');  -- Reset-Ausgang
        valid_out <= '0';
      else
        -- Berechne Startindex für den ausgewählten Block
        start_idx := to_integer(filter_sel) * CHANNELS_TOTAL * KERNEL_SIZE**2 * DATA_WIDTH + 
                     to_integer(channel_block) * CHANNELS_PER_BLOCK * KERNEL_SIZE**2 * DATA_WIDTH;

        -- Slice aus Pool auf kernel_out registrieren
        kernel_out <= kernel_pool(start_idx + kernel_out'length - 1 downto start_idx);
        valid_out <= '1';
      end if;
    end if;
  end process;
end Behavioral;





