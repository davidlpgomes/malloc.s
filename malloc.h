#ifndef MALLOC_H
#define MALLOC_H

/*!
    \brief Executes the brk syscall to get the address of the heap top
*/
void startAllocator();

/*!
    \brief Restores the heap state
*/
void endAllocator();

/*!
    \brief Free the memory used on the pointer param

    \param pointer pointer to the memory block
*/
void freeMem(void* pointer);

/*!
    \brief Alloc num_bytes bytes on the heap and returns the address

    \param num_bytes number of bytes to alloc

    \returns The addres to the allocated memory block
*/
void* alloc(int num_bytes);

/*!
    \brief Prints the heap state. Each character represents one byte.
    '#' represents a management byte, '+' represents a occupied byte, and
    '-' represents a free byte.
*/
void printHeap();

#endif
