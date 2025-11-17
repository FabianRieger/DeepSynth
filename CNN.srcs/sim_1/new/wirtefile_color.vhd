----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/08/2025 03:12:58 PM
-- Design Name: 
-- Module Name: wirtefile_color - Behavioral
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

entity writefile_comp_3x3_rgb is
  generic (
    FileName : string := "output_patch_3x3.dat"
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    valid : in  std_logic;
    data  : in  std_logic_vector(215 downto 0)  -- 9 × 24 = 216 Bit
  );
end writefile_comp_3x3_rgb;

architecture Behavioral of writefile_comp_3x3_rgb is
  type byte_file is file of character;
  file outfile : byte_file open write_mode is FileName;
begin

  process(clk, rst)
    variable r_byte, g_byte, b_byte : character;
    variable pixel_idx : integer;
    variable r, g, b   : std_logic_vector(7 downto 0);
  begin
    if rst = '1' then
      -- do nothing on reset

    elsif rising_edge(clk) then
      if valid = '1' then
        for pixel_idx in 0 to 8 loop  -- 9 Pixel = 3x3
          -- Berechne Startbit für diesen Pixel
          r := data(215 - pixel_idx*24 downto 215 - pixel_idx*24 - 7);
          g := data(215 - pixel_idx*24 - 8  downto 215 - pixel_idx*24 - 15);
          b := data(215 - pixel_idx*24 - 16 downto 215 - pixel_idx*24 - 23);

          -- Umwandeln in Byte
          r_byte := character'val(to_integer(unsigned(r)));
          g_byte := character'val(to_integer(unsigned(g)));
          b_byte := character'val(to_integer(unsigned(b)));

          -- Schreiben in Datei
          write(outfile, r_byte);
          write(outfile, g_byte);
          write(outfile, b_byte);
        end loop;
      end if;
    end if;
  end process;

end Behavioral;

