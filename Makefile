
# Loads uio module to kernel.
.PHONY: load_uio
load_uio:
	modprobe uio

# Loads uio_pci_generic module to kernel.
.PHONY: load_uio_pci_generic
load_uio_pci_generic:
	modprobe uio_pci_generic
