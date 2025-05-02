---
- name: CIS 2.3.4 - Ensure Telnet client is not installed
  hosts: all
  become: yes
  gather_facts: yes

  vars:
    backup_dir: "/var/backups/cis_telnet_removal"
    telnet_pkg: "telnet"
    log_file: "/var/log/cis_telnet_removal.log"

  tasks:

    - name: "Checkpoint 1 - Create backup directory"
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'

    - name: "Checkpoint 2 - Backup list of installed telnet-related packages"
      shell: "rpm -qa | grep -i {{ telnet_pkg }} > {{ backup_dir }}/telnet_rpm_list.txt"
      register: rpm_list
      changed_when: false

    - name: "Checkpoint 3 - Save current telnet binary location if exists"
      shell: "which telnet || true"
      register: telnet_path
      changed_when: false

    - name: "Checkpoint 4 - Save checksum of telnet binary if it exists"
      shell: "sha256sum {{ telnet_path.stdout }} > {{ backup_dir }}/telnet_sha256sum.txt"
      when: telnet_path.stdout != ''
      changed_when: false

    - name: "Checkpoint 5 - Ensure telnet package is absent (CIS 2.3.4)"
      package:
        name: "{{ telnet_pkg }}"
        state: absent
      register: telnet_removed

    - name: "Checkpoint 6 - Log telnet removal result"
      lineinfile:
        path: "{{ log_file }}"
        line: "Telnet package removal status: {{ 'Removed' if telnet_removed.changed else 'Already Absent' }} at {{ ansible_date_time.iso8601 }}"
        create: yes
        mode: '0644'

    - name: "Checkpoint 7 - Verify telnet is no longer available"
      command: "which telnet"
      register: verify_telnet
      failed_when: verify_telnet.rc == 0
      ignore_errors: false
      changed_when: false

