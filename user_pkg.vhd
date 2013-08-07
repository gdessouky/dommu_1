--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package user_pkg is

-- controls the width of the data word
constant DATA_WIDTH		: natural := 4;

-- controls the number of mux inputs for mux_generic_tb.vhd
constant MUX_IN_CONST  : natural := 6;

-- synthesis of 2D arrays is cumbersome: best to create a type which is an array (1D) of an array or std_logic_vector
type data_route IS ARRAY(DATA_WIDTH -1 downto 0) OF STD_LOGIC;  -- single data word
type port_vector IS ARRAY (NATURAL RANGE <>)OF data_route;      -- a port vector: array of data words

-- reconfigurable crossbar constants M x N
constant M: natural :=4; --(PE num)
constant N: natural :=4; -- (BRAM num)

-- xbar switch data direction
constant XBAR_DIR : std_logic_vector(1 downto 0) := "01";  
-- convention (M x N xbar), 01 ( M => N), 10 (N => M), 11 (bidirectional)

-- xbar has 2 ports (1 and 2, port 1 with M nodes and port 2 with N nodes)
type xbar_port_1 IS ARRAY( M - 1 downto 0) OF data_route; 
type xbar_port_2 IS ARRAY( N - 1 downto 0) OF data_route;

-- xbar switch has 2 sets of select lines, one set for port 1, and the other set for port 2
type xbar_sel_port_1 IS ARRAY (M - 1 downto 0)  OF natural range 0 to N-1;
type xbar_sel_port_2 IS ARRAY (N - 1 downto 0)  OF natural range 0 to M-1;

-- types for DOMMU: BRAC
subtype bram_depth_match is integer range 0 to 100; -- 0 means exact match, 100 means 100% extra
constant BRAM_DEPTH_MATCH_MARGIN: bram_depth_match:= 0; -- BRAM_DEPTH_MATCH_MARGIN is used to define the acceptable margin difference in depth of BRAM elemen	
-- to accept it to serve a PE request for BRAM


-- BRAM ID and PE ID are in the natural range: 0 + -> positive

type bram is
	record 
		bram_id: positive;
		bram_type:  std_logic_vector(1 downto 0); -- 4 types supported
		width: positive;
		depth: positive;
	end record;
	
type bram_type is array (NATURAL RANGE <>) of bram;

type bram_alloc is
	record
		bram_id: positive;
		is_alloc: std_logic;
		pe_wr: natural;  -- since is is natural then it can take '0'. IDs are positive so if this is 0, it indicates no ID is assigned
		pe_rd: natural;
		pe_rd_wr: natural;
	end record;
	
type bram_alloc_type is array (NATURAL RANGE <>) of bram_alloc;

type pe_alloc is	-- the array is created with records for all PEs but not all PEs are assigned to RATs, therefore
	record         -- when not assigned to RAT, the brat_id is 0
		pe_id: positive; -- there is a record for every PE
		brat_id: natural;  -- when 0 then the PE is not assigned
		bram_count: natural; -- because it can be allocated zero BRAM elements in case all its assigned BRAM elements get de-allocated
	end record;
	
type pe_alloc_type is array (NATURAL RANGE <>) of pe_alloc;

	

-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
procedure search_dealloc (variable bram_dealloc_flag_v	: in std_logic_vector(N downto 0);
								  signal bram_array			: in bram_type;
								  variable search_dealloc_ok_v : out std_logic;
								  variable bram_to_alloc_index_v : out natural;
								  variable bram_req_depth_v				: in natural;
								  variable bram_req_width_v				: in natural);

procedure search_unalloc (variable bram_alloc_flag_v	: in std_logic_vector(N downto 0);
								  signal bram_array			: in bram_type;
								  variable search_unalloc_ok_v : out std_logic;
								  variable bram_to_alloc_index_v : out natural;
								  variable bram_req_depth_v				: in natural;
								  variable bram_req_width_v				: in natural);
								  

procedure add_bram_alloc_array (signal bram_alloc_array: inout bram_alloc_type (N downto 0);
										  variable bram_to_alloc_index: in natural; 
										  variable pe_id_v : in natural);
										  
