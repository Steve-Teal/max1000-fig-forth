---------------------------------------------------------------------------------------------------
--
-- General purpose input/output Module
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
-- Bits 0 to 21 are bi-directional, bits 22 to 29 are out only
--
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gpio is
	port (
	   clock        : in std_logic;
		reset_n      : in std_logic;
		data_in      : in std_logic_vector(7 downto 0);
		data_out     : out std_logic_vector(7 downto 0);
		wr_n         : in std_logic;
		rd_n         : in std_logic;
		address      : in std_logic_vector(15 downto 0);
		inputs       : in std_logic_vector(21 downto 0);
		outputs      : out std_logic_vector(29 downto 0);
		tristates    : out std_logic_vector(21 downto 0));
end gpio;

architecture rtl of gpio is

	signal output_reg   : std_logic_vector(29 downto 0);
	signal tristate_reg : std_logic_vector(21 downto 0);
	signal addressed    : std_logic;
	signal write_enable : std_logic;
	signal read_enable  : std_logic;
	signal read_mux     : std_logic_vector(7 downto 0);

begin

	addressed <= '1' when address(15 downto 3) = "1111111111111" else '0';
	read_enable <= addressed and not rd_n;
	write_enable <= addressed and not wr_n;
	outputs <= output_reg;
	tristates <= tristate_reg;
	
	data_out <= read_mux when read_enable = '1' else X"00";
	
	--
	-- Read mux
	--
	
	with address(2 downto 0) select read_mux <=
		inputs(7 downto 0)                when "000",
		inputs(15 downto 8)               when "001",
		"00" & inputs(21 downto 16)       when "010",
		output_reg(29 downto 22)          when "011",
		tristate_reg(7 downto 0)          when "100",
		tristate_reg(15 downto 8)         when "101",
		"00" & tristate_reg(21 downto 16) when "110",
		X"00" when others;
		
	--
	-- Register writes
	--
	
	process(clock, reset_n)
	begin
		if reset_n = '0' then
			output_reg <= (others=>'0');
			tristate_reg <= (others=>'0');
		elsif rising_edge(clock) then
			if write_enable = '1' then
				case address(2 downto 0) is
					when "000" => output_reg(7 downto 0) <= data_in;
					when "001" => output_reg(15 downto 8) <= data_in;
					when "010" => output_reg(21 downto 16) <= data_in(5 downto 0);
					when "011" => output_reg(29 downto 22) <= data_in;
					when "100" => tristate_reg(7 downto 0) <= data_in;
					when "101" => tristate_reg(15 downto 8) <= data_in;
					when "110" => tristate_reg(21 downto 16) <= data_in(5 downto 0);
					when others => null;
				end case;
			end if;
		end if;
	end process;

end rtl;

-- End of file