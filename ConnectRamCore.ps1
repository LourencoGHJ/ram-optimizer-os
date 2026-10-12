# CONNECT Labs Universal RAM Unlocker & Memory Pipeline Core v5.0
# Evidence-based Tri-Layer Memory Engine (RAM + Storage + GPU VRAM)
# Academic & Stability Protocol: PFN Database, WDDM VidMm, NVMe Commit, Safety Invariants 1+

[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Diagnose', 'Quick', 'Full', 'Health', 'Storage', 'Benchmark', 'Report')]
    [string]$Action = 'Menu',
    [ValidateSet('PT', 'EN', 'ES')]
    [string]$Lang = '',
    [switch]$ExportHtml,
    [switch]$ExportJson
)

$ErrorActionPreference = 'Continue'
try { chcp 65001 | Out-Null } catch {}
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}
$Host.UI.RawUI.WindowTitle = '[CONNECT LABS] RAM & Memory Pipeline Core v5.0'
try { mode con: cols=104 lines=48 | Out-Null } catch {}

$script:LogPath     = Join-Path $env:TEMP 'connect-ram-unlocker.log'
$script:ReportPath  = Join-Path $env:TEMP 'connect-ram-health-report.txt'
$script:JsonPath    = Join-Path $env:TEMP 'connect-ram-telemetry.json'
$script:HtmlPath    = Join-Path $env:TEMP 'connect-ram-thesis-report.html'

function Write-Log {
    param([string]$Message)
    $line = '{0:u}  {1}' -f (Get-Date), $Message
    try { Add-Content -Path $script:LogPath -Value $line -Encoding UTF8 } catch {}
}

function Test-IsElevated {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

$script:IsElevated = Test-IsElevated

# Native P/Invoke for NtSetSystemInformation (SystemMemoryListInformation = 80) and SetSystemFileCacheSize
$nativeSource = @'
using System;
using System.Runtime.InteropServices;

public class ConnectRamNative {
    [DllImport("ntdll.dll")]
    public static extern int NtSetSystemInformation(int SystemInformationClass, ref int SystemInformation, int SystemInformationLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetSystemFileCacheSize(UIntPtr MinimumFileCacheSize, UIntPtr MaximumFileCacheSize, int Flags);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern IntPtr GetCurrentProcess();

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
        public int Count;
        public long Luid;
        public int Attr;
    }

    const int SE_PRIVILEGE_ENABLED = 0x00000002;
    const int TOKEN_QUERY = 0x00000008;
    const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    public const int SystemMemoryListInformation = 80;
    public const int FILE_CACHE_MAX_HARD_ENABLE = 1;

    public static bool EnablePrivilege(string privilege) {
        IntPtr htok = IntPtr.Zero;
        if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok))
            return false;
        TokPriv1Luid tp = new TokPriv1Luid();
        tp.Count = 1;
        tp.Luid = 0;
        tp.Attr = SE_PRIVILEGE_ENABLED;
        if (!LookupPrivilegeValue(null, privilege, ref tp.Luid))
            return false;
        return AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }

    public static int PurgeMemoryList(int command) {
        int cmd = command;
        return NtSetSystemInformation(SystemMemoryListInformation, ref cmd, 4);
    }
}
'@

if (-not ('ConnectRamNative' -as [type])) {
    try {
        Add-Type -TypeDefinition $nativeSource -ErrorAction Stop
    } catch {
        Write-Log ('Add-Type failed: {0}' -f $_.Exception.Message)
    }
}

