###################################################################################################
###################################################################################################
# BLOOMFILTER PARAMETERS: MODIFIABLE 
###################################################################################################
FALSE_POSITIVITY_RATE := 0.1

###################################################################################################
# TESTBENCH INPUT GENERATION PARAMETERS: MODIFIABLE 
###################################################################################################
# Number of safe, unsafe and randomly generated frames
NUM_SAFE=2
NUM_UNSAFE=0
NUM_RAND=2

###################################################################################################
# ETHERNET PARAMETERS: MODIFIABLE 
###################################################################################################
FrameSize=1200
Index_Size=1
Table_Size=$(shell echo $$((1 << $(Index_Size))))


###################################################################################################
# ETHERNET PARAMETERS: DO NOT MODIFY THE UNDERNEATH PARAMETERS
###################################################################################################
# FRAME SIZE AND FORMAT
EthHeaderSize=14
EthFCSSize=4
EthMTUSize=$(shell echo $$(($(FrameSize) - $(EthHeaderSize) - $(EthFCSSize))))


# Gen params
PWD=$(CURDIR)
BUILD_DIR:=$(PWD)/build
SRC_V:=$(PWD)/v_src
FEEDS_DIR:=$(PWD)/feeds

# BloomFilter params
BF_JSON_DIR:=$(PWD)/bloomfilter_generator/test_rules
BF_BSV_WRAPPER_DIR:=$(PWD)/bloomfilter_generator/bsv_wrapper

# Usage : Variables which are to be passed to bluespec `define variables are to be specified here and values to be given above
DEFINES := EthHeaderSize EthMTUSize EthFCSSize FrameSize Index_Size Table_Size

# Include directories:
BSV_INC_DIR:=.:%/Libraries:$(CPU_DIR)/fabrics/axi4:$(CPU_DIR)/fabrics/axi4lite:$(CPU_DIR)/fabrics/bridges:$(CPU_DIR)/common_bsv

Loopback_all: init generate_bf generate_eth_conn generate_lb generate_tb 
Loopback_dup: init generate_bf_dup generate_eth_conn generate_lb generate_tb 
Loopback_bf: init generate_bf_actual generate_eth_conn generate_lb generate_tb 

init:
	@mkdir -p $(SRC_V)
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(FEEDS_DIR)

generate_bf: bloomfilter_generator/Makefile
	@echo "\n"
	@echo "bloom filter generation"
	@echo "expected false positivity: $(FALSE_POSITIVITY_RATE)"
	@cd bloomfilter_generator && make run compile_bsv BF_JSON_DIR=$(BF_JSON_DIR) SRC_V=$(SRC_V) SRC_B=$(BF_BSV_WRAPPER_DIR) BUILD_DIR=$(BUILD_DIR) FALSE_POSITIVITY_RATE=$(FALSE_POSITIVITY_RATE)

generate_bf_dup: firewall_dup_generator/generate_firewall.py
	@echo "\n"
	@echo "proxy firewall generation"
	@python3 firewall_dup_generator/generate_firewall.py --input $(BF_JSON_DIR)/rules.json --output $(SRC_V)/topmodule.v
	@cd bloomfilter_generator && make compile_bsv BF_JSON_DIR=$(BF_JSON_DIR) SRC_V=$(SRC_V) SRC_B=$(BF_BSV_WRAPPER_DIR) BUILD_DIR=$(BUILD_DIR) FALSE_POSITIVITY_RATE=$(FALSE_POSITIVITY_RATE)

generate_bf_actual: bloomfilter_actual/Makefile
	@echo "\n"
	@echo "bloom filter generation"
	@cd bloomfilter_actual && make compile_bsv SRC_V=$(SRC_V) SRC_B=$(BF_BSV_WRAPPER_DIR) BUILD_DIR=$(BUILD_DIR) FALSE_POSITIVITY_RATE=$(FALSE_POSITIVITY_RATE)

