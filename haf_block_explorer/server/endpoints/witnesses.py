import json
import re
from jsonrpcserver import method

from haf_block_explorer.server.endpoints.common import db


@method(name='witnesses.get_witness_voters_num')
async def get_witness_voters_num(witness_name):
    query = f"""
        SELECT COUNT(*) FROM haf_block_explorer.witness_votes_current WHERE witness = '{witness_name}';
    """
    res = db.select(query)
    if res:
        return res[0][0]
    else:
        return 0

@method(name='witnesses.get_witness_voters')
async def get_witness_voters(witness_name, limit=1000, offset=0, order_by='vests', order_is='DESC', to_hp:bool=True):
    """
        - witness_name: str(16) >> witness name
        - limit: int >> limit the results
        - offset: int >> offset the results (for pagination)
        - order_by: str >> order by this column (voter,  vests,  account_vests,  proxied_vests,  timestamp)
        - order_is: str >> order direction (ASC, DESC)
        - to_hp: bool >> convert vests to HP

    """
    query = f"""
        SELECT voter, vests FROM haf_block_explorer.witness_votes_current WHERE witness = '{witness_name}' ORDER BY {order_by} {order_is} LIMIT {limit} OFFSET {offset};
    """
    res = db.select(query)
    if res:
        return res
    else:
        return []

