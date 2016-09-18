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
	
	component tis50 is
		port(
			clk        : in  std_logic;
			rst        : in  std_logic;
			io_in      : in  std_logic_vector(7 downto 0);
			io_read    : in  std_logic;
			io_out     : in  std_logic_vector(7 downto 0);
			io_write   : in  std_logic;
			mem_addr   : out std_logic_vector(7 downto 0);
			mem_val    : in  std_logic_vector(7 downto 0);
			mem_enable : out std_logic;
			mem_ready  : in  std_logic
			);
	end component;

	procedure tick (signal clk : out std_logic) is	
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end procedure;

	signal clk         : std_logic := '0';

	signal ram_we      : std_logic := '0';
	signal ram_address : std_logic_vector(7 downto 0);
	signal ram_input   : std_logic_vector(7 downto 0);
	signal ram_output  : std_logic_vector(7 downto 0);
	signal ram_enable  : std_logic := '0';
	signal ram_ready   : std_logic := '0';
	
	signal mem_address : std_logic_vector(7 downto 0);
	
	signal port_reg    : std_logic_vector(7 downto 0);	
	signal port_read   : std_logic := '0';
	signal port_write  : std_logic := '0';

begin

	ram0: ram port map (
		clock   => clk, 
		we      => ram_we,
		address => ram_address,
		datain  => ram_input,
		dataout => ram_output
	);
	
	tis0 : tis50 port map (
		clk        => clk,
		rst        => '0',
		io_in      => port_reg,
		io_out     => port_reg,
		io_read    => port_read,
		io_write   => port_write,
		mem_addr   => mem_address,
		mem_val    => ram_output,
		mem_enable => ram_enable,
		mem_ready  => ram_ready
	);

	process
		procedure write(
			signal clk : out std_logic;
			address : in integer;
			value : in integer) is
		begin
			ram_input   <= std_logic_vector(to_unsigned(value, ram_input'length));
			ram_address <= std_logic_vector(to_unsigned(address, ram_address'length));
			ram_we <= '1';
			tick(clk => clk);
			ram_we <= '0';
		end procedure;
	begin
		wait for 1 ns;
		
		write(
			clk => clk, 
			address => 0, 
			value => 1); -- SWP
		write(
			clk => clk, 
			address => 1, 
			value => 2); -- SAV
		write(
			clk => clk, 
			address => 2, 
			value => 0); 
		write(
			clk => clk, 
			address => 3, 
			value => 0);
		
		for i in 0 to 13 loop
			if ram_enable = '1' then
				ram_address <= mem_address;
				ram_ready <= '1';
			else
				ram_ready <= '0';
			end if;
			
			if port_write = '1' then
				report "Writing " & integer'image(to_integer(signed(port_reg))) & " to the port";
			end if;

			tick(clk => clk);
		end loop;
		
		-- assert false report "end of test" severity note;
		wait;
	end process;

end;