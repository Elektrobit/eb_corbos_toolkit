/// Copyright 2025 Elektrobit Automotive GmbH
/// All rights reserved

#include <stdio.h>
#include <unistd.h>

#include <sys/ioctl.h>

#define SLEEP   1 // Sleep 1s between runs

int main() {
  unsigned int i = 0;

  // Disable buffering as the required syscall isn't allowed in HI mode.
  // NOLINTNEXTLINE(bugprone-unsafe-functions,cert-msc24-c,cert-msc33-c)
  setbuf(stdout, NULL);

  printf("Hello safety!\n");
 
#if defined(IS_FASTDEV)

  // Let's explicitly do a forbidden syscall and trigger a kernel message
  // for demo purpose. This only works in fastdev environments, as in
  // full integrations the OS safety monitor would detect this and trigger
  // the health signal handler.
  ioctl(0, 0);

#endif

  while(1) {
    sleep(SLEEP);
    i++;
    // Use the following line to spam the serial console
    // printf("Hello safety #%u!\n", i);
  }
  
  return 0;
}
