library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tis50 is

	port(
		clk        : in    std_logic;
		rst        : in    std_logic;
		io_in      : in    std_logic_vector(7 downto 0);
		io_out     : in    std_logic_vector(7 downto 0);
		mem_addr   : out   std_logic_vector(7 downto 0);
		mem_val    : in    std_logic_vector(7 downto 0);
		mem_enable : out   std_logic;
		mem_ready  : in    std_logic
		);

end tis50;

architecture standard of tis50 is
	
	type fsm_state_type is (
		Init,
		Fetch,
		FetchMore,
		Decode
	);
	
	signal IP          : std_logic_vector(7 downto 0);
	signal ACC         : std_logic_vector(7 downto 0);
	signal BAK         : std_logic_vector(7 downto 0);
	
	signal instr_coded : std_logic_vector(7 downto 0);
	signal instruction : std_logic_vector(3 downto 0);
	signal info1       : std_logic_vector(3 downto 0);
	signal info2       : std_logic_vector(7 downto 0);
	signal fsm_state   : fsm_state_type := Init;
	
begin

	instruction <= instr_coded(3 downto 0);
	info1       <= instr_coded(7 downto 4);

	process (clk)
	begin
		if rising_edge(clk) then
			case fsm_state is
				when Init =>
					IP        <= std_logic_vector(to_unsigned(0, IP'Length));
					ACC       <= std_logic_vector(to_unsigned(0, ACC'Length));
					BAK       <= std_logic_vector(to_unsigned(0, BAK'Length));
					fsm_state <= Fetch;
				when Fetch =>
					mem_addr    <= IP;
					instr_coded <= mem_val;
					IP          <= std_logic_vector(unsigned(IP) + to_unsigned(1, IP'Length));
					if instruction(3) = '1' then
						fsm_state <= FetchMore;
					else
						fsm_state <= Decode;
					end if;
				when FetchMore =>
					mem_addr <= IP;
					info2 <= mem_val;
					IP <= std_logic_vector(unsigned(IP) + to_unsigned(1, IP'Length));
					fsm_state <= Decode;
				when Decode =>
					
				
				when others =>
					fsm_state <= Fetch;
			end case;
			
		end if;
	end process;


end standard;