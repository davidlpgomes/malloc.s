.section .data
    INITIAL_HEAP_TOP: .quad 0
    HEAP_TOP: .quad 0
    BRK: .quad 0
    MANAGERIAL_STR: .string "################"
    FREE_BYTE_CHAR: .string "-"
    OCCUPIED_BYTE_CHAR: .string "+"

.section .text

.globl startAllocator
.type startAllocator, @function
startAllocator:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax
    movq $0, %rdi
    syscall

    movq %rax, INITIAL_HEAP_TOP
    movq %rax, HEAP_TOP
    movq %rax, BRK

    popq %rbp
    ret


.globl endAllocator
.type endAllocator, @function
endAllocator:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax
    movq INITIAL_HEAP_TOP, %rdi
    movq %rdi, HEAP_TOP
    movq %rdi, BRK
    syscall

    popq %rbp
    ret


.globl freeMem
.type freeMem, @function
freeMem:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rax
    subq $16, %rax
    movq $0, (%rax)

    call joinNodes
    call joinNodes

    popq %rbp
    ret


joinNodes:
    pushq %rbp
    movq %rsp, %rbp

    movq INITIAL_HEAP_TOP, %rdi
    jmp joinNodesWhile

    joinNodesIncrement:
    cmpq %rdi, HEAP_TOP
    jle joinNodesEnd

    movq %rdi, %r14
    addq $8, %r14
    movq (%r14), %r10
    addq $16, %rdi
    addq %r10, %rdi   # Increments %rdi

    joinNodesWhile:
    movq (%rdi), %r14 # r14 = byte de gerenciamento
    cmpq $1, %r14
    je joinNodesIncrement

    joinNodesFuse:
    movq %rdi, %rax   # rax aponta pro inicio do bloco 1
    addq $8, %rax     # rax aponta pro 2o byte gerencial
    movq (%rax), %r10 # r10 = numBytes do primeiro bloco

    movq %rdi, %r11   # r11 aponta pro inicio do bloco 1
    addq $16, %r11
    addq %r10, %r11   # r11 += numBytes do primeiro bloco

    cmpq %r11, HEAP_TOP
    jle joinNodesEnd

    movq (%r11), %r12 # r12 conteudo do primeiro byte do segundo bloco
    cmpq $1, %r12     # se segundo bloco estiver ocupado não combina
    je joinNodesIncrement

    addq $8, %r11     # r11 -> byte de tamanho do segundo bloco
    movq (%r11), %r13 # r13 = tamanho do segundo bloco

    movq %rdi, %r11
    addq $8, %r11     # r11 = byte de tamanho do primeiro bloco
    addq %r13, (%r11) # r11 += tamanho do segundo bloco
    addq $16, (%r11) 

    joinNodesEnd:
    popq %rbp
    ret


