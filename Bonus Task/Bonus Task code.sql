/*
    Lab: Bonus Banking System
    ID: 24B031787
*/

-- Cleaning up previous runs
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TYPE IF EXISTS txn_type CASCADE;
DROP TYPE IF EXISTS txn_status CASCADE;

-- Enums for data integrity
CREATE TYPE txn_type AS ENUM ('transfer', 'deposit', 'withdrawal', 'salary_payout');
CREATE TYPE txn_status AS ENUM ('pending', 'completed', 'failed', 'reversed');

-- Core Tables
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15,2) DEFAULT 1000000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number VARCHAR(20) UNIQUE NOT NULL,
    currency CHAR(3) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate DECIMAL(10,6) NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    UNIQUE(from_currency, to_currency)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.0,
    amount_kzt DECIMAL(15,2),
    type txn_type NOT NULL,
    status txn_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

-- Using JSONB for the audit log as requested to handle flexible schema changes
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

-- Initial Data Population
INSERT INTO customers (iin, full_name, email, status) VALUES
('951212300451', 'Arman Ospanov', 'arman@kbtu.kz', 'active'),
('980101400502', 'Elena Kim', 'elena@gmail.com', 'active'),
('850505300100', 'Big Corp LLP', 'finance@bigcorp.kz', 'active'),
('990909300200', 'Suspicious User', 'hacker@dark.net', 'frozen');

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ501', 'KZT', 500000.00),
(1, 'KZ502', 'USD', 1000.00),
(2, 'KZ601', 'KZT', 250000.00),
(2, 'KZ602', 'EUR', 500.00),
(3, 'KZ999', 'KZT', 100000000.00),
(4, 'KZ000', 'KZT', 5000.00);

-- Rates (Base KZT)
INSERT INTO exchange_rates (from_currency, to_currency, rate) VALUES
('USD', 'KZT', 485.50), ('KZT', 'USD', 0.00206),
('EUR', 'KZT', 520.00), ('KZT', 'EUR', 0.00192),
('RUB', 'KZT', 5.10),   ('KZT', 'RUB', 0.196),
('KZT', 'KZT', 1.0);

