--Zholdassali Amir 24B031787
--Task 1.1
CREATE TABLE employees(
    employee_id SERIAL PRIMARY KEY,
    first_name varchar(50),
    last_name varchar(50),
    age integer CHECK (age between 18 and 65),
    salary numeric CHECK (salary > 0)
);


--Task 1.2
create table products_catalog(
    product_id serial primary key,
    product_name varchar(50),
    regular_price numeric,
    discount_price numeric,
    CONSTRAINT valid_discount CHECK(regular_price > 0 AND discount_price > 0 AND discount_price < regular_price)
);


--Task 1.3
create table bookings(
    booking_id serial primary key,
    check_in_date date,
    check_out_date date CHECK (check_out_date > check_in_date),
    num_guests integer CHECK (num_guests between 1 and 10)
);


--Task 1.4
INSERT INTO employees VALUES(1, 'A', 'Z', 25, 10000); --successfully inserted
INSERT INTO bookings VALUES(1, '01-01-2025', '01-01-2024', 25); --not inserted
--in relation "bookings" new row violates connstraint "bookings_check". The value for "check_out_date" column is smaller than "check_in_date" and value for "num_guests" is too high.


--Task 2.1
create table customers(
    customer_id serial primary key NOT NULL,
    email varchar(50) NOT NULL,
    phone varchar(20) NULL,
    registration_date date NOT NULL
);


--Task 2.2
create table inventory(
    item_id serial primary key NOT NULL,
    item_name varchar(50) NOT NULL,
    quantity integer NOT NULL CHECK (quantity >= 0),
    unit_price numeric NOT NULL CHECK (unit_price > 0),
    last_updated timestamp NOT NULL
);


--Task 2.3
insert into customers values(1, 'my_email', '1234', '01-01-2020'); --successfully inserted
insert into customers values(1, NULL, '1234', NULL); --error
insert into customers values(1, 'my_email', NULL, '01-01-2020'); --null value successfully inserted


--Task 3.1
create table users(
    user_id serial primary key,
    username varchar(50) UNIQUE,
    email varchar(50) UNIQUE,
    created_at timestamp
);


--Task 3.2
create table course_enrollments(
    enrollment_id integer,
    student_id integer,
    course_code varchar(25),
    semester varchar(10),
    UNIQUE (student_id, course_code, semester)
);


--Task 3.3
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users (username)
VALUES ('user');
INSERT INTO users (username) --error
VALUES ('user');


--Task 4.1
CREATE TABLE departments(
    dept_id integer PRIMARY KEY,
    dept_name text NOT NULL,
    location text
);

INSERT INTO departments (dept_id) VALUES(1); --inserted
INSERT INTO departments (dept_id) VALUES(1); --must be unique
INSERT INTO departments (dept_id) VALUES(NULL); --can't be NULL


--Task 4.2
CREATE TABLE student_courses(
    student_id integer,
    course_id integer,
    enrollment_date date,
    grade text,
    PRIMARY KEY (student_id, course_id)
);


--Task 4.3
--PRIMARY KEY is a combination of UNIQUE and NOT NULL
--Use singe-column when you need 1 primary key column, use composite PRIMARY KEY when you need multiple primary key columns
--Because primary key constraint indicates that a column, or group of columns, can be used as a unique identifier for rows in the table


--Task 5.1
CREATE TABLE employees_dept(
    emp_id integer PRIMARY KEY,
    emp_name text NOT NULL,
    dept_id integer REFERENCES departments,
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'A', 1, '10-10-2025'); --successfully implemented
INSERT INTO employees_dept VALUES (2, 'B', 2, '11-10-2025'); --not working


--Task 5.2
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

--Sample data for authors
INSERT INTO authors (author_name, country)
VALUES
('George Orwell', 'United Kingdom'),
('Haruki Murakami', 'Japan'),
('J.K. Rowling', 'United Kingdom'),
('Ernest Hemingway', 'United States');

--Sample data for publishers
INSERT INTO publishers (publisher_name, city)
VALUES
('Penguin Books', 'London'),
('Vintage', 'New York'),
('Shinchosha', 'Tokyo'),
('Bloomsbury', 'London');

--Sample data for books
INSERT INTO books (title, author_id, publisher_id, publication_year, isbn)
VALUES
('1984', 1, 1, 1949, '9780451524935'),
('Kafka on the Shore', 2, 3, 2002, '9781400079278'),
('Harry Potter and the Philosopher''s Stone', 3, 4, 1997, '9780747532699'),
('The Old Man and the Sea', 4, 2, 1952, '9780684801223'),
('Norwegian Wood', 2, 3, 1987, '9780375704024');


--Task 5.3
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

-- Sample data
INSERT INTO categories (category_name) VALUES ('Electronics'), ('Books');

INSERT INTO products_fk (product_name, category_id)
VALUES ('Laptop', 1), ('Smartphone', 1), ('Novel', 2);

INSERT INTO orders (order_date)
VALUES ('2025-10-01'), ('2025-10-10');

INSERT INTO order_items (order_id, product_id, quantity)
VALUES (1, 1, 2), (1, 2, 1), (2, 3, 4);

-- 1. Try deleting category with products (should fail)
DELETE FROM categories WHERE category_id = 1;

-- 2. Delete an order and observe CASCADE behavior
DELETE FROM orders WHERE order_id = 1;

-- 3. Check results
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM categories;


--Task 6.1
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
    )
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);


-- Sample records for customers
INSERT INTO customers (name, email, phone, registration_date) VALUES
('Alice Johnson', 'alice@example.com', '+1234567890', '2024-03-10'),
('Bob Smith', 'bob@example.com', '+1987654321', '2024-05-22'),
('Charlie Brown', 'charlie@example.com', '+1098765432', '2024-06-15'),
('Diana Lee', 'diana@example.com', '+1123456789', '2024-08-01'),
('Ethan Miller', 'ethan@example.com', '+1222333444', '2024-09-12');

-- Sample records for products
INSERT INTO products (name, description, price, stock_quantity) VALUES
('Laptop', '15-inch display, 512GB SSD', 1200.00, 10),
('Smartphone', '6.5-inch OLED screen, 128GB storage', 800.00, 25),
('Headphones', 'Noise-cancelling over-ear model', 150.00, 50),
('Keyboard', 'Mechanical RGB keyboard', 90.00, 40),
('Mouse', 'Wireless ergonomic mouse', 45.00, 60);

-- Sample records for orders
INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-10-01', 1290.00, 'delivered'),
(2, '2024-10-03', 845.00, 'processing'),
(3, '2024-10-05', 135.00, 'pending'),
(4, '2024-10-08', 1245.00, 'shipped'),
(5, '2024-10-10', 90.00, 'cancelled');

-- Sample records for order_details
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),
(1, 5, 2, 45.00),
(2, 2, 1, 800.00),
(3, 3, 1, 135.00),
(4, 1, 1, 1200.00),
(4, 4, 1, 90.00),
(5, 4, 1, 90.00);





