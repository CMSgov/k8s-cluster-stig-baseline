# encoding: UTF-8

control 'V-242395' do
  title 'Kubernetes dashboard must not be enabled.'
  desc  "While the Kubernetes dashboard is not inherently insecure on its own,
it is often coupled with a misconfiguration of Role-Based Access control (RBAC)
permissions that can unintentionally over-grant access. It is not commonly
protected with \"NetworkPolicies\", preventing all pods from being able to
reach it. In increasingly rare circumstances, the Kubernetes dashboard is
exposed publicly to the internet."
  desc  'rationale', ''
  desc  'check', "
    From the master node, run the command:

    kubectl get pods --all-namespaces -l k8s-app=kubernetes-dashboard

    If any resources are returned, this is a finding.
  "
  desc 'fix', "
    Delete the Kubernetes dashboard deployment with the following command:

    kubectl delete deployment kubernetes-dashboard --namespace=kube-system
  "
  impact 0.5
  tag severity: 'medium'
  tag gtitle: 'SRG-APP-000033-CTR-000095'
  tag gid: 'V-242395'
  tag rid: 'SV-242395r712541_rule'
  tag stig_id: 'CNTR-K8-000420'
  tag fix_id: 'F-45628r712540_fix'
  tag cci: ['CCI-000213']
  tag nist: ['AC-3']

  describe 'Kubernetes Dashboard resources' do
    subject { k8sobjects(api: 'v1', type: 'pods', labelSelector: 'k8s-app=kubernetes-dashboard') }
    it { should_not exist }
  end
end
