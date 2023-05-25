import json
import re
from jsonrpcserver import method

from haf_block_explorer.server.endpoints.common import (
    check_account_name,
    check_block_hash,
    check_transaction_hash,
    find_matching_accounts,
    get_head_block_num
)


@method(name='sys.get_input_type')
async def get_input_type(_input):
    _input = _input.lower()
    head_block_num = get_head_block_num()

    # First, name existence is checked
    if check_account_name(_input):
        return {
            'input_type': 'account_name',
            'input_value': _input,
        }

    # Second, positive digit and not name is assumed to be block number
    if re.fullmatch('\d+', _input):
        if int(_input) > head_block_num:
            raise Exception(f'Block number {_input} is higher than head block number {head_block_num}')
        else:
            return {
                'input_type': 'block_num',
                'input_value': _input,
            }

    # Third, if input is 40 char hash, it is validated for transaction or block hash
    if re.fullmatch('[a-f0-9]{40}', _input):
        if check_transaction_hash(_input):
            return {
                'input_type': 'transaction_hash',
                'input_value': _input,
            }
        else:
            block_num = check_block_hash(_input)
            if block_num is not None:
                return {
                    'input_type': 'block_hash',
                    'input_value': block_num,
                }
            else:
                raise Exception(f'Hash {_input} is neither transaction nor block hash')

    # Fourth, it is still possible input is partial name, max 50 names returned
    accounts_array = find_matching_accounts(_input)
    if accounts_array is not None:
        return {
            'input_type': 'account_name_array',
            'input_value': accounts_array,
        }
    else:
        raise Exception(
            f'Input {_input} is not a valid account name, block number, transaction hash, '
            f'block hash, or partial account name'
        )

