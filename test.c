#include <stdio.h>

#include "malloc.h"

int main() {
    startAllocator();
    printHeap();

    void *a, *b, *c, *d, *e;

    // Initial alloc
    a = alloc(100);
    printHeap();

    b = alloc(130);
    printHeap();

    c = alloc(120);
    printHeap();

    d = alloc(110);
    printHeap();

    // Test
    freeMem(b);
    printHeap();

    freeMem(d);
    printHeap();

    b = alloc(50);
    printHeap();

    d = alloc(90);
    printHeap();

    e = alloc(40);
    printHeap();

    // Free
    freeMem(c);
    printHeap(); 

    freeMem(a);
    printHeap();

    freeMem(b);
    printHeap();

    freeMem(d);
    printHeap();

    freeMem(e);
    printHeap();

    endAllocator();

    return 0;
}
