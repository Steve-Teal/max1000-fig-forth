---------------------------------------------------------------------------------------------------
--
-- Fig-Forth 1802 for the MAX1000 FPGA development board
--
-- Top level module
--
-- Features:
--
--     * UART console interface over the USB serial port (115200, 8-n-1)
--     * 8-LEDS memory mapped LEDS
--     * 23 GPIO pins
--     * 28K RAM
--
-- See readme.md for more information
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

entity maxforth is
	port(
        clk12m   : in std_logic;
		  led      : out std_logic_vector(7 downto 0);
        user_btn : in std_logic;
        bdbus    : inout std_logic_vector(1 downto 0);
		  ain      : inout std_logic_vector(6 downto 0);
		  d        : inout std_logic_vector(14 downto 0));
end maxforth;

architecture rtl of maxforth is

component mx1802
		port(
			clock:		in std_logic;
			ce:			in std_logic;
			reset_n:	in std_logic;
			data_in:	in std_logic_vector(7 downto 0);
			data_out:	out std_logic_vector(7 downto 0);
			address:	out std_logic_vector(15 downto 0);
			ef:			in std_logic_vector(3 downto 0);
			nout: 		out std_logic_vector(2 downto 0);
			qout:		out std_logic;
			rd_n:		out std_logic;
			wr_n:		out std_logic;
			int_n:  	in std_logic;
			dma_in_n:   in std_logic;
			dma_out_n:  in std_logic;
			s:          out std_logic_vector(1 downto 0));
		end component;

	component ram
		port(
			clock:		in std_logic;
			cs_n:		in std_logic;
			rd_n:       in std_logic;	   
			wr_n:       in std_logic;
			address:    in std_logic_vector(14 downto 0); 
			data_in:    in std_logic_vector(7 downto 0);
			data_out:   out std_logic_vector(7 downto 0));
		end component;

    component uart is 
        generic (
            cycles_per_bit: integer;
            data_out_port : integer;
            data_in_port : integer;
            status_in_port : integer);
    
        port(  
            clock:      in std_logic;
            reset_n:    in std_logic;
            ce:         in std_logic;
            data_in:    in std_logic_vector(7 downto 0);
            data_out:   out std_logic_vector(7 downto 0);
            n:          in std_logic_vector(2 downto 0);
            rd_n:       in std_logic;
            wr_n:       in std_logic;
            tx:         out std_logic;
            rx:         in std_logic;
            cts:        out std_logic;
            rts:        in std_logic);
		end component;
		
	component gpio is
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
		end component;
			
	signal data_bus     : std_logic_vector(7 downto 0);
	signal cpu_data     : std_logic_vector(7 downto 0);
	signal ram_data     : std_logic_vector(7 downto 0);
	signal uart_data    : std_logic_vector(7 downto 0);
	signal gpio_data    : std_logic_vector(7 downto 0);
	signal address      : std_logic_vector(15 downto 0);
	signal n	           : std_logic_vector(2 downto 0);
	signal rd_n         : std_logic;
	signal wr_n         : std_logic;
	signal ram_cs       : std_logic;
	signal ef           : std_logic_vector(3 downto 0);
	signal cpu_ce 	     : std_logic;
	signal sync_reset   : std_logic;
	signal gpio_outputs   : std_logic_vector(29 downto 0);
	signal gpio_inputs    : std_logic_vector(21 downto 0);
	signal gpio_tristates : std_logic_vector(21 downto 0);

