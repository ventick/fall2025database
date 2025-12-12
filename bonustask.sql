DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_matviews WHERE matviewname = 'salary_batch_summary_mv') THEN
    EXECUTE 'DROP MATERIALIZED VIEW salary_batch_summary_mv';
  END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END$$;

DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
  customer_id      BIGSERIAL PRIMARY KEY,
  iin              CHAR(12) UNIQUE NOT NULL CHECK (iin ~ '^[0-9]{12}$'),
  full_name        TEXT NOT NULL,
  phone            TEXT,
  email            TEXT,
  status           TEXT NOT NULL CHECK (status IN ('active','blocked','frozen')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  daily_limit_kzt  NUMERIC(18,2) NOT NULL CHECK (daily_limit_kzt >= 0)
);

CREATE TABLE accounts (
  account_id      BIGSERIAL PRIMARY KEY,
  customer_id     BIGINT NOT NULL REFERENCES customers(customer_id),
  account_number  TEXT UNIQUE NOT NULL, -- "IBAN format" in assignment; we keep it as text
  currency        TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  balance         NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  is_active       BOOLEAN NOT NULL DEFAULT true,
  opened_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at       TIMESTAMPTZ
);

CREATE TABLE exchange_rates (
  rate_id        BIGSERIAL PRIMARY KEY,
  from_currency  TEXT NOT NULL CHECK (from_currency IN ('KZT','USD','EUR','RUB')),
  to_currency    TEXT NOT NULL CHECK (to_currency IN ('KZT','USD','EUR','RUB')),
  rate           NUMERIC(18,8) NOT NULL CHECK (rate > 0),
  valid_from     TIMESTAMPTZ NOT NULL,
  valid_to       TIMESTAMPTZ NOT NULL,
  CHECK (valid_to > valid_from)
);

CREATE TABLE transactions (
  transaction_id     BIGSERIAL PRIMARY KEY,
  from_account_id    BIGINT REFERENCES accounts(account_id),
  to_account_id      BIGINT REFERENCES accounts(account_id),
  amount             NUMERIC(18,2) NOT NULL CHECK (amount > 0),
  currency           TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  exchange_rate      NUMERIC(18,8),
  amount_kzt         NUMERIC(18,2) NOT NULL CHECK (amount_kzt > 0),
  type               TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
  status             TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at       TIMESTAMPTZ,
  description        TEXT
);

CREATE TABLE audit_log (
  log_id       BIGSERIAL PRIMARY KEY,
  table_name   TEXT NOT NULL,
  record_id    BIGINT,
  action       TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_values   JSONB,
  new_values   JSONB,
  changed_by   TEXT NOT NULL DEFAULT current_user,
  changed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address   TEXT
);

