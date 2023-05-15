marcin.confluent_kafka
=========

An Ansible role that installs and configures Confluent Kafka.

Requirements
------------

- Ansible verison 2.2.1.0+

Role Variables
--------------

Available variables are listed below, along with default values (see `defaults/main.yml`):

    kafka_broker_download_from_confluent: true
    kafka_broker_install_dir: "/opt/confluent_kafka"
    suppress_kafka_handlers: false
    proxy_env: "None"
    kafka:
      confluent_platform:
        confluent_metrics_enabled: false
        major_version: "5.2"
        minor_version: "1"
        scala_version: "2.12"
        home_dir: "/home/kafka"
        download_path: "/tmp"
        checksum: "c5612a324025a84b77b063b5b5698abd36e444e87ca4e01fa4bfbe5aa6396f61"
      broker:
        user: "kafka"
        group: "kafka"
        conf_dir: "{{ kafka_broker_install_dir }}/conf"
        port: 9092
        remove_download: false
        working_dir: "{{ kafka_broker_install_dir }}/current"
        install_dir: "/opt/confluent_kafka"
        jmx_port: 9096
        logfile_dir: "/var/log/confluent_kafka"
        heap_opts: ["-Xmx1g", "-Xms1g"]
        jvm_performance_opts: ["-XX:MetaspaceSize=96m", "-XX:G1HeapRegionSize=16M", "-XX:MinMetaspaceFreeRatio=50", "-XX:MaxMetaspaceFreeRatio=80"]
        zk_chroot: "kafka-{{ ansible_inventory_name }}"
        security_mode: "plaintext"
        ssl_truststore_password: "confluent"
        ssl_keystore_password: "confluent"
        ssl_key_password: "confluent"
        properties:
          log_dirs:
            - "/data/kafka/logs"
          log_retention_hours: 168
          auto_create_topics_enable: false
          background_threads: 10
          message_max_bytes: 1024000
          min_insync_replicas: 2
          num_io_threads: 8
          num_network_threads: 3
          # Below should be set to number of disks
          num_recovery_threads_per_data_dir: 1
          # Increase this if replicas are lagging
          num_replica_fetchers: 1
          offsets_retention_minutes: 10080
          unclean_leader_election_enable: false
          zookeeper_session_timeout_ms: 6000
          zookeeper_connection_timeout_ms: 6000
          # This should be string representing rack where given server is placed.
          broker_rack: "{{ kafka_broker_rack }}"
          default_replication_factor: 3
          num_partitions: 9
          quota_producer_default: 10485760
          quota_consumer_default: 10485760
          delete_topic_enable: true
          offsets_topic_replication_factor: 3
          transaction_state_log_replication_factor: 3
          transaction_state_log_min_isr: 2
          log_segment_bytes: 1073741824
          log_retention_check_interval_ms: 300000
          group_initial_rebalance_delay_ms: 3

Most of those variables are used to configure kafka broker, including Java memory and performance settings and kafka server properties.

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: marcin.confluent_kafka }

License
-------

MIT / BSD

Author Information
------------------

marcin
