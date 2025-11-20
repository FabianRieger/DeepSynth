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

entity Max_Pooling_tb is
--  Port ( );
end Max_Pooling_tb;

architecture Behavioral of Max_Pooling_tb is

    component writefile_comp_1pixel_rgb
      generic(
            FileName : string := "../../../../TestCode/output_image_Max_Pooling.dat"  
      );
      Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            valid: in  STD_LOGIC;
            data : in  STD_LOGIC_VECTOR (23 downto 0)
      );
    end component;
    
    component readfile_comp_bin_rgb
      generic(
            FileName : string := "../../../../TestCode/input_image.dat"
   
      );
      Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            valid: out STD_LOGIC;
            ready: in  STD_LOGIC;
            data : out STD_LOGIC_VECTOR (23 downto 0)
      );
    end component;  
    
    
    component Max_Pooling_Layer
        generic (
        WIDTH  : integer := 640;
        HEIGHT : integer := 480;
        kernel_size: integer :=2;         --Kernel Size
        pixeldeepth: integer := 8;         -- Pixeltiefe
        Stride: integer := 2
        
        );
        port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        pixel_in   : in  std_logic_vector(3*pixeldeepth-1 downto 0);
        valid_in   : in  std_logic;
        pixel_out  : out std_logic_vector(3*pixeldeepth-1 downto 0);
        valid_out  : out std_logic
            );
    end component;
      

    
    signal clk     :  STD_LOGIC := '0';
    signal rst     :  STD_LOGIC := '0';
    
    signal valid_w :  STD_LOGIC := '0';
    signal ready_w :  STD_LOGIC := '0';
    signal data_w  :  STD_LOGIC_VECTOR (24-1 downto 0) := (others=>'0');
    
    signal ready_r :  STD_LOGIC := '0';
    signal valid_r :  STD_LOGIC := '0';
    signal data_r  :  STD_LOGIC_VECTOR (24-1 downto 0) := (others=>'0');

    
    signal pixel_in : std_logic_vector(23 downto 0) := (others=>'0');
    signal pixel_out : std_logic_vector(3*8-1 downto 0);
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

  valid_in <= valid_r;
  pixel_in <= data_r;
  
  valid_w <= valid_out;
  data_w <= pixel_out;
  
 

    write1: writefile_comp_1pixel_rgb
      generic map(
            FileName => "../../../../TestCode/output_image_Max_Pooling.dat"
            
      )
      Port map( 
            clk   => clk,
            rst   => rst,
            valid => valid_w,
            data  => data_w
      );
      
    read1: readfile_comp_bin_rgb
      generic map(
            FileName => "../../../../TestCode/input_image.dat"          
      )
      Port map( 
            clk   => clk,
            rst   => rst,
            ready => ready_r,
            valid => valid_r,
            data  => data_r
      );    
      
     
      
    uut_conv: Max_Pooling_Layer
        port map(
            clk => clk,
            rst => rst,
            pixel_in => pixel_in,
            pixel_out => pixel_out,
            valid_in => valid_in,
            valid_out => valid_out
    );  
    

end Behavioral;