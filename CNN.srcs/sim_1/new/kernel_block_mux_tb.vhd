library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_kernel_block_mux is
-- Testbench hat keine Ports
end entity;

architecture Behavioral of tb_kernel_block_mux is

  -- Parameter aus dem Modul
  constant DATA_WIDTH         : integer := 8;
  constant KERNEL_SIZE        : integer := 3;
  constant CHANNELS_TOTAL     : integer := 3;
  constant CHANNELS_PER_BLOCK : integer := 2;
  constant FILTERS_TOTAL      : integer := 4;

  -- Berechnete Größen
  constant OUT_WIDTH: integer := CHANNELS_PER_BLOCK * KERNEL_SIZE * KERNEL_SIZE * DATA_WIDTH;

  -- Signale
  signal clk           : std_logic := '0';
  signal rst           : std_logic := '1';
  signal filter_sel    : unsigned(integer(ceil(log2(real(FILTERS_TOTAL))))-1 downto 0) := (others => '0');
  signal channel_block : unsigned(integer(ceil(log2(real(CHANNELS_TOTAL/CHANNELS_PER_BLOCK))))-1 downto 0) := (others => '0');
  signal kernel_pool   : std_logic_vector(FILTERS_TOTAL*CHANNELS_TOTAL*KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH-1 downto 0);
  signal kernel_out    : std_logic_vector(OUT_WIDTH-1 downto 0);

  -- Für automatische Überprüfung
  signal expected_val : std_logic_vector(OUT_WIDTH-1 downto 0);

begin

  -- Instanziierung des DUT
  DUT: entity work.kernel_block_mux
    port map (
      clk           => clk,
      rst         => rst,
      filter_sel    => filter_sel,
      channel_block => channel_block,
      kernel_pool   => kernel_pool,
      kernel_out    => kernel_out
    );

  -- Taktgenerator: 10 ns Periode
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
  end process;

  -- Initialisierung des Kernel-Pools mit Testdaten
  init_pool : process
    variable idx : integer := 0;
  begin
    for f in 0 to FILTERS_TOTAL-1 loop
      for c in 0 to CHANNELS_TOTAL-1 loop
        for k in 0 to KERNEL_SIZE*KERNEL_SIZE-1 loop
          for b in 0 to DATA_WIDTH-1 loop
            kernel_pool(idx) <= std_logic(to_unsigned(idx mod 5,1)(0)); -- einfache Testdaten
            idx := idx + 1;
          end loop;
        end loop;
      end loop;
    end loop;
    wait;
  end process;

  -- Stimuli-Prozess (synchron auf clk)
  stim : process(clk)
    variable f : integer := 0;
    variable b : integer := 0;
    variable start_idx : integer := 0;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        filter_sel    <= (others => '0');
        channel_block <= (others => '0');
        rst <= '0';  -- Reset nach 1 Takt loslassen
      else
        -- Filter/Block auswählen
        filter_sel    <= to_unsigned(f, filter_sel'length);
        channel_block <= to_unsigned(b, channel_block'length);

        -- Berechne erwarteten Startindex
        start_idx := f*CHANNELS_TOTAL*KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH + b*CHANNELS_PER_BLOCK*KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH;

        -- Slice für Vergleich
        for i in 0 to OUT_WIDTH-1 loop
          expected_val(i) <= kernel_pool(start_idx + i);
        end loop;

        -- Assertion zur Überprüfung
        assert kernel_out = expected_val
        report "Mismatch at filter=" & integer'image(f) & " block=" & integer'image(b)
        severity error;

        -- Inkrementiere Block/Filter
        if b < (CHANNELS_TOTAL/CHANNELS_PER_BLOCK)-1 then
          b := b + 1;
        else
          b := 0;
          if f < FILTERS_TOTAL-1 then
            f := f + 1;
          else

            if f = FILTERS_TOTAL-1 and b = (CHANNELS_TOTAL/CHANNELS_PER_BLOCK)-1 then
                report "Test abgeschlossen" severity note;
                 -- Keine weitere Aktion, alles bleibt auf aktuellen Signalen
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;




