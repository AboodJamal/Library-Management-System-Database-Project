-- Retrieve all books borrowed by a specific borrower
SELECT b.Title, b.Author, l.DateBorrowed, l.DueDate
FROM Loans l
JOIN Books b ON l.BookID = b.BookID
WHERE l.BorrowerID = 2 AND l.DateReturned IS NULL;


-- Identify borrowers who've borrowed 2 or more books but haven't returned any
WITH BorrowedBooksCTE AS (
    SELECT BorrowerID, COUNT(*) AS BooksBorrowed
    FROM Loans
    WHERE DateReturned IS NULL
    GROUP BY BorrowerID
)

SELECT b.FirstName, b.LastName, b.Email
FROM Borrowers b
JOIN BorrowedBooksCTE cte ON b.BorrowerID = cte.BorrowerID
where cte.BooksBorrowed >= 2;



-- Rank borrowers based on borrowing frequency
SELECT b.FirstName, b.LastName, COUNT(l.LoanID) AS BorrowingFrequency,
    RANK() OVER (ORDER BY COUNT(l.LoanID) DESC) AS BorrowingRank
FROM Loans l 
JOIN Borrowers b ON b.BorrowerID = l.BorrowerID
GROUP BY b.BorrowerID, b.FirstName, b.LastName;

-- or
SELECT b.FirstName, b.LastName, COUNT(l.LoanID) AS BorrowingFrequency,
    DENSE_RANK() OVER (ORDER BY COUNT(l.LoanID) DESC) AS BorrowingRank
FROM Loans l 
JOIN Borrowers b ON b.BorrowerID = l.BorrowerID
GROUP BY b.BorrowerID, b.FirstName, b.LastName
ORDER BY BorrowingRank;


-- Identify the most popular genre for a given month
DECLARE @Month INT = 8;  
WITH GenreCounts AS (
    SELECT Genre, COUNT(*) AS GenreCount
    FROM Books b
    JOIN Loans l ON b.BookID = l.BookID
    WHERE MONTH(l.DateBorrowed) = @Month
    GROUP BY Genre
)
SELECT Genre, GenreCount,
    RANK() OVER (ORDER BY GenreCount DESC) AS GenreRank
FROM GenreCounts;



-- Add New Borrower PROCEDURE
CREATE PROCEDURE sp_AddNewBorrower
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(255),
    @DateOfBirth DATE,
    @MembershipDate DATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Borrowers WHERE Email = @Email)
        BEGIN
            RAISERROR ('Email already exists.', 16, 1);
            RETURN;
        END
    ELSE
        BEGIN
            INSERT INTO Borrowers (FirstName, LastName, Email, DateOfBirth, MembershipDate)
            VALUES (@FirstName, @LastName, @Email, @DateOfBirth, @MembershipDate);
            
            SELECT SCOPE_IDENTITY() AS BorrowerID;
        END
END;

EXEC sp_AddNewBorrower 'Abood', 'Jamal', 'jamal.doe@example.com', '1990-05-15', '2023-10-01';


