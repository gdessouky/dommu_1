----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:11:18 03/15/2013 
-- Design Name: 
-- Module Name:    mem_ctrl - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use WORK.user_pkg.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rac is
   
	-- generics for the number of processing elements and BRAM elements which are managed
	generic (PE_NUM : integer := M; 
	         BRAM_NUM : integer :=N;
				BRAM_WIDTH : integer:= DATA_WIDTH);


	port (  
	        CLK_IN : in  STD_LOGIC;
			  EN_IN : in  STD_LOGIC;
			  
			  -- DATA PORTS needed for memory request and allocation
			  BRAM_REQ_IN : in  STD_LOGIC; 
			  PE_ID_IN : in NATURAL;
			  BRAM_REQ_DEPTH_IN: in NATURAL;
			  BRAM_REQ_WIDTH_IN: in NATURAL;
			  BRAM_REQ_COUNT_IN: in NATURAL;  -- the number of such elements needed
			  -- Ideally it would be more sophisticated if the PE requests the size it desires and
			  -- the mapping of this size to the BRAM blocks is done and partitioning, but this is not
			  -- the case, the BRAM elements are already synthesized in terms of width and depth 
			  -- PE can still request random size and be allocated that (mapped to multiple BRAM elements or one larger
			  -- one and so on...) 
			  -- Usually hardware PEs do not know the size requested, but know the number of words needed
			  -- and the word width which is how the request is currently set
			  
			  EN_RD_IN   : in STD_LOGIC;
			  EN_WR_IN   : in STD_LOGIC;
			  
			  -- memory read/write address consists of 2 MSB bits to define BRAM_ID and 11 bits to define WORD_ADDRESS within the BRAM
			  ADDR_RD_IN : in STD_LOGIC_VECTOR (12 downto 0);  
			  ADDR_WR_IN : in STD_LOGIC_VECTOR (12 downto 0);  
			  
           BRAM_GRANT_OUT : out STD_LOGIC;
			  BRAM_ACK_OUT : out STD_LOGIC;
           BRAM_SIZE_OUT : out  STD_LOGIC_VECTOR (11 downto 0);
			  
			  -- SELECT LINES of INTERCONNECTION NETWORK	
			  
			  PE0_MUX_SEL : out INTEGER;
			  PE1_MUX_SEL : out INTEGER;
			  PE2_MUX_SEL : out INTEGER;
			  PE3_MUX_SEL : out INTEGER;
			  
			  BRAM0_MUX_SEL : out INTEGER;
			  BRAM1_MUX_SEL : out INTEGER;
			  BRAM2_MUX_SEL : out INTEGER;
			  BRAM3_MUX_SEL : out INTEGER );
			  

end rac;

architecture rac_rtl of rac is

   -- the arrays involved to keep track of BRAM allocation and deallocation as well as PE allocation to RAM Address Translators
   signal bram_array : bram_type (BRAM_NUM downto 0);
	signal bram_alloc_array : bram_alloc_type (BRAM_NUM downto 0);
	signal pe_alloc_array : pe_alloc_type (PE_NUM  downto 0);
	signal bram_dealloc_flag : std_logic_vector (BRAM_NUM downto 0); 
	-- bram_dealloc_flag vector keeps track of deallocated BRAM elements: they get flagged
	-- so when giving priority to re-allocating deallocated BRAM elements, this vector is used
	-- to search the bram_array and allocated
	-- No preference is given to the first or last deallocated BRAM element or so!
	-- Fragmentation is not really an issue since memory mapping of random memory size is not a concern
	-- This is used along with the bram_dealloc_count to keep track of the number of BRAM elements de-allocated
	
	-- registers to keep track of the number of allocated BRAM elements,
	-- and number of deallocated BRAM elements, and finally number
	-- of PEs allocated to RATs
	-- these registers are used along with the array above to keep count
	-- of the numbers and to aid in locating data in the arrays
	signal bram_alloc_count, bram_alloc_count_D : natural := 0;
	signal bram_dealloc_count, bram_dealloc_count_D : natural := 0;
	signal pe_alloc_count, pe_alloc_count_D : natural := 0;
	
	signal bram_rem_count, bram_rem_count_D : natural :=0; -- to indicate remaining BRAM elements unallocated
	signal bram_req_rem : natural := 0;
	
	signal bram_to_alloc_index: natural := 0; -- to indicate the BRAM element index in the deallocation array
	
	
	signal alloc_en: std_logic := '0';
	signal bram_ack: std_logic := '0';
	signal bram_grant: std_logic := '0';
	
	
	signal bram_id_wr: std_logic_vector(1 downto 0):= "00";

