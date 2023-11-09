#!/bin/bash

set -e
set -u
set -o pipefail

function check_required_tools() {
    if ! command -v terraform &> /dev/null; then
        echo "Error: terraform is not installed or not in PATH."
        exit 1
    fi
}

function destroy_infra() {
    local tf_dir="${PWD}/terraform"
    local backend_conf="${tf_dir}/backend.conf"

    cd "${tf_dir}" || exit

    terraform init -reconfigure -backend-config="${backend_conf}"

    if ! terraform validate; then
        echo "Terraform validation failed. Exiting..."
        exit 1
    fi

    echo "Destroying all resources..."
    terraform destroy -auto-approve

    cd - || exit
}

check_required_tools
destroy_infra