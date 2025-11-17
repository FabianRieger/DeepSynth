library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity writefile_comp_1pixel_rgb is
  generic (
    FileName : string := "output_pixel.dat"
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    valid : in  std_logic;
    data  : in  std_logic_vector(37 downto 0)  -- 1 Pixel = 38 Bit
  );
end writefile_comp_1pixel_rgb;

architecture Behavioral of writefile_comp_1pixel_rgb is
  type byte_file is file of character;
  file outfile : byte_file open write_mode is FileName;
begin

  process(clk, rst)
    variable byte_array : std_logic_vector(39 downto 0); -- 40 Bit, obere 2 Bits = 0
    variable b4, b3, b2, b1, b0 : character;
  begin
    if rst = '1' then
      -- nichts bei Reset

    elsif rising_edge(clk) then
      if valid = '1' then
        -- 38 Bit Wert in 40 Bit Array, obere 2 Bits auf 0
        byte_array(37 downto 0) := data;
        byte_array(39 downto 38) := "00";

        -- 5 Bytes erzeugen (MSB zuerst)
        b4 := character'val(to_integer(unsigned(byte_array(39 downto 32))));
        b3 := character'val(to_integer(unsigned(byte_array(31 downto 24))));
        b2 := character'val(to_integer(unsigned(byte_array(23 downto 16))));
        b1 := character'val(to_integer(unsigned(byte_array(15 downto 8))));
        b0 := character'val(to_integer(unsigned(byte_array(7 downto 0))));

        -- Schreiben in Datei
        write(outfile, b4);
        write(outfile, b3);
        write(outfile, b2);
        write(outfile, b1);
        write(outfile, b0);
      end if;
    end if;
  end process;

end Behavioral;
