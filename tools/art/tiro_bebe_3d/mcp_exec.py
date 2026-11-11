"""Execute a supplied Blender Python file through the installed local MCP bridge.

Protocol is the one implemented by the user's official Blender MCP add-on.
This does not register an MCP server in Codex or change Blender preferences.
"""
import argparse
import json
import socket
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('script',type=Path)
parser.add_argument('--timeout',type=float,default=60)
args=parser.parse_args()
request={'type':'execute','code':args.script.read_text(encoding='utf-8-sig'),'strict_json':True}
with socket.create_connection(('127.0.0.1',9876),timeout=10) as connection:
    connection.settimeout(args.timeout)
    connection.sendall(json.dumps(request).encode('utf8')+b'\0')
    response=bytearray()
    while b'\0' not in response:
        block=connection.recv(65536)
        if not block:break
        response.extend(block)
        if len(response)>8_000_000:raise RuntimeError('Response exceeded the diagnostic limit')
    answer=json.loads(response.split(b'\0',1)[0])
    print(json.dumps(answer,ensure_ascii=False,indent=2))
    if answer.get('status')!='ok':raise SystemExit(1)
