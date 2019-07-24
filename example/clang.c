#!/usr/bin/c
#include <stdio.h>

int main(int args, char *argv[]) {
printf("Arguments received: %d", args);
int i = 0;
for (i = 0; i < args; i++){
        printf("\n%s", argv[i]);
}
printf("\n");
return 0;
}

/*  Sidenote:
        for shebang support
        https://github.com/ryanmjacobs/c
*/