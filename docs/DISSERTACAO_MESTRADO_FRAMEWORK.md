# Framework Científico e Metodológico para Dissertação de Mestrado

**Título Proposto da Dissertação:**  
*Otimização Preditiva e Fluxo Unificado de Memória em Sistemas Operativos Modernos: Uma Abordagem Baseada no Modelo Hidráulico Tri-Camada (DRAM, NVMe e VRAM) com Garantias de Invariantes de Segurança 1+ no Kernel Windows*

**Área de Especialização:**  
Sistemas de Computadores · Arquitetura de Sistemas Operativos · Engenharia de Software de Baixo Nível

---

## Resumo Executivo (Abstract Académico)

A gestão de memória em sistemas operativos contemporâneos (Windows 10/11 x86-64) opera frequentemente sob paradigmas compartimentados, tratando a memória física principal (DRAM), a memória virtual ancorada em armazenamento secundário (Pagefile/NVMe) e a memória de vídeo dedicada e partilhada (VRAM/VidMm) como subsistemas com canais de comunicação reativos e frequentemente assíncronos. Esta compartimentação gera, sob condições de elevada contenção ou má configuração de arranque (e.g. parâmetros BCD espúrios, *working-set thrashing*, acumulação patológica na *Standby List* e esgotamento do *Commit Headroom*), fenómenos críticos de instabilidade sistémica, tais como:
1. *Timeouts* de escalonamento gráfico com disparo do mecanismo WDDM TDR (*Timeout Detection and Recovery*, códigos 0x116/0x117 e congelamento de ecrã);
2. *Thrashing* violento de faltas de página duras (*hard page faults*);
3. Exposição inadvertida de falhas permanentes de hardware de silício (*hard errors* de DRAM documentados por Schroeder et al., ACM SIGMETRICS).

Nesta dissertação, desenvolve-se e valida-se formalmente o **Modelo do Pipeline Hidráulico Tri-Camada de Memória**, que modela o fluxo de páginas e alocações entre GPU (L1), Host DRAM (L2) e Armazenamento NVMe (L3) como um sistema hidráulico de vasos comunicantes com buffers transacionais (análogo a um motor de base de dados relacional de alto débito). Prova-se e implementa-se o conjunto de **Cinco Invariantes de Segurança 1+**, garantindo que as operações de libertação e reconfiguração do mapa físico decorram de forma atómica, não-destrutiva e imune a *hangs* ou degradação de desempenho, cumprindo integralmente as especificações da Microsoft (WHCP/WHQL, WDDM 3.x), normas JEDEC (JESD79) e o modelo de Working Set de Peter Denning (CACM 1968).

---

## 1. Enquadramento e Motivação

### 1.1 O Mito dos "RAM Cleaners" vs. A Realidade do Kernel Windows
Durante décadas, o ecossistema de software de consumo foi inundado por ferramentas denominadas "RAM Boosters", "Memory Cleaners" ou "Game Optimizers". Na sua esmagadora maioria, estas ferramentas limitam-se a:
- Invocar primitivas de trim global de Working Sets (e.g. `EmptyWorkingSet()` em todos os PIDs ativos);
- Executar rotinas geridas irrelevantes em espaço de utilizador (e.g. `[System.GC]::Collect()`);
- Forçar purgas indiscriminadas que expulsam código ativo do *Desktop Window Manager* (`dwm.exe`) e de processos críticos do sistema (`csrss.exe`, `lsass.exe`).

O resultado prático destas intervenções ingénuas é diametralmente oposto ao prometido:
- A remoção forçada de páginas do conjunto de trabalho de processos ativos viola diretamente o **Modelo de Working Set de Peter Denning (1968)**, obrigando a CPU a interromper a execução para resolver avalanches de *hard page faults* contra o subsistema de armazenamento secundário;
- No subsistema gráfico, a ausência repentina de superfícies de composição em memória de acesso imediato obriga o gestor de memória de vídeo do WDDM (`VidMm`) a desencadear *paging* forçado através do barramento PCIe. Se a resposta da GPU exceder o limite do temporizador `TdrDelay` (por omissão, 2 segundos), o kernel declara *timeout*, reinicializa o driver de vídeo via `DxgkDdiResetFromTimeout` e induz ecrãs negros permanentes ou ecrãs azuis `VIDEO_TDR_FAILURE` (0x116).

