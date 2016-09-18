library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tis50 is

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

end tis50;

architecture standard of tis50 is
	
	type fsm_state_type is (
		Init,
		Fetch,
		Fetch_Ready,
		FetchMore,
		FetchMore_Ready,
		Decode,
		ADD_SRC,
		ADD_IMM,
		SUB_SRC,
		SUB_IMM,
		MOV_SRC,
		MOV_IMM,
		JRO_SRC,
		JRO_IMM,
		JMP
	);
	
	signal IP          : std_logic_vector(7 downto 0);
	signal ACC         : std_logic_vector(7 downto 0);
	signal BAK         : std_logic_vector(7 downto 0);
	
	signal instr_coded : std_logic_vector(7 downto 0);
	signal instruction : std_logic_vector(3 downto 0);
	signal info1       : std_logic_vector(3 downto 0);
	signal info2       : std_logic_vector(7 downto 0);
	
	signal fsm_state   : fsm_state_type := Init;

	signal current_state : integer;
	
begin

	instruction <= instr_coded(3 downto 0);
	info1       <= instr_coded(7 downto 4);

	process (clk, rst)
	begin
		if rst = '1' then
			fsm_state <= Init;
		end if;
		if rising_edge(clk) then
			case fsm_state is
				when Init =>
					current_state <= 0;
					IP         <= std_logic_vector(to_unsigned(0, IP'Length));
					ACC        <= std_logic_vector(to_unsigned(0, ACC'Length));
					BAK        <= std_logic_vector(to_unsigned(0, BAK'Length));
					mem_enable <= '0';
					fsm_state  <= Fetch;
					
				when Fetch =>
					current_state <= 1;
					mem_addr    <= IP;
					mem_enable  <= '1';
					if mem_ready = '1' then
						fsm_state <= Fetch_Ready;
					end if;
				
				when Fetch_Ready =>
					current_state <= 2;
					instr_coded <= mem_val;
					mem_enable  <= '0';
					IP          <= std_logic_vector(unsigned(IP) + to_unsigned(1, IP'Length));
					if mem_val(3) = '1' then
						fsm_state <= FetchMore;
					else
						fsm_state <= Decode;
					end if;
				
				when FetchMore =>
					current_state <= 3;
					mem_addr   <= IP;
					mem_enable <= '1';
					if mem_ready = '1' then
						fsm_state <= FetchMore_Ready;
					end if;
				
				when FetchMore_Ready =>
					current_state <= 4;
					mem_enable  <= '0';
					info2       <= mem_val;
					IP          <= std_logic_vector(unsigned(IP) + to_unsigned(1, IP'Length));
					fsm_state   <= Decode;
				
				when Decode =>
					current_state <= 5;
					case to_integer(unsigned(instruction)) is
						when 0 => -- NOP
							fsm_state <= Fetch;
							
						when 1 => -- SWP
							ACC <= BAK;
							BAK <= ACC;
							fsm_state <= Fetch;
						
						when 2 => -- SAV
							BAK <= ACC;
							fsm_state <= Fetch;
						
						when 3 => -- ADD <SRC>
							fsm_state <= ADD_SRC;
						
						when 4 => -- SUB <SRC>
							fsm_state <= SUB_SRC;
						
						when 5 => -- NEG
							ACC <= std_logic_vector(-signed(ACC));
							fsm_state <= Fetch;
						
						when 6 => -- JRO <SRC>
							fsm_state <= JRO_SRC;
						
						when 8 => -- MOV <SRC>, <DST>
							fsm_state <= MOV_SRC;
						
						when 9 => -- MOV <IMM>, <DST>
							fsm_state <= MOV_IMM;
						
						when 10 => -- ADD <IMM>
							ACC <= std_logic_vector(signed(ACC) + signed(info2));
							fsm_state <= Fetch;
						
						when 11 => -- SUB <IMM>
							ACC <= std_logic_vector(signed(ACC) - signed(info2));
							fsm_state <= Fetch;
						
						when 12 => -- JMP, JEZ, JNZ, JGZ, JLZ
							case info1 is
								when "0000" => -- JMP
									IP <= info2;
									fsm_state <= Fetch;
								
								when "0001" => -- JEZ
									if signed(ACC) = 0 then
										IP <= info2;
									end if;
									fsm_state <= Fetch;
								
								when "0010" => -- JNZ
									if signed(ACC) /= 0 then
										IP <= info2;
									end if;
									fsm_state <= Fetch;
								
								when "0011" => -- JGZ
									if signed(ACC) > 0 then
										IP <= info2;
									end if;
									fsm_state <= Fetch;
								
								when "0100" => -- JLZ
									if signed(ACC) < 0 then
										IP <= info2;
									end if;
									fsm_state <= Fetch;
								
								when others =>
									fsm_state <= Init;
							end case;
						
						when 13 => -- JRO <IMM>
							IP <= std_logic_vector(unsigned(IP) + unsigned(info2));
							fsm_state <= Fetch;
						
						when others =>
							fsm_state <= Init;
					end case;
				when others =>
					current_state <= 99;
					fsm_state <= Init;
			end case;
			
		end if;
	end process;


end standard;