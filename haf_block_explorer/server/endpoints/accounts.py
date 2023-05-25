import json
import re
from typing import List

from jsonrpcserver import method

from haf_block_explorer.server.endpoints.common import db
from haf_block_explorer.server.endpoints.common import get_head_block_num

"""
[
  {
    "trx_id": HASH,
    "block": NUMBER,
    "trx_in_block": NUMBER,
    "op_in_trx": NUMBER,
    "virtual_op": BOOLEAN,
    "timestamp": TIMESTAMP,
    "age": INTERVAL,
    "op": {
      "type": TEXT,
      "value": JSON
    },
    "operation_id": NUMBER,
    "acc_operation_id": NUMBER
  },
  ...
  {}
]
"""

@method(name='accounts.get_account_ops')
async def get_account_ops(account, filter: List[int], start_date=None, end_date=None):
    query = f"""
        SELECT 
    """