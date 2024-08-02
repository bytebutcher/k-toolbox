# k-toolkit (Kubernetes Toolkit)

k-toolkit is a collection of utility scripts for working with Kubernetes clusters. 
This toolbox provides enhanced functionality and convenience for common Kubernetes operations.

## Tools

### k-apply

An enhanced version of kubectl apply that allows patching of Kubernetes manifests before applying them to the cluster.

**Usage:**
```
k-apply -f <base_yaml_file> [-p <patch_file>...] [kubectl_options]
```

**Options:**
- `-f, --filename`: Path to the base YAML file or `-` for stdin (required)
- `-p, --patch-file`: Path to patch file(s) or `-` for stdin (can be specified multiple times)
- `-h, --help`: Displays help information, including all supported `kubectl apply` options
- All other `kubectl apply` options are supported and passed through to kubectl

