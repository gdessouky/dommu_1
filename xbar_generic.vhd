----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:02:43 07/08/2013 
-- Design Name: 
-- Module Name:    crossbar_generic - Behavioral 
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
-- library UNISIM;
-- use UNISIM.VComponents.all; 

entity xbar_generic is

   -- initialize all ports with zeros so that unused ports can be left OPEN in PORT MAP 
	-- without synthesis errors. Will need to leave ports OPEN in case of uni-directional
	-- xbar switches

    port ( 
	 XBAR_1_IN : in port_vector(M-1 downto 0) := (others=> (others=>'0'));
	 XBAR_2_IN : in port_vector(N-1 downto 0) := (others=> (others=>'0'));
	 XBAR_1_OUT : out port_vector(M-1 downto 0) := (others=> (others=>'0'));
	 XBAR_2_OUT : out port_vector(N-1 downto 0) := (others=> (others=>'0'));
	 XBAR_1_SEL_IN : in xbar_sel_port_1 := (others=>0);
	 XBAR_2_SEL_IN : in xbar_sel_port_2 := (others=>0)
    );
 
end xbar_generic;

architecture Behavioral of xbar_generic is

  -- Component Declaration
          COMPONENT mux_generic
			 GENERIC (MUX_IN_COUNT : integer := 4);
    PORT ( 
        MUX_IN : in port_vector (MUX_IN_COUNT-1 downto 0  );
        MUX_SEL : in integer range 0 to MUX_IN_COUNT-1;
		  MUX_OUT : out data_route
    );
	 END COMPONENT;

begin


  -- conditional generate 
  -- Component Instantiation
  -- Instantiate M muxes with N inputs
  
  -- If XBAR_DIR = "10" OR "11"
  
 GEN1_IF: 
 if (XBAR_DIR = "10" or XBAR_DIR = "11") generate
  GEN1_LOOP: 		for index in 0 to (M-1) generate
		  muxes_port2 : mux_generic   -- muxes which generate the outputs for port "
		  GENERIC MAP(
        MUX_IN_COUNT         => N
        )
        PORT MAP (
	       MUX_IN        => XBAR_2_IN,
          MUX_SEL       => XBAR_1_SEL_IN(index),
          MUX_OUT      => XBAR_1_OUT(index)
        );

end generate GEN1_LOOP;
end generate GEN1_IF;


  -- Component Instantiation
  -- Instantiate M muxes with N inputs
  
  -- If XBAR_DIR = "01" OR "11"
  
  -- conditional generate 
  
 GEN2_IF: 
 if (XBAR_DIR = "01" or XBAR_DIR = "11") generate
  GEN2_LOOP: 		for index in 0 to (N-1) generate
		  muxes_port2 : mux_generic   -- muxes which generate the outputs for port "
		  GENERIC MAP(
        MUX_IN_COUNT         => M
        )
        PORT MAP (
	       MUX_IN        => XBAR_1_IN,
          MUX_SEL       => XBAR_2_SEL_IN(index),
          MUX_OUT      => XBAR_2_OUT(index)
        );

end generate GEN2_LOOP;
end generate GEN2_IF;

end Behavioral;

