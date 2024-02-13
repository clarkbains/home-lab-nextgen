job "democratic-csi-iscsi-node" {
  datacenters = ["dc1"]

  # you can run node plugins as service jobs as well, but this ensures
  # that all nodes in the DC have a copy.
  type = "system"

  group "nodes" {
    task "plugin" {
      driver = "docker"

      env {
        CSI_NODE_ID = "${attr.unique.hostname}"
        
        # if you run into a scenario where your iscsi volumes are zeroed each time they are mounted,
        # you can configure the fs detection system used with the following envvar:
        #FILESYSTEM_TYPE_DETECTION_STRATEGY = "blkid"
      }

      config {
        image = "docker.io/democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.5.0",
          # must match the csi_plugin.id attribute below
          "--csi-name=org.democratic-csi.iscsi",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=node",
          "--server-socket=/csi/csi.sock",
        ]

        # node plugins must run as privileged jobs because they
        # mount disks to the host
        privileged = true
        ipc_mode = "host"
        network_mode = "host"

        mount {
          type = "bind"
          target = "/host"
          source = "/"
          readonly=false
        }
        
        # if you run into a scenario where your iscsi volumes are zeroed each time they are mounted,
        # you can try uncommenting the following additional mount block:
        #mount {
        #  type     = "bind"
        #  target   = "/run/udev"
        #  source   = "/run/udev"
        #  readonly = true
        #}
      }

      template {
        destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
driver: freenas-iscsi
instance_id:
httpConnection:
  protocol: http
  host: truenas.ott.cbains.ca
  port: 80
  # use only 1 of apiKey or username/password
  # if both are present, apiKey is preferred
  # apiKey is only available starting in TrueNAS-12
  #apiKey:
  username: root
  password: truenas
  allowInsecure: true
  # use apiVersion 2 for TrueNAS-12 and up (will work on 11.x in some scenarios as well)
  # leave unset for auto-detection
  #apiVersion: 2
sshConnection:
  host: truenas.ott.cbains.ca
  port: 22
  username: root
  # use either password or key
  password: truenas
zfs:
  # can be used to override defaults if necessary
  # the example below is useful for TrueNAS 12
  #cli:
  #  sudoEnabled: true
  #
  #  leave paths unset for auto-detection
  #  paths:
  #    zfs: /usr/local/sbin/zfs
  #    zpool: /usr/local/sbin/zpool
  #    sudo: /usr/local/bin/sudo
  #    chroot: /usr/sbin/chroot

  # can be used to set arbitrary values on the dataset/zvol
  # can use handlebars templates with the parameters from the storage class/CO
  #datasetProperties:
  #  "org.freenas:description": "{{ parameters.[csi.storage.k8s.io/pvc/namespace] }}/{{ parameters.[csi.storage.k8s.io/pvc/name] }}"
  #  "org.freenas:test": "{{ parameters.foo }}"
  #  "org.freenas:test2": "some value"
  
  # total volume name (zvol/<datasetParentName>/<pvc name>) length cannot exceed 63 chars
  # https://www.ixsystems.com/documentation/freenas/11.2-U5/storage.html#zfs-zvol-config-opts-tab
  # standard volume naming overhead is 46 chars
  # datasetParentName should therefore be 17 chars or less when using TrueNAS 12 or below
  datasetParentName: t/k8s/b/vols
  # do NOT make datasetParentName and detachedSnapshotsDatasetParentName overlap
  # they may be siblings, but neither should be nested in the other 
  # do NOT comment this option out even if you don't plan to use snapshots, just leave it with dummy value
  detachedSnapshotsDatasetParentName: t/k8s/b/snaps
  # "" (inherit), lz4, gzip-9, etc
  zvolCompression:
  # "" (inherit), on, off, verify
  zvolDedup:
  zvolEnableReservation: false
  # 512, 1K, 2K, 4K, 8K, 16K, 64K, 128K default is 16K
  zvolBlocksize:
iscsi:
  targetPortal: "truenas.ott.cbains.ca"
  # for multipath
  # targetPortals: [] # [ "server[:port]", "server[:port]", ... ]
  # leave empty to omit usage of -I with iscsiadm
  interface:

  # MUST ensure uniqueness
  # full iqn limit is 223 bytes, plan accordingly
  # default is "{{ name }}"
  #nameTemplate: "{{ parameters.[csi.storage.k8s.io/pvc/namespace] }}-{{ parameters.[csi.storage.k8s.io/pvc/name] }}"
  namePrefix: csi-
  nameSuffix: "-clustera"

  # add as many as needed
  targetGroups:
    # get the correct ID from the "portal" section in the UI
    - targetGroupPortalGroup: 1
      # get the correct ID from the "initiators" section in the UI
      targetGroupInitiatorGroup: 2
      # None, CHAP, or CHAP Mutual
      targetGroupAuthType: None
      # get the correct ID from the "Authorized Access" section of the UI
      # only required if using Chap
      #targetGroupAuthGroup:

  #extentCommentTemplate: "{{ parameters.[csi.storage.k8s.io/pvc/namespace] }}/{{ parameters.[csi.storage.k8s.io/pvc/name] }}"
  extentInsecureTpc: true
  extentXenCompat: false
  extentDisablePhysicalBlocksize: true
  # 512, 1024, 2048, or 4096,
  extentBlocksize: 4096
  # "" (let FreeNAS decide, currently defaults to SSD), Unknown, SSD, 5400, 7200, 10000, 15000
  extentRpm: "SSD"
  # 0-100 (0 == ignore)
  extentAvailThreshold: 80
EOH
    left_delimiter = "{{{"
    right_delimiter = "}}}"
      }

      csi_plugin {
        # must match --csi-name arg
        id        = "org.democratic-csi.iscsi"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 50
        memory = 256
      }
    }
  }
}