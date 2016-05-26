# Task runner for Bash

[![NPM](https://badge.fury.io/js/bash-task-runner.svg)][npm]
[![Gitter](https://badges.gitter.im/stylemistake/bash-task-runner.svg)][gitter]

Simple, lightweight task runner for Bash.

If you find any bugs, let me know by creating an [issue][issues].


## 1. Pre-requisites

Runner depends on:

* bash `>=4.0`
* coreutils `>=8.0`

These are very likely to be already installed on your Linux machine.

**Note for Mac OS X users:**

Use [Homebrew] to install the dependencies:

```bash
brew install bash coreutils
```


## 2. Installation

There are many different ways to use `runner` in your project.

Using `npm`:

```bash
## To install to your project folder
npm install --save-dev bash-task-runner

## To install globally
npm install -g bash-task-runner
```

Alternatively, you can simply download the [src/runner.sh] file
and place it inside your project folder.


## 3. Usage

### 3.1. Setup

Create an empty bash script (`runnerfile.sh`), which is an entry point for the
task runner.

*Optional*: If you want the `runnerfile.sh` to be a self-contained script, add
this to the beginning:

```bash
#!/bin/bash
cd `dirname ${0}`
source <path_to>/runner.sh
```


### 3.2. Basics

Create some tasks:

```bash
task_foo() {
    ## Do something...
}

task_bar() {
    ## Do something...
}
```

Then you can run tasks with the `runner` tool:

```bash
$ runner foo bar
[23:43:37.754] Starting 'foo'
[23:43:37.755] Finished 'foo' after 1 ms
[23:43:37.756] Starting 'bar'
[23:43:37.757] Finished 'bar' after 1 ms
```

Or in case your script sources the task runner:

```bash
$ bash runnerfile.sh foo bar
```

You can define a default task. It will run if no arguments were provided to the
task runner:

```bash
task_default() {
    ## Do something...
}
```

You can change which task is default:

```bash
runner_default_task="foo"
```

### 3.3. Task chaining

Tasks can launch other tasks in two ways: *sequentially* and in *parallel*.
This way you can optimize the task flow for maximum concurrency.

To run tasks sequentially, use:

```bash
task_default() {
    runner_sequence foo bar
    ## [23:50:33.194] Starting 'foo'
    ## [23:50:33.195] Finished 'foo' after 1 ms
    ## [23:50:33.196] Starting 'bar'
    ## [23:50:33.198] Finished 'bar' after 2 ms
}
```

To run tasks in parallel, use:

```bash
task_default() {
    runner_parallel foo bar
    ## [23:50:33.194] Starting 'foo'
    ## [23:50:33.194] Starting 'bar'
    ## [23:50:33.196] Finished 'foo' after 2 ms
    ## [23:50:33.196] Finished 'bar' after 2 ms
}
```

### 3.4. Error handling

Sometimes you need to stop the whole task if some of the commands fails.
You can achieve this with a simple conditional return:

```bash
task_foo() {
    ...
    php composer.phar install || return
    ...
}
```

If a failed task was a part of a sequence, the whole sequence fails. Same
applies to the tasks running in parallel.

The difference in `runner_parallel` is if an error occurs in one of the tasks,
other tasks continue to run. After all tasks finish, it returns `0` if
none have failed, `41` if some have failed and `42` if all have failed.

### 3.5. Flags

All flags you pass after the task name are passed to your tasks.

```bash
$ runner foo --production

task_foo() {
    echo ${@} # --production
}
```

To pass options to the `runner` CLI specifically, you must provide them
before any task names:

```bash
$ runner -f scripts/tasks.sh foo
```

To get all possible `runner` CLI options, use the `-h` (help) flag:

```bash
$ runner -h
```

### 3.6. Command echoing

`runner_run` command gives a way to run commands and have them outputted:

```bash
task_default() {
  runner_run composer install
  ## [12:19:17.170] Starting 'default'...
  ## [12:19:17.173] composer install
  ## Loading composer repositories with package information
  ## ...
  ## [12:19:17.932] Finished 'default' after 758 ms
}
```

### 3.7 Bash completion

The `runner` CLI supports autocompletion for task names. Simply add the following line your `~/.bashrc`:

```bash
eval $(runner --completion=bash)
```

## 4. Example

This is a real world script that automates the initial setup of a
Laravel project.

```bash
#!/bin/bash
cd `dirname ${0}`
source runner.sh

NPM_GLOBAL_PACKAGES="gulp bower node-gyp"

task_default() {
    runner_parallel php node || return
    if ! runner_is_defined ${NPM_GLOBAL_PACKAGES}; then
        runner_log_warning "Please install these packages manually:"
        runner_log "'npm install -g ${NPM_GLOBAL_PACKAGES}'"
        exit 1
    fi
}

task_php() {
    runner_sequence php_{composer,vendor} || return
    if [[ ! -e ".env" ]]; then
        cp .env.example .env
        runner_run php artisan key:generate
    fi
}

task_php_composer() {
    if [[ ! -e "composer.phar" ]]; then
        php -r "readfile('https://getcomposer.org/installer');" | php
    fi
}

task_php_vendor() {
    runner_run php composer.phar install
}

task_node() {
    runner_parallel node_{npm,bower}
}

task_node_npm() {
    if [[ "${1}" == "--virtualbox" ]]; then
        local npm_options="--no-bin-links"
        runner_log_warning "Using npm options: ${npm_options}"
    fi
    npm install ${npm_options}
}

task_node_bower() {
    bower install
}

runner_bootstrap
runner_log_success "Success!"
```


## 5. FAQ

Read the [FAQ]


## 6. Contribution

Please provide pull requests in a separate branch (other than `master`), this
way it's more manageable for me to review and pull.

Before writing code, open an [issue][issues] to get initial feedback and
resolve potential problems. Write all feature related comments there, not into
pull-request.


## 7. License

This software is covered by [LGPL-3 license][license].


## Contacts

Style Mistake <[stylemistake@gmail.com]>


[gitter]: https://gitter.im/stylemistake/bash-task-runner
[npm]: https://www.npmjs.com/package/bash-task-runner
[homebrew]: http://brew.sh/
[src/runner.sh]: https://raw.githubusercontent.com/stylemistake/bash-task-runner/master/src/runner.sh
[issues]: https://github.com/stylemistake/bash-task-runner/issues
[manuel]: https://github.com/ShaneKilkelly/manuel
[faq]: https://github.com/stylemistake/bash-task-runner/wiki/FAQ
[license]: LICENSE.md
[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
