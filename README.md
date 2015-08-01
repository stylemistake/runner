# Task runner for Bash

Simple, lightweight task runner for Bash.

Inspired by [Gulp] version 4, although very different by design.

Script is still early and incomplete. If you find any bugs, let me know in the
issues section of Github.


## 1. Pre-requisites

Runner depends on:

* `bash >=4.0`
* `coreutils`
* `findutils` (`xargs`)
* `grep`

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
[23:43:37.755] Finished 'foo' (0)
[23:43:37.756] Starting 'bar'
[23:43:37.757] Finished 'bar' (0)
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
runner_set_default_task <task_name>
```

### 3.2. Task chaining

Tasks can launch other tasks in two ways: *sequentially* and in *parallel*.
This way you can optimize the task flow for maximum concurrency.

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

If you want a task to stop on error, use `runner_bubble`:

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

### 3.4. Flags

All flags you pass to the script are passed to your tasks. Flags are arguments
beginning with a dash.

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


## 5. WHY?

![Why this exists?][derp_why]

**Q:** Isn't Bash itself fundamentally a task runner?

**A:** No, it is not. Bash is a generic scripting language for unix.
You can write a script which can handle some basic stuff. But if it does a
lot of *independent* tasks, then you have to write boilerplate code to run
them individually or in parallel. This library makes it very easy to do
without writing much code.

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
but `bash`. You could do this in plain `bash`, but this library just makes
it go concurrent. It is especially useful for CI.

I would also like to mention [Manuel], which is a similar task runner for
`bash`. It doesn't do concurrency though, just adds more complexity (in my
humble opinion). Feel free to check it out, too.


## 6. Contribution

Got a suggestion for a feature? Feel free to open a feature request in the
issue section or make a pull request.


## Contacts

Email: [stylemistake@gmail.com]

Web: [stylemistake.com]

[gulp]: https://github.com/gulpjs/gulp
[issues]: https://github.com/stylemistake/bash-task-runner/issues
[derp_why]: http://cdn.alltheragefaces.com/img/faces/jpg/neutral-whyyyyy.jpg
[manuel]: https://github.com/ShaneKilkelly/manuel
[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