CREATE TABLE salary_batches (
  batch_id              BIGSERIAL PRIMARY KEY,
  company_account_id    BIGINT NOT NULL REFERENCES accounts(account_id),
  company_account_number TEXT NOT NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  payments              JSONB NOT NULL,
  successful_count      INT NOT NULL,
  failed_count          INT NOT NULL,
  failed_details        JSONB NOT NULL
);

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('040101123456','Aruzhan Sadykova','+77010000001','aruzhan@gmail.com','active', 1000000),
('990202234567','Dias Nurpeisov','+77010000002','dias@gmail.com','active', 1000000),
('870303345678','Madina Tulegen','+77010000003','madina@gmail.com','active', 3000000), -- VIP
('050404456789','Ilyas Akhmetov','+77010000004','ilyas@gmail.com','blocked',1000000),
('060505567890','Amina Kassym','+77010000005','amina@gmail.com','frozen',1000000),
('010606678901','Timur Zhaksyly','+77010000006','timur@gmail.com','active', 1000000),
('020707789012','Dina Kairat','+77010000007','dina@gmail.com','active', 1000000),
('030808890123','Ruslan Bek','+77010000008','ruslan@gmail.com','active', 3000000), -- VIP
('041009901234','Zhanna Mukhamet','+77010000009','zhanna@gmail.com','active', 1000000),
('051010012345','Adilet Serik','+77010000010','adilet@gmail.com','active', 1000000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1,'KZ00KZTB000000000001','KZT', 800000, true),
(1,'KZ00KZTB000000000002','USD', 1200,   true),
(2,'KZ00KZTB000000000003','KZT', 150000, true),
(2,'KZ00KZTB000000000004','EUR', 900,    true),
(3,'KZ00KZTB000000000005','KZT', 2500000,true),
(3,'KZ00KZTB000000000006','RUB', 250000, true),
(4,'KZ00KZTB000000000007','KZT', 400000, true),  -- blocked customer
(5,'KZ00KZTB000000000008','KZT', 900000, true),  -- frozen customer
(6,'KZ00KZTB000000000009','USD', 500,    true),
(7,'KZ00KZTB000000000010','KZT', 300000, false), -- inactive
(8,'KZ00KZTB000000000011','KZT', 1000000,true),
(9,'KZ00KZTB000000000012','EUR', 1500,   true),
(10,'KZ00KZTB000000000013','RUB', 100000, true),
(10,'KZ00KZTB000000000014','KZT', 700000, true);

WITH v AS (
  SELECT
    now() - interval '30 days' AS vf,
    now() + interval '30 days' AS vt
)
INSERT INTO exchange_rates (from_currency,to_currency,rate,valid_from,valid_to)
SELECT 'USD','KZT',519.74, vf, vt FROM v
UNION ALL SELECT 'EUR','KZT',609.91, vf, vt FROM v
UNION ALL SELECT 'RUB','KZT',  5.52, vf, vt FROM v
UNION ALL SELECT 'KZT','USD', 1/519.74, vf, vt FROM v
UNION ALL SELECT 'KZT','EUR', 1/609.91, vf, vt FROM v
UNION ALL SELECT 'KZT','RUB', 1/5.52,   vf, vt FROM v;

INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, ip_address) VALUES
('customers',1,'INSERT',NULL,jsonb_build_object('iin','040101123456'), '127.0.0.1'),
('customers',2,'INSERT',NULL,jsonb_build_object('iin','990202234567'), '127.0.0.1'),
('customers',3,'INSERT',NULL,jsonb_build_object('iin','870303345678'), '127.0.0.1'),
('accounts',1,'INSERT',NULL,jsonb_build_object('account_number','KZ00KZTB000000000001'), '127.0.0.1'),
('accounts',2,'INSERT',NULL,jsonb_build_object('account_number','KZ00KZTB000000000002'), '127.0.0.1'),
('accounts',3,'INSERT',NULL,jsonb_build_object('account_number','KZ00KZTB000000000003'), '127.0.0.1'),
('accounts',4,'INSERT',NULL,jsonb_build_object('account_number','KZ00KZTB000000000004'), '127.0.0.1'),
('exchange_rates',1,'INSERT',NULL,jsonb_build_object('from','USD','to','KZT'), '127.0.0.1'),
('exchange_rates',2,'INSERT',NULL,jsonb_build_object('from','EUR','to','KZT'), '127.0.0.1'),
('exchange_rates',3,'INSERT',NULL,jsonb_build_object('from','RUB','to','KZT'), '127.0.0.1');

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description) VALUES
(1,  3, 50000,'KZT',1,50000,'transfer','completed', now()-interval '2 days', now()-interval '2 days','seed transfer'),
(3,  1, 20000,'KZT',1,20000,'transfer','completed', now()-interval '1 days', now()-interval '1 days','seed transfer'),
(2,  9,   50,'USD',519.74, round(50*519.74,2),'transfer','completed', now()-interval '1 days', now()-interval '1 days','usd->eur target'),
(4, NULL, 100,'EUR',609.91, round(100*609.91,2),'withdrawal','failed', now()-interval '1 days', NULL,'failed withdrawal sample'),
(NULL,5,  100000,'KZT',1,100000,'deposit','completed', now()-interval '3 days', now()-interval '3 days','seed deposit'),
(6, 10, 10000,'RUB',5.52, round(10000*5.52,2),'transfer','completed', now()-interval '5 hours', now()-interval '5 hours','rub transfer'),
(14,11, 100000,'KZT',1,100000,'transfer','completed', now()-interval '2 hours', now()-interval '2 hours','kzt transfer'),
(11,14,  50000,'KZT',1,50000,'transfer','completed', now()-interval '90 minutes', now()-interval '90 minutes','kzt transfer'),
(11,14,  50000,'KZT',1,50000,'transfer','completed', now()-interval '89 minutes', now()-interval '89 minutes','rapid transfer'),
(1,  3, 900000,'KZT',1,900000,'transfer','completed', now()-interval '30 minutes', now()-interval '30 minutes','big transfer for limit demo');

