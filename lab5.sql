-- Davletov Akylbek 21B030796
CREATE TABLE employees(
    employee_id INT,
    first_name TEXT,
    last_name TEXT,
    age INT CHECK ( age BETWEEN 18 AND 65),
    salary NUMERIC CHECK ( salary > 0 )
);
CREATE TABLE products_catalog(
    product_id INT,
    product_name TEXT,
    regular_price NUMERIC CHECK ( regular_price > 0 ),
    discount_price NUMERIC CHECK ( discount_price > 0 AND discount_price < regular_price )
);

CREATE TABLE bookings(
    booking_id INT,
    check_in_date DATE,
    check_out_date DATE CHECK ( check_out_date > check_in_date ),
    num_guests INT CHECK ( num_guests BETWEEN 1 AND 10)
);

--INSERT INTO employees(employee_id, first_name, last_name, age, salary)
--    VALUES (2, 'Nagimov', 'Almas', 17, 100000);
-- тут попытался добавить employee которому 17 лет, вернул ошибку из за ограничений в чек
INSERT INTO employees(employee_id, first_name, last_name, age, salary)
    VALUES (2, 'Nagimov', 'Almas', 20, 100000),
           (3, 'Seifullin', 'Arman', 23, 200000);

INSERT INTO products_catalog(product_id, product_name, regular_price, discount_price)
    VALUES (1, 'balabaqsha', 100, 80),
           (2,'college', 400, 300);
           --(3, 'jumys', 200, 300);
           -- на 3 вернула ошибку потому что 200 меньше чем 300

INSERT INTO bookings(booking_id, check_in_date, check_out_date, num_guests)
    VALUES (1, '2025-08-01', '2025-08-15', 3),
           (2,'2025-09-01', '2025-09-15', 2);
           --(3,'2025-09-10', '2025-09-01', 5);
           -- на 3 вернула ошибку потому что вторая дата чек аут раньше чем чек ин

-- Part_2
CREATE TABLE customers (
    customer_id INT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);
CREATE TABLE inventory (
    item_id INT NOT NULL,
    item_name TEXT NOT NULL,
    quantity INT NOT NULL CHECK ( quantity >= 0 ),
    unit_price NUMERIC NOT NULL CHECK ( unit_price > 0 ),
    last_updated TIMESTAMP NOT NULL
);
INSERT INTO customers(customer_id, email, phone, registration_date)
VALUES (1,'123mail.ru','777666', '2025-10-01');

INSERT INTO inventory(item_id, item_name, quantity, unit_price, last_updated)
VALUES (1, 'pen', 3,10,'2025-09-02 10:10:10');

-- Part_3
CREATE TABLE users (
    user_id INT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);
CREATE TABLE course_enrollments (
    enrollment_id INT,
    student_id INT,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username),
ADD CONSTRAINT unique_email UNIQUE (email);

--Part_4
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);
INSERT INTO departments (dept_id, dept_name, location)
VALUES
    (1, 'Sales', 'Almaty'),
    (2, 'IT', 'Almaty'),
    (3, 'CC', 'Almaty');
    --(1,'Sales', 'Almaty');
CREATE TABLE student_courses (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);
/*
1. Difference between UNIQUE and PRIMARY KEY
A PRIMARY KEY uniquely identifies each row in a table and cannot contain NULL values.
Each table can have only one primary key.
A UNIQUE constraint also ensures that all values in a column are unique, but it can allow NULL values.
A table can have multiple UNIQUE constraints.
2. Single-column vs Composite PRIMARY KEY
A single-column primary key is used when one column alone can uniquely identify a record.
A composite primary key is used when a combination of two or more columns is needed to uniquely identify a record.
3. Why a table can have only one PRIMARY KEY but multiple UNIQUE constraints
A table can have only one primary key because it defines the main unique identity of each row.
*/
--Part_5
CREATE TABLE employees_dept (
    emp_id INT PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    hire_date DATE
);
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES
(1, 'Akylbek Davletov', 1, '2024-06-15'),
(2, 'Almas Nagimov', 2, '2024-07-01'),
(3, 'Arman Seifullin', 3, '2024-08-10');
--(4,'test', 4, '1111-11-11');

CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);
CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT REFERENCES authors(author_id),
    publisher_id INT REFERENCES publishers(publisher_id),
    publication_year INT,
    isbn TEXT UNIQUE
);
INSERT INTO authors (author_id, author_name, country)
VALUES
(1, 'George Orwell', 'United Kingdom'),
(2, 'Fyodor Dostoevsky', 'Russia'),
(3, 'J.K. Rowling', 'United Kingdom');
INSERT INTO publishers (publisher_id, publisher_name, city)
VALUES
(1, 'Penguin Books', 'London'),
(2, 'Bloomsbury', 'Oxford'),
(3, 'Vintage Classics', 'New York');
INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
VALUES
(1, '1984', 1, 1, 1949, '9780451524935'),
(2, 'Crime and Punishment', 2, 3, 1866, '9780140449136'),
(3, 'Harry Potter and the Philosopher''s Stone', 3, 2, 1997, '9780747532699');

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INT REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products_fk(product_id),
    quantity INT CHECK (quantity > 0)
);

INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Books');

INSERT INTO products_fk VALUES
(1, 'Laptop', 1),
(2, 'Novel', 2);

INSERT INTO orders VALUES
(1, '2024-09-10'),
(2, '2024-10-01');

INSERT INTO order_items VALUES
(1, 1, 1, 2),
(2, 2, 2, 1);

--DELETE FROM categories WHERE category_id = 1;

DELETE FROM orders WHERE order_id = 1;

SELECT * FROM orders;
SELECT * FROM order_items;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INT CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INT PRIMARY KEY,
    order_id INT REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    quantity INT CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
(1, 'akylbek@mail.ru', '87776665555', '2024-06-10'),
(2, 'Almas@mail.ru', '87776665554', '2024-07-12'),
(3, 'Arman@mail.ru', '87776665553', '2024-08-15'),
(4, 'Sayat@mail.ru', '87776665552', '2024-09-01'),
(5, 'Almat@mail.ru', '87776665551', '2024-09-20');

-- Продукты
INSERT INTO products VALUES
(1, 'Laptop', 'Gaming laptop', 300000, 10),
(2, 'Headphones', 'Wireless Bluetooth', 50000, 30),
(3, 'Keyboard', 'Mechanical RGB', 25000, 50),
(4, 'Mouse', 'Wireless ergonomic', 15000, 40),
(5, 'Monitor', '27 inch Full HD', 90000, 20);

-- Заказы
INSERT INTO ecommerce_orders VALUES
(1, 1, '2024-10-01', 350000, 'pending'),
(2, 2, '2024-10-02', 115000, 'processing'),
(3, 3, '2024-10-03', 25000, 'delivered'),
(4, 4, '2024-10-04', 45000, 'shipped'),
(5, 5, '2024-10-05', 90000, 'cancelled');

-- Детали заказов
INSERT INTO order_details VALUES
(1, 1, 1, 1, 300000),
(2, 1, 2, 1, 50000),
(3, 2, 4, 3, 15000),
(4, 3, 3, 1, 25000),
(5, 5, 5, 1, 90000);

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM ecommerce_orders;
SELECT * FROM order_details;

DELETE FROM customers WHERE customer_id = 1;

SELECT * FROM ecommerce_orders;
SELECT * FROM order_details;