.globl alloc
.type alloc, @function
alloc:
    pushq %rbp
    movq %rsp, %rbp
    subq $40, %rsp

    movq INITIAL_HEAP_TOP, %rax
    movq %rax, -8(%rbp) # node = topoInicial

    movq HEAP_TOP, %rax
    movq %rax, -16(%rbp) # bestFit = topo

    movq $0, -24(%rbp) # bestFitFound = 0

    movq %rdi, -32(%rbp) # numBytes = %rdi

    movq %rbx, -40(%rbp) # salva %rbx

    allocWhile:
    # while (node != topoHeap)
    movq HEAP_TOP, %rax
    cmpq -8(%rbp), %rax
    je allocWhileEnd

    # checa se nodo está disponível
    movq -8(%rbp), %rbx
    movq (%rbx), %rax
    cmpq $1, %rax
    je allocWhileIncrement

    # checa se tamanho do nodo é maior ou igual ao solicitado
    movq -8(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rax
    movq -32(%rbp), %rdi
    cmpq %rax, %rdi
    jg allocWhileIncrement

    movq -24(%rbp), %rbx
    cmpq $1, %rbx
    je allocWhileBestFitFound
    jmp allocWhileBestFitNotFound

    allocWhileBestFitFound:
    movq -16(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rdi
    cmpq %rdi, %rax
    jge allocWhileIncrement

    movq -8(%rbp), %rax
    movq %rax, -16(%rbp) # bestFit = node

    jmp allocWhileIncrement

    allocWhileBestFitNotFound:
    movq -8(%rbp), %rax
    movq %rax, -16(%rbp) # bestFit = node
    movq $1, -24(%rbp) # bestFitFound = 1
    jmp allocWhileIncrement

    allocWhileIncrement:
    # Incrementa o node
    movq -8(%rbp), %rax
    addq $8, %rax
    movq (%rax), %rdi # rdi = numBytes

    addq $16, -8(%rbp)  # node += 16
    addq %rdi, -8(%rbp) # node += numBytes

    jmp allocWhile

    allocWhileEnd:
    # checa se bestFit == topoHead
    movq HEAP_TOP, %rdi
    cmpq -16(%rbp), %rdi
    jne allocSliceBlock

    # ALTERA TOPO HEAP
    movq HEAP_TOP, %r14 # topoAntigo = topoHeap
    addq $16, HEAP_TOP
    movq -32(%rbp), %rbx
    addq %rbx, HEAP_TOP # topoHead += 16 + numBytes

    # VERIFICA SE HEAP_TOP > BRK
    movq HEAP_TOP, %rax
    movq BRK, %rdi
    cmp %rax, %rdi
    jge allocUpdateHeapTop

    subq %rdi, %rax  # diff = topoHeap - brkHeap
    movq %rax, %rbx
    andq $4095, %rax # diff % 4096
    cmpq $0, %rax
    je allocUpdateBrk

    addq $4096, %rbx
    subq %rax, %rbx  # diff += 4096 - (diff % 4096)

    allocUpdateBrk:
    # ALTERA BRK
    movq BRK, %rdi
    addq %rbx, %rdi
    movq $12, %rax
    syscall

    allocUpdateHeapTop:
    addq $8, %r14
    movq -32(%rbp), %rbx # topoAntigo+1 = numBytes
    movq %rbx, (%r14)
    jmp allocEnd

    allocSliceBlock:
    # -16(%rbp) apontando pro 1o byte de gerenciamento bestFit (= nodo encontrado)
    # numBytes em -32(%rbp) = N
    movq -16(%rbp), %rax
    movq %rax, %rbx  # rbx = end. 1o byte de gerenciamento bestFit
    addq $8, %rbx
    movq (%rbx), %r10 # r10 = tamanho do bestFit = M
    movq %r10, %r11 # r11 = M
    subq -32(%rbp), %r11 # r11 = M - N
    cmpq $17, %r11
    jl allocEnd # se (M - N) < 17, não divide bloco

    # r10 = M
    # -32(%rbp) = N
    # r11 = M - N

    addq $8, %rbx   # rbx -> aponta para o fim dos bytes de gerenciamento do bestFit
    addq -32(%rbp), %rbx # rbx -> aponta para o início do próximo bloco (a ser criado)
    movq $0, (%rbx) # 1o byte de gerenciamento do bloco a ser criado recebe 0 (livre)

    subq $16, %r11  # r11 = tamanho do segundo bloco
    addq $8, %rbx
    movq %r11, (%rbx) # 2o byte de gerenciamento do bloco a ser criado recebe (M - N - 16)

    # atualizar tamanho do primeiro bloco:
    movq %rax, %rbx
    addq $8, %rbx
    movq -32(%rbp), %r12
    movq %r12, (%rbx) # byte de tamanho do 1o primeiro bloco recebe N


    allocEnd:
    movq -16(%rbp), %rax
    movq $1, (%rax) # *bestFit = 1

    addq $16, %rax # retorna *x

    movq -40(%rbp), %rbx # restaura %rbx

    addq $40, %rsp
    popq %rbp
    ret

.globl printHeap
.type printHeap, @function
printHeap:
    pushq %rbp
    movq %rsp, %rbp
    subq $8, %rsp # node

    movq $1, %rax # syscall write
    movq $1, %rdi # write on stdout

    movq INITIAL_HEAP_TOP, %r10
    movq %r10, -8(%rbp) # node = topoInicial

    printHeapWhile:
    # while (node != topoHeap)
    movq HEAP_TOP, %r10
    cmpq -8(%rbp), %r10
    je printHeapWhileEnd

    movq $16, %rdx
    movq $MANAGERIAL_STR, %rsi
    syscall # write # 16x on stdout

    movq $1, %rdx
    movq $OCCUPIED_BYTE_CHAR, %rsi

    # checa se nodo está disponível
    movq -8(%rbp), %r10
    movq (%r10), %r11
    cmpq $1, %r11
    je printHeapIfEnd

    movq $FREE_BYTE_CHAR, %rsi

    # ########
    printHeapIfEnd:
    addq $8, %r10
    movq (%r10), %r14 # r14 = numBytes
    movq $0, %r12 # r12 = 0

    printHeapWhileData:
    # while (i != numBytes)
    cmpq %r14, %r12
    jg printHeapWhileDataEnd
    syscall # write + or - 1x on stdout
    movq $1, %rax
    addq $1, %r12
    jmp printHeapWhileData
    # #########

    printHeapWhileDataEnd:
    movq -8(%rbp), %r10
    addq $8, %r10
    movq (%r10), %r11 # r11 = numBytes

    addq $16, -8(%rbp)  # node += 16
    addq %r11, -8(%rbp) # node += numBytes

    jmp printHeapWhile

    printHeapWhileEnd:
    # NEW LINE
    pushq $'\n'
    movq $1, %rax
    movq $1, %rdi
    movq %rsp, %rsi
    movq $1, %rdx
    syscall
    addq $8, %rsp

    # NEW LINE
    pushq $'\n'
    movq $1, %rax
    movq $1, %rdi
    movq %rsp, %rsi
    movq $1, %rdx
    syscall
    addq $8, %rsp

    addq $8, %rsp
    popq %rbp
    ret