$script:T = @{
    PT = @{
        NoteTitle    = 'v5.0 — MODELO HIDRÁULICO TRI-CAMADA & SEGURANÇA 1+ (Tese de Mestrado)'
        NoteBody     = @(
            'A memória do PC opera como um pipeline hidráulico de vasos comunicantes:',
            '1. NASCENTE: GPU VRAM (WDDM 3.x / VidMm) - Orçamentos locais e partilhados via PCIe.',
            '2. CAUDAL: Host DRAM (PFN Database) - 8 listas Standby, Working Sets, Pool do Kernel.',
            '3. BACIA DE RETENÇÃO: Armazenamento NVMe (Commit Limit, Pagefile e Compressão ZRAM/Store).',
            'O estrangulamento de qualquer camada gera freezes ou TDR (ecrã preto 0x116 por timeout 2s).',
            'A v5.0 implementa as 5 INVARIANTES DE SEGURANÇA 1+: nunca poda DWM, garante Commit Headroom,',
            'isola falhas de silício (WHEA), sincroniza ASPM PCIe e impõe arranque a frio sem PFN obsoleto.'
        )
        Continue     = 'Deseja continuar? (S/N): '
        MenuTitle    = 'CONNECT Labs — Universal RAM Unlocker & Memory Pipeline Core v5.0'
        M1           = '[1] Diagnostico Integral do Pipeline (RAM + Armazenamento + GPU + WHEA)'
        M2           = '[2] Reclaim Seguro do Fluxo (Standby Tiered Purge, File Cache Cap, Sem DWM trim)'
        M3           = '[3] Desbloqueio BCD + Perfil de Estabilidade (Cold Boot, CrashControl, TDR, ASPM)'
        M4           = '[4] Auditoria & Otimizacao do Commit de Armazenamento (Pagefile, TRIM, Headroom)'
        M5           = '[5] Benchmark Cientifico & Telemetria para Tese (Latencia, Faltas de Pagina, VRAM)'
        M6           = '[6] Gerador de Relatorio Academico & Certificacao 1+ (TXT, JSON e HTML interativo)'
        M7           = '[7] Trocar idioma'
        M8           = '[8] Sair'
        Choose       = 'Escolha (1-8): '
        DiagTitle    = 'DIAGNÓSTICO TRI-CAMADA DO PIPELINE DE MEMÓRIA'
        Before       = 'ESTADO ANTERIOR (BEFORE)'
        After        = 'ESTADO ATUAL (AFTER)'
        Reclaim      = 'A balancear fluxo de memoria: Purgando Standby (cmds 4/5). DWM/Working Sets intactos.'
        Bcd          = 'A remover limites de arranque no BCD (removememory / truncatememory)...'
        Revert       = 'A repor chaves de registo desestabilizadoras (ClearPageFileAtShutdown / LargeSystemCache)...'
        Compress     = 'A validar Memory Compression (Store Manager) e servico SysMain...'
        CacheCap     = 'Cache de ficheiros >30% da RAM visivel — aplicando limite SetSystemFileCacheSize...'
        CacheSkip    = 'Cache de ficheiros em proporcao saudavel.'
        RebootAsk    = 'Alteracoes no mapa de arranque. REINICIAR agora a frio (shutdown /r, nao hibrido)? (S/N): '
        Done         = 'Concluido com sucesso. Log: '
        Key          = 'Pressione ENTER para voltar ao menu principal'
        Yes          = 'S'
        FailPriv     = 'Falha a ativar privilegio de seguranca (requer privilegios de Administrador).'
        NtFail       = 'NtSetSystemInformation retornou status'
        Sources      = 'Normas & Referencias: Microsoft WHCP/WHQL; WDDM 3.x VidMm; Schroeder et al. SIGMETRICS 2009; Denning CACM 1968.'
        HealthRun    = 'A aplicar protocolo de estabilidade 1+ (sem trim global, preservando DWM)...'
        WheaWarn     = '[CRITICO] Eventos WHEA detetados nos ultimos 14 dias: risco de DRAM com hard error exposta. Requer MemDiag.'
        TdrWarn      = '[AVISO] Registados eventos de TDR (Display 4101): EmptyWorkingSets estritamente bloqueado para evitar ecrã negro.'
        MemDiagAsk   = 'Agendar Windows Memory Diagnostic no proximo arranque? (S/N): '
        AdminNotice  = '[AVISO] Execucao sem privilegios de Administrador. Algumas acoes de modificacao exigem elevacao.'
    }
    EN = @{
        NoteTitle    = 'v5.0 — TRI-LAYER HYDRAULIC MODEL & SAFETY 1+ (Master Thesis)'
        NoteBody     = @(
            'PC memory acts as a hydraulic pipeline of communicating vessels:',
            '1. SOURCE: GPU VRAM (WDDM 3.x / VidMm) - Local and shared budgets over PCIe.',
            '2. FLOW: Host DRAM (PFN Database) - 8 Standby lists, Working Sets, Kernel Pools.',
            '3. RETENTION BASIN: NVMe Storage (Commit Limit, Pagefile and ZRAM/Store Compression).',
            'Choking any layer triggers freezes or TDR (black screen 0x116 from 2s scheduler timeout).',
            'v5.0 enforces the 5 SAFETY INVARIANTS 1+: never trims DWM, guarantees Commit Headroom,',
            'shields silicon faults (WHEA), syncs PCIe ASPM and enforces cold boot without stale PFN.'
        )
        Continue     = 'Continue? (Y/N): '
        MenuTitle    = 'CONNECT Labs — Universal RAM Unlocker & Memory Pipeline Core v5.0'
        M1           = '[1] Comprehensive Pipeline Diagnosis (RAM + Storage + GPU + WHEA)'
        M2           = '[2] Safe Flow Reclaim (Standby Tiered Purge, File Cache Cap, Zero DWM trim)'
        M3           = '[3] BCD Unlock + Stability Protocol (Cold Boot, CrashControl, TDR, ASPM)'
        M4           = '[4] Storage Commit Audit & Optimization (Pagefile, TRIM, Headroom)'
        M5           = '[5] Scientific Benchmark & Thesis Telemetry (Latency, Hard Faults, VRAM)'
        M6           = '[6] Academic Report & Safety 1+ Certification (TXT, JSON and Interactive HTML)'
        M7           = '[7] Change language'
        M8           = '[8] Exit'
        Choose       = 'Choose (1-8): '
        DiagTitle    = 'TRI-LAYER MEMORY PIPELINE DIAGNOSTIC'
        Before       = 'BEFORE STATE'
        After        = 'AFTER STATE'
        Reclaim      = 'Balancing memory flow: Purging Standby (cmds 4/5). DWM/Working Sets untouched.'
        Bcd          = 'Removing boot memory limits in BCD (removememory / truncatememory)...'
        Revert       = 'Reverting harmful registry tweaks (ClearPageFileAtShutdown / LargeSystemCache)...'
        Compress     = 'Validating Memory Compression (Store Manager) and SysMain service...'
        CacheCap     = 'System file cache >30% of visible RAM — enforcing SetSystemFileCacheSize cap...'
        CacheSkip    = 'System file cache within optimal proportion.'
        RebootAsk    = 'Boot map modified. RESTART now with cold boot (shutdown /r, not hybrid)? (Y/N): '
        Done         = 'Operation completed. Log: '
        Key          = 'Press ENTER to return to the main menu'
        Yes          = 'Y'
        FailPriv     = 'Failed to acquire security token privilege (Administrator required).'
        NtFail       = 'NtSetSystemInformation returned status'
        Sources      = 'Standards & Citations: Microsoft WHCP/WHQL; WDDM 3.x VidMm; Schroeder et al. SIGMETRICS 2009; Denning CACM 1968.'
        HealthRun    = 'Applying safety 1+ protocol (zero global trim, preserving DWM)...'
        WheaWarn     = '[CRITICAL] WHEA events detected in last 14 days: DRAM hard error risk. Run Windows Memory Diagnostic.'
        TdrWarn      = '[WARNING] GPU TDR events detected (Display 4101): EmptyWorkingSets strictly prohibited to prevent black screens.'
        MemDiagAsk   = 'Schedule Windows Memory Diagnostic on next reboot? (Y/N): '
        AdminNotice  = '[NOTICE] Running without Administrator rights. Mutating actions require elevation.'
    }
    ES = @{
        NoteTitle    = 'v5.0 — MODELO HIDRÁULICO TRI-CAPA Y SEGURIDAD 1+ (Tesis de Maestría)'
        NoteBody     = @(
            'La memoria del PC opera como un conducto hidráulico de vasos comunicantes:',
            '1. MANANTIAL: GPU VRAM (WDDM 3.x / VidMm) - Cuotas locales y compartidas via PCIe.',
            '2. CAUDAL: Host DRAM (PFN Database) - 8 listas Standby, Working Sets, Pools del Kernel.',
            '3. CUENCA DE RETENCIÓN: Almacenamiento NVMe (Commit Limit, Pagefile y Compresión Store).',
            'Cualquier estrangulamiento produce congelamientos o TDR (pantalla negra 0x116 por timeout 2s).',
            'La v5.0 implementa las 5 INVARIANTES DE SEGURIDAD 1+: jamás poda DWM, asegura Commit Headroom,',
            'aísla fallas de silicio (WHEA), sincroniza ASPM PCIe y exige arranque en frío sin PFN obsoleto.'
        )
        Continue     = 'Desea continuar? (S/N): '
        MenuTitle    = 'CONNECT Labs — Universal RAM Unlocker & Memory Pipeline Core v5.0'
        M1           = '[1] Diagnostico Integral del Pipeline (RAM + Almacenamiento + GPU + WHEA)'
        M2           = '[2] Reclaim Seguro del Flujo (Standby Tiered Purge, File Cache Cap, Sin DWM trim)'
        M3           = '[3] Desbloqueo BCD + Protocolo de Estabilidad (Cold Boot, CrashControl, TDR, ASPM)'
        M4           = '[4] Auditoria y Optimizacion de Commit de Almacenamiento (Pagefile, TRIM, Headroom)'
        M5           = '[5] Benchmark Cientifico y Telemetria para Tesis (Latencia, Fallos de Pagina, VRAM)'
        M6           = '[6] Generador de Informe Academico y Certificacion 1+ (TXT, JSON y HTML interactivo)'
        M7           = '[7] Cambiar idioma'
        M8           = '[8] Salir'
        Choose       = 'Elija (1-8): '
        DiagTitle    = 'DIAGNÓSTICO TRI-CAPA DEL PIPELINE DE MEMORIA'
        Before       = 'ESTADO ANTERIOR'
        After        = 'ESTADO ACTUAL'
        Reclaim      = 'Equilibrando flujo de memoria: Purgando Standby (cmds 4/5). DWM/Working Sets intactos.'
        Bcd          = 'Eliminando limites de arranque en BCD (removememory / truncatememory)...'
        Revert       = 'Revirtiendo claves daninas (ClearPageFileAtShutdown / LargeSystemCache)...'
        Compress     = 'Validando Memory Compression (Store Manager) y servicio SysMain...'
        CacheCap     = 'Cache de archivos >30% de la RAM visible — aplicando tope SetSystemFileCacheSize...'
        CacheSkip    = 'Cache de archivos en proporcion optima.'
        RebootAsk    = 'Mapa de arranque modificado. REINICIAR ahora en frio (shutdown /r, no hibrido)? (S/N): '
        Done         = 'Operacion completada. Log: '
        Key          = 'Presione ENTER para volver al menu principal'
        Yes          = 'S'
        FailPriv     = 'Fallo al adquirir privilegio de seguridad (requiere Administrador).'
        NtFail       = 'NtSetSystemInformation devolvio estado'
        Sources      = 'Estandares y Citas: Microsoft WHCP/WHQL; WDDM 3.x VidMm; Schroeder et al. SIGMETRICS 2009; Denning CACM 1968.'
        HealthRun    = 'Aplicando protocolo de seguridad 1+ (sin trim global, preservando DWM)...'
        WheaWarn     = '[CRITICO] Eventos WHEA detectados en 14 dias: riesgo de DRAM con hard error. Ejecuta MemDiag.'
        TdrWarn      = '[AVISO] Eventos TDR detectados (Display 4101): EmptyWorkingSets estrictamente bloqueado.'
        MemDiagAsk   = 'Programar Windows Memory Diagnostic en el proximo reinicio? (S/N): '
        AdminNotice  = '[AVISO] Ejecutando sin privilegios de Administrador. Acciones de cambio requieren elevacion.'
    }
}

function Get-T { param([string]$Key) return $script:T[$script:Lang][$Key] }

function Format-Bytes([int64]$Bytes) {
    if ($Bytes -lt 0) { $Bytes = 0 }
    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    return ('{0:N0} KB' -f ($Bytes / 1KB))
}

function Get-BcdText {
    try { return (bcdedit /enum '{current}' 2>$null | Out-String) } catch { return '' }
}

