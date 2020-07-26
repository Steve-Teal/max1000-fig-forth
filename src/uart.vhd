---------------------------------------------------------------------------------------------------
--
-- UART module designed to work with the 1802 IN/OUT interface
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

library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is 
	generic (
		cycles_per_bit: integer;
		data_out_port : integer;
		data_in_port : integer;
		status_in_port : integer);

		port(  
			clock:		in std_logic;
			reset_n:	in std_logic;
			ce:			in std_logic;
			data_in:	in std_logic_vector(7 downto 0);
			data_out:	out std_logic_vector(7 downto 0);
			n:			in std_logic_vector(2 downto 0);
			rd_n:		in std_logic;
			wr_n:		in std_logic;
			tx:         out std_logic;
			rx:         in std_logic;
			cts:        out std_logic;
			rts:        in std_logic);

		
end uart;

architecture rtl of uart is

	-- RX State machine
	type rx_state_type is (RX_IDLE,RX_START,RX_BITS,RX_STOP);
	signal rx_state : rx_state_type;
	
	-- RX signals
	signal rhr : std_logic_vector(7 downto 0); -- Receive holding register
	signal da : std_logic; -- Data Availible 
	signal fe : std_logic; -- Framing error
	signal set_da : std_logic; -- From RX state machine used to set da
	signal clr_da : std_logic; -- From CPU read used to clear da
	signal rsr : std_logic_vector(7 downto 0); -- Receive shift register
	signal rx_baud_counter : unsigned(9 downto 0);
	signal rx_bit_counter : unsigned(2 downto 0);
	signal rx_filter : std_logic_vector(2 downto 0);
	signal rx_filter_out : std_logic;

	-- TX State machine
	type tx_state_type is (TX_IDLE,TX_START,TX_BITS,TX_STOP);
	signal tx_state : tx_state_type;

	-- TX signals
	signal thr : std_logic_vector(7 downto 0); -- Transmit holding register
	signal thre : std_logic; -- Transmit holding register empty
	signal tsr : std_logic_vector(7 downto 0); -- Transmit Shift Register
	signal tx_baud_counter : unsigned(9 downto 0);
	signal tx_bit_counter : unsigned(2 downto 0);
	signal rts_sync : std_logic; -- RTS syncronised
	
	-- Constants
	constant bit_counter_top : unsigned(2 downto 0) := "111";
	constant baud_counter_rx_sample : unsigned(9 downto 0) := to_unsigned((cycles_per_bit - 1)/2,rx_baud_counter'length);
	constant baud_counter_top : unsigned(9 downto 0) := to_unsigned(cycles_per_bit-1,rx_baud_counter'length);
	constant parity_mask : std_logic_vector(7 downto 0) := "01111111";
		
begin	

--
-- Transmit holding register write from CPU
--
	process(clock)
	begin
		if rising_edge(clock) then
			if reset_n = '0' then
				thre <= '1';
			elsif ce = '1' and n = std_logic_vector(to_unsigned(data_out_port,n'length)) and rd_n = '0' then
				thr <= data_in and parity_mask;
				thre <= '0';
			elsif tx_state = TX_IDLE and thre = '0' and rts_sync = '0' then
				thre <= '1';
			end if;
		end if;
	end process;
	
--
-- Receive holding register and status read to CPU
--
	process(clock)
	begin
		if rising_edge(clock) then
			if wr_n = '0' then
				if n = std_logic_vector(to_unsigned(data_in_port,n'length)) then
					data_out <= rhr;
					clr_da <= '1';
				elsif n = std_logic_vector(to_unsigned(status_in_port,n'length)) then
					data_out <= thre & "000" & fe & "00" & da;
					clr_da <= '0';
				else
					data_out <= (others=>'0');
					clr_da <= '0';
				end if;
			else
				clr_da <= '0';
				data_out <= (others=>'0');
			end if;
		end if;
	end process;
	
--
-- Data availible status bit
-- 
	process(clock)
	begin
		if rising_edge(clock) then
			da <= (set_da or (da and not clr_da)) and reset_n;
		end if;
	end process;
	
--
-- CTS and RTS
--
	process(clock)
	begin	
		if rising_edge(clock) then
			if rx_state = RX_IDLE then
				cts <= da;
			else
				cts <= '1';
			end if;
			rts_sync <= rts;
		end if;
	end process;
		
--
-- Receive filter / syncroniser
--
	
	process(clock)
	begin
		if rising_edge(clock) then
			rx_filter <= rx_filter(1 downto 0) & rx;
			if rx_filter = "000" or rx_filter = "001" or rx_filter = "010" or rx_filter = "100" then
				rx_filter_out <= '0';
			else
				rx_filter_out <= '1';
			end if;
		end if;
	end process;
			
--
-- Transmit state machine
--
	process(clock)
	begin
		if rising_edge(clock) then
			if reset_n = '0' then
				tx_state <= TX_IDLE;
				tx <= '1';
				tx_baud_counter <= (others=>'0');
				tx_bit_counter <= "000";
			else
				case tx_state is
				
					when TX_IDLE =>
						if thre = '0' and rts_sync = '0' then
							tx_state <= TX_START;
							tx <= '0';
							tsr <= thr;
						end if;
						
					when TX_START =>
						if tx_baud_counter = baud_counter_top then
							tx <= tsr(0);
							tsr <= '0' & tsr(7 downto 1);
							tx_baud_counter <= (others=>'0');
							tx_state <= TX_BITS;
						else
							tx_baud_counter <= tx_baud_counter + 1;
						end if;
						
					when TX_BITS =>
						if tx_baud_counter = baud_counter_top then
							tx <= tsr(0);
							tsr <= '0' & tsr(7 downto 1);
							tx_baud_counter <= (others=>'0');
							if tx_bit_counter = bit_counter_top then
								tx <= '1';
								tx_state <= TX_STOP;
								tx_bit_counter <= "000";
							else
								tx_bit_counter <= tx_bit_counter + 1;
							end if;
						else
							tx_baud_counter <= tx_baud_counter + 1;
						end if;
						
					when TX_STOP =>
						if tx_baud_counter = baud_counter_top then
							tx_baud_counter <= (others=>'0');
							tx_state <= TX_IDLE;
						else
							tx_baud_counter <= tx_baud_counter + 1;
						end if;
						
				end case;
			end if;
		end if;
	end process;
	
--
-- Receive state machine
--

	process(clock)
	begin
		if rising_edge(clock) then
			if reset_n = '0' then
				rx_state <= RX_IDLE;
				rx_baud_counter <= (others=>'0');
				rx_bit_counter <= "000";
				set_da <= '0';
				fe <= '0';
			else
				case rx_state is
					when RX_IDLE =>
						set_da <= '0';
						if rx_filter_out = '0' then
							rx_state <= RX_START;
							rx_baud_counter <= (others=>'0');
						end if;
						
					when RX_START =>
						rx_baud_counter <= rx_baud_counter + 1;
						if rx_baud_counter = baud_counter_rx_sample then
							if rx = '0' then
								rx_state <= RX_BITS;
							else
								rx_state <= RX_IDLE;
							end if;
						end if;
						
					when RX_BITS =>
						-- Increment and wrap around baud counter
						if rx_baud_counter = baud_counter_top then
							rx_baud_counter <= (others=>'0');
						else
							rx_baud_counter <= rx_baud_counter + 1;
						end if;
						-- Sample RX and increment bit counter
						if rx_baud_counter = baud_counter_rx_sample then
							rsr <= rx_filter_out & rsr(7 downto 1);
							if rx_bit_counter = bit_counter_top then
								rx_bit_counter <= "000";
								rx_state <= RX_STOP;
							else
								rx_bit_counter <= rx_bit_counter + 1;
							end if;
						end if;
						
					when RX_STOP =>
						-- Increment baud counter, change to idle state when counter reaches top
						if rx_baud_counter = baud_counter_top then
							rx_baud_counter <= (others=>'0');
						else
							rx_baud_counter <= rx_baud_counter + 1;
						end if;
						-- Sample STOP bit
						if rx_baud_counter = baud_counter_rx_sample then
							if rx_filter_out = '1' then
								-- STOP bit OK
								rhr <= rsr;
								set_da <= '1';
								fe <= '0';
							else
								-- STOP bit incorrect - framing error
								fe <= '1';
							end if;
							rx_state <= RX_IDLE;
						end if;
						
				end case;
			end if;
		end if;
	end process;
		
end rtl;

-- End of file