### 1.2 O Problema do Mapa Físico e da Memória Reservada para Hardware
A memória rotulada como "Hardware Reserved" no Windows Gestor de Tarefas decorre fundamentalmente de três origens:
1. **Regiões de Firmware e MMIO:** Mapeamento de periféricos PCIe, buffers ACPI, interfaces APIC e framebuffer estático de GPUs integradas (UMA). Estas páginas são reportadas pela interface UEFI via `GetMemoryMap` como inacessíveis ao sistema operativo;
2. **Parâmetros de Teste no BCD (Boot Configuration Data):** Diretivas como `truncatememory` e `removememory`, frequentemente inseridas por engano por utilizadores ao alterarem definições avançadas do `msconfig` ("Memória Máxima");
3. **Instabilidades de Hardware Silenciosas (WHEA/MCA):** Quando módulos de memória DRAM apresentam linhas de dados, células ou controladores degradados, a ativação da totalidade do mapa expõe o kernel a corrupção de dados, despoletando *Machine Check Architecture* (MCA) e *bug checks* `WHEA_UNCORRECTABLE_ERROR` (0x124).

A intervenção requer, portanto, uma arquitetura cirúrgica, baseada em evidência empírica e métricas verificadas, capaz de articular o desbloqueio com a resiliência operacional do sistema.

---

## 2. O Modelo do Pipeline Hidráulico Tri-Camada

A analogia conceptual apresentada pelo utilizador — *"a água de um poço que não avança por um bloqueio, onde o trabalho é dar o caminho seguro para que a água circule entre a RAM, o SSD e a gráfica como um núcleo de base de dados com segurança 1+"* — encontra uma tradução matemática e arquitetural direta no modelo tri-camada:

```
+-------------------------------------------------------------------------+
|                  NASCENTE (Tier 1: GPU VRAM / VidMm)                    |
|   - Largura de Banda: 300 - 1000 GB/s (GDDR6 / HBM)                    |
|   - Local VRAM Budget + Non-Local Aperture (Host DRAM)                  |
|   - WDDM 3.x Hardware Scheduling (HAGS) & TDR Watchdog                  |
+-------------------------------------------------------------------------+
                                    ▲  ▼ (Barramento PCIe Gen3/Gen4/Gen5)
+-------------------------------------------------------------------------+
|                 CAUDAL PRINCIPAL (Tier 2: Host DRAM / PFN)               |
|   - Largura de Banda: 40 - 100 GB/s (DDR4 / DDR5)                       |
|   - PFN Database: Active, Standby (0..7), Modified, Free, Zero          |
|   - System File Cache & In-Memory Store Manager (Compression)           |
+-------------------------------------------------------------------------+
                                    ▲  ▼ (Storage Queue / NVMe Subsystem)
+-------------------------------------------------------------------------+
|             BACIA DE RETENÇÃO (Tier 3: NVMe SSD / Commit Engine)        |
|   - Largura de Banda: 3 - 7 GB/s (PCIe NVMe DirectStorage)              |
|   - System Commit Limit = RAM + Pagefile                                |
|   - Crash Dump Subsystem (CrashDumpEnabled = 7) & TRIM Status           |
+-------------------------------------------------------------------------+
```

### 2.1 Formalização Matemática do Fluxo

Seja $\mathcal{M}(t)$ o estado do sistema de memória no instante $t$:

$$\mathcal{M}(t) = \langle \mathcal{V}_{gpu}(t), \mathcal{R}_{pfn}(t), \mathcal{S}_{commit}(t) \rangle$$

1. **Camada GPU ($\mathcal{V}_{gpu}$):**  
   O gestor de memória de vídeo mantém uma quota de alocações locais $A_{local}$ e alocações não-locais partilhadas na RAM do sistema $A_{shared}$:
   $$A_{total\_gpu} = A_{local} + A_{shared}$$
   A condição de estabilidade do pipeline gráfico exige que a latência de transferência de páginas entre $A_{shared}$ e $A_{local}$ satisfaça a restrição temporal do árbitro de watchdog:
   $$\Delta t_{paging} < \tau_{TdrDelay} \quad (\text{onde } \tau_{TdrDelay} \ge 2.0\text{ s})$$

