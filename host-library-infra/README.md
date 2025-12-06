# host-library-infra

Host-side infrastructure for the "Library System" demo:

- COBOL MQ test program (LIBMQTST)
- JCL for compile/run and tests
- DB2 schema and testdata
- Ansible playbooks for deploy and tests on IBM Z (XPlore-compatible)

## Layout

cobol/
  LIBMQTST.cbl        - MQ echo program with CorrelationId handling

jcl/
  LIBMQTSTC.jcl       - Compile+link job (template, customize DSNs)
  LIBMQTST.jcl        - Simple run job (template)
  test/LIBTEST01.jcl  - Example test job

db2/
  schema.sql          - LIBRARY.USER/BOOK/LOAN DDL
  testdata.sql        - sample data
  jobs/LIBSCHEMA.jcl  - DSNTEP2 job to create schema
  jobs/LIBDATA.jcl    - DSNTEP2 job to load data

ansible/
  ansible.cfg
  inventories/hosts.yml
  inventories/group_vars/all.yml
  playbooks/
    smoke.yml         - connectivity + Python/ZOAU check
    library_deploy.yml- PDS, upload COBOL/JCL, compile, run
    db2_schema.yml    - upload + submit DB2 schema/data jobs
    library_tests.yml - submit test job

## Usage (high level)

1. On your local machine (controller), install:
   - Python 3.11+
   - ansible-core 2.17.x
   - ibm.ibm_zos_core collection

2. Adjust `ansible/inventories/hosts.yml` and `group_vars/all.yml`:
   - `ansible_host`, `ansible_user`
   - `hlq`

3. Run smoke test:

   cd ansible
   ansible-playbook playbooks/smoke.yml

4. Deploy COBOL + JCL:

   ansible-playbook playbooks/library_deploy.yml

5. Deploy DB2 schema/data:

   ansible-playbook playbooks/db2_schema.yml

6. Run host tests:

   ansible-playbook playbooks/library_tests.yml

Customize JCL datasets (COBOL/MQ/DB2 libraries) to match your system.
