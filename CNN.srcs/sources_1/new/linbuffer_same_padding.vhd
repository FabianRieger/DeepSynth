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
use IEEE.MATH_REAL.ALL;

entity linebuffer_same_padding is
    generic (
        IMAGE_WIDTH  : integer := 640;
        IMAGE_HEIGHT : integer := 480;
        KERNEL_SIZE  : integer := 3;
        CHANNELS     : integer := 3;
        TOTAL_BITS   : integer := 8;
        STRIDE       : integer := 1
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Eingabe-Stream
        valid_in   : in  std_logic;
        pixel_in   : in  std_logic_vector(CHANNELS*TOTAL_BITS-1 downto 0);

        -- Fenster-Steuerung
        ctrl_in    : in  std_logic;
        --ctrl_out   : out std_logic;
        row_ptr         : in unsigned(integer(ceil(log2(real(IMAGE_HEIGHT)))) downto 0);
        col_ptr         : in unsigned(integer(ceil(log2(real(IMAGE_WIDTH)))) downto 0);

        -- Fenster-Ausgabe
        window_out : out std_logic_vector(CHANNELS*TOTAL_BITS*KERNEL_SIZE*KERNEL_SIZE-1 downto 0);
        valid_out  : out std_logic
    );
end entity;

architecture rtl of linebuffer_same_padding is
    constant PIXEL_W : integer := CHANNELS*TOTAL_BITS;
    constant PAD: integer := KERNEL_SIZE/2;

    -- Voller Framebuffer (BRAM)
    type line_t       is array(0 to IMAGE_WIDTH-1) of std_logic_vector(PIXEL_W-1 downto 0);
    type framebuffer_t is array(0 to IMAGE_HEIGHT-1) of line_t;
    signal framebuffer : framebuffer_t := (others => (others => (others => '0')));
    attribute ram_style : string;
    attribute ram_style of framebuffer : signal is "block";

    -- Schreibzeiger
    signal w_row, w_col : integer range 0 to IMAGE_HEIGHT-1 := 0;

    -- Lesepointer für Fenster
    signal r_row, r_col : integer range 0 to IMAGE_HEIGHT-1 := 0;

    -- Schieberegister für Fenster (KERNEL_SIZE x KERNEL_SIZE)
    type row_shift_t   is array(0 to KERNEL_SIZE-1) of std_logic_vector(PIXEL_W-1 downto 0);
    type window_regs_t is array(0 to KERNEL_SIZE-1) of row_shift_t;
    signal win_regs    : window_regs_t := (others => (others => (others => '0')));


    -- Fenster gültig?
    signal valid_window : std_logic := '0';
    
    
        ----------------------------------------------------------------------------
    -- Fenster packen in Vektor
    ----------------------------------------------------------------------------
    function pack_window(regs : window_regs_t) return std_logic_vector is
        variable res : std_logic_vector(KERNEL_SIZE*KERNEL_SIZE*PIXEL_W-1 downto 0);
        variable idx : integer := 0;
    begin
        for r in KERNEL_SIZE-1 downto 0 loop
            for c in KERNEL_SIZE-1 downto 0 loop
                res((idx+1)*PIXEL_W-1 downto idx*PIXEL_W) := regs(r)(c);
                idx := idx + 1;
            end loop;
        end loop;
        return res;
    end function;
    
    
begin

    ----------------------------------------------------------------------------
    process(clk)
    variable row_idx : integer;
    variable col_idx : integer;
    begin
        if rising_edge(clk) then
            if rst='1' then
                w_row <= 0; w_col <= 0;
                r_row <= 0; r_col <= 0;
                win_regs <= (others => (others => (others => '0')));
                --ctrl_out <= '0';
                valid_window <= '0';
                framebuffer <= (others => (others => (others => '0')));
            else
                ----------------------------------------
                -- 1) Schreibe Pixel in Framebuffer
                ----------------------------------------
                if valid_in='1' then
                    framebuffer(w_row)(w_col) <= pixel_in;
                    if w_col = IMAGE_WIDTH-1 then
                        w_col <= 0;
                        if w_row = IMAGE_HEIGHT-1 then
                            w_row <= 0;
                        else
                            w_row <= w_row + 1;
                        end if;
                    else
                        w_col <= w_col + 1;
                    end if;
                end if;

                -----------------------------------------
                -- 2) Fenster-Ausgabe (ctrl_in gesteuert)
                -----------------------------------------
                
                
                if ctrl_in='1' then
                      
            
                    -- Taps aus Framebuffer holen
                    for i in 0 to KERNEL_SIZE-1 loop
                        for j in 0 to KERNEL_SIZE-1 loop
                            -- tatsächliche Bildkoordinaten für den Pixel
                        
                            row_idx := to_integer(row_ptr) + i - PAD;
                            col_idx := to_integer(col_ptr) + j - PAD;
                        
                            if (row_idx >= 0) and (row_idx < IMAGE_HEIGHT) and
                               (col_idx >= 0) and (col_idx < IMAGE_WIDTH) then
                                win_regs(i)(j) <= framebuffer(row_idx)(col_idx);
                            else
                                win_regs(i)(j) <= (others => '0'); -- Padding oben/links/rechts/unten
                            end if;
                        end loop;
                    end loop;

                    valid_window <= '1';        
                
                else
                    valid_window <= '0';
                end if;

            end if;
        end if;
    end process;

    window_out <= pack_window(win_regs);
    valid_out  <= valid_window;

end architecture;





