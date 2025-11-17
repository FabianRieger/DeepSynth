----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/06/2025 10:37:33 AM
-- Design Name: 
-- Module Name: conv_nxn_core - Behavioral
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


-- Funktioniert in der Regel zuerst nur mit bitdeepth und pixeldeep = 8;

entity conv_nxn_core is
    generic  (
        bitdeepth : integer := 8;        --Auflösung der Werte
        kernel_size: integer :=3;         --Kernel Size
        pixeldeepth: integer := 8         -- Pixeltiefe
        );
    
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic ;
        valid_out: out std_logic;
        
        -- 3x3 RGB Fenster: 9 x (R,G,B) je 8 Bit =216 Bit
        --window_in : in std_logic_vector (215 downto 0);
        -- generischer Code
        window_in : in std_logic_vector (kernel_size*kernel_size*pixeldeepth-1 downto 0);
        
        -- 3x3 Kernel:  je 8 Bit =72 Bit
        --kernel_in : in std_logic_vector (71 downto 0);
        -- generischer Code
        kernel_in : in std_logic_vector(bitdeepth*kernel_size*kernel_size-1 downto 0);
        
        -- generischer Code: Output sind 3 pixelfarbwerte
        pixel_out : out std_logic_vector (3*pixeldeepth-1 downto 0)
            
        
    );
end conv_nxn_core;


architecture Behavioral of conv_nxn_core is
    signal sum_r, sum_g, sum_b : integer;
    
    type pixel_array is array (0 to kernel_size*kernel_size-1) of unsigned(pixeldeepth downto 0);
    type kernel_array is array (0 to kernel_size*kernel_size-1) of signed(bitdeepth downto 0);
    type mult_array is array (0 to kernel_size*kernel_size-1) of integer;
    
    signal window_r, window_g, window_b : pixel_array;
    signal kernel : kernel_array;
    
    signal mult_r, mult_g, mult_b : mult_array;
    

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out <= '0';
                pixel_out <= (others => '0');
                
            elsif valid_in = '1' then
                
                -- Kernel_koeffizienten aus Vektor laden
                for i in 0 to 8 loop
                    -- generic
                    --kernel(i) <= signed(kernel_in(bitdeepth*kernel_size*kernel_size-1-i*bitdeepth downto bitdeepth*kernel_size*kernel_size-bitdeepth -i*bitdeepth));
                    kernel(i) <= signed(kernel_in(71 - i*8 downto 64-i*8));
                end loop;
                
                -- Extrahiere RGB-Werte aus Fenster (je 24 Bit)
                for i in 0 to 8 loop
                    window_r(i) <= unsigned(window_in(i*24+23 downto i*24+16));
                    window_g(i) <= unsigned(window_in(i*24+15 downto i*24+8));
                    window_b(i) <= unsigned(window_in(i*24+7 downto i*24));
                end loop;
                
                -- Multiplikation
                for i in 0 to 8 loop
                    mult_r(i) <= to_integer(resize(window_r(i),16)) + to_integer(kernel(i));
                    mult_g(i) <= to_integer(resize(window_r(i),16)) + to_integer(kernel(i));
                    mult_b(i) <= to_integer(resize(window_r(i),16)) + to_integer(kernel(i));
                end loop;
                
                -- Summieren
                sum_r <= 0;
                sum_g <= 0;
                sum_b <= 0;
                
                for i in 0 to 8 loop
                    sum_r <= sum_r + mult_r(i);
                    sum_g <= sum_g + mult_g(i);
                    sum_b <= sum_b + mult_b(i);
                end loop;
                
                -- Werte auf 0-255 begrenzen
                if sum_r > 255 then sum_r <= 255;
                elsif sum_r <0 then sum_r <= 0;
                end if;

                if sum_g > 255 then sum_g <= 255;
                elsif sum_g <0 then sum_g <= 0;
                end if;
                
                if sum_b > 255 then sum_b <= 255;
                elsif sum_b <0 then sum_b <= 0;
                end if;
                
                -- Output
                pixel_out <= std_logic_vector(to_unsigned(sum_r,8)) &
                             std_logic_vector(to_unsigned(sum_g, 8)) &
                             std_logic_vector(to_unsigned(sum_b, 8));
                             
                valid_out <= '1';
                
            else
                valid_out <= '0';
            end if;
          
        end if;
        
    end process;
    
end Behavioral;
