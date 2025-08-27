# Database Triggers & Transaction Log Management – NBE Internship Project  

**Developer:** Erfan Nada  
**Supervision:** Eng. Islam Sayed 

**Organization:** National Bank of Egypt

---

## 📌 Project Overview  
This project was developed during an internship at the **National Bank of Egypt (NBE)** to simulate solutions for real-world database management challenges. As part of a proof-of-concept project, the focus was on:  

1. **Database Audit Trails** – Using SQL Server triggers to track every `INSERT`, `UPDATE`, and `DELETE` with before/after images.  
2. **Transaction Log Management** – Implementing scheduled transaction log backups with automated cleanup to prevent uncontrolled growth.  
3. **Demonstration Application** – A Python-based GUI to showcase record management and audit trail functionality.  

The project acted as a **proof-of-concept demonstration**, simulating critical banking scenarios such as migration support, data consistency, and compliance auditing.  

---

## 🚩 Problem Statement  
Banks face challenges in database management, especially during migrations (e.g., SQL Server → Oracle):  
- No reliable way to track record changes before and after updates.  
- Transaction logs growing uncontrollably, consuming large storage.  
- Increased risk of performance issues and unreliable data migration.  

---

## 🎯 Objectives  
- Build a **robust audit trail** for accountability.  
- Develop **efficient log backup & retention strategies**.  
- Create a **demo system** to simulate real-world banking scenarios.  

---

## 🛠️ Features  

### 🔹 Database Audit Mechanism  
- Dedicated `Employees_Audit` table to store historical changes.  
- SQL Server **AFTER triggers** capture:  
  - Inserts  
  - Deletes  
  - Updates (before & after images)  

### 🔹 Transaction Log Management  
- SQL Server Agent Job + PowerShell script to:  
  - Backup logs every **5 minutes**.  
  - Automatically clean up log files older than **50 minutes**.  

### 🔹 Demonstration Application  
- Python-based GUI to:  
  - Insert, update, delete employee records.  
  - View the audit trail in real time.  

---

## 📂 Project Structure  

```
├── NBE Database Project.pdf      # Full project documentation & presentation
├── trigger.sql                   # SQL triggers for audit trail
├── Transaction Logs Script.sql   # Transaction log backup & cleanup job
└── README.md                     # Project description
```

---

## ⚙️ Technologies Used  
- **SQL Server Management System**  
- **PowerShell (automated cleanup scripts)**  
- **Python (GUI demo application)**  

---

## 🚀 Outcomes  
- Built a complete audit mechanism ensuring **accountability & transparency**.  
- Prevented transaction log overflow with **automated backup/cleanup**.  
- Simulated **real-world banking database operations** in a controlled environment.  
- Gained practical skills in **SQL Server administration, auditing, and log management**.  

---

## 📈 Future Enhancements  
- Add **real-time alerts** for unusual changes.  
- Create advanced **reporting dashboards**.  
- Expand integration with **enterprise monitoring tools**.  
