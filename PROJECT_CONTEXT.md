PROJECT: Library System (Java Spring Boot ⇄ MQ ⇄ z/OS Host / COBOL / DB2)

================================================================================
ENVIRONMENT
================================================================================

LOCAL (MacBook):
- OS: macOS
- Shell: zsh
- Zowe CLI:
    CLI Version: 8.29.5
    Zowe Release Version: v3.4.0
- Ansible:
    ansible-core 2.17.x
    Python runtime: 3.13.x (brew)
- Status:
    ✅ Zowe CLI fully working
    ⚠️ Ansible Galaxy SSL issues resolved via certifi / REQUESTS_CA_BUNDLE
    ✅ ibm.ibm_zos_core collection installable after SSL fix
    ❌ ibm.ibm_zos_wazi_deploy NOT available (commercial)

HOST (IBM Z XPlore):
- Access: SSH port 22 ✅
- OS: z/OS UNIX System Services
- Restrictions:
    - No commercial software installation
    - No system modifications
- Python:
    Path: /usr/lpp/IBM/cyp/v3r9/pyz/bin/python3
    Version: Python 3.9.2 ✅
- ZOAU:
    ZOAU_ROOT=/usr/lpp/IBM/zoautil
    Python binding test:
        python3 -c "import zoautil_py; print('ZOAU OK')"
        ✅ works
- Other:
    - IBM MQ runtime assumed available
    - DB2 available via JCL utilities

================================================================================
ARCHITECTURE
================================================================================

END-TO-END FLOW:

    REST Client (JSON)
        |
        v
    Spring Boot (Java)
      - Hexagonal Architecture
      - Domain / Application / Ports / Adapters
      - CorrelationID tracing
        |
        v
    IBM MQ (Request Queue)
        |
        v
    COBOL Batch Program (no CICS)
        |
        v
    DB2
        |
        v
    IBM MQ (Reply Queue, CorrelId = MsgId)
        |
        v
    Spring Boot → REST Response

--------------------------------------------------------------------------------
ASCII ARCHITECTURE DIAGRAM
--------------------------------------------------------------------------------

[ REST (JSON) ]
       |
       v
[ Spring Boot (Hexagonal) ]
       |
       |  (JMS / MQ)
       v
[ MQ REQ QUEUE ] ---> [ COBOL BATCH ] ---> [ DB2 ]
        ^                   |
        |               CorrelId=MsgId
        |                   v
[ MQ REP QUEUE ] <-----------+
        |
        v
[ Spring Boot MQ Gateway ]
        |
        v
[ REST Response ]

--------------------------------------------------------------------------------
HEXAGONAL / CLEAN ARCHITECTURE (JAVA)
--------------------------------------------------------------------------------

Логические слои Java-backend:

- domain/
  - Чистая доменная модель: Book, User, Loan и пр.
  - Бизнес-правила без зависимостей от Spring, JAXB, JPA и т.п.
  - Порт домена: LibraryHostPort (интерфейс).

- application/
  - Application-сервисы, оркеструющие домен:
    - LoanAppService и др.
  - Знают о портах домена, но не знают об инфраструктуре.

- ports/
  - Интерфейсы для внешних систем (доменные порты).
  - Пример: LibraryHostPort (операции для обращения к host/COBOL).

- adapters/
  - Реализации портов (инфраструктурные адаптеры).
  - MQ-адаптер: LibraryMqAdapter — реализация LibraryHostPort через MQ.
  - REST-адаптеры: контроллеры, принимающие/отдающие JSON.

- gateway/
  - Общий MQ-gateway-шаблон:
    - CicsMqGatewayTemplate — инкапсулирует отправку/приём по MQ c CorrelId.
  - Используется адаптерами, но не зависит от домена.

- api/
  - REST-контроллеры и DTO:
    - LoanController, BorrowBookRequest, ReturnBookRequest, LoanResponse.

- contract/host-schema/
  - XSD-схема для формата обмена с host (XML).
  - На основе схемы через JAXB генерируются Java-классы (contract-модель).

