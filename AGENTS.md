# AGENTS.md — Library System (Java Spring Boot ⇄ MQ ⇄ z/OS Host / COBOL / DB2)

## Project purpose

Library System: REST API на Spring Boot, который через IBM MQ вызывает COBOL batch на z/OS (IBM Z XPlore) и DB2.
Полный поток: REST → Java (Hexagonal) → MQ REQ → COBOL batch → DB2 → MQ REP → Java → REST.

## Important docs

- PROJECT_CONTEXT.md — каноническое описание среды, архитектуры и ограничений.
- PROJECT_TODO_*.md — актуальный backlog по приоритетам (P0/P1/P2).
- host-library-infra/ — COBOL, JCL, DB2-скрипты и Ansible для z/OS.

Пожалуйста, **сначала прочитай эти файлы**, прежде чем вносить изменения.

## Architecture constraints

- Java:
  - Spring Boot, Hexagonal/Clean Architecture:
    - `domain/` — чистая доменная модель (без @Entity/@JPA, без JAXB).
    - `application/` — use cases (LoanAppService и др.).
    - `ports/` — интерфейсы для внешних систем (например, LibraryHostPort).
    - `adapters/mq/` — реализация портов для MQ (LibraryMqAdapter).
    - `gateway/` — общий MQ gateway (CicsMqGatewayTemplate).
    - `mapping/` — MapStruct мапперы (LoanRestMapper, LoanHostMapper).
    - `contract/host-schema/` — XSD + JAXB DTO для host.
- Host:
  - COBOL batch (без CICS) + DB2.
  - MQ correlation: CorrelId = MsgId (см. COBOL-фрагмент в PROJECT_CONTEXT.md).

## MQ correlation rule (VERY IMPORTANT)

- COBOL:
  - MOVE MQMD-MSGID TO MQMD-CORRELID.
  - MOVE MQMI-NONE TO MQMD-MSGID.
- Java:
  - После отправки сообщения в request-очередь прочитать JMSMessageID.
  - Читать ответ из reply-очереди по селектору:
    - `JMSCorrelationID = '<JMSMessageID>'`.

Не изменяй эту стратегию.

## Tools & limitations

- z/OS host: IBM Z XPlore, нельзя ставить коммерческие продукты, Python 3.9 + ZOAU.
- Используем Ansible + ibm.ibm_zos_core, **не используем** Wazi Deploy.
- Локально MQ может быть IBM MQ или Artemis (Docker), но код должен быть максимально абстрактным.

## How to make changes

1. Перед началом задачи:
   - Осмотрись в `PROJECT_CONTEXT.md` и `PROJECT_TODO_*.md`.
2. Всегда поддерживай Hexagonal структуру:
   - домен не тянет в себя аннотации инфраструктуры.
   - адаптеры и gateway не лезут в бизнес-логику.
3. Пиши тесты:
   - Для MQ-слоя: юнит-тесты с моками JmsTemplate и Translator.
   - Не добавляй интеграционные тесты с реальным MQ без явной инструкции.
4. Если добавляешь/удаляешь/переименовываешь тесты, обновляй docs/testing/TEST_CATALOG.md в том же PR/коммите.
5. Если добавляешь/удаляешь/переименовываешь модули или меняешь run/test команды, обновляй docs/runbooks/MODULES_AND_MVN_COMMANDS.md в том же PR/коммите.
6. Если меняешь модули/эндпоинты/run/test команды или workflows деплоя, обновляй README.md в том же PR/коммите.
7. Если меняешь host smoke/debug workflow, модули, эндпоинты или run команды, обновляй docs/runbooks/HOST_SMOKE_AND_DEBUG.md в том же PR/коммите.

## Example tasks you can do

- Завершить `pom.xml` так, чтобы:
  - проект собирался (Java 17),
  - подключены Spring Boot, MapStruct, JAXB (jaxb2-maven-plugin), JUnit/Mockito.
- Реализовать `CicsMqGatewayTemplate` по CorrelId=MsgId.
- Дописать `LibraryMqAdapter` и соответствующие тесты.
- Настроить JAXB-слой по XSD в `contract/host-schema/`.

##  Правила работы с агентами
### 1 Нумерация сообщений (обязательно)
Каждое сообщение агента в чате проекта начинается с:

```text
=== Сообщение : ID: <последовательный числовой ID> : TIME: <YYYY-MM-DD HH:MM:SS> ===
Проект : <имя чата/ветки работы>
=====================================================
```

### 2 Chit commits (обязательно)
Ключевые решения фиксируются как chit commits.
- Формат: `PROJECT_CONTEXT_CHIT_COMMIT.md`
- Лог(если есть): `PROJECT_CONTEXT_CHIT_LOG.md`
- Эти файлы — источник правды.

### 3 Не угадывать
При неоднозначности агент обязан либо:
- задать уточняющий вопрос,
- либо сделать best-effort и явно пометить допущения (если пользователь попросил не уточнять).

