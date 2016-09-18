library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is 

end testbench;

architecture default of testbench is

	component ram is 
		port (
			clock   : in  std_logic;
			we      : in  std_logic;
			address : in  std_logic_vector;
			datain  : in  std_logic_vector;
			dataout : out std_logic_vector
		);
	end component;

	procedure tick (signal clk : out std_logic) is
	
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end procedure;

	signal clk : std_logic := '0';
	signal we : std_logic;

	signal ram_address : std_logic_vector(7 downto 0);
	signal ram_input : std_logic_vector(7 downto 0);
	signal ram_output : std_logic_vector(7 downto 0);
	
begin

	ram0: ram port map (
		clock   => clk, 
		we      => we,
		address => ram_address,
		datain  => ram_input,
		dataout => ram_output
	);

	process
	begin
		wait for 1 ns;
		
		ram_input <= "00000010";
		ram_address <= "00000000";
		we <= '1';
		
		tick(clk => clk);
		
		ram_input <= "00000100";
		ram_address <= "00000001";
		we <= '1';
		
		tick(clk => clk);
		
		we <= '0';
		ram_address <= "00000000";
		
		tick(clk => clk);
		we <= '0';
		ram_address <= "00000001";
		
		tick(clk => clk);
		
		-- assert false report "end of test" severity note;
		wait;
	end process;

end;