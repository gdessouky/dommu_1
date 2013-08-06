--
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   19:10:25 03/14/2013 
-- Design Name: 
-- Module Name:	   pe_module - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 


library IEEE;
use IEEE.STD_LOGIC_1164.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- this line also is must.This includes the particular package into your program.
use work.user_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- PE receives BRAM_ALERT_IN asserted when it runs out of BRAM. 
-- PE responds by requesting BRAM by asserting BRAM_REQ_OUT.
-- BRAM is requested and when BRAM is allocaed, this is acknowledged by the PE receiving BRAM_ACK_IN for one clock cycle.
-- EN_DATA_OUT indicates that data output is enabled.
-- BRAM_DEPTH_IN indicates the number of words in BRAM.

entity pe is
      port (EN_IN	  : in	std_logic;
	    CLK_IN	  : in	std_logic;
	    BRAM_ACK_IN	  : in	std_logic;
	    BRAM_ALERT_IN : in	std_logic;
	    BRAM_DEPTH_IN : in	std_logic_vector (11 downto 0);
	    PE_ID_OUT	  : out positive;
	    DATA_OUT	  : out std_logic_vector (11 downto 0);
	    EN_DATA_OUT	  : out std_logic;
	    BRAM_REQ_OUT  : out std_logic);
end pe;


architecture pe_rtl of pe is
      signal cnt_word, cnt_word_D     : std_logic_vector (11 downto 0) := (others => '0');
      signal bram_alloc, bram_alloc_D : std_logic		       := '0';
      signal bram_req, en_out_D	      : std_logic		       := '0';
      signal bram_rem, bram_rem_D     : std_logic_vector (11 downto 0) := (others => '0');
      constant pe_id		      : positive := 1;


begin

-- sequential: registers update at clock cycle rising edge
	register_signals:     process (CLK_IN)
      begin
	    if (rising_edge(CLK_IN)) then
		  cnt_word     <= cnt_word_D;
		  bram_rem     <= bram_rem_D;
		  DATA_OUT     <= cnt_word_D;
		  PE_ID_OUT    <= pe_id;
		  BRAM_REQ_OUT <= bram_req;
		  EN_DATA_OUT  <= en_out_D;
		  bram_alloc   <= bram_alloc_D;
	    end if;
     end process register_signals;



-- combinational circuit to update the output enable signal and the counter word that is output by the PE 
-- to the BRAM element 
  update_output:    process (EN_IN, cnt_word, bram_alloc)
      begin
	    if (EN_IN = '1' and bram_alloc = '1') then
		  cnt_word_D <= std_logic_vector(unsigned(cnt_word) + 1);
		  en_out_D   <= '1';
	    else
		  en_out_D   <= '0';
		  cnt_word_D <= cnt_word;
	    end if;
      end process update_output;


-- combinational circuit to update the bram request signal when bram_alloc is de-asserted when 
-- the PE runs out of BRAM
  update_bram_req:    process (bram_alloc)
      begin
	    if ((bram_alloc = '0')) then
		  bram_req <= '1';
	    else
		  bram_req <= '0';
	    end if;
      end process update_bram_req;



-- combinational circuit to update the remaining BRAM words allocated to the PE				
  update_rem_bram:    process (BRAM_ACK_IN, BRAM_DEPTH_IN, EN_IN, bram_alloc, bram_rem)
      begin

	    if (BRAM_ACK_IN = '1') then	 -- when PE is acknowledged new BRAM
		  bram_rem_D <= std_logic_vector(unsigned(BRAM_DEPTH_IN));
	    elsif (EN_IN = '1' and bram_alloc = '1') then  -- when PE processing is enabled and BRAM allocated for PE
		  bram_rem_D <= std_logic_vector(unsigned(bram_rem) -1);
	    else
		  bram_rem_D <= bram_rem;
	    end if;

      end process update_rem_bram;

-- combinational circuit to assert/de-assert the bram_alloc depending on the available BRAM elements
-- and the BRAM_ALERT_IN
-- bram_alloc is a flag that indicates whether BRAM is allocated for the PE or not
   assert_alloc:   process (BRAM_ACK_IN, bram_rem, BRAM_ALERT_IN)
      begin
	    if (BRAM_ACK_IN = '1') then
		  bram_alloc_D <= '1';
	    elsif ((unsigned(bram_rem) < 2) or (BRAM_ALERT_IN = '1')) then
		  bram_alloc_D <= '0';
	    else
		  bram_alloc_D <= '1';
	    end if;
      end process assert_alloc;
end pe_rtl;

