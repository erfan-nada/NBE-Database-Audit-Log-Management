CREATE DATABASE DB1;
CREATE DATABASE DB2;
GO
                                                                                            
USE DB1;
GO

CREATE TABLE Employees (
    EmpID INT PRIMARY KEY IDENTITY(1,1),
    EmpName NVARCHAR(100),
    Salary DECIMAL(10,2),
    Age INT
);
USE DB2;
GO

CREATE TABLE Employees_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    EmpID INT,
    EmpName NVARCHAR(100),
    Salary DECIMAL(10,2),
    Age INT,
    ActionType NVARCHAR(20),   -- BeforeUpdate / AfterUpdate
    ActionTime DATETIME DEFAULT GETDATE()
);

INSERT INTO Employees (EmpName, Salary, Age)
VALUES 
    ('John Doe', 55000.00, 30),
    ('Jane Smith', 62000.50, 28),
    ('Michael Johnson', 75000.00, 40),
    ('Emily Davis', 48000.75, 25),
    ('Robert Brown', 85000.00, 35);

USE DB1;
GO

CREATE TRIGGER trg_Employees_Update
ON Employees
AFTER UPDATE
AS
BEGIN
    -- حفظ نسخة قبل التعديل
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT EmpID, EmpName, Salary, Age, 'BeforeUpdate'
    FROM deleted;

    -- حفظ نسخة بعد التعديل
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT EmpID, EmpName, Salary, Age, 'AfterUpdate'
    FROM inserted;
END
GO

-- إضافة موظف
INSERT INTO DB1.dbo.Employees (EmpName, Salary, Age)
VALUES ('Ali', 5000, 30);

-- تحديث الموظف
UPDATE DB1.dbo.Employees
SET Salary = 6000, Age = 31
WHERE EmpID = 1;

-- استعراض جدول المراقبة
SELECT * FROM DB2.dbo.Employees_Audit;

use master
-- إنشاء login على ال

CREATE LOGIN AdminUser WITH PASSWORD = 'StrongAdminPassword!';
use master
CREATE LOGIN NormalUser WITH PASSWORD = 'StrongUserPassword!';

-- ربط login بـ DB1
USE DB1;
CREATE USER AdminUser FOR LOGIN AdminUser;
CREATE USER NormalUser FOR LOGIN NormalUser;

-- ربط login بـ DB2
USE DB2;
CREATE USER AdminUser FOR LOGIN AdminUser;
CREATE USER NormalUser FOR LOGIN NormalUser;
use master
GRANT CONNECT SQL TO [AdminUser];



-- DB1
USE DB1;
GRANT SELECT, INSERT, UPDATE, DELETE ON Employees TO AdminUser;
GRANT SELECT ON Employees TO NormalUser;

USE DB2;
ALTER TABLE Employees_Audit
ADD TxnStatus NVARCHAR(20);   -- Success / Failed

USE DB1;
GO

CREATE OR ALTER TRIGGER trg_Employees_Update
ON Employees
INSTEAD OF UPDATE
AS
BEGIN
    DECLARE @user NVARCHAR(100) = SUSER_SNAME();

    IF @user = 'AdminUser'
    BEGIN
        -- تنفيذ التحديث الفعلي
        UPDATE e
        SET e.EmpName = i.EmpName,
            e.Salary  = i.Salary,
            e.Age     = i.Age
        FROM Employees e
        INNER JOIN inserted i ON e.EmpID = i.EmpID;

        -- حفظ في Audit (Before + After + Success)
        INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType, TxnStatus)
        SELECT d.EmpID, d.EmpName, d.Salary, d.Age, 'BeforeUpdate', 'Success'
        FROM deleted d;

        INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType, TxnStatus)
        SELECT i.EmpID, i.EmpName, i.Salary, i.Age, 'AfterUpdate', 'Success'
        FROM inserted i;
    END
    ELSE
    BEGIN
        -- المستخدم مش Admin → ما يتنفذش التعديل
        -- بس يتسجل في Audit كمحاولة فاشلة
        INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType, TxnStatus)
        SELECT d.EmpID, d.EmpName, d.Salary, d.Age, 'AttemptedUpdate', 'Failed'
        FROM deleted d;
    END
END;
GO



-- كأدمن (بينجح)
EXECUTE AS LOGIN = 'AdminUser';

UPDATE DB1.dbo.Employees SET Salary = 9000 WHERE EmpID = 1;
REVERT;

-- كمستخدم عادي (بيفشل، بس يتسجل في Audit)
EXECUTE AS LOGIN = 'NormalUser';
UPDATE DB1.dbo.Employees SET Salary = 10000 WHERE EmpID = 1;
REVERT;

-- عرض الـ Audit
use DB2
SELECT * FROM DB2.dbo.Employees_Audit;

select * from [dbo].[Employees_Audit]

EXEC xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'LoginMode';



 --   SELECT * FROM fn_my_permissions('dbo.Employees', 'OBJECT');

 USE DB1;
GO

-- إعطاء كل الصلاحيات للأدمن
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Employees TO AdminUser;

-- إعطاء قراءة فقط لليوزر العادي
GRANT SELECT ON dbo.Employees TO NormalUser;


USE DB2;
GO

-- الأدمن يقدر يقرأ الـ Audit
GRANT SELECT ON dbo.Employees_Audit TO AdminUser;

-- النورمال يوزر يقدر يقرأ الـ Audit برضه
GRANT SELECT ON dbo.Employees_Audit TO NormalUser;

------------------------------------------------
USE DB1;
GO
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.Employees FROM AdminUser;
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.Employees FROM NormalUser;


USE DB2;
GO
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.Employees_Audit FROM AdminUser;
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.Employees_Audit FROM NormalUser;

USE DB1;
GO
-- Admin full access
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Employees TO AdminUser;

-- NormalUser read only
GRANT SELECT ON dbo.Employees TO NormalUser;

USE DB2;
GO
-- AdminUser يقرأ Audit
GRANT SELECT ON dbo.Employees_Audit TO AdminUser;

-- NormalUser يقرأ Audit
GRANT SELECT ON dbo.Employees_Audit TO NormalUser;

--
EXECUTE AS LOGIN = 'AdminUser';
UPDATE DB1.dbo.Employees SET Salary = 10000 WHERE EmpID = 1;  -- لازم ينجح
SELECT TOP 5 * FROM DB2.dbo.Employees_Audit;                  -- يقدر يشوف
REVERT;


