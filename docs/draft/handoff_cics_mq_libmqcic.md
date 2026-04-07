# Handoff: CICS / COBOL / MQ (LIBMQCIC + транзакция LIBT)

Дата: 2026-04-06 (Europe/Berlin)  
Скоуп: персональный CICS-регион (APPLID=CXZ88011, SYSID=S750) + COBOL/DB2/MQ тестовая программа `LIBMQCIC`, транзакция `LIBT`, ресурсы в CSD-группе `Z88011`.

---

## 1) Цели (что хотим получить)

1. **Стабильный запуск персонального CICS-региона** из JCL (PROC `CICS4ZXP`) с предсказуемыми ресурсами.
2. **Транзакция `LIBT` всегда доступна после рестарта региона**, без ручного `CEDA INSTALL` каждый раз.
3. **Компиляция/линковка/рантайм программы `LIBMQCIC` без ошибок**, включая:
   - корректную CICS-трансляцию `EXEC CICS ...`
   - корректные MQ-copybooks (CMQV/CMQODV/CMQMDV/CMQGMOV/CMQPMOV)
   - корректные DB2 SQL include/declare/prepare
4. **Понятная “инфраструктура как код” для CICS ресурсов** (CEDA/DFHCSDUP/CMCI/и т.д.) и runbook для автодеплоя.

---

## 2) Текущий статус (что уже есть)

### 2.1 Ресурсы в CICS
- COBOL-программа: `LIBMQCIC`.
- Транзакция: `LIBT`, связка подтверждена:
  - `CEMT I TRANS(LIBT)` → `Pro(LIBMQCIC)` (Enabled)
  - `CEMT I PROG(LIBMQCIC)` → программа установлена/доступна
- Ресурсы определялись в **CSD-группе `Z88011`** и затем устанавливались:
  - `CEDA INSTALL GROUP(Z88011)` → после этого `LIBT` снова становится доступна.

### 2.2 Поведение при рестарте/остановке
- После остановки CICS-региона **транзакция может стать недоступной** (не installed/не enabled в рантайме).
- После `CEDA INSTALL GROUP(Z88011)` — снова доступна.
- Вывод: **определение в CSD сохраняется**, но **установка (INSTALL) ресурсов в рантайм при старте не гарантирована** текущей конфигурацией старта.

### 2.3 Ошибки/диагностика, которые уже были
- В JES2 joblog встречалось:
  - `PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND.` (на шаге TRANSL)
  - `ABEND=S722` после `ESTIMATED LINES EXCEEDED` (часто = spool/output/line limit; нужно подтверждать по политике JES)
- По COBOL compile listing:
  - `IGYOS0230-S ... CICS integrated translator ... unable to load ... All "EXEC CICS" statements were discarded.`
  - Ошибки по MQ default-структурам:
    - `MQOD-DEFAULT / MQMD-DEFAULT / MQGMO-DEFAULT / MQPMO-DEFAULT was not defined as a data-name`
  - (Похоже на опечатку в коде/листинге): `WS-REQ-QUEGGUE` вместо `WS-REQ-QUEUE`
- В рантайме транзакции:
  - `DFHAC2206 ... Transaction LIBT failed with abend APCW. Updates ... backed out.`

---

## 3) Принятые решения / наблюдения

### 3.1 Про “пропадание” транзакций после остановки CICS
- **CEDA DEFINE/ALTER** записывает определения в **CSD (DFHCSD dataset)** — это *персистентно*.
- **CEDA INSTALL** делает *рантайм-инсталляцию* ресурсов в активный регион — это *не персистентно*.
- Поэтому после рестарта нужно либо:
  1) автоматизировать **INSTALL GROUP(...)** при старте, либо  
  2) настроить **GRPLIST/PLT** так, чтобы группа устанавливалась автоматически.

### 3.2 По MQOD-DEFAULT и подобным
- В приведённом copybook `CMQODV` (и в доке IBM MQ 9.2) **нет `MQOD-DEFAULT`**.
- Практика в COBOL для MQ:
  - либо есть отдельный copybook/константы с “defaults/инициализаторами” (в некоторых инсталляциях),
  - либо делать инициализацию вручную (StrucId/Version/Options и т.п.).
- Следствие: **заменить `MOVE MQOD-DEFAULT` на корректную инициализацию**, или подключить правильный copybook/константы, если они реально поставлены в вашей MQ COBOL libs.