begin
	
	bram_rem_count<= BRAM_NUM - bram_alloc_count;
	
	
	-- controller FSM combinational circuit 
	process (EN_IN, current_state, BRAM_REQ_IN, bram_rem_count, bram_dealloc_count, bram_dealloc_flag, bram_array, search_dealloc_ok, bram_to_alloc_index, BRAM_REQ_DEPTH,  BRAM_REQ_WIDTH )
	
	-- variables for combinational logic within the controller process and FSM
	variable bram_rem_v: natural := 0;
	variable bram_dealloc_v : natural := 0;
	variable bram_rem_req_v   : natural := 0;
	variable search_dealloc_ok_v : std_logic := '0'; -- to indicate if the search in deallocation array was successful
	variable bram_dealloc_flag_v : std_logic_vector(BRAM_NUM downto 0) := (others => '0');
	variable bram_to_alloc_index_v : natural := 0;
	variable bram_alloc_count_v : natural;
	variable bram_req_depth_v  : natural;
	variable bram_req_width_v : natural;
	variable pe_id_v : positive;

	begin
		if (EN_IN = '1') then  -- controller enabled
			CASE current_state is
			
				-- s0: initial state/wait state: waiting for BRAM_REQ_IN to indicate a BRAM request
				when s0 =>
				if (BRAM_REQ_IN = '1') then    -- BRAM_REQ_IN therefore capture the BRAM request parameters entered
					-- assign signals and inputs to variables before beginning to serve the BRAM requests
				   bram_rem_req_v := BRAM_REQ_COUNT_IN; -- read value of number of requested BRAM elements
					bram_rem_v := bram_rem_count;   -- read value of remaining free BRAM elements in system
					bram_dealloc_v := bram_dealloc_count;
					bram_dealloc_flag_v := bram_dealloc_flag;
					bram_req_depth_v := BRAM_REQ_DEPTH_IN;
					bram_req_width_v := BRAM_REQ_WIDTH_IN;
					bram_alloc_count_v := bram_alloc_count;
					pe_id_v  			:= PE_ID_IN;
					
					-- serve the first BRAM element request 
					if (bram_rem_count_v > 0) then 
						if ( bram_rem_v> 0) then 		  -- remaining unallocated BRAM elements > 0
							if ( bram_dealloc_num > 0 and search_dealloc_ok_v = '0') then -- deallocated BRAM elements: consider these first	
								search_dealloc(bram_dealloc_flag_v, bram_array, search_dealloc_ok_v, bram_to_alloc_index_v, bram_req_depth_v, bram_req_width_v);
								if (search_dealloc_ok_v = '1') then
								   
									-- update all counts
									bram_rem_v := bram_rem_v - 1;
									bram_rem_req_v := bram_rem_req_v - 1;
									bram_alloc_count_v := bram_alloc_count_v + 1;
									bram_dealloc_v := bram_dealloc_v - 1;
									
									-- update dealloc and alloc array data
									bram_dealloc_flag_v(bram_to_alloc_index) <= '0'; -- allocated element
									add_bram_alloc_array(bram_alloc_array, bram_to_alloc_index, pe_id_v); --
									
									
									-- update PE information
									
									
									
									
									
								
						while (bram_rem_count_v > 0) loop  -- requested BRAM elements still not served		
								
								
						
						if ( bram_dealloc_num > 0 and search_dealloc_ok = '0') then -- deallocated BRAM elements: consider these first	
							search_dealloc(bram_dealloc_flag, bram_array, search_dealloc_ok, bram_to_alloc_index, BRAM_REQ_DEPTH, BRAM_REQ_WIDTH);
							if (search_dealloc_ok = '1') then
								bram_rem := bram_rem - 1;
								bram_dealloc_num := bram_dealloc_num - 1;
							end if;
						end if;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	
	
		
						
					 	
						
						
						
--						if (search_dealloc_ok = '1') then -- matching BRAM element found
--							bram_dealloc_flag(bram_to_alloc_index) <= '0'; -- de-assert the de-allocated element
--							bram_dealloc_count_D <= bram_dealloc_count - 1;
--							bram_rem_count_D <= bram_rem_count - 1;
--							search_dealloc_ok <= '0';
							
							

	
	-- combinational circuit						
	process (alloc_en, alloc_num)
	begin
		if (alloc_en = '1') then
			alloc_num_D <= std_logic_vector(unsigned(alloc_num) + 1);
		else
			alloc_num_D <= alloc_num; 
		end if;	
			
	end process;
	
	
	-- combinational circuit						
	process (alloc_en, alloc_num)
	begin
		if (alloc_en = '1') then
			alloc_num_D <= std_logic_vector(unsigned(alloc_num) + 1);
		else
			alloc_num_D <= alloc_num;
		end if;	
			
	end process;
	
	-- setting BRAM MUX select lines
	process(alloc_en)
	begin
		if (alloc_en = '1') then
		    case alloc_num is when
				when "00" => BRAM0_MUX_SEL <= PE_ID_IN;
				when "01" => BRAM1_MUX_SEL <= PE_ID_IN;
				when "10" => BRAM2_MUX_SEL <= PE_ID_IN;
				when "11" => BRAM3_MUX_SEL <= PE_ID_IN;		
          end case;				
			

	
	
	-- registers
	process (CLK_IN)
	begin
		if (rising_edge(CLK_IN)) then
			if (EN_IN = '1') then
				cnt_word <= cnt_word_D;
				bram_set <= bram_set_D;
				EN_BRAM_OUT  <= BRAM_GRANT_IN;
				DATA_BRAM_OUT <= cnt_word;
				PE_ID_OUT <= pe_id;
				BRAM_REQ_OUT <= bram_req;
			end if;
		end if;					
				
	end process;

end rac_rtl;



