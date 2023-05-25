CREATE TABLE IF NOT EXISTS haf_block_explorer.global_props(
    sync_enabled BOOLEAN DEFAULT true,
    check_in TIMESTAMP,
    latest_block_num INTEGER,
    latest_block_time TIMESTAMP
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.witness_votes_history(
    id SERIAL PRIMARY KEY,
    block_num BIGINT NOT NULL,
    trx_id BYTEA NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    voter VARCHAR NOT NULL,
    witness VARCHAR NOT NULL,
    approve BOOLEAN NOT NULL
);


CREATE TABLE IF NOT EXISTS haf_block_explorer.witness_votes_current (
    account VARCHAR NOT NULL,
    witness VARCHAR NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    approve BOOLEAN NOT NULL,
    CONSTRAINT account_witness_votes_pkey PRIMARY KEY (account, witness)
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.account_balance_state(
    account VARCHAR NOT NULL,
    delegated BIGINT NOT NULL,
    delegation_received BIGINT NOT NULL,
    CONSTRAINT account_balance_state_pkey PRIMARY KEY (account)
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.witness_properties(
    account VARCHAR NOT NULL PRIMARY KEY,
    url VARCHAR NOT NULL,
    block_signing_key VARCHAR NOT NULL,
    account_creation_fee BIGINT NOT NULL,
    maximum_block_size INTEGER NOT NULL,
    hbd_interest_rate INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS haf_block_explorer.account_proxies (
    account VARCHAR NOT NULL,
    proxy VARCHAR NOT NULL,
    CONSTRAINT account_witness_proxies_pkey PRIMARY KEY (account)
);

-- delegations

CREATE TABLE IF NOT EXISTS haf_block_explorer.delegations_vesting(
    id BIGSERIAL PRIMARY KEY,
    block_num INTEGER NOT NULL,
    created TIMESTAMP NOT NULL,
    trx_id BYTEA NOT NULL,
    delegator VARCHAR(16) NOT NULL,
    delegatee VARCHAR(16) NOT NULL,
    amount BIGINT
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.delegations_vesting_returns(
    id BIGSERIAL PRIMARY KEY,
    block_num INTEGER NOT NULL,
    created TIMESTAMP NOT NULL,
    trx_id BYTEA NOT NULL,
    account VARCHAR(16) NOT NULL,
    amount BIGINT,
    UNIQUE (account)
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.delegations_balances(
    id BIGSERIAL PRIMARY KEY,
    delegator VARCHAR(16) NOT NULL,
    delegatee VARCHAR(16) NOT NULL,
    amount BIGINT DEFAULT 0,
    UNIQUE (delegator,delegatee)
);