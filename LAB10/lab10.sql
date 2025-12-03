--Task 1
BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
COMMIT;

--Alice now has 900 and Bob has 600
--This is important because we want to subtract the balance from one account and add it to another.
--Alice would have lost 100

--Task 2
BEGIN;
UPDATE accounts SET balance = balance - 500.00
 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
-- Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
--a) 400
--b) again 900
--c) if I have an error or if I accidentally changed the data

--Task 3
BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Wally';
COMMIT;
--a) 800, 600, 850 respectively
--b) no because we rolled back
--c) we can create a savepoint before risky commands

--Task 4
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--a) Before it sees Coke and Pepsi, after only Fanta
--b) Only Fanta
--c) READ COMMITTED sees data that commited,

--5
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--a) Terminal 1 does not see the new product inserted by Terminal 2.
--b) Phantom read is when a transaction sees new rows inserted or deleted by other transactions between two queries within the same transaction.
--c) SERIALIZABLE isolation level prevents phantom reads.

--Task 6
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--a) Terminal 1 may see the price of 99.99 before Terminal 2 rolled back. This is problematic because it reads uncommitted, potentially non-existent data.
--b) Dirty read is when a transaction reads data written by another transaction that has not yet committed.
--c) READ UNCOMMITTED should be avoided because it can lead to inconsistent, incorrect, or temporary data being used.

--Exercise 1
BEGIN;
DO $$
DECLARE
    bob_balance numeric;
BEGIN
    SELECT balance INTO bob_balance FROM accounts WHERE name='Bob';
    IF bob_balance >= 200 THEN
        UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
        UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
    ELSE
        RAISE NOTICE 'Insufficient funds';
    END IF;
END $$;
COMMIT;

--Exercise 2
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Coke', 2.50);
SAVEPOINT sp1;
UPDATE products SET price = 3.00 WHERE product = 'Coke';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'Coke';
ROLLBACK TO sp1;
COMMIT;

--Exercise 3
-- User A
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='SharedAccount';
UPDATE accounts SET balance = balance - 100 WHERE name='SharedAccount';
COMMIT;

-- User B (simultaneously)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='SharedAccount';
UPDATE accounts SET balance = balance - 150 WHERE name='SharedAccount';
COMMIT;

--Exercise 4
-- Without transactions
SELECT MAX(price) FROM products;
SELECT MIN(price) FROM products;
-- Sally may see MAX < MIN due to interleaved updates

-- With transactions
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price) FROM products;
SELECT MIN(price) FROM products;
COMMIT;
-- Sally now sees consistent MAX >= MIN
