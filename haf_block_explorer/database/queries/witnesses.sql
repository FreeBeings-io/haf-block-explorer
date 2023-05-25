CREATE OR REPLACE FUNCTION haf_block_explorer.get_top_witnesses(n INT)
RETURNS TABLE (
    witness VARCHAR,
    votes NUMERIC
) AS $$
DECLARE
    balance BIGINT;
    delegated_out_balance BIGINT;
    delegated_in_balance BIGINT;
    proxy_balance BIGINT;
    account_balance BIGINT;
BEGIN
    RETURN QUERY 
    WITH vote_balances AS (
        SELECT 
            wv.witness,
            cab.balance - COALESCE(db1.amount, 0) + COALESCE(db2.amount, 0) AS vote_balance
        FROM haf_block_explorer.witness_votes_current AS wv
        LEFT JOIN haf_block_explorer.account_proxies AS ap ON wv.account = ap.account
        LEFT JOIN btracker_app.current_account_balances AS cab ON wv.account = cab.account AND cab.nai = 37
        LEFT JOIN haf_block_explorer.delegations_balances AS db1 ON wv.account = db1.delegator
        LEFT JOIN haf_block_explorer.delegations_balances AS db2 ON wv.account = db2.delegatee
        WHERE ap.account IS NULL OR ap.proxy != wv.account
        AND wv.enabled = true
    ), proxy_balances AS (
        SELECT 
            wv.witness,
            SUM(cab.balance) AS proxy_balance
        FROM haf_block_explorer.witness_votes_current AS wv
        JOIN haf_block_explorer.account_proxies AS ap ON wv.account = ap.account
        JOIN btracker_app.current_account_balances AS cab ON ap.proxy = cab.account AND cab.nai = 37
        WHERE wv.enabled = true
        GROUP BY wv.witness
    )
    SELECT 
        vb.witness,
        SUM(vb.vote_balance) + COALESCE(SUM(pb.proxy_balance), 0) AS votes
    FROM vote_balances AS vb
    LEFT JOIN proxy_balances AS pb ON vb.witness = pb.witness
    GROUP BY vb.witness
    ORDER BY votes DESC
    LIMIT n;
END; $$
LANGUAGE 'plpgsql';
