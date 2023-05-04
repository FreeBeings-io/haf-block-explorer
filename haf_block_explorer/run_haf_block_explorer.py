"""Main entrypoint script for the HAF Block Explorer app."""

import sys

from haf_block_explorer.config import Config
from haf_block_explorer.database.core import DbSession
from haf_block_explorer.database.haf import Haf

config = Config.config

def run():
    """Main entrypoint. Runs main application processes and server."""
    database = DbSession('haf-block-explorer-setup')
    try:
        print("---   HAF Block Explorer started   ---")
        Haf.init(database)
    except KeyboardInterrupt:
        sys.exit()

if __name__ == "__main__":
    run()
