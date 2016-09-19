library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tis100 is

	port(
		clk        : in  std_logic;
		rst        : in  std_logic;
		hlt        : out std_logic;
		io_in      : in  std_logic_vector(7 downto 0);
		io_out     : out std_logic_vector(7 downto 0);
		io_read    : out std_logic := '0';
		io_write   : out std_logic := '0';
		io_ready   : in  std_logic;
		io_port    : out std_logic_vector(2 downto 0);
		mem_addr   : out std_logic_vector(7 downto 0);
		mem_val    : in  std_logic_vector(7 downto 0);
		mem_enable : out std_logic;
		mem_ready  : in  std_logic
		);

end tis100;

architecture standard of tis100 is
	
	type fsm_state_type is (
		Init,
		Halted,
		Fetch,
		Fetch_Ready,
		FetchMore,
		FetchMore_Ready,
		Decode,
		ADD_IMM,
		SUB_IMM,
		JRO_IMM,
		READ_SRC, -- requires fsm_state_nx
		MOV_IMM,
		MOV_IMM_PORT
	);
	
	signal IP           : std_logic_vector(7 downto 0);
	signal ACC          : std_logic_vector(7 downto 0);
	signal BAK          : std_logic_vector(7 downto 0);
	
	signal instr_coded  : std_logic_vector(7 downto 0);
	signal instruction  : std_logic_vector(3 downto 0);
	signal info1        : std_logic_vector(3 downto 0);
	signal info2        : std_logic_vector(7 downto 0);
	
	signal fsm_state    : fsm_state_type := Init;
	signal fsm_state_nx : fsm_state_type := Init;
	signal src_index    : std_logic_vector(3 downto 0);
	
	signal current_state : integer;
	
	signal port_writing : std_logic := '0';
	
begin

	instruction <= instr_coded(3 downto 0);
	info1       <= instr_coded(7 downto 4);

	process (clk, rst)
	begin
		if rst = '1' then
			fsm_state <= Init;
		end if;
		if fsm_state = Halted then
			hlt <= '1';
		else
			hlt <= '0';
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
				
				when Halted =>
					-- Does nothing anymore...
				
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
							src_index    <= info1;
							fsm_state_nx <= ADD_IMM;
							fsm_state    <= READ_SRC;
						
						when 4 => -- SUB <SRC>
							src_index    <= info1;
							fsm_state_nx <= SUB_IMM;
							fsm_state    <= READ_SRC;
						
						when 5 => -- NEG
							ACC <= std_logic_vector(-signed(ACC));
							fsm_state <= Fetch;
						
						when 6 => -- JRO <SRC>
							src_index    <= info1;
							fsm_state_nx <= JRO_IMM;
							fsm_state    <= READ_SRC;
						
						when 7 => -- HLT
							fsm_state <= Halted;
						
						when 8 => -- MOV <SRC>, <DST>
							src_index    <= info2(3 downto 0);
							fsm_state_nx <= MOV_IMM;
							fsm_state    <= READ_SRC;
						
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
									assert false report "Invalid jump opcode." severity failure;
							end case;
						
						when 13 => -- JRO <IMM>
							IP <= std_logic_vector(unsigned(IP) + unsigned(info2) - 2);
							fsm_state <= Fetch;
						
						when others =>
							assert false
								report "Invalid opcode:" & integer'image(to_integer(unsigned(instruction)))
								severity failure;
							fsm_state <= Init;
					end case;
				
					when READ_SRC =>
						current_state <= 8;
						if src_index(3) = '0' then
							case src_index is
								when "0001" =>
									info2 <= ACC;
									fsm_state <= fsm_state_nx;
								
								when "0010" =>
									info2 <= std_logic_vector(to_signed(0, info2'length));
									fsm_state <= fsm_state_nx;
								when others =>
									assert false
										report "Invalid <SRC>:" & integer'image(to_integer(unsigned(src_index)))
										severity failure;
									fsm_state <= Init;
							end case;
						else
							io_read <= '1';
							io_port <= src_index(2 downto 0);
							if io_ready = '1' then
								info2 <= io_in;
								fsm_state <= fsm_state_nx;
								io_read <= '0';
							end if;						
						end if;

					when ADD_IMM => -- ADD <IMM>
						ACC <= std_logic_vector(signed(ACC) + signed(info2));
						fsm_state <= Fetch;
					
					when SUB_IMM => -- SUB <IMM>
						ACC <= std_logic_vector(signed(ACC) - signed(info2));
						fsm_state <= Fetch;
					
					when JRO_IMM => -- JRO <IMM>
						IP <= std_logic_vector(unsigned(IP) + unsigned(info2) - 2);
						fsm_state <= Fetch;
						
						
					-- Will provide MOV info2, <DST>
					-- Is jumped from
					-- MOV <SRC>, <DST> and
					-- MOV <IMM>, <DST>
					when MOV_IMM =>
						current_state <= 6;
						if info1(3) = '0' then
							case info1 is
								when "0001" =>
									ACC <= info2;
									fsm_state <= Fetch;
									
								when "0010" =>
									ACC <= std_logic_vector(to_unsigned(0, ACC'Length));
									fsm_state <= Fetch;
								
								when others =>
									assert false
										report "Invalid <DST>:" & integer'image(to_integer(unsigned(info1)))
										severity failure;
									fsm_state <= Init;
							end case;
						else
							io_write <= '1';
							io_port  <= info1(2 downto 0);
							if io_ready = '1' then
								port_writing <= '1';
								io_out <= info2;
								fsm_state <= MOV_IMM_PORT;
							end if;
						end if;

					when MOV_IMM_PORT =>
						current_state <= 7;
						io_write <= '0';
						port_writing <= '0';
						fsm_state <= Fetch;
				
				when others =>
					current_state <= 99;
					fsm_state <= Init;
					
					assert false report "Invalid state: " & fsm_state_type'image(fsm_state) severity failure;
					
			end case;
			
		end if;
	end process;


end standard;