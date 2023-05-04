CREATE TABLE IF NOT EXISTS haf_block_explorer.global_props(
    sync_enabled BOOLEAN DEFAULT true,
    check_in TIMESTAMP,
    latest_block_num INTEGER,
    latest_block_time TIMESTAMP
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.account_witness_votes (
    account VARCHAR NOT NULL,
    witness VARCHAR NOT NULL,
    approve BOOLEAN NOT NULL,
    CONSTRAINT account_witness_votes_pkey PRIMARY KEY (account, witness)
);

CREATE TABLE IF NOT EXISTS haf_block_explorer.account_witness_proxies (
    account VARCHAR NOT NULL,
    proxy VARCHAR NOT NULL,
    CONSTRAINT account_witness_proxies_pkey PRIMARY KEY (account)
);