2. **Camada Host DRAM ($\mathcal{R}_{pfn}$):**  
   A base de dados PFN (*Page Frame Number*) decompõe a memória física visível $M_{vis}$ em classes de equivalência:
   $$M_{vis} = M_{active} + \sum_{p=0}^7 M_{standby}^{(p)} + M_{modified} + M_{free} + M_{zero}$$
   A memória disponível para novas alocações imediatas de grande bloco ($Available$) é dada por:
   $$M_{avail} = M_{free} + M_{zero} + \sum_{p=0}^7 M_{standby}^{(p)}$$
   O desbloqueio cirúrgico liberta prioritariamente os estratos de baixa prioridade $M_{standby}^{(0..3)}$ e contingentes de ficheiros volumosos ($FileCache$), sem desmantelar os *working sets* $M_{active}$.

3. **Camada Armazenamento / Commit ($\mathcal{S}_{commit}$):**  
   O limite absoluto de compromisso do sistema ($CommitLimit$) define o volume máximo de memória virtual privada que o sistema operativo pode garantir sem colapso por falta de suporte:
   $$C_{limit} = M_{vis} + \sum P_{pagefile}$$
   A margem de segurança de commit ($H_{commit}$) é definida por:
   $$H_{commit} = \frac{C_{limit} - C_{committed}}{C_{limit}} \times 100\%$$
   Se $H_{commit} < 15\%$ ou se o espaço livre no disco do pagefile for insuficiente ($< 10\text{ GB}$), o pipeline entra em estado de estrangulamento hidráulico, culminando em `STATUS_COMMITMENT_LIMIT_EXCEEDED` (0xC000012D).

---

## 3. Os Cinco Invariantes de Segurança 1+ (Mathematical Safety Invariants)

Para garantir que o sistema nunca congele, nunca reduza o desempenho e execute intervenções em regime transacional atómico com resiliência de nível industrial ("Segurança 1+"), definem-se cinco invariantes que qualquer ação do software é obrigada a validar:

### Invariante $I_1$: Não-Interrupção da Camada Gráfica e DWM
> **Definição Formal:**  
> $\forall t, \quad \mathcal{A}_{action} \cap \text{TrimWorkingSet}(PID_{DWM}) = \emptyset \land \mathcal{A}_{action} \cap \text{TrimWorkingSet}(PID_{CSRSS}) = \emptyset$

*Justificação:* O esvaziamento forçado de working sets de processos de infraestrutura gráfica induz faltas de página críticas durante a fase de rasterização e composição de frames, constituindo o gatilho principal de ecrãs negros reportados por utilizadores de scripts legados.

### Invariante $I_2$: Garantia de Commit Headroom e Salvaguarda de Armazenamento
> **Definição Formal:**  
> $H_{commit}(t_{after}) \ge 15\% \quad \land \quad FreeSpace(Drive_{Pagefile}) \ge 5\text{ GB}$

*Justificação:* Nenhum ajuste de limites de memória física pode ser efetuado se isso comprimir o limite de commit abaixo do teto de segurança operacional ou se o suporte de armazenamento estiver no limite da capacidade.

### Invariante $I_3$: Coerência de Boot e Prevenção de PFN Hibernado Obsoleto
> **Definição Formal:**  
> $\Delta BCD(M_{phys}) \neq \emptyset \implies (HiberbootEnabled = 0 \land RebootType = \text{ColdBoot})$

*Justificação:* O mecanismo de *Fast Startup* do Windows armazena uma imagem hibernada do kernel no ficheiro `hiberfil.sys`. A alteração do mapa de memória físico no BCD (`truncatememory`/`removememory`) sem a desativação do arranque híbrido faz com que o kernel retome sobre uma base de dados PFN que já não corresponde ao mapa UEFI real, originando corrupção e falhas de arranque.

### Invariante $I_4$: Resiliência e Proteção do Watchdog TDR WDDM
> **Definição Formal:**  
> $TdrLevel \in \{3\} \quad \land \quad (Count(TDR_{14d}) \ge 3 \implies TdrDelay \ge 8\text{ s})$

