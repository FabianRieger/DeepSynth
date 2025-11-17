----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 10:02:17 PM
-- Design Name: 
-- Module Name: Accumulator_Pingpong_tb - Behavioral
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

entity tb_accumulator_pingpong is
end entity;

architecture sim of tb_accumulator_pingpong is
  constant WIDTH     : integer := 16;
  constant ACC_WIDTH : integer := 32;

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';

  signal tvalid    : std_logic := '0';
  signal tlast     : std_logic := '0';
  signal tdata     : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

  signal out_valid : std_logic;
  signal out_data  : std_logic_vector(ACC_WIDTH-1 downto 0);

  -- Eigenen Array-Typ für die Testdaten definieren
  type int_array is array (natural range <>) of integer;

begin
  -- DUT
  uut: entity work.accumulator_pingpong
    generic map (
      WIDTH     => WIDTH,
      ACC_WIDTH => ACC_WIDTH
    )
    port map (
      clk       => clk,
      rst       => rst,
      tvalid    => tvalid,
      tlast     => tlast,
      tdata     => tdata,
      out_valid => out_valid,
      out_data  => out_data
    );

  -- Clock 100 MHz
  clk <= not clk after 5 ns;

  -- Stimulus
  process
    procedure send_block(vals : in int_array) is
    begin
      for i in vals'range loop
        tvalid <= '1';
        tdata  <= std_logic_vector(to_signed(vals(i), WIDTH));
        if i = vals'high then
          tlast <= '1';
        else
          tlast <= '0';
        end if;
        wait until rising_edge(clk);
      end loop;
      tvalid <= '0';
      tlast  <= '0';
      wait until rising_edge(clk);
    end procedure;
  begin
    -- Reset
    rst <= '1';
    wait for 20 ns;
    rst <= '0';

    -- Block 1: 1+2+3+4 = 10
    send_block((1, 2, 3, 4));

    -- Block 2: 5+5+5+5 = 20
    send_block((5, 5, 5, 5));

    -- Block 3: -1+2-3+4 = 2
    send_block((-1, 2, -3, 4));

    wait for 100 ns;
    assert false report "Simulation fertig" severity failure;
  end process;

end architecture;


