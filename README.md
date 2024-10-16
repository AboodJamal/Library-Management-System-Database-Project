Library Management System: Database Project
Background:
A local library wishes to transition from their traditional book-keeping to a more robust digital system. They want a platform to efficiently track books, borrowers, loans, returns, and offer insights into borrowing trends.

Objective:
Design and implement a relational database using MS SQL that supports the library's operations and offers extensive querying capabilities.

Requirements:
1. Entity Relationship Model (ERM) Diagram:
Entities: Illustrate entities: Books, Borrowers, and Loans.
Attributes: Detail attributes for each entity.
Relationships: Exhibit connections between entities.
Connectivity and Cardinality: Notate the relationship type between entities.
Keys: Mark primary (PK) and foreign keys (FK).
Tools: Use tools such as ERDPlus, Lucidchart, or similar. Include the diagram in the repository.
2. Design the Relational Schema using MS SQL:
Books Table:
BookID (PK)
Title
Author
ISBN
Published Date
Genre
Shelf Location
Current Status ('Available' or 'Borrowed')
Borrowers Table:
BorrowerID (PK)
First Name
Last Name
Email
Date of Birth
Membership Date
Loans Table:
LoanID (PK)
BookID (FK)
BorrowerID (FK)
Date Borrowed
Due Date
Date Returned (NULL if not returned yet)
3. Build and Seed the Database:
Construct the database in MS SQL.
Seed the database with fictional data:
Populate 1000 books
Populate 1000 borrowers
Populate 1000 loan records
Include DML (Data Manipulation Language) scripts for seeding in the GitHub repository. Ensure the data is consistent and meaningful. You can generate data using tools or scripts.
4. Complex Queries and Procedures:
Note: Each of the following requirements should be implemented in a separate SQL file and pushed to the GitHub repository in a distinct commit.

Queries and Procedures:
List of Borrowed Books:

Retrieve all books borrowed by a specific borrower, including those currently unreturned.
Active Borrowers with CTEs:

Identify borrowers who've borrowed 2 or more books but haven't returned any using CTEs (Common Table Expressions).
Borrowing Frequency using Window Functions:

Rank borrowers based on borrowing frequency.
Popular Genre Analysis using Joins and Window Functions:

Identify the most popular genre for a given month.
Stored Procedures:
sp_AddNewBorrower:

Purpose: Streamline the process of adding a new borrower.
Parameters: FirstName, LastName, Email, DateOfBirth, MembershipDate.
Implementation: Check if an email exists; if not, add to Borrowers. If existing, return an error message.
Return: The new BorrowerID or an error message.
fn_CalculateOverdueFees:

Purpose: Compute overdue fees for a given loan.
Parameter: LoanID
Implementation: Charge fees based on overdue days: $1/day for up to 30 days, $2/day after.
Return: Overdue fee for the LoanID.
fn_BookBorrowingFrequency:

Purpose: Gauge the borrowing frequency of a book.
Parameter: BookID
Implementation: Count the number of times the book has been issued.
Return: Borrowing count of the book.
Additional Queries:
Overdue Analysis:

List all books overdue by more than 30 days with their associated borrowers.
Author Popularity using Aggregation:

Rank authors by the borrowing frequency of their books.
Genre Preference by Age using Group By and Having:

Determine the preferred genre of different age groups of borrowers. (Age groups: (0,10), (11,20), (21,30), etc.)
Stored Procedures and Triggers:
sp_BorrowedBooksReport:

Purpose: Generate a report of books borrowed within a specified date range.
Parameters: StartDate, EndDate
Implementation: Retrieve all books borrowed within the given range, with details like borrower name and borrowing date.
Return: Tabulated report of borrowed books.
Trigger Implementation:

Design a trigger to log an entry into a separate AuditLog table whenever a book's status changes from 'Available' to 'Borrowed' or vice versa. The AuditLog should capture:
BookID
StatusChange
ChangeDate
Stored Procedure with Temp Table:

Design a stored procedure that retrieves all borrowers who have overdue books. Store these borrowers in a temporary table, then join this temp table with the Loans table to list out the specific overdue books for each borrower.
BONUS:
Weekly Peak Days:
The library is planning to employ a new part-time worker. This worker will work 3 days weekly in the library. From the loan data, determine the top 3 days in the week with the most share of the loans. Display the result of each day as a percentage of all loans, sorted from the highest to the lowest percentage (e.g., 25.18% of the loans happen on Monday).

