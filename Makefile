FAMILY=Cyclone IV E
PART=EP4CE22F17C6
PROJECT_NAME=riscv_core
SRC_FILES=adder.sv  aludec.sv  alu.sv  core_controller.sv  core_datapath.sv  extend.sv  flip_flops.sv  hazard_unit.sv  maindec.sv  muxes.sv  regfile.sv  riscv_core.sv

TARGETS=$(PROJECT_NAME).map.rpt

SAUCE=--source=adder.sv  --source=aludec.sv  --source=alu.sv --source=core_controller.sv  --source=core_datapath.sv  --source=extend.sv --source=flip_flops.sv  --source=hazard_unit.sv  --source=maindec.sv --source=muxes.sv  --source=regfile.sv  --source=riscv_core.sv

all: $(TARGETS)

%.map.rpt: $(SRC_FILES)
	quartus_map $(PROJECT_NAME) $(SAUCE) --family="$(FAMILY)" --part="$(PART)"
	#quartus_map $(PROJECT_NAME) --source=$^ --family="$(FAMILY)" --part="$(PART)"

clean:
	@rm -f $(TARGETS)