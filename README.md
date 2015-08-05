# Task runner for Bash

Simple, lightweight task runner for Bash.

Inspired by [Gulp] version 4.

Script is still early and incomplete. If you find any bugs, let me know in the
[issues section][issues] of this repository.


## 1. Pre-requisites

Runner depends on:

* `bash >=4.0`
* `coreutils`

These are very likely to be already installed on your system.


## 2. Installation

Simply download the `runner.sh` file and place it somewhere inside your
project folder.


## 3. Usage

### 3.1. Basics

Create an empty bash script (e.g. `tasks.sh`), which is going to be an entry
point for the task runner. Add this to the beginning:

```bash
#!/bin/bash
cd `dirname ${0}`
source runner.sh
```

Create some tasks:

```bash
task_foo() {
    ## Do something...
}

task_bar() {
    ## Do something...
}
```

You can run a task by running this script with task names as arguments:

```bash
$ bash tasks.sh foo bar
[23:43:37.754] Starting 'foo'
[23:43:37.755] Finished 'foo' after 1 ms
[23:43:37.756] Starting 'bar'
[23:43:37.757] Finished 'bar' after 1 ms
```

You can define a default task. It will run if no arguments were provided to
the script:

```bash
task_default() {
    ## Do something...
}
```

You can change which task is default:

```bash
runner_set_default_task foo
```

### 3.2. Task chaining

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

### 3.3. Error handling

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

### 3.4. Flags

All flags you pass to the script are passed to your tasks.

```bash
$ bash tasks.sh foo --production

task_foo() {
    echo ${@} # --production
}
```


## 4. Example

This example is a real world script, which automates setup of a Laravel
project:

```bash
#!/bin/bash
cd `dirname ${0}`
source runner.sh

cd ..

NPM_GLOBAL_PACKAGES="gulp bower node-gyp"

task_php() {
    if ! [ -e "composer.phar" ]; then
        wget http://getcomposer.org/composer.phar || return
    fi

    php composer.phar install || return

    if ! [ -e ".env" ]; then
        cp .env.example .env
        php artisan key:generate
    fi
}

task_node() {
    if [ -e "${HOME}/.nvm/nvm.sh" ]; then
        if ! runner_is_defined ${NPM_GLOBAL_PACKAGES}; then
            npm install -g ${NPM_GLOBAL_PACKAGES} || return
        fi
    fi
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

task_default() {
    runner_parallel php node || return

    if ! runner_is_defined ${NPM_GLOBAL_PACKAGES}; then
        runner_log_warning "Please install these packages manually:"
        runner_log "'npm install -g ${NPM_GLOBAL_PACKAGES}'"
    fi
}
```


## 5. WHY?

![Why this exists?][derp_why]

**Q:** Isn't Bash itself fundamentally a task runner?

**A:** No, bash is a scripting language, not a task runner. Same story is with
Grunt/Gulp for Javascript - you can "run tasks" in vanilla JS without any
frameworks, but it costs you maintainability, redundancy, etc. My library is
just a very thin layer around bash with functions that make sense for task
running with concurrency in mind. You still got the power of bash in your
hands.

**Q:** Why use this and not `make` / `ant` / ...?

**A:** For a couple of reasons:

* Sometimes it is just inappropriate to use them:
    * They are meant to be used for build automation. If you're doing just
    a bunch of scripts with it, you're using 1% of these tools' features.
    * It's a yet another dependency. If you're already using `artisan` and
    `gulp` in your project, `make` will just add more confusion.
* This library is very lightweight, runs straight away, and it is designed to
be bundled with your project source code.
* It is a good tool to automate a project setup when you got nothing else,
but `bash`.
* If you already know `bash`, there is no new syntax to learn!
* It's as fast as `make` with `-j` flag if using parallel execution of tasks.
Even single core systems may benefit from this, especially if tasks are more
IO oriented.

I would also like to mention [Manuel], which is a similar task runner for
`bash`. It is similar in many ways (although lacks concurrency). Feel free to
check it out, too.


## 6. Contribution

Got a suggestion for a feature? Feel free to open a [feature request][issues].


## Contacts

Email: [stylemistake@gmail.com]

Web: [stylemistake.com]

[gulp]: https://github.com/gulpjs/gulp
[issues]: https://github.com/stylemistake/bash-task-runner/issues
[derp_why]: http://cdn.alltheragefaces.com/img/faces/jpg/neutral-whyyyyy.jpg
[manuel]: https://github.com/ShaneKilkelly/manuel
[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
