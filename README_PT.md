# Universal RAM Unlocker & Memory Pipeline Core v5.0
### Investigação e Engenharia de Sistemas de Baixo Nível — CONNECT Labs

[⬅️ Voltar ao Seletor de Idioma](./README.md) · [🇬🇧 Read in English](./README_EN.md)

![Plataforma](https://img.shields.io/badge/Plataforma-Windows%2010%20%7C%2011%20(x64)-0078D6?style=for-the-badge&logo=windows)
![Arquitetura](https://img.shields.io/badge/Kernel-NT%20PFN%20%7C%20WDDM%203.x-informational?style=for-the-badge)
![Autoria e Avaliação](https://img.shields.io/badge/Desenvolvido%20e%20Avaliado%20por-Gui%20(CONNECT)-success?style=for-the-badge)
![Nível Académico](https://img.shields.io/badge/Tese%20de%20Mestrado-Engenharia%20Informática-blueviolet?style=for-the-badge)
![Resultados](https://img.shields.io/badge/Eficácia%20Empírica-25.9%20GB%20Disponíveis-brightgreen?style=for-the-badge)

---

## 🔬 Declaração de Autoria e Avaliação Pessoal

> **Nota do Autor (Gui — CONNECT Labs):**  
> *"Este software e modelo arquitetural foram idealizados, desenvolvidos e rigorosamente avaliados por mim no meu próprio ambiente computacional. Não se trata de uma coleção genérica de scripts de terceiros nem de truques superficiais de 'limpeza de RAM'. O projeto nasceu da necessidade real de resolver problemas críticos de bloqueio de memória e instabilidade no Windows, tendo sido refinado com fundamentação teórica avançada de sistemas operativos. Os resultados práticos obtidos foram bastantes satisfatórios — comprovados por métricas de telemetria do kernel, pelo Gestor de Tarefas e pelo Microsoft Sysinternals RAMMap —, transformando uma máquina com pressão severa de memória num sistema com fluidez absoluta, sem congelamentos e com segurança garantida."*

---

## 1. Fundamentação Teórica: Por Que a Memória do Windows "Estrangula"?

Para além de mitos de fóruns e soluções cosméticas, a gestão de memória física no kernel Windows NT assenta em estruturas de dados precisas que explicam o comportamento dos sistemas sob carga:

### 1.1 A Base de Dados PFN (Page Frame Number)
Toda a moldura de memória física de 4 KB ou 2 MB é rastreada na **PFN Database** do kernel (`ntoskrnl.exe`) através de estados formais:
- **Active / Valid:** Páginas pertencentes aos Working Sets de processos ou do kernel.
- **Standby (Prioridades 0 a 7):** Páginas que retêm dados de ficheiros ou código não modificado, prontas a ser reutilizadas instantaneamente caso o processo as volte a pedir (falta suave / *soft fault*) ou cedidas para novas alocações (*Available*).
- **Modified:** Páginas que foram escritas em memória e aguardam que o *Modified Page Writer* as despeje para o disco ou pagefile.
- **Zeroed & Free:** Páginas limpas e inicializadas prontas para concessão imediata sem latência de preenchimento.

### 1.2 O Erro Fatal dos "RAM Cleaners" Convencionais
Os utilitários comerciais comuns limitam-se a iterar processos e chamar `EmptyWorkingSet()` em massa. O modelo formal de **Peter J. Denning (CACM 1968, *The Working Set Model for Program Behavior*)** demonstra matematicamente que retirar páginas ativas do conjunto de trabalho de um processo força a CPU a interromper a execução para resolver avalanches de faltas de página duras (*hard page faults*).

No subsistema gráfico, esvaziar os working sets do *Desktop Window Manager* ([`dwm.exe`](file:///c:/Windows/System32/dwm.exe)) ou do runtime gráfico faz com que o **Video Memory Manager (VidMm)** do WDDM sofra bloqueios de paginação no barramento PCIe. Quando o escalonador gráfico excede o limite de 2 segundos do temporizador `TdrDelay`, o kernel dispara **TDR (Timeout Detection and Recovery, Evento 4101)** ou o clássico ecrã azul:
$$\mathbf{VIDEO\_TDR\_FAILURE\ (0x00000116)}$$
O motor v5.0 elimina esta falha: **os Working Sets nunca são tocados**; apenas as listas Standby de baixa prioridade são reorganizadas via chamadas nativas a `NtSetSystemInformation` (classe 80 / 0x50), exatamente como implementado na ferramenta de referência da Microsoft, o **RAMMap**.

---

## 2. A 1ª Versão e o Percurso Evolutivo do Projeto (Roadmap Histórico)

O projeto percorreu um caminho evolutivo consistente de engenharia de sistemas, partindo de um resgate prático até à formulação científica atual:

```
[ v1.0: O Resgate Inicial ] ────────▶ [ v2.0 - v3.x: Testes Empíricos ] ────────▶ [ v4.0 - v4.1: Transição Científica ] ────────▶ [ v5.0: Memory Pipeline Core ]
• Resolução de RAM presa no boot        • Primeiros ensaios com BCD e pools       • Eliminação de rotinas placebo          • Modelo Hidráulico Tri-Camada
• Desbloqueio BCD truncatememory         • Validação prática em carga real         • APIs nativas NtSetSystemInformation    • Invariantes de Segurança 1+
• Salvou o PC do criador                • Deteção de riscos de ecrã negro          • Telemetria WHEA, BugCheck e TDR        • 25.9 GB Livres / Tese Mestrado
```

- **v1.0 — A Origem & O Resgate de Emergência:** O projeto nasceu para resolver um bloqueio severo no PC do criador: gigabytes de RAM física estavam presos como "Reservada ao Hardware" devido a limites de boot no BCD (`truncatememory` e `removememory`), ativados inadvertidamente no `msconfig`. A versão inicial focou-se na cirurgia direta de arranque, desarmou essas diretivas e recuperou a memória total utilizável da máquina.
- **v2.0 - v3.x — A Fase Experimental:** Testes empíricos de libertação de working sets e ajustes no pagefile. Demonstrou a viabilidade da ideia em jogos e multitarefa pesada, mas evidenciou o risco de instabilidade gráfica caso os working sets de processos do sistema fossem desestabilizados.
- **v4.0 - v4.1 — A Transição Baseada em Evidência:** Eliminação definitiva de métodos "placebo" contrários à documentação técnica da Microsoft (remoção de `[System.GC]::Collect()`, `LargeSystemCache`, matar Explorer e `ClearPageFileAtShutdown`), transição para chamadas nativas de kernel `NtSetSystemInformation` (0x50 / RAMMap) e diagnóstico de telemetria de 14 dias (WHEA/TDR/BugCheck).
- **v5.0 — Universal Memory Pipeline Core (Atual):** Formulação matemática do **Modelo Hidráulico Tri-Camada** (GPU VRAM ↔ Host DRAM ↔ Armazenamento NVMe), comprovação formal das **Cinco Invariantes de Segurança 1+**, telemetria avançada, validação forense no RAMMap (**25.9 GB de RAM disponível**) e especificação completa para Dissertação de Mestrado.

> **Repositório Oficial:** [https://github.com/LourencoGHJ/win-ram-unlocker](https://github.com/LourencoGHJ/win-ram-unlocker)

---

## 3. O Modelo do Pipeline Hidráulico Tri-Camada ("A Circulação da Água")

```
   [ TIER 1: GPU VRAM & VidMm ]   <--- Nascente (Largura de Banda: 300 - 1000 GB/s)
                 ▲ ▼ PCIe Link (ASPM Off, TDR Level 3 Recover)
   [ TIER 2: HOST DRAM & PFN ]    <--- Caudal Principal (DDR4/DDR5: 40 - 100 GB/s)
                 ▲ ▼ Storage Queue & DirectStorage
   [ TIER 3: NVMe STORAGE & COMMIT ] <-- Bacia de Retenção (NVMe SSD: 3 - 7 GB/s)
```

A metáfora condutora do projeto — *a água de um poço que se encontra represada por estrangulamentos e que precisa de um caminho seguro para circular fluidamente entre a RAM, o SSD e a GPU como uma base de dados com segurança 1+* — reflete-se na harmonia entre:
1. **GPU VRAM (Nascente):** Gestão equilibrada entre VRAM local dedicada e abertura partilhada em memória de sistema (*Shared System Memory*).
2. **Host DRAM (Caudal):** Equilíbrio de molduras de página sem acumulação patológica na cache de ficheiros (>30%) e com monitorização contínua de pools de memória (Paged e Non-Paged Pool) para prevenção de fugas de drivers.
3. **NVMe Storage & Commit (Bacia de Retenção):** O teto de compromisso virtual ($CommitLimit = RAM + Pagefile$). Garantia de que a margem de commit permaneça sempre acima de 15% e verificação do espaço em disco no volume do sistema para assegurar a persistência de alocações e gravação de crash dumps (`CrashDumpEnabled = 7`).

---

## 3. Demonstração Empírica e Resultados Experimentais

A eficácia do sistema foi comprovada na minha estação de trabalho com **32.0 GB de RAM DDR4 (3200 MT/s)**, unidade **NVMe Samsung SSD 970 EVO Plus** e GPU **NVIDIA GeForce RTX 2060**. Segue-se a sequência experimental documentada:

### Fase 1: Estado Inicial de Saturação e Pressão de Memória (Baseline)
O sistema encontrava-se com **23.5 GB em uso (74%)**, restando apenas **8.4 GB disponíveis**. A cache acumulada ascendia a **8.7 GB** e os blocos de memória do kernel estavam sobrecarregados (**6.2 GB paginado** e **3.4 GB não paginado**).

<p align="center">
  <img src="./screenshots/1.png" alt="Estado Inicial de Pressão de Memória" width="850"/>
  <br>
  <i>Figura 1: Estado inicial no Gestor de Tarefas — 23.5 GB em uso (74%), 8.4 GB disponíveis e pools do kernel saturados.</i>
</p>

---

### Fase 2: Início da Desobstrução e Estabilização de Carga
Ao aplicar os primeiros passos do protocolo de higiene e auditoria de alocações, o consumo reduziu-se para **21.0 GB em uso (66%)**, elevando a memória disponível para **10.7 GB** com curva estável.

<p align="center">
  <img src="./screenshots/2.png" alt="Estabilização Inicial" width="850"/>
  <br>
  <i>Figura 2: Estabilização da curva de utilização com início de libertação do commit charge.</i>
</p>

---

### Fase 3: Auditoria Ativa de Working Sets via Consola e Queda em Tempo Real
Utilizando a consola de administração PowerShell para auditar e isolar processos com alocações hipertrofiadas sem afetar a integridade da composição gráfica (DWM), verificou-se uma **queda abrupta e imediata de 21.2 GB para 16.7 GB (52%)**, com a memória disponível a subir para **15.2 GB** em tempo real e sem qualquer instabilidade ou piscar de ecrã.

<p align="center">
  <img src="./screenshots/3.png" alt="Auditoria de Working Sets e Queda em Tempo Real" width="950"/>
  <br>
  <i>Figura 3: Telemetria em tempo real — queda abrupta de 66% para 52% (16.7 GB em uso, 15.2 GB disponíveis).</i>
</p>

---

### Fase 4: Descongestionamento Pleno e Alívio Drástico dos Pools do Kernel
Com o fluxo desobstruído e os parâmetros de estabilidade consolidados, a memória em uso desceu para **10.5 GB (apenas 34%)**, colocando **21.2 GB de memória disponível**.  
**Destaque Técnico Fundamental:** O bloco paginado despencou de **6.2 GB para 651 MB**, e o bloco não paginado reduziu-se de **3.4 GB para 553 MB**, restaurando as estruturas de dados do kernel para o estado de um sistema acabado de arrancar.

<p align="center">
  <img src="./screenshots/4.png" alt="Descongestionamento Profundo e Estabilidade" width="850"/>
  <br>
  <i>Figura 4: Descongestionamento consolidado — apenas 34% em uso, 21.2 GB disponíveis e pools do kernel totalmente saneados.</i>
</p>

---

### Fase 5: Validação Forense com Microsoft Sysinternals RAMMap
A prova cabal e científica dos resultados foi confirmada através do **RAMMap v1.6+**:
- **Memória em Uso no Gestor de Tarefas:** Caiu para incríveis **5.7 GB** (num sistema de 32 GB), com **25.9 GB de Memória Disponível (81% de RAM livre)**!
- **Auditoria da PFN Database no RAMMap:** A lista **Zeroed** registou **12.38 GB de páginas físicas totalmente limpas** (Zeroed List: 12.387.040 KB), e a lista **Standby** reorganizou-se perfeitamente em 9.67 GB de cache útil e recuperável.
- **Estabilidade:** Zero erros de hardware WHEA, zero eventos de timeout TDR, zero cintilações e tempo de resposta instantâneo.

<p align="center">
  <img src="./screenshots/5.png" alt="Validação com Microsoft Sysinternals RAMMap" width="950"/>
  <br>
  <i>Figura 5: Validação forense com Sysinternals RAMMap — 5.7 GB em uso, 25.9 GB disponíveis e 12.38 GB de páginas na Zeroed List.</i>
</p>

---

## 4. Tabela Comparativa de Resultados Quantitativos

Os resultados medidos pessoalmente durante o ensaio experimental evidenciam o impacto da intervenção:

| Métrica do Subsistema de Memória | Estado Inicial (Baseline) | Fase Intermédia | Estado Final Otimizado | Variação Global |
|---|---|---|---|---|
| **Memória em Uso Ativo** | 23.5 GB (74%) | 16.7 GB (52%) | **5.7 GB (18%)** | 🟢 **-17.8 GB (-75.7%)** |
| **Memória Física Disponível** | 8.4 GB | 15.2 GB | **25.9 GB** | 🟢 **+17.5 GB (+208%)** |
| **Páginas Limpas na Zeroed List** | Residual (< 200 MB) | ~ 3.5 GB | **12.38 GB** | 🟢 **+12.18 GB** |
| **Pool Paginado do Kernel** | 6.2 GB | 1.8 GB | **619 MB** | 🟢 **-5.58 GB (-90%)** |
| **Pool Não Paginado (Driver Locked)** | 3.4 GB | 1.1 GB | **574 MB** | 🟢 **-2.82 GB (-83%)** |
| **Carga de Commit Virtual** | 24.4 / 34.4 GB | 16.7 / 34.4 GB | **14.1 / 38.6 GB** | 🟢 **Commit Headroom: 63.5%** |
| **Resiliência Gráfica (WDDM TDR)** | Risco latente (0x116 histórico) | Monitorizado | **Zero Erros / TdrLevel 3** | 🟢 **100% Estável** |

---

## 5. As Cinco Invariantes de Segurança 1+ Implementadas

Para assegurar que qualquer computador atinja este nível sem travar nem limitar:
1. **$I_1$ (Isolamento da Composição DWM):** Working sets de processos gráficos e de sistema operacional não são podados.
2. **$I_2$ (Salvaguarda de Commit e Armazenamento NVMe):** Margem de compromisso mantida $\ge 15\%$ e espaço livre no disco do sistema monitorizado.
3. **$I_3$ (Coerência de Boot BCD):** Remoção de limitadores BCD associada a `HiberbootEnabled = 0` (Fast Startup desligado) e arranque a frio para evitar retoma sobre PFN desatualizado.
4. **$I_4$ (Árbitro TDR):** Manutenção do watchdog WDDM ativo (`TdrLevel = 3`), expandindo adaptativamente o atraso para 8s sob tempestades de carga. ASPM PCIe desativado no perfil de energia ativo.
5. **$I_5$ (Blindagem de Silício):** Deteção de eventos WHEA de hardware com agendamento do `{memdiag}` antes de qualquer exposição de memória.

---

## 6. Documentação Científica para a Dissertação de Mestrado

Este projeto integra uma especificação formal completa para apresentação e defesa de mestrado:
- 📄 **Candidatura e Quadro Científico da Dissertação (8 Capítulos):** [`docs/DISSERTACAO_MESTRADO_FRAMEWORK.md`](./docs/DISSERTACAO_MESTRADO_FRAMEWORK.md)
- 🧠 **Notas Técnicas de Mapeamento do Kernel e PFN:** [`docs/TESE_NOTAS.md`](./docs/TESE_NOTAS.md)

---

## 7. Instruções de Execução

Executa com privilégios de Administrador através do ficheiro bat ou diretamente via PowerShell:

```powershell
# Diagnóstico completo das 3 camadas (GPU + DRAM + NVMe)
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Diagnose -Lang PT

# Executar benchmark científico e emitir telemetria para a tese
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Benchmark -Lang PT

# Reclaim cirúrgico do fluxo de memória
powershell -NoProfile -ExecutionPolicy Bypass -File .\ConnectRamCore.ps1 -Action Quick -Lang PT
```
