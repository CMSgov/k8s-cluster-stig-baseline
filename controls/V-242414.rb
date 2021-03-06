# encoding: UTF-8

control 'V-242414' do
  title "The Kubernetes cluster must use non-privileged host ports for user
pods."
  desc  "Privileged ports are those ports below 1024 and that require system
privileges for their use. If containers can use these ports, the container must
be run as a privileged user. Kubernetes must stop containers that try to map to
these ports directly. Allowing non-privileged ports to be mapped to the
container-privileged port is the allowable method when a certain port is
needed. An example is mapping port 8080 externally to port 80 in the container."
  desc  'rationale', ''
  desc  'check', "
    On the Master node, run the command:

    kubectl get pods --all-namespaces

    The list returned is all pods running within the Kubernetes cluster. For
those pods running within the user namespaces (System namespaces are
kube-system, kube-node-lease and kube-public), run the command:

    kubectl get pod podname -o yaml | grep -i port

    Note: In the above command, \"podname\" is the name of the pod. For the
command to work correctly, the current context must be changed to the namespace
for the pod. The command to do this is:

    kubectl config set-context --current --namespace=namespace-name
    (Note: \"namespace-name\" is the name of the namespace.)

    Review the ports that are returned for the pod.

    If any host-privileged ports are returned for any of the pods, this is a
finding.
  "
  desc 'fix', "For any of the pods that are using host-privileged ports,
reconfigure the pod to use a service to map a host non-privileged port to the
pod port or reconfigure the image to use non-privileged ports."
  impact 0.5
  tag severity: 'medium'
  tag gtitle: 'SRG-APP-000142-CTR-000330'
  tag gid: 'V-242414'
  tag rid: 'SV-242414r717030_rule'
  tag stig_id: 'CNTR-K8-000960'
  tag fix_id: 'F-45647r717032_fix'
  tag cci: ['CCI-000382']
  tag nist: ['CM-7 b']

  userspace_ports_found = []

  # List pods not in system namespaces
  k8sobjects(api: 'v1', type: 'pods').where { namespace != 'kube-system' && namespace != 'kube-node-lease' && namespace != 'kube-public' }.entries.each do |entry|
    # List containers in each pod found
    k8sobject(api: 'v1', type: 'pods', name: entry.name, namespace: entry.namespace).k8sobject.spec.containers.each do |container|
      # Inspect any port mapped on each container
      next if container.ports.nil? || container.ports.empty?
      container.ports.each do |port|
        next if port.hostPort.nil?
        # Tally up ports found
        userspace_ports_found << port.hostPort
        describe "Pod: #{entry.name} Namespace: #{entry.namespace} ContainerName: #{container.name} hostPort: #{port.hostPort}" do
          subject { port.hostPort }
          it { should cmp >= 1024 }
        end
      end
    end
  end

  # Pass if no container ports are mapped in user namespaces
  if userspace_ports_found.empty?
    describe 'Host port mapping found in pods in the user namespaces' do
      subject { userspace_ports_found }
      it { should be_empty }
    end
  end
end