-- =========================================================
-- TASK 1: Transfer Procedure [cite: 17]
-- =========================================================
CREATE OR REPLACE PROCEDURE process_transfer(
    sender_iban VARCHAR,
    receiver_iban VARCHAR,
    transfer_amount DECIMAL,
    transfer_currency VARCHAR,
    txn_desc TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- IDs and basic info
    sender_id INT;
    receiver_id INT;
    sender_cust_id INT;
    sender_status VARCHAR;

    -- Calculation variables
    sender_balance DECIMAL;
    daily_limit DECIMAL;
    current_spent DECIMAL;
    conversion_rate DECIMAL := 1.0;
    amount_in_kzt DECIMAL; -- needed for limit check
    final_credit_amount DECIMAL; -- what the receiver actually gets
    receiver_curr VARCHAR;
BEGIN
    IF transfer_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be positive';
    END IF;

    -- Get account IDs first to establish locking order
    SELECT account_id, customer_id INTO sender_id, sender_cust_id
    FROM accounts WHERE account_number = sender_iban;

    SELECT account_id, currency INTO receiver_id, receiver_curr
    FROM accounts WHERE account_number = receiver_iban;

    IF sender_id IS NULL OR receiver_id IS NULL THEN
        RAISE EXCEPTION 'One or both account numbers are invalid';
    END IF;

    -- Deadlock Prevention: Always lock the smaller ID first [cite: 27]
    -- This ensures that if two people send money to each other at the same time,
    -- one will wait for the other instead of crashing.
    IF sender_id < receiver_id THEN
        PERFORM 1 FROM accounts WHERE account_id = sender_id FOR UPDATE;
        PERFORM 1 FROM accounts WHERE account_id = receiver_id FOR UPDATE;
    ELSE
        PERFORM 1 FROM accounts WHERE account_id = receiver_id FOR UPDATE;
        PERFORM 1 FROM accounts WHERE account_id = sender_id FOR UPDATE;
    END IF;

    -- Check if customer is allowed to transact [cite: 24]
    SELECT status, daily_limit_kzt INTO sender_status, daily_limit
    FROM customers WHERE customer_id = sender_cust_id;

    IF sender_status != 'active' THEN
        -- Log the failed attempt as per requirements
        INSERT INTO audit_log (table_name, action, new_values)
        VALUES ('transactions', 'BLOCK', jsonb_build_object('account', sender_iban, 'reason', 'Customer status: ' || sender_status));
        RAISE EXCEPTION 'Sender account is not active';
    END IF;

    -- Check Balance [cite: 25]
    SELECT balance INTO sender_balance FROM accounts WHERE account_id = sender_id;
    IF sender_balance < transfer_amount THEN
        RAISE EXCEPTION 'Insufficient balance. You have: %', sender_balance;
    END IF;

    -- Normalize amount to KZT for daily limit checking [cite: 26]
    IF transfer_currency != 'KZT' THEN
        SELECT rate INTO amount_in_kzt FROM exchange_rates
        WHERE from_currency = transfer_currency AND to_currency = 'KZT';

        -- Safe calculation
        amount_in_kzt := transfer_amount * COALESCE(amount_in_kzt, 0);
    ELSE
        amount_in_kzt := transfer_amount;
    END IF;

    -- Check today's usage
    SELECT COALESCE(SUM(amount_kzt), 0) INTO current_spent
    FROM transactions
    WHERE from_account_id = sender_id
    AND created_at::date = CURRENT_DATE
    AND type = 'transfer';

    IF (current_spent + amount_in_kzt) > daily_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded. You have used % of %', current_spent, daily_limit;
    END IF;

    -- Calculate exchange rate if currencies are different
    IF transfer_currency != receiver_curr THEN
        SELECT rate INTO conversion_rate FROM exchange_rates
        WHERE from_currency = transfer_currency AND to_currency = receiver_curr;

        IF conversion_rate IS NULL THEN
            RAISE EXCEPTION 'No exchange rate found for % to %', transfer_currency, receiver_curr;
        END IF;
    END IF;

    final_credit_amount := transfer_amount * conversion_rate;

    -- Perform the actual money movement
    UPDATE accounts SET balance = balance - transfer_amount WHERE account_id = sender_id;
    UPDATE accounts SET balance = balance + final_credit_amount WHERE account_id = receiver_id;

    -- Record the transaction
    INSERT INTO transactions (
        from_account_id, to_account_id, amount, currency,
        exchange_rate, amount_kzt, type, status, completed_at, description
    ) VALUES (
        sender_id, receiver_id, transfer_amount, transfer_currency,
        conversion_rate, amount_in_kzt, 'transfer', 'completed', NOW(), txn_desc
    );

    -- Audit trail [cite: 29]
    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES ('transactions', lastval(), 'INSERT',
            jsonb_build_object('amt', transfer_amount, 'sender', sender_iban, 'receiver', receiver_iban));

EXCEPTION
    WHEN OTHERS THEN
        -- Catch-all for any other errors to ensure we log them
        INSERT INTO audit_log (table_name, action, new_values)
        VALUES ('transactions', 'ERROR', jsonb_build_object('error_msg', SQLERRM));
        RAISE; -- Re-throw the error so the app knows it failed
END;
$$;

-- =========================================================
-- TASK 2: Views [cite: 30]
-- =========================================================

-- 1. Customer Summary: Converting everything to KZT to see true total balance
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.full_name,
    a.account_number,
    a.balance,
    a.currency,
    (a.balance * COALESCE(er.rate, 1)) AS balance_in_kzt,
    c.daily_limit_kzt,
    -- Ranking customers by wealth
    RANK() OVER (ORDER BY SUM(a.balance * COALESCE(er.rate, 1)) OVER (PARTITION BY c.customer_id) DESC) as wealth_rank
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN exchange_rates er ON a.currency = er.from_currency AND er.to_currency = 'KZT';

-- 2. Daily Report with Window Functions
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    created_at::date as report_date,
    type,
    COUNT(*) as total_txns,
    SUM(amount_kzt) as volume_kzt,
    AVG(amount_kzt) as avg_txn_size,
    -- Running total for the day
    SUM(SUM(amount_kzt)) OVER (ORDER BY created_at::date) as running_total,
    -- Growth calc: (Current - Prev) / Prev
    (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::date))
    / NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::date), 0) * 100 as growth_percentage
