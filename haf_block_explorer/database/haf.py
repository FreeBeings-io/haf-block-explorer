import logging
import os
from threading import Thread

from haf_block_explorer.config import Config
from haf_block_explorer.database.core import DbSession

MAIN_DIR = os.path.dirname(__file__)
TRIGGERS_DIR = os.path.dirname(__file__) + "/triggers"
QUERIES_DIR = os.path.dirname(__file__) + "/queries"

config = Config.config


class Haf:

    @classmethod
    def _is_valid_sql_file(cls, file):
        return file.endswith('.sql')

    @classmethod
    def _get_haf_sync_head(cls, db):
        sql = "SELECT hive.app_get_irreversible_block();"
        res = db.select(sql)
        return res[0]

    @classmethod
    def _update_functions(cls, db, functions):
        db.execute(functions, None)
        db.commit()

    @classmethod
    def _init_haf(cls, db):
        db.execute(f"CREATE SCHEMA IF NOT EXISTS {config['schema']};")
        db.commit()
        # functions
        sqls = []
        # load files in sql folders
        main_sqls = [f.name for f in os.scandir(MAIN_DIR) if cls._is_valid_sql_file(f.name)]
        for _file in main_sqls:
            _sql = (open(f'{MAIN_DIR}/{_file}', 'r', encoding='UTF-8').read()
                .replace('haf_block_explorer.', f"{config['schema']}.")
            )
            sqls.append(_sql)
        # functions
        functions = [f.name for f in os.scandir(f'{TRIGGERS_DIR}') if cls._is_valid_sql_file(f.name)]
        for _file in functions:
            _sql = (open(f'{TRIGGERS_DIR}/{_file}', 'r', encoding='UTF-8').read()
                .replace('haf_block_explorer.', f"{config['schema']}.")
            )
            sqls.append(_sql)
        # queries
        queries = [f.name for f in os.scandir(f'{QUERIES_DIR}') if cls._is_valid_sql_file(f.name)]
        for _file in queries:
            _sql = (open(f'{QUERIES_DIR}/{_file}', 'r', encoding='UTF-8').read()
                .replace('haf_block_explorer.', f"{config['schema']}.")
            )
            sqls.append(_sql)

        for cmd in sqls:
            db.execute(cmd)
        db.commit()

    @classmethod
    def _init_data(cls, db):
        has_globs = db.select(f"SELECT * FROM {config['schema']}.global_props;")
        sqls = []
        if not has_globs:
            # insert global props
            sqls.append(f"INSERT INTO {config['schema']}.global_props (latest_block_num) VALUES('0');")
        db.execute('\n'.join(sqls))
        db.commit()
    
    @classmethod
    def _cleanup(cls, db):
        """Stops any running sync procedures from previous instances."""
        try:
            running = db.select_one(f"SELECT {config['schema']}.is_sync_running('{config['schema']}-main');")
            if running is True:
                db.execute(f"SELECT {config['schema']}.terminate_main_sync('{config['schema']}-main');")
        except Exception as err:
            logging.info(f"Session cancel encountered error: {err}")
        if config['reset'] == 'true':
            try:
                db.execute(f"DROP SCHEMA {config['schema']} CASCADE;")
                db.commit()
            except Exception as err:
                print(f"Reset encountered error: {err}")

    @classmethod
    def _init_main_sync(cls, db):
        print("Starting main sync process...")
        db.execute(f"CALL {config['schema']}.sync_main();")
    
    @classmethod
    def init(cls, db):
        """Initializes the HAF sync process."""
        cls._cleanup(db)
        cls._init_haf(db)
        cls._init_data(db)
        start = db.select(f"SELECT {config['schema']}.global_sync_enabled()")[0][0]
        if start is True:
            db_main = DbSession('main')
            Thread(target=cls._init_main_sync, args=(db_main,)).start()
        else:
            print("Global sync is disabled. Shutting down")
            os._exit(0)