CREATE OR REPLACE FUNCTION fx_rate(p_from TEXT, p_to TEXT)
RETURNS NUMERIC(18,8)
LANGUAGE plpgsql
AS $$
DECLARE
  r NUMERIC(18,8);
  r1 NUMERIC(18,8);
  r2 NUMERIC(18,8);
BEGIN
  IF p_from = p_to THEN
    RETURN 1;
  END IF;

  SELECT er.rate INTO r
  FROM exchange_rates er
  WHERE er.from_currency = p_from
    AND er.to_currency   = p_to
    AND now() BETWEEN er.valid_from AND er.valid_to
  ORDER BY er.valid_from DESC
  LIMIT 1;

  IF r IS NOT NULL THEN
    RETURN r;
  END IF;

  IF p_from <> 'KZT' AND p_to <> 'KZT' THEN
    r1 := fx_rate(p_from, 'KZT');
    r2 := fx_rate('KZT', p_to);
    RETURN r1 * r2;
  END IF;

  RAISE EXCEPTION 'FX rate not found for % -> %', p_from, p_to
    USING ERRCODE = 'P0100';
END;
$$;

CREATE OR REPLACE PROCEDURE process_transfer(
  IN  p_from_account_number TEXT,
  IN  p_to_account_number   TEXT,
  IN  p_amount              NUMERIC(18,2),
  IN  p_currency            TEXT,
  IN  p_description         TEXT,
  OUT p_transaction_id      BIGINT,
  OUT p_status              TEXT,
  OUT p_error_code          TEXT,
  OUT p_error_message       TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_from_acc   accounts%ROWTYPE;
  v_to_acc     accounts%ROWTYPE;
  v_customer   customers%ROWTYPE;

  v_rate_from  NUMERIC(18,8);
  v_rate_to    NUMERIC(18,8);
  v_amount_from NUMERIC(18,2);
  v_amount_to   NUMERIC(18,2);
  v_amount_kzt  NUMERIC(18,2);

  v_today_sum_kzt NUMERIC(18,2);
BEGIN
  p_transaction_id := NULL;
  p_status := 'failed';
  p_error_code := NULL;
  p_error_message := NULL;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    p_error_code := 'P0001';
    p_error_message := 'amount_must_be_positive';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  IF p_currency NOT IN ('KZT','USD','EUR','RUB') THEN
    p_error_code := 'P0001';
    p_error_message := 'unsupported_currency';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  SELECT * INTO v_from_acc
  FROM accounts
  WHERE account_number = p_from_account_number
  FOR UPDATE;

  IF NOT FOUND OR v_from_acc.is_active IS DISTINCT FROM true THEN
    p_error_code := 'P0002';
    p_error_message := 'from_account_not_found_or_inactive';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  SELECT * INTO v_to_acc
  FROM accounts
  WHERE account_number = p_to_account_number
  FOR UPDATE;

  IF NOT FOUND OR v_to_acc.is_active IS DISTINCT FROM true THEN
    p_error_code := 'P0003';
    p_error_message := 'to_account_not_found_or_inactive';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  SELECT * INTO v_customer
  FROM customers
  WHERE customer_id = v_from_acc.customer_id;

  IF v_customer.status <> 'active' THEN
    p_error_code := 'P0004';
    p_error_message := 'customer_not_active';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  v_rate_from := fx_rate(p_currency, v_from_acc.currency);
  v_rate_to   := fx_rate(p_currency, v_to_acc.currency);

  v_amount_from := round(p_amount * v_rate_from, 2);
  v_amount_to   := round(p_amount * v_rate_to,   2);

  v_amount_kzt  := round(p_amount * fx_rate(p_currency,'KZT'), 2);

  SELECT COALESCE(SUM(t.amount_kzt),0)
  INTO v_today_sum_kzt
  FROM transactions t
  JOIN accounts a ON a.account_id = t.from_account_id
  WHERE a.customer_id = v_customer.customer_id
    AND t.status = 'completed'
    AND t.created_at::date = current_date;

  IF v_today_sum_kzt + v_amount_kzt > v_customer.daily_limit_kzt THEN
    p_error_code := 'P0005';
    p_error_message := 'daily_limit_exceeded';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  IF v_from_acc.balance < v_amount_from THEN
    p_error_code := 'P0006';
    p_error_message := 'insufficient_funds';
    RAISE EXCEPTION '%', p_error_message USING ERRCODE = p_error_code;
  END IF;

  INSERT INTO transactions (
    from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,
    type,status,created_at,description
  ) VALUES (
    v_from_acc.account_id, v_to_acc.account_id, p_amount, p_currency,
    fx_rate(p_currency,'KZT'), v_amount_kzt,
    'transfer','pending', now(), p_description
  )
  RETURNING transaction_id INTO p_transaction_id;

  UPDATE accounts SET balance = round(balance - v_amount_from, 2)
  WHERE account_id = v_from_acc.account_id;

  UPDATE accounts SET balance = round(balance + v_amount_to, 2)
  WHERE account_id = v_to_acc.account_id;

  UPDATE transactions
  SET status = 'completed',
      completed_at = now()
  WHERE transaction_id = p_transaction_id;

  INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, ip_address)
  VALUES (
    'transactions',
    p_transaction_id,
    'INSERT',
    NULL,
    jsonb_build_object(
      'from_account', p_from_account_number,
      'to_account', p_to_account_number,
      'amount', p_amount,
      'currency', p_currency,
      'amount_kzt', v_amount_kzt,
      'status', 'completed'
    ),
    '127.0.0.1'
  );

  p_status := 'completed';
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, ip_address)
    VALUES (
      'transactions',
      p_transaction_id,
      'INSERT',
      NULL,
      jsonb_build_object(
        'from_account', p_from_account_number,
        'to_account', p_to_account_number,
        'amount', p_amount,
        'currency', p_currency,
        'description', p_description,
        'error_sqlstate', SQLSTATE,
        'error_message', SQLERRM
      ),
      '127.0.0.1'
    );

    p_status := 'failed';
    p_error_code := COALESCE(p_error_code, SQLSTATE);
    p_error_message := COALESCE(p_error_message, SQLERRM);

    IF p_transaction_id IS NOT NULL THEN
      UPDATE transactions
      SET status = 'failed'
      WHERE transaction_id = p_transaction_id AND status = 'pending';
    END IF;

    RAISE;
