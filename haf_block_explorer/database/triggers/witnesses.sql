-- function for account_witness_vote_operation

CREATE OR REPLACE FUNCTION haf_block_explorer.account_witness_vote_operation( _block_num INT, _timestamp TIMESTAMP, _trx_id bytea, _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _witness VARCHAR;
            _approve BOOLEAN;
        BEGIN
            _account := _body -> 'value' ->> 'account';
            _witness := _body -> 'value' ->> 'witness';
            _approve := _body -> 'value' ->> 'approve';
            INSERT INTO haf_block_explorer.witness_votes_history (block_num, trx_id, timestamp, voter, witness, approve) VALUES (_block_num, _trx_id, _timestamp, _account, _witness, _approve);
            INSERT INTO haf_block_explorer.witness_votes_current (account, witness, approve) VALUES (_account, _witness, _approve) ON CONFLICT (account, witness) DO UPDATE SET approve = _approve;
        END;
    $$;

CREATE OR REPLACE FUNCTION haf_block_explorer.account_witness_proxy_operation( _block_num INT, _timestamp TIMESTAMP, _trx_id bytea, _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _proxy VARCHAR;
        BEGIN
            _account := _body -> 'value' ->> 'account';
            _proxy := _body -> 'value' ->> 'proxy';
            INSERT INTO haf_block_explorer.account_proxies (account, proxy) VALUES (_account, _proxy) ON CONFLICT (account) DO UPDATE SET proxy = _proxy;
        END;
    $$;

CREATE OR REPLACE FUNCTION haf_block_explorer.proxy_cleared( _block_num INT, _timestamp TIMESTAMP, _trx_id bytea, _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _proxy VARCHAR;
        BEGIN
            _account := _body -> 'value' ->> 'account';
            _proxy := _body -> 'value' ->> 'proxy';
            DELETE FROM haf_block_explorer.account_proxies WHERE account = _account AND proxy = _proxy;
        END;
    $$;

CREATE OR REPLACE FUNCTION haf_block_explorer.witness_shutdown_operation( _block_num INT, _timestamp TIMESTAMP, _trx_id bytea, _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
        BEGIN
            _account := _body -> 'value' ->> 'owner';
            UPDATE haf_block_explorer.witness_votes_current SET enabled = false WHERE witness = _account;
        END;
    $$;

/*
{"type":"witness_update_operation","value":{"owner":"anyx","url":"https://steemit.com/witness-category/@anyx/witness-application-anyx","block_signing_key":"STM6MRHXpPaEdzN2DVH6BtFsyJd7s2p8B6Qh9v35qjKBzgPLbCvRs","props":{"account_creation_fee":{"amount":"58800","precision":3,"nai":"@@000000021"},"maximum_block_size":65536,"hbd_interest_rate":300},"fee":{"amount":"0","precision":3,"nai":"@@000000021"}}}
*/
CREATE OR REPLACE FUNCTION haf_block_explorer.witness_update_operation( _block_num INT, _timestamp TIMESTAMP, _trx_id bytea, _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _url VARCHAR;
            _block_signing_key VARCHAR;
            _account_creation_fee NUMERIC;
            _maximum_block_size INT;
            _hbd_interest_rate INT;
        BEGIN
            _account := _body -> 'value' ->> 'owner';
            _url := _body -> 'value' ->> 'url';
            _block_signing_key := _body -> 'value' ->> 'block_signing_key';
            _account_creation_fee := (_body -> 'value' -> 'props' -> 'account_creation_fee' ->> 'amount')::NUMERIC;
            _maximum_block_size := (_body -> 'value' -> 'props' ->> 'maximum_block_size')::INT;
            _hbd_interest_rate := (_body -> 'value' -> 'props' ->> 'hbd_interest_rate')::INT;
            INSERT INTO haf_block_explorer.witness_properties (account, url, block_signing_key, account_creation_fee, maximum_block_size, hbd_interest_rate)
            VALUES (_account, _url, _block_signing_key, _account_creation_fee, _maximum_block_size, _hbd_interest_rate)
            ON CONFLICT (account) DO UPDATE SET url = _url, block_signing_key = _block_signing_key, account_creation_fee = _account_creation_fee, maximum_block_size = _maximum_block_size, hbd_interest_rate = _hbd_interest_rate;
            IF _block_signing_key = 'STM1111111111111111111111111111111114T1Anm' THEN
                --DELETE FROM haf_block_explorer.witness_votes_current WHERE witness = _account;
                UPDATE haf_block_explorer.witness_votes_current SET enabled = false WHERE witness = _account;
            END IF;
        END;
    $$;
