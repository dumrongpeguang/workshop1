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

ติดตั้งโมดูล Microsoft Graph (ครั้งเดียว):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

## 2. การ Deploy สคริปต์

### 2.1 Clone repository ลงเครื่องที่ใช้งาน (Admin Workstation หรือ Jump Server)

```powershell
git clone <repository-url> C:\IT-Automation
```

### 2.2 (ทางเลือก) Deploy ไปยังเครื่องอื่นด้วย Copy/Robocopy

```powershell
robocopy C:\IT-Automation \\FILESERVER\Scripts\IT-Automation /MIR
```

### 2.3 ตั้งค่า Execution Policy

โดย default เครื่อง Windows จะ block การรันสคริปต์ที่ไม่ได้ลงนาม ให้ตั้งค่าที่เครื่องที่จะรันสคริปต์:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

> หมายเหตุด้านความปลอดภัย: หลีกเลี่ยงการตั้งเป็น `Unrestricted` แบบ `LocalMachine` เพราะเปิดช่องให้สคริปต์ที่ไม่รู้ที่มารันได้ทั้งเครื่อง ใช้ `RemoteSigned` และจำกัด scope เป็น `CurrentUser` หรือ `Process` เท่าที่จำเป็น

### 2.4 (ทางเลือก) Unblock ไฟล์ที่ดาวน์โหลดมาจากอินเทอร์เน็ต

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
| `...cannot be loaded because running scripts is disabled` | Execution Policy ปิดกั้น | รันคำสั่งใน 2.3 |
| `Access Denied` เมื่อรันแบบ Remote | สิทธิ์ไม่พอ หรือ WinRM ปิดอยู่ | ตรวจสอบสิทธิ์ Admin และเปิด WinRM (`Enable-PSRemoting`) |
| Microsoft365 scripts ค้างที่หน้า login | ยังไม่ได้ authenticate หรือ token หมดอายุ | รัน `Disconnect-MgGraph` แล้วรันสคริปต์ใหม่ |
| Module `Microsoft.Graph` ไม่พบ | ยังไม่ได้ติดตั้งโมดูล | รันคำสั่งติดตั้งใน หัวข้อ 1 |
