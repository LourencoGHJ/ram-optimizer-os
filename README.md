# Universal RAM Unlocker & Memory Pipeline Core v5.0
### Investigação e Engenharia de Sistemas de Baixo Nível — CONNECT Labs

<div align="center">

[![Plataforma](https://img.shields.io/badge/Plataforma-Windows%2010%20%7C%2011%20(x64)-0078D6?style=for-the-badge&logo=windows)](https://github.com/LourencoGHJ/win-ram-unlocker)
[![Kernel](https://img.shields.io/badge/Kernel-NT%20PFN%20%7C%20WDDM%203.x-informational?style=for-the-badge)](https://github.com/LourencoGHJ/win-ram-unlocker)
[![Autoria](https://img.shields.io/badge/Desenvolvido%20e%20Avaliado%20por-Gui%20(CONNECT)-success?style=for-the-badge)](https://github.com/LourencoGHJ/win-ram-unlocker)
[![Tese](https://img.shields.io/badge/Disserta%C3%A7%C3%A3o-Mestrado%20Engenharia-purple?style=for-the-badge)](./docs/DISSERTACAO_MESTRADO_FRAMEWORK.md)
[![Eficácia](https://img.shields.io/badge/Resultado%20Empírico-25.9%20GB%20Disponíveis-brightgreen?style=for-the-badge)](./README_PT.md)

<br>

### 🌐 Selecione o seu Idioma / Choose Your Language

<table align="center">
  <tr>
    <td align="center" width="320">
      <a href="./README_PT.md">
        <img src="https://img.shields.io/badge/PORTUGUÊS-🇵🇹_🇧🇷-blue?style=for-the-badge&logo=readme&logoColor=white" alt="Português" width="280"/>
        <br><br>
        <b>👉 Ler Relatório Técnico Completo em Português</b>
        <br>
        <sub>(Fundamentação Teórica, Análise de Screenshots e Resultados)</sub>
      </a>
    </td>
    <td align="center" width="320">
      <a href="./README_EN.md">
        <img src="https://img.shields.io/badge/ENGLISH-🇺🇸_🇬🇧-red?style=for-the-badge&logo=readme&logoColor=white" alt="English" width="280"/>
        <br><br>
        <b>👉 Read Full Technical Engineering Report in English</b>
        <br>
        <sub>(Theory, In-depth Screenshot Telemetry and Metrics)</sub>
      </a>
    </td>
  </tr>
</table>

<br>

🔗 **Repositório Oficial:** [https://github.com/LourencoGHJ/win-ram-unlocker](https://github.com/LourencoGHJ/win-ram-unlocker)

</div>

---

## 🔬 Declaração de Autoria e Avaliação Pessoal / Authorship Statement

> **🇵🇹 Nota do Autor (Gui — CONNECT Labs):**  
> *"Este software e modelo arquitetural foram idealizados, desenvolvidos e rigorosamente avaliados por mim no meu próprio ambiente computacional. Não se trata de uma coleção genérica de scripts nem de truques superficiais de 'limpeza de RAM'. O projeto nasceu da necessidade real de resolver problemas críticos de bloqueio de memória e instabilidade no Windows, tendo sido refinado com fundamentação teórica de sistemas operativos. Os resultados práticos obtidos foram bastantes satisfatórios — comprovados pelo Gestor de Tarefas e pelo Microsoft Sysinternals RAMMap —, transformando uma máquina sob pressão severa num sistema com fluidez absoluta, sem congelamentos e com segurança garantida."*
>
> **🇬🇧 Author's Statement (Gui — CONNECT Labs):**  
> *"This software and architectural model were conceived, engineered, and rigorously evaluated by myself in my personal computing environment. It is not an arbitrary compilation of third-party scripts or superficial 'RAM booster' gimmicks. The project originated from the urgent, practical necessity to overcome critical memory reservation blocks and system instability under Windows. It was refined using advanced operating systems theory. The empirical results achieved were remarkably satisfactory — objectively verified across kernel telemetry counters, the Windows Task Manager, and Microsoft Sysinternals RAMMap —, transforming a heavily congested system into a fluid, freeze-free workstation with certified Safety 1+."*

---

## 📜 A 1ª Versão e o Caminho Evolutivo do Projeto / Project Origins & Roadmap

O percurso do projeto representa uma evolução contínua de engenharia, partindo de um resgate de emergência até à formulação de um modelo científico com garantias matemáticas:

```
[ v1.0: O Resgate Inicial ] ────────▶ [ v2.0 - v3.x: Testes Empíricos ] ────────▶ [ v4.0 - v4.1: Transição Científica ] ────────▶ [ v5.0: Memory Pipeline Core ]
• Resolução de RAM presa no boot        • Primeiros ensaios com BCD e pools       • Eliminação de rotinas placebo          • Modelo Hidráulico Tri-Camada
• Desbloqueio BCD truncatememory         • Validação prática em carga real         • APIs nativas NtSetSystemInformation    • Invariantes de Segurança 1+
• Salvou o PC do criador                • Deteção de riscos de ecrã negro          • Telemetria WHEA, BugCheck e TDR        • 25.9 GB Livres / Tese Mestrado
```

### 1. **v1.0 — A Origem e o Resgate de Emergência (Boot Unlock Origin)**
- **O Problema Real:** O projeto teve génese num bloqueio crítico no computador do próprio autor: o Windows arrancava com gigabytes de memória física inutilizáveis, marcados como "Reservada ao Hardware" devido a parâmetros truncados no BCD (`truncatememory` e `removememory`), frequentemente ativados inadvertidamente no `msconfig`.
- **A Solução v1.0:** Foi concebida uma rotina pioneira focada em reconfigurar e desarmar estas diretivas BCD, devolvendo imediatamente ao kernel o mapa físico completo da máquina. Foi esta versão inicial que salvou o sistema do criador e provou a existência de uma falha grave na gestão convencional.
- **Registo no Repositório:** Acompanha as primeiras revisões no repositório oficial em [`https://github.com/LourencoGHJ/win-ram-unlocker`](https://github.com/LourencoGHJ/win-ram-unlocker).

### 2. **v2.0 & v3.x — A Fase Experimental e os Primeiros Ensaios**
- **O que foi explorado:** Foram adicionadas rotinas de descarte de working sets, manipulação do pagefile e testes de carga em sessões pesadas de multitarefa.
- **As Lições Técnicas:** Embora libertasse memória a curto prazo, a tentativa de esvaziar working sets sem distinção revelou o mecanismo de risco dos sistemas Windows: faltas de página súbitas no `dwm.exe` que podiam culminar em cintilações e timeouts TDR na placa gráfica. Ficou patente que era necessária uma base teórica mais profunda.

### 3. **v4.0 & v4.1 — A Transição Baseada em Evidência (Evidence-Based Hygiene)**
- **Purga de Métodos Nocivos:** Eliminação definitiva de soluções placebo desmentidas pela documentação técnica da Microsoft (remoção de `[System.GC]::Collect()`, `LargeSystemCache`, matar o Explorer e `ClearPageFileAtShutdown`).
- **Adoção de APIs Nativas de Baixo Nível:** Introdução de chamadas diretas a `NtSetSystemInformation` (classe `0x50` / `SystemMemoryListInformation`), espelhando a arquitetura do **Microsoft Sysinternals RAMMap**.
- **Diagnóstico Forense de 14 Dias:** Implementação de telemetria para ler eventos WHEA-Logger (18/19), BugCheck 1001 e Display TDR (4101).

### 4. **v5.0 — Universal Memory Pipeline Core (CONNECT Architecture para Dissertação de Mestrado)**
- **O Salto Arquitetural:** Formalização do **Modelo Hidráulico Tri-Camada** (GPU VRAM ↔ Host DRAM ↔ Armazenamento NVMe Commit).
- **As Cinco Invariantes de Segurança 1+:** Prova matemática de que a intervenção nunca causa congelamentos nem ecrãs pretos.
- **Resultados Empíricos Comprovados:** Redução da memória em uso de **23.5 GB para 5.7 GB**, expansão de memória disponível para **25.9 GB**, **12.38 GB** na lista *Zeroed* do RAMMap e documentação completa para Tese de Mestrado.

---

## 🌊 O Modelo do Pipeline Hidráulico Tri-Camada ("A Circulação da Água")

```
   [ TIER 1: GPU VRAM & VidMm ]   <--- Nascente / Source (300 - 1000 GB/s)
                 ▲ ▼ PCIe Link (ASPM Off, TDR Level 3 Recover)
   [ TIER 2: HOST DRAM & PFN ]    <--- Caudal Principal / Main Flow (40 - 100 GB/s)
                 ▲ ▼ Storage Queue & DirectStorage
   [ TIER 3: NVMe STORAGE & COMMIT ] <-- Bacia de Retenção / Retention Basin (3 - 7 GB/s)
```

A metáfora condutora do projeto — *a água de um poço que não avança por um bloqueio, onde o trabalho é dar o caminho seguro para que a água circule livremente entre a RAM, o SSD e a gráfica como um núcleo de base de dados com segurança 1+* — foi traduzida num motor transacional de páginas físicas e virtuais:
- **Tier 1 (GPU VRAM / WDDM VidMm):** Prevenção de *paging stalls* no barramento PCIe. Blindagem do Desktop Window Manager ([`dwm.exe`](file:///c:/Windows/System32/dwm.exe)) para evitar o disparo do watchdog TDR e do ecrã azul `VIDEO_TDR_FAILURE` (0x116).
- **Tier 2 (Host DRAM / PFN Database):** Reorganização cirúrgica das listas *Standby* de baixa prioridade via `NtSetSystemInformation` (0x50), controlo da cache de ficheiros (>30%) e saneamento dos pools do kernel.
- **Tier 3 (Armazenamento NVMe & Commit):** Salvaguarda da margem de commit ($CommitHeadroom \ge 15\%$), verificação de espaço na unidade do pagefile e ativação de crash dumps automáticos (`CrashDumpEnabled = 7`).

---

## 📸 Demonstração Empírica dos Resultados / Empirical Showcase

Abaixo apresenta-se a progressão real medida na minha máquina com **32.0 GB de RAM**, **NVMe Samsung 970 EVO Plus** e GPU **RTX 2060**:

| Fase | Screenshot | Métrica Principal no Gestor de Tarefas | Estado da PFN Database / Kernel |
|---|---|---|---|
| **1. Baseline (Saturação)** | [Figura 1](./screenshots/1.png) | **23.5 GB em uso (74%)**, 8.4 GB disponíveis | Pools do kernel saturados (6.2 GB Paged / 3.4 GB Non-Paged) |
| **2. Estabilização** | [Figura 2](./screenshots/2.png) | **21.0 GB em uso (66%)**, 10.7 GB disponíveis | Nivelamento da curva de consumo e início do alívio de commit |
| **3. Queda em Tempo Real** | [Figura 3](./screenshots/3.png) | **16.7 GB em uso (52%)**, 15.2 GB disponíveis | Auditoria cirúrgica via PowerShell; queda imediata de mais de 4.5 GB |
| **4. Descongestionamento** | [Figura 4](./screenshots/4.png) | **10.5 GB em uso (34%)**, **21.2 GB disponíveis** | Pools saneados: Paged cai para 651 MB e Non-Paged para 553 MB |
| **5. Validação Forense** | [Figura 5](./screenshots/5.png) | **5.7 GB em uso (18%)**, **25.9 GB disponíveis** | **RAMMap:** 12.38 GB de páginas físicas limpas na **Zeroed List**! |

<div align="center">

### Comparativo Visual de Extremos: De 23.5 GB em Uso para 5.7 GB em Uso

<table align="center">
  <tr>
    <td align="center" width="50%">
      <b>ANTES (Figura 1 — Saturação a 74%)</b><br><br>
      <img src="./screenshots/1.png" alt="Antes" width="480"/>
      <br>
      <sub>23.5 GB em uso · Apenas 8.4 GB disponíveis · Pools inflamados</sub>
    </td>
    <td align="center" width="50%">
      <b>DEPOIS (Figura 5 — Sysinternals RAMMap a 18%)</b><br><br>
      <img src="./screenshots/5.png" alt="Depois" width="480"/>
      <br>
      <sub><b>5.7 GB em uso · 25.9 GB disponíveis · 12.38 GB Zeroed List</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 📊 Tabela de Eficácia Empírica

| Métrica do Sistema | Antes da Otimização | Após Aplicação do Motor | Ganho Líquido / Variação |
|---|---|---|---|
| **Memória Ativa em Uso** | 23.5 GB (74%) | **5.7 GB (18%)** | 🟢 **-17.8 GB (-75.7%)** |
| **Memória Física Disponível** | 8.4 GB | **25.9 GB** | 🟢 **+17.5 GB (+208%)** |
| **Páginas Físicas na Zeroed List** | Residual (< 200 MB) | **12.38 GB (12.387.040 KB)** | 🟢 **+12.18 GB Limpos** |
| **Kernel Paged Pool** | 6.2 GB | **619 MB** | 🟢 **-5.58 GB (-90%)** |
| **Kernel Non-Paged Pool** | 3.4 GB | **574 MB** | 🟢 **-2.82 GB (-83%)** |
| **Estabilidade Gráfica e TDR** | Histórico 0x116 detetado | **Zero Falhas / TdrLevel 3** | 🟢 **100% Estável** |

---

## 🛡️ As Cinco Invariantes de Segurança 1+
1. **$I_1$ (Isolamento da Composição Gráfica):** Zero trim em working sets de `dwm.exe` e `csrss.exe` — elimina a causa de ecrãs pretos.
2. **$I_2$ (Garantia de Commit Headroom):** Margem de compromisso mantida $\ge 15\%$ e monitorização do espaço livre no disco do sistema.
3. **$I_3$ (Coerência de Boot BCD):** Limpeza de limitadores de boot com Fast Startup desligado e cold restart (`shutdown /r`).
4. **$I_4$ (Árbitro TDR):** Manutenção estrita de `TdrLevel = 3` (Recover), com atraso de 8s sob tempestades. ASPM PCIe desativado.
5. **$I_5$ (Blindagem de Silício):** Bloqueio de desbloqueios cegos sob eventos WHEA e agendamento de `{memdiag}`.

---

## 🎓 Documentação para Dissertação de Mestrado
- 📄 **Quadro Científico e Metodológico Completo (8 Capítulos):** [`docs/DISSERTACAO_MESTRADO_FRAMEWORK.md`](./docs/DISSERTACAO_MESTRADO_FRAMEWORK.md)
- 🧠 **Notas Técnicas de Engenharia e Mapeamento PFN:** [`docs/TESE_NOTAS.md`](./docs/TESE_NOTAS.md)
- 🇵🇹 **Relatório Técnico Aprofundado (Português):** [`README_PT.md`](./README_PT.md)
- 🇬🇧 **In-Depth Technical Engineering Report (English):** [`README_EN.md`](./README_EN.md)

---

<p align="center">
  Desenvolvido e avaliado por <b>Gui</b> sob a iniciativa <b>CONNECT Labs</b>.<br>
  <sub>Repositório Oficial: <a href="https://github.com/LourencoGHJ/win-ram-unlocker">https://github.com/LourencoGHJ/win-ram-unlocker</a></sub>
</p>
