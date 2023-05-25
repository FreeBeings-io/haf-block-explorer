from aiohttp import web
from jsonrpcserver import async_dispatch as dispatch
from jsonrpcserver.methods import Methods

from haf_block_explorer.config import Config
from haf_block_explorer.server.endpoints import input_types

config = Config.config

async def handle(request):
    request = await request.text()
    response = await dispatch(request)
    if response.wanted:
        return web.json_response(response)
    else:
        return web.Response()

app = web.Application()
app.router.add_post("/", handle)

def run_server():
    web.run_app(app, host=config['server_host'], port=config['server_port'])
