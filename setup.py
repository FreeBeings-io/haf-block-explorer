import sys

from setuptools import find_packages
from setuptools import setup

assert sys.version_info[0] == 3 and sys.version_info[1] >= 9, "HAF Block Explorer requires Python 3.9 or newer"

setup(
    name='haf_block_explorer',
    version='0.1.0',
    description='HAF Block Explorer',
    long_description=open('README.md', 'r', encoding='UTF-8').read(),
    packages=find_packages(exclude=['scripts']),
    install_requires=[
        'requests',
        'psycopg2-binary',
        'jsonrpcserver == 5.0.9',
        'aiohttp'
    ],
    entry_points = {
        'console_scripts': [
            'haf_block_explorer = haf_block_explorer.run_haf_block_explorer:run'
        ]
    }
)
