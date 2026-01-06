BITS 64
DEFAULT REL

extern GetStdHandle
extern WriteFile
extern ExitProcess
extern GetCurrentProcessId

STDOUT_HANDLE equ -11
;info debug
section .data
msg_start   db "[+] Entered main() - Initializing execution flow",13,10
len_start   equ $-msg_start

msg_sid     db "[+] Resolved syscall ID for NtOpenProcess: 0x",0
len_sid     equ $-msg_sid

msg_call    db "[+] Invoking direct syscall (NtOpenProcess)",13,10
len_call    equ $-msg_call

msg_ok      db "[+] Success - Process handle acquired: 0x",0
msg_fail    db "[-] Failure - NTSTATUS returned: 0x",0
nl          db 13,10

hex_digits  db "0123456789ABCDEF"
target_name db "NtOpenProcess",0


section .bss
written     resd 1
hexbuf      resb 32
hProcess    resq 1
sys_id      resd 1

cid_pid     resq 1
cid_tid     resq 1

oa_len      resd 1
oa_pad1     resd 1
oa_root     resq 1
oa_name     resq 1
oa_attr     resd 1
oa_pad2     resd 1
oa_security resq 1
oa_qos      resq 1

section .text
global main

write_msg:
    sub rsp, 40
    mov r8, rdx
    mov rdx, rcx
    mov ecx, STDOUT_HANDLE
    call GetStdHandle
    mov rcx, rax
    lea r9, [written]
    mov qword [rsp+32], 0
    call WriteFile
    add rsp, 40
    ret

write_str:
    push rsi
    mov rsi, rcx
    xor rdx, rdx
.strlen:
    cmp byte [rsi+rdx], 0
    je .strdone
    inc rdx
    jmp .strlen
.strdone:
    call write_msg
    pop rsi
    ret

write_hex_rax:
    push rbx
    lea rsi, [hexbuf+32]
    mov rbx, 16
.hex:
    xor rdx, rdx
    div rbx
    dec rsi
    mov dl, [hex_digits + rdx]
    mov [rsi], dl
    test rax, rax
    jnz .hex
    mov rcx, rsi
    lea rdx, [hexbuf+32]
    sub rdx, rsi
    call write_msg
    pop rbx
    ret

write_hex_eax:
    push rax
    push rbx
    mov rbx, 16
    lea rsi, [hexbuf+8]
    mov ecx, 8
.hex:
    xor edx, edx
    div ebx
    dec rsi
    mov dl, [hex_digits + rdx]
    mov [rsi], dl
    loop .hex
    mov rcx, rsi
    mov rdx, 8
    call write_msg
    pop rbx
    pop rax
    ret

syscall_stub:
    mov r10, rcx
    mov eax, [sys_id]
    syscall
    ret

find_syscall_id:
    push rsi
    mov rsi, rax
    
    mov ecx, 64
.search_mov_eax:
    cmp byte [rsi], 0xB8
    je .found_mov_eax
    inc rsi
    loop .search_mov_eax
    mov eax, 0
    jmp .done
    
.found_mov_eax:
    mov eax, [rsi + 1]
    
.done:
    pop rsi
    ret

;main
main:
    sub rsp, 40


    lea rcx, [msg_start]
    mov edx, len_start
    call write_msg


    mov rax, gs:[0x60] 
    mov rax, [rax + 0x18] 
    mov rax, [rax + 0x20]
    mov rax, [rax]
    mov rdi, [rax + 0x20]

    mov eax, [rdi + 0x3C]
    add rax, rdi
    mov eax, [rax + 0x88]
    add rax, rdi
    mov rsi, rax

    mov ecx, [rsi + 0x18]
    mov r8d, [rsi + 0x20]
    add r8, rdi
    mov r9d, [rsi + 0x24]
    add r9, rdi
    mov r10d,[rsi + 0x1C]
    add r10, rdi

    xor ecx, ecx
.find_loop:
    cmp ecx, [rsi + 0x18]
    jge .fail_export
    
    mov eax, [r8 + rcx*4]
    add rax, rdi
    mov r11, rax
    lea r12, [target_name]

.compare:
    mov al, [r11]
    mov dl, [r12]
    cmp al, dl
    jne .next
    test al, al
    jz .found_name
    inc r11
    inc r12
    jmp .compare

.next:
    inc ecx
    jmp .find_loop

.found_name:
    movzx eax, word [r9 + rcx*2]
    mov eax, [r10 + rax*4]
    add rax, rdi

    call find_syscall_id
    test eax, eax
    jz .fail_export
    mov [sys_id], eax

    ;syscall id print
    lea rcx, [msg_sid]
    call write_str
    mov eax, [sys_id]
    call write_hex_eax
    lea rcx, [nl]
    mov edx, 2
    call write_msg

    call GetCurrentProcessId
    mov [cid_pid], rax
    xor rax, rax
    mov [cid_tid], rax

    mov dword [oa_len], 48
    xor rax, rax
    mov [oa_pad1], eax
    mov [oa_root], rax
    mov [oa_name], rax
    mov [oa_attr], eax
    mov [oa_pad2], eax
    mov [oa_security], rax
    mov [oa_qos], rax

    lea rcx, [msg_call]
    mov edx, len_call
    call write_msg

    lea rcx, [hProcess]
    mov edx, 0x1F0FFF
    lea r8, [oa_len]
    lea r9, [cid_pid]
    call syscall_stub

    ;vef resultado
    test eax, eax
    jnz .fail_syscall

    ;sucesso
    lea rcx, [msg_ok]
    call write_str
    mov rax, [hProcess]
    call write_hex_rax
    lea rcx, [nl]
    mov edx, 2
    call write_msg
    jmp .exit

.fail_export:
    lea rcx, [msg_fail]
    call write_str
    mov eax, 0xFFFFFFFF
    call write_hex_eax
    lea rcx, [nl]
    mov edx, 2
    call write_msg
    jmp .exit

.fail_syscall:
    lea rcx, [msg_fail]
    call write_str
    call write_hex_eax
    lea rcx, [nl]
    mov edx, 2
    call write_msg

.exit:
    xor ecx, ecx
    call ExitProcess