### 3.3 По CICS integrated translator
- Ошибка `unable to load the CICS integrated translator services module` означает:
  - либо не найден модуль сервисов интегр. транслятора (STEPLIB/системные библиотеки),
  - либо неверная compile procedure.
- У вас при этом есть отдельный успешный листинг **CICS Command Language Translator** (“NO MESSAGES PRODUCED”), т.е. **как отдельный шаг трансляция CICS-команд работает**, но **как integrated translator при компиляции — нет**.

---

## 4) Открытые задачи (что делать дальше)

### A) Авто-установка CSD группы при старте региона (чтобы LIBT не “пропадала”)
Варианты (выбрать один):

1. **SIT параметр GRPLIST=...**  
   - Добавить группу `Z88011` в GRPLIST (или в список групп), чтобы регион сам устанавливал её на старте.
2. **PLTPI/PLTSD (Program List Table)**  
   - Запуск действия на старте, чтобы выполнить install нужной группы.
3. **Batch DFHCSDUP / автосценарий до DFHSIP**  
   - В PROC до шага `//CICS EXEC PGM=DFHSIP` добавить batch шаг, который гарантирует наличие/актуальность определений и затем выполняет установку.

**Пользовательский вопрос:** “я могу запуск группы добавить в джоб запуска CICS?”  
Смысловой ответ: **да**, но лучше через стандартный механизм старта (GRPLIST/PLT) или через batch шаг до DFHSIP — чтобы было повторяемо.

---

### B) Починить `MQOD-DEFAULT` / `MQMD-DEFAULT` / `MQGMO-DEFAULT` / `MQPMO-DEFAULT`
1. Проверить, есть ли отдельные “defaults” copybooks в вашей инсталляции MQ COBOL (поиск по `SCSQCOB*` / `SCSQC*` и т.п.).
2. Если **нет**:
   - заменить на ручную инициализацию:
     - заполнить StrucId/Version/Options,
     - затем обязательные поля (ObjectName, MsgType, Encoding, CCSID, GMO/PMO options).
3. Исправить опечатку `WS-REQ-QUEGGUE` → `WS-REQ-QUEUE`.

---

### C) Зафиксировать сборочную цепочку для CICS
1. Выбрать схему:
   - **CICS translator step → COBOL compile (без CICS option) → linkedit**, или
   - **COBOL compile с CICS option через integrated translator** (тогда обеспечить правильные библиотеки/модули).
2. Разобраться с `DFHAPIR NOT FOUND` (parmlib/member для translator step).

---

### D) Разобрать `ABEND=APCW` в транзакции `LIBT`
- Нужна диагностика из CICS:
  - CSMT / MSGUSR / DFH messages,
  - dump/trace (если включено),
  - что именно выполнялось в `LIBMQCIC` при падении (MQCONN/MQOPEN/MQGET/DB2/и т.д.).
- Проверить runtime libs:
  - MQ runtime libs (CSQ*) в STEPLIB/DFHRPL,
  - DB2 libs,
  - LE libs,
  - security/RACF.

---

## 5) Термины / сокращения

- **CICS** — Customer Information Control System.
- **CSD / DFHCSD** — CICS System Definition dataset (персистентные определения ресурсов).
- **RDO** — Resource Definition Online (CEDA/DFHCSDUP).
- **CEDA** — интерактивное DEFINE/ALTER/INSTALL ресурсов.
- **DFHCSDUP** — batch utility для работы с CSD (скриптовая автоматизация).
- **INSTALL GROUP** — установка определений из CSD в рантайм активного региона.
- **SIT** — System Initialization Table (параметры старта).
- **GRPLIST** — список групп ресурсов для автозагрузки на старте региона.
- **PLT** — Program List Table (действия на старте/остановке).
- **CMCI** — CICS Management Client Interface (HTTP/REST automation).
- **CPSM** — CICSPlex SM.
- **MQ** — IBM MQ.
- **MQOD/MQMD/MQGMO/MQPMO** — MQI структуры.
- **DB2 / SQLCA / DSNHDECP** — DB2 и настройки SQL coprocessor.
- **APCW** — CICS abend code (требует расшифровки по CICS logs/dump).
- **S722** — system abend (часто лимиты spool/output, но подтверждать по JES policy).

---

## 6) Мини-план “первое в следующем чате”

1) Встроить автозагрузку группы `Z88011` при старте (GRPLIST/PLT/DFHCSDUP-step).  
2) Починить `LIBMQCIC` по MQ defaults + CICS translator chain.  
3) Снять причину `APCW` (CSMT/MSGUSR/trace/dump) и закрыть рантайм проблему.

