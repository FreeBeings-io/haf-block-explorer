import decimal
import re
from datetime import datetime

from haf_block_explorer.config import Config

config = Config.config

def is_valid_hive_account(acc):
    return bool(re.match(r'^[a-z][a-z0-9-.]{3,16}$', acc))

def schemafy(data:str, plug=None):
    _data = data.replace('haf_block_explorer.', f"{config['schema']}.")
    return _data

def _get_populated(data, fields):
    res = {}
    for i in range(len(fields)):
        # if entry split by space is longer than one, then choose the last one as key
        _key_check = fields[i].split(' ')
        if len(_key_check) > 1:
            _key = _key_check[-1]
        else:
            _key = fields[i]
        res[_key] = data[i]
    return res

def populate_by_schema(data, fields):
    assert isinstance(data, list), f"populate requires list, not {type(data)}"
    result = []
    for entry in data:
        result.append(_get_populated(entry, fields))
    return result