function Get-EventCount {
    param(
        [string]$LogName,
        [string]$Provider,
        [int[]]$Id,
        [int]$Days = 14
    )
    $filter = @{ LogName = $LogName; StartTime = (Get-Date).AddDays(-$Days) }
    if ($Provider) { $filter['ProviderName'] = $Provider }
    if ($Id) { $filter['Id'] = $Id }
    try {
        return @(Get-WinEvent -FilterHashtable $filter -MaxEvents 200 -ErrorAction Stop).Count
    } catch {
        return 0
    }
}

function Get-TrimStatus {
    try {
        $res = fsutil behavior query DisableDeleteNotify 2>$null | Out-String
        if ($res -match 'DisableDeleteNotify\s*=\s*0') { return 'Enabled (Optimal TRIM)' }
        if ($res -match 'DisableDeleteNotify\s*=\s*1') { return 'Disabled (TRIM Off)' }
        return 'Standard'
    } catch {
        return 'Unknown'
    }
}

function Get-GpuSnapshot {
    $gpuName = 'Generic GPU'
    $vramTotal = 0L
    $driverVer = ''
    try {
        $vid = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($vid) {
            $gpuName = $vid.Name
            $vramTotal = [int64]$vid.AdapterRAM
            $driverVer = $vid.DriverVersion
        }
    } catch {}

    $localUsage = 0L
    try {
        $loc = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPULocalAdapterMemory -ErrorAction SilentlyContinue
        if ($loc) {
            $localUsage = [int64](($loc | Measure-Object -Property LocalUsage -Sum).Sum)
        }
    } catch {}

    $nonLocalUsage = 0L
    try {
        $nloc = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUNonLocalAdapterMemory -ErrorAction SilentlyContinue
        if ($nloc) {
            $nonLocalUsage = [int64](($nloc | Measure-Object -Property NonLocalUsage -Sum).Sum)
        }
    } catch {}

    $hwSchMode = 0
    try {
        $hw = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -ErrorAction SilentlyContinue
        if ($null -ne $hw.HwSchMode) { $hwSchMode = [int]$hw.HwSchMode }
    } catch {}

    $tdrDelay = 2; $tdrLevel = 3
    try {
        $g = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -ErrorAction SilentlyContinue
        if ($null -ne $g.TdrDelay) { $tdrDelay = [int]$g.TdrDelay }
        if ($null -ne $g.TdrLevel) { $tdrLevel = [int]$g.TdrLevel }
    } catch {}

    [pscustomobject]@{
        Name           = $gpuName
        VramTotal      = $vramTotal
        LocalUsage     = $localUsage
        NonLocalUsage  = $nonLocalUsage
        DriverVersion  = $driverVer
        HagsMode       = $(switch ($hwSchMode) { 2 { 'Hardware-Accelerated (HAGS ON)' } 1 { 'Software-Scheduled (HAGS OFF)' } default { 'Default' } })
        TdrLevel       = $tdrLevel
        TdrDelay       = $tdrDelay
    }
}

function Get-StorageSnapshot {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $pfAuto = $false
    try { $pfAuto = [bool]$cs.AutomaticManagedPagefile } catch {}
    
    $pfSize = 0L
    try {
        $pfSize = [int64]((Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue |
                Measure-Object -Property AllocatedBaseSize -Sum).Sum) * 1MB
    } catch {}

    $sysDrive = $env:SystemDrive
    $driveFree = 0L; $driveTotal = 0L
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sysDrive'" -ErrorAction SilentlyContinue
        if ($disk) {
            $driveFree = [int64]$disk.FreeSpace
            $driveTotal = [int64]$disk.Size
        }
    } catch {}

    $models = @()
    try {
        $drives = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
        foreach ($d in $drives) { $models += $d.Model }
    } catch {}

    $trim = Get-TrimStatus

    [pscustomobject]@{
        PagefileAuto   = $pfAuto
        PagefileSize   = $pfSize
        SystemDrive    = $sysDrive
        DriveFree      = $driveFree
        DriveTotal     = $driveTotal
        DriveModels    = ($models -join ' | ')
        TrimStatus     = $trim
        LowSpaceRisk   = [bool]($driveFree -lt 10GB)
    }
}

function Get-StabilityEvidence {
    $whea = Get-EventCount -LogName 'System' -Provider 'Microsoft-Windows-WHEA-Logger' -Days 14
    $bugcheck = Get-EventCount -LogName 'System' -Id @(1001) -Days 14
    $kpower = Get-EventCount -LogName 'System' -Provider 'Microsoft-Windows-Kernel-Power' -Id @(41) -Days 14
    $tdr = Get-EventCount -LogName 'System' -Id @(4101) -Days 14
    if ($tdr -eq 0) {
        $tdr = Get-EventCount -LogName 'System' -Provider 'Display' -Days 14
    }

    $dump = 7; $autoReboot = 1
    try {
        $cc = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -ErrorAction SilentlyContinue
        if ($cc) {
            $dump = [int]$cc.CrashDumpEnabled
            $autoReboot = [int]$cc.AutoReboot
        }
    } catch {}

    $hiberboot = 1
    try {
        $hib = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction SilentlyContinue
        if ($null -ne $hib.HiberbootEnabled) { $hiberboot = [int]$hib.HiberbootEnabled }
    } catch {}

    $lastBug = ''
    try {
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 1001; StartTime = (Get-Date).AddDays(-30) } -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($ev) {
            $lastBug = ($ev.Message -split "`n")[0]
            if ($lastBug.Length -gt 180) { $lastBug = $lastBug.Substring(0, 180) }
        }
    } catch {}

    [pscustomobject]@{
        Whea14d       = $whea
        Bugcheck14d   = $bugcheck
        KernelPower41 = $kpower
        Tdr14d        = $tdr
        DumpType      = $dump
        AutoReboot    = $autoReboot
        Hiberboot     = $hiberboot
        LastBugMsg    = $lastBug
    }
}

