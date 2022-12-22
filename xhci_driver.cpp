/**
 * @file /xhci.cpp
 * @brief This file implements a xhci driver executed on uio.
 * 
*/

#include <iostream>
#include <fcntl.h>
#include <unistd.h>
using namespace std;

int uiofd;
int configfd;

void DumpPciConfigSpace()
{
    char buf[4];
    for (int i = 0; i < 4; i++) {
        pread(configfd, buf, 4, i * 4);
        for (int j = 0; j < 4; j++) {
            printf("%02hhx ", buf[j]);
        }
        printf("\n");
    }
}

int main()
{
    /* file for interruptions */
    uiofd = open("/dev/uio0", O_RDONLY);
    if (uiofd == -1) {
        cout << "failed to open /dev/uio0" << endl;
        exit(EXIT_FAILURE);        
    }

    /* file for pci configuration */
    configfd = open("/sys/class/uio/uio0/device/config", O_RDWR);
    if (configfd == -1) {
        cout << "failed to open /sys/class/uio/uio0/device/config" << endl;
        exit(EXIT_FAILURE);        
    }

    DumpPciConfigSpace();
}