generate_eth_conn: bsv_src/eth-ip/Ethernet_IP_Phy.bsv bsv_src/eth-ip/Ethernet_IP_RX.bsv bsv_src/eth-ip/Ethernet_IP_TX.bsv bsv_src/eth-ip/Ethernet_IP.bsv
	@echo "\n"
	@echo "compilation: variable parameter values: "
	@echo $(foreach var,$(DEFINES),$(var)=$($(var)) "\t") 
	@echo "compiling bsv_src/eth-ip/Ethernet_IP_Phy.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/eth-ip/Ethernet_IP_Phy.bsv
	@echo "compiling bsv_src/eth-ip/Ethernet_IP_RX.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/eth-ip/Ethernet_IP_RX.bsv
	@echo "compiling bsv_src/eth-ip/Ethernet_IP_TX.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/eth-ip/Ethernet_IP_TX.bsv
	@echo "compiling bsv_src/eth-ip/Ethernet_IP.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/eth-ip/Ethernet_IP.bsv
	@echo "compiling bsv_src/eth-ip/Ethernet_IP_MDIO.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/eth-ip/Ethernet_IP_MDIO.bsv
	@sed -i 's/always@(posedge CLK)/always@(negedge CLK)/g' $(SRC_V)/mkEthIPMDIO.v

generate_lb: bsv_src/loopback/MPD_LB.bsv bsv_src/loopback/Loopback.bsv bsv_src/loopback/lb_top.v bsv_src/Ref_Dtypes.bsv bsv_src/AXI4_Lite_Types.bsv
	@echo "\n"
	@echo "compiling bsv_src/Ref_Dtypes.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/Ref_Dtypes.bsv
	@echo "compiling bsv_src/Semi_FIFO.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/Semi_FIFOF.bsv
	@echo "compiling bsv_src/AXI4_Lite_Types.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -u -p $(BSV_INC_DIR) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/AXI4_Lite_Types.bsv
	@echo "compiling bsv_src/loopback/MPD_LB.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/loopback/MPD_LB.bsv
	@echo "compiling bsv_src/loopback/Loopback.bsv"
	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -vdir $(SRC_V) -bdir $(BUILD_DIR) -verilog bsv_src/loopback/Loopback.bsv
	@cp bsv_src/loopback/lb_top.v $(SRC_V)/
	

NUM_LINES := $$(wc -l < $(FEEDS_DIR)/in_eth0.txt)
EXE := out
generate_tb: bloomfilter_generator/test_rules/rules.json 	
	@echo "\n"
	@echo "generating feeds for testing"
	@python3 generate_packets.py --rules bloomfilter_generator/test_rules/rules.json --feeds=$(FEEDS_DIR) --num_safe=$(NUM_SAFE) --num_unsafe=$(NUM_UNSAFE) --num_rand=$(NUM_RAND) --FrameSize=$(FrameSize)
	
# run_bsv_sim:  bsv_src/test_bench/Tb_LB.bsv
# 	@echo "\n"
# 	@echo "bluespec simulation:"
# 	@sed -i 's:^String feeds.*:String feeds = "$(FEEDS_DIR)";:' bsv_src/test_bench/Tb_LB.bsv
# 	@bsc $(foreach var,$(DEFINES),-D $(var)=$($(var))) -D NUM_LINES=$(NUM_LINES) -vdir $(SRC_V) -bdir $(BUILD_DIR) -suppress-warnings G0010 -suppress-warnings S0080 -steps-warn-interval 1000000 -verilog bsv_src/test_bench/Tb_LB.bsv
# 	@cd $(SRC_V) && bsc -o $(EXE) -e mkPyFeedTb mkPyFeedTb.v && ./$(EXE)

clean:
	rm -rf $(BUILD_DIR) 
	rm -rf $(SRC_V)
	cd bloomfilter_generator && make clean
	rm -rf $(FEEDS_DIR)
