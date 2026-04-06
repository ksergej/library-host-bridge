# runbook_cics_config.md
## Автоматизация конфигурации COBOL программ для CICS-транзакций через “скрипты”
Цель: описать практичные способы **создавать/обновлять ресурсы CICS пакетно** (Infrastructure-as-Code для CICS) и встроить это в CI/CD.

Ниже 3 основных подхода (часто используются вместе):
1) **RDO через CEDA/DFHCSDUP (CSD)** — классика, работает почти везде.
2) **CICSPlex SM / BAS** — централизованное управление, bundles/политики.
3) **CMCI** — внешняя автоматизация по HTTP/REST (удобно для CI/CD).

---

## 3) Конфигурация через CICS ресурсы (автодеплой скриптами)

### A) CEDA / DFHCSDUP (batch) / RDO (Resource Definition Online)

#### A1) Интерактивно: CEDA DEFINE/ALTER/INSTALL (для ручной отладки)
Используется для “проверить руками”, а затем перенести команды в batch (DFHCSDUP).

Пример (идея):
- `CEDA DEFINE PROGRAM(LIBMQCIC) GROUP(LIBGRP) LANGUAGE(COBOL) ...`
- `CEDA DEFINE TRANSACTION(LMQC) PROGRAM(LIBMQCIC) ...`
- `CEDA INSTALL GROUP(LIBGRP)`

Плюсы: быстро для теста. Минус: плохо для повторяемого CI/CD.

---

#### A2) Пакетно: DFHCSDUP (CSD utility) — “скриптовая” IaC для CICS
**DFHCSDUP** позволяет выполнять **DEFINE / ALTER / DELETE / LIST** над ресурсами в **DFHCSD** (CSD), а затем **INSTALL** в регион (через GRPLIST или отдельные инсталляции).

**Какие ресурсы обычно автоматизируют:**
- `PROGRAM`, `TRANSACTION`
- `FILE`, `TDQUEUE`, `TSQUEUE`
- `DB2CONN`, `DB2ENTRY`, `DB2TRAN`
- `MQCONN` / `MQMONITOR` (если у вас MQ в CICS)
- `URIMAP`, `TCPIPSERVICE`, `WEBSERVICE`, `PIPELINE`, `JVMSERVER` (если web/services)
- и т.д.

##### Пример: DFHCSDUP “командный файл” (SYSIN)
Ниже пример для **PROGRAM+TRANSACTION**, типовой для COBOL+CICS.

```text
* === Обновление группы ресурсов ===
DEFINE GROUP(LIBGRP) DESCRIPTION('Library demo resources')  /* если группы нет */

* === PROGRAM ===
DEFINE PROGRAM(LIBMQCIC) GROUP(LIBGRP) DESCRIPTION('MQ+DB2 CICS program')
  LANGUAGE(COBOL)
  CEDF(YES)
  EXECKEY(CICS)              /* или USER */
  RESIDENT(NO)
  DATALOCATION(ANY)
  THREADSAFE(NO)             /* если есть threadsafe-ready - YES */
  RELOAD(NO)
  USAGE(NORMAL)

* === TRANSACTION ===
DEFINE TRANSACTION(LMQC) GROUP(LIBGRP) DESCRIPTION('Library MQ transaction')
  PROGRAM(LIBMQCIC)
  PRIORITY(1)
  TASKDATALOC(ANY)
  TWASIZE(0)
  PROFILE(DFHCICSA)          /* зависит от site policy */
  SPURGE(YES)
  SHUTDOWN(DISABLED)
  STATUS(ENABLED)

LIST PROGRAM(LIBMQCIC) GROUP(LIBGRP)
LIST TRANSACTION(LMQC) GROUP(LIBGRP)
```

##### Пример: JCL для запуска DFHCSDUP
Внимание: имена датасетов (SDFHLOAD, DFHCSD и т.д.) зависят от установки.
Это “скелет”, который вы адаптируете под сайт.

```jcl
//DFHCSDUP JOB (ACCT),'CICS CSD UPDATE',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//*
//STEP1    EXEC PGM=DFHCSDUP,REGION=0M
//STEPLIB  DD  DISP=SHR,DSN=your.cics.SDFHLOAD
//DFHCSD   DD  DISP=SHR,DSN=your.cics.DFHCSD
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  /* сюда вставляете команды DEFINE/ALTER/DELETE/LIST */
  /* пример из предыдущего блока */
/*
```

##### Практика “промоушна”
Обычно делают так:
1) В DEV обновили CSD (DFHCSDUP).
2) Включили группу в **GRPLIST** региона или сделали install.
3) Промоушн в TEST/PROD — либо переносом CSD (site policy), либо повторным DFHCSDUP на целевом окружении (предпочтительно, если разрешено).

##### Rollback (откат)
- Самый простой: `DELETE PROGRAM(...) GROUP(...)` / `DELETE TRANSACTION(...) GROUP(...)` + reinstall.
- Более аккуратный: хранить “предыдущую версию” SYSIN в SCM (git) и уметь прогнать “reverse” пакет.

---

