# คู่มือการ Deploy และการใช้งาน (Deployment & Usage Manual)

คู่มือนี้อธิบายวิธีนำสคริปต์ในโฟลเดอร์ `IT-Automation` ไปติดตั้งและใช้งานจริงบนเครื่อง/เซิร์ฟเวอร์ปลายทาง

## 1. ข้อกำหนดเบื้องต้น (Prerequisites)

| รายการ | รายละเอียด |
|---|---|
| OS | Windows 10/11 หรือ Windows Server 2016+ |
| PowerShell | Windows PowerShell 5.1 ขึ้นไป หรือ PowerShell 7+ |
| สิทธิ์ | Local Administrator (สำหรับสคริปต์ที่ต้องจัดการ Service/Remote) |
| โมดูลเสริม | `Microsoft.Graph` (เฉพาะสคริปต์ในโฟลเดอร์ `Microsoft365`) |
| เครือข่าย | WinRM เปิดใช้งานบนเครื่องปลายทาง หากต้องรันแบบ Remote (`-ComputerName`) |
| สิทธิ์ Remote CIM/WMI | บัญชีที่รันสคริปต์ต้องอยู่ใน local `Administrators` group ของเครื่องปลายทาง และ firewall ต้องเปิด rule "Windows Management Instrumentation (WMI)" |

ติดตั้งโมดูล Microsoft Graph (ครั้งเดียว):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

## 2. การ Deploy สคริปต์

### 2.1 ติดตั้ง Git (ถ้ายังไม่มี)

ถ้ารันคำสั่ง `git --version` แล้วขึ้น error เช่น `'git' is not recognized as an internal or external command` แปลว่าเครื่องยังไม่ได้ติดตั้ง Git ให้ติดตั้งก่อนตามระบบปฏิบัติการ:

**Windows** (เลือกวิธีใดวิธีหนึ่ง):

```powershell
# ใช้ winget (Windows 10/11)
winget install --id Git.Git -e --source winget

# หรือใช้ Chocolatey
choco install git -y
```

หรือดาวน์โหลดตัวติดตั้งจาก https://git-scm.com/download/win แล้วรันแบบ Next-Next-Finish

**Linux (Debian/Ubuntu):**

```bash
sudo apt update && sudo apt install -y git
```

หลังติดตั้งเสร็จ ให้**เปิด terminal ใหม่**แล้วตรวจสอบอีกครั้ง:

```powershell
git --version
```

ถ้ายังขึ้น error หลังติดตั้งแล้ว ให้ตรวจสอบว่า path ของ Git (เช่น `C:\Program Files\Git\cmd`) ถูกเพิ่มใน environment variable `PATH` หรือยัง แล้ว restart เครื่อง/terminal อีกครั้ง

### 2.2 Clone repository ลงเครื่องที่ใช้งาน (Admin Workstation หรือ Jump Server)

```powershell
git clone <repository-url> C:\IT-Automation
```

### 2.3 (ทางเลือก) Deploy ไปยังเครื่องอื่นด้วย Copy/Robocopy

```powershell
robocopy C:\IT-Automation \\FILESERVER\Scripts\IT-Automation /MIR
```

### 2.4 ตั้งค่า Execution Policy

โดย default เครื่อง Windows จะ block การรันสคริปต์ที่ไม่ได้ลงนาม ให้ตั้งค่าที่เครื่องที่จะรันสคริปต์:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

> หมายเหตุด้านความปลอดภัย: หลีกเลี่ยงการตั้งเป็น `Unrestricted` แบบ `LocalMachine` เพราะเปิดช่องให้สคริปต์ที่ไม่รู้ที่มารันได้ทั้งเครื่อง ใช้ `RemoteSigned` และจำกัด scope เป็น `CurrentUser` หรือ `Process` เท่าที่จำเป็น

### 2.5 (ทางเลือก) Unblock ไฟล์ที่ดาวน์โหลดมาจากอินเทอร์เน็ต

```powershell
Get-ChildItem -Path C:\IT-Automation -Recurse -Filter *.ps1 | Unblock-File
```

## 3. วิธีใช้งานแต่ละกลุ่มสคริปต์

### 3.1 PowerShell (การดูแลระบบทั่วไป)

```powershell
# ตรวจพื้นที่ดิสก์ พร้อมแจ้งเตือนเมื่อเหลือน้อยกว่า 20%
.\IT-Automation\PowerShell\Check-DiskSpace.ps1 -ComputerName SRV01,SRV02 -ThresholdPercent 20

# ตรวจสถานะ Service และสั่ง restart อัตโนมัติถ้าหยุดทำงาน
.\IT-Automation\PowerShell\Check-Service.ps1 -ServiceName Spooler,BITS -AutoRestart

# ดึงข้อมูลเครื่อง (OS, Hardware, Boot time)
.\IT-Automation\PowerShell\Get-ComputerInfo.ps1 -ComputerName SRV01

# Restart Print Spooler พร้อมล้างคิวพิมพ์
.\IT-Automation\PowerShell\Restart-Spooler.ps1 -ComputerName PRINTSRV01 -ClearQueue
```

### 3.2 Network (ตรวจสอบระบบเครือข่าย)

```powershell
# ทดสอบ ping
.\IT-Automation\Network\Ping-Test.ps1 -ComputerName google.com,8.8.8.8

# ทดสอบ DNS resolve
.\IT-Automation\Network\DNS-Test.ps1 -ComputerName example.com -RecordType MX

# ทดสอบ TCP Port
.\IT-Automation\Network\Port-Test.ps1 -ComputerName SRV01 -Port 80,443,3389
```

