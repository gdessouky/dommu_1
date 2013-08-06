----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:35:21 07/03/2013 
-- Design Name: 
-- Module Name:    mux_generic - Behavioral 
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
use WORK.user_pkg.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;\

--Refer to http://forums.xilinx.com/t5/Synthesis/Generic-MUX-using-VHDL/m-p/285911#M7532

entity mux_generic is
	generic (MUX_IN_COUNT : integer := 4);
    port ( 
        MUX_IN : in port_vector (MUX_IN_COUNT-1 downto 0);
        MUX_SEL : in integer range 0 to MUX_IN_COUNT-1;
		  MUX_OUT : out data_route
    );
 
end mux_generic;

architecture Behavioral of mux_generic is

begin

-- -- Cannot access a complete slice of a 2D array, can only access bit by bit therefore need For...Generate
-- -- to assign one bit at a time to the output port of the mux
--	gen: FOR i IN DATA_WIDTH-1 DOWNTO 0 GENERATE
--        MUX_OUT(i) <= MUX_IN(MUX_SEL, i);
--   END GENERATE gen; 

MUX_OUT <= MUX_IN(MUX_SEL);
	
 -- Any mux control logic such as enables or so should be added here
	
end Behavioral;

