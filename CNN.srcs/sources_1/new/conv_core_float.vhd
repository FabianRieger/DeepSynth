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

entity conv_core_float is
    generic  (
        kernel_size: integer := 3;       -- Kernel Size
        pixeldeepth: integer := 8;       -- Pixeltiefe (bleibt bei 8 Bit)
        channels: integer :=3;           -- Anzahl channels (rgb = 3) Funktioniert momentan nur mit 3
        -- Festkomma-Parameter
        FRAC_BITS : integer := 16;       -- Nachkommastellen
        INT_BITS : integer := 8;         -- Ganzzahlstellen (ohne Vorzeichen)
        TOTAL_BITS : integer := 25;      -- Gesamtbits (1+8+16)
        
        -- Convolution Parameter
        MAX_KERNEL_VALUE: integer := integer(ceil(log2(real(9))));  -- Maximale Wert Eines Kernel Inhalts
        --MAX_LEN : integer := 32;         -- aximallänge als Zwischenspeicher (Kernel Addition)
        SAT_MAX: integer := 255;         -- Satturation auf MAX Wert   
        SAT_MIN: integer := 0            -- Satturation auf MIN Wert
        
    );
    
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out: out std_logic;
        
        -- RGB Fenster: kernel_size x kernel_size x 3 x pixeldeepth
        window_in : in std_logic_vector (kernel_size*kernel_size*channels*pixeldeepth-1 downto 0);
        
        -- Kernel im Festkommaformat 1.5.16
        kernel_in : in std_logic_vector(TOTAL_BITS*kernel_size*kernel_size-1 downto 0);
        
        -- Output RGB-Pixel
        pixel_out : out std_logic_vector (channels*pixeldeepth-1 downto 0)
    );
end conv_core_float;

architecture Behavioral of conv_core_float is

    constant ADD_WIDTH : integer := integer(ceil(log2(real((kernel_size**2) * (2**(INT_BITS+MAX_KERNEL_VALUE)))))) + FRAC_BITS+1; -- Länge für Zwischenspeicherung Addition

    -- Festkomma-Typen
    subtype fixed_point is signed(TOTAL_BITS-1 downto 0);  
    
    -- Für Multiplikation: Doppelte Breite (Festkomma * Festkomma)
    subtype fixed_mult is signed(2*TOTAL_BITS - 1 downto 0);  
    
    -- Arrays für Pixel und Kernel
    type pixel_array is array (0 to kernel_size*kernel_size-1) of unsigned(pixeldeepth-1 downto 0);
    type kernel_array is array (0 to kernel_size*kernel_size-1) of fixed_point;
    type window_array is array (0 to channels -1) of pixel_array;
    type fixed_point_array is array (0 to kernel_size*kernel_size-1) of fixed_point;
    type mult_array is array (0 to kernel_size*kernel_size-1) of signed(TOTAL_BITS + MAX_KERNEL_VALUE-1 downto 0);
    
    -- Für Debbugen
    type b_array is array (0 to kernel_size*kernel_size-1) of unsigned (TOTAL_BITS-1 downto 0);
    

    signal window_r, window_g, window_b  : pixel_array := (others => (others => '0'));
    signal kernel : kernel_array := (others => (others => '0'));
    signal mult_r, mult_g, mult_b : mult_array := (others => (others => '0'));
    
    
    -- Beobachtungchssignal
    signal sum_r, sum_g, sum_b : signed(ADD_WIDTH - 1 downto 0) := (others => '0');
    
       
    
    function round_scale(x : signed(ADD_WIDTH - 1 downto 0)) return unsigned is
        variable rounded    : signed(ADD_WIDTH-1 downto 0);
        variable scaled     : unsigned(pixeldeepth-1 downto 0);
    begin
        -- Rounded sciebt die zahlen entsprechend nach lins, damit ganzzahl richtiges format hat
        rounded := x + to_signed(2**(FRAC_BITS-1), ADD_WIDTH);
            
        --Ausschneiden des richtigen bereichs
        scaled := unsigned(rounded(FRAC_BITS+pixeldeepth-1 downto FRAC_BITS));
            
        return scaled;
    end function;
   
    function saturate_pixel(value : signed(ADD_WIDTH-1 downto 0)) return unsigned is
    begin
        if value > to_signed(SAT_MAX,ADD_WIDTH) sll FRAC_BITS then
            return to_unsigned(SAT_MAX, pixeldeepth);
        elsif value < to_signed(SAT_MIN,ADD_WIDTH) sll FRAC_BITS then
            return to_unsigned(SAT_MIN, pixeldeepth);
        else
            return round_scale(value);
        end if;
    end function;
    
    
    function mult_signed_festkomma(
        a : signed(TOTAL_BITS-1 downto 0);
        b : signed(TOTAL_BITS-1 downto 0)
        )return signed is 
            variable product    : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
            variable rounded    : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
            variable scaled     : signed(TOTAL_BITS + MAX_KERNEL_VALUE-1 downto 0):= (others => '0');
            variable round_bit  : signed(2*TOTAL_BITS-1 downto 0) := (others => '0');
        begin
            -- Multipliaktion ergibt 44 bit
            product := a*b;      
                    
            round_bit(FRAC_BITS-1) := '1';     
            if product >= 0 then
                rounded := product + round_bit;
            else
                rounded := product + round_bit; -- kein Runden, negative Richtung bleibt
            end if;      
            
            scaled := rounded(FRAC_BITS + TOTAL_BITS + MAX_KERNEL_VALUE-1 downto FRAC_BITS);
            
            if product(2*TOTAL_BITS-1) ='0' then 
                scaled(TOTAL_BITS+MAX_KERNEL_VALUE-1) := '0';
            else
                scaled(TOTAL_BITS+MAX_KERNEL_VALUE-1) := '1';
            end if;
        return scaled;
    end function;
            