begin

	u1: mx1802 port map (
		clock => clk12m,
		ce => cpu_ce,
		reset_n => user_btn,
		data_in => data_bus,
		data_out => cpu_data,
		address => address,
		ef => ef,
		nout => n, 
		qout => open,
		rd_n => rd_n,
		wr_n =>	wr_n,
		int_n => '1',
		dma_in_n => '1',
		dma_out_n => '1',
		s => open);

	u2: ram port map (
		clock => clk12m,
		cs_n => ram_cs,
		rd_n => rd_n,
		wr_n => wr_n,
		address => address(14 downto 0),
		data_in => data_bus,
		data_out =>	ram_data);
		
   u3: uart    
        generic map (
            cycles_per_bit => 104,
            data_out_port => 2,
				data_in_port => 2,
				status_in_port => 3)
        port map (
            clock => clk12m,
            reset_n => sync_reset,
            ce => cpu_ce,
            data_in => data_bus,
            data_out => uart_data,
            n => n,
            rd_n => rd_n,
            wr_n => wr_n,
            tx => bdbus(1),
            rx => bdbus(0),
            cts => open,
            rts => '0');
				
	u4: gpio
			port map (
				clock => clk12m,
				reset_n => sync_reset,
				data_in => data_bus,
				data_out => gpio_data,
				wr_n => wr_n,
				rd_n => rd_n,
				address => address,
				inputs => gpio_inputs,
				outputs => gpio_outputs,
				tristates => gpio_tristates);
		

	 data_bus <= cpu_data or ram_data or uart_data or gpio_data;	
	 ram_cs <= '0' when address(15) = '0' and address(14 downto 12) /= "111" else '1';
	 ef <= "0000";
	 
	 
	 process(clk12m)
     begin
        if rising_edge(clk12m) then
            sync_reset <= user_btn;
        end if;
    end process;
	 
    process(clk12m)
    begin
        if rising_edge(clk12m) then
            if sync_reset = '0' then
                cpu_ce <= '0';
            else
                cpu_ce <= not cpu_ce;
            end if;
        end if;
    end process;
	 
	 -- GPIO conections and tri-state drivers
	 ain(0) <= 'Z' when gpio_tristates(0) = '0' else gpio_outputs(0);
	 ain(1) <= 'Z' when gpio_tristates(1) = '0' else gpio_outputs(1);
	 ain(2) <= 'Z' when gpio_tristates(2) = '0' else gpio_outputs(2);
	 ain(3) <= 'Z' when gpio_tristates(3) = '0' else gpio_outputs(3);
	 ain(4) <= 'Z' when gpio_tristates(4) = '0' else gpio_outputs(4);
	 ain(5) <= 'Z' when gpio_tristates(5) = '0' else gpio_outputs(5);
	 ain(6) <= 'Z' when gpio_tristates(6) = '0' else gpio_outputs(6);
	 d(0) <= 'Z' when gpio_tristates(7) = '0' else gpio_outputs(7);
	 d(1) <= 'Z' when gpio_tristates(8) = '0' else gpio_outputs(8);
	 d(2) <= 'Z' when gpio_tristates(9) = '0' else gpio_outputs(9);
	 d(3) <= 'Z' when gpio_tristates(10) = '0' else gpio_outputs(10);
	 d(4) <= 'Z' when gpio_tristates(11) = '0' else gpio_outputs(11);
	 d(5) <= 'Z' when gpio_tristates(12) = '0' else gpio_outputs(12);
	 d(6) <= 'Z' when gpio_tristates(13) = '0' else gpio_outputs(13);
	 d(7) <= 'Z' when gpio_tristates(14) = '0' else gpio_outputs(14);
	 d(8) <= 'Z' when gpio_tristates(15) = '0' else gpio_outputs(15);
	 d(9) <= 'Z' when gpio_tristates(16) = '0' else gpio_outputs(16);
	 d(10) <= 'Z' when gpio_tristates(17) = '0' else gpio_outputs(17);
	 d(11) <= 'Z' when gpio_tristates(18) = '0' else gpio_outputs(18);
	 d(12) <= 'Z' when gpio_tristates(19) = '0' else gpio_outputs(19);
	 d(13) <= 'Z' when gpio_tristates(20) = '0' else gpio_outputs(20);
	 d(14) <= 'Z' when gpio_tristates(21) = '0' else gpio_outputs(21);
	 gpio_inputs(6 downto 0) <= ain;
	 gpio_inputs(21 downto 7) <= d;
	 led <= gpio_outputs(29 downto 22);
	 
end rtl;

-- End of file
