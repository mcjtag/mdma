# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Settings}]
  set_property tooltip {Settings} ${Page_0}
  #Adding Group
  set General [ipgui::add_group $IPINST -name "General" -parent ${Page_0}]
  set_property tooltip {General} ${General}
  ipgui::add_param $IPINST -name "C_M_AXI_BURST_LEN" -parent ${General} -widget comboBox
  ipgui::add_param $IPINST -name "C_INTERRUPT_USE" -parent ${General} -widget comboBox

  #Adding Group
  set MM2S_Channel [ipgui::add_group $IPINST -name "MM2S Channel" -parent ${Page_0}]
  set_property tooltip {MM2S Channel} ${MM2S_Channel}
  ipgui::add_param $IPINST -name "C_MM2S_CHANNEL" -parent ${MM2S_Channel} -widget comboBox
  ipgui::add_param $IPINST -name "C_M_AXIS_DATA_WIDTH" -parent ${MM2S_Channel} -widget comboBox

  #Adding Group
  set S2MM_Channel [ipgui::add_group $IPINST -name "S2MM Channel" -parent ${Page_0}]
  set_property tooltip {S2MM Channel} ${S2MM_Channel}
  ipgui::add_param $IPINST -name "C_S2MM_CHANNEL" -parent ${S2MM_Channel} -widget comboBox
  ipgui::add_param $IPINST -name "C_S_AXIS_DATA_WIDTH" -parent ${S2MM_Channel} -widget comboBox



}

proc update_PARAM_VALUE.C_INTERRUPT_USE { PARAM_VALUE.C_INTERRUPT_USE } {
	# Procedure called to update C_INTERRUPT_USE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_INTERRUPT_USE { PARAM_VALUE.C_INTERRUPT_USE } {
	# Procedure called to validate C_INTERRUPT_USE
	return true
}

proc update_PARAM_VALUE.C_MM2S_CHANNEL { PARAM_VALUE.C_MM2S_CHANNEL } {
	# Procedure called to update C_MM2S_CHANNEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MM2S_CHANNEL { PARAM_VALUE.C_MM2S_CHANNEL } {
	# Procedure called to validate C_MM2S_CHANNEL
	return true
}

proc update_PARAM_VALUE.C_M_AXIS_DATA_WIDTH { PARAM_VALUE.C_M_AXIS_DATA_WIDTH } {
	# Procedure called to update C_M_AXIS_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_DATA_WIDTH { PARAM_VALUE.C_M_AXIS_DATA_WIDTH } {
	# Procedure called to validate C_M_AXIS_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_ADDR_WIDTH } {
	# Procedure called to update C_M_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_M_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_BURST_LEN { PARAM_VALUE.C_M_AXI_BURST_LEN } {
	# Procedure called to update C_M_AXI_BURST_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_BURST_LEN { PARAM_VALUE.C_M_AXI_BURST_LEN } {
	# Procedure called to validate C_M_AXI_BURST_LEN
	return true
}

proc update_PARAM_VALUE.C_M_AXI_DATA_WIDTH { PARAM_VALUE.C_M_AXI_DATA_WIDTH } {
	# Procedure called to update C_M_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_DATA_WIDTH { PARAM_VALUE.C_M_AXI_DATA_WIDTH } {
	# Procedure called to validate C_M_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S2MM_CHANNEL { PARAM_VALUE.C_S2MM_CHANNEL } {
	# Procedure called to update C_S2MM_CHANNEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S2MM_CHANNEL { PARAM_VALUE.C_S2MM_CHANNEL } {
	# Procedure called to validate C_S2MM_CHANNEL
	return true
}

proc update_PARAM_VALUE.C_S_AXIS_DATA_WIDTH { PARAM_VALUE.C_S_AXIS_DATA_WIDTH } {
	# Procedure called to update C_S_AXIS_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXIS_DATA_WIDTH { PARAM_VALUE.C_S_AXIS_DATA_WIDTH } {
	# Procedure called to validate C_S_AXIS_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to update C_S_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to validate C_S_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to update C_S_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to validate C_S_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_M_AXI_ADDR_WIDTH PARAM_VALUE.C_M_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_M_AXI_DATA_WIDTH PARAM_VALUE.C_M_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_BURST_LEN { MODELPARAM_VALUE.C_M_AXI_BURST_LEN PARAM_VALUE.C_M_AXI_BURST_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_BURST_LEN}] ${MODELPARAM_VALUE.C_M_AXI_BURST_LEN}
}

proc update_MODELPARAM_VALUE.C_S_AXIS_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXIS_DATA_WIDTH PARAM_VALUE.C_S_AXIS_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXIS_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXIS_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_DATA_WIDTH { MODELPARAM_VALUE.C_M_AXIS_DATA_WIDTH PARAM_VALUE.C_M_AXIS_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXIS_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_INTERRUPT_USE { MODELPARAM_VALUE.C_INTERRUPT_USE PARAM_VALUE.C_INTERRUPT_USE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_INTERRUPT_USE}] ${MODELPARAM_VALUE.C_INTERRUPT_USE}
}

proc update_MODELPARAM_VALUE.C_MM2S_CHANNEL { MODELPARAM_VALUE.C_MM2S_CHANNEL PARAM_VALUE.C_MM2S_CHANNEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MM2S_CHANNEL}] ${MODELPARAM_VALUE.C_MM2S_CHANNEL}
}

proc update_MODELPARAM_VALUE.C_S2MM_CHANNEL { MODELPARAM_VALUE.C_S2MM_CHANNEL PARAM_VALUE.C_S2MM_CHANNEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S2MM_CHANNEL}] ${MODELPARAM_VALUE.C_S2MM_CHANNEL}
}

