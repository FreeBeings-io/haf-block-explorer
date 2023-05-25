import json
import re
from jsonrpcserver import method

from haf_block_explorer.server.endpoints.common import get_head_block_num as _get_head_block_num

@method(name='blocks.get_head_block_num')
async def get_head_block_num():
    return _get_head_block_num()
