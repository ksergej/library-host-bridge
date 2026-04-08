# Library Host Bridge

## Overview

Library System: Spring Boot REST services that integrate with IBM MQ to call a COBOL batch on z/OS (IBM Z XPlore) backed by DB2. End-to-end flow: REST → Java (Hexagonal) → MQ request → COBOL batch → DB2 → MQ reply → Java → REST.

## Architecture

Key integration rule (MQ correlation):
- COBOL: `MQMD-CORRELID = MQMD-MSGID`, then clear `MQMD-MSGID` so MQ generates a new one.
- Java: read `JMSMessageID` after send and receive reply with selector `JMSCorrelationID = '<JMSMessageID>'`.

ASCII diagram:

```
[ REST Client ]
      |
      v
[ Spring Boot (Hexagonal) ]
      |
      |  (JMS / MQ)
      v
[ MQ REQ QUEUE ] ---> [ COBOL BATCH ] ---> [ DB2 ]
       ^                  |
       |              CorrelId=MsgId
       |                  v
[ MQ REP QUEUE ] <---------+
       |
       v
[ Spring Boot MQ Gateway ]
       |
       v
[ REST Response ]
```

## Modules

| Module name | Type | Responsibility | How to run/build |
| --- | --- | --- | --- |
| library-domain | library | Pure domain model and ports (no Spring). | `mvn -pl library-domain -am package` |
| library-web-common | library | Shared web concerns (correlation ID, error handling, OpenAPI config). | `mvn -pl library-web-common -am package` |
| library-host-connector | library | MQ gateway/adapter, JAXB translator, MapStruct host mapping, MQ config/properties, XSD contract. | `mvn -pl library-host-connector -am package` |
| loan-command-service | app | Command endpoints for borrow/return, command application service. | `mvn -pl loan-command-service -am spring-boot:run` |
| loan-query-service | app | Query endpoint for active loans by user, query application service. | `mvn -pl loan-query-service -am spring-boot:run` |
| host-library-infra | infra | COBOL/JCL/DB2/Ansible assets for z/OS host. | `ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml host-library-infra/ansible/playbooks/smoke.yml` |

## Prerequisites

- Java 17
- Maven 3.9+
- Optional (host automation): Ansible + `ibm.ibm_zos_core`, Zowe CLI, access to IBM Z XPlore

## Build & Test

Copy/paste commands:

```
mvn -U test
mvn -U -DskipTests package
```

Per-module examples:

```
mvn -pl library-host-connector -am test
mvn -pl loan-command-service -am test
mvn -pl loan-query-service -am test
```

## Run Locally (Spring Boot)

Command service:

```
mvn -pl loan-command-service -am spring-boot:run
```

Query service:

```
mvn -pl loan-query-service -am spring-boot:run
```

Profiles (example):

```
mvn -pl loan-command-service -am spring-boot:run -Dspring-boot.run.profiles=xplore
mvn -pl loan-query-service -am spring-boot:run -Dspring-boot.run.profiles=local
```

Do not commit real secrets. Use `application-*.yml.example` plus environment variables or a secrets manager.

## API Quickstart (curl)

Borrow (200):

```
curl -i -X POST http://localhost:8080/api/loans/borrow \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: demo-corr-1' \
  -d '{"userId":"user-1","bookId":"book-1"}'
```

Return (200):

```
curl -i -X POST http://localhost:8080/api/loans/return \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: demo-corr-2' \
  -d '{"loanId":"loan-1"}'
```

By user (200):

```
curl -i -X POST http://localhost:8080/api/loans/by-user \
  -H 'Content-Type: application/json' \
  -H 'X-Correlation-Id: demo-corr-3' \
  -d '{"userId":"user-1"}'
```

Expected behavior:
- 200 for happy paths (valid payloads)
- 400 for validation errors (e.g., missing required fields)
- 503 when the host/MQ integration is unavailable

## Host/Infra Quickstart

Host assets live under `host-library-infra/` (COBOL, JCL, DB2, Ansible).

Current host programs:
- `LIBMQTST` (batch baseline)
- `LIBMQCIC` (parallel CICS-oriented program)

Run Ansible smoke from repo root:

```
ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/smoke.yml
```

Deploy-only + compile-only sequence:

```
ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/library_deploy.yml

ansible-playbook -i host-library-infra/ansible/inventories/hosts.yml \
  host-library-infra/ansible/playbooks/compile_host.yml
```

Fill placeholders in `host-library-infra/ansible/inventories/group_vars/zos_xplore.yml` before running on IBM Z XPlore.

Host CI workflow (FLOW-02):

- Workflow file: `.github/workflows/host-ci.yml`
- Trigger: `workflow_dispatch` (manual) and host-related `push`/`pull_request` path filters
- Required GitHub Secrets:
  - `ZOS_HOST`
  - `ZOS_SSH_USER`
  - `ZOS_SSH_PRIVATE_KEY`
  - `ZOS_HLQ`
- Optional GitHub Variable:
  - `ZOS_SSH_PORT` (defaults to `22`)

## Docs Index

- Docs index: `docs/README.md`
- Testing catalog: `docs/testing/TEST_CATALOG.md`
- Runbooks: `docs/runbooks/MODULES_AND_MVN_COMMANDS.md`
- Host smoke/debug: `docs/runbooks/HOST_SMOKE_AND_DEBUG.md`
- API docs: `docs/api/`
- MQ/Host docs: `docs/mq/`

## Security Note

Do not commit secrets or production credentials to git. Use `.example` files plus environment variables or a secrets manager, and rotate credentials immediately if anything is leaked.

## Maintenance

When a task adds/removes modules, changes endpoints, changes run/test commands, or changes host deploy workflows, update README.md in the same PR/commit.
