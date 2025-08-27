INSERT INTO Employees (EmpName, Salary, Age)
VALUES
('Sara Mohamed', 8500, 27),
('Omar Hassan', 9500, 35),
('Laila Youssef', 15000, 40);

UPDATE Employees
SET EmpName = 'ahmed'
WHERE EmpID = 2;

INSERT INTO Employees (EmpName, Salary, Age)
VALUES
('Erfan', 8500, 27);

UPDATE Employees
SET EmpName = 'ahmed'
WHERE EmpID = 2;

USE DB1;
GO

ALTER TRIGGER dbo.trg_Employees_Update
ON dbo.Employees
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT only
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT i.EmpID, i.EmpName, i.Salary, i.Age, 'Insert'
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.EmpID = i.EmpID);

    -- DELETE only
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT d.EmpID, d.EmpName, d.Salary, d.Age, 'Delete'
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.EmpID = d.EmpID);

    -- UPDATE - before image
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT d.EmpID, d.EmpName, d.Salary, d.Age, 'BeforeUpdate'
    FROM deleted d
    INNER JOIN inserted i ON i.EmpID = d.EmpID;

    -- UPDATE - after image
    INSERT INTO DB2.dbo.Employees_Audit (EmpID, EmpName, Salary, Age, ActionType)
    SELECT i.EmpID, i.EmpName, i.Salary, i.Age, 'AfterUpdate'
    FROM inserted i
    INNER JOIN deleted d ON d.EmpID = i.EmpID;
END
GO

UPDATE Employees
SET EmpName = 'ahmed hossam'
WHERE EmpID = 2;

INSERT INTO Employees (EmpName, Salary, Age)
VALUES
('Omar', 8500, 27);

alter table [dbo].[Employees_Audit]
drop column TxnStatus;

INSERT INTO Employees (EmpName, Salary, Age)
VALUES
('Mostafa', 8500, 27);