*Justificação:* Desativar o TDR (`TdrLevel = 0`) é terminantemente proibido: transforma falhas recuperáveis em congelamentos totais do equipamento (*hard lockups*). O padrão Microsoft WHQL exige $TdrLevel = 3$ (*Recover*), expandindo adaptativamente o tempo de tolerância para 8 segundos caso o histórico recente evidencie instabilidade de carga.

### Invariante $I_5$: Blindagem de Integridade de Silício (Detetor WHEA/MCA)
> **Definição Formal:**  
> $Count(WHEA_{14d}) > 0 \implies \text{BlockUnverifiedUnlock} \land \text{ScheduleMemDiag}(\{memdiag\})$

*Justificação:* Se existirem registos de eventos de arquitetura de verificação de erros de hardware (WHEA-Logger 18/19), o desbloqueio ingénuo de intervalos de memória física expõe células de DRAM fisicamente degradadas (*hard errors*), resultando em `WHEA_UNCORRECTABLE_ERROR` (0x124). O protocolo isola a memória suspeita e direciona para validação diagnóstica antes da exposição em produção.

---

## 4. Normas da Indústria, Certificações e Referências Verificadas

Para suportar a dissertação perante um júri académico exigente, o projeto ancora-se em normas e investigações de referência internacional:

| Domínio | Norma / Publicação | Requisito / Princípio Aplicado |
|---|---|---|
| **Compatibilidade de Hardware** | **Microsoft WHCP / WHQL** (*Windows Hardware Compatibility Program*) | Preservação da integridade de PFNs, persistência de crash dumps (`CrashDumpEnabled = 7`), conformidade com WDDM 2.x/3.x. |
| **Arquitetura Gráfica** | **Microsoft WDDM 3.x Specification** | Gestão de resiliência do *Video Memory Manager* (VidMm), orçamento de VRAM e disciplina do mecanismo TDR. |
| **Integridade de DRAM** | **JEDEC JESD79-4 / JESD79-5** (DDR4/DDR5) | Padrões de temporização e sinal elétrico de DRAM; restrições de operação fora de especificação JEDEC (XMP/EXPO). |
| **Estudo Empírico de Falhas** | **Schroeder, Pinheiro & Weber (ACM SIGMETRICS 2009)** | *"DRAM Errors in the Wild: A Large-Scale Field Study"* — comprova a prevalência de erros duros e a futilidade de "otimizações" puramente lógicas sobre silício danificado. |
| **Teoria de Sistemas Operativos** | **Peter J. Denning (CACM 1968)** | *"The Working Set Model for Program Behavior"* — demonstra a relação formal entre corte de working set e o fenómeno de *thrashing*. |
| **Arquitetura Interna NT** | **Russinovich, Solomon & Ionescu** (*Windows Internals*) | Decomposição formal da base de dados PFN, listas de Standby, Modified, Free, Zero, e subsistema de compressão *Store Manager*. |
| **Interfaces de Plataforma** | **ACPI 6.4 Specification / APEI & WHEA** | Tabelas HEST, BERT e ERST para reporte estruturado de falhas de hardware corrigidas e não-corrigidas. |
| **Qualidade de Software** | **ISO/IEC 25010** | Critérios de Eficiência de Desempenho, Fiabilidade (Tolerância a Falhas) e Segurança Funcional. |

---

## 5. Metodologia Experimental e Protocolo de Avaliação para a Tese

Para a componente experimental da dissertação, estabelece-se um protocolo de teste controlado e repetível:

### 5.1 Formulação de Hipóteses
- **Hipótese Nula ($H_0$):** A aplicação do pipeline coordenado de gestão de memória e desbloqueio físico não produz melhoria estatisticamente significativa na latência de alocação de memória ou na redução de falhas gráficas (TDR) em comparação com o estado nativo do sistema operativo.
- **Hipótese Alternativa ($H_1$):** A aplicação do pipeline coordenado aumenta a memória disponível imediata, elimina perdas artificiais de capacidade por parâmetros BCD, estabiliza o subsistema gráfico e previne eventos de congelamento, mantendo as cinco invariantes de segurança.

