# Dynamic Syscall Stub (Windows x64, Assembly)

<p align="center">
  <img src="https://img.shields.io/badge/status-active-success?style=flat-square"/>
  <img src="https://img.shields.io/badge/platform-Windows%20x64-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/language-x64%20Assembly-critical?style=flat-square"/>
  <img src="https://img.shields.io/badge/syscalls-dynamic-important?style=flat-square"/>
  <img src="https://img.shields.io/badge/purpose-educational-lightgrey?style=flat-square"/>
</p>


This repository contains a **minimal, educational proof-of-concept** of a **dynamic syscall stub implemented in pure x64 Assembly** for Windows.

The project demonstrates how to:
- Resolve a syscall ID **at runtime**
- Invoke a Windows `Nt*` syscall **directly**
- Avoid hardcoded syscall numbers
- Perform a real user → kernel → user transition

---

## 🚀 What this project does

This program dynamically resolves and executes the `NtOpenProcess` syscall by:

1. Locating `ntdll.dll` via the **PEB (Process Environment Block)**
2. Parsing the **Export Table** to find `NtOpenProcess`
3. Extracting the syscall ID from the function stub (`mov eax, imm32`)
4. Executing the syscall using a **custom syscall stub**
5. Opening a handle to the **current process**
6. Printing the syscall ID and resulting handle

All of this is done **without calling high-level APIs like `OpenProcess`**.

---

## 🧠 Why this is a *dynamic* syscall stub

- The syscall ID is **not hardcoded**
- It is resolved **at runtime** from the loaded `ntdll.dll`
- The same binary works across Windows versions where syscall IDs differ

This approach is commonly referred to as:
- *Dynamic syscall resolution*
- *Manual syscall invocation*
- *Direct syscall stub*

---

## 🧩 Core syscall stub

```asm
syscall_stub:
    mov r10, rcx
    mov eax, [sys_id]
    syscall
    ret
````

This stub follows the **Windows x64 syscall ABI**:

* `RCX` is mirrored into `R10`
* `EAX` contains the syscall ID
* Arguments are passed via registers

---

## 🖥️ Example output

```text
[+] Entered main() - Initializing execution flow
[+] Resolved syscall ID for NtOpenProcess: 0x00000026
[+] Invoking direct syscall (NtOpenProcess)
[+] Success - Process handle acquired: 0x9C
```

The returned handle is a **real kernel handle**, not a fake value.

---

## 🔍 How to validate it works (recommended)

Use **x64dbg** to observe:

* Runtime resolution of the syscall ID
* The `syscall` instruction being executed
* Return value (`NTSTATUS`) in `EAX`
* Kernel-written handle in user memory

This confirms the syscall transition is real.

---

## ⚠️ Notes & limitations

* This project is **educational / research-oriented**
* It does **not** include:

  * Hook detection
  * EDR bypass techniques
  * Syscall fallback logic
* It targets **Windows x64 only**
* It opens **only the current process**

---

## 📚 Intended audience

This project is useful for:

* Low-level Windows developers
* Reverse engineering learners
* Malware development research (educational)
* Understanding how Windows syscalls work internally

---

## 🛠 Build

Assemble and link using NASM + MSVC linker (example):

```bat
nasm -f win64 syscall.asm -o syscall.obj
link syscall.obj kernel32.lib /subsystem:console /entry:main
```

---

## 📜 Disclaimer

This code is provided **for educational and research purposes only**.
The author is not responsible for misuse.

---

## ❤️ Author

🥷 Slayer  
🔗 [pwnbuffer.org](https://pwnbuffer.org)  
🐧 Free code is free knowledge.