END;
$$;


CREATE VIEW customer_balance_summary AS
WITH acc AS (
  SELECT
    c.customer_id,
    c.iin,
    c.full_name,
    c.status,
    c.daily_limit_kzt,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    round(a.balance * fx_rate(a.currency,'KZT'), 2) AS balance_kzt
  FROM customers c
  LEFT JOIN accounts a ON a.customer_id = c.customer_id
)
, totals AS (
  SELECT
    customer_id,
    COALESCE(SUM(balance_kzt),0) AS total_kzt
  FROM acc
  GROUP BY customer_id
)
, today_spend AS (
  SELECT
    c.customer_id,
    COALESCE(SUM(t.amount_kzt),0) AS today_kzt
  FROM customers c
  LEFT JOIN accounts a ON a.customer_id = c.customer_id
  LEFT JOIN transactions t ON t.from_account_id = a.account_id
    AND t.status='completed'
    AND t.created_at::date = current_date
  GROUP BY c.customer_id
)
SELECT
  acc.customer_id,
  acc.iin,
  acc.full_name,
  acc.status,
  acc.account_number,
  acc.currency,
  acc.balance,
  totals.total_kzt AS total_balance_kzt,
  round( (today_spend.today_kzt / NULLIF(acc.daily_limit_kzt,0)) * 100, 2) AS daily_limit_utilization_pct,
  RANK() OVER (ORDER BY totals.total_kzt DESC) AS rank_by_total_balance
