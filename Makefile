target		:= xhci_driver
sources		:= $(wildcard *.cpp)
objects		:= $(subst .cpp,.o,$(sources))
CXX			:= g++
CXXFLAGS	:= -Wall
# The bus id of xHCI.
xhci_id 	= $(shell lspci -nn | grep xHCI | grep -o '\[....\:....\]' | sed 's#\[##' | sed 's#\]##' | sed 's#\:# #')
xhci_bus_id	= $(addprefix 0000:,$(shell lspci | grep xHCI | cut -d ' ' -f 1))

all: $(target)

run: $(target)
	sudo ./$(target)

$(target): $(objects)
	$(CXX) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $^

# loads modules and registers the vendor/device id of the xhci
.PHONY: setup_uio_xhci
setup_uio_xhci:
	modprobe uio_pci_generic
	echo $(xhci_id) | sudo tee /sys/bus/pci/drivers/uio_pci_generic/new_id

# enables xhci in uio
.PHONY: enable_uio_xhci
enable_uio_xhci:
	modprobe uio_pci_generic
	echo -n $(xhci_bus_id) | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind > /dev/null
	echo -n $(xhci_bus_id) | sudo tee /sys/bus/pci/drivers/uio_pci_generic/bind > /dev/null

# disables xhci in uio 
.PHONY: disable_uio_xhci
disable_uio_xhci:
	modprobe uio_pci_generic
	echo -n $(xhci_bus_id) | sudo tee /sys/bus/pci/drivers/uio_pci_generic/unbind > /dev/null
	echo -n $(xhci_bus_id) | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind > /dev/null

.PHONY: debug
debug:
	@echo $(xhci_id)
	@echo $(xhci_bus_id)

.PHONY: clean
clean:
	rm -r -f $(target) $(objects)
