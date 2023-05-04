-- function for account_witness_vote_operation
/*
    {
        "type": "account_witness_vote_operation",
        "value": {
            "account": "catavele",
            "witness": "curie",
            "approve": true
        }
    }

*/
CREATE OR REPLACE FUNCTION haf_block_explorer.account_witness_vote_operation( _body JSONB )
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
            INSERT INTO haf_block_explorer.account_witness_votes (account, witness, approve) VALUES (_account, _witness, _approve) ON CONFLICT (account, witness) DO UPDATE SET approve = _approve;
        END;
    $$;

-- function for account_witness_proxy_operation
/*
    {
        "type": "account_witness_proxy_operation",
        "value": {
            "account": "catavele",
            "proxy": "curie"
        }
    }

*/
CREATE OR REPLACE FUNCTION haf_block_explorer.account_witness_proxy_operation( _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _proxy VARCHAR;
        BEGIN
            _account := _body -> 'value' ->> 'account';
            _proxy := _body -> 'value' ->> 'proxy';
            INSERT INTO haf_block_explorer.account_witness_proxies (account, proxy) VALUES (_account, _proxy) ON CONFLICT (account) DO UPDATE SET proxy = _proxy;
        END;
    $$;
-- function for proxy_cleared_operation
/*
    {
        "type": "proxy_cleared_operation",
        "value": {
            "account": "hive-189312",
            "proxy": "josephsavage"
        }
    }
*/
CREATE OR REPLACE FUNCTION haf_block_explorer.proxy_cleared( _body JSONB )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            _account VARCHAR;
            _proxy VARCHAR;
        BEGIN
            _account := _body -> 'value' ->> 'account';
            _proxy := _body -> 'value' ->> 'proxy';
            DELETE FROM haf_block_explorer.account_witness_proxies WHERE account = _account AND proxy = _proxy;
        END;
    $$;
