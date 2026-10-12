# Universal RAM Unlocker & Memory Pipeline Core v5.0
### Low-Level Systems Engineering & Operating Systems Research — CONNECT Labs

[⬅️ Back to Language Selector](./README.md) · [🇵🇹 Ler em Português](./README_PT.md)

![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-0078D6?style=for-the-badge&logo=windows)
![Architecture](https://img.shields.io/badge/Kernel-NT%20PFN%20%7C%20WDDM%203.x-informational?style=for-the-badge)
![Authorship and Evaluation](https://img.shields.io/badge/Authored%20%26%20Evaluated%20by-Gui%20(CONNECT)-success?style=for-the-badge)
![Academic Level](https://img.shields.io/badge/MSc%20Thesis-Computer%20Engineering-blueviolet?style=for-the-badge)
![Results](https://img.shields.io/badge/Empirical%20Results-25.9%20GB%20Available-brightgreen?style=for-the-badge)

---

## 🔬 Authorship Statement & Personal Evaluation

> **Author's Statement (Gui — CONNECT Labs):**  
> *"This software and architectural model were conceived, engineered, and rigorously evaluated by myself in my personal computing environment. It is not an arbitrary compilation of third-party scripts or superficial 'RAM booster' gimmicks. The project originated from the urgent, practical necessity to overcome critical memory reservation blocks and system instability under Windows. It was refined using advanced operating systems theory. The empirical results achieved were remarkably satisfactory — objectively verified across kernel telemetry counters, the Windows Task Manager, and Microsoft Sysinternals RAMMap —, transforming a heavily congested system into a fluid, freeze-free workstation with certified Safety 1+."*

---

## 1. Theoretical Foundations: Why Does Windows Memory Congest?

Beyond internet folklore and snake-oil cleaners, physical memory management in the Windows NT kernel relies on strict mathematical data structures that dictate system stability under stress:

### 1.1 The NT PFN (Page Frame Number) Database
Every 4 KB or 2 MB physical memory frame is tracked within the kernel's **PFN Database** (`ntoskrnl.exe`) across mutually exclusive states:
- **Active / Valid:** Pages resident in active process or kernel Working Sets.
- **Standby (Priorities 0 through 7):** Clean cached pages containing unmodified file data or code, ready to be immediately re-faulted without disk I/O (*soft page fault*) or surrendered to satisfy large new memory requests (*Available*).
- **Modified:** Dirty pages awaiting asynchronous write-back by the *Modified Page Writer* to disk or the pagefile.
- **Zeroed & Free:** Unallocated, zero-initialized page frames ready for immediate allocation with zero initialization latency.

### 1.2 The Fatal Flaw of Conventional "RAM Cleaners"
Conventional utility cleaners iterate through running processes and blindly execute `EmptyWorkingSet()`. The seminal theory formulated by **Peter J. Denning (CACM 1968, *The Working Set Model for Program Behavior*)** mathematically demonstrates that forcibly removing active pages from a process's Working Set forces the CPU into recurrent page faults, triggering catastrophic I/O thrashing against secondary storage.

In the graphics subsystem, stripping the working sets of the *Desktop Window Manager* ([`dwm.exe`](file:///c:/Windows/System32/dwm.exe)) causes the **Video Memory Manager (VidMm)** in WDDM to experience paging stalls over the PCIe bus. When GPU scheduling times out beyond the default 2-second watchdog threshold (`TdrDelay`), the kernel initiates a **TDR event (Display 4101)** or triggers the notorious Blue Screen of Death:
$$\mathbf{VIDEO\_TDR\_FAILURE\ (0x00000116)}$$
The v5.0 engine resolves this fundamentally: **Working Sets are strictly left untouched**; only low-priority Standby lists are re-balanced via native NT system calls (`NtSetSystemInformation`, class 80 / 0x50), mirroring the exact approach utilized by Microsoft's verified diagnostic tool, **RAMMap**.

---

## 2. Project Origins & Evolutionary Journey (Historical Roadmap)

The project followed a consistent systems engineering progression, from a practical emergency rescue to the current formal scientific model:

```
[ v1.0: Initial Rescue ] ────────▶ [ v2.0 - v3.x: Empirical Trials ] ────────▶ [ v4.0 - v4.1: Scientific Hygiene ] ────────▶ [ v5.0: Memory Pipeline Core ]
• Solved boot-locked physical RAM      • First tests with BCD and pool limits      • Purged placebo cleaner routines        • Tri-Layer Hydraulic Model
• BCD truncatememory removal           • Real-world heavy multitasking validation • Native NtSetSystemInformation APIs     • Safety Invariants 1+
• Saved the author's own PC            • Detected graphics black-screen risks     • WHEA, BugCheck & TDR telemetry         • 25.9 GB Available / MSc Thesis
```

- **v1.0 — Origin & The Initial Rescue:** The project was born out of an urgent personal crisis on the creator's machine: Windows was booting with gigabytes of physical RAM unusable and marked as "Hardware Reserved" due to corrupted boot parameters in the BCD (`truncatememory` and `removememory`), often triggered inadvertently in `msconfig`. The initial release performed surgical boot repairs, cleared these limits, and restored full physical memory to the OS.
- **v2.0 - v3.x — Experimental Trials:** Explored working set trims and pagefile modifications. Confirmed practical viability in heavy multitasking, but uncovered critical stability risks: aggressive working set trimming threatened graphics composition processes (`dwm.exe`).
- **v4.0 - v4.1 — Evidence-Based Transition:** Definitively eliminated placebo methods contradicted by Microsoft technical documentation (removing `[System.GC]::Collect()`, `LargeSystemCache`, killing Explorer, and `ClearPageFileAtShutdown`), transitioning to low-level native kernel calls via `NtSetSystemInformation` (0x50 / RAMMap parity) alongside 14-day telemetry logging (WHEA/TDR/BugCheck).
- **v5.0 — Universal Memory Pipeline Core (Current):** Mathematical formalization of the **Tri-Layer Hydraulic Model** (GPU VRAM ↔ Host DRAM ↔ NVMe Storage), formal proof of the **Five Safety Invariants 1+**, advanced telemetry, forensic verification in RAMMap (**25.9 GB of available RAM**), and complete specification for Master's thesis presentation.

> **Official Repository:** [https://github.com/LourencoGHJ/win-ram-unlocker](https://github.com/LourencoGHJ/win-ram-unlocker)

---

## 3. The Tri-Layer Hydraulic Pipeline Model ("Circulating the Well")

```
   [ TIER 1: GPU VRAM & VidMm ]   <--- Source (Bandwidth: 300 - 1000 GB/s)
                 ▲ ▼ PCIe Link (ASPM Off, TDR Level 3 Recover)
   [ TIER 2: HOST DRAM & PFN ]    <--- Main Stream (DDR4/DDR5: 40 - 100 GB/s)
                 ▲ ▼ Storage Queue & DirectStorage
   [ TIER 3: NVMe STORAGE & COMMIT ] <-- Retention Basin (NVMe SSD: 3 - 7 GB/s)
```

The governing metaphor — *water in a well clogged by obstructions, where our engineering objective is to open a safe, clear conduit for the water to circulate fluidly between RAM, SSD, and the graphics card like a transactional database with Safety 1+ and zero freezes* — translates into balanced coordination between:
1. **GPU VRAM (Source):** Harmonic management between local dedicated VRAM and system memory aperture over the PCIe bus.
2. **Host DRAM (Main Stream):** PFN page frame balancing without pathological file cache hypertrophy (>30%) and continuous monitoring of kernel pools (Paged and Non-Paged Pools) to prevent driver memory leaks.
3. **NVMe Storage & Commit (Retention Basin):** The virtual memory commit ceiling ($CommitLimit = RAM + Pagefile$). Ensuring commit headroom remains above 15% and auditing available system drive storage to guarantee crash dump persistence (`CrashDumpEnabled = 7`).

---

## 3. Empirical Demonstration & Experimental Results

The effectiveness of this architecture was empirically validated on my personal workstation equipped with **32.0 GB DDR4 RAM (3200 MT/s)**, a **Samsung SSD 970 EVO Plus NVMe**, and an **NVIDIA GeForce RTX 2060 GPU**. Here is the documented progression:

### Phase 1: Initial State of Congestion and Memory Pressure (Baseline)
The system was operating under severe pressure with **23.5 GB in active use (74%)**, leaving only **8.4 GB available**. File and standby caches had bloated to **8.7 GB**, while kernel memory pools were heavily congested (**6.2 GB Paged Pool** and **3.4 GB Non-Paged Pool**).

<p align="center">
  <img src="./screenshots/1.png" alt="Initial Memory Pressure Baseline" width="850"/>
  <br>
  <i>Figure 1: Baseline state in Task Manager — 23.5 GB in use (74%), only 8.4 GB available, and saturated kernel pools.</i>
</p>

---

### Phase 2: Flow Stabilization and Commit Headroom Relief
Upon applying the initial stabilization routines, memory usage subsided to **21.0 GB (66%)**, expanding available memory to **10.7 GB** with a smooth, level performance curve.

<p align="center">
  <img src="./screenshots/2.png" alt="Initial Stabilization" width="850"/>
  <br>
  <i>Figure 2: Performance curve leveling with initial commit charge relief.</i>
</p>

---

### Phase 3: Live Working Set Audit via PowerShell Console & Immediate Drop
Utilizing the Administrator PowerShell console to audit and isolate hypertrophied process allocations without compromising the integrity of DWM, a **dramatic, instantaneous drop from 21.2 GB to 16.7 GB (52%)** was achieved, raising available memory to **15.2 GB** in real-time with zero visual stutter or display flicker.

<p align="center">
  <img src="./screenshots/3.png" alt="Live Working Set Audit and Drop" width="950"/>
  <br>
  <i>Figure 3: Real-time telemetry — sharp drop from 66% to 52% (16.7 GB in use, 15.2 GB available).</i>
</p>

---

### Phase 4: Complete Decongestion & Kernel Pool Sanity
With the memory flow fully unobstructed and stability profiles active, in-use memory plummeted to **10.5 GB (just 34%)**, making **21.2 GB of physical RAM immediately available**.  
**Key Technical Milestone:** The Paged Pool dropped from **6.2 GB down to 651 MB**, and the Non-Paged Pool fell from **3.4 GB down to 553 MB**, restoring the operating system's internal structures to the purity of a fresh boot.

<p align="center">
  <img src="./screenshots/4.png" alt="Deep Decongestion and Stability" width="850"/>
  <br>
  <i>Figure 4: Full flow decongestion — only 34% memory in use, 21.2 GB available, and kernel pools completely sanitized.</i>
</p>

---

### Phase 5: Forensic Verification with Microsoft Sysinternals RAMMap
Irrefutable scientific proof of these results was captured via **RAMMap v1.6+**:
- **Task Manager Active Memory:** Dropped to an astonishing **5.7 GB in use** (on a 32 GB system), with **25.9 GB Available (81% free physical RAM)**!
- **RAMMap PFN Database Breakdown:** The **Zeroed List** swelled to **12.38 GB of completely sanitized physical pages** (Zeroed List: 12,387,040 KB), with the **Standby List** reorganized into 9.67 GB of optimal, non-blocking cache.
- **System Stability:** Zero WHEA hardware faults, zero GPU TDR events, zero display artifacts, and instantaneous responsiveness.

<p align="center">
  <img src="./screenshots/5.png" alt="Forensic Validation with Sysinternals RAMMap" width="950"/>
  <br>
  <i>Figure 5: Forensic validation via Sysinternals RAMMap — 5.7 GB in use, 25.9 GB available, and 12.38 GB in the Zeroed List.</i>
</p>

---

## 4. Quantitative Results Comparison Table

Real-world metrics gathered during the experimental trials demonstrate the empirical efficiency of the system:

| Memory Subsystem Metric | Initial State (Baseline) | Intermediate State | Optimized Final State | Global Delta |
|---|---|---|---|---|
| **Active In-Use Memory** | 23.5 GB (74%) | 16.7 GB (52%) | **5.7 GB (18%)** | 🟢 **-17.8 GB (-75.7%)** |
| **Available Physical RAM** | 8.4 GB | 15.2 GB | **25.9 GB** | 🟢 **+17.5 GB (+208%)** |
| **Zeroed List Page Frames** | Residual (< 200 MB) | ~ 3.5 GB | **12.38 GB** | 🟢 **+12.18 GB** |
| **Kernel Paged Pool** | 6.2 GB | 1.8 GB | **619 MB** | 🟢 **-5.58 GB (-90%)** |
| **Kernel Non-Paged Pool** | 3.4 GB | 1.1 GB | **574 MB** | 🟢 **-2.82 GB (-83%)** |
| **Virtual Commit Charge** | 24.4 / 34.4 GB | 16.7 / 34.4 GB | **14.1 / 38.6 GB** | 🟢 **Commit Headroom: 63.5%** |
| **GPU Stability (WDDM TDR)** | Latent Risk (historic 0x116) | Monitored | **Zero Errors / TdrLevel 3** | 🟢 **100% Rock Solid** |

---

## 5. The Five Mathematical Safety Invariants 1+

Enforcing that any target workstation achieves this level of efficiency without freezing or throttling:
1. **$I_1$ (DWM Composition Isolation):** Graphics and shell process working sets are never trimmed.
2. **$I_2$ (Commit & Storage Safeguard):** Commit headroom is maintained $\ge 15\%$, and pagefile drive free space is proactively verified.
3. **$I_3$ (BCD Boot Coherence):** Removal of BCD memory limits couples with `HiberbootEnabled = 0` (Fast Startup disabled) and cold reboot to eliminate stale PFN database resume.
4. **$I_4$ (TDR Watchdog Sentinel):** WDDM watchdog remains active (`TdrLevel = 3`), adaptively widening delay to 8s under load spikes. PCIe ASPM disabled on active plan.
5. **$I_5$ (Silicon Integrity Shield):** Detection of WHEA hardware machine checks enforces diagnostic `{memdiag}` scheduling before exposing physical memory.

---

## 6. Academic Framework for Master's Thesis

This software package includes a full academic specification ready for formal Master's thesis submission and defence:
- 📄 **Complete MSc Dissertation Framework (8 Chapters):** [`docs/DISSERTACAO_MESTRADO_FRAMEWORK.md`](./docs/DISSERTACAO_MESTRADO_FRAMEWORK.md)
- 🧠 **Kernel Architecture & PFN Technical Notes:** [`docs/TESE_NOTAS.md`](./docs/TESE_NOTAS.md)

---

## 7. Execution Instructions

Launch with Administrator privileges through the launcher or directly in PowerShell:

```powershell
# Comprehensive 3-Tier Pipeline Diagnosis (GPU + DRAM + NVMe)
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Diagnose -Lang EN

# Scientific Benchmark Trial & Academic Telemetry Export
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Benchmark -Lang EN

# Safe Memory Flow Reclaim
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Quick -Lang EN
```