FROM transactions
WHERE status = 'completed'
GROUP BY created_at::date, type;

-- 3. Security View [cite: 39]
-- Using SECURITY BARRIER to ensure filters run before user queries
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
WITH transaction_stats AS (
    SELECT *,
           -- Look at previous transaction time
           LAG(created_at) OVER (PARTITION BY from_account_id ORDER BY created_at) as last_txn_time,
           -- Count txns in the current hour block
           COUNT(*) OVER (PARTITION BY from_account_id, date_trunc('hour', created_at)) as hourly_count
    FROM transactions
)
SELECT transaction_id, from_account_id, amount_kzt, description, 'Limit Breach' as flag
FROM transactions WHERE amount_kzt > 5000000
UNION ALL
SELECT transaction_id, from_account_id, amount_kzt, description, 'Spamming'
FROM transaction_stats WHERE hourly_count > 10
UNION ALL
SELECT transaction_id, from_account_id, amount_kzt, description, 'Fast Fingers'
FROM transaction_stats WHERE created_at - last_txn_time < interval '1 minute';

-- =========================================================
-- TASK 3: Indexes [cite: 41]
-- =========================================================

-- Foreign keys usually need indexes for JOIN performance
CREATE INDEX idx_txn_fkeys ON transactions(from_account_id, to_account_id);

-- Hash index is faster for equality checks like currency
CREATE INDEX idx_acc_currency ON accounts USING HASH (currency);

-- Partial index: we mostly query active accounts, so let's save space
CREATE INDEX idx_active_accs ON accounts(account_number) WHERE is_active = TRUE;

-- Composite index for the "Show me my history" query
CREATE INDEX idx_history_lookup ON transactions(from_account_id, created_at DESC);

-- GIN index for the JSON log (audit requirements)
CREATE INDEX idx_audit_search ON audit_log USING GIN (new_values);

-- Functional index for login/search by email (case insensitive)
CREATE INDEX idx_email_search ON customers(lower(email));

-- =========================================================
-- TASK 4: Batch Processing [cite: 49]
-- =========================================================
CREATE OR REPLACE PROCEDURE process_salary_batch(
    comp_iban VARCHAR,
    payment_list JSONB -- Array of objects: {iin, amount, description}
)
LANGUAGE plpgsql
AS $$
DECLARE
    comp_id INT;
    current_comp_bal DECIMAL;
    single_payment JSONB;
    total_batch_cost DECIMAL := 0;

    employee_acc_id INT;
    employee_iin VARCHAR;
    pay_amount DECIMAL;

    -- Counters for reporting
    success_cnt INT := 0;
    fail_cnt INT := 0;
    fail_reasons JSONB := '[]'::JSONB;