FROM acc
JOIN totals USING (customer_id)
JOIN today_spend USING (customer_id);

CREATE VIEW daily_transaction_report AS
WITH d AS (
  SELECT
    created_at::date AS dt,
    type,
    COUNT(*) AS tx_count,
    SUM(amount_kzt) AS total_kzt,
    AVG(amount_kzt) AS avg_kzt
  FROM transactions
  WHERE status='completed'
  GROUP BY 1,2
)
SELECT
  dt,
  type,
  tx_count,
  total_kzt,
  avg_kzt,
  SUM(total_kzt) OVER (PARTITION BY type ORDER BY dt) AS running_total_kzt,
  round(
    (total_kzt - LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt))
    / NULLIF(LAG(total_kzt) OVER (PARTITION BY type ORDER BY dt),0) * 100
  , 2) AS day_over_day_growth_pct
FROM d
ORDER BY dt, type;

CREATE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH base AS (
  SELECT
    t.*,
    a.customer_id
  FROM transactions t
  LEFT JOIN accounts a ON a.account_id = t.from_account_id
  WHERE t.status='completed'
),
big_tx AS (
  SELECT transaction_id, 'over_5m_kzt' AS flag
  FROM base
  WHERE amount_kzt > 5000000
),
many_per_hour AS (
  SELECT
    customer_id,
    date_trunc('hour', created_at) AS hr,
    COUNT(*) AS cnt
  FROM base
  GROUP BY 1,2
  HAVING COUNT(*) > 10
),
rapid_seq AS (
  SELECT
    transaction_id,
    'rapid_sequential' AS flag
  FROM (
    SELECT
      b.*,
      LAG(created_at) OVER (PARTITION BY from_account_id ORDER BY created_at) AS prev_time
    FROM base b
  ) x
  WHERE prev_time IS NOT NULL
    AND (created_at - prev_time) < interval '1 minute'
)
SELECT
  b.transaction_id,
  b.from_account_id,
  b.to_account_id,
  b.amount,
  b.currency,
  b.amount_kzt,
  b.created_at,
  COALESCE(bt.flag,
           CASE WHEN mph.customer_id IS NOT NULL THEN 'more_than_10_in_hour' END,
           rs.flag) AS suspicious_flag
FROM base b
LEFT JOIN big_tx bt ON bt.transaction_id = b.transaction_id
LEFT JOIN many_per_hour mph ON mph.customer_id = b.customer_id AND mph.hr = date_trunc('hour', b.created_at)
LEFT JOIN rapid_seq rs ON rs.transaction_id = b.transaction_id
WHERE bt.transaction_id IS NOT NULL
   OR mph.customer_id IS NOT NULL
   OR rs.transaction_id IS NOT NULL;

