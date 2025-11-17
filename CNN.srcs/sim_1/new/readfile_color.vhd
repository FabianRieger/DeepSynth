----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/08/2025 02:59:39 PM
-- Design Name: 
-- Module Name: readfile_color - Behavioral
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
use STD.TEXTIO.ALL;

entity readfile_comp_bin_rgb is
  generic (
    FileName : string := "input_image.dat"  -- Binärdatei mit RGB
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    ready : in  std_logic;
    valid : out std_logic;
    data  : out std_logic_vector(23 downto 0)  -- 24 Bit = R(23:16), G(15:8), B(7:0)
  );
end readfile_comp_bin_rgb;

architecture Behavioral of readfile_comp_bin_rgb is
  type byte_file is file of character;
  file bin_file : byte_file open read_mode is FileName;
  signal write_data: std_logic := '0';
begin

  process(clk, rst, ready)
    variable r, g, b : character;
  begin
    if rst = '1' then
      data  <= (others => '0');
      valid <= '0';
      
    elsif ready = '1' then
        write_data <= '1';

    elsif rising_edge(clk) then
      valid <= '0';

      --if ready = '1' and not endfile(bin_file) then
      if write_data = '1' and not endfile(bin_file) then
        -- Lies 3 Bytes = 24 Bit RGB
        read(bin_file, r);
        if not endfile(bin_file) then
          read(bin_file, g);
        else
          g := character'val(0);
        end if;

        if not endfile(bin_file) then
          read(bin_file, b);
        else
          b := character'val(0);
        end if;

        -- Zusammensetzen zu 24 Bit: R & G & B
        data <= std_logic_vector(
                  to_unsigned(character'pos(r), 8) &
                  to_unsigned(character'pos(g), 8) &
                  to_unsigned(character'pos(b), 8)
               );

        valid <= '1';
      else
        write_data <= '0';
      end if;
    end if;
  end process;

end Behavioral;

