----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/05/2022 01:44:58 PM
-- Design Name: 
-- Module Name: lab_rw_comp1_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity conv_core_tb is
--  Port ( );
end conv_core_tb;

architecture Behavioral of conv_core_tb is

    component writefile_comp_1pixel_rgb
      generic(
            FileName : string := "/home/rif45011/Documents/CNN/output_image_Conv_layer_ones.dat"  
      );
      Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            valid: in  STD_LOGIC;
            data : in  STD_LOGIC_VECTOR (37 downto 0)
      );
    end component;
    
    component readfile_comp_bin_rgb
      generic(
            FileName : string := "/home/rif45011/Documents/CNN/input_image.dat"
   
      );
      Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            valid: out STD_LOGIC;
            ready: in  STD_LOGIC;
            data : out STD_LOGIC_VECTOR (23 downto 0)
      );
    end component;  
    
    
    component Conv_Layer
        generic (
        WIDTH  : integer := 640;
        HEIGHT : integer := 480;
        KERNEL_SIZE: integer :=3;         --Kernel Size
        Stride: integer := 1;
        CHANNELS: integer := 3;           -- Anzahl channels (rgb = 3) Funktioniert momentan nur mit 3
        
        TOTAL_BITS_WEIGHT : integer := 25;        --Auflösung der Werte
        FRAC_BITS_WEIGHT : integer := 16;       -- Nachkommastellen
        INT_BITS_WEIGHT : integer := 8;         -- Ganzzahlstellen (ohne Vorzeichen)
        
        TOTAL_BITS_IN : integer := 8;
        INT_BITS_IN: integer := 8;
        FRAC_BITS_IN : integer := 0;
        
         -- Convolution Parameter
        MAX_KERNEL_VALUE: integer := integer(ceil(log2(real(9))))  -- Maximale Wert Eines Kernel Inhalts
        );
        port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        pixel_in   : in  std_logic_vector(CHANNELS*TOTAL_BITS_IN - 1 downto 0);
        valid_in   : in  std_logic;
        kernel_in  : in std_logic_vector(TOTAL_BITS_WEIGHT*KERNEL_SIZE*KERNEL_SIZE*CHANNELS-1 downto 0);
        pixel_out  : out std_logic_vector(integer(ceil(log2(real(2**(INT_BITS_WEIGHT*2)*KERNEL_SIZE**2*CHANNELS))))+FRAC_BITS_WEIGHT +1 -1 downto 0);
        valid_out  : out std_logic
            );
    end component;
      
    -- 3x3 Kernel, alle Werte = 1.0
    -- 1.8.16: Vorzeichen=0, Ganzzahl=1, Nachkommabits=0000...0
    constant kernel_all_ones : std_logic_vector(224 downto 0) :=
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000" & -- 1.0
    "0000000010000000000000000";  -- 1.0
    
    
 
    --0.914151   -3.119952    2.251354
    --2.821694   -5.853106   -3.906539
    --0.383521   -0.948728   -0.050403

    -- 3x3 Kernel, Gaußverteilung um 0, Bereich ca. ±9
    -- Format: 1 Vorzeichenbit + 8 Ganzzahlbits + 16 Nachkommabits
    constant kernel_gauss : std_logic_vector(224 downto 0) :=
    "0000000001110101000111101" & --  0.914151
    "1111111001110000111111101" & -- -3.119952
    "0000000010100000100000111" & --  2.251354
    "0000000010110100110001001" & --  2.821694
    "1111110100110110110111011" & -- -5.853106
    "1111111000001110010000101" & -- -3.906539
    "0000000001100011000001101" & --  0.383521
    "1111111111110001111010110" & -- -0.948728
    "1111111111111110111101000";  -- -0.050403
    
    constant kernel_kantenerkennung : std_logic_vector(674 downto 0) :=
    "1111111101100000000000000" & -- -1.25
    "1111111110001100110011010" & -- -0.90
    "1111111101110011001100110" & -- -1.10
    "1111111110000110011001101" & -- -0.95
    "0000010000100110011001101" & -- 8.30
    "1111111110010011001100110" & -- -0.85
    "1111111101101100110011010" & -- -1.15
    "1111111110000110011001101" & -- -0.95
    "1111111101100110011001101" &  -- -1.20
    "1111111101100000000000000" & -- -1.25
    "1111111110001100110011010" & -- -0.90
    "1111111101110011001100110" & -- -1.10
    "1111111110000110011001101" & -- -0.95
    "0000010000100110011001101" & -- 8.30
    "1111111110010011001100110" & -- -0.85
    "1111111101101100110011010" & -- -1.15
    "1111111110000110011001101" & -- -0.95
    "1111111101100110011001101" &  -- -1.20
    "1111111101100000000000000" & -- -1.25
    "1111111110001100110011010" & -- -0.90
    "1111111101110011001100110" & -- -1.10
    "1111111110000110011001101" & -- -0.95
    "0000010000100110011001101" & -- 8.30
    "1111111110010011001100110" & -- -0.85
    "1111111101101100110011010" & -- -1.15
    "1111111110000110011001101" & -- -0.95
    "1111111101100110011001101";  -- -1.20

    
    signal clk     :  STD_LOGIC := '0';
    signal rst     :  STD_LOGIC := '0';
    
    signal valid_w :  STD_LOGIC := '0';
    signal ready_w :  STD_LOGIC := '0';
    signal data_w  :  STD_LOGIC_VECTOR (37 downto 0) := (others=>'0');
    
    signal ready_r :  STD_LOGIC := '0';
    signal valid_r :  STD_LOGIC := '0';
    signal data_r  :  STD_LOGIC_VECTOR (24-1 downto 0) := (others=>'0');

    
    signal kernel_in : std_logic_vector(25*3*3*3-1 downto 0) := (others => '0');
    signal pixel_in : std_logic_vector(23 downto 0) := (others=>'0');
    signal pixel_out : std_logic_vector(37 downto 0);
    signal valid_in : std_logic := '0';
    signal valid_out : std_logic := '0';
 


begin

    

  clk <= not clk after 20 ns;
  rst <= '1', '0' after 100 ns;
  
  --ready_w <= '1' after 500 ns, '0' after 650 ns;
  --valid_w <= valid_r;
  --data_w <= std_logic_vector(TO_UNSIGNED(23,c_WIDTH));
  --data_w <= data_r;
  
  ready_r <= '1' after 200 ns;

  kernel_in <= kernel_kantenerkennung;
  valid_in <= valid_r;
  pixel_in <= data_r;
  
  valid_w <= valid_out;
  data_w <= pixel_out;
  
 

    write1: writefile_comp_1pixel_rgb
      generic map(
            FileName => "/home/rif45011/Documents/CNN/output_image_Conv_layer_ones.dat"
            
      )
      Port map( 
            clk   => clk,
            rst   => rst,
            valid => valid_w,
            data  => data_w
      );
      
    read1: readfile_comp_bin_rgb
      generic map(
            FileName => "/home/rif45011/Documents/CNN/input_image.dat"          
      )
      Port map( 
            clk   => clk,
            rst   => rst,
            ready => ready_r,
            valid => valid_r,
            data  => data_r
      );    
      
     
      
    uut_conv: Conv_Layer
        port map(
            clk => clk,
            rst => rst,
            pixel_in => pixel_in,
            pixel_out => pixel_out,
            valid_in => valid_in,
            valid_out => valid_out,
            kernel_in => kernel_in
    );  
    

end Behavioral;