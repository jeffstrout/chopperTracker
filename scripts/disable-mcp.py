#!/usr/bin/env python3

import re

# Read the main.py file
with open('/Users/jeffstrout/Projects/ChopperTracker/BackEnd/src/main.py', 'r') as f:
    content = f.read()

# Replace problematic lines
content = re.sub(r'^from \.mcp import MCPServer.*$', '# from .mcp import MCPServer  # Temporarily disabled', content, flags=re.MULTILINE)
content = re.sub(r'^mcp_server = None.*$', '# mcp_server = None  # Temporarily disabled', content, flags=re.MULTILINE)
content = re.sub(r'global collector_service, mcp_server', 'global collector_service  # , mcp_server', content)
content = re.sub(r'^\s*mcp_server = MCPServer.*$', '        # mcp_server = MCPServer(redis_service, collector_service)  # Temporarily disabled', content, flags=re.MULTILINE)

# Comment out MCP endpoints
content = re.sub(r'^(@app\.(get|post)\("\/mcp.*?\n)', r'# \1', content, flags=re.MULTILINE)
content = re.sub(r'^(async def mcp_.*?:)', r'# \1', content, flags=re.MULTILINE)

# Replace the content of MCP functions to just return an error
mcp_section_start = content.find('# MCP endpoints')
if mcp_section_start > 0:
    mcp_section_end = content.find('if __name__ == "__main__":', mcp_section_start)
    if mcp_section_end > 0:
        before = content[:mcp_section_start]
        after = content[mcp_section_end:]
        middle = '''# MCP endpoints - Temporarily disabled
# All MCP functionality has been disabled until package dependencies are resolved

'''
        content = before + middle + after

# Write back
with open('/Users/jeffstrout/Projects/ChopperTracker/BackEnd/src/main.py', 'w') as f:
    f.write(content)

print("✅ MCP functionality disabled in main.py")