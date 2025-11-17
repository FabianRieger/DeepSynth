----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/26/2025 10:00:38 AM
-- Design Name: 
-- Module Name: conv_control - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity conv_control is
  generic (
    CHANNELS_TOTAL     : integer := 3;
    CHANNELS_PER_BLOCK : integer := 3;
    FILTERS_TOTAL      : integer := 1;
    WIDTH              : integer := 640;
    HEIGHT             : integer := 480;
    STRIDE             : integer := 1;
    KERNEL_SIZE        : integer := 3
  );
  
    port ( 
        clk             : in  std_logic;
        rst             : in  std_logic;
        --ctrl_in_conv    : in std_logic;
        ctrl_out_conv   : out std_logic;
        row_ptr         : out unsigned(integer(ceil(log2(real(HEIGHT)))) downto 0);
        col_ptr         : out unsigned(integer(ceil(log2(real(WIDTH)))) downto 0);
        ctrl_in_buffer  : in std_logic;
        ctrl_out_buffer : out std_logic;
        valid_in_write  : in std_logic;     -- valid signal bei der Datenübertragung in den Linebuffer
        t_last          : out std_logic;
        valid_buffer    : in std_logic;
        filter_sel      : out unsigned(integer(ceil(log2(real(FILTERS_TOTAL)))) downto 0);
        channel_block   : out unsigned(integer(ceil(log2(real(CHANNELS_TOTAL/CHANNELS_PER_BLOCK)))) downto 0)
        );
end conv_control;

architecture Behavioral of conv_control is

constant PAD: integer := KERNEL_SIZE/2;

signal conv_abgeschlossen : std_logic := '0';
signal filter  : unsigned(integer(ceil(log2(real(FILTERS_TOTAL)))) downto 0) := (others => '0');
signal channel : unsigned(integer(ceil(log2(real(CHANNELS_TOTAL/CHANNELS_PER_BLOCK)))) downto 0) := (others => '0');
signal acc_last:            std_logic := '0';
signal valid:        std_logic := '0';

signal w_col: integer:= 0;
signal w_row: integer:= 0;

signal r_col: unsigned(integer(ceil(log2(real(WIDTH)))) downto 0); 
signal r_row: unsigned(integer(ceil(log2(real(HEIGHT)))) downto 0);


begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ctrl_out_buffer <= '0';               
                filter_sel      <= (others => '0');
                channel_block   <= (others => '0');
                conv_abgeschlossen <= '1';
                filter  <= (others => '0');
                channel <= (others => '0');
                acc_last <= '0';
                valid <= '0';
                r_row <= (others => '0');
                r_col <= (others => '0');
            else    
                -- Datenübertragung von Buffer in Linebuffer genehmigen nach vollständigen Abschluss der Convolution    
                if ctrl_in_buffer = '1' and conv_abgeschlossen = '1' then
                    ctrl_out_buffer <= '1';
                else
                    ctrl_out_buffer <= '0';
                end if;
                
                conv_abgeschlossen <= '0';
                
                if valid_in_write = '1' then
                    if w_col = WIDTH-1 then
                        w_col <= 0;
                        if w_row = HEIGHT+PAD+1 then
                            w_row <= 0;
                        else
                            w_row <= w_row + 1;
                        end if;
                    else
                        w_col <= w_col + 1;
                    end if;
                end if;
                                  
                valid <='0';
                -- Iteration über Mux Channels und Ausgabe eines Bits an Linebuffer bei Fertigstellung
                if ((r_row + PAD-1 < w_row) and (r_col + PAD-1 < w_col)) or r_row + PAD < w_row or w_row = 480 then
                    valid <= '1';
                end if;
                if ((r_row + PAD-1 < w_row) and (r_col + PAD < w_col)) or r_row + PAD < w_row or w_row = 480 then   
                    valid <= '1';
                    if channel >= (CHANNELS_TOTAL/CHANNELS_PER_BLOCK)-1 then
                        channel <= (others => '0');
                        if filter >= FILTERS_TOTAL-1 then
                            filter <= (others => '0');                                             
                            if r_col >= WIDTH-1 then
                                r_col <= (others => '0');
                                if r_row >= HEIGHT-1 then
                                    r_row <= (others => '0');
                                    w_row <= 0;
                                    valid <= '0';
                                else
                                    r_row <= r_row + STRIDE;
                                end if;
                            else
                                r_col <= r_col + STRIDE;
                            end if;
                        else
                            filter <= filter + 1;
                        end if;
                    else
                        channel <= channel + 1;     
                    end if;
                end if;
      
                
                if channel = (CHANNELS_TOTAL/CHANNELS_PER_BLOCK)-1 then
                    acc_last <= '1';
                else 
                    acc_last <= '0';
                end if;
                
                
                if filter = 0 and channel = 0 and r_row = 0 and r_col = 0 then
                    conv_abgeschlossen <= '1';
                end if;
                
            end if; -- <- wichtig: schließt den Reset-else Block!
        end if;
    end process;

    ctrl_out_conv <= valid; 
    filter_sel <= filter; 
    channel_block <= channel;
    t_last <= acc_last;
    row_ptr <= r_row;
    col_ptr <= r_col;
    
end Behavioral;