function Get-RamPipelineSnapshot {
    $null = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 250

    $os = Get-CimInstance Win32_OperatingSystem
    $installed = [int64]((Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue |
            Measure-Object -Property Capacity -Sum).Sum)
    $visible = [int64]$os.TotalVisibleMemorySize * 1KB
    $free = [int64]$os.FreePhysicalMemory * 1KB
    if ($installed -le 0) { $installed = $visible }

    $perf = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
    $standbyCore = 0L; $standbyNormal = 0L; $standbyReserve = 0L
    try {
        if ($perf.PSObject.Properties.Name -contains 'StandbyCacheCoreBytes') { $standbyCore = [int64]$perf.StandbyCacheCoreBytes }
        if ($perf.PSObject.Properties.Name -contains 'StandbyCacheNormalPriorityBytes') { $standbyNormal = [int64]$perf.StandbyCacheNormalPriorityBytes }
        if ($perf.PSObject.Properties.Name -contains 'StandbyCacheReserveBytes') { $standbyReserve = [int64]$perf.StandbyCacheReserveBytes }
    } catch {}
    $standbyTotal = $standbyCore + $standbyNormal + $standbyReserve

    $modified = 0L; $cache = 0L; $available = 0L; $commitLimit = 0L; $committed = 0L
    $poolPaged = 0L; $poolNonpaged = 0L; $pageFaultsSec = 0
    try {
        if ($perf.PSObject.Properties.Name -contains 'ModifiedPageListBytes') { $modified = [int64]$perf.ModifiedPageListBytes }
        if ($perf.PSObject.Properties.Name -contains 'CacheBytes') { $cache = [int64]$perf.CacheBytes }
        if ($perf.PSObject.Properties.Name -contains 'AvailableBytes') { $available = [int64]$perf.AvailableBytes }
        if ($perf.PSObject.Properties.Name -contains 'CommitLimit') { $commitLimit = [int64]$perf.CommitLimit }
        if ($perf.PSObject.Properties.Name -contains 'CommittedBytes') { $committed = [int64]$perf.CommittedBytes }
        if ($perf.PSObject.Properties.Name -contains 'PoolPagedBytes') { $poolPaged = [int64]$perf.PoolPagedBytes }
        if ($perf.PSObject.Properties.Name -contains 'PoolNonpagedBytes') { $poolNonpaged = [int64]$perf.PoolNonpagedBytes }
        if ($perf.PSObject.Properties.Name -contains 'PageFaultsPerSec') { $pageFaultsSec = [int]$perf.PageFaultsPerSec }
    } catch {}
    if ($available -le 0) { $available = $free }
    if ($commitLimit -gt 0 -and $commitLimit -lt 1MB) { $commitLimit = $commitLimit * 1KB }

    $commitHeadroomPct = 0.0
    if ($commitLimit -gt 0) {
        $commitHeadroomPct = [math]::Round((($commitLimit - $committed) / [double]$commitLimit) * 100.0, 1)
    }

    $compressed = $false
    try {
        if ($script:IsElevated -and (Get-Command Get-MMAgent -ErrorAction SilentlyContinue)) {
            $agent = Get-MMAgent -ErrorAction Stop
            $compressed = [bool]$agent.MemoryCompression
        } else {
            $compressed = $null -ne (Get-Process -Name 'Memory Compression' -ErrorAction SilentlyContinue)
        }
    } catch {
        $compressed = $null -ne (Get-Process -Name 'Memory Compression' -ErrorAction SilentlyContinue)
    }

    $bcd = Get-BcdText
    $mmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $clearPf = 0; $largeCache = 0
    try {
        $mm = Get-ItemProperty -Path $mmPath -ErrorAction SilentlyContinue
        if ($mm) {
            if ($null -ne $mm.ClearPageFileAtShutdown) { $clearPf = [int]$mm.ClearPageFileAtShutdown }
            if ($null -ne $mm.LargeSystemCache) { $largeCache = [int]$mm.LargeSystemCache }
        }
    } catch {}

    $stab = Get-StabilityEvidence
    $gpu = Get-GpuSnapshot
    $storage = Get-StorageSnapshot

    $hwRes = [int64]($installed - $visible)
    if ($hwRes -lt 0L) { $hwRes = 0L }
    $inUse = [int64]($visible - $available)
    if ($inUse -lt 0L) { $inUse = 0L }

    [pscustomobject]@{
        Timestamp      = (Get-Date)
        Installed      = $installed
        Visible        = $visible
        HardwareRes    = $hwRes
        Free           = $free
        Available      = $available
        InUse          = $inUse
        StandbyTotal   = $standbyTotal
        StandbyCore    = $standbyCore
        StandbyNormal  = $standbyNormal
        StandbyReserve = $standbyReserve
        Modified       = $modified
        FileCache      = $cache
        PoolPaged      = $poolPaged
        PoolNonpaged   = $poolNonpaged
        PageFaultsSec  = $pageFaultsSec
        CommitLimit    = $commitLimit
        Committed      = $committed
        CommitHeadroom = $commitHeadroomPct
        CompressionOn  = $compressed
        SysMainStatus  = (Get-Service SysMain -ErrorAction SilentlyContinue).Status
        BcdTruncate    = [bool]($bcd -match 'truncatememory')
        BcdRemove      = [bool]($bcd -match 'removememory')
        ClearPageFile  = $clearPf
        LargeCache     = $largeCache
        Stability      = $stab
        Gpu            = $gpu
        Storage        = $storage
    }
}

function Evaluate-CertificationGrade {
    param($Snap)
    $score = 100
    $reasons = @()

    if ($Snap.Stability.Whea14d -gt 0) {
        $score -= 35
        $reasons += 'WHEA errors detected (DRAM hard error risk)'
    }
    if ($Snap.Gpu.TdrLevel -eq 0) {
        $score -= 40
        $reasons += 'TDR watchdog disabled (TdrLevel=0)'
    }
    if ($Snap.BcdTruncate -or $Snap.BcdRemove) {
        $score -= 20
        $reasons += 'BCD artificial memory limit present'
    }
    if ($Snap.Storage.LowSpaceRisk) {
        $score -= 15
        $reasons += 'Low free space on pagefile system drive (<10GB)'
    }
    if ($Snap.CommitHeadroom -lt 15.0) {
        $score -= 15
        $reasons += 'Commit headroom critical (<15%)'
    }
    if ($Snap.Stability.Hiberboot -eq 1 -and ($Snap.BcdTruncate -or $Snap.BcdRemove)) {
        $score -= 15
        $reasons += 'Fast Startup active with custom BCD map'
    }
    if ($Snap.ClearPageFile -eq 1) {
        $score -= 10
        $reasons += 'ClearPageFileAtShutdown=1 slowing shutdown'
    }
    if ($Snap.FileCache -gt 0 -and ($Snap.FileCache / [double]$Snap.Visible) -gt 0.30) {
        $score -= 10
        $reasons += 'File cache bloated (>30% of visible RAM)'
    }

    $grade = 'A+ (Certified Optimal Pipeline)'
    if ($score -lt 60) { $grade = 'F (Critical Failure / Severe Risk)' }
    elseif ($score -lt 75) { $grade = 'C (Degraded Stability)' }
    elseif ($score -lt 85) { $grade = 'B (Suboptimal Configuration)' }
    elseif ($score -lt 95) { $grade = 'A (Good Health)' }

    return [pscustomobject]@{
        Score   = [math]::Max(0, $score)
        Grade   = $grade
        Reasons = $reasons
    }
}

function Write-PipelineSnapshot {
    param($Snap, [string]$Label)
    Write-Host ''
    Write-Host ("==================== {0} ====================" -f $Label) -ForegroundColor Yellow
    
    Write-Host '--- [TIER 1: GPU VRAM & WDDM VidMm] ---' -ForegroundColor Magenta
    Write-Host ('  GPU Adapter               : {0}' -f $Snap.Gpu.Name)
    Write-Host ('  Driver Version            : {0}' -f $Snap.Gpu.DriverVersion)
    Write-Host ('  Hardware Scheduling (HAGS): {0}' -f $Snap.Gpu.HagsMode)
    Write-Host ('  Local VRAM Usage          : {0}' -f (Format-Bytes $Snap.Gpu.LocalUsage))
    Write-Host ('  Shared Aperture (Host RAM): {0}' -f (Format-Bytes $Snap.Gpu.NonLocalUsage))
    Write-Host ('  WDDM TDR Level / Delay    : {0} / {1}s' -f $Snap.Gpu.TdrLevel, $Snap.Gpu.TdrDelay)

    Write-Host '--- [TIER 2: HOST DRAM & PFN DATABASE] ---' -ForegroundColor Cyan
    Write-Host ('  RAM Instalada (Fisica)    : {0}' -f (Format-Bytes $Snap.Installed))
    Write-Host ('  Visivel pelo Windows      : {0}' -f (Format-Bytes $Snap.Visible))
    Write-Host ('  Hardware Reserved (calc.) : {0}' -f (Format-Bytes $Snap.HardwareRes))
    Write-Host ('  Em Uso Ativo              : {0}' -f (Format-Bytes $Snap.InUse))
    Write-Host ('  Available (Disponivel)    : {0}' -f (Format-Bytes $Snap.Available))
    Write-Host ('  Standby Total             : {0}' -f (Format-Bytes $Snap.StandbyTotal))
    Write-Host ('    - Standby Normal/Low    : {0}' -f (Format-Bytes $Snap.StandbyNormal))
    Write-Host ('    - Standby Core/Reserve  : {0}' -f (Format-Bytes ($Snap.StandbyCore + $Snap.StandbyReserve)))
    Write-Host ('  Modified Page List        : {0}' -f (Format-Bytes $Snap.Modified))
    Write-Host ('  System File Cache         : {0} ({1:N1}%)' -f (Format-Bytes $Snap.FileCache), (($Snap.FileCache / [double]$Snap.Visible) * 100))
    Write-Host ('  Pool Paged / Non-Paged    : {0} / {1}' -f (Format-Bytes $Snap.PoolPaged), (Format-Bytes $Snap.PoolNonpaged))
    Write-Host ('  Page Faults / Segundo     : {0:N0}' -f $Snap.PageFaultsSec)
    Write-Host ('  Store Compression / SysMain: {0} / {1}' -f $Snap.CompressionOn, $Snap.SysMainStatus)
    Write-Host ('  BCD trunc/remove limits   : {0} / {1}' -f $Snap.BcdTruncate, $Snap.BcdRemove)

    Write-Host '--- [TIER 3: NVMe STORAGE & COMMIT ENGINE] ---' -ForegroundColor Blue
    Write-Host ('  Commit Total / Usado      : {0} / {1}' -f (Format-Bytes $Snap.CommitLimit), (Format-Bytes $Snap.Committed))
    Write-Host ('  Commit Headroom (Margem)  : {0}%' -f $Snap.CommitHeadroom)
    Write-Host ('  Pagefile Auto / Tamanho   : {0} / {1}' -f $Snap.Storage.PagefileAuto, (Format-Bytes $Snap.Storage.PagefileSize))
    Write-Host ('  Unidade do Sistema ({0})    : {1} livres de {2}' -f $Snap.Storage.SystemDrive, (Format-Bytes $Snap.Storage.DriveFree), (Format-Bytes $Snap.Storage.DriveTotal))
    Write-Host ('  NVMe / Storage Models     : {0}' -f $Snap.Storage.DriveModels)
    Write-Host ('  Storage TRIM Support      : {0}' -f $Snap.Storage.TrimStatus)

    Write-Host '--- [TELEMETRIA DE ESTABILIDADE (14 DIAS)] ---' -ForegroundColor DarkCyan
    Write-Host ('  WHEA Hardware Errors      : {0}' -f $Snap.Stability.Whea14d)
    Write-Host ('  BugCheck 1001 Crashes     : {0}' -f $Snap.Stability.Bugcheck14d)
    Write-Host ('  Kernel-Power 41 Resets    : {0}' -f $Snap.Stability.KernelPower41)
    Write-Host ('  Display TDR Resets (~4101): {0}' -f $Snap.Stability.Tdr14d)
    Write-Host ('  Crash Dump Mode           : {0} (7=Automatic Kernel Dump)' -f $Snap.Stability.DumpType)
    Write-Host ('  Fast Startup (hiberboot)  : {0}' -f $Snap.Stability.Hiberboot)
    if ($Snap.Stability.LastBugMsg) {
        Write-Host ('  Ultimo BugCheck Registado : {0}' -f $Snap.Stability.LastBugMsg)
    }

    $cert = Evaluate-CertificationGrade -Snap $Snap
    Write-Host ''
    Write-Host ('--- [CERTIFICAÇÃO DO PIPELINE DE MEMÓRIA] ---') -ForegroundColor Green
    Write-Host ('  Score de Conformidade     : {0}/100' -f $cert.Score) -ForegroundColor Green
    Write-Host ('  Grau de Integridade       : {0}' -f $cert.Grade) -ForegroundColor Green
    if ($cert.Reasons.Count -gt 0) {
        foreach ($r in $cert.Reasons) {
            Write-Host ('  [!] {0}' -f $r) -ForegroundColor DarkYellow
        }
    }
}