### 3.3 Microsoft365 (ต้อง Connect-MgGraph ก่อน สคริปต์จะขอ sign-in ให้อัตโนมัติ)

```powershell
# ตรวจสถานะ MFA ของผู้ใช้
.\IT-Automation\Microsoft365\Check-MFA.ps1 -UserPrincipalName user@contoso.com

# ออกรายงาน License ทั้งหมด และ export เป็น CSV
.\IT-Automation\Microsoft365\User-License-Report.ps1 -OutputPath C:\Reports\Licenses.csv
```

## 4. การตั้งเวลารันอัตโนมัติ (Scheduling)

ใช้ Windows Task Scheduler เพื่อรันสคริปต์เป็นรอบ เช่น ตรวจ Disk Space ทุกวันตอน 07:00:

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\IT-Automation\PowerShell\Check-DiskSpace.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 7:00AM
Register-ScheduledTask -TaskName "Check-DiskSpace" -Action $action -Trigger $trigger -RunLevel Highest
```

## 5. ความปลอดภัย (Security Notes)

- ห้าม hardcode username/password ในสคริปต์ ให้ใช้ `Get-Credential`, Windows Credential Manager หรือ Managed Identity/Service Principal แทน
- บัญชีที่ใช้รัน Scheduled Task ควรใช้สิทธิ์ต่ำสุดเท่าที่จำเป็น (least privilege) ไม่ใช้ Domain Admin
- สคริปต์กลุ่ม Microsoft365 ควรใช้ App Registration พร้อม certificate-based auth สำหรับการรันแบบ unattended แทนการ login แบบ interactive
- เก็บ log การรันสคริปต์ (เช่น `Start-Transcript`) ไว้ตรวจสอบย้อนหลัง

## 6. การแก้ปัญหาเบื้องต้น (Troubleshooting)

| อาการ | สาเหตุที่เป็นไปได้ | วิธีแก้ |
|---|---|---|
| `'git' is not recognized as an internal or external command` | ยังไม่ได้ติดตั้ง Git หรือติดตั้งแล้วแต่ PATH ไม่ถูกอัปเดต | ติดตั้ง Git ตามขั้นตอนใน 2.1 แล้วเปิด terminal ใหม่ |
| `...cannot be loaded because running scripts is disabled` | Execution Policy ปิดกั้น | รันคำสั่งใน 2.4 |
| `WARNING: Unable to query <computer> : Access is denied` | รันสคริปต์แบบไม่ใช่ Admin, บัญชีไม่มีสิทธิ์บนเครื่องปลายทาง, หรือ firewall/DCOM ปิดกั้น WMI | ดูวิธีแก้แบบละเอียดใน 6.1 |
| `Access Denied` เมื่อรันแบบ Remote | สิทธิ์ไม่พอ หรือ WinRM ปิดอยู่ | ตรวจสอบสิทธิ์ Admin และเปิด WinRM (`Enable-PSRemoting`) |
| Microsoft365 scripts ค้างที่หน้า login | ยังไม่ได้ authenticate หรือ token หมดอายุ | รัน `Disconnect-MgGraph` แล้วรันสคริปต์ใหม่ |
| Module `Microsoft.Graph` ไม่พบ | ยังไม่ได้ติดตั้งโมดูล | รันคำสั่งติดตั้งใน หัวข้อ 1 |

### 6.1 แก้ปัญหา `Access is denied` ตอนใช้ `Check-DiskSpace.ps1` / `Get-ComputerInfo.ps1`

Error นี้เกิดจาก `Get-CimInstance` เรียกไปที่เครื่องปลายทาง (`-ComputerName`) แล้วถูกปฏิเสธสิทธิ์ ให้ไล่เช็คตามลำดับ:

1. **รัน PowerShell แบบ Run as Administrator** — คลิกขวา PowerShell แล้วเลือก "Run as administrator" ก่อนรันสคริปต์อีกครั้ง
2. **ตรวจสอบว่าบัญชีที่ใช้รันอยู่ใน local Administrators group ของเครื่องปลายทาง** เช่น `A-144848`:
   ```powershell
   Invoke-Command -ComputerName A-144848 -ScriptBlock { net localgroup Administrators }
   ```
3. **ถ้าใช้บัญชี local (ไม่ใช่ domain account)** Windows จะ block remote admin token โดย default (UAC remote restriction) ต้องตั้งค่านี้บนเครื่องปลายทางแล้ว restart:
   ```powershell
   New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
       -Name LocalAccountTokenFilterPolicy -PropertyType DWord -Value 1 -Force
   ```
4. **เปิด Firewall rule สำหรับ WMI** บนเครื่องปลายทาง:
   ```powershell
   Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"
   ```
5. **ทดสอบว่าเครื่องปลายทางเข้าถึงได้จริง** ก่อนรันสคริปต์ซ้ำ:
   ```powershell
   Test-NetConnection -ComputerName A-144848 -Port 135
   Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName A-144848
   ```
6. ถ้ายัง Access Denied อยู่ ให้ตรวจสอบว่าเครื่องปลายทางไม่ได้ถูกจำกัดด้วย Group Policy (เช่น "Network access: Sharing and security model" หรือ WMI namespace security ที่ถูกปรับแต่งไว้)
