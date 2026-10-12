# Notas de fundamentação (nível mestrado) — estabilidade após limitação de RAM no Windows v5.0

Documento de apoio à dissertação / relatório técnico do *Universal RAM Unlocker & Memory Pipeline Core* v5.0 (CONNECT Labs).  
Complementa a especificação integral: [`docs/DISSERTACAO_MESTRADO_FRAMEWORK.md`](./DISSERTACAO_MESTRADO_FRAMEWORK.md).

**Hipótese Central de Trabalho:**  
Crashes, ecrãs negros e congelamentos após "limitar / desbloquear RAM" não constituem um problema de cache suja tratável por utilitários genéricos de limpeza, mas resultam de:
1. Ruptura de coerência no mapa físico (PFN database) decorrente de limites BCD ou retoma hibernada via *Fast Startup*;
2. Exposição inadvertida de DRAM fisicamente degradada com *hard errors* (Schroeder et al., ACM SIGMETRICS);
3. Estrangulamento no pipeline hidráulico tri-camada (Host DRAM ↔ Armazenamento NVMe Commit ↔ GPU VRAM/VidMm), desencadeando *page fault storms* e violação da janela de tolerância do watchdog WDDM TDR (códigos 0x116 e 0x117).

---

## 1. O Modelo do Pipeline Hidráulico Tri-Camada

A metáfora do sistema — *a água de um poço que se encontra obstruída, onde o propósito da engenharia é abrir canais seguros para que o fluido circule livremente entre DRAM, Armazenamento Secundário e a Placa Gráfica como uma base de dados transacional com segurança 1+* — corresponde à integração de três domínios do subsistema de memória:

### 1.1 Nascente: Camada Gráfica e GPU VRAM (WDDM 3.x / VidMm)
- **VRAM Local (GDDR6/GDDR6X):** Memória de largura de banda extrema (centenas de GB/s), gerida pelo *Video Memory Manager* (`VidMm`) do kernel DirectX (`dxgkrnl.sys`).
- **Abertura de Sistema (Non-Local Shared Memory):** Região de DRAM física do host mapeada para buffers gráficos via barramento PCIe.
- **Risco de Estrangulamento:** Se os *working sets* forem forçadamente esvaziados (e.g. trim de `dwm.exe`), o subsistema gráfico entra em contenção de alocação de superfícies. Quando o escalonador do GPU não obtém as páginas no prazo definido por `TdrDelay` (por omissão 2s), dispara o evento **Display 4101** e `DxgkDdiResetFromTimeout`, originando o clássico ecrã negro.

### 1.2 Caudal Principal: Host Physical DRAM & PFN Database
- O kernel do Windows decompõe cada moldura de página de 4KB/2MB num registo da **PFN Database** com estados mutuamente exclusivos:
  - *Active / Valid:* Páginas ativas no conjunto de trabalho de algum processo ou do kernel.
  - *Standby (prioridades 0 a 7):* Cache de páginas limpas mantidas em memória para reutilização instantânea (contam como memória disponível!).
  - *Modified:* Páginas com dados alterados aguardando escrita pelo *Modified Page Writer*.
  - *Free / Zero:* Páginas não alocadas e prontas para nova concessão.
- **Intervenção Segura v5.0:** O reclaim cirúrgico atua exclusivamente via `NtSetSystemInformation` classe `0x50` nos comandos 4 (*Purge Standby*) e 5 (*Purge Low Priority Standby*). Os working sets permanecem estritamente intactos, respeitando o modelo de **Peter Denning (1968)**.
- **Deteção de Fugas de Kernel:** Monitorização em tempo real de `PoolPagedBytes` e `PoolNonpagedBytes` para isolar drivers de terceiros com fugas de pool que drenam a RAM física.

### 1.3 Bacia de Retenção: Armazenamento NVMe & Sistema de Commit
- **System Commit Limit:** $CommitLimit = RAM_{visivel} + \sum Pagefiles$.
- O compromisso virtual total não pode ultrapassar o limite, sob pena de recusa de alocações (`STATUS_COMMITMENT_LIMIT_EXCEEDED` 0xC000012D).
- **Alerta Crítico de Espaço no Disco de Paginação:** Em unidades NVMe de sistema com espaço residual escasso (e.g. menos de 10 GB livres), a expansão dinâmica do `pagefile.sys` pode falhar, impedindo alocações e a gravação de *crash dumps* (`MEMORY.DMP`).
- **TRIM e I/O Stack:** O estado de TRIM (`fsutil behavior query DisableDeleteNotify`) e a compressão em memória (*Store Manager*) são validados para evitar latência excessiva de escrita/leitura.