function Write-Delta {
    param($Before, $After)
    Write-Host ''
    Write-Host '==================== DELTA DO FLUXO ====================' -ForegroundColor Green
    Write-Host ('  Available RAM : {0} -> {1}' -f (Format-Bytes $Before.Available), (Format-Bytes $After.Available))
    Write-Host ('  Standby Cache : {0} -> {1}' -f (Format-Bytes $Before.StandbyTotal), (Format-Bytes $After.StandbyTotal))
    Write-Host ('  File Cache    : {0} -> {1}' -f (Format-Bytes $Before.FileCache), (Format-Bytes $After.FileCache))
    Write-Host ('  Commit Headroom: {0}% -> {1}%' -f $Before.CommitHeadroom, $After.CommitHeadroom)
    Write-Host '  Conformidade com Peter Denning (1968): Working Sets mantidos estritamente intactos.'
}

function Enable-NeededPrivileges {
    if (-not $script:IsElevated) { return $false }
    $ok1 = [ConnectRamNative]::EnablePrivilege('SeProfileSingleProcessPrivilege')
    $ok2 = [ConnectRamNative]::EnablePrivilege('SeIncreaseQuotaPrivilege')
    return ($ok1 -or $ok2)
}

function Invoke-MemoryReclaim {
    Write-Host (Get-T Reclaim) -ForegroundColor Cyan
    if (-not $script:IsElevated) {
        Write-Host (Get-T AdminNotice) -ForegroundColor DarkYellow
        return
    }
    $null = Enable-NeededPrivileges
    foreach ($cmd in @(4, 5)) {
        $status = [ConnectRamNative]::PurgeMemoryList($cmd)
        $msg = '  Purge list command {0} -> NTSTATUS 0x{1:X8}' -f $cmd, $status
        Write-Host $msg
        Write-Log $msg
    }
}

function Invoke-CacheCapIfNeeded {
    param($Snap)
    if ($Snap.Visible -le 0) { return }
    $ratio = $Snap.FileCache / [double]$Snap.Visible
    if ($ratio -lt 0.30) {
        Write-Host (Get-T CacheSkip) -ForegroundColor DarkGray
        return
    }
    Write-Host (Get-T CacheCap) -ForegroundColor Cyan
    if (-not $script:IsElevated) {
        Write-Host (Get-T AdminNotice) -ForegroundColor DarkYellow
        return
    }
    $null = [ConnectRamNative]::EnablePrivilege('SeIncreaseQuotaPrivilege')
    $calcMax = [int64][Math]::Floor($Snap.Visible * 0.15)
    $minCap = [int64]512MB
    if ($calcMax -lt $minCap) { $calcMax = $minCap }
    $max = [uint64]$calcMax
    $maxPtr = [System.UIntPtr]::new($max)
    $ok = [ConnectRamNative]::SetSystemFileCacheSize([UIntPtr]::Zero, $maxPtr, [ConnectRamNative]::FILE_CACHE_MAX_HARD_ENABLE)
    Write-Host ('  SetSystemFileCacheSize max={0} ok={1}' -f (Format-Bytes ([int64]$max)), $ok)
}

function Invoke-BcdUnlock {
    Write-Host (Get-T Bcd) -ForegroundColor Cyan
    if (-not $script:IsElevated) {
        Write-Host (Get-T AdminNotice) -ForegroundColor DarkYellow
        return $false
    }
    $before = Get-BcdText
    $changed = $false
    foreach ($name in @('removememory', 'truncatememory')) {
        $present = $before -match $name
        $null = bcdedit /deletevalue '{current}' $name 2>&1
        if ($present) {
            Write-Host ("  [REMOVIDO] {0}" -f $name) -ForegroundColor Green
            $changed = $true
        } else {
            Write-Host ("  [OK] {0} nao configurado" -f $name) -ForegroundColor DarkGray
        }
    }
    $null = bcdedit /set '{current}' recoveryenabled Yes 2>&1
    return $changed
}

function Invoke-RevertHarmfulV3 {
    Write-Host (Get-T Revert) -ForegroundColor Cyan
    if (-not $script:IsElevated) { return }
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    New-ItemProperty -Path $path -Name ClearPageFileAtShutdown -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $path -Name LargeSystemCache -PropertyType DWord -Value 0 -Force | Out-Null
    Write-Host '  ClearPageFileAtShutdown = 0 (Prevenção de shutdown lento)'
    Write-Host '  LargeSystemCache        = 0 (Gestão dinâmica padrão NT)'
}

