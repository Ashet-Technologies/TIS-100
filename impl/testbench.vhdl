library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is 

end testbench;

architecture default of testbench is
	
	component tis100 is
		port(
			clk        : in  std_logic;
			rst        : in  std_logic;
			hlt        : out std_logic;
			io_in      : in  std_logic_vector(7 downto 0);
			io_out     : out std_logic_vector(7 downto 0);
			io_read    : out std_logic;
			io_write   : out std_logic;
			io_ready   : in  std_logic;
			io_port    : out std_logic_vector(2 downto 0);
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
	
	function datum (x : integer) 
		return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(x, 8));
	end datum;
	
	function program_memory (addr : std_logic_vector(7 downto 0)) 
		return std_logic_vector is
	begin
		case to_integer(unsigned(addr)) is
			when 0 => return datum(16#98#);
			when 1 => return datum(16#08#);
			when 2 => return datum(16#98#);
			when 3 => return datum(16#08#);
			when 4 => return datum(7);
			when others => return datum(0);
		end case;
	end function;
	
	function input_stream(addr : std_logic_vector(3 downto 0))
		return std_logic_vector is
	begin
		case to_integer(unsigned(addr)) is
			when 0 => return datum(10);
			when 1 => return datum(20);
			when 2 => return datum(30);
			when 3 => return datum(40);
			when others => return datum(0);
		end case;
	end function;

	signal clk          : std_logic := '0';

	signal code_address  : std_logic_vector(7 downto 0);
	signal code_output   : std_logic_vector(7 downto 0);
	signal code_enable   : std_logic := '0';
	signal code_ready    : std_logic := '0';
	
	signal port_reg_in  : std_logic_vector(7 downto 0);
	signal port_reg_out : std_logic_vector(7 downto 0);
	signal port_read    : std_logic := '0';
	signal port_write   : std_logic := '0';
	signal port_ready   : std_logic := '0';
	signal port_num     : std_logic_vector(2 downto 0);
	
	signal halt         : std_logic := '0';
	
	signal port_tb_writing : std_logic := '0';

	signal input_addr   : std_logic_vector(3 downto 0);
	
begin
	
	tis0 : tis100 port map (
		clk        => clk,
		rst        => '0',
		hlt        => halt,
		io_in      => port_reg_in,
		io_out     => port_reg_out,
		io_read    => port_read,
		io_write   => port_write,
		io_ready   => port_ready,
		io_port    => port_num,
		mem_addr   => code_address,
		mem_val    => code_output,
		mem_enable => code_enable,
		mem_ready  => code_ready
	);

	process
		
	begin
		wait for 1 ns;
		
		while halt = '0' loop
			if code_enable = '1' then
				code_output <= program_memory(code_address);
				code_ready <= '1';
			else
				code_ready <= '0';
			end if;
			
			if port_write = '1' and port_read = '1' then
				assert false report "io_read and io_write are both set." severity error;
			end if;
			
			if port_ready = '1' then
				if port_write = '1' then
					report
						"Writing " & 
						integer'image(to_integer(signed(port_reg_out))) & 
						" out of the port(" &
						integer'image(to_integer(unsigned(port_num))) & 
						")";
				end if;
				if port_write = '0' and port_read = '0' then
					port_ready <= '0';
				end if;
				port_tb_writing <= '0';
			else
				if port_write = '1' then
					port_ready <= '1';
				end if;
				if port_read = '1' then
					port_tb_writing <= '1';
					input_addr <= std_logic_vector(unsigned(input_addr) + to_unsigned(1, 4));
					if input_addr = "1111" then
						assert false report "end of input stream" severity note;
						wait;
					end if;
					port_reg_in <= input_stream(input_addr);
					report
						"Reading " & 
						integer'image(to_integer(unsigned(input_stream(input_addr)))) &
						" into the port(" & 
						integer'image(to_integer(unsigned(port_num))) & 
						")";
					port_ready <= '1';
				else
					port_tb_writing <= '0';
				end if;
			end if;
			
			tick(clk => clk);
		end loop;
		
		assert false report "end of test" severity note;
		wait;
	end process;

end;