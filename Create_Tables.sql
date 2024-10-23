CREATE TABLE Books (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    Author NVARCHAR(255) NOT NULL,
    ISBN NVARCHAR(13) UNIQUE,
    PublishedDate DATE,
    Genre NVARCHAR(50),
    ShelfLocation NVARCHAR(50),
    CurrentStatus NVARCHAR(10) CHECK (CurrentStatus IN ('Available', 'Borrowed')) DEFAULT 'Available'
);



CREATE TABLE Borrowers (
    BorrowerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) UNIQUE,
    DateOfBirth DATE,
    MembershipDate DATE DEFAULT GETDATE()
);



CREATE TABLE Loans (
    LoanID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT FOREIGN KEY REFERENCES Books(BookID),
    BorrowerID INT FOREIGN KEY REFERENCES Borrowers(BorrowerID),
    DateBorrowed DATE DEFAULT GETDATE(),
    DueDate DATE,
    DateReturned DATE NULL  
);