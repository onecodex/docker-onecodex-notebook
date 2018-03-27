#!/usr/bin/env python
import os
import sys

import nbformat
from nbconvert.exporters import export, HTMLExporter
from nbconvert.preprocessors import ExecutePreprocessor
from traitlets.config import Config
from weasyprint import HTML

# For some execution environments, set the path to be the "share" directory;
# otherwise the current dir
PATH_PREFIX = os.path.abspath(os.curdir) + '/'
if os.path.exists('/share/'):
    PATH_PREFIX = '/share/'

# Load the notebook and process all the cells,
# optionally from sys.argv[1]
try:
    notebook_path = sys.argv[1]
except IndexError:
    notebook_path = os.path.join(os.path.abspath(os.curdir), 'notebook.ipynb')
with open(notebook_path, 'r') as f:
    notebook = nbformat.read(f, as_version=4)

executor = ExecutePreprocessor(timeout=int(os.environ.get('REPORT_TIMEOUT', 14400)))
executor.preprocess(notebook, {})

# Set up the export config
c = Config()
if os.path.exists('/share/notebook_template.tpl'):
    c.HTMLExporter.template_file = '/share/notebook_template.tpl'
else:
    c.HTMLExporter.template_file = '/opt/onecodex/notebook_template.tpl'

notebook.metadata['vars'] = {
    'trusted': True,
    'PATH_PREFIX': PATH_PREFIX,
    'OTHER_REPORT_LOGO': os.environ.get('OTHER_REPORT_LOGO', ''),
    'ONE_CODEX_REPORT_UUID': os.environ.get('ONE_CODEX_REPORT_UUID', ''),
}

title = os.environ.get('ONE_CODEX_REPORT_TITLE', False)
if title:
    notebook.metadata['title'] = title

# Export the notebook as a pdf
exporter = HTMLExporter(config=c)
output, _ = export(exporter, notebook)
out_filename = os.environ.get('ONE_CODEX_REPORT_FILENAME', 'notebook').rstrip('.pdf') + '.pdf'
HTML(string=output).write_pdf(out_filename)
