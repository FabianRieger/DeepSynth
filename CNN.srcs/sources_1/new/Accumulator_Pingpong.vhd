----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 09:58:58 PM
-- Design Name: 
-- Module Name: Accumulator_Pingpong - Behavioral
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

entity accumulator_pingpong is
  generic (
    WIDTH     : integer := 38;  -- Eingangsbreite (signed)
    ACC_WIDTH : integer := 64   -- Akkubreite (>= WIDTH + log2(max Blocklänge))
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;

    -- Eingangsstream
    tvalid  : in  std_logic;
    tlast   : in  std_logic;  -- markiert letztes Sample eines Blocks
    tdata   : in  std_logic_vector(WIDTH-1 downto 0); -- signed

    -- Ausgang
    out_valid : out std_logic;  -- pulst 1 Takt lang am Blockende
    out_data  : out std_logic_vector(ACC_WIDTH-1 downto 0)  -- Ergebnis (signed)
  );
end entity;

architecture rtl of accumulator_pingpong is

  signal acc0, acc1 : signed(ACC_WIDTH-1 downto 0) := (others => '0');
  signal use_acc0   : std_logic := '1';  -- '1' => acc0 aktiv; '0' => acc1 aktiv
  signal out_reg    : signed(ACC_WIDTH-1 downto 0) := (others => '0');
  signal out_v_reg  : std_logic := '0';
begin

  process(clk, rst)
    variable din_s : signed(WIDTH-1 downto 0);
  begin
    if rst = '1' then
      acc0      <= (others => '0');
      acc1      <= (others => '0');
      use_acc0  <= '1';
      out_reg   <= (others => '0');
      out_v_reg <= '0';

    elsif rising_edge(clk) then
      out_v_reg <= '0';  -- Default

      if tvalid = '1' then
        din_s := signed(tdata);

        if use_acc0 = '1' then
          -- sammeln in acc0
          acc0 <= acc0 + resize(din_s, acc0'length);

          if tlast = '1' then
            -- Blockabschluss: Ergebnis (inkl. aktuellem Sample) ausgeben
            out_reg   <= acc0 + resize(din_s, acc0'length);
            out_v_reg <= '1';

            -- Rolle tauschen und den neuen aktiven Akku leeren
            use_acc0  <= '0';
            acc1      <= (others => '0');  -- neuer aktiver Akku ab nächstem Takt
          end if;

        else
          -- sammeln in acc1
          acc1 <= acc1 + resize(din_s, acc1'length);

          if tlast = '1' then
            out_reg   <= acc1 + resize(din_s, acc1'length);
            out_v_reg <= '1';

            use_acc0  <= '1';
            acc0      <= (others => '0');
          end if;
        end if;

      end if; -- tvalid

    end if;
  end process;

  out_data  <= std_logic_vector(out_reg);
  out_valid <= out_v_reg;

end architecture;