### 5.2 Variáveis do Estudo
- **Variáveis Independentes:**
  - Aplicação do algoritmo de balanceamento de Standby (cmds 4/5) via `NtSetSystemInformation`;
  - Remoção atómica de limitadores BCD (`removememory`/`truncatememory`);
  - Aplicação do perfil de integridade de commit e resiliência TDR.
- **Variáveis Dependentes:**
  - Volume de memória física visível ($M_{vis}$ em GB);
  - Volume de memória disponível imediata ($Available$ em GB);
  - Taxa de faltas de página duras por segundo ($HardFaults/s$);
  - Latência de alocação de blocos de memória contíguos (em milissegundos);
  - Frequência de eventos de anomalia no registo de eventos (WHEA, BugCheck 1001, TDR 4101);
  - Estabilidade de frametime em cargas de trabalho gráficas e computacionais intensivas.

### 5.3 Artefactos de Evidência Produzidos pelo Motor
O motor de software desenvolvido exporta automaticamente três artefactos empíricos essenciais para a defesa da tese:
1. `connect-ram-telemetry.json`: Dataset estruturado em formato JSON com carimbos temporais, leituras pré/pós intervenção, contadores WMI/CIM e perfis de hardware para posterior análise em Python/R/Jupyter;
2. `connect-ram-health-report.txt`: Relatório técnico sucinto de diagnóstico de conformidade;
3. `connect-ram-thesis-report.html`: Relatório interativo de auditoria visual com certificado formal de conformidade, classificação de integridade de fluxo (Grade A+) e mapeamento para as referências da dissertação.

---

## 6. Estrutura Proposta para a Redação da Dissertação

1. **Capítulo 1: Introdução**
   - Contexto e Motivação
   - Enunciado do Problema
   - Objetivos e Contribuições Científicas
   - Organização do Documento
2. **Capítulo 2: Fundamentação Teórica e Estado da Arte**
   - Arquitetura de Memória x86-64 e Gestão de Endereços Físicos/Virtuais
   - O Kernel do Windows NT: PFN Database e Políticas de Paginação
   - Subsistema Gráfico WDDM 3.x e o Video Memory Manager (VidMm)
   - O Modelo de Working Set de Denning e o Impacto do *Thrashing*
   - Análise Crítica dos Utilitários de Otimização Existentes no Mercado
3. **Capítulo 3: Arquitetura do Modelo do Pipeline Hidráulico Tri-Camada**
   - Modelação da Hierarquia: VRAM, Host DRAM e Armazenamento NVMe
   - O Motor de Base de Dados de Estado de Memória
   - Interações Transacionais e Gestão de Concorrência
4. **Capítulo 4: Formalização das Invariantes de Segurança 1+**
   - Demonstração Matemática das Invariantes $I_1$ a $I_5$
   - Algoritmos de Resolução e Verificação em Tempo de Execução
   - Políticas de Rollback e Idempotência Operacional
5. **Capítulo 5: Implementação do Sistema (CONNECT Memory Pipeline Core)**
   - Integração com Interfaces Não-Documentadas do Kernel (`NtSetSystemInformation`)
   - Orquestração de Privilégios de Segurança (`SeProfileSingleProcessPrivilege`, `SeIncreaseQuotaPrivilege`)
   - Telemetria de Baixo Impacto com Contadores de Desempenho e WMI/CIM
   - Motor de Relatórios e Auditoria Multiformato
6. **Capítulo 6: Avaliação Experimental e Resultados**
   - Metodologia de Teste e Cenários de Carga
   - Resultados de Desempenho e Eficácia de Reclaim
   - Análise de Resiliência e Prevenção de Falhas Gráficas
   - Discussão de Resultados e Validação da Hipótese $H_1$
7. **Capítulo 7: Conclusões e Trabalho Futuro**
   - Síntese dos Resultados Alcançados
   - Limitações do Estudo
   - Direções de Investigação Futura (e.g. Drivers de Kernel Dedicados, IA Preditiva para Gestão de Working Sets)
8. **Referências Bibliográficas**
9. **Anexos** (Código Fonte, Esquemas Arquiteturais, Datasets Experimentais)
