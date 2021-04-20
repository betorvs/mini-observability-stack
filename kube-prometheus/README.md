# kube-prometheus


## install

```
jb install
```

## Patch node-exporter daemonset

When using docker-desktop it cannot mount `root` directory, then that patch simple remove it.