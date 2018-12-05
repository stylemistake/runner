from distutils.core import setup

setup(
    name="bash-task-runner",
    version="0.9.0",
    author="stylemistake",
    author_email="stylemistake@gmail.com",
    url="https://github.com/stylemistake/runner",
    description="A Simple, lightweight task runner for Bash.",
    license="LGPL-3.0",
    scripts=["bin/runner"],
    data_files=[
        ('src', ['src/cli.sh', 'src/runner.sh']),
        ('completion', ['completion/runner.bash']),
    ]
)
