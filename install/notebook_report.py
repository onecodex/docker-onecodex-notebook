#!/usr/bin/env python

import click
import os
import sys

import nbformat
from nbconvert.exporters import export, HTMLExporter, PDFExporter
from nbconvert.preprocessors import ExecutePreprocessor
from traitlets.config import Config
from weasyprint import CSS, HTML

@click.command()
@click.argument('notebook_path', required=False, default=None)
@click.option('--html/--latex', is_flag=True, default=False)
def cli(notebook_path, html):
    # For some execution environments, set the path to be the "share" directory;
    # otherwise the current dir
    PATH_PREFIX = os.path.abspath(os.curdir) + '/'
    if os.path.exists('/share/'):
        PATH_PREFIX = '/share/'

    # Load the notebook and process all the cells,
    # optionally from sys.argv[1]
    if not notebook_path:
        notebook_path = os.path.join(os.path.abspath(os.curdir), 'notebook.ipynb')
    with open(notebook_path, 'r') as f:
        notebook = nbformat.read(f, as_version=4)

    os.environ['SUPPRESS_WARNINGS'] = 'True'

    executor = ExecutePreprocessor(timeout=int(os.environ.get('REPORT_TIMEOUT', 14400)))
    executor.preprocess(notebook, {})

    # Set up the export config
    c = Config()
    if html:
        if os.path.exists('/share/notebook_template.tpl'):
            c.HTMLExporter.template_file = '/share/notebook_template.tpl'
        else:
            c.HTMLExporter.template_file = '/opt/onecodex/notebook_template.tpl'
    else:
        if os.path.exists('/share/notebook_template.tplx'):
            c.LatexExporter.template_file = '/share/notebook_template.tplx'
        else:
            c.LatexExporter.template_file = '/opt/onecodex/notebook_template.tplx'


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
    if html:
        exporter = HTMLExporter(config=c)
    else:
        exporter = PDFExporter(config=c)
    output, _ = export(exporter, notebook)
    out_filename = os.environ.get('ONE_CODEX_REPORT_FILENAME', 'notebook').rstrip('.pdf') + '.pdf'
    if html:
        with open(out_filename.replace('.pdf', '.html'), 'w') as f:
            f.write(output)
        css_path = '/share/custom.css'
        if not os.path.exists(css_path):
            css_path = '/opt/onecodex/custom.css'
        HTML(string=output, base_url='file:///share/').write_pdf(out_filename, stylesheets=[CSS(css_path)])
    else:
        with open(out_filename, 'wb') as f:
            f.write(output)

if __name__ == '__main__':
    cli()
