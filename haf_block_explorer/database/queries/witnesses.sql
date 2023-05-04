CREATE OR REPLACE FUNCTION haf_block_explorer.top_witnesses_by_weighted_votes_with_proxy(limit_count INTEGER)
RETURNS TABLE (
    witness VARCHAR,
    total_weighted_votes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH proxy_weight AS (
        SELECT
            p.proxy,
            SUM(cab.balance) AS proxy_total_weight
        FROM
            haf_block_explorer.account_witness_proxies p
        JOIN
            btracker_app.current_account_balances cab ON p.account = cab.account
        WHERE
            cab.nai = 37
        GROUP BY
            p.proxy
    ),
    account_votes AS (
        SELECT
            COALESCE(awp.proxy, awv.account) AS voter_account,
            awv.witness
        FROM
            haf_block_explorer.account_witness_votes awv
        LEFT JOIN
            haf_block_explorer.account_witness_proxies awp ON awv.account = awp.account
        WHERE
            awv.approve = true
    )
    SELECT
        av.witness,
        CAST(SUM(COALESCE(pw.proxy_total_weight, cab.balance)) AS BIGINT) AS total_weighted_votes
    FROM
        account_votes av
    JOIN
        btracker_app.current_account_balances cab ON av.voter_account = cab.account
    LEFT JOIN
        proxy_weight pw ON av.voter_account = pw.proxy
    WHERE
        cab.nai = 37
    GROUP BY
        av.witness
    ORDER BY
        total_weighted_votes DESC
    LIMIT
        limit_count;
END;
$$ LANGUAGE plpgsql;
