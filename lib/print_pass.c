#include <stdio.h>
#include <stdlib.h>

int main () {
   printf("%s\n", getenv("SSHFS_AUTH_PASSPHRASE"));
   return(0);
}