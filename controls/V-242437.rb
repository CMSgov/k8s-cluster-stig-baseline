# encoding: UTF-8

control 'V-242437' do
  title 'Kubernetes must have a pod security policy set.'
  desc  "Enabling the admissions webhook allows for Kubernetes to apply
policies against objects that are to be created, read, updated, or deleted. By
applying a pod security policy, control can be given to not allow images to be
instantiated that run as the root user. If pods run as the root user, the pod
then has root privileges to the host system and all the resources it has. An
attacker can use this to attack the Kubernetes cluster. By implementing a
policy that does not allow root or privileged pods, the pod users are limited
in what the pod can do and access."
  desc  'rationale', ''
  desc  'check', "
    On the Master Node, run the command:

    kubectl get podsecuritypolicy

    If there is no pod security policy configured, this is a finding.

    For any pod security policies listed, edit the policy with the command:

    kubectl edit podsecuritypolicy policyname
    (Note: \"policyname\" is the name of the policy.)

    Review the runAsUser, supplementalGroups and fsGroup sections of the policy.

    If any of these sections are missing, this is a finding.

    If the rule within the runAsUser section is not set to
\"MustRunAsNonRoot\", this is a finding.

    If the ranges within the supplementalGroups section has min set to \"0\" or
min is missing, this is a finding.

    If the ranges within the fsGroup section has a min set to \"0\" or the min
is missing, this is a finding.
  "
  desc 'fix', "
    From the Master node, save the following policy to a file called
restricted.yml.

    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: restricted
      annotations:
        seccomp.security.alpha.kubernetes.io/allowedProfileNames:
'docker/default,
        apparmor.security.beta.kubernetes.io/allowedProfileNames:
'runtime/default'
        seccomp.security.alpha.kubernetes.io/defaultProfileName:
'runtime/default'
        apparmor.security.beta.kubernetes.io/defaultProfileName:
'runtime/default'
    spec:
      privileged: false
      # Required to prevent escalations to root.
      allowPrivilegeEscalation: false
      # This is redundant with non-root + disallow privilege escalation,
      # but we can provide it for defense in depth.
      requiredDropCapabilities:
        - ALL
      # Allow core volume types.
      volumes:
        - 'configMap'
        - 'emptyDir'
        - 'projected'
        - 'secret'
        - 'downwardAPI'
        # Assume that persistentVolumes set up by the cluster admin are safe to
use.
        - 'persistentVolumeClaim'
      hostNetwork: false
      hostIPC: false
      hostPID: false
      runAsUser:
        # Require the container to run without root privileges.
        rule: 'MustRunAsNonRoot'
      seLinux:
        # This policy assumes the nodes are using AppArmor rather than SELinux.
        rule: 'RunAsAny'
      supplementalGroups:
        rule: 'MustRunAs'
        ranges:
          # Forbid adding the root group.
          - min: 1
            max: 65535
      fsGroup:
        rule: 'MustRunAs'
        ranges:
          # Forbid adding the root group.
          - min: 1
            max: 65535
      readOnlyRootFilesystem: false

    To implement the policy, run the command:

    kubectl create -f restricted.yml
  "
  impact 0.7
  tag severity: 'high'
  tag gtitle: 'SRG-APP-000342-CTR-000775'
  tag gid: 'V-242437'
  tag rid: 'SV-242437r712667_rule'
  tag stig_id: 'CNTR-K8-002010'
  tag fix_id: 'F-45670r717028_fix'
  tag cci: ['CCI-002233']
  tag nist: ['AC-6 (8)']

  pod_security_policies = k8sobjects(api: 'policy/v1beta1', type: 'podsecuritypolicies')

  describe 'Pod Security Policies' do
    subject { pod_security_policies }
    it { should exist }
  end

  pod_security_policies.entries.each do |policy|
    policy_object = k8sobject(api: 'policy/v1beta1', type: 'podsecuritypolicies', name: policy.name)

    describe policy_object do
      its ('item.spec.runAsUser.rule') { should cmp 'MustRunAsNonRoot' }
    end

    describe "Pod security: #{policy.name}; Policy fsGroup ranges" do
      subject { policy_object.item.spec.fsGroup.ranges }
      it { should_not be_nil }
    end

    unless policy_object.item.spec.fsGroup.ranges.nil?
      describe "Pod security: #{policy.name}; Policy fsGroup range minimum" do
        subject { policy_object.item.spec.fsGroup.ranges.map(&:min) }
        it { should_not be_empty }
        it { should_not include 0 }
      end
    end

    describe "Pod security: #{policy.name}; Policy supplementalGroups ranges" do
      subject { policy_object.item.spec.supplementalGroups.ranges }
      it { should_not be_nil }
    end

    unless policy_object.item.spec.supplementalGroups.ranges.nil?
      describe "Pod security: #{policy.name}; Policy supplementalGroups range minimum" do
        subject { policy_object.item.spec.supplementalGroups.ranges.map(&:min) }
        it { should_not be_empty }
        it { should_not include 0 }
      end
    end
  end
end