-- Database Function - Calculate Overdue Fees
CREATE FUNCTION fn_CalculateOverdueFees (@LoanID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @OverdueDays INT;
    DECLARE @OverdueFee DECIMAL(10, 2);
    DECLARE @DateReturned DATE;
    DECLARE @DueDate DATE;

    SELECT @DueDate = DueDate, @DateReturned = DateReturned
    FROM Loans
    WHERE LoanID = @LoanID;

    IF @DateReturned IS NULL
    BEGIN
        SET @OverdueDays = DATEDIFF(DAY, @DueDate, GETDATE());
    END
    ELSE
    BEGIN
        SET @OverdueDays = DATEDIFF(DAY, @DueDate, @DateReturned);
    END

    IF @OverdueDays > 0
    BEGIN
        IF @OverdueDays <= 30
        BEGIN
            SET @OverdueFee = @OverdueDays * 1.00;
        END
        ELSE
        BEGIN
            SET @OverdueFee = (30 * 1.00) + ((@OverdueDays - 30) * 2.00);
        END
    END
    ELSE
    BEGIN
        SET @OverdueFee = 0.00;
    END

    RETURN @OverdueFee;
END;

SELECT dbo.fn_CalculateOverdueFees(1);






-- Book Borrowing Frequency

CREATE FUNCTION fn_BookBorrowingFrequency (@BookID INT)
RETURNS INT
AS
BEGIN
    DECLARE @BorrowCount INT;
    
    SELECT @BorrowCount = COUNT(*)
    FROM Loans
    WHERE BookID = @BookID;
    
    RETURN @BorrowCount;
END;

SELECT dbo.fn_BookBorrowingFrequency(3) AS BorrowingFrequency;  


-- Overdue Analysis
SELECT b.Title, br.FirstName, br.LastName, DATEDIFF(DAY, l.DueDate, GETDATE()) AS DaysOverdue
FROM Loans l
JOIN Books b ON l.BookID = b.BookID
JOIN Borrowers br ON l.BorrowerID = br.BorrowerID
WHERE DATEDIFF(DAY, l.DueDate, GETDATE()) > 30 AND l.DateReturned IS NULL;




-- Rank authors by the borrowing frequency of their books
WITH AuthorBorrowingFrequency AS (
    SELECT 
        b.Author, 
        COUNT(l.LoanID) AS BorrowingCount
    FROM 
        Books b
    JOIN 
        Loans l ON b.BookID = l.BookID
    GROUP BY 
        b.Author
)
SELECT 
    abf.Author, 
    abf.BorrowingCount, 
    RANK() OVER (ORDER BY abf.BorrowingCount DESC) AS BorrowingRank -- or DENSE_RANK()
FROM 
    AuthorBorrowingFrequency abf;



-- Determine the preferred genre of different age groups of borrowers
WITH BorrowerAgeGroup AS (
    SELECT b.BorrowerID, 
        CASE 
            WHEN DATEDIFF(YEAR, b.DateOfBirth, GETDATE()) BETWEEN 0 AND 10 THEN '0-10'
            WHEN DATEDIFF(YEAR, b.DateOfBirth, GETDATE()) BETWEEN 11 AND 20 THEN '11-20'
            WHEN DATEDIFF(YEAR, b.DateOfBirth, GETDATE()) BETWEEN 21 AND 30 THEN '21-30'
            WHEN DATEDIFF(YEAR, b.DateOfBirth, GETDATE()) BETWEEN 31 AND 40 THEN '31-40'
            ELSE '41+'
        END AS AgeGroup
    FROM Borrowers b
),
GenrePreference AS (
    SELECT g.AgeGroup, bk.Genre, COUNT(l.LoanID) AS LoanCount
    FROM BorrowerAgeGroup g
    JOIN Loans l ON g.BorrowerID = l.BorrowerID
    JOIN Books bk ON l.BookID = bk.BookID
    GROUP BY g.AgeGroup, bk.Genre
)
SELECT gp.AgeGroup, gp.Genre, gp.LoanCount AS MaxLoans
FROM GenrePreference gp
WHERE gp.LoanCount = (
    SELECT MAX(LoanCount)
    FROM GenrePreference gp2
    WHERE gp2.AgeGroup = gp.AgeGroup
);



-- Borrowed Books Report
CREATE PROCEDURE sp_BorrowedBooksReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    IF @StartDate > @EndDate
    BEGIN
        RAISERROR ('StartDate cannot be greater than EndDate.', 16, 1);
        RETURN;
    END

    SELECT b.Title AS BookTitle, 
        br.FirstName + ' ' + br.LastName AS BorrowerName, 
        l.DateBorrowed, 
        l.DueDate,
        l.DateReturned
    FROM Loans l
    JOIN Books b ON l.BookID = b.BookID
    JOIN Borrowers br ON l.BorrowerID = br.BorrowerID
    WHERE l.DateBorrowed BETWEEN @StartDate AND @EndDate
    ORDER BY l.DateBorrowed;
END;

EXEC sp_BorrowedBooksReportt '2024-08-01', '2024-8-31';


-- AuditLog Trigger Implementation
CREATE TABLE AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT NOT NULL,
    StatusChange NVARCHAR(255),
    ChangeDate DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trigger_BookStatusChange
ON Books
AFTER UPDATE
AS
BEGIN
    IF UPDATE(CurrentStatus)
    BEGIN
        INSERT INTO AuditLog (BookID, StatusChange, ChangeDate)
        SELECT BookID, 'Status changed to ' + CurrentStatus, GETDATE()
        FROM inserted;
    END
END;


-- Tisting:
INSERT INTO Books (Title, Author, ISBN, PublishedDate, Genre, ShelfLocation, CurrentStatus)
VALUES ('The Great Gatsby', 'F. Scott Fitzgerald', '9780743273565', '1925-04-10', 'Fiction', 'A1', 'Available');

UPDATE Books
SET CurrentStatus = 'Borrowed'
WHERE Title = 'The Great Gatsby';

SELECT * FROM AuditLog;


-- Procedure borrowers who have overdue books with temp table
--Books that are overdue and not yet returned.
--Books that have been returned but are overdue .
CREATE PROCEDURE sp_OverdueBorrowers
AS
BEGIN
    CREATE TABLE #OverdueBorrowers (
        BorrowerID INT,
        BorrowerName NVARCHAR(255)
    );

    INSERT INTO #OverdueBorrowers (BorrowerID, BorrowerName)
    SELECT DISTINCT 
        b.BorrowerID, 
        b.FirstName + ' ' + b.LastName AS BorrowerName
    FROM Borrowers b
    JOIN Loans l ON b.BorrowerID = l.BorrowerID
    WHERE l.DueDate < GETDATE() AND l.DateReturned IS NULL;

    SELECT 
        o.BorrowerID,
        o.BorrowerName,
        b.Title AS [Book Title],
        l.DateBorrowed,
        l.DueDate
    FROM #OverdueBorrowers o
    JOIN Loans l ON o.BorrowerID = l.BorrowerID
    JOIN Books b ON l.BookID = b.BookID
    WHERE (l.DueDate < GETDATE() AND l.DateReturned IS NULL)
    OR (l.DateReturned IS NOT NULL AND l.DateReturned > l.DueDate);

    DROP TABLE #OverdueBorrowers;
END;


EXEC sp_OverdueBorrowers;


-- BONUS 
SELECT Top 3 DATENAME(WEEKDAY, DateBorrowed) AS DayOfWeek, COUNT(LoanID) AS [Number of loans], 
       CONCAT(FORMAT(ROUND((COUNT(LoanID) * 100.0 / (SELECT COUNT(*) FROM Loans)), 2), '0.##'), '%') AS [Percentage]
FROM Loans
GROUP BY DATENAME(WEEKDAY, DateBorrowed)
ORDER BY COUNT(LoanID) DESC;
