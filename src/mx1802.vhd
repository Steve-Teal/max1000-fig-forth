---------------------------------------------------------------------------------------------------
--
-- 1802 CPU Module
--
---------------------------------------------------------------------------------------------------
--
-- This file is part of the max1000-fig-forth Project
-- Copyright (C) 2020 Steve Teal
-- 
-- This source file may be used and distributed without restriction provided that this copyright
-- statement is not removed from the file and that any derivative work contains the original
-- copyright notice and the associated disclaimer.
-- 
-- This source file is free software; you can redistribute it and/or modify it under the terms
-- of the GNU Lesser General Public License as published by the Free Software Foundation,
-- either version 3 of the License, or (at your option) any later version.
-- 
-- This source is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-3.0.en.html
--
---------------------------------------------------------------------------------------------------
--
-- TODO:
-- 		Implement/test IDL instruction
--
---------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mx1802 is 
	port(  
		clock:		in std_logic;
		ce:			in std_logic;
		reset_n:	in std_logic;
		data_in:	in std_logic_vector(7 downto 0);
		data_out:	out std_logic_vector(7 downto 0);
		address:	out std_logic_vector(15 downto 0);
		ef:			in std_logic_vector(3 downto 0);
		nout:	 	out std_logic_vector(2 downto 0);
		qout:		out std_logic;
		rd_n:		out std_logic;
		wr_n:		out std_logic;
		int_n:      in std_logic;
		dma_in_n:   in std_logic;
		dma_out_n:  in std_logic;
		s:          out std_logic_vector(1 downto 0));
end mx1802;

architecture rtl of mx1802 is
	-- Processor registers
	signal n : std_logic_vector(3 downto 0);
	signal i : std_logic_vector(3 downto 0);
	signal p : std_logic_vector(3 downto 0);
	signal x : std_logic_vector(3 downto 0);
	signal t : std_logic_vector(7 downto 0);
	signal d : std_logic_vector(7 downto 0);
	signal b : std_logic_vector(7 downto 0);  
	signal df : std_logic;
	signal ie : std_logic;
	signal q  : std_logic;

	-- Register file
	type reg_file_type is array (0 to 15) of unsigned(15 downto 0);
	signal reg_file			: reg_file_type;
	signal reg_file_out		: unsigned(15 downto 0);	
	signal reg_file_in		: unsigned(15 downto 0);
	signal reg_file_add		: unsigned(15 downto 0);
	signal reg_file_address	: unsigned(3 downto 0);
	
	-- Register file control
	signal reg_file_write_hi	: std_logic;
	signal reg_file_write_lo	: std_logic;
	signal reg_file_write_exec	: std_logic;
	signal reg_file_source		: std_logic_vector(1 downto 0);
	
	-- State and timing control
	type state_type is (initialize, fetch, execute, longbranch, interrupt, dmain, dmaout);
	signal  state : state_type;
	signal t1, t2 : std_logic;
	
	-- Instruction decode signals
	signal idl,ldn,inc,dec,sbr,lda,str,inp,outp,glo,ghi,plo,phi : std_logic;
	signal lbr,sep,sex,retdis,ldxa,stxd,sav,mark,reqseq : std_logic;
	signal shift,arithmetic,logic,immd,index,lsie : std_logic;
	
	-- Conditional branch / skip signals
	signal cond_src_sel : std_logic_vector(2 downto 0);
	signal condition_mux : std_logic;
	signal condition : std_logic;
	signal take_branch : std_logic;
	signal lbr_reg_we : std_logic;
	
	signal load_b : std_logic;
	signal read_op : std_logic;
	signal carry_in : std_logic;
	
	signal adder : std_logic_vector(8 downto 0);
	signal adder_a_in : std_logic_vector(8 downto 0);
	signal adder_b_in : std_logic_vector(8 downto 0);

		
	signal d_src_sel : std_logic_vector(2 downto 0);
	signal d_src : std_logic_vector(7 downto 0);
	signal d_zero_reg : std_logic;
	signal d_zero : std_logic;


	
	signal reset_reg : std_logic;
	signal reset : std_logic;
	
	-- State output constants
	constant s_fetch:     std_logic_vector(1 downto 0) := "00";
	constant s_execute:   std_logic_vector(1 downto 0) := "01";
	constant s_dma:       std_logic_vector(1 downto 0) := "10";
	constant s_interrupt: std_logic_vector(1 downto 0) := "11";
	

	
