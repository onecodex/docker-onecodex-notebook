import pytest
import os
import subprocess

IMAGE = "docker-onecodex-notebook"


def run_docker_container(container_command):
    command = [
        "docker",
        "run",
        "--rm",
        *("--volume", f"{os.getcwd()}/test/notebooks/:/share"),
        *("--user", "1000"),
        *("--entrypoint", "/usr/local/bin/jupyter"),
        IMAGE,
        *container_command,
    ]

    result = subprocess.run(command, capture_output=True)

    if result.returncode != 0:
        raise Exception(
            "\n".join(
                [
                    "Command Failed!",
                    "command:",
                    " ".join(command),
                    "stdout:",
                    result.stdout.decode("utf-8"),
                    "stderr:",
                    result.stderr.decode("utf-8"),
                ]
            )
        )

    return result


def test_render_notebook():
    run_docker_container(
        [
            "nbconvert",
            "--execute",
            "--to",
            # custom One Codex export format (see
            # https://github.com/onecodex/onecodex#jupyter-notebook-custom-exporters)
            "onecodex_pdf",
            "/share/example.ipynb",
        ]
    )

    expected_path = "test/notebooks/example_expected.pdf"

    try:
        subprocess.check_output(
            [
                "diff-pdf",
                *("--output-diff", "diff.pdf"),
                "test/notebooks/example.pdf",
                expected_path,
            ]
        )
    except subprocess.CalledProcessError:
        pytest.fail(
            f"Notebook rendering did not match expected output {expected_path}. Check diff.pdf for differences"
        )