-- Takt muss um 2 versetzt werden(Takt1 daten holen, Takt2 multiplilkation, Takt3 out)
signal valid_pipe : std_logic_vector(2 downto 0) := (others => '0');
signal valid_out_pip : std_logic := '0';
            
begin
    process(clk)
        variable temp_sum_r, temp_sum_g, temp_sum_b : signed(ADD_WIDTH - 1 downto 0);
    begin
        if rising_edge(clk) then
            valid_pipe <= valid_pipe(1 downto 0) & valid_in;
            if rst = '1' then
                valid_out_pip <= '0';
                valid_pipe <= (others => '0');
                pixel_out <= (others => '0');
                
            elsif valid_in = '1' then
                
                
                -- 1. Kernel-Koeffizienten aus Vektor laden (Festkommaformat)
                for i in 0 to kernel_size*kernel_size-1 loop
                    kernel(i) <= signed(kernel_in(TOTAL_BITS*kernel_size*kernel_size-1-i*TOTAL_BITS 
                                              downto TOTAL_BITS*kernel_size*kernel_size-TOTAL_BITS-i*TOTAL_BITS));                                             
                end loop;
                               
               valid_out_pip <= '1';             
            else
                valid_out_pip <= '0';
                
            end if;                        
                
                -- 2. RGB-Werte aus Fenster extrahieren (Integer-Pixel)
                for i in 0 to kernel_size*kernel_size-1 loop
                   
                    window_r(i) <= unsigned(window_in(i*channels*pixeldeepth+channels*pixeldeepth-1 downto i*channels*pixeldeepth+2*pixeldeepth));
                    window_g(i) <= unsigned(window_in(i*channels*pixeldeepth+(channels-1)*pixeldeepth-1 downto i*channels*pixeldeepth+pixeldeepth));
                    window_b(i) <= unsigned(window_in(i*channels*pixeldeepth+pixeldeepth-1 downto i*channels*pixeldeepth));
                end loop;
                

                
                -- 3. Multiplikation: Festkomma-Pixel * Festkomma-Kernel
                for i in 0 to kernel_size*kernel_size-1 loop
                    -- Pixel zu Festkommaformat konvertieren (Integer * 2^FRAC_BITS)
                    -- dann mit Festkomma-Kernel multiplizieren

                    mult_r(i) <= mult_signed_festkomma((signed(resize(window_r(i), TOTAL_BITS)) sll FRAC_BITS), signed(resize(kernel(i), TOTAL_BITS)));
                    mult_g(i) <= mult_signed_festkomma((signed(resize(window_g(i), TOTAL_BITS)) sll FRAC_BITS), signed(resize(kernel(i), TOTAL_BITS)));
                    mult_b(i) <= mult_signed_festkomma((signed(resize(window_b(i), TOTAL_BITS)) sll FRAC_BITS), signed(resize(kernel(i), TOTAL_BITS)));
                end loop;
                
                -- 4. Summation in Variablen (um korrekte Akkumulation zu gewährleisten)
                temp_sum_r := (others => '0');
                temp_sum_g := (others => '0');
                temp_sum_b := (others => '0');
                
                for i in 0 to kernel_size*kernel_size-1 loop
                    temp_sum_r := temp_sum_r + resize(mult_r(i), ADD_WIDTH);
                    temp_sum_g := temp_sum_g + resize(mult_g(i), ADD_WIDTH);
                    temp_sum_b := temp_sum_b + resize(mult_b(i), ADD_WIDTH);
                end loop;
                
                -- Beobachtungssignal
                sum_r <= temp_sum_r;
                sum_g <= temp_sum_g;
                sum_b <= temp_sum_b;

                -- 6. Sättigung auf 0-255
                pixel_out <= std_logic_vector(saturate_pixel(temp_sum_r)) &
                             std_logic_vector(saturate_pixel(temp_sum_g)) &
                             std_logic_vector(saturate_pixel(temp_sum_b));
                                        
        end if;
    end process;
    valid_out <= valid_pipe(2); -- Ausgabe erst im 3. Takt
end Behavioral;
