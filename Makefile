
# The bus id of xHCI.
xhci_bus_id	= $(addprefix 0000:,$(shell lspci | grep xHCI | cut -d ' ' -f 1))

# Loads uio module to kernel.
.PHONY: load_uio
load_uio:
	modprobe uio

# Loads uio_pci_generic module to kernel.
.PHONY: load_uio_pci_generic
load_uio_pci_generic:
	modprobe uio_pci_generic

# Enables the xHCI in uio 
.PHONY: enable_xhci
enable_xhci:
	@modprobe uio_pci_generic
	@sudo sh -c 'echo -n $(xhci_bus_id) > /sys/bus/pci/drivers/xhci_hcd/unbind' 
	@sudo sh -c 'echo -n $(xhci_bus_id) > /sys/bus/pci/drivers/uio_pci_generic/bind' 
	@echo 'See /dev/uioX'

# Disables the xHCI in uio 
.PHONY: disable_xhci
disable_xhci:
	@modprobe uio_pci_generic
	@sudo sh -c 'echo -n $(xhci_bus_id) > /sys/bus/pci/drivers/uio_pci_generic/unbind'
	@sudo sh -c 'echo -n $(xhci_bus_id) > /sys/bus/pci/drivers/xhci_hcd/bind'
