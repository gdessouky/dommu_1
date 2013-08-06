----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:11:18 07/09/2013 
-- Design Name: 
-- Module Name:    xbar_generic_tb - Behavioral 
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
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.user_pkg.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity xbar_generic_tb is
end xbar_generic_tb;

architecture Behavioral of xbar_generic_tb is


signal port1_input : port_vector(M-1 downto 0);
signal port2_input : port_vector(N-1 downto 0);
signal port1_output : port_vector(M-1 downto 0);
signal port2_output : port_vector(N-1 downto 0);
signal xbar_port1_select : xbar_sel_port_1;
signal xbar_port2_select : xbar_sel_port_2;

-- Component Declaration
      COMPONENT xbar_generic
    PORT ( 
	 XBAR_1_IN : in port_vector(M-1 downto 0) := (others=> (others=>'0'));
	 XBAR_2_IN : in port_vector(N-1 downto 0) := (others=> (others=>'0'));
	 XBAR_1_OUT : out port_vector(M-1 downto 0) := (others=> (others=>'0'));
	 XBAR_2_OUT : out port_vector(N-1 downto 0) := (others=> (others=>'0'));
	 XBAR_1_SEL_IN : in xbar_sel_port_1 := (others=>0);
	 XBAR_2_SEL_IN : in xbar_sel_port_2 := (others=>0)
    );
	 END COMPONENT;

begin

	 -- XBAR Instantiation
	 
GEN_IF1: 
  if (XBAR_DIR = "01") generate  -- M => N
 xbar: xbar_generic
     PORT MAP (
	 XBAR_1_IN => port1_input,
	 XBAR_2_IN => open,
	 XBAR_1_OUT => open,
	 XBAR_2_OUT => port2_output,
	 XBAR_1_SEL_IN => open,
	 XBAR_2_SEL_IN => xbar_port2_select
     );
end generate GEN_IF1;
 
 GEN_IF2: 
 if (XBAR_DIR = "10") generate      -- N => M
 xbar: xbar_generic
     PORT MAP (
	 XBAR_1_IN => open,
	 XBAR_2_IN => port2_input,
	 XBAR_1_OUT => port1_output,
	 XBAR_2_OUT => open,
	 XBAR_1_SEL_IN => xbar_port1_select,
	 XBAR_2_SEL_IN => open
     );
end generate GEN_IF2;	  

GEN_IF3: 
if (XBAR_DIR = "11") generate  -- bidirectional M <=> N
	xbar: xbar_generic
     PORT MAP (
	 XBAR_1_IN => port1_input,
	 XBAR_2_IN => port2_input,
	 XBAR_1_OUT => port1_output,
	 XBAR_2_OUT => port2_output,
	 XBAR_1_SEL_IN => xbar_port1_select,
	 XBAR_2_SEL_IN => xbar_port2_select
     );
end generate GEN_IF3;

  --  Test Bench Statements
     tb : PROCESS
     BEGIN 
	  -- port input signals set
	  port1_input(0) <= x"0";
	  port1_input(1) <= x"A";
	  port1_input(2) <= x"B";
	  port1_input(3) <= x"1";
	  
	  port2_input(0) <= x"C";
	  port2_input(1) <= x"D";
	  port2_input(2) <= x"E";
	  port2_input(3) <= x"F";
	  
        -- Add user defined stimulus here

        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 
end Behavioral;