BEGIN
    -- Lock company account first
    SELECT account_id, balance INTO comp_id, current_comp_bal
    FROM accounts WHERE account_number = comp_iban FOR UPDATE;

    IF comp_id IS NULL THEN
        RAISE EXCEPTION 'Company account does not exist';
    END IF;

    -- Prevent two batches running at once for same company [cite: 57]
    -- Using advisory lock on the company ID
    IF NOT pg_try_advisory_xact_lock(comp_id) THEN
        RAISE EXCEPTION 'Batch is already running for this company';
    END IF;

    -- Calculate total cost first
    FOR single_payment IN SELECT * FROM jsonb_array_elements(payment_list)
    LOOP
        total_batch_cost := total_batch_cost + (single_payment->>'amount')::DECIMAL;
    END LOOP;

    IF current_comp_bal < total_batch_cost THEN
        RAISE EXCEPTION 'Not enough money in company account. Need: %', total_batch_cost;
    END IF;

    -- Process each employee
    FOR single_payment IN SELECT * FROM jsonb_array_elements(payment_list)
    LOOP
        employee_iin := single_payment->>'iin';
        pay_amount := (single_payment->>'amount')::DECIMAL;

        -- Find the KZT account for the employee
        SELECT a.account_id INTO employee_acc_id
        FROM accounts a
        JOIN customers c ON a.customer_id = c.customer_id
        WHERE c.iin = employee_iin AND a.currency = 'KZT' AND a.is_active = TRUE
        LIMIT 1;

        IF employee_acc_id IS NOT NULL THEN
            -- We use a nested block with EXCEPTION to handle individual failures
            -- without killing the whole batch (Requirement: Partial completion)
            BEGIN
                -- Move the money
                UPDATE accounts SET balance = balance - pay_amount WHERE account_id = comp_id;
                UPDATE accounts SET balance = balance + pay_amount WHERE account_id = employee_acc_id;

                INSERT INTO transactions (
                    from_account_id, to_account_id, amount, currency,
                    amount_kzt, type, status, description
                ) VALUES (
                    comp_id, employee_acc_id, pay_amount, 'KZT',
                    pay_amount, 'salary_payout', 'completed', single_payment->>'description'
                );

                success_cnt := success_cnt + 1;
            EXCEPTION WHEN OTHERS THEN
                -- If something breaks for one person, log it and continue
                fail_cnt := fail_cnt + 1;
                fail_reasons := fail_reasons || jsonb_build_object('iin', employee_iin, 'msg', SQLERRM);
            END;
        ELSE
            -- Employee not found or no KZT account
            fail_cnt := fail_cnt + 1;
            fail_reasons := fail_reasons || jsonb_build_object('iin', employee_iin, 'msg', 'No active KZT account found');
        END IF;
    END LOOP;

    -- Summary log
    INSERT INTO audit_log (table_name, action, new_values)
    VALUES ('batch_run', 'SUMMARY', jsonb_build_object('ok', success_cnt, 'bad', fail_cnt, 'errors', fail_reasons));

    RAISE NOTICE 'Batch finished. OK: %, Bad: %', success_cnt, fail_cnt;
END;
$$;

--=======================================
-- EXPLAIN ANALYZE Outputs
--=======================================

SET enable_seqscan = OFF;

EXPLAIN ANALYZE SELECT * FROM accounts WHERE currency = 'KZT';
-- "Bitmap Index Scan on idx_acc_currency"

EXPLAIN ANALYZE SELECT * FROM accounts WHERE account_number = 'KZ501' AND is_active = TRUE;
-- "Index Scan using idx_active_accs"

EXPLAIN ANALYZE SELECT * FROM audit_log WHERE new_values @> '{"sender": "KZ501"}';
-- "Bitmap Index Scan on idx_audit_search"

EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = 'arman@kbtu.kz';
-- "Index Scan using idx_email_search"


-- ==========================================
-- TEST CASE SUITE
-- ==========================================

-- TEST 1: SUCCESSFUL TRANSFER
-- Arman sends 100 USD to Elena (Currency conversion applied)
CALL process_transfer('KZ502', 'KZ601', 100.00, 'USD', 'Test Transfer 1');

-- Verify results:
SELECT * FROM transactions WHERE description = 'Test Transfer 1';
SELECT * FROM accounts WHERE account_number IN ('KZ502', 'KZ601');

-- TEST 2: FAILED TRANSFER (Insufficient Funds)
-- Elena tries to send 1,000,000 EUR (She only has 500)
DO $$
BEGIN
    CALL process_transfer('KZ602', 'KZ501', 1000000.00, 'EUR', 'Fail Test');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected Error Caught: %', SQLERRM;
END $$;

-- TEST 3: BATCH SALARY PROCESSING
-- Big Corp pays Arman and Elena
CALL process_salary_batch(
    'KZ999',
    '[
        {"iin": "951212300451", "amount": 50000, "description": "Salary Sept"},
        {"iin": "980101400502", "amount": 60000, "description": "Salary Sept"},
        {"iin": "000000000000", "amount": 10000, "description": "Invalid User"}
     ]'::jsonb
);
-- Note: The Invalid User should fail, but the other two should succeed (Partial Batch).

-- Verify Audit Log for Batch Summary:
SELECT * FROM audit_log WHERE action = 'SUMMARY';


-- ==========================================
-- Concurrency Demonstration
-- ==========================================
BEGIN;
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;

COMMIT;

SET enable_seqscan = ON;