#### A3) RDO без CSD (альтернативы зависят от сайта)
Некоторые сайты используют другие механизмы хранения/промоушна (например, стандарты через библиотеку definitional членов). По сути, **DFHCSDUP остаётся главным batch-инструментом** для RDO.

---

### B) CICSPlex SM / BAS (Business Application Services)
Если у вас есть **CICSPlex SM (CPSM)**, то вы можете централизованно управлять ресурсами:
- через **BAS** (Bundles, Definition, Deployment)
- через политики и стандартные “deployment bundles”
- часто есть интеграция с Change Management и автоматизацией промоушна.

**Идея:** вы описываете “комплект приложения” (что ставить, куда, на какие регионы/плексы), и дальше это деплоится как единый объект.

**Скриптизация:**
- Обычно это автоматизируется через процедуры/инструменты CPSM (в зависимости от вашей установки), включая запуск из pipeline.
- Важно: BAS хорош, когда много регионов и нужен централизованный контроль.

**Когда выбирать BAS:**
- много регионов, нужна консистентность и governance;
- деплой “bundle” как единицы, не отдельных DEFINE.

---

### C) CMCI / scripts (REST/HTTP automation)
**CMCI (CICS Management Client Interface)** — это HTTP интерфейс (обычно REST-like), который позволяет управлять CICS ресурсами извне.

Это идеальный мост в CI/CD:
- pipeline вызывает скрипт,
- скрипт делает HTTP calls к CMCI,
- создаёт/меняет/устанавливает ресурсы,
- читает статусы, собирает инвентарь.

#### C1) Что обычно делают через CMCI
- Create/Update/Install ресурсов (в зависимости от прав и режима)
- Query состояния (например, что установлено, enabled/disabled, ошибки)
- Автоматические проверки (smoke checks): “program installed?”, “tran enabled?”, “tcpipservice open?”

#### C2) Пример “скрипта” на curl (концептуально)
Точные URL/ресурсы зависят от вашей конфигурации CMCI и версий.

```bash
# 1) проверить доступность CMCI
curl -sS -u "$USER:$PASS" \
  "https://<cmci-host>:<port>/CICSSystemManagement/version"

# 2) получить список транзакций по маске (пример)
curl -sS -u "$USER:$PASS" \
  "https://<cmci-host>:<port>/CICSSystemManagement/cicsTransaction?CRITERIA=(name=LMQC)"
```

На практике обычно делают обёртку (Python/shell), плюс:
- retries/backoff,
- логирование ответов,
- “idempotent” поведение (если ресурс уже есть — ALTER вместо DEFINE),
- формирование отчёта для pipeline.

---

## Рекомендованный “минимальный” CI/CD pattern (если нет CPSM)
1) **Git хранит**:
   - DFHCSDUP SYSIN (ресурсные определения),
   - связанный JCL (или шаблон JCL),
   - версионирование по релизам.
2) Pipeline шаги:
   - Compile/Link/BIND (если есть DB2) для программ.
   - Deploy load module в нужный dataset (DFHRPL concat).
   - DFHCSDUP APPLY (DEFINE/ALTER/LIST) на целевом окружении.
   - INSTALL/Enable (через GRPLIST+restart или install operations).
   - Smoke checks (через CMCI или через CICS commands / logs).

---

## Частые грабли и проверки
- **CICS translator / SDFHLOAD**: если COBOL компилируется с `CICS`, но не грузится integrated translator — будут отброшены `EXEC CICS` (как в вашем листинге). Это лечится корректной компоновкой STEPLIB/SDFHLOAD или правильной процедурой компиляции (обычно DFH* procs).
- **MQ COPYBOOKs**: `MQOD-DEFAULT`, `MQMD-DEFAULT` и т.п. определяются copybook’ами (CMQV/CMQODV/CMQMDV/CMQGMOV/CMQPMOV). Если компилятор их “не видит” — проверьте SYSLIB concatenation.
- **Idempotency**: DFHCSDUP скрипты лучше писать так, чтобы повторный прогон не ломал окружение (например, `ALTER` вместо `DEFINE`, или `DEFINE` в “если нет” — зависит от политики).
- **Security**: CMCI требует корректных прав, TLS/сертификатов, иногда RACF permits.

---

## Шаблоны (что держать рядом в репозитории)
- `cics/dfhcsdup/libgrp.sysin` — определения PROGRAM/TRANSACTION/URIMAP и т.д.
- `cics/dfhcsdup/run_dfhcsdup.jcl` — запуск DFHCSDUP
- `cics/cmci/` — скрипты smoke-check / inventory
- `docs/runbook_cics_config.md` — этот файл

---

## Быстрый чек-лист для PROGRAM+TRANSACTION деплоя
- [ ] Load module в DFHRPL доступен региону
- [ ] PROGRAM определён и installed/enabled
- [ ] TRANSACTION определён и enabled
- [ ] Если есть DB2: DB2ENTRY/DB2TRAN/DB2CONN корректны
- [ ] Если есть MQ: MQCONN (и monitor, если нужен) корректны
- [ ] Smoke test (минимум): выполнить транзакцию / вызвать entrypoint / проверить CMCI status
