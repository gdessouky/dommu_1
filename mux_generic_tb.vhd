-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use WORK.user_pkg.ALL;

  ENTITY mux_generic_tb IS
  END mux_generic_tb;

  ARCHITECTURE behavior OF mux_generic_tb IS 

  -- Component Declaration
          COMPONENT mux_generic
			 GENERIC (MUX_IN_COUNT : integer := 4);
    PORT ( 
        MUX_IN : in port_vector (0 to MUX_IN_COUNT-1 );
        MUX_SEL : in integer range 0 to MUX_IN_COUNT-1;
		  MUX_OUT : out data_route
    );
	 END COMPONENT;
			 
          SIGNAL mux_select :  integer := 0;
			 SIGNAL mux_output : data_route;
			 signal mux_input  : port_vector (0 to MUX_IN_CONST-1);
          

  BEGIN

  -- Component Instantiation
 mux1: mux_generic
     GENERIC MAP(
        MUX_IN_COUNT         => MUX_IN_CONST
     )
     PORT MAP (
	     MUX_IN        => mux_input,
        MUX_SEL       => mux_select,
        MUX_OUT      => mux_output
     );

  --  Test Bench Statements
     tb : PROCESS
     BEGIN
	  
	  mux_input(0) <= x"01010101";
	  mux_input(1) <= x"ABABABAB";
	  mux_input(2) <= x"CDCDCDCD";
	  mux_input(3) <= x"EFEFEFEF";
	  mux_input(4) <= x"10101010";
	  mux_input(5) <= x"00110011";

        wait for 100 ns; -- wait until global set/reset completes
		  

        -- Add user defined stimulus here

        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;


