----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/06/2025 02:54:08 PM
-- Design Name: 
-- Module Name: linebuffer_nxn - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity linebuffer_3x3 is
    generic (
        IMAGE_WIDTH : integer := 640;  -- Bildbreite in Pixeln
        IMAGE_HEIGHT : integer := 480
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid_in   : in  std_logic;
        pixel_in   : in  std_logic_vector(23 downto 0); -- RGB Pixel 24bit
        window_out : out std_logic_vector(9*24 - 1 downto 0); -- 3x3 Fenster (9 Pixel à 24bit)
        valid_out  : out std_logic
    );
end entity;

architecture Behavioral of linebuffer_3x3 is

    -- Zeilenpuffer (Shiftregister) mit Tiefe IMAGE_WIDTH
    type line_t is array(0 to IMAGE_WIDTH-1) of std_logic_vector(23 downto 0);
    type row is array(0 to 2) of std_logic_vector(23 downto 0);

    -- Wir nutzen hier zwei RAM/Arrays als Zeilenbuffer
    signal linebuffer_1 : line_t := (others => (others => '0'));
    signal linebuffer_2 : line_t := (others => (others => '0'));

    -- Lese-/Schreibindex für Spalte
    signal col_ptr : integer range 0 to IMAGE_WIDTH-1 := 0;
    signal row_ptr: integer range 0 to IMAGE_HEIGHT-1 :=0;
    

    -- Pipeline Register für die 3 Pixel pro Zeile (Shiftregister für Fenster)
    signal win_row0 : row := (others => (others => '0'));
    signal win_row1 : row := (others => (others => '0'));
    signal win_row2 : row := (others => (others => '0'));

    -- Gültigkeit des Fensters (ab zweiter Zeile und dritter Spalte)
    signal valid_window : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                col_ptr <= 0;
                row_ptr <= 0;
                valid_window <= '0';                                                               
                -- Reset aller Shiftregister (optional)
                for i in 0 to 2 loop
                    win_row0(i) <= (others => '0');
                    win_row1(i) <= (others => '0');
                    win_row2(i) <= (others => '0');                                         
                end loop;
                linebuffer_1 <= (others => (others => '0'));
                linebuffer_2 <= (others => (others => '0'));
            else
                if valid_in = '1' then
                    -- Pixel in Zeilenpuffer speichern
                    linebuffer_2(col_ptr) <= linebuffer_1(col_ptr);
                    linebuffer_1(col_ptr) <= pixel_in;

                    -- Pixel-Schieberegister für Fenster aufbauen
                    -- Neue Spalte ganz rechts reinschieben, Links nach rechts verschieben
                    -- Zeile 0 = älteste Zeile (linebuffer_2)
                    win_row0(0) <= win_row0(1);
                    win_row0(1) <= win_row0(2);
                    win_row0(2) <= linebuffer_2(col_ptr);

                    -- Zeile 1 = mittlere Zeile (linebuffer_1)
                    win_row1(0) <= win_row1(1);
                    win_row1(1) <= win_row1(2);
                    win_row1(2) <= linebuffer_1(col_ptr);

                    -- Zeile 2 = aktuelle Zeile (pixel_in)
                    win_row2(0) <= win_row2(1);
                    win_row2(1) <= win_row2(2);
                    win_row2(2) <= pixel_in;

                    -- Gültigkeit nur, wenn mindestens 2 Zeilen und 2 Spalten schon durchlaufen
                    if row_ptr >= 2 and col_ptr >= 2 then
                        valid_window <= '1';
                    else
                        valid_window <= '0';
                    end if;

                    -- Spalten/reihenindex inkrementieren
                    if col_ptr = IMAGE_WIDTH-1 then
                        col_ptr <= 0;
                        if row_ptr = IMAGE_HEIGHT-1 then
                            row_ptr <= 0;
                        else
                            row_ptr <= row_ptr +1;
                        end if;
                    else
                        col_ptr <= col_ptr + 1;
                        
                    end if;
                    
                else
                    valid_window <= '0';
                end if;
            end if;
        end if;
    end process;

    -- 3x3 Fenster zusammensetzen: (von oben links bis unten rechts)
    -- Index 0..8: (0,0), (0,1), (0,2), (1,0), ..., (2,2)
    window_out <=
        win_row0(0) & win_row0(1) & win_row0(2) &
        win_row1(0) & win_row1(1) & win_row1(2) &
        win_row2(0) & win_row2(1) & win_row2(2);

    valid_out <= valid_window;

end Behavioral;