---

## 2. As Cinco Invariantes de Segurança 1+ (Safety Invariants)

Toda a intervenção do motor v5.0 obedece a cinco teoremas de segurança não-negociáveis:

1. **Invariante $I_1$ (Isolamento da Composição Gráfica):** Proibição estrita de invocar `EmptyWorkingSets` (comando 2) ou intervenções que forcem desalocação do `dwm.exe` ou processos do subsistema Win32k/CSRSS.
2. **Invariante $I_2$ (Salvaguarda de Commit e Armazenamento):** Garantia de que a margem de commit ($CommitHeadroom$) permaneça superior a 15% e verificação de espaço em disco no volume do pagefile.
3. **Invariante $I_3$ (Coerência de Arranque a Frio):** Após remoção de `truncatememory`/`removememory` no BCD, imposição de `HiberbootEnabled = 0` (Fast Startup OFF) e solicitação de reinício a frio (`shutdown /r`), prevenindo retoma de PFNs obsoletos.
4. **Invariante $I_4$ (Árbitro TDR e Proteção de Watchdog):** Manutenção estrita de `TdrLevel = 3` (Recover). Elevação adaptativa de `TdrDelay` para 8s exclusivamente na presença comprovada de tempestades de TDR ($\ge 3$ eventos em 14 dias), sem nunca desativar a proteção. Sincronização de ASPM PCIe em estado estável.
5. **Invariante $I_5$ (Blindagem de Silício WHEA):** Na presença de erros de hardware WHEA (18/19), suspensão de desbloqueios não-verificados e agendamento proativo do *Windows Memory Diagnostic* (`{memdiag}`) no arranque.

---

## 3. Normas, Certificações e Referências Verificadas

1. **Schroeder, B., Pinheiro, E., & Weber, W.-D. (2009).** DRAM errors in the wild: a large-scale field study. *ACM SIGMETRICS*.
2. **Denning, P. J. (1968).** The working set model for program behavior. *Communications of the ACM*, 11(5).
3. **Microsoft Windows Hardware Compatibility Program (WHCP / WHQL).** Requisitos de integridade de memória e suporte de crash dumps automáticos.
4. **Microsoft WDDM 3.x Architecture Documentation.** Video Memory Management, Residency Budgets e arquitetura de TDR.
5. **JEDEC Solid State Technology Association.** JESD79-4 / JESD79-5 DDR4/DDR5 Memory Standards.
6. **Russinovich, M., Solomon, D., & Ionescu, A.** *Windows Internals* — PFN database, Memory Management subsystem, Store Manager e Commit limits.
7. **Geoff Chappell.** *NtSetSystemInformation* / `SystemMemoryListInformation` (0x50), comandos de controlo de listas.
8. **ISO/IEC 25010.** Modelo de Qualidade de Produto de Software: Fiabilidade, Desempenho e Segurança Funcional.

---

## 4. Sistema de Certificação e Auditoria v5.0

O motor gera um índice determinístico de conformidade (**Pipeline Health & Safety Score**):
- **Classificação A+:** Todos os parâmetros de BCD, PFN, TDR, Commit, Pagefile e Silício conformes com as especificações Microsoft WHQL/WDDM.
- **Classificação A / B:** Desvios menores (e.g. Fast Startup ativo ou cache de ficheiros ligeiramente elevado).
- **Classificação C / F (Alerta Crítico):** Presença de erros WHEA de hardware, TDR desativado (`TdrLevel=0`) ou commit headroom saturado.

Artefactos gerados:
- `%TEMP%\connect-ram-health-report.txt` (Sumário técnico em texto puro)
- `%TEMP%\connect-ram-telemetry.json` (Dataset completo para análise em R/Python/SPSS na dissertação)
- `%TEMP%\connect-ram-thesis-report.html` (Relatório visual certificado com diagramas de fluxo de memória)
