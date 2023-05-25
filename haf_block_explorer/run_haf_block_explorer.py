"""Main entrypoint script for the HAF Block Explorer app."""

import sys

from haf_block_explorer.config import Config
from haf_block_explorer.database.core import DbSession
from haf_block_explorer.database.haf import Haf
from haf_block_explorer.server.server import run_server

config = Config.config

def run():
    """Main entrypoint. Runs main application processes and server."""
    database = DbSession('haf-block-explorer-setup')
    try:
        print("---   HAF Block Explorer started   ---")
        Haf.init(database)
        run_server()

    except KeyboardInterrupt:
        sys.exit()

if __name__ == "__main__":
    run()