begin
	
	--
	--
	--
	
	address <= std_logic_vector(reg_file_out);
	qout <= q;
	
	--
	-- Reset
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			reset_reg <= reset_n;			
			reset <= not reset_reg;
		end if;
	end process;
	
	--
	-- Timing
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				t1 <= '0';
				t2 <= '0';
			elsif ce = '1' then
				t1 <= not t1;
				t2 <= t1;
			end if;
		end if;
	end process;
	--
	-- State machine
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				state <= initialize;
				s <= s_fetch;
			elsif (t2 and ce) = '1' then
				case state is
					when initialize =>
						if dma_in_n = '0' then
							state <= dmain;
							s <= s_dma;
						else
							state <= fetch;
							s <= s_fetch;
						end if;
					when fetch =>
						if idl = '0' then
							state <= execute;
							s <= s_execute;
						end if;
					when execute =>
						if lbr = '1' then
							state <= longbranch;
						elsif dma_in_n = '0' then
							state <= dmain;
							s <= s_dma;
						elsif dma_out_n = '0' then
							state <= dmaout;
							s <= s_dma;
						elsif int_n = '0' and ie = '1' then
							state <= interrupt;
							s <= s_interrupt;
						else
							state <= fetch;
							s <= s_fetch;
						end if;
					when longbranch =>
						if dma_in_n = '0' then
							state <= dmain;
							s <= s_dma;
						elsif dma_out_n = '0' then
							state <= dmaout;
							s <= s_dma;
						elsif int_n = '0' and ie = '1' then
							state <= interrupt;
							s <= s_interrupt;
						else
							state <= fetch;
							s <= s_fetch;
						end if;
					when dmain =>
						if dma_in_n = '1' then
							if dma_out_n = '0' then
								state <= dmaout;
							elsif int_n = '0' and ie = '1' then
								state <= interrupt;
								s <= s_interrupt;
							else
								state <= fetch;
								s <= s_fetch;
							end if;
						end if;
					when dmaout =>
						if dma_out_n = '1' then
							if dma_in_n = '0' then
								state <= dmain;
							elsif int_n = '0' and ie = '1' then
								state <= interrupt;
								s <= s_interrupt;
							else
								state <= fetch;
								s <= s_fetch;
							end if;
						end if;
					when interrupt =>
						if dma_in_n = '0' then
							state <= dmain;
							s <= s_dma;
						elsif dma_out_n = '0' then
							state <= dmaout;
							s <= s_dma;
						else
							state <= fetch;
							s <= s_fetch;
						end if;
					when others => 
						state <= initialize;
				end case;
			end if;
		end if;
	end process;

	--
	-- Instruction Decoder
	--
	
	--idl <= '1' when n = "0000" and i = "0000" else '0';
	idl <= '0';
	ldn <= '1' when i = "0000" else '0'; -- Includes IDL
	inc <= '1' when i = "0001" else '0';
	dec <= '1' when i = "0010" else '0';
	sbr <= '1' when i = "0011" else '0';
	lda <= '1' when i = "0100" else '0';
	str <= '1' when i = "0101" else '0';
	outp <= '1' when i = "0110" and n(3) = '0' else '0';
	inp  <= '1' when i = "0110" and n(3) = '1' else '0';
	retdis <= '1' when i = "0111" and n(3 downto 1) = "000" else '0';
	ldxa <= '1' when i = "0111" and n = "0010" else '0';
	stxd <= '1' when i = "0111" and n = "0011" else '0';
	sav <= '1' when i = "0111" and n = "1000" else '0';
	mark <= '1' when i = "0111" and n = "1001" else '0';
	reqseq <= '1' when i = "0111" and n(3 downto 1) = "101" else '0';
	glo <= '1' when i = "1000" else '0';
	ghi <= '1' when i = "1001" else '0';
	plo <= '1' when i = "1010" else '0';
	phi <= '1' when i = "1011" else '0';
	lbr <= '1' when i = "1100" else '0';
	sep <= '1' when i = "1101" else '0';
	sex <= '1' when i = "1110" else '0';
	lsie <= '1' when i = "1100" and n = "1100" else '0';
	shift <= '1' when i(2 downto 0) = "111" and n(2 downto 0) = "110" else '0';
	arithmetic <= '1' when i(2 downto 0) = "111" and  n(2) = '1' else '0';
	logic <= '1' when i = "1111" and n(2) = '0' and (n(0) = '1' or n(1) = '1') else '0';
	immd <= '1' when (i = "0111" and n(3 downto 2) = "11") or (i = "1111" and n(3)='1') else '0';
	index <= '1' when (i = "0111" and n(3 downto 2) = "01") or (i = "1111" and n(3)='0') else '0';

	--
	-- Register File
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if ce = '1' then
				if t1 = '1' then
					reg_file_out <= reg_file(to_integer(reg_file_address));					
				elsif t2 = '1' then
					if reg_file_write_lo = '1' then
						reg_file(to_integer(reg_file_address))(7 downto 0) <= reg_file_in(7 downto 0);
					end if;
					if reg_file_write_hi = '1' then
						reg_file(to_integer(reg_file_address))(15 downto 8) <= reg_file_in(15 downto 8);
					end if;
				end if;
			end if;
		end if;
	end process;
	
		
	--
	-- Register source 
	--
	
	reg_file_add <= X"FFFF" when state = execute and (dec or stxd or mark) = '1' else X"0001";
	reg_file_source(0) <= '1' when state = initialize or (state = execute and (plo or phi) = '1') else '0';
	reg_file_source(1) <= '1' when state = initialize or take_branch = '1' else '0';
	
	with reg_file_source select reg_file_in <=
		reg_file_out + reg_file_add when "00",
		unsigned(d) & unsigned(d) when "01",
		unsigned(b) & unsigned(data_in) when "10",
		X"0000" when "11",
		(others=>'X') when others;
	
	
	
	
	--
	-- Register file address selection 
	--
	
	process(state,p,n,x,mark,reqseq,immd,sbr,lbr,ldn,inc,dec,lda,str,glo,ghi,plo,phi,sep,sex)
	begin
		case state is
			when initialize|dmain =>
				reg_file_address <= "0000";
			when fetch|longbranch =>
				reg_file_address <= unsigned(p);
			when execute =>
				if mark = '1' then
					reg_file_address <= "0010";
				elsif (reqseq or immd or sbr or lbr) = '1' then
					reg_file_address <= unsigned(p);
				elsif (ldn or inc or dec or lda or str or glo or ghi or plo or phi or sep or sex) = '1' then
					reg_file_address <= unsigned(n);
				else
					reg_file_address <= unsigned(x);
				end if;
			when interrupt =>
				reg_file_address <= unsigned(n);
			when others =>
				reg_file_address <= "0000";
		end case;
	end process;
	
	--
	-- Register file write control
	--
	
	reg_file_write_exec <= inc or dec or lda or ldxa or outp or retdis or stxd or mark or (immd and not shift) or (sbr and not condition) or lbr_reg_we;
	
	process(state,idl,plo,phi,reg_file_write_exec,sbr)
	begin
		reg_file_write_lo <= '0';
		reg_file_write_hi <= '0';
		case state is
			when initialize|dmain|dmaout =>
				reg_file_write_lo <= '1';
				reg_file_write_hi <= '1';
			when fetch =>
				if idl = '0' then
					reg_file_write_lo <= '1';
					reg_file_write_hi <= '1';
				end if;
			when execute =>
				if (plo or reg_file_write_exec or sbr)='1' then
					reg_file_write_lo <= '1';
				end if;
				if (phi or reg_file_write_exec)='1' then
					reg_file_write_hi <= '1';
				end if;
			when longbranch =>
				if lbr_reg_we = '1' then
					reg_file_write_lo <= '1';
					reg_file_write_hi <= '1';
				end if;
			when others => null;
		end case;
	end process;
	
	--
	-- I and N Registers
	--
	process(clock)
	begin
		if rising_edge(clock) then
			if (ce and t2) = '1' and state = fetch and idl = '0' then
				n <= data_in(3 downto 0);
				i <= data_in(7 downto 4);
			end if;
		end if;
	end process;
	
	--
	-- X,P and T Registers
	--
	process(clock)
	begin
		if rising_edge(clock) then
			if (ce and t2) = '1' then
				case state is
					when initialize =>
						x <= "0000";
						p <= "0000";
						t <= "00000000";
					when execute =>
						if retdis = '1' then
							p <= data_in(3 downto 0);
							x <= data_in(7 downto 4);
						elsif mark = '1' then
							x <= p;
							t <= x & p;
						else
							if sex = '1' then
								x <= n;
							end if;
							if sep = '1' then
								p <= n;
							end if;
						end if;
					when interrupt =>
						p <= "0001";
						x <= "0010";
						t <= x & p;
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	--
	-- D Register
	-- 		

	d_src_sel(0) <= ghi or (shift and n(3)) or (logic and n(0));
	d_src_sel(1) <= glo or ghi or (logic and n(1));
	d_src_sel(2) <= glo or ghi or shift;
	
	with d_src_sel select d_src <=
		adder(7 downto 0) when "000",
		d or b when "001",
		d and b when "010",
		d xor b when "011",
		carry_in & d(7 downto 1) when "100",
		d(6 downto 0) & carry_in when "101",
		std_logic_vector(reg_file_out(7 downto 0)) when "110",
		std_logic_vector(reg_file_out(15 downto 8)) when "111",
		(others=>'0') when others;
		
	d_zero <= '1' when d_src = "00000000" else '0';
	
	process(clock)
	begin
		if rising_edge(clock) then
			case state is
				when fetch =>
					if (ce and t1 and (read_op or inp)) = '1' then
						d <= d_src;
						d_zero_reg <= d_zero;
					end if;
				when execute =>
					if (ce and t2 and (glo or ghi or shift)) = '1' then
						d <= d_src;
						d_zero_reg <= d_zero;
					end if;
				when others => null;
			end case;
		end if;
	end process;
	
	--
	-- DF Register
	--

	process(clock)
	begin
		if rising_edge(clock) then
			case state is
				when fetch =>
					if (ce and t1 and arithmetic) = '1' and shift = '0' then
						df <= adder(8);
					end if;
				when execute =>
					if (ce and t2 and shift) = '1' then
						if n(3) = '1' then
							df <= d(7);
						else
							df <= d(0);
						end if;
					end if;
				when others => null;
			end case;
		end if;
	end process;
		
	--
	-- Adder and carry in
	-- 
			
	adder_a_in <= (others=>'0') when arithmetic = '0' else ('0' & not d) when n(1 downto 0) = "01" else ('0' & d);
	adder_b_in <= ('0' & not b) when (arithmetic and n(0) and n(1)) = '1' else ('0' & b);
	adder <= std_logic_vector(unsigned(adder_a_in) + unsigned(adder_b_in) + ("00000000" & carry_in));
	carry_in <= arithmetic and ((df and not i(3)) or (i(3) and n(0)));
	
	--
	-- Memory read
	--
	
	read_op <= (ldn or lda or ldxa or index or immd) and not shift; 
	load_b <= read_op or inp or lbr;
	
	process(clock)
	begin
		if rising_edge(clock) then
			if (ce and t1) = '1' then
				case state is
					when initialize =>
						rd_n <= '1';
					when fetch | dmaout =>
						rd_n <= '0';
					when execute =>
						rd_n <=  not (read_op or sbr or lbr or outp or retdis);
					when longbranch =>
						rd_n <= '0';
					when others => null;
				end case;
			end if;
			if (ce and t2) = '1' then
				if state = execute and load_b = '1' then
					b <= data_in;
				end if;
				rd_n <= '1';
			end if;
		end if;
	end process;
	
	--
	-- Memory write
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if reset_n = '0' then
				wr_n <= '1';
			elsif ce = '1' then
				if t1 = '1' and state = execute then
					if (str or stxd) = '1' then
						data_out <= d;
						wr_n <= '0';
					elsif sav = '1' then
						data_out <= t;
						wr_n <= '0';
					elsif mark = '1' then
						data_out <= x & p;
						wr_n <= '0';
					elsif inp = '1' then
						wr_n <= '0';
						data_out <= "00000000";
					end if;
				elsif t1 = '1' and state = dmain then
					wr_n <= '0';
					data_out <= "00000000";
				elsif t2 = '1' then
					wr_n <= '1';
				else
					data_out <= "00000000";					
				end if;
			end if;
		end if;
	end process;
	
	--
	-- Q register
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if state = execute and (ce and t2 and reqseq) = '1' then
				q <= n(0);
			end if;
		end if;
	end process;
	
	--
	-- IE Register
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if (ce and t2) = '1' then
				case state is
					when initialize =>
						ie <= '1';
					when execute =>
						if retdis = '1' then
							ie <= not n(0);
						end if;
					when interrupt =>
						ie <= '0';
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	--
	-- N outputs
	--
	
	process(clock)
	begin
		if rising_edge(clock) then
			if (ce and (inp or outp)) = '1' and state = execute then
				if t1 = '1' then
					nout <= n(2 downto 0);
				elsif t2 = '1' then
					nout <= "000";
				end if;
			end if;
		end if;
	end process;
				

	
	--
	-- Condition logic
	--
	
	cond_src_sel(0) <= n(0);
	cond_src_sel(1) <= n(1);
	cond_src_sel(2) <= n(2) and sbr;
	condition <= condition_mux xor n(3) when lsie = '0' else ie;
	take_branch <= '1' when condition = '1' and ((state = execute and sbr = '1') or (state = longbranch and n(2) = '0')) else '0';
	lbr_reg_we <= lbr and (n(2) nand condition);
	
	with cond_src_sel select condition_mux <=
		'1' when "000",
		q when "001",
		d_zero_reg when "010",
		df when "011",
		ef(0) when "100",
		ef(1) when "101",
		ef(2) when "110",
		ef(3) when "111",
		'0' when others;
		
		
	
end rtl;

