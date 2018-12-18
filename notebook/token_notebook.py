#!/usr/bin/env python

from notebook.notebookapp import NotebookApp
from notebook.auth.login import LoginHandler
from tornado import web
import os


class BearerTokenLoginAuthHandler(LoginHandler):
    """Bearer auth support for Jupyter notebook"""
    @staticmethod
    def login_available(settings):
        return True

    @staticmethod
    def get_user(handler):
        if os.environ["SECURE_BEARER_TOKEN"] == handler.request.headers.get("Authorization"):
            return "user_is_authenticated"
        else:
            raise web.HTTPError(403)


class TokenAuthNotebook(NotebookApp):
    login_handler_class = BearerTokenLoginAuthHandler


def main(argv=None):
    return TokenAuthNotebook.launch_instance(argv)


if __name__ == "__main__":
    main()