CREATE INDEX idx_accounts_account_number_btree ON accounts(account_number);

CREATE INDEX idx_transactions_from_status_date ON transactions(from_account_id, status, created_at);

CREATE INDEX idx_accounts_active_only ON accounts(account_number) WHERE is_active = true;

CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

CREATE INDEX idx_audit_log_new_values_gin ON audit_log USING GIN (new_values);

CREATE INDEX idx_customers_iin_hash ON customers USING HASH (iin);

CREATE OR REPLACE PROCEDURE process_salary_batch(
  IN  p_company_account_number TEXT,
  IN  p_payments JSONB,
  OUT successful_count INT,
  OUT failed_count INT,
  OUT failed_details JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_company accounts%ROWTYPE;
  v_total_debit_company NUMERIC(18,2) := 0;

  v_item JSONB;
  v_iin TEXT;
  v_amount NUMERIC(18,2);
  v_currency TEXT;
  v_desc TEXT;

  v_rec_customer customers%ROWTYPE;
  v_rec_account accounts%ROWTYPE;

  v_amt_company NUMERIC(18,2);
  v_amt_rec     NUMERIC(18,2);
  v_amt_kzt     NUMERIC(18,2);

  v_tx_id BIGINT;

  v_failed JSONB := '[]'::jsonb;
BEGIN
  successful_count := 0;
  failed_count := 0;
  failed_details := '[]'::jsonb;

  IF jsonb_typeof(p_payments) <> 'array' THEN
    RAISE EXCEPTION 'payments must be JSONB array' USING ERRCODE='P1001';
  END IF;

  SELECT * INTO v_company
  FROM accounts
  WHERE account_number = p_company_account_number
  FOR UPDATE;

  IF NOT FOUND OR v_company.is_active IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'company_account_not_found_or_inactive' USING ERRCODE='P1002';
  END IF;

  PERFORM pg_advisory_xact_lock(v_company.account_id);

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    v_amount := (v_item->>'amount')::numeric;
    v_currency := COALESCE(v_item->>'currency', v_company.currency);
    IF v_amount IS NULL OR v_amount <= 0 THEN
      CONTINUE;
    END IF;
    v_amt_company := round(v_amount * fx_rate(v_currency, v_company.currency), 2);
    v_total_debit_company := v_total_debit_company + v_amt_company;
  END LOOP;

  IF v_company.balance < v_total_debit_company THEN
    RAISE EXCEPTION 'insufficient_company_balance_for_batch' USING ERRCODE='P1003';
  END IF;

  CREATE TEMP TABLE tmp_salary_success(
    to_account_id BIGINT,
    amount_to     NUMERIC(18,2),
    amount_kzt    NUMERIC(18,2),
    currency      TEXT,
    description   TEXT
  ) ON COMMIT DROP;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    SAVEPOINT sp_one;

    BEGIN
      v_iin := v_item->>'iin';
      v_amount := (v_item->>'amount')::numeric;
      v_currency := COALESCE(v_item->>'currency', v_company.currency);
      v_desc := COALESCE(v_item->>'description', 'salary payment');

      IF v_iin IS NULL OR v_iin !~ '^[0-9]{12}$' THEN
        RAISE EXCEPTION 'invalid_iin' USING ERRCODE='P1101';
      END IF;

      IF v_amount IS NULL OR v_amount <= 0 THEN
        RAISE EXCEPTION 'invalid_amount' USING ERRCODE='P1102';
      END IF;

      IF v_currency NOT IN ('KZT','USD','EUR','RUB') THEN
        RAISE EXCEPTION 'invalid_currency' USING ERRCODE='P1103';
      END IF;

      SELECT * INTO v_rec_customer
      FROM customers
      WHERE iin = v_iin;

      IF NOT FOUND OR v_rec_customer.status <> 'active' THEN
        RAISE EXCEPTION 'recipient_not_active_or_missing' USING ERRCODE='P1104';
      END IF;

      SELECT * INTO v_rec_account
      FROM accounts
      WHERE customer_id = v_rec_customer.customer_id
        AND currency = v_currency
        AND is_active = true
      ORDER BY account_id
      LIMIT 1;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'recipient_account_missing_for_currency' USING ERRCODE='P1105';
      END IF;

      v_amt_company := round(v_amount * fx_rate(v_currency, v_company.currency), 2);
      v_amt_rec     := round(v_amount * fx_rate(v_currency, v_rec_account.currency), 2); -- usually equals amount
      v_amt_kzt     := round(v_amount * fx_rate(v_currency,'KZT'), 2);

      INSERT INTO tmp_salary_success(to_account_id, amount_to, amount_kzt, currency, description)
      VALUES (v_rec_account.account_id, v_amt_rec, v_amt_kzt, v_currency, v_desc);

      INSERT INTO transactions (
        from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,
        type,status,created_at,description
      ) VALUES (
        v_company.account_id, v_rec_account.account_id, v_amount, v_currency,
        fx_rate(v_currency,'KZT'), v_amt_kzt,
        'salary','pending', now(), 'SALARY BATCH: ' || v_desc
      ) RETURNING transaction_id INTO v_tx_id;

      successful_count := successful_count + 1;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT sp_one;
        failed_count := failed_count + 1;

        v_failed := v_failed || jsonb_build_object(
          'iin', COALESCE(v_iin, v_item->>'iin'),
          'error_sqlstate', SQLSTATE,
          'error_message', SQLERRM,
          'item', v_item
        );

        -- Audit failed attempt
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, ip_address)
        VALUES (
          'transactions', NULL, 'INSERT', NULL,
          jsonb_build_object('batch_company', p_company_account_number, 'error_sqlstate', SQLSTATE, 'error_message', SQLERRM, 'item', v_item),
          '127.0.0.1'
        );
    END;

  END LOOP;

  SELECT COALESCE(SUM( round((t.amount)::numeric * fx_rate(t.currency, v_company.currency), 2) ),0)
  INTO v_total_debit_company
  FROM transactions t
  WHERE t.from_account_id = v_company.account_id
    AND t.type = 'salary'
    AND t.status = 'pending'
    AND t.description LIKE 'SALARY BATCH:%'
    AND t.created_at::date = current_date;

  UPDATE accounts
  SET balance = round(balance - v_total_debit_company, 2)
  WHERE account_id = v_company.account_id;

  UPDATE accounts a
  SET balance = round(a.balance + s.sum_amount_to, 2)
  FROM (
    SELECT to_account_id, SUM(amount_to) AS sum_amount_to
    FROM tmp_salary_success
    GROUP BY to_account_id
  ) s
  WHERE a.account_id = s.to_account_id;

  UPDATE transactions
  SET status = 'completed', completed_at = now()
  WHERE from_account_id = v_company.account_id
    AND type='salary'
    AND status='pending'
    AND description LIKE 'SALARY BATCH:%'
    AND created_at::date = current_date;

  failed_details := v_failed;

  INSERT INTO salary_batches(company_account_id, company_account_number, payments, successful_count, failed_count, failed_details)
  VALUES (v_company.account_id, p_company_account_number, p_payments, successful_count, failed_count, failed_details);

  INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, ip_address)
  VALUES (
    'salary_batches', currval('salary_batches_batch_id_seq'), 'INSERT', NULL,
    jsonb_build_object('company', p_company_account_number, 'successful', successful_count, 'failed', failed_count),
    '127.0.0.1'
  );

END;
$$;

CREATE MATERIALIZED VIEW salary_batch_summary_mv AS
SELECT
  batch_id,
  company_account_number,
  created_at::date AS batch_date,
  successful_count,
  failed_count
FROM salary_batches
ORDER BY batch_id DESC;
