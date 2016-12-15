# bounded-local Kubernetes Flexvolume

Here is an example implementation of flexvolume which creates a volume much like the kubernetes EmptyDir volume but with some interesting attributes that may assist cluster administrators and developers in the collection and forwarding of log files from their kubernetes cluster to a central logging platform, such as splunk or elasticsearch.

Features of bounded-local volumes: -

* They are provisioned locally on the node hosting the kubelet (much like EmptyDir)
* They are bounded by maximum size (therefore protecting the system from a undisciplied process logging excessively)
* They can be optionally mounted to another location on the node for log collection to occur.
* They can be left intact for a period of time after pod deletion in order for log collection to finish collecting the output.
* They can collect meta-data from a pod and add it to logging events forwarded to the logging solution.

## Using a bounded-local volume

To use the volume, add a FlexVolume mount to your pod like this: -

    apiVersion: v1
    kind: Pod
    metadata:
      name: logging-test1
      annotations:
        launched_as: part_of_voltest
      labels:
        k8s-app: random_logger
        voltestpod: "true"
    spec:
      containers:
        - name: logtest1
          image: davidmccormick/random_log_generator
          volumeMounts:
        - name: logging
          mountPath: /logs
      volumes:
      - name: logging
        flexVolume:
          driver: kubernetes.io/bounded-local
          fsType: ext4
          options:
            size: "4096"
            cleanupDelay: "60"
            logCollectCopy: "true"

In the example above the random_log_generator image above writes a random log to /logs/random.log.  We have mounted a bounded-local 
volume of 4Gib on /logs, this volume will also be mirrored to another location from log collection via the logCollectCopy option and we have set a delay of 60 seconds before the volume is cleaned up after it has been unmounted/removed from the pod.

The delayed clean-up and logCollectCopy features require that a separate controller process be run on the kubernetes node and, of course, a log collection daemon will also need to be run.  An example controller process is included as 'bounded-local-controller' (see Installing the Controller)

## Installing the flex-volume on the kubelet

Add the bounded-local script to the location of kubelets flexible volume directory that you specify to the kubelet with the --volume-plugin-dir command-line parameter, e.g. if we have set _--volume-plugin-dir=/etc/kubernetes/vol-plugins_ on the kubelet then we will add the script as /etc/kubernetes/vol-plugins/kubernetes.io~bounded-local/bounded-local.

Note: This flexvolume requires access to the system mount table, so you may encounter difficulties in using this volume when your kubelet is running inside a container.

You can configure certain aspects of volumes, such as their location etc. by editing the variables at the top of the script: -

    # VOLUME_PATH: location of sparse file and meta-data
    # must be accessible to kublet (mount if running kubelet in container)
    VOLUME_PATH=/var/lib/kubelet/bounded-local
    
    # DEFAULT_DELAY: 0 for immediate removal (performed by the driver)
    # When non-zero volume clean up must be performed by another maintenance task
    # driver just umounts and updates metadata status.
    DEFAULT_DELAY=0
    
    # DEFAULT_SIZE: Size in MB for the sparse volume
    DEFAULT_SIZE=2048
    
    # DEFAULT_MIRROR: Whether to mirror (mount it read only elsewhere) for log collection
    DEFAULT_MIRROR="false"

## Installing the controller on the kubelet node

The controller is designed to check the bounded-volumes checking for volumes that need to be cleaned up (the cleanupDelay option) and managing a local log collector (such as a splunk universal forwarder).  The controller requires access to the system mount table so you may encounter issues if trying to run it in a container.

Here is an example config for running the controller as a systemd service: -

    [Unit]
    Description=Runs the bounded-local-controller for managing bounded-local volumes and making them available for log collection.
    
    [Service]
    Environment=RUN_LOOP_DELAY=10
    Environment=VOLUME_PATH=/var/lib/kubelet/bounded-local
    Environment=LOGGING_PATH=/var/log-collection
    Environment=LOGGING_BACKEND_PLUGIN=/opt/bin/bounded-local-splunk
    ExecStart=/bin/bash -c "systemd-cat -t bounded-local-controller /opt/bin/bounded-local-controller"
    Type=simple
    Restart=on-failure
    RestartSec=5
    
    [Install]
    WantedBy=multi-user.target

The controller script is configured by the following ENVIRONMENT variables: -

* RUN_LOOP_DELAY - the time in seconds between checking the volumes (defaults to not set, i.e. do not loop).
* VOLUME_PATH - the path of the volumes (defaults to /var/lib/kubelet/bounded-local).
* LOGGING_PATH - the path where volumes are mirrored for log collection (defaults to /var/log-collection).
* LOGGING_BACKEND_PLUGIN - a plugin script to manage a specific type of log collector (defaults to none).

In the example system service above, the variables are set to run the controller every 10 seconds and to enable the splunk backend for log collection.

## Advanced Log Collection

Logs can collected simply by watching for all log files under /var/log-collection/*

### Pod metadata

It is often more desirable to record meta-data along with our logs 



