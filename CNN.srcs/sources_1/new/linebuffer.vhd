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



-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity linebuffer is
    generic (
        IMAGE_WIDTH  : integer := 640;   -- Bildbreite in Pixeln
        IMAGE_HEIGHT : integer := 480;   -- Bildhöhe in Pixeln
        KERNEL_SIZE  : integer := 3;     -- Fenstergröße (>= 2)
        CHANNELS     : integer := 3;     -- Anzahl Kanäle (z. B. 1=grau, 3=RGB)
        TOTAL_BITS   : integer := 8;    -- Gesamtbreite pro Kanal
        FRAC_BITS    : integer := 0;     -- Nachkommabits
        INT_BITS     : integer := 8; -- ganzzahlige Bits
        STRIDE       : integer := 1
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid_in   : in  std_logic;
        pixel_in   : in  std_logic_vector(CHANNELS*TOTAL_BITS - 1 downto 0); -- Multi-Channel Pixel
        window_out : out std_logic_vector(TOTAL_BITS*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0);
        valid_out  : out std_logic
    );
end entity;

architecture Behavioral of linebuffer is

    constant PIXEL_WIDTH : integer := CHANNELS * TOTAL_BITS;

    -- Eine Zeile Speicher + Padding Erweiterung
    type line_t is array(0 to IMAGE_WIDTH + KERNEL_SIZE -1 -1) of std_logic_vector(PIXEL_WIDTH-1 downto 0);

    -- Eine Zeile des Fensters (KERNEL_SIZE Pixel)
    type row_t is array(0 to KERNEL_SIZE-1) of std_logic_vector(PIXEL_WIDTH-1 downto 0);

    -- Puffer (KERNEL_SIZE-1 Stück)
    type linebuffer_array_t is array(0 to IMAGE_HEIGHT + KERNEL_SIZE - 1 -1) of line_t;
    signal linebuffers : linebuffer_array_t := (others => (others => (others => '0')));

    -- Komplettes Fenster
    type window_array_t is array(0 to KERNEL_SIZE-1) of row_t;
    signal win_rows : window_array_t := (others => (others => (others => '0')));

    -- Spalten- und Zeilenposition
    signal col_ptr : integer range 0 to IMAGE_WIDTH-1 := 0;
    signal row_ptr : integer range 0 to IMAGE_HEIGHT-1 := 0;

    -- Gültigkeit
    signal valid_window : std_logic := '0';
    
    -- Funktion zum Zusammenpacken
    function pack_window(w : window_array_t) return std_logic_vector is
        variable res : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*PIXEL_WIDTH - 1 downto 0);
        variable idx : integer := 0;
    begin
        for r in KERNEL_SIZE-1 downto 0 loop
            for c in KERNEL_SIZE-1 downto 0 loop
                res((idx+1)*PIXEL_WIDTH - 1 downto idx*PIXEL_WIDTH) := w(r)(c);
                idx := idx + 1;
            end loop;
        end loop;
        return res;
    end function;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                col_ptr       <= 0;
                row_ptr       <= 0;
                valid_window  <= '0';
                win_rows      <= (others => (others => (others => '0')));
                linebuffers   <= (others => (others => (others => '0')));
            else
                if valid_in = '1' then


                    linebuffers(row_ptr+KERNEL_SIZE/2)(col_ptr+KERNEL_SIZE/2) <= pixel_in;
                    
                    
                    for r in KERNEL_SIZE-1 downto 0 loop
                        for c in KERNEL_SIZE-1 downto 0 loop
                            win_rows(r)(c) <= linebuffers(r+row_ptr)(c+col_ptr);
                        end loop;
                    end loop;
                    
                    valid_window <= '1';

                    -- 5) Spalten-/Zeilenzeiger hochzählen
                    if col_ptr = IMAGE_WIDTH-1 then
                        col_ptr <= 0;
                        if row_ptr = IMAGE_HEIGHT-1 then
                            row_ptr <= 0;
                        else
                            row_ptr <= row_ptr + 1;
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

    window_out <= pack_window(win_rows);
    valid_out  <= valid_window;

end Behavioral;



