import pytest
import os
import subprocess

IMAGE = "docker-onecodex-notebook"


def run_docker_container(tmp_path, container_command, env=None):
    if env is None:
        env = {}

    command = [
        "docker",
        "run",
        "--rm",
        *("--volume", f"{os.getcwd()}:/repo"),
        *("--volume", f"{tmp_path}:/pytest"),
        *("--volume", f"{os.getcwd()}/test/notebooks/:/share"),
        *("--entrypoint", "/usr/local/bin/jupyter"),
        *("--workdir", "/pytest"),
        *[i for r in [("--env", f"{k}={v}") for k, v in env.items()] for i in r],
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


def test_render_notebook(tmp_path):
    run_docker_container(
        tmp_path, ["nbconvert", "--execute", "--to", "onecodex_pdf", "/share/example.ipynb"]
    )

    expected_path = "test/notebooks/example_expected.pdf"

    try:
        subprocess.check_output(
            [
                "diff-pdf",
                "test/notebooks/example.pdf",
                expected_path,
                "--output-diff",
                "diff.pdf",
            ]
        )
    except subprocess.CalledProcessError:
        pytest.fail(
            f"Notebook rendering did not match expected output {expected_path}. Check diff.pdf for differences"
        )
