runner_default_task="shellcheck"
source_files=(bin/* src/* completions/* index.sh)

task_shellcheck() {
    runner_run shellcheck --exclude=SC2155 "${source_files[@]}"
}
