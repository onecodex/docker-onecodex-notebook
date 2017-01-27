#!/usr/bin/env python
import os
import sys

import nbformat
from nbconvert.exporters import export, PDFExporter
from nbconvert.preprocessors import ExecutePreprocessor
from traitlets.config import Config

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
    notebook_path = PATH_PREFIX + 'notebook.ipynb'
with open(notebook_path, 'r') as f:
    notebook = nbformat.read(f, as_version=4)

executor = ExecutePreprocessor(timeout=int(os.environ.get('REPORT_TIMEOUT', 14400)))
executor.preprocess(notebook, {})

# Set up the export config
c = Config()
c.LatexExporter.template_file = PATH_PREFIX + 'notebook_template.tplx'

notebook.metadata['vars'] = {
    'trusted': True,
    'PATH_PREFIX': PATH_PREFIX,
    'OTHER_REPORT_LOGO': os.environ.get('OTHER_REPORT_LOGO', ''),
    'ONE_CODEX_REPORT_UUID': os.environ.get('ONE_CODEX_REPORT_UUID', ''),
}

# Export the notebook as a pdf
exporter = PDFExporter(config=c)
output, _ = export(exporter, notebook)
out_filename = os.environ.get('ONE_CODEX_REPORT_FILENAME', 'notebook').rstrip('.pdf') + '.pdf'
with open(out_filename, 'wb') as f:
    f.write(output)