- mapping/
  - MapStruct-мапперы:
    - LoanRestMapper — REST DTO ↔ доменная модель.
    - LoanHostMapper — доменная модель ↔ JAXB-контракт (host schema).

================================================================================
CODE / PROJECT STRUCTURE
================================================================================

ЛОГИЧЕСКИЙ РАЗДЕЛ РЕПОЗИТОРИЯ:

java-backend/
├── domain/
│   ├── model/
│   │   ├── Book.java
│   │   ├── User.java
│   │   └── Loan.java
│   └── port/
│       └── LibraryHostPort.java
├── application/
│   └── LoanAppService.java
├── api/
│   ├── controller/
│   │   └── LoanController.java
│   └── dto/
│       ├── BorrowBookRequest.java
│       ├── ReturnBookRequest.java
│       └── LoanResponse.java
├── mapping/
│   ├── LoanRestMapper.java      (MapStruct)
│   └── LoanHostMapper.java      (MapStruct)
├── contract/
│   └── host-schema/
│       ├── library-loan.xsd     (XSD для host contract)
│       └── target/generated-sources/jaxb/
│           └── com/company/library/host/schema/*.java (JAXB)
├── ports/                       (опционально, если не внутри domain/)
├── adapters/
│   └── mq/
│       ├── LibraryMqAdapter.java
│       └── translator/
│           └── LibraryMessageTranslator.java
├── gateway/
│   └── CicsMqGatewayTemplate.java
└── src/test/java/
    ├── mq/
    │   ├── CicsMqGatewayTemplateTest.java
    │   └── LibraryMqAdapterTest.java
    └── domain/
        └── LoanDomainTest.java

host-library-infra/
├── cobol/
│   └── LIBMQTST.cbl
├── jcl/
│   ├── LIBMQTST.jcl
│   ├── LIBSCHEMA.jcl
│   └── LIBDATA.jcl
├── db2/
│   ├── library_schema.sql
│   └── library_testdata.sql
└── ansible/
    ├── inventories/
    │   └── xplore/
    │       └── hosts.yml
    ├── playbooks/
    │   ├── smoke.yml
    │   └── library_deploy.yml
    └── group_vars/
        └── all.yml

================================================================================
MQ CORRELATION STRATEGY
================================================================================

Стратегия корреляции сообщений фиксирована и обязательна:

- На COBOL-стороне (host):
  - При обработке запроса:
    - MQMD-CORRELID = входящий MQMD-MSGID
    - MQMD-MSGID очищается, чтобы MQ сгенерировал новый.
- На Java-стороне:
  - После отправки сообщения в request-очередь:
    - Берётся JMSMessageID отправленного сообщения.
  - Ответ читается из reply-очереди по селектору:
    - JMSCorrelationID = (JMSMessageID запроса).

WORKING COBOL FRAGMENT (MQ CORRELATION):

    * From request MQMD
    * MOVE request MsgId to CorrelId
         MOVE MQMD-MSGID      TO MQMD-CORRELID.

    * Clear MsgId so MQ generates a new one for reply
         MOVE MQMI-NONE       TO MQMD-MSGID.

LOCAL JAVA BEHAVIOR (MQ GATEWAY):

- CicsMqGatewayTemplate:
  - Отправляет JMS-сообщение в request-очередь.
  - Читает JMSMessageID.
  - Формирует JMS selector: "JMSCorrelationID = '<JMSMessageID>'".
  - Ожидает ответ в reply-очереди с таймаутом.

================================================================================
JAXB CONTRACT LAYER (HOST SCHEMA)
================================================================================

Цель: формализованный контракт с host в виде XML-схем (XSD) и сгенерированных DTO, разделённых от доменной модели.

- XSD (пример): contract/host-schema/library-loan.xsd
  - Описывает:
    - HostBorrowRequest
    - HostBorrowResponse
    - Структуры Book/User/Loan для host.

- Генерация:
  - Используется jaxb2-maven-plugin.
  - Целевой пакет: com.company.library.host.schema.
  - Выход: target/generated-sources/jaxb/com/company/library/host/schema/*.

- Использование:
  - LibraryMessageTranslator:
    - Domain → JAXB DTO → XML (маршаллинг) → bytes (MQ payload).
    - XML (bytes) → JAXB DTO → Domain (unmarshal + маппинг).

================================================================================
MAPSTRUCT MAPPING
================================================================================

Для типобезопасного маппинга между слоями используются мапперы MapStruct.

LoanRestMapper — граница REST ↔ домен:

    @Mapper(componentModel = "spring")
    public interface LoanRestMapper {

        Loan toDomain(BorrowBookRequest request);

        LoanResponse toResponse(Loan loan);
    }

LoanHostMapper — граница домен ↔ JAXB-контракт (host):

    @Mapper(componentModel = "spring")
    public interface LoanHostMapper {

        HostBorrowRequest toHostRequest(Loan loan);

        Loan fromHostResponse(HostBorrowResponse response);
    }

Особенности:

- componentModel = "spring" — мапперы регистрируются как Spring-бины.
- Основная логика — генерация кода на этапе компиляции.
- При изменении доменных или контрактных DTO компилятор подсвечивает несовместимые изменения.

================================================================================
MQ LAYER TESTING (JUNIT + MOCKS)
================================================================================

Для MQ-слоя используются unit-тесты с моками (JUnit 5 + Mockito):

- Цели:
  - Проверить работу CicsMqGatewayTemplate без реального MQ:
    - Корректность формирования селектора.
    - Корректность обработки таймаутов и ошибок.
  - Проверить LibraryMqAdapter:
    - Взаимодействие с gateway и translator.
    - Корректная реакция на ошибки host.

- Подход:
  - Подмена JmsTemplate в CicsMqGatewayTemplate на mock.
  - Мокирование LibraryMessageTranslator в тестах адаптера.
  - Использование assert’ов для проверки:
    - что отправка идёт в правильную очередь;
    - JMSCorrelationID учитывается в селекторе;
    - исключения переводятся в доменные HostCommunicationException и т.п.

================================================================================
ANSIBLE / AUTOMATION
================================================================================

- Используется коллекция ibm.ibm_zos_core:
  - Копирование файлов на z/OS (zos_copy).
  - Запуск JCL (zos_job_submit) с проверкой RC.
- Wazi Deploy не используется (коммерческий продукт, недоступен).
- Параметры Python-интерпретатора на z/OS:

  group_vars/all.yml:

    PYZ: "/usr/lpp/IBM/cyp/v3r9/pyz"
    ZOAU: "/usr/lpp/IBM/zoautil"
    ansible_python_interpreter: "{{ PYZ }}/bin/python3"

- Кодировка:
  - Исходники перед копированием должны конвертироваться из ISO8859-1 в IBM-1047 (на уровне zos_copy).

================================================================================
TESTING STRATEGY
================================================================================

Java:
- Unit-тесты:
  - Доменные правила (LoanDomainTest и др.).
  - Мапперы MapStruct (простые проверки, что поля маппятся).
  - MQ-слой: CicsMqGatewayTemplateTest, LibraryMqAdapterTest (с моками).
- Интеграционные тесты:
  - С MQ (Artemis/IBM MQ в docker, по возможности).
  - Проверка полной связки: REST → Application → Adapter → Gateway (без host).

Host:
- JCL-based tests:
  - Запуск LIBMQTST.jcl с проверкой RC.
  - Отдельные JCL для загрузки схемы и тестовых данных (LIBSCHEMA.jcl, LIBDATA.jcl).

E2E:
- Поток:
  - REST → Java → MQ → COBOL → DB2 → MQ → Java → REST.
- Корреляция:
  - CorrelationID = MsgId как на COBOL, так и в Java-gateway.
- Отслеживание:
  - CorrelationId прокидывается сквозь логирование Java и, по возможности, в host-логах.

================================================================================
DECISIONS (FINAL)
================================================================================

- ✅ Используем Ansible + ibm.ibm_zos_core для автоматизации на z/OS.
- ❌ Не используем Wazi Deploy (коммерческий, недоступен на XPlore).
- ✅ Zowe CLI используется только для ручной диагностики/отладки.
- ✅ Host-программы — COBOL batch (без CICS).
- ✅ MQ CorrelationID = MsgId — обязательная стратегия:
  - COBOL: MOVE MQMD-MSGID TO MQMD-CORRELID / MOVE MQMI-NONE TO MQMD-MSGID.
  - Java: селектор по JMSCorrelationID = JMSMessageID запроса.
- ✅ Java использует Hexagonal Architecture + явный MQ Gateway (CicsMqGatewayTemplate).
- ✅ Domain-модель не зависит от инфраструктуры (без @Entity, без JAXB).
- ✅ JAXB используется для host contract layer (XML schema ↔ JAXB DTO).
- ✅ MapStruct используется для маппинга:
  - REST DTO ↔ Domain (LoanRestMapper).
  - Domain ↔ JAXB DTO (LoanHostMapper).
- ✅ Конфигурация MQ хранится в application.yml (spring + custom префиксы).
- ✅ Для MQ-слоя используются unit-тесты (JUnit + Mockito) с моками JmsTemplate / translator.
- ✅ DB2 используется как основное хранилище host-части (схема LIBRARY).

================================================================================
PROBLEMS IDENTIFIED
================================================================================

1. ibm.ibm_zos_wazi_deploy
   - Статус: ❌ недоступен.
   - Причина: коммерческий IBM продукт, недоступен в IBM Z XPlore.

2. Python Version на Host
   - Доступен только Python 3.9 (Cypress).
   - Ок для ZOAU + ibm_zos_core.
   - Невозможно обновить до более новой версии (ограничения среды).

3. Ansible Galaxy SSL на macOS
   - Изначально проблемы с SSL_CERT_FILE.
   - Решено через установку certifi и настройку REQUESTS_CA_BUNDLE.

4. IBM MQ Dev Environment локально
   - Требует отдельной настройки (IBM MQ / Artemis).
   - Не зафиксирован единый стандарт контейнера (зависит от выбора).

================================================================================
WORKAROUNDS
================================================================================

- Вместо Wazi Deploy:
  - Используем чистые модули ibm_zos_core (zos_copy, zos_job_submit).
- Для SSL в Ansible:
  - Используем certifi, настраиваем REQUESTS_CA_BUNDLE/SSL_CERT_FILE.
- Для связи Java ↔ host:
  - Для локальных тестов можно использовать MQ-брокер в docker (Artemis/IBM MQ),
    а на XPlore — реальный IBM MQ.
- Кодировка:
  - При копировании исходников и JCL на z/OS используем конвертацию ISO8859-1 → IBM-1047.
- JAXB/MapStruct:
  - Генерация кодов DTO/мапперов переносит рутину на build-этап, что уменьшает ручной код
    и снижает риск расхождений между моделями.

================================================================================
CONFIRMED WORKING
================================================================================

- ✅ SSH-доступ к z/OS.
- ✅ Python 3.9 + импорт ZOAU (python3 -c "import zoautil_py; print('ZOAU OK')").
- ✅ Zowe CLI.
- ✅ Ansible core.
- ✅ Коллекция ibm.ibm_zos_core установлена и работает.
- ✅ MQ correlation pattern реализован на COBOL-стороне (LIBMQTST.cbl).
- ✅ DB2-скрипты (schema + testdata) подготовлены для запуска через JCL/DSNTEP2.

================================================================================
NOT WORKING (BY DESIGN)
================================================================================

- ❌ Wazi Deploy.
- ❌ Коллекция ibm.ibm_zos_wazi_deploy.
- ❌ Обновление Python на XPlore host (фиксированная версия 3.9).
- ❌ Использование JPA/@Entity в доменной модели (domain остаётся чистым, без инфраструктурных аннотаций).

================================================================================
END OF PROJECT CONTEXT
================================================================================
