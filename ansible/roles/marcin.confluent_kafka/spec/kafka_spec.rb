require 'spec_helper'

describe 'Running serverspec tests for marcin.confluent_kafka role' do

  if ['VMLC.all', 'VMLC.provision', 'VMLC.image_build'].include?(property['vmlc_stage'])

    describe 'Test if kafka is installed' do

      describe group(resolve_ansible_variables(property['kafka']['broker']['group'])) do
        it { should exist }
      end

      describe user(resolve_ansible_variables(property['kafka']['broker']['user'])) do
        it { should exist }
        it { should belong_to_group resolve_ansible_variables(property['kafka']['broker']['group']) }
        it { should have_home_directory resolve_ansible_variables(property['kafka']['broker']['home_dir']) }
      end

      describe file(resolve_ansible_variables(property['kafka']['broker']['install_dir'])) do
        it { should be_directory }
        it { should be_owned_by resolve_ansible_variables(property['kafka']['broker']['user'])}
        it { should be_grouped_into resolve_ansible_variables(property['kafka']['broker']['group']) }
        it { should be_mode 755 }
      end

      describe file(resolve_ansible_variables(property['kafka']['broker']['install_dir']) + "/conf") do
        it { should be_directory }
        it { should be_owned_by resolve_ansible_variables(property['kafka']['broker']['user'])}
        it { should be_grouped_into resolve_ansible_variables(property['kafka']['broker']['group']) }
        it { should be_mode 755 }
      end

      resolve_ansible_variables(property['kafka']['broker']['properties']['log_dirs']).each do |p|
        describe file("#{p}") do
          it { should be_directory }
          it { should be_owned_by resolve_ansible_variables(property['kafka']['broker']['user'])}
          it { should be_grouped_into resolve_ansible_variables(property['kafka']['broker']['group']) }
          it { should be_mode 755 }
        end
      end

      describe file(resolve_ansible_variables(property['kafka']['broker']['logfile_dir'])) do
        it { should be_directory }
        it { should be_owned_by resolve_ansible_variables(property['kafka']['broker']['user'])}
        it { should be_grouped_into resolve_ansible_variables(property['kafka']['broker']['group']) }
        it { should be_mode 755 }
      end

      describe file('/etc/systemd/system/kafka.service') do
        it { should be_file }
        it { should be_owned_by "root"}
        it { should be_grouped_into "root" }
        it { should be_mode 644 }
      end

    end

  end

  if ['VMLC.all', 'VMLC.provision', 'VMLC.image_build'].include?(property['vmlc_stage'])

    describe 'Test if kafka is configured' do

      describe file(resolve_ansible_variables(property['kafka']['broker']['install_dir']) + "/current") do
        it { should be_symlink }
      end

    end

  end

  if ['VMLC.all', 'VMLC.provision', 'VMLC.image_build'].include?(property['vmlc_stage'])

    describe 'Test if kafka service is running' do

      describe service('kafka.service') do
        it { should be_enabled }
        it { should be_running }
      end

      describe port(resolve_ansible_variables(property['kafka']['broker']['port'])) do
        it { should be_listening }
      end

      describe port(resolve_ansible_variables(property['kafka']['broker']['jmx_port'])) do
        it { should be_listening }
      end

      resolve_ansible_variables(property['kafka']['broker']['heap_opts']).each do |p|
        describe command("ps aux | grep -v grep | grep kafkaS") do
          its(:stdout) { should contain "#{p}"}
        end
      end

      resolve_ansible_variables(property['kafka']['broker']['jvm_performance_opts']).each do |p|
        describe command("ps aux | grep -v grep | grep kafkaS") do
          its(:stdout) { should contain "#{p}"}
        end
      end

      if resolve_ansible_variables(property['kafka']['broker']['prometheus_jmx_exporter_deployment']) == true

        describe command("ps aux | grep -v grep | grep kafkaS") do
          its(:stdout) { should contain "-javaagent:/opt/confluent_kafka/jmx_prometheus_javaagent/jmx_prometheus_javaagent-#{resolve_ansible_variables(property['kafka']['broker']['prometheus_jmx_exporter_version'])}.jar=#{resolve_ansible_variables(property['kafka']['broker']['prometheus_jmx_exporter_port'])}:/opt/confluent_kafka/conf/kafka-jmxexporter.yml"}
        end

      end

    end

  end

end
