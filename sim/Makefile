RTL_DIR   := ../rtl
TB_DIR    := ../tb
BUILD_DIR := build
IVL_FLAGS := -g2012 -Wall -I $(RTL_DIR)

.PHONY: all clean

all: vdc circle

vdc: sim_vdc16 sim_vdc3 sim_vdc7
circle: sim_circle2 sim_circle3

sim_vdc16: $(BUILD_DIR)/tb_vdc_16
	vvp $<

sim_vdc3: $(BUILD_DIR)/tb_vdc_3_ilds
	vvp $<

sim_vdc7: $(BUILD_DIR)/tb_vdc_7_ilds
	vvp $<

sim_circle2: $(BUILD_DIR)/tb_circle_2_16
	vvp $<

sim_circle3: $(BUILD_DIR)/tb_circle_3_16
	vvp $<

$(BUILD_DIR)/tb_vdc_16: $(RTL_DIR)/vdc_16.v $(TB_DIR)/tb_vdc_16.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_vdc_16.v $(RTL_DIR)/vdc_16.v

$(BUILD_DIR)/tb_vdc_3_ilds: $(RTL_DIR)/vdc_3_ilds.v $(TB_DIR)/tb_vdc_3_ilds.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_vdc_3_ilds.v $(RTL_DIR)/vdc_3_ilds.v

$(BUILD_DIR)/tb_vdc_7_ilds: $(RTL_DIR)/vdc_7_ilds.v $(TB_DIR)/tb_vdc_7_ilds.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_vdc_7_ilds.v $(RTL_DIR)/vdc_7_ilds.v

$(BUILD_DIR)/tb_circle_2_16: $(RTL_DIR)/circle_2_16.v $(TB_DIR)/tb_circle_2_16.v $(RTL_DIR)/vdc_16.v $(RTL_DIR)/cordic_16.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_circle_2_16.v $(RTL_DIR)/circle_2_16.v $(RTL_DIR)/vdc_16.v $(RTL_DIR)/cordic_16.v

$(BUILD_DIR)/tb_circle_3_16: $(RTL_DIR)/circle_3_16.v $(TB_DIR)/tb_circle_3_16.v $(RTL_DIR)/vdc_3_ilds.v $(RTL_DIR)/cordic_16.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_circle_3_16.v $(RTL_DIR)/circle_3_16.v $(RTL_DIR)/vdc_3_ilds.v $(RTL_DIR)/cordic_16.v

$(BUILD_DIR):
	@if not exist $@ mkdir $@

clean:
	@if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
	@if exist $(TB_DIR)\*.vcd del /q $(TB_DIR)\*.vcd 2>nul