procedure assign_brat_to_pe (signal pe_alloc_array: inout pe_alloc_type (M downto 0);
									  variable pe_id_v : in natural);

end user_pkg;

package body user_pkg is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example

-- procedure search_dealloc searches the BRAM deallocation array for suitable BRAM elements that can be allocated
procedure search_dealloc  (variable bram_dealloc_flag_v	: in std_logic_vector(N downto 0);
								  signal bram_array			: in bram_type;
								  variable search_dealloc_ok_v : out std_logic;
								  variable bram_to_alloc_index_v : out natural;
								  variable bram_req_depth_v				: in natural;
								  variable bram_req_width_v				: in natural) is
   variable index: natural;
	begin
		search_dealloc_ok_v := '0'; -- flag to assert or de-assert success of search (exit value!)
		for index in bram_dealloc_flag_v'range loop
			if bram_dealloc_flag_v(index) = '1' then -- de-allocated BRAM element 
				if (bram_array(index).width = bram_req_width_v) and (bram_array(index).depth -  bram_req_depth_v <= (bram_req_depth_v * BRAM_DEPTH_MATCH_MARGIN / 100)) then -- need to have a certain
				-- allowed margin, depth can be more by now many words?
					bram_to_alloc_index_v := index;
					search_dealloc_ok_v := '1';
					exit;
				end if;
			end if;
		end loop;
	end procedure search_dealloc;
	

-- procedure add_bram_alloc_array asserts that a certain BRAM element has been allocated to a certain PE
procedure add_bram_alloc_array (signal bram_alloc_array: inout bram_alloc_type (N downto 0);
								        variable bram_to_alloc_index: in natural; 
										  variable pe_id_v : in natural) is
	begin
		bram_alloc_array(bram_to_alloc_index).is_alloc <= '1';
		bram_alloc_array(bram_to_alloc_index).pe_wr <= pe_id_v;
		bram_alloc_array(bram_to_alloc_index).pe_rd <= pe_id_v;
		bram_alloc_array(bram_to_alloc_index).pe_rd_wr <= pe_id_v;
	end procedure add_bram_alloc_array;

-- procedure assign_brat_to_pe assigns a BRAT to a PE in case a PE has not been assigned to a BRAT yet
procedure assign_brat_to_pe (signal pe_alloc_array: inout pe_alloc_type (M downto 0);
									  variable pe_id_v : in natural) is
	begin
		if (pe_alloc_array(pe_id_v-1).brat_id = 0) then   -- not assigned to BRAT yet
			 pe_alloc_array(pe_id_v-1).brat_id <= pe_id_v;  -- assign BRAT ID to be equal to PE ID
		end if;
		pe_alloc_array(pe_id_v-1).bram_count <= pe_alloc_array(pe_id_v-1).bram_count + 1;
	end procedure assign_brat_to_pe;

-- procedure search_unalloc searches the array of available free BRAM elements for suitable BRAM elements that can be allocated
procedure search_unalloc (variable bram_alloc_flag_v	: in std_logic_vector(N downto 0);
								  signal bram_array			: in bram_type;
								  variable search_unalloc_ok_v : out std_logic;
								  variable bram_to_alloc_index_v : out natural;
								  variable bram_req_depth_v				: in natural;
								  variable bram_req_width_v				: in natural) is
   variable index: natural;
	begin
		search_unalloc_ok_v := '0'; -- flag to assert or de-assert success of search (exit value!)
		for index in bram_alloc_flag_v'range loop
			if bram_alloc_flag_v(index) = '0' then -- un-allocated BRAM element 
				if (bram_array(index).width = bram_req_width_v) and (bram_array(index).depth -  bram_req_depth_v <= (bram_req_depth_v * BRAM_DEPTH_MATCH_MARGIN / 100)) then -- need to have a certain
				-- allowed margin, depth can be more by now many words?
					bram_to_alloc_index_v := index;
					search_unalloc_ok_v := '1';
					exit;
				end if;
			end if;
		end loop;
	end procedure search_unalloc;	
	
end user_pkg;
