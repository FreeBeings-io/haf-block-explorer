DROP SCHEMA IF EXISTS btracker_app CASCADE;

CREATE SCHEMA IF NOT EXISTS btracker_app;

CREATE OR REPLACE FUNCTION btracker_app.define_schema()
RETURNS VOID
LANGUAGE 'plpgsql'
AS $$
BEGIN

RAISE NOTICE 'Attempting to create an application schema tables...';

CREATE TABLE IF NOT EXISTS btracker_app.app_status
(
  continue_processing BOOLEAN NOT NULL,
  last_processed_block INT NOT NULL
);

INSERT INTO btracker_app.app_status
(continue_processing, last_processed_block)
VALUES
(True, 0)
;


CREATE TABLE IF NOT EXISTS btracker_app.current_account_balances
(
  account VARCHAR NOT NULL, -- Balance owner account
  nai     INT NOT NULL,     -- Balance type (currency)
  balance BIGINT NOT NULL,  -- Balance value (amount of held tokens)
  source_op BIGINT NOT NULL,-- The operation triggered last balance change
  source_op_block INT NOT NULL, -- Block containing the source operation

  CONSTRAINT pk_current_account_balances PRIMARY KEY (account, nai)
);

CREATE TABLE IF NOT EXISTS btracker_app.account_balance_history
(
  account VARCHAR NOT NULL, -- Balance owner account
  nai     INT NOT NULL,     -- Balance type (currency)
  balance BIGINT NOT NULL,  -- Balance value after a change
  source_op BIGINT NOT NULL,-- The operation triggered given balance change
  source_op_block INT NOT NULL -- Block containing the source operation
  
  /** Because of bugs in blockchain at very begin, it was possible to make a transfer to self. See summon transfer in block 118570,
      like also `register` transfer in block 818601
      That's why constraint has been eliminated.
  */
  --CONSTRAINT pk_account_balance_history PRIMARY KEY (account, source_op_block, nai, source_op)
);

--recreate role for reading data
IF (SELECT 1 FROM pg_roles WHERE rolname='btracker_user') IS NOT NULL THEN
  DROP OWNED BY btracker_user;
END IF;
DROP ROLE IF EXISTS btracker_user;
CREATE ROLE btracker_user LOGIN PASSWORD 'btracker_user';
GRANT hive_applications_group TO btracker_user;
GRANT USAGE ON SCHEMA btracker_app to btracker_user;
GRANT SELECT ON btracker_app.account_balance_history, hive.blocks TO btracker_user;

-- add ability for haf_admin to switch to btracker_user role
GRANT btracker_user TO haf_app_admin;

-- add btracker_app schema owner
DROP ROLE IF EXISTS btracker_owner;
CREATE ROLE btracker_owner;
ALTER SCHEMA btracker_app OWNER TO btracker_owner;
END
$$
;

--- Helper function telling application main-loop to continue execution.
CREATE OR REPLACE FUNCTION btracker_app.continueProcessing()
RETURNS BOOLEAN
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  RETURN continue_processing FROM btracker_app.app_status LIMIT 1;
END
$$
;

CREATE OR REPLACE FUNCTION btracker_app.allowProcessing()
RETURNS VOID
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  UPDATE btracker_app.app_status SET continue_processing = True;
END
$$
;

--- Helper function to be called from separate transaction (must be committed) to safely stop execution of the application.
CREATE OR REPLACE FUNCTION btracker_app.stopProcessing()
RETURNS VOID
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  UPDATE btracker_app.app_status SET continue_processing = False;
END
$$
;

CREATE OR REPLACE FUNCTION btracker_app.storeLastProcessedBlock(IN _lastBlock INT)
RETURNS VOID
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  UPDATE btracker_app.app_status SET last_processed_block = _lastBlock;
END
$$
;

CREATE OR REPLACE FUNCTION btracker_app.lastProcessedBlock()
RETURNS INT
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  RETURN last_processed_block FROM btracker_app.app_status LIMIT 1;
END
$$
;

CREATE OR REPLACE FUNCTION btracker_app.process_block_range_data_c(in _from INT, in _to INT, IN _report_step INT = 1000)
RETURNS VOID
LANGUAGE 'plpgsql'
SET from_collapse_limit = 16
SET join_collapse_limit = 16
SET jit = OFF
AS
$$
DECLARE
  __balance_change RECORD;
  __current_balance BIGINT;
  __last_reported_block INT := 0;
BEGIN
FOR __balance_change IN
  WITH balance_impacting_ops AS
  (
    SELECT ot.id
    FROM hive.operation_types ot
    WHERE ot.name IN (SELECT * FROM hive.get_balance_impacting_operations())
  )
  SELECT bio.account_name AS account, bio.asset_symbol_nai AS nai, bio.amount as balance, ho.id AS source_op, ho.block_num AS source_op_block
  FROM hive.operations_view ho --- APP specific view must be used, to correctly handle reversible part of the data.
  JOIN balance_impacting_ops b ON ho.op_type_id = b.id
  JOIN LATERAL
  (
    SELECT * FROM hive.get_impacted_balances(ho.body, ho.block_num)
  ) bio ON true
  WHERE ho.block_num BETWEEN _from AND _to
  ORDER BY ho.block_num, ho.id
LOOP
  INSERT INTO btracker_app.current_account_balances
    (account, nai, source_op, source_op_block, balance)
  SELECT __balance_change.account, __balance_change.nai, __balance_change.source_op, __balance_change.source_op_block, __balance_change.balance
  ON CONFLICT ON CONSTRAINT pk_current_account_balances DO
    UPDATE SET balance = btracker_app.current_account_balances.balance + EXCLUDED.balance,
               source_op = EXCLUDED.source_op,
               source_op_block = EXCLUDED.source_op_block
  RETURNING balance into __current_balance;

  INSERT INTO btracker_app.account_balance_history
    (account, nai, source_op, source_op_block, balance)
  SELECT __balance_change.account, __balance_change.nai, __balance_change.source_op, __balance_change.source_op_block, COALESCE(__current_balance, 0)
  ;

--	if __balance_change.source_op_block = 199701 then
--	RAISE NOTICE 'Balance change data: account: %, amount change: %, source_op: %, source_block: %, current_balance: %', __balance_change.account, __balance_change.balance, __balance_change.source_op, __balance_change.source_op_block, COALESCE(__current_balance, 0);
--	end if;

  IF __balance_change.source_op_block % _report_step = 0 AND __last_reported_block != __balance_change.source_op_block THEN
    RAISE NOTICE 'Processed data for block: %', __balance_change.source_op_block;
    __last_reported_block := __balance_change.source_op_block;
  END IF;
END LOOP;

END
$$
;

CREATE OR REPLACE PROCEDURE btracker_app.processBlock(in _block INT)
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  PERFORM btracker_app.process_block_range_data_c(_block, _block);
  COMMIT; -- For single block processing we want to commit all changes for each one.
END
$$
;


CREATE OR REPLACE PROCEDURE btracker_app.create_indexes()
LANGUAGE 'plpgsql'
AS
$$
BEGIN
  CREATE INDEX idx_btracker_app_account_balance_history_account ON btracker_app.account_balance_history(account);
  CREATE INDEX idx_btracker_app_account_balance_history_nai ON btracker_app.account_balance_history(nai);
END
$$
;

SELECT btracker_app.define_schema();
--CALL btracker_app.create_indexes();