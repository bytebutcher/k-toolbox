#!/usr/bin/env python3

import argparse
import subprocess
import sys
import tempfile
import yaml


def load_yaml(file_path):
    if file_path == '-':
        return yaml.safe_load(sys.stdin)
    with open(file_path, 'r') as file:
        return yaml.safe_load(file)


def apply_changes(base_yaml, changes):
    def recursive_update(d, u):
        for k, v in u.items():
            if isinstance(v, dict):
                d[k] = recursive_update(d.get(k, {}), v)
            elif isinstance(v, list) and k == 'containers':
                for patch_container in v:
                    existing_container = next((c for c in d.get(k, []) if c['name'] == patch_container['name']), None)
                    if existing_container:
                        existing_container.update(patch_container)
                    else:
                        d.setdefault(k, []).append(patch_container)
            elif isinstance(v, list):
                d[k] = v
            else:
                d[k] = v
        return d

    return recursive_update(base_yaml, changes)


def run_kubectl(args, input_yaml=None):
    kubectl_cmd = ['kubectl', 'apply'] + args
    if input_yaml:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as temp_file:
            yaml.dump(input_yaml, temp_file, default_flow_style=False)
            temp_file_name = temp_file.name
        kubectl_cmd.extend(['-f', temp_file_name])

    result = subprocess.run(kubectl_cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result.returncode


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('-f', '--filename', help='Path to the base YAML file or - for stdin')
    parser.add_argument('-p', '--patch-file', action='append', help='Path to patch file(s) or - for stdin')
    parser.add_argument('-h', '--help', action='store_true', help='Show this help message and exit')

    args, unknown = parser.parse_known_args()

    if not args.filename:
        print("error: must specify -f")
        sys.exit(1)

    if args.help:
        # Run kubectl apply --help and append our custom help
        subprocess.run(['kubectl', 'apply', '--help'])
        print("\nAdditional options for k-apply:")
        print("  -p, --patch-file FILE  Path to patch file(s) or - for stdin")
        sys.exit(0)

    base_yaml = load_yaml(args.filename)

    if args.patch_file:
        for patch_file in args.patch_file:
            patch = load_yaml(patch_file)
            base_yaml = apply_changes(base_yaml, patch)

    return run_kubectl(unknown, base_yaml)


if __name__ == '__main__':
    sys.exit(main())