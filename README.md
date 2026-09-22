# workshop1

## IT Script & Automation Repository

ที่เก็บรวมสคริปต์ PowerShell / Batch / Python ไว้ที่เดียว ใช้สำหรับงาน IT operations และ automation ต่างๆ

```
IT-Automation
│
├── PowerShell
│   ├── Check-DiskSpace.ps1
│   ├── Check-Service.ps1
│   ├── Get-ComputerInfo.ps1
│   └── Restart-Spooler.ps1
│
├── Network
│   ├── Ping-Test.ps1
│   ├── DNS-Test.ps1
│   └── Port-Test.ps1
│
└── Microsoft365
    ├── Check-MFA.ps1
    └── User-License-Report.ps1
```

### PowerShell
- **Check-DiskSpace.ps1** — เช็คพื้นที่ดิสก์ที่เหลือทั้งเครื่อง local/remote แล้วแจ้งเตือนถ้าต่ำกว่าเกณฑ์ที่ตั้งไว้
- **Check-Service.ps1** — เช็คสถานะ Windows service และสั่ง auto-restart ได้ถ้า service หยุดทำงาน
- **Get-ComputerInfo.ps1** — ดึงข้อมูล hardware, OS, BIOS จากเครื่อง local/remote
- **Restart-Spooler.ps1** — restart Print Spooler service พร้อมเคลียร์คิวพิมพ์ได้ถ้าต้องการ

### Network
- **Ping-Test.ps1** — เทส ICMP connectivity ไปยัง host ที่ระบุ
- **DNS-Test.ps1** — resolve DNS record (A, AAAA, CNAME, MX, TXT, NS) ของ hostname ที่ระบุ
- **Port-Test.ps1** — เทส TCP port connectivity ไปยัง host ที่ระบุ

### Microsoft365
- **Check-MFA.ps1** — เช็คสถานะการลงทะเบียน MFA ของ user ใน Microsoft 365 (ต้องมี Microsoft Graph module)
- **User-License-Report.ps1** — ออกรายงาน license ที่ user แต่ละคนถืออยู่

### Requirements
- Windows PowerShell 5.1+ หรือ PowerShell 7+
- สคริปต์ในกลุ่ม Microsoft365 ต้องมี `Microsoft.Graph` PowerShell module และสิทธิ์ Azure AD ที่เหมาะสม

### Deployment & Usage
ดูวิธี deploy และใช้งานแบบเต็มๆ ได้ที่ [DEPLOYMENT.md](DEPLOYMENT.md) (setup, execution policy, scheduling, security notes, troubleshooting)

