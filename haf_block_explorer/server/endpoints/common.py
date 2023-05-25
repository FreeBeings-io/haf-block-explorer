from haf_block_explorer.database.core import DbSession
from haf_block_explorer.tools import populate_by_schema, schemafy

db = DbSession('haf-block-explorer-server')

def check_account_name(acc):
    query = schemafy(f"SELECT 1 FROM hive.accounts_view WHERE name = _input LIMIT 1;")
    res = db.select(query)
    if res is None:
        return False
    else:
        return True

def get_head_block_num():
    query = schemafy(f"SELECT hive.app_get_irreversible_block();")
    res = db.select(query)
    return res[0][0]

def check_transaction_hash(trx_id):
    query = schemafy(f"SELECT 1 FROM hive.transactions_view WHERE encode(trx_hash, 'hex') = {trx_id} LIMIT 1;")
    res = db.select(query)
    if res is None:
        return False
    else:
        return True

def check_block_hash(block_hash) -> int:
    query = schemafy(f"SELECT block_num FROM hive.blocks_view WHERE encode(hash, 'hex') = {block_hash} LIMIT 1;")
    res = db.select(query)
    if res is None:
        return None
    else:
        return res[0][0]

def find_matching_accounts(_input):
    query = schemafy(f"SELECT name FROM hive.accounts_view WHERE name ILIKE '%' || {_input} || '%' LIMIT 50;")
    res = db.select(query)
    if res is None:
        return None
    else:
        return res