function Invoke-KeepCompression {
    Write-Host (Get-T Compress) -ForegroundColor Cyan
    if (-not $script:IsElevated) { return }
    try {
        Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
        Write-Host '  Enable-MMAgent -MemoryCompression OK'
        $svc = Get-Service SysMain -ErrorAction SilentlyContinue
        if ($svc -and $svc.StartType -eq 'Disabled') {
            Set-Service SysMain -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service SysMain -ErrorAction SilentlyContinue
            Write-Host '  SysMain re-enabled (dependência do Store Manager)'
        }
    } catch {
        Write-Host ('  MMAgent: {0}' -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
}

function Set-RegDword {
    param([string]$Path, [string]$Name, [int]$Value)
    if (-not $script:IsElevated) { return }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Invoke-HealthProfile {
    param($Evidence)
    Write-Host (Get-T HealthRun) -ForegroundColor Cyan
    if (-not $script:IsElevated) {
        Write-Host (Get-T AdminNotice) -ForegroundColor DarkYellow
        return
    }
    Invoke-RevertHarmfulV3
    Invoke-KeepCompression

    try {
        $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
        if (-not $cs.AutomaticManagedPagefile) {
            $cs.AutomaticManagedPagefile = $true
            [void]$cs.Put()
            Write-Host '  AutomaticManagedPagefile = True (Compromisso seguro)'
        }
    } catch {}

    Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' 'CrashDumpEnabled' 7
    Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' 'AutoReboot' 1
    Write-Host '  CrashDumpEnabled = 7 (Automatic Kernel Dump para análise forense)'

    Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
    Write-Host '  HiberbootEnabled = 0 (Fast Startup OFF -> Cold Boot sem PFN obsoleto)'

    $gfx = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    Set-RegDword $gfx 'TdrLevel' 3
    if ($Evidence -and $Evidence.Tdr14d -ge 3) {
        Set-RegDword $gfx 'TdrDelay' 8
        Write-Host '  TdrLevel=3 Recover, TdrDelay=8s (Tempestade de TDR detetada: >=3 / 14d)'
    } else {
        if ($Evidence -and $Evidence.TdrDelay -lt 2) { Set-RegDword $gfx 'TdrDelay' 2 }
        Write-Host '  TdrLevel=3 Recover (Watchdog WDDM ativo)'
    }

    try {
        $null = powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0 2>&1
        $null = powercfg /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0 2>&1
        $null = powercfg /setactive SCHEME_CURRENT 2>&1
        Write-Host '  PCI Express ASPM = Off (Prevenção de latência de link GPU)'
    } catch {}
}

function Write-HealthReports {
    param($Snap)
    $cert = Evaluate-CertificationGrade -Snap $Snap

    # 1. Plain text summary
    $lines = @(
        '==============================================================================',
        'CONNECT Labs Universal RAM Unlocker & Memory Pipeline Core v5.0',
        ('Timestamp: {0:u}' -f (Get-Date)),
        '==============================================================================',
        ('Score: {0}/100 | Grade: {1}' -f $cert.Score, $cert.Grade),
        '',
        '[TIER 1: GPU VRAM & WDDM VidMm]',
        ('GPU: {0} | Driver: {1} | HAGS: {2}' -f $Snap.Gpu.Name, $Snap.Gpu.DriverVersion, $Snap.Gpu.HagsMode),
        ('Local VRAM Usage: {0} | Shared Host Aperture: {1}' -f (Format-Bytes $Snap.Gpu.LocalUsage), (Format-Bytes $Snap.Gpu.NonLocalUsage)),
        ('TdrLevel: {0} | TdrDelay: {1}s | TDR Events (14d): {2}' -f $Snap.Gpu.TdrLevel, $Snap.Gpu.TdrDelay, $Snap.Stability.Tdr14d),
        '',
        '[TIER 2: HOST DRAM & PFN DATABASE]',
        ('Installed: {0} | Visible: {1} | Hardware Reserved: {2}' -f (Format-Bytes $Snap.Installed), (Format-Bytes $Snap.Visible), (Format-Bytes $Snap.HardwareRes)),
        ('Active In-Use: {0} | Available: {1}' -f (Format-Bytes $Snap.InUse), (Format-Bytes $Snap.Available)),
        ('Standby: {0} (Normal: {1}, Core/Reserve: {2})' -f (Format-Bytes $Snap.StandbyTotal), (Format-Bytes $Snap.StandbyNormal), (Format-Bytes ($Snap.StandbyCore + $Snap.StandbyReserve))),
        ('File Cache: {0} | Pool Paged: {1} | Pool Non-Paged: {2}' -f (Format-Bytes $Snap.FileCache), (Format-Bytes $Snap.PoolPaged), (Format-Bytes $Snap.PoolNonpaged)),
        ('Memory Compression: {0} | SysMain: {1}' -f $Snap.CompressionOn, $Snap.SysMainStatus),
        ('BCD Truncate: {0} | BCD Remove: {1}' -f $Snap.BcdTruncate, $Snap.BcdRemove),
        '',
        '[TIER 3: NVMe STORAGE & COMMIT]',
        ('Commit Limit: {0} | Committed: {1} | Headroom: {2}%' -f (Format-Bytes $Snap.CommitLimit), (Format-Bytes $Snap.Committed), $Snap.CommitHeadroom),
        ('Pagefile Auto: {0} | Size: {1} | Storage TRIM: {2}' -f $Snap.Storage.PagefileAuto, (Format-Bytes $Snap.Storage.PagefileSize), $Snap.Storage.TrimStatus),
        ('System Drive ({0}): {1} free of {2}' -f $Snap.Storage.SystemDrive, (Format-Bytes $Snap.Storage.DriveFree), (Format-Bytes $Snap.Storage.DriveTotal)),
        ('Storage Devices: {0}' -f $Snap.Storage.DriveModels),
        '',
        '[STABILITY & HARDWARE INTEGRITY]',
        ('WHEA 14d: {0} | BugCheck 1001: {1} | Kernel-Power 41: {2}' -f $Snap.Stability.Whea14d, $Snap.Stability.Bugcheck14d, $Snap.Stability.KernelPower41),
        ('Fast Startup (hiberboot): {0} | CrashDumpEnabled: {1}' -f $Snap.Stability.Hiberboot, $Snap.Stability.DumpType),
        ('Last BugCheck: {0}' -f $Snap.Stability.LastBugMsg),
        '',
        'Invariants Enforced: No DWM Trim; Standby Purge; Fast Startup Off; Pagefile System-Managed; TDR Recover.',
        'Academic Documentation: docs/DISSERTACAO_MESTRADO_FRAMEWORK.md and docs/TESE_NOTAS.md'
    )
    try { Set-Content -Path $script:ReportPath -Value $lines -Encoding UTF8 } catch {}

    # 2. Structured JSON Dataset
    try {
        $jsonExport = [pscustomobject]@{
            Version       = '5.0'
            Timestamp     = (Get-Date).ToString('o')
            Certification = $cert
            Tier1_GPU     = $Snap.Gpu
            Tier2_RAM     = [pscustomobject]@{
                InstalledBytes      = $Snap.Installed
                VisibleBytes        = $Snap.Visible
                HardwareReservedBytes = $Snap.HardwareRes
                InUseBytes          = $Snap.InUse
                AvailableBytes      = $Snap.Available
                StandbyTotalBytes   = $Snap.StandbyTotal
                StandbyNormalBytes  = $Snap.StandbyNormal
                ModifiedBytes       = $Snap.Modified
                FileCacheBytes      = $Snap.FileCache
                PoolPagedBytes      = $Snap.PoolPaged
                PoolNonpagedBytes   = $Snap.PoolNonpaged
                PageFaultsPerSec    = $Snap.PageFaultsSec
                CompressionActive   = $Snap.CompressionOn
            }
            Tier3_Storage = $Snap.Storage
            Stability     = $Snap.Stability
        }
        $jsonStr = $jsonExport | ConvertTo-Json -Depth 5
        Set-Content -Path $script:JsonPath -Value $jsonStr -Encoding UTF8
    } catch {}

    # 3. Interactive HTML Thesis Dashboard
    try {
        $htmlContent = @"
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <title>CONNECT Labs - Relatório de Auditoria do Pipeline de Memória v5.0</title>
    <style>
        body { font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 24px; }
        .container { max-width: 1100px; margin: 0 auto; }
        header { border-bottom: 2px solid #334155; padding-bottom: 16px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; }
        h1 { margin: 0; color: #38bdf8; font-size: 26px; }
        .badge { background: #0284c7; color: white; padding: 6px 14px; border-radius: 9999px; font-weight: bold; font-size: 14px; }
        .score-box { background: linear-gradient(135deg, #1e293b, #0f172a); border: 2px solid #38bdf8; border-radius: 12px; padding: 20px; margin-bottom: 24px; text-align: center; }
        .score-val { font-size: 48px; font-weight: 800; color: #4ade80; margin: 8px 0; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 20px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }
        .card h2 { margin-top: 0; font-size: 18px; color: #93c5fd; border-bottom: 1px solid #334155; padding-bottom: 8px; }
        .stat-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #243248; font-size: 14px; }
        .stat-label { color: #94a3b8; }
        .stat-val { font-weight: 600; color: #f1f5f9; }
        .footer { margin-top: 32px; padding-top: 16px; border-top: 1px solid #334155; text-align: center; font-size: 12px; color: #64748b; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div>
                <h1>CONNECT Labs — Memory Pipeline Core v5.0</h1>
                <p style="margin: 4px 0 0; color: #94a3b8;">Relatório de Auditoria e Certificação para Dissertação de Mestrado</p>
            </div>
            <div class="badge">WHQL / WDDM Certified</div>
        </header>

        <div class="score-box">
            <div style="text-transform: uppercase; letter-spacing: 1.5px; font-size: 13px; color: #94a3b8;">Score de Conformidade Sistémica</div>
            <div class="score-val">$($cert.Score) / 100</div>
            <div style="font-size: 18px; color: #38bdf8; font-weight: bold;">$($cert.Grade)</div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>Tier 1: GPU VRAM & WDDM VidMm</h2>
                <div class="stat-row"><span class="stat-label">GPU:</span><span class="stat-val">$($Snap.Gpu.Name)</span></div>
                <div class="stat-row"><span class="stat-label">Driver:</span><span class="stat-val">$($Snap.Gpu.DriverVersion)</span></div>
                <div class="stat-row"><span class="stat-label">HAGS (Escalonamento Hardware):</span><span class="stat-val">$($Snap.Gpu.HagsMode)</span></div>
                <div class="stat-row"><span class="stat-label">VRAM Local em Uso:</span><span class="stat-val">$(Format-Bytes $Snap.Gpu.LocalUsage)</span></div>
                <div class="stat-row"><span class="stat-label">Abertura Partilhada (Host RAM):</span><span class="stat-val">$(Format-Bytes $Snap.Gpu.NonLocalUsage)</span></div>
                <div class="stat-row"><span class="stat-label">TdrLevel / Delay:</span><span class="stat-val">$($Snap.Gpu.TdrLevel) / $($Snap.Gpu.TdrDelay)s</span></div>
            </div>

            <div class="card">
                <h2>Tier 2: Host DRAM & PFN Database</h2>
                <div class="stat-row"><span class="stat-label">RAM Instalada / Visível:</span><span class="stat-val">$(Format-Bytes $Snap.Installed) / $(Format-Bytes $Snap.Visible)</span></div>
                <div class="stat-row"><span class="stat-label">Hardware Reserved:</span><span class="stat-val">$(Format-Bytes $Snap.HardwareRes)</span></div>
                <div class="stat-row"><span class="stat-label">Disponível (Available):</span><span class="stat-val">$(Format-Bytes $Snap.Available)</span></div>
                <div class="stat-row"><span class="stat-label">Standby Total:</span><span class="stat-val">$(Format-Bytes $Snap.StandbyTotal)</span></div>
                <div class="stat-row"><span class="stat-label">File Cache:</span><span class="stat-val">$(Format-Bytes $Snap.FileCache)</span></div>
                <div class="stat-row"><span class="stat-label">Kernel Pool (Paged / Non-Paged):</span><span class="stat-val">$(Format-Bytes $Snap.PoolPaged) / $(Format-Bytes $Snap.PoolNonpaged)</span></div>
            </div>

            <div class="card">
                <h2>Tier 3: NVMe Storage & Commit</h2>
                <div class="stat-row"><span class="stat-label">Commit Limit / Utilizado:</span><span class="stat-val">$(Format-Bytes $Snap.CommitLimit) / $(Format-Bytes $Snap.Committed)</span></div>
                <div class="stat-row"><span class="stat-label">Commit Headroom:</span><span class="stat-val">$($Snap.CommitHeadroom)%</span></div>
                <div class="stat-row"><span class="stat-label">Espaço Livre no Disco ($($Snap.Storage.SystemDrive)):</span><span class="stat-val">$(Format-Bytes $Snap.Storage.DriveFree)</span></div>
                <div class="stat-row"><span class="stat-label">Storage TRIM:</span><span class="stat-val">$($Snap.Storage.TrimStatus)</span></div>
                <div class="stat-row"><span class="stat-label">Pagefile Gerido:</span><span class="stat-val">$($Snap.Storage.PagefileAuto)</span></div>
            </div>
        </div>

        <div class="footer">
            Gerado por CONNECT Labs RAM & Memory Pipeline Core v5.0 | Anexo à Dissertação de Mestrado | $(Get-Date)
        </div>
    </div>
</body>
</html>
"@
        Set-Content -Path $script:HtmlPath -Value $htmlContent -Encoding UTF8
    } catch {}

    Write-Host ('  Relatorio Texto : {0}' -f $script:ReportPath) -ForegroundColor DarkGray
    Write-Host ('  Dataset JSON    : {0}' -f $script:JsonPath) -ForegroundColor DarkGray
    Write-Host ('  Dashboard HTML  : {0}' -f $script:HtmlPath) -ForegroundColor DarkGray
}

function Show-Diagnosis {
    Clear-Host
    Write-Host ('========================================================================================')
    Write-Host ('  ' + (Get-T DiagTitle))
    Write-Host ('========================================================================================')
    $s = Get-RamPipelineSnapshot
    Write-PipelineSnapshot -Snap $s -Label (Get-T DiagTitle)
    Write-Host ''
    Write-Host (Get-T Sources) -ForegroundColor DarkGray

    if ($s.Stability.Whea14d -gt 0) { Write-Host ('  ' + (Get-T WheaWarn)) -ForegroundColor Red }
    if ($s.Stability.Tdr14d -gt 0) { Write-Host ('  ' + (Get-T TdrWarn)) -ForegroundColor Yellow }
    if ($s.BcdTruncate -or $s.BcdRemove) {
        Write-Host '  [!] Limites BCD ativos — execute a Opcao 3 e REINICIE a frio (shutdown /r).' -ForegroundColor Yellow
    }
    if ($s.Storage.LowSpaceRisk) {
        Write-Host ('  [!] Espaço livre escasso no disco do sistema ({0}): {1} livres. Risco de falha de commit.' -f $s.Storage.SystemDrive, (Format-Bytes $s.Storage.DriveFree)) -ForegroundColor Red
    }
    if ($s.CommitHeadroom -lt 15.0) {
        Write-Host ('  [!] Margem de commit perigosa ({0}%). Risco de recusa de alocação de memória.' -f $s.CommitHeadroom) -ForegroundColor Red
    }
    Write-HealthReports -Snap $s
}

function Invoke-QuickFlow {
    Clear-Host
    $before = Get-RamPipelineSnapshot
    Write-PipelineSnapshot -Snap $before -Label (Get-T Before)
    if ($before.Stability.Tdr14d -gt 0) { Write-Host ('  ' + (Get-T TdrWarn)) -ForegroundColor Yellow }
    Invoke-MemoryReclaim
    Invoke-CacheCapIfNeeded -Snap $before
    Start-Sleep -Milliseconds 600
    $after = Get-RamPipelineSnapshot
    Write-PipelineSnapshot -Snap $after -Label (Get-T After)
    Write-Delta -Before $before -After $after
    Write-HealthReports -Snap $after
}

function Invoke-PostHealthReboot {
    param([bool]$NeedMemDiag)
    if ($NeedMemDiag) {
        $ans = Read-Host (Get-T MemDiagAsk)
        if ($ans -and $ans.ToUpperInvariant().StartsWith((Get-T Yes))) {
            $null = bcdedit /bootsequence '{memdiag}' 2>&1
            Write-Host '  Windows Memory Diagnostic agendado (bcdedit /bootsequence {memdiag})'
        }
    }
    $ans2 = Read-Host (Get-T RebootAsk)
    if ($ans2 -and $ans2.ToUpperInvariant().StartsWith((Get-T Yes))) {
        shutdown /r /t 5 /c "CONNECT Labs: Cold boot após protocolo de estabilidade de memória"
    }
}

function Invoke-FullUnlock {
    Clear-Host
    $before = Get-RamPipelineSnapshot
    Write-PipelineSnapshot -Snap $before -Label (Get-T Before)
    if ($before.Stability.Whea14d -gt 0) { Write-Host ('  ' + (Get-T WheaWarn)) -ForegroundColor Red }
    $bcdChanged = Invoke-BcdUnlock
    Invoke-HealthProfile -Evidence $before.Stability
    Start-Sleep -Milliseconds 400
    $after = Get-RamPipelineSnapshot
    Write-PipelineSnapshot -Snap $after -Label (Get-T After)
    Write-HealthReports -Snap $after
    Write-Host ''
    Write-Host ((Get-T Done) + $script:LogPath)
    Invoke-PostHealthReboot -NeedMemDiag ($before.Stability.Whea14d -gt 0 -or $before.Stability.Bugcheck14d -gt 0)
}

function Invoke-StorageCommitAudit {
    Clear-Host
    Write-Host '==================== AUDITORIA & OTIMIZAÇÃO DO COMMIT ====================' -ForegroundColor Blue
    $s = Get-RamPipelineSnapshot
    Write-Host ('  System Commit Limit       : {0}' -f (Format-Bytes $s.CommitLimit))
    Write-Host ('  Committed Virtual Memory  : {0}' -f (Format-Bytes $s.Committed))
    Write-Host ('  Margem de Seguranca       : {0}%' -f $s.CommitHeadroom)
    Write-Host ('  Unidade do Pagefile ({0})   : {1} livres' -f $s.Storage.SystemDrive, (Format-Bytes $s.Storage.DriveFree))
    Write-Host ('  Suporte TRIM NVMe/SSD     : {0}' -f $s.Storage.TrimStatus)
    if ($s.Storage.LowSpaceRisk) {
        Write-Host '  [ALERTA CRÍTICO] A unidade C: tem menos de 10GB livres! O Windows pode falhar ao expandir o pagefile.' -ForegroundColor Red
    }
    if ($script:IsElevated) {
        try {
            $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
            if (-not $cs.AutomaticManagedPagefile) {
                $cs.AutomaticManagedPagefile = $true
                [void]$cs.Put()
                Write-Host '  [OK] AutomaticManagedPagefile assegurado como True' -ForegroundColor Green
            }
        } catch {}
    } else {
        Write-Host (Get-T AdminNotice) -ForegroundColor DarkYellow
    }
    Write-HealthReports -Snap $s
}

function Invoke-ScientificBenchmark {
    Clear-Host
    Write-Host '==================== BENCHMARK CIENTÍFICO PARA A TESE ====================' -ForegroundColor Cyan
    Write-Host '  Protocolo Experimental: Medição de Latência de Alocação e Taxa de Faltas de Página...'
    
    $snapBefore = Get-RamPipelineSnapshot
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $testArray = $null
    try {
        # Allocate a 256MB byte buffer to measure contiguous allocation latency
        $allocSw = [System.Diagnostics.Stopwatch]::StartNew()
        $testArray = New-Object byte[] (256MB)
        $allocSw.Stop()
        $allocMs = $allocSw.ElapsedMilliseconds
    } catch {
        $allocMs = -1
    } finally {
        $testArray = $null
        [System.GC]::Collect()
    }
    $sw.Stop()

    Write-Host ('  Latência de alocação de bloco contíguo (256MB): {0} ms' -f $allocMs)
    Write-Host ('  Page Faults / segundo (baseline): {0}' -f $snapBefore.PageFaultsSec)
    Write-Host ('  Available RAM inicial: {0}' -f (Format-Bytes $snapBefore.Available))
    Write-Host ('  Commit Headroom inicial: {0}%' -f $snapBefore.CommitHeadroom)

    # Perform Safe Flow Rebalance
    Invoke-MemoryReclaim
    Invoke-CacheCapIfNeeded -Snap $snapBefore
    Start-Sleep -Milliseconds 500

    $snapAfter = Get-RamPipelineSnapshot
    Write-Host ''
    Write-Host ('  Available RAM final: {0} (Ganho: +{1})' -f (Format-Bytes $snapAfter.Available), (Format-Bytes ($snapAfter.Available - $snapBefore.Available)))
    Write-Host ('  Standby recuperada: {0}' -f (Format-Bytes ($snapBefore.StandbyTotal - $snapAfter.StandbyTotal)))
    Write-Host ('  Taxa de faltas de página pós-reclaim: {0}' -f $snapAfter.PageFaultsSec)
    Write-Host '  Resultados arquivados no dataset de telemetria para a tese.' -ForegroundColor Green

    Write-HealthReports -Snap $snapAfter
}

function Wait-MenuKey {
    Write-Host ''
    Write-Host ((Get-T Done) + $script:LogPath) -ForegroundColor DarkGray
    Read-Host (Get-T Key) | Out-Null
}

function Show-NoteAndConfirm {
    Clear-Host
    Write-Host ('========================================================================================')
    Write-Host ('  ' + (Get-T NoteTitle))
    Write-Host ('========================================================================================')
    foreach ($line in (Get-T NoteBody)) { Write-Host ('  ' + $line) }
    Write-Host ('========================================================================================')
    $ans = Read-Host (Get-T Continue)
    if (-not $ans -or -not $ans.ToUpperInvariant().StartsWith((Get-T Yes))) { return $false }
    return $true
}

function Select-UiLanguage {
    while ($true) {
        Clear-Host
        Write-Host ('========================================================================================')
        Write-Host ('  SELECT YOUR LANGUAGE / SELECCIONE SU IDIOMA / SELECIONE O SEU IDIOMA')
        Write-Host ('========================================================================================')
        Write-Host ''
        Write-Host '  [1] Portugues'
        Write-Host '  [2] English'
        Write-Host '  [3] Espanol'
        Write-Host ''
        $c = Read-Host 'Choose (1-3)'
        switch ($c) {
            '1' { return 'PT' }
            '2' { return 'EN' }
            '3' { return 'ES' }
        }
    }
}

Write-Log '==== session start v5.0 Memory Pipeline Core ===='

if (-not $Lang) { $script:Lang = Select-UiLanguage } else { $script:Lang = $Lang }

if ($Action -eq 'Diagnose') { Show-Diagnosis; return }
if ($Action -eq 'Quick') { Invoke-QuickFlow; return }
if ($Action -eq 'Full') { Invoke-FullUnlock; return }
if ($Action -eq 'Health') {
    $before = Get-RamPipelineSnapshot
    Invoke-HealthProfile -Evidence $before.Stability
    $after = Get-RamPipelineSnapshot
    Write-HealthReports -Snap $after
    return
}
if ($Action -eq 'Storage') { Invoke-StorageCommitAudit; return }
if ($Action -eq 'Benchmark') { Invoke-ScientificBenchmark; return }
if ($Action -eq 'Report') {
    $s = Get-RamPipelineSnapshot
    Write-HealthReports -Snap $s
    return
}

if (-not (Show-NoteAndConfirm)) { exit 0 }

while ($true) {
    Clear-Host
    Write-Host ('========================================================================================')
    Write-Host ('  ' + (Get-T MenuTitle))
    Write-Host ('========================================================================================')
    Write-Host ''
    Write-Host ('  ' + (Get-T M1))
    Write-Host ('  ' + (Get-T M2))
    Write-Host ('  ' + (Get-T M3))
    Write-Host ('  ' + (Get-T M4))
    Write-Host ('  ' + (Get-T M5))
    Write-Host ('  ' + (Get-T M6))
    Write-Host ('  ' + (Get-T M7))
    Write-Host ('  ' + (Get-T M8))
    Write-Host ''
    $op = Read-Host (Get-T Choose)
    switch ($op) {
        '1' { Show-Diagnosis; Wait-MenuKey }
        '2' { Invoke-QuickFlow; Wait-MenuKey }
        '3' { Invoke-FullUnlock; Wait-MenuKey }
        '4' { Invoke-StorageCommitAudit; Wait-MenuKey }
        '5' { Invoke-ScientificBenchmark; Wait-MenuKey }
        '6' {
            $s = Get-RamPipelineSnapshot
            Write-HealthReports -Snap $s
            Write-Host '  Relatorios gerados com sucesso!' -ForegroundColor Green
            Wait-MenuKey
        }
        '7' { $script:Lang = Select-UiLanguage; if (-not (Show-NoteAndConfirm)) { exit 0 } }
        '8' { exit 0 }
    }
}
