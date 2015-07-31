# Task runner for Bash

This is a simple task runner for Bash, heavily inspired by [Gulp].

Although this script was thoroughly tested, it is still very alpha and may have
bugs, so be prepared for them. If you find any, please create an issue.


## 1. Pre-requisites

Runner depends on:

* `bash >=4.0`
* `xargs`

These are very likely installed on your system by default. If not, let me
know, we can replace some of the dependencies in the script to make life
easier for everyone.


## 2. Installation

Simply download the `runner.sh` file and place it somewhere inside your
project folder.


## 3. Usage

### 3.1. Basics

Create an empty bash script (for example `tasks.sh`), which is going to be an
entry point for the task runner. Add this to the beginning:

```bash
#!/bin/bash
cd `dirname ${0}`
source runner.sh
```

If your `runner.sh` is placed somewhere else, change the path accordingly.

Create some tasks:

```bash
task_foo() {
    ## Do something...
}

task_bar() {
    ## Do something...
}
```

Then you can run a task by running this script with task names as arguments:

```bash
$ bash tasks.sh foo bar
[23:43:37.754] Starting 'foo'
[23:43:37.755] Finished 'foo' (0)
[23:43:37.756] Starting 'bar'
[23:43:37.757] Finished 'bar' (0)
```

You can define a default task:

```bash
task_default() {
    ## Do something...
}
```

It will run if no arguments were provided to the script.

You can also change which task is default by using:

```bash
runner_set_default_task <task_name>
```

### 3.2. Task chaining

Tasks can launch other tasks in two ways: sequentially and in parallel. This
way you can optimize the task flow for maximum concurrency.

To run tasks sequentially, use:

```bash
task_default() {
    runner_sequence foo bar

    ## [23:50:33.194] Starting 'foo'
    ## [23:50:33.195] Finished 'foo' (0)
    ## [23:50:33.196] Starting 'bar'
    ## [23:50:33.198] Finished 'bar' (0)
}
```

To run tasks in parallel, use:

```bash
task_default() {
    runner_parallel foo bar

    ## [23:50:33.194] Starting 'foo'
    ## [23:50:33.194] Starting 'bar'
    ## [23:50:33.198] Finished 'foo' (0)
    ## [23:50:33.198] Finished 'bar' (0)
}
```

### 3.3. Error handling

At some point of the task errors can occur, which you want to bubble up.
There is a handy function for this:

```bash
task_foo() {
    ...
    php composer.phar install
    runner_bubble ${?}
    ...
}
```

If you are running tasks in parallel, you may want to stop execution of all
parallel tasks when error bubbles through `runner_bubble`. To do this, call
this function before running parallel tasks:

```bash
task_default() {
    runner_break_parallel
    runner_parallel foo bar
}
```


## 4. Example

This example is a real world script, which prepares Laravel project environment
(`utils/bootstrap.sh`):

```bash
#!/bin/bash
cd `dirname ${0}`
source runner.sh

cd ..

NPM_GLOBAL_PACKAGES="gulp bower node-gyp"

task_php() {
    if ! [ -e "composer.phar" ]; then
        wget http://getcomposer.org/composer.phar
        runner_bubble ${?}
    fi

    php composer.phar install
    runner_bubble ${?}

    if ! [ -e ".env" ]; then
        cp .env.example .env
        php artisan key:generate
        runner_bubble ${?}
    fi
}

task_node() {
    if [ -e "${HOME}/.nvm/nvm.sh" ]; then
        if ! runner_is_defined ${NPM_GLOBAL_PACKAGES}; then
            npm install -g ${NPM_GLOBAL_PACKAGES}
            runner_bubble ${?}
        fi
    fi

    runner_parallel node_{npm,bower}
}

task_node_npm() {
    npm install
}

task_node_bower() {
    bower install
}

task_default() {
    runner_parallel php node

    if ! runner_is_defined ${NPM_GLOBAL_PACKAGES}; then
        runner_log "Please install these packages manually:"
        runner_log "'npm install -g ${NPM_GLOBAL_PACKAGES}'"
        exit 1
    fi
}
```


## Contacts

Email: [stylemistake@gmail.com]

Web: [stylemistake.com]

[gulp]: https://github.com/gulpjs/gulp
[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com