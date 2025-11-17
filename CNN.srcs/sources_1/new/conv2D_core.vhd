----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/06/2025 08:34:01 PM
-- Design Name: 
-- Module Name: conv_core_float - Behavioral
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

-- Festkomma-Arithmetik: 1.5.16 Format (22 Bit total)
-- 1 Vorzeichen, 5 Ganzzahl, 16 Nachkommastellen


--#####################################
--TOTAL_BITS_IN< TOTAL_BITS !!!!!!!!!!!
--#####################################

entity conv2d_core is
    generic (
        kernel_size : integer := 3;
        channels    : integer := 3;
        
        TOTAL_BITS_IN : integer := 8;
        INT_BITS_IN: integer := 8;
        FRAC_BITS_IN : integer := 0;
             
        FRAC_BITS   : integer := 16;
        INT_BITS    : integer := 8;
        TOTAL_BITS  : integer := 25;
        
        MAX_KERNEL_VALUE  : integer := 9  --Als Integer Wert
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid_in_kernel: in std_logic;
        valid_in   : in  std_logic;
        valid_out  : out std_logic;

        window_in  : in  std_logic_vector(kernel_size*kernel_size*channels*TOTAL_BITS_IN-1 downto 0);

        kernel_in  : in  std_logic_vector(TOTAL_BITS*kernel_size*kernel_size*channels-1 downto 0);

        pixel_out  : out std_logic_vector(integer(ceil(log2(real(2**INT_BITS*2**INT_BITS_IN*kernel_size**2*channels))))+FRAC_BITS +1 -1 downto 0)
    );
end conv2d_core;


architecture Behavioral of conv2d_core is
    
    --constant MAX_KERNEL_VALUE : integer := integer(ceil(log2(real(MAX_KERNEL))));
    --constant WIDTH : integer := integer(ceil(log2(real((kernel_size**2) * (2**(INT_BITS+MAX_KERNEL_VALUE))))));
    constant ADD_WIDTH: integer := integer(ceil(log2(real(2**INT_BITS*2**INT_BITS_IN*kernel_size**2*channels))))+FRAC_BITS +1;

    -- Festkomma-Typen
    subtype fixed_point is signed(TOTAL_BITS-1 downto 0);  
    subtype fixed_mult  is signed(2*TOTAL_BITS - 1 downto 0);  

    -- Array-Definitionen
    type pixel_array        is array (0 to kernel_size*kernel_size-1) of unsigned(TOTAL_BITS_IN-1 downto 0);
    type kernel_array is array (0 to channels-1, 0 to kernel_size*kernel_size-1) of fixed_point;
    type channel_window     is array (0 to channels-1) of pixel_array;
    type mult_array         is array (0 to kernel_size*kernel_size-1) of signed(TOTAL_BITS + MAX_KERNEL_VALUE-1 downto 0);
    type channel_mult_array is array (0 to channels-1) of mult_array;
    type sum_array          is array (0 to channels-1) of signed(ADD_WIDTH-1 downto 0);

    -- Signale
    signal window_pixels : channel_window := (others => (others => (others => '0')));
    signal kernel : kernel_array := (others => (others => (others => '0')));
    signal mult_values   : channel_mult_array := (others => (others => (others => '0')));
    --signal sum_values    : sum_array := (others => (others => '0'));

    signal valid_pipe     : std_logic_vector(2 downto 0) := (others => '0');
    signal valid_out_pip  : std_logic := '0';

  
    
    --function round_scale(x : signed(ADD_WIDTH - 1 downto 0)) return unsigned is
--        variable rounded    : signed(ADD_WIDTH-1 downto 0);
--        variable scaled     : unsigned(pixeldepth-1 downto 0);
--    begin
--        -- Rounded addiert 0.5
--        rounded := x + to_signed(2**(FRAC_BITS-1), ADD_WIDTH);
--            
--        --Ausschneiden des richtigen bereichs
--        scaled := unsigned(rounded(FRAC_BITS+pixeldepth-1 downto FRAC_BITS));
--            
--        return scaled;
--    end function;
--   
--    function saturate_pixel(value : signed(ADD_WIDTH-1 downto 0)) return unsigned is
--    begin
--        if value > to_signed(SAT_MAX,ADD_WIDTH) sll FRAC_BITS then
--            return to_unsigned(SAT_MAX, pixeldepth);
--        elsif value < to_signed(SAT_MIN,ADD_WIDTH) sll FRAC_BITS then
--            return to_unsigned(SAT_MIN, pixeldepth);
--        else
--            return round_scale(value);
--        end if;
--    end function;
    
    
--    function mult_signed_festkomma(
--        a : signed(TOTAL_BITS-1 downto 0);
--        b : signed(TOTAL_BITS-1 downto 0)
--        )return signed is 
--            variable product    : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
--            variable rounded    : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
--            variable scaled     : signed(TOTAL_BITS + MAX_KERNEL_VALUE-1 downto 0):= (others => '0');
--            variable round_bit  : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
--        begin
--            -- Multipliaktion ergibt doppelte Bitbreite
--            product := a*b;      
                    
