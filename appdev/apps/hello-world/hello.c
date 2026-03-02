/// Copyright 2025 Elektrobit Automotive GmbH
/// All rights reserved

#include <stdio.h>
#include <unistd.h>

#define NR_RUNS 5 // Run the loop 5 times
#define SLEEP   1 // Sleep 1s between runs

int main() {
  unsigned int i = 0;
  
  printf("Hello world!\n");

  for(i=0; i < NR_RUNS; i++) {
    sleep(1);
    printf("Hello again #%u!\n", i);
  }
  
  return 0;
}
