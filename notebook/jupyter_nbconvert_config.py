c = get_config()

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
