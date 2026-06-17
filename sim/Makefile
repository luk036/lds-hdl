RTL_DIR   := ../rtl
TB_DIR    := ../tb
BUILD_DIR := build
IVL_FLAGS := -g2012 -Wall -I $(RTL_DIR)

.PHONY: all clean vdc circle vdc32 circle32 all32

all: vdc circle

all32: vdc32 circle32 sqrt32 disk32 sphere32

vdc: sim_vdc16 sim_vdc3 sim_vdc7
circle: sim_circle2 sim_circle3

vdc32: sim_vdc32 sim_vdc3_32
circle32: sim_circle2_32 sim_circle3_32
sqrt32: sim_sqrt32
disk32: sim_disk32
sphere32: sim_sphere32

# --- 16-bit targets ---

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

# --- 32-bit targets ---

sim_vdc32: $(BUILD_DIR)/tb_vdc_32
	vvp $<

sim_vdc3_32: $(BUILD_DIR)/tb_vdc_3_ilds_32
	vvp $<

sim_sqrt32: $(BUILD_DIR)/tb_sqrt_32
	vvp $<

sim_circle2_32: $(BUILD_DIR)/tb_circle_2_32
	vvp $<

sim_circle3_32: $(BUILD_DIR)/tb_circle_3_32
	vvp $<

sim_disk32: $(BUILD_DIR)/tb_disk_32
	vvp $<

sim_sphere32: $(BUILD_DIR)/tb_sphere_32
	vvp $<

# --- Build rules 16-bit ---

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

# --- Build rules 32-bit ---

$(BUILD_DIR)/tb_vdc_32: $(RTL_DIR)/vdc_32.v $(TB_DIR)/tb_vdc_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_vdc_32.v $(RTL_DIR)/vdc_32.v

$(BUILD_DIR)/tb_vdc_3_ilds_32: $(RTL_DIR)/vdc_3_ilds_32.v $(TB_DIR)/tb_vdc_3_ilds_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_vdc_3_ilds_32.v $(RTL_DIR)/vdc_3_ilds_32.v

$(BUILD_DIR)/tb_sqrt_32: $(RTL_DIR)/cordic_sqrt_32.v $(TB_DIR)/tb_sqrt_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_sqrt_32.v $(RTL_DIR)/cordic_sqrt_32.v

$(BUILD_DIR)/tb_circle_2_32: $(RTL_DIR)/circle_2_32.v $(TB_DIR)/tb_circle_2_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/cordic_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_circle_2_32.v $(RTL_DIR)/circle_2_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/cordic_32.v

$(BUILD_DIR)/tb_circle_3_32: $(RTL_DIR)/circle_3_32.v $(TB_DIR)/tb_circle_3_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_circle_3_32.v $(RTL_DIR)/circle_3_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_32.v

$(BUILD_DIR)/tb_disk_32: $(RTL_DIR)/disk_32.v $(TB_DIR)/tb_disk_32.v $(RTL_DIR)/circle_2_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/cordic_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_sqrt_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_disk_32.v $(RTL_DIR)/disk_32.v $(RTL_DIR)/circle_2_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/cordic_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_sqrt_32.v

$(BUILD_DIR)/tb_sphere_32: $(RTL_DIR)/sphere_32.v $(TB_DIR)/tb_sphere_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/circle_3_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_32.v $(RTL_DIR)/cordic_sqrt_32.v | $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $(TB_DIR)/tb_sphere_32.v $(RTL_DIR)/sphere_32.v $(RTL_DIR)/vdc_32.v $(RTL_DIR)/circle_3_32.v $(RTL_DIR)/vdc_3_ilds_32.v $(RTL_DIR)/cordic_32.v $(RTL_DIR)/cordic_sqrt_32.v

$(BUILD_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR)
	@rm -f $(TB_DIR)/*.vcd
