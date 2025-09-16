    -- LabWork 1
    -- Part 1
    -- Task 1.1
    -- Relation A
    -- Employee(EmpID, SSN, Email, Phone, Name, Department, Salary)
    -- *6 different superkeys: EmpID, SSN, Email, (EmpID, SSN), (EmpID, Email), (SSN, Email)
    -- *All candidate keys: EmpID, SSN, Email.
    -- *As a primary key from candidate keys, I choose - EmpID.
    --  Because, EmpID never will change and comfortable to use.
    -- *Two employees can have same number, for example: sales team.
    --  In my job, they use same number for connect with customers.

    -- Relation B
    -- Registration(StudentID, CourseCode, Section, Semester, Year, Grade, Credits)
    -- *Minimum unique attribute(candidate key): (StudentID, CourseCode, Section, Semester, Year)
    -- *Primary key - (StudentID, CourseCode, Section, Semester, Year)

    -- Task 1.2
    -- Student(StudentID, Name, Email, Major, AdvisorID)
    -- Professor(ProfID, Name, Department, Salary)
    -- Course(CourseID, Title, Credits, DepartmentCode)
    -- Department(DeptCode, DeptName, Budget, ChairID)
    -- Enrollment(StudentID, CourseID, Semester, Grade)
    -- 1) Student - AdvisorID --> Professor.ProfID
    -- 2) Professor - no FK
    -- 3) Course - DepartmentCode --> Department.DeptCode
    -- 4) Department - ChairID --> Professor.ProfID
    -- 5) Enrollment StudentID --> Student.StudentID
    --               CourseID --> Course.CourseID

    -- Task 2.2 E-Commerce Database

-- 1) Customers
CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Address VARCHAR(200)
);

-- 2) Products
CREATE TABLE Product (
    ProductID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Price NUMERIC(10,2) NOT NULL,
    StockQty INT NOT NULL
);

-- 3) Orders
CREATE TABLE "Order" (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount NUMERIC(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- 4) OrderItems (связь между Orders и Products)
CREATE TABLE OrderItem (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    PriceAtOrderTime NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES "Order"(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

-- 5) Payments
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    OrderID INT NOT NULL,
    Method VARCHAR(50),
    Amount NUMERIC(10,2) NOT NULL,
    PaymentDate DATE NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES "Order"(OrderID)
);
-- Customers
INSERT INTO Customer (Name, Email, Address) VALUES
('Alice', 'alice@mail.com', '123 Main St'),
('Bob', 'bob@mail.com', '456 Elm St');

-- Products
INSERT INTO Product (Name, Price, StockQty) VALUES
('Laptop', 1200.00, 10),
('Phone', 600.00, 20),
('Headphones', 80.00, 50);

-- Orders
INSERT INTO "Order" (CustomerID, OrderDate, TotalAmount) VALUES
(1, '2025-09-10', 1800.00),
(2, '2025-09-11', 680.00);

-- OrderItems
INSERT INTO OrderItem (OrderID, ProductID, Quantity, PriceAtOrderTime) VALUES
(1, 1, 1, 1200.00),   -- Alice купила 1 Laptop
(1, 2, 1, 600.00),    -- Alice купила 1 Phone
(2, 3, 2, 80.00);     -- Bob купил 2 Headphones

-- Payments
INSERT INTO Payment (OrderID, Method, Amount, PaymentDate) VALUES
(1, 'Credit Card', 1800.00, '2025-09-10'),
(2, 'Cash', 160.00, '2025-09-11'),
(2, 'Credit Card', 520.00, '2025-09-11');

-- Все заказы с клиентами
SELECT o.OrderID, c.Name AS Customer, o.TotalAmount, o.OrderDate
FROM "Order" o
JOIN Customer c ON o.CustomerID = c.CustomerID;

-- Все товары в заказах
SELECT oi.OrderID, p.Name AS Product, oi.Quantity, oi.PriceAtOrderTime
FROM OrderItem oi
JOIN Product p ON oi.ProductID = p.ProductID;

-- Платежи по заказам
SELECT p.PaymentID, o.OrderID, c.Name AS Customer, p.Method, p.Amount
FROM Payment p
JOIN "Order" o ON p.OrderID = o.OrderID
JOIN Customer c ON o.CustomerID = c.CustomerID;
