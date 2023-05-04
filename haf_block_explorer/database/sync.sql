CREATE OR REPLACE FUNCTION haf_block_explorer.global_sync_enabled()
    RETURNS BOOLEAN
    LANGUAGE plpgsql
    VOLATILE AS $function$
        BEGIN
            RETURN (SELECT sync_enabled FROM haf_block_explorer.global_props LIMIT 1);
        END;
    $function$;

CREATE OR REPLACE PROCEDURE haf_block_explorer.sync_main()
    LANGUAGE plpgsql
    AS $$
        DECLARE
            temprow RECORD;

            _global_start_block INTEGER := 0;
            _last_block_timestamp TIMESTAMP;
            _head_haf_block_num INTEGER;
            _latest_block_num INTEGER;
            _first_block INTEGER;
            _last_block INTEGER;
            _step INTEGER;

            _begin INTEGER;
            _target INTEGER;
        BEGIN
            _step := 10000;
            RAISE NOTICE 'Global start block: %s', _global_start_block;
            SELECT latest_block_num INTO _latest_block_num FROM haf_block_explorer.global_props;
            

            --decide which block to start at initially
            IF _latest_block_num IS NULL THEN
                _begin := _global_start_block;
            ELSE
                _begin := _latest_block_num;
            END IF;

            -- begin main sync loop
            WHILE true LOOP
                IF haf_block_explorer.global_sync_enabled() = true THEN
                    _target := hive.app_get_irreversible_block();
                    IF _target - _begin >= 0 THEN
                        RAISE NOTICE 'New block range: <%,%>', _begin, _target;
                        FOR _first_block IN _begin .. _target BY _step LOOP
                            _last_block := _first_block + _step - 1;

                            IF _last_block > _target THEN --- in case the _step is larger than range length
                                _last_block := _target;
                            END IF;

                            RAISE NOTICE 'Attempting to process a block range: <%, %>', _first_block, _last_block;
                            -- process btracker
                            PERFORM btracker_app.process_block_range_data_c(_first_block, _last_block);
                            PERFORM btracker_app.storeLastProcessedBlock(_last_block);
                            -- process main
                            FOR temprow IN
                                SELECT
                                    ov.id,
                                    ov.op_type_id,
                                    ov.block_num,
                                    ov.timestamp,
                                    ov.trx_in_block,
                                    tv.trx_hash,
                                    ov.body::varchar::jsonb
                                FROM hive.operations_view ov
                                LEFT JOIN hive.transactions_view tv
                                    ON tv.block_num = ov.block_num
                                    AND tv.trx_in_block = ov.trx_in_block
                                WHERE ov.block_num >= _first_block
                                    AND ov.block_num <= _last_block
                                ORDER BY ov.block_num, ov.id
                            LOOP
                                -- process operation
                                PERFORM haf_block_explorer.process_operation(temprow);
                                _last_block_timestamp := temprow.timestamp;
                            END LOOP;
                            RAISE NOTICE 'Block range: <%, %> processed successfully.', _first_block, _last_block;
                            -- update global props and save
                            UPDATE haf_block_explorer.global_props SET check_in = NOW(), latest_block_num = _last_block, latest_block_time = _last_block_timestamp;
                            COMMIT;
                        END LOOP;
                        _begin := _target +1;
                    ELSE
                        RAISE NOTICE 'begin: %   target: %', _begin, _target;
                        PERFORM pg_sleep(1);
                    END IF;
                ELSE
                    PERFORM pg_sleep(2);
                END IF;
            END LOOP;
        END;
    $$;

CREATE OR REPLACE FUNCTION haf_block_explorer.process_operation( _temprow RECORD )
    RETURNS VOID
    LANGUAGE plpgsql
    AS $$
        DECLARE
            tempnotif JSONB;
            _module_schema VARCHAR;
        BEGIN
            IF _temprow.op_type_id = 12 THEN
                PERFORM haf_block_explorer.account_witness_vote_operation(_temprow.body);
            ELSIF _temprow.op_type_id = 13 THEN
                PERFORM haf_block_explorer.account_witness_proxy_operation(_temprow.body);
            ELSIF _temprow.op_type_id = 91 THEN
                PERFORM haf_block_explorer.proxy_cleared(_temprow.body);
            END IF;
        END;
    $$;