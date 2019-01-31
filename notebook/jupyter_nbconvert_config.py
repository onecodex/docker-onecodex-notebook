c = get_config()

# Prefer SVG over JavaScript when exporting notebooks as HTML
c.NbConvertBase.display_data_priority = [
    'application/vnd.jupyter.widget-state+json',
    'application/vnd.jupyter.widget-view+json',
    'image/svg+xml',
    'application/javascript',
    'text/html',
    'text/markdown',
    'text/latex',
    'image/png',
    'image/jpeg',
    'text/plain'
]