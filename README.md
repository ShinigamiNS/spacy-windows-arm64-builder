# spaCy for Windows ARM64: Build Tools & Pre-compiled Wheels

This repository contains tools and instructions to successfully compile **spaCy** (and its dependencies like `srsly`, `blis`, `thinc`) on **Windows on ARM64** devices (Surface Pro X, Surface Laptop 7, Snapdragon Dev Kits, etc.).

## 🛑 The Problem
Building spaCy from source via `pip` on Windows ARM64 often fails with:
* **Compiler Crashes:** `error: command 'cl.exe' failed: None` (The native MSVC compiler is unstable in some environments).
* **Linker Errors:** `lld-link: error: could not open 'libcmt.lib'` (Library paths are not automatically found).
* **Narrowing Errors:** `error: non-constant-expression cannot be narrowed` (If switching to Clang without specific flags).

## ✅ The Solution
This repository provides a **"Masquerade Script"** (`build_spacy_arm64.bat`) that:
1.  **Activates** the correct Visual Studio ARM64 environment.
2.  **Shims** the compiler: It forces Python to use `clang-cl.exe` (which is stable) by disguising it as `cl.exe`.
3.  **Auto-Locates Libraries:** It hunts your drive for the correct ARM64 versions of `msvcrt.lib`, `kernel32.lib`, and `ucrt.lib` and forces the linker to use them.
4.  **Fixes Compilation:** Injects flags (`-Wno-c++11-narrowing`) to bypass strict Clang errors.

## 🚀 Quick Start (Use the Wheel)
If you just want to install spaCy without building it, download the `.whl` file from the [Releases/Dist folder] and run:

```bash
pip install spacy-3.x.x-cp311-cp311-win_arm64.whl

```


## 🛠️ How to Build from Source
If you need to build it yourself (e.g., for a different python version), follow these steps.

1. Prerequisites
Install Visual Studio Build Tools 2022. In the "Individual Components" tab, ensure these are checked:

MSVC v143 - VS 2022 C++ ARM64/ARM64EC build tools

C++ Clang Compiler for Windows

Windows 11 SDK (10.0.22621.0) (Critical for libcmt.lib)

C++ ATL for v143 build tools (ARM64)

2. Setup
Clone this repo.

Download the spaCy source code.

Copy build_scripts/build_spacy_arm64.bat into the root of the spaCy source folder.

3. Run the Builder
Right-click build_spacy_arm64.bat and select Run as Administrator.

The script will:

  Detect your Python installation automatically.
  
  Create a temp shim folder (C:\cls_shim).
  
  Install build dependencies (cython, numpy).
  
  Compile the project using the Clang shim.
  
  Output the final .whl file in the dist/ folder.
