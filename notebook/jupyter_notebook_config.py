# Copyright (c) Jupyter Development Team.
import os

c = get_config()
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.tornado_settings = {"xsrf_cookies": False}

# Prefer JavaScript over SVG when exporting notebooks as HTML--keeps figures interactive
c.NbConvertBase.display_data_priority = [
    'application/vnd.jupyter.widget-state+json',
    'application/vnd.jupyter.widget-view+json',
    'application/javascript',
    'image/svg+xml',
    'text/html',
    'text/markdown',
    'text/latex',
    'image/png',
    'image/jpeg',
    'text/plain'
]

# Set a password if PASSWORD is set
if 'PASSWORD' in os.environ:
    from IPython.lib import passwd
    c.NotebookApp.password = passwd(os.environ['PASSWORD'])
    del os.environ['PASSWORD']