--            round_bit(FRAC_BITS-1) := '1';     
--            if product >= 0 then
--                rounded := product + round_bit;
--            else
--                rounded := product + round_bit; -- negativ wird auch ins positive gerundet
--            end if;      
            
--            scaled := rounded(FRAC_BITS + TOTAL_BITS + MAX_KERNEL_VALUE-1 downto FRAC_BITS);
            
--            if product(2*TOTAL_BITS-1) ='0' then 
--                scaled(TOTAL_BITS+MAX_KERNEL_VALUE-1) := '0';
--            else
--                scaled(TOTAL_BITS+MAX_KERNEL_VALUE-1) := '1';
--            end if;
--        return scaled;
--    end function;
    
    
    function mult_signed_festkomma(
        pixel_val  : unsigned(TOTAL_BITS_IN-1 downto 0);
        kernel_val : fixed_point
    ) return signed is
  

        -- Variablen
        variable pixel_q16       : signed(TOTAL_BITS-1 downto 0);
        variable product_q32     : signed(2*TOTAL_BITS-1 downto 0);
        variable product_rounded : signed(2*TOTAL_BITS-1 downto 0);
        variable round_bit       : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
    
        -- Das finale Ergebnis (genaue Zieldimension)
        variable result_var      : signed(TOTAL_BITS + MAX_KERNEL_VALUE - 1 downto 0);
    
    begin
        -- 1) Pixel in Q.16 (oder allgemein FRAC_BITS)
        pixel_q16 := signed(resize(pixel_val, TOTAL_BITS)) sll (FRAC_BITS - FRAC_BITS_IN);
    
        -- 2) Multiplizieren (volle Breite)
        product_q32 := pixel_q16 * kernel_val;
    
        -- 3) Runden (add 0.5 LSB)
        round_bit(FRAC_BITS - 1) := '1';
        product_rounded := product_q32 + round_bit;
    
        -- 4) Slice bestimmen: (2*TOTAL_BITS-2 downto FRAC_BITS)
        result_var := product_rounded(FRAC_BITS + TOTAL_BITS + MAX_KERNEL_VALUE-1 downto FRAC_BITS);
        
        return result_var;
    end function;

            
            
begin
    process(clk)
        variable temp_sum_total : signed(ADD_WIDTH-1 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            valid_pipe <= valid_pipe(1 downto 0) & valid_in;

            if rst = '1' then
                valid_out_pip <= '0';
                valid_pipe    <= (others => '0');
                pixel_out     <= (others => '0');
               

            elsif valid_in = '1' and valid_in_kernel = '1' then
                -- 1. Kernel-Koeffizienten laden
                for ch in 0 to channels-1 loop
                    for i in 0 to kernel_size*kernel_size-1 loop
                        kernel(ch, i) <= signed(kernel_in(
                            TOTAL_BITS*kernel_size*kernel_size*channels - 1 - (ch*kernel_size*kernel_size + i)*TOTAL_BITS downto
                            TOTAL_BITS*kernel_size*kernel_size*channels - (ch*kernel_size*kernel_size + i + 1)*TOTAL_BITS
                        ));
                    end loop;
                end loop;


                -- 2. Pixel extrahieren für alle Channels
                for ch in 0 to channels-1 loop
                    for i in 0 to kernel_size*kernel_size-1 loop
                    --for ch in 0 to channels-1 loop
                        window_pixels(ch)(i) <= unsigned(window_in(
                            i*channels*TOTAL_BITS_IN + (ch+1)*TOTAL_BITS_IN - 1 downto
                            i*channels*TOTAL_BITS_IN + ch*TOTAL_BITS_IN));
                    end loop;
                end loop;

                -- 3. Multiplikation
                for ch in 0 to channels-1 loop
                    for i in 0 to kernel_size*kernel_size-1 loop
                        mult_values(ch)(i) <= mult_signed_festkomma(window_pixels(ch)(i), kernel(ch, i));
                    end loop;
                end loop;                

                -- 4. Summation
                temp_sum_total := (others => '0');
                for ch in 0 to channels-1 loop
                    for i in 0 to kernel_size*kernel_size-1 loop
                        temp_sum_total := temp_sum_total + resize(mult_values(ch)(i), ADD_WIDTH);
                    end loop;
                end loop;
                

                -- 5. Output zusammensetzen
                pixel_out <= std_logic_vector(temp_sum_total);

                valid_out_pip <= '1';

            else
                valid_out_pip <= '0';
            end if;
        end if;
    end process;

    valid_out <= valid_pipe(2);
end Behavioral;

