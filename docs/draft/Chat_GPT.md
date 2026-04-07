  

Новые пути развития проекта. Расскажи мне как я могу проверить мои права по работе с CICS?

  

Nachgedacht für 39s

Проверка “моих прав на работу с CICS” на z/OS обычно сводится к трём вещам:

1. **Есть ли вообще доступная CICS-регион/APPLID в системе**
    
2. **Могу ли я в неё залогиниться (CESN) и выполнять хотя бы read-only транзакции**
    
3. **Есть ли у меня расширенные права (CEMT/CECI/CEDA/ресурсы RACF)**
    

Ниже — практичный чек-лист (через 3270/TSO/ISPF), без админских предположений.

---

## 1) Убедиться, что CICS в системе реально “есть” и запущен

### Вариант A: через SDSF (самый быстрый)

1. Зайди в **SDSF** (часто команда `SDSF` из TSO/ISPF Command line).
    
2. Открой **ST** (Started Tasks).
    
3. Отфильтруй по имени `CICS`, `DFHSIP`, `CICSTS`, `AOR`, `TOR` и т.п.
    

**Что это даёт:**

- Если ты **видишь** стартед-таски CICS → CICS запущен, и ты как минимум имеешь права видеть ST.
    
- Если SDSF не пускает (ISF… errors) → у тебя может не быть прав на SDSF, тогда переходи к варианту B.
    

### Вариант B: косвенно (если SDSF недоступен)

Попроси у мейнфрейм-админа/инструктора **APPLID CICS региона** (например `CICS1A`, `CICSA`, `CICSDEV1`) — без APPLID дальше не проверить вход.

---

## 2) Проверить право “войти в регион” (VTAM/APPLID + CICS signon)

### Шаг 1: попробовать LOGON к APPLID

На “пустом” 3270-экране (или через VTAM-меню) выполняют вход вида:

- `LOGON APPLID(CICSxxxx)`  
    или иногда просто вводят `CICSxxxx` (зависит от терминального софта/настроек).
    

Если **APPLID не существует/недоступен** — будет ошибка VTAM/логон-фейл (это уже сигнал).

### Шаг 2: CICS signon (CESN)

Если попал в CICS-экран — введи:

- `CESN`
    

Дальше, если включена безопасность, CICS запросит user/password (иногда автологин).

**Интерпретация результата:**

- ✅ **Успешный signon** → у тебя есть базовый доступ к региону.
    
- ❌ Сообщения вида “not authorized / security violation” (часто DFH… security) → доступ к региону есть/виден, но **логиниться нельзя** (нужны права на region/APPLID/terminal).
    

---

## 3) Проверить, что именно тебе разрешено внутри CICS (самое полезное)

После успешного CESN проверь транзакции “по возрастанию опасности” (сначала read-only):

### A) Read-only диагностика (обычно разрешают чаще всего)

- `CEMT I SYS` (или `CEMT INQUIRE SYSTEM`)
    
- `CEMT I TASK` (просмотр задач)
    
- `CEMT I PROGRAM(xxx)` (если знаешь имя)
    

✅ Если проходит — у тебя есть хотя бы “operator/inquiry” уровень.

### B) Dev/utility транзакции (часто ограничены)

- `CECI` (Command-level interpreter, мощный)
    
- `CEDA` (definitions, ещё мощнее)
    
- `CEDF` (debug facility)
    

❌ Если на них “not authorized” — это нормально для shared сред, просто значит **нет прав дев/админа**, даже если базовый доступ есть.

### C) Проверка “могу ли я реально запускать свои штуки”

Самый честный тест: есть ли у тебя право на **конкретную транзакцию**, которую ты хочешь сделать для проекта (например кастомная транзакция, которая дергает программу/канал/MQ).  
Если транзакции ещё нет — её надо будет определить (а это уже CEDA/ресурсная безопасность).

---

## 4) Если есть доступ к RACF-командам: проверить права “в лоб” (опционально)

Если у тебя разрешены команды RACF в TSO, можно проверить:

- что твой userid вообще в RACF,
    
- какие классы/профили тебя режут.
    

Команды зависят от того, что разрешено в системе, но типично это что-то вроде `LU <userid>` и `RLIST ...` по профилям.

Важно: в CICS безопасность может быть на разных ресурсах (регион/APPLID, транзакции, программы, файлы/TDQ/TSQ, и т.д.), поэтому “войти” ≠ “разрешено CEDA/CECI”.

---

## 5) Как это связать с “новыми путями развития” проекта

Сейчас у нас зафиксировано, что host-часть у тебя **COBOL batch без CICS** .  
Чтобы “завернуть” обработку в CICS, тебе фактически нужны **две независимые вещи**:

1. **Техническая доступность CICS-региона** (ты можешь в него войти)
    
2. **Права** хотя бы на:
    
    - запуск нужной транзакции,
        
    - и/или определение ресурсов (если надо заводить новые PROGRAM/TRANSACTION/FILE/MQCONN), что часто требует CEDA и соответствующих security-разрешений.
        

---

## Мини-шпаргалка “что сказать администратору”, если прав нет

Если где-то упёрся, самый короткий запрос админам обычно такой:

- “Дайте APPLID dev CICS региона + доступ на CESN”
    
- “Разрешите транзакции: CEMT (inquire), и (если нужно) CECI/CEDA”
    
- “Если будем добавлять новую транзакцию/программу: нужны права на resource definitions и на конкретные транзакции/программы”
    

---

Если хочешь, напиши, **что именно у тебя есть из доступов** (SDSF есть/нет, APPLID знаешь/нет, CESN пускает/нет) и **какая ошибка/сообщение** появляется — я по симптомам скажу, на каком уровне тебя режет (VTAM/APPLID, signon, transaction security, resource security).

  

sd st - вижу только свои джобы

  

Nachgedacht für 1m 19s

Ок — если в **SDSF / ST** ты видишь **только свои job’ы**, это обычно означает одно из двух:

1. у тебя просто стоят фильтры **OWNER/PREFIX** (и их можно снять), **или**
    
2. SDSF **ограничен по безопасности** и тебе физически не дают видеть чужие JOB/STC (started tasks), даже если ты пытаешься показать “всё”.
    

Ниже — как быстро отличить (1) от (2) и что делать дальше, чтобы всё равно проверить доступ к CICS.

---

## 1) Проверка: это фильтр или реально права?

На панели **ST** в командной строке введи:

- `SET DISPLAY ?` (покажет текущие настройки OWNER/PREFIX/DEST и т.д.)
    

Потом попробуй явно “показать всё”:

- `OWNER *`
    
- `PREFIX *`
    

Команда `PREFIX` влияет на ST/DA и другие панели, то есть должна расширять выборку.   
Команда `OWNER`/`PREFIX` может быть защищена SAF/RACF (SDSF class ресурсы вроде `ISFCMD.FILTER.OWNER` / `ISFCMD.FILTER.PREFIX`). 

### Как понять результат

- Если после `OWNER *` / `PREFIX *` **вдруг появляется куча чужих задач/джобов** → это был просто фильтр.
    
- Если:
    
    - команды **ругаются “NOT AUTHORIZED”**, или
        
    - команды принимаются, но **всё равно видишь только своё**  
        → это почти наверняка **ограничение прав SDSF** (тебе разрешено смотреть только “свои” объекты).
        

---

## 2) Что это значит для “проверить права на CICS”

Если SDSF режет обзор, то через ST ты **не сможешь надежно доказать**, что CICS-регион запущен/существует.

Тогда самый прямой путь проверить доступ к CICS — **через VTAM LOGON на APPLID региона**:

1. Нужно знать **APPLID** (имя региона в сети, 1–8 символов). 
    
2. Делаешь `LOGON APPLID(XXXX)` → попадаешь/не попадаешь
    
3. Внутри пробуешь `CESN` (signon) и дальше read-only транзакции типа `CEMT I SYS`.
    

Если админы ограничивают доступ к региону, это обычно делается через RACF **APPL class** на профили APPLID CICS. 

---

## 3) Как добыть APPLID, если SDSF не показывает started tasks

Самый практичный вариант: **попросить у админа/инструктора** “APPLID dev/test CICS региона”.

Если хочешь попробовать сам (без админов), есть шанс найти по процедурам старта:

- В **ISPF 3.4** попробовать посмотреть `SYS1.PROCLIB` / site-proclib и поискать члены/строки с `DFHSIP`или `APPLID=` (иногда APPLID видно в SYSIN/параметрах).  
    Но это зависит от того, есть ли у тебя read-доступ к PROCLIB.
    

---

## 4) Быстрый вывод по твоему симптому

То, что ты “видишь только свои джобы” — очень похоже на **SDSF security restriction** (типичный учебный/песочничный сетап), а не на проблему CICS.

---

Если ты напишешь, что именно происходит при вводе `OWNER *` и `PREFIX *` (принялось? какая реакция/сообщение?), я скажу точно: **это фильтр** или **нехватка прав**, и какой самый короткий путь дальше (через APPLID/3270 или через ISPF).

  

как в sd st фильтровать имена типа CICS..., CICSP..., DFH..., TOR..., AOR...

  

Nachgedacht für 19s

В **SDSF / ST** для отбора по имени задачи (JOBNAME/STCNAME) используется именно команда **`PREFIX`**: она ограничивает список по маске имени и действует на панели **ST**. 

### Как фильтровать по “CICS… / DFH… / TOR… / AOR…”

1. Зайди в **SDSF → ST**
    
2. В строке `COMMAND INPUT ===>` введи одну из масок и нажми Enter:
    

PREFIX CICS*  
PREFIX CICSP*  
PREFIX DFH*  
PREFIX TOR*  
PREFIX AOR*

3. Сброс фильтра (показать всё, что тебе разрешено видеть):
    

PREFIX *

### Посмотреть, какой фильтр сейчас активен

SET DISPLAY ?

### Подсказка по синтаксису прямо из SDSF

HELP PREFIX

(В SDSF можно вызывать help по командам с командной строки.) 

---

Важно: `PREFIX` — это **одна маска за раз** (то есть “CICS* OR DFH*” одним вводом обычно не делают). Если у тебя из-за прав в ST сейчас показываются только твои jobs, то `PREFIX CICS*` просто вернёт пусто — это нормально.

Если хочешь, напиши, что показывает `SET DISPLAY ?` (особенно `PREFIX=` и `OWNER=`) — скажу, ограничение это фильтрами или уже SDSF-security.

  

SDSF STATUS DISPLAY ALL CLASSES LINE 1-2 (2) PREFIX=CICS* DEST=(ALL) OWNER=* SYSNAME= NP JOBNAME JobID Owner Prty Queue C Pos SAff ASys Sta CICSTS62 STC01258 STCOPER 15 EXECUTION S0W1 S0W1 CICSCOMP JOB03614 Z49597 1 PRINT 7 138

  

Отлично — по твоему `STATUS DISPLAY` видно, что фильтр **работает** и ты **видишь STC**:

- `CICSTS62 STC01258 ... EXECUTION` → это **started task**, т.е. CICS-регион (или компонент CICS) **реально запущен**.
    
- `CICSCOMP JOB03614 ... PRINT` → обычный batch job в очереди PRINT (к CICS-региону напрямую может не относиться).
    

Теперь главный вопрос: **как узнать APPLID (VTAM имя), чтобы проверить “права на вход в CICS” через 3270?**  
Имя started task (`CICSTS62`) _часто_ похоже на APPLID, но **не гарантированно равно ему**.

## 1) Узнать APPLID прямо из SDSF (через output STC)

1. В **SDSF → ST** поставь `S` слева от `CICSTS62` и нажми Enter.  
    Ты попадёшь в просмотр выходных данных (панель со списком DD’шек типа `JESMSGLG`, `JESYSMSG`, `JESJCL` и т.п.).
    
2. Открой **`JESMSGLG`** (обычно тоже командой `S` или `B`/`?` — зависит от настроек SDSF, но цель: _Browse_ этого DD).
    
3. Внутри просмотра сделай поиск:
    
    - `F APPLID`
        
    - `F DFHSIT`
        
    - `F SIT`
        
    - `F NETNAME`
        
    - `F DFH` (если ничего не находится)
        

Часто в сообщениях старта CICS прямо печатается строка с **APPLID=XXXX** (или что-то очень близкое).

## 2) Если APPLID нашёлся — проверка прав в 3270

1. На “VTAM/логон” экране:
    
    - `LOGON APPLID(XXXX)` (где `XXXX` — найденный APPLID)
        
2. В CICS введи:
    
    - `CESN` (signon)
        
3. И минимально “безопасная” проверка внутри:
    
    - `CEMT I SYS`
        

**Интерпретация:**

- LOGON не пускает → проблема на уровне VTAM/APPL security.
    
- CESN не пускает → security на уровне CICS signon.
    
- CESN ок, но `CEMT/CECI/CEDA` запрещены → тебе дали “user” доступ, но не оператора/админа (это нормально).
    

## 3) Дополнительные фильтры в ST (чтобы найти другие регионы)

Ты уже сделал `PREFIX=CICS*`. Аналогично можешь прогнать по очереди:

- `PREFIX DFH*`
    
- `PREFIX CICSP*`
    
- `PREFIX TOR*`
    
- `PREFIX AOR*`
    

(одна маска за раз)

---

Если хочешь — пришли 5–10 строк из `JESMSGLG` старта `CICSTS62`, где видно параметры/инициализацию (можно просто копипастой). Я по ним скажу, где там APPLID и какой у тебя следующий самый короткий шаг для проверки прав.

  

DFHPA1927 CICSTS62 APPLID=(CICSTS62,CICSTS62) APPLID FOR THIS CI

  

Супер — это ровно то, что нужно.

Сообщение

`DFHPA1927 CICSTS62 APPLID=(CICSTS62,CICSTS62)`

означает: **VTAM APPLID этого CICS-региона = `CICSTS62`** (у тебя даже primary/alternate одинаковые).

## Дальше: как проверить твои права в CICS (самый прямой тест)

### 1) Войти в регион по APPLID

На 3270 (в VTAM/логон-экране) выполни:

- `LOGON APPLID(CICSTS62)`
    

Если логон вообще не проходит — это признак, что тебя режут на уровне **VTAM/APPL security** (часто RACF class `APPL` на профиль `CICSTS62`).

### 2) Проверить signon

Внутри CICS введи:

- `CESN`
    

Дальше:

- если попросит user/pass — вводишь свои.
    
- если получишь “not authorized / security violation” — значит **в регион попал, но signon запрещён**(CICS security).
    

### 3) Проверить, что разрешено внутри (read-only → более мощное)

После успешного CESN попробуй по очереди:

- `CEMT I SYS` (самый базовый “inquire system”)
    
- `CEMT I TASK` (просмотр задач)
    

Если тебе нужно именно “dev-уровень”, попробуй (часто запрещено обычным юзерам — и это нормально):

- `CECI`
    
- `CEDA`
    

## Как интерпретировать результат

- **LOGON не пускает** → проблема прав на APPLID/терминал (уровень VTAM).
    
- **LOGON ок, CESN не пускает** → нет прав на CICS signon (уровень CICS security).
    
- **CESN ок, но CEMT/CECI/CEDA запрещены** → ты обычный пользователь, без operator/dev прав.
    

Если ты пришлёшь текст ошибки/сообщение (DFH… / “not authorized” и т.п.) на шаге, где упёрся, я скажу точно: _какой именно уровень безопасности тебя режет_ и что просить у админа (APPLID-доступ, CESN, права на конкретные транзакции типа CEMT/CECI/CEDA).

  

![Hochgeladenes Bild](https://chatgpt.com/backend-api/estuary/content?id=file_00000000f34471f4b8ec78574e958f8c&ts=493167&p=fs&cid=1&sig=a26319a8eb8515eebc70de66ff72e3a6b81378a92b5b38fdd71675b959918580&v=0)

как делать - тут? На 3270 (в VTAM/логон-экране) выполни:

  

Nachgedacht für 31s

На этом экране ты **ещё не в VTAM/CICS** — это стартовый “welcome”, который предлагает **войти в TSO**.

### Шаг 1 — зайти в TSO

Внизу слева, где мигает курсор, введи **одну из команд** и нажми **Enter**:

**Вариант A (обычно проще):**

TSO

Появится панель логина, введёшь userid/password.

**Вариант B (сразу логон):**

LOGON <твoй_userid>

Например:

LOGON Z49597

---

### Шаг 2 — перейти в “VTAM/Session Manager”, чтобы сделать LOGON APPLID(CICSTS62)

Команда `LOGON APPLID(...)` работает **не в TSO**, а в **VTAM (Session Manager)**. Поэтому после TSO логина сделай так:

1. Попади на `READY` или в ISPF.
    
2. Попробуй запустить session manager (что именно есть в системе — зависит от стенда), по очереди:
    

TPX

или

NET

или

VTAM

**Как понять, что ты попал куда надо:** появится экран/меню приложений (список APPLID’ов) или экран, где принимается `LOGON APPLID(...)`.

---

### Шаг 3 — логон в CICS

Уже в VTAM/Session Manager введи:

LOGON APPLID(CICSTS62)

(Иногда достаточно просто набрать `CICSTS62` и Enter — зависит от меню.)

---

### Если “LOGON APPLID” не работает

Если ты введёшь `LOGON APPLID(CICSTS62)` и получишь что-то типа **IKJ… COMMAND NOT FOUND** — значит ты всё ещё в **TSO**, а не в VTAM.

Скажи мне, что у тебя появляется **после `TSO` логина** (экран `READY`? сразу ISPF меню?), и что происходит на командах `TPX`/`NET`/`VTAM` — я подскажу точный путь именно для твоего стенда.

  

как выйти из ISPF -> TSO

  

Чтобы выйти из **ISPF** обратно в **чистый TSO (READY)**:

### Вариант 1 (самый правильный)

На любой панели ISPF в командной строке введи:

X

или

= X

и нажми **Enter**.

Обычно появится подтверждение “Exit ISPF?”. Введи:

Y

### Вариант 2 (через меню выхода)

- `=X` — перейти сразу на панель выхода
    
- `=X` → затем выбрать “Exit” / подтвердить
    

### Вариант 3 (быстрый “назад-назад”)

Если ты глубоко внутри панелей:

- `END` (F3) несколько раз, пока не выйдешь
    
- затем `X` для выхода из самого ISPF
    

После успешного выхода ты увидишь примерно:

READY

Если скажешь, **какой у тебя эмулятор** (x3270 / tn3270 / Vista/Quick3270 / WC3270 / Zowe z/OSMF web terminal) и что именно появляется при `X`, я подскажу точную комбинацию клавиш (Enter/F3/F12 и т.д.).

  

![Hochgeladenes Bild](https://chatgpt.com/backend-api/estuary/content?id=file_00000000954071f4a6f65a203d8b397c&ts=493167&p=fs&cid=1&sig=2684f64909b22db6c5d864f5ec5a4ef349bd503648e8da5b8cef575f4612299d&v=0)

  

Ты уже **на экране завершения ISPF** (“Specify Disposition of Log Data Set”). Отсюда выйти в TSO очень просто:

### Чтобы **выйти из ISPF и попасть в TSO (READY)**

1. В поле **`Process Option`** введи **`2`** (самый безопасный/обычный вариант):
    

- `2 = Delete data set without printing` (удалить лог, не печатая)
    

2. Нажми **Enter**.
    

После этого ISPF завершится, и ты должен увидеть **`READY`** (это и есть чистый TSO).

---

### Если ты **не хочешь выходить**, а хочешь вернуться в меню ISPF

В командной строке введи:

- `END` (или нажми **PF3/F3**) — вернёт в **Primary Option Menu**.
    

---

Если после `2` + Enter не появляется `READY`, а перекидывает куда-то ещё — напиши, что именно видишь (1–2 строки сверху экрана), и я скажу следующий шаг.

  

если я ввожу x - то сразу получаю logoff LOGOFF IKJ56470I Z88011 LOGGED OFF TSO AT 06:01:20 ON DECEMBER 29, 2025 ******

  

Да, это нормальное поведение **в твоей конфигурации**: команда `X` у тебя настроена как **выход из ISPF + немедленный LOGOFF из TSO** (часто так делают на учебных стендах/в некоторых профайлах).

Чтобы выйти **только из ISPF**, но **остаться в TSO (READY)**, делай так:

## Правильный выход из ISPF → в TSO (без LOGOFF)

### Вариант 1 (лучший): `RETURN`

На любой панели ISPF в командной строке введи:

RETURN

(или коротко `R`) и Enter.

Это должно вернуть тебя в **TSO READY**.

### Вариант 2: `=X` (через панель завершения) + выбрать опцию

Если `RETURN` недоступен, то выходи через “termination panel”:

1. `=X` → попадёшь на экран типа “Specify Disposition of Log Data Set”
    
2. там выбери опцию (обычно `2`) и Enter  
    После этого должен быть **READY**, _без_ LOGOFF.
    

> У тебя `X` = “exit & logoff”, а `=X` = “exit ISPF (controlled)”.

### Вариант 3: через команду TSO внутри ISPF

В ISPF можно выполнить TSO-команду:

TSO ISPF END

или

TSO =X

(в зависимости от того, что разрешено).

---

## Как не “вылетать” случайно

- Не вводи просто `X`, если хочешь остаться залогиненным.
    
- Используй `RETURN` или `=X`.
    

---

Если твоя цель — попасть в VTAM/Session Manager (чтобы сделать `LOGON APPLID(CICSTS62)`), то после **`RETURN` → READY** попробуй по очереди:

TPX  
NET  
VTAM

и скажи, какая из команд срабатывает/какую ошибку даёт — я подскажу следующий шаг.

  

Menu List Mode Functions Utilities Help --------------------------------------------------------- ISPF Command Shell Enter TSO commands below: ===> VTAM Place cursor on choice and press enter to Retrieve comman => NET => TPX => st => da => => => => => => IKJ56500I COMMAND VTAM NOT FOUND ***

  

Ок, это уже очень показательно.

Ты в **ISPF Command Shell**, и строка:

`IKJ56500I COMMAND VTAM NOT FOUND`

значит: **в твоём TSO environment нет команды “VTAM” как TSO-команды** (это нормально). Вход в VTAM/CICS делается **через Session Manager** (обычно **NET** или **TPX**), а не через “VTAM”.

## Что делать прямо на этом экране

### 1) Запусти Session Manager

В командной строке `===>` введи по очереди (по одному) и Enter:

NET

Если не сработает — тогда:

TPX

(“VTAM” игнорируем — у тебя его нет.)

### 2) Если NET/TPX откроется

Ты попадёшь в экран/меню с приложениями. Там уже делай:

- либо ввод `CICSTS62` (если меню принимает APPLID напрямую),
    
- либо команду:
    

LOGON APPLID(CICSTS62)

### 3) Если NET/TPX тоже “NOT FOUND”

Тогда это значит, что у тебя **нет доступа/нет выделенной точки входа в VTAM** из твоего logon-процесса (или команда называется иначе).

В этом случае самый надёжный путь:

- входить в CICS **не через TSO**, а **через отдельную 3270-сессию** на **VTAM (IBM Session Manager)** — но на твоём стенде чаще всего это всё равно `NET`/`TPX`.
    

---

## Маленький лайфхак: запускай их как TSO-команды

Иногда в ISPF Command Shell нужно явно:

TSO NET

или

TSO TPX

Попробуй **сначала `TSO NET`**.

---

## Что мне нужно от тебя (без лишних кругов)

Введи **`NET`** (или `TSO NET`) и пришли, что появится:

- откроется меню?
    
- или опять `IKJ56500I COMMAND NET NOT FOUND`?
    
- или security/permission message?
    

По этому одному сообщению я точно скажу следующий шаг до `LOGON APPLID(CICSTS62)`.

  

Enter TSO commands below: ===> net Place cursor on choice and press enter to => VTAM => NET => TPX => st => da => => => => => IKJ56500I COMMAND NET NOT FOUND ***

  

Ок — теперь ясно: у тебя в TSO **нет команд NET/TPX** (или они не в твоей CLIST/REXX logon proc), поэтому из TSO ты **не можешь попасть в VTAM Session Manager** стандартным способом.

Это не означает, что CICS недоступен — просто точка входа “в сети” у тебя другая.

## Что делать дальше (3 рабочих варианта)

### Вариант A — самый частый на учебных стендах: вход в CICS напрямую из “welcome” экрана (до TSO)

Помни самый первый экран с подсказкой `Enter TSO` / `logon userid`?  
На нём иногда можно **напрямую** ввести APPLID приложения.

Попробуй на этом экране (НЕ в TSO/ISPF), в месте ввода команды:

CICSTS62

Если не примет — попробуй:

LOGON CICSTS62

или

LOGON APPLID(CICSTS62)

Если это “Session Manager” — он пустит в CICS. Если это чисто TSO welcome — скажет, что не знает такую команду.

**Как вернуться на этот экран:** ты уже видела, что `X` выводит тебя в LOGOFF. После LOGOFF ты как раз попадёшь на приветственный экран, и можно пробовать там.

---

### Вариант B — сделать вторую 3270-сессию прямо на VTAM (без TSO)

У тебя сверху видно подключение к `204.90.115.200:623` — это tn3270 gateway.  
Часто там есть **разные порты/ендпоинты**:

- один ведёт в TSO,
    
- другой — в VTAM/session manager.
    

Если в твоём клиенте можно добавить новое соединение, попробуй создать **второе** и спросить у стенда/инструктора:

> “какой host/port для VTAM/Session Manager (TPX/NETVIEW)?”

На IBM Z Xplore это обычно предусмотрено, просто тебе нужен правильный endpoint.

---

### Вариант C — выяснить APPLID/точку входа у админов (быстро и без догадок)

Ты уже точно знаешь APPLID CICS = `CICSTS62`. Теперь нужно только **как туда логониться**.  
Правильный короткий вопрос админам/инструкторам:

> “У меня нет команд NET/TPX в TSO (NET NOT FOUND). Какой способ входа в VTAM/Session Manager, чтобы сделать LOGON APPLID(CICSTS62)? Есть ли отдельный tn3270 endpoint?”

---

## Мини-проверка “а вдруг это просто не TSO-команда”

Иногда `NET/TPX` доступны как **CLIST** в логон-библиотеках, но не в ISPF Shell.

Попробуй в ISPF Command Shell:

TSO %NET

и отдельно:

TSO %TPX

(Знак `%` — запуск CLIST.)

Если и так “NOT FOUND” — тогда точно вариант A/B/C.

---

## Самый практичный следующий шаг прямо сейчас

1. Выйди из ISPF/TSO (да, у тебя это `X` → LOGOFF).
    
2. На приветственном экране **вместо TSO** набери:
    
    - `CICSTS62`
        
    - если не сработает — `LOGON CICSTS62`
        

И пришли ответ/сообщение, которое появится. По нему сразу скажу, в каком ты режиме и как зайти в CICS.

  

IKJ56710I INVALID USERID, CICSTS62 IKJ56703A REENTER THIS OPERAND - APPLID(CICSTS62) IKJ56710I INVALID USERID, APPLID(CICSTS62) IKJ56703A REENTER THIS OPERAND -

  

Nachgedacht für 36s

Это сообщение означает, что ты вводишь `CICSTS62` **не в VTAM/Session Manager**, а в **TSO LOGON**, где система ждёт **TSO userid**.

Поэтому и получаешь:

- `IKJ56710I INVALID USERID, CICSTS62` — “CICSTS62” восприняли как userid
    
- `IKJ56710I INVALID USERID, APPLID(CICSTS62)` — то же самое, только с другой строкой
    

То есть: **ты пока физически не попал на экран, где принимается `LOGON APPLID(...)`.**

## Что это значит practically

1. **APPLID CICS ты уже нашёл** (CICSTS62) ✅
    
2. Но у тебя **нет пути в VTAM Session Manager** из TSO (у тебя `NET`/`TPX` “NOT FOUND”) ❌
    
3. Следовательно, “проверить права на CICS” (через `CESN`, `CEMT`) **пока нельзя**, пока тебе не дадут точку входа в VTAM.
    

---

## Что попробовать прямо сейчас

### 1) Попробовать NET/TPX как CLIST (часто так и есть)

Не `NET`, а **с %**. Лучше делать на `READY`, но можно и из ISPF command shell:

TSO %NET  
TSO %TPX

Если ты на `READY`, то можно так:

%NET  
%TPX

Если опять “NOT FOUND” — идём дальше.

### 2) Отдельная 3270-сессия “в VTAM/Session Manager”

На учебных/песочничных стендах часто есть **два входа**:

- один сразу в **TSO logon** (как у тебя),
    
- второй — в **Session Manager (TPX/NET)**, откуда уже делается `LOGON APPLID(CICSTS62)`.
    

Нужно найти/получить **host/port/endpoint для Session Manager**.

---

## Что попросить у админа/инструктора (самый короткий запрос)

Скопируй/отправь им вот так:

> “Я вижу CICS started task и в логе DFHPA1927: APPLID=CICSTS62.  
> Но из TSO у меня нет NET/TPX (IKJ56500I COMMAND NET NOT FOUND), и `LOGON APPLID(...)`негде вводить — TSO logon воспринимает CICSTS62 как userid (IKJ56710I).  
> Дайте, пожалуйста, точку входа в VTAM/Session Manager (TPX/NET) или отдельный tn3270 endpoint, чтобы я мог сделать LOGON APPLID(CICSTS62).”

---

## Как только попадёшь в Session Manager

Там уже последовательность простая:

1. `LOGON APPLID(CICSTS62)`
    
2. `CESN`
    
3. `CEMT I SYS` (проверка минимальных прав)
    

---

Хочешь — скажи, какой у тебя сейчас “базовый” способ подключения (адрес/порт ты показал `204.90.115.200:623`). Часто рядом есть второй endpoint (другой порт или другой профиль подключения) именно для VTAM/TPX — подскажу, что обычно искать в настройках твоего 3270-клиента.

  

у меня в cobol CBL NOXREF NOMAP NOOFFSET IDENTIFICATION DIVISION. PROGRAM-ID. LIBMQTST. как можно еще уменьшить листинг для компиляции

  

Nachgedacht für 32s

У тебя уже выключены “тяжёлые” части листинга (`NOXREF NOMAP NOOFFSET`). Ещё сильнее уменьшить можно так:

## 1) Отключить сам листинг и исходник в листинге

Добавь к `CBL`:

CBL NOLIST NOSOURCE NOXREF NOMAP NOOFFSET NOVBREF

- `NOLIST` — подавляет листинг. 
    
- `NOSOURCE` — не печатать исходник в листинге. 
    
- `NOVBREF` — подавляет VBREF-листинг (если он вообще включался). 
    

(IBM прямо рекомендует набор вида `NOSOURCE NOXREF NOVBREF NOMAP NOOFFSET NOLIST` для минимизации листингов.) 

## 2) Жёсткий способ: не спулить листинг вообще (JCL)

Если твоя compile-процедура печатает листинг в `SYSPRINT`, можно в JCL “выкинуть” его:

//SYSPRINT DD DUMMY

⚠️ Минус: ты можешь потерять **диагностику компилятора** в выводе (в зависимости от PROC/стенда). Поэтому обычно лучше сначала вариант (1), а `DD DUMMY` — только если уверен, что ошибки всё равно видны в другом DD (например, `SYSOUT`/`SYSERR` и т.п.).

Если покажешь свой compile JCL/PROC (хотя бы DD-шки `SYSPRINT/SYSOUT`), скажу точно куда у тебя уходит листинг и где безопаснее “урезать”.

  

на какой позиции в Кобол может стоять EXEC SQL DECLARE CURSOR

  

`EXEC SQL DECLARE <cursor> CURSOR ... END-EXEC` в COBOL **должен стоять в WORKING-STORAGE SECTION**, то есть в **DATA DIVISION**, **после** `EXEC SQL INCLUDE SQLCA END-EXEC` (обычно) и **до** первого `OPEN` этого курсора в `PROCEDURE DIVISION`.

Типовая схема:

       DATA DIVISION.  
       WORKING-STORAGE SECTION.  
  
       EXEC SQL INCLUDE SQLCA END-EXEC.  
  
       EXEC SQL  
           DECLARE C1 CURSOR FOR  
               SELECT ...  
               FROM   ...  
               WHERE  ...  
       END-EXEC.  
  
       PROCEDURE DIVISION.  
           EXEC SQL OPEN C1 END-EXEC  
           ...  
           EXEC SQL FETCH C1 INTO :WS-... END-EXEC  
           ...  
           EXEC SQL CLOSE C1 END-EXEC  
           ...

### Важные нюансы (по “позиции”)

- Это **не** “column 8..72” как у старого fixed-format — `EXEC SQL` может начинаться в обычной области кода, но **ключевое**: он должен быть в **WORKING-STORAGE**, а не в PROCEDURE (в PROCEDURE — только OPEN/FETCH/CLOSE).
    
- В DB2 precompiler `DECLARE CURSOR` — это “declarative statement”, он должен быть **до** использования курсора (до `OPEN`).
    

Если хочешь — скинь 15–30 строк вокруг твоего места вставки (Data Division / Working-Storage / Procedure) — скажу, куда именно лучше вставить в твоём стиле программы (с COPY MQ, SQLCA и т.д.).

  

у меня репозитарий https://github.com/ksergej/library-host-bridge.git я делаю локально .../library-host-bridge [1] git push To https://github.com/ksergej/library-host-bridge.git ! [rejected] main -> main (non-fast-forward) error: failed to push some refs to 'https://github.com/ksergej/library-host-bridge.git' hint: Updates were rejected because the tip of your current branch is behind hint: its remote counterpart. If you want to integrate the remote changes, hint: use 'git pull' before pushing again. hint: See the 'Note about fast-forwards' in 'git push --help' for details.

  

Это стандартная ситуация: в **remote `main`** уже есть коммиты, которых **нет в твоём локальном `main`**, поэтому Git запрещает пуш (чтобы не “переписать” чужую историю).

### Вариант 1 (рекомендую): подтянуть remote и перепроиграть свои коммиты поверх (rebase)

git status  
git fetch origin  
git pull --rebase origin main  
# если будут конфликты:  
#   исправь файлы  
#   git add <file...>  
#   git rebase --continue  
git push origin main

### Вариант 2: подтянуть remote обычным merge

(будет merge-коммит)

git fetch origin  
git pull origin main  
git push origin main

### Вариант 3 (опасно): force push

Только если ты **точно** понимаешь, что делаешь и хочешь **перетереть** удалённую ветку своей локальной историей:

git push --force-with-lease origin main

`--force-with-lease` чуть безопаснее, чем `--force` (не затрёт чужие новые коммиты, если они появились внезапно).

---

Если хочешь самый быстрый “без сюрпризов” путь: **Вариант 1 (`pull --rebase`)**.

Если после `git pull --rebase` появятся конфликты — просто вставь сюда вывод (пару строк “CONFLICT …”) и я скажу, что именно править и какими командами закончить rebase.

  

host-library-infra.zip

ZIP-Archiv

вот мой текущий часть хост части проекта прочитай

  

Nachgedacht für 34s

Прочитал `host-library-infra.zip`. В целом структура очень аккуратная: **COBOL + MQ + DB2**, JCL шаблоны под Ansible, плюс готовые playbooks для **deploy → schema/data → compile**.

Ниже — что у тебя уже хорошо и что бы я поправил/усилил (самое “важное по делу”).

---

## Что уже сделано хорошо

### 1) COBOL `LIBMQTST.cbl`

- ✅ Есть `EXEC SQL INCLUDE SQLCA` и курсор `DECLARE CUR-ACTIVE-LOANS` в **WORKING-STORAGE**(это правильное место).
    
- ✅ MQ correlation pattern реализован корректно:
    
    - `MOVE MQMD-MSGID TO MQMD-CORRELID`
        
    - `MOVE MQMI-NONE TO MQMD-MSGID`
        
- ✅ У тебя есть три ветки логики: **BORROW / RETURN / ACTIVE**.
    
- ✅ Запросы DB2 + `COMMIT`/`ROLLBACK` выглядят логично.
    

### 2) Ansible

- ✅ Правильно сделано:
    
    - создание PDS/PDSE,
        
    - `zos_copy` с `ISO8859-1 -> IBM-1047`,
        
    - preflight `import zoautil_py`,
        
    - локальный render JCL + проверка на “неразрешённые {{…}}” — это прям хороший safety-check.
        

---

## Что бы я поправил в первую очередь (важные несостыковки)

### A) Несоответствие имени run-JCL в playbook

- В `library_deploy.yml` ты грузишь run job как:
    
    - `{{ jcl_pds }}(LIBMQTST)` (из шаблона `LIBMQTST.jcl.j2`)
        
- А `run_host.yml` пытается запускать:
    
    - `{{ jcl_pds }}(LIBMQRUN)`
        

➡️ Это баг/рассинхрон. Либо:

- переименовать в playbook на `LIBMQTST`,  
    либо
    
- реально загрузить член `LIBMQRUN`.
    

### B) `CBLMQDB2.jcl.j2` “compile+link+bind plan” — но биндишь только PACKAGE

Файл называется “Bind plan”, но в конце:

BIND PACKAGE({{ hlq }}) MEMBER(LIBMQTST) ...

- нет `BIND PLAN(...)`
    
- `MEMBER(LIBMQTST)` — захардкожено (лучше `{{ host_program_member }}`)
    

При этом run JCL запускает:

RUN PROGRAM(LIBMQTST) PLAN(&SYSUID) ...

➡️ Если плана `PLAN(&SYSUID)` нет — run будет падать, даже если package есть.

Тут два нормальных варианта:

1. **Сделать compile job реально “package+plan”**
    
    - добавить `BIND PLAN({{ hlq }}) PKLIST({{ hlq }}.*) ...`
        
    - и в run JCL использовать `PLAN({{ hlq }})`, а не `PLAN(&SYSUID)`
        
2. Или оставить plan “как есть в системе”, но тогда:
    
    - в README/vars явно фиксировать, какой **PLAN** должен существовать,
        
    - и почему он равен `&SYSUID`.
        

### C) `BINDPLAN.jcl.j2` использует захардкоженный SDSNLOAD

Там:

//STEPLIB  DD DSN=DSND10.SDSNLOAD,DISP=SHR

а в vars у тебя уже есть `db2.loadlib`.

➡️ Лучше сделать так же, как в остальных шаблонах: `DSN={{ db2.loadlib }}`.

---

## Ещё 5 точечных улучшений (не срочно, но полезно)

1. **MQPUT length**
    
    - сейчас `COMPUTE RSP-DATA-LEN = FUNCTION LENGTH(RSP-DATA).`
        
    - это даст 8192 почти всегда (потому что поле фиксированное).
        
    - лучше длину брать от указателя `WS-PTR-1` после `STRING ... WITH POINTER`, или “trim + measure”.
        
2. **XML парсинг сейчас очень хрупкий**
    
    - `INSPECT ... FOR ALL "<HostActiveLoansByUserRequest"` ок для демо,
        
    - но лучше хотя бы нормализовать пробелы/переводы строк или сделать минимальные проверки на `xmlns`/варианты.
        
3. **Обработка `SQLCODE = 100`**
    
    - у тебя для cursor fetch это сделано корректно,
        
    - для select’ов местами тоже ок (в RETURN). Для BORROW COUNT(*) 100 не будет, но это норм.
        
4. **Имена таблиц без квалификатора**
    
    - в SQL: `FROM LOAN`
        
    - в DB2 на z/OS это зависит от CURRENT SQLID/qualifier.
        
    - Можно либо:
        
        - настроить qualifier через bind options,
            
        - либо писать `{{ db2.qualifier }}.LOAN` (но тогда precompile/bind/DDL должны совпасть).
            
5. **Playbooks: разбить “deploy” на idempotent этапы**
    
    - у тебя уже есть `compile_host.yml`, `db2_schema.yml`, `db2_data.yml`
        
    - можно сделать “meta-playbook” `all.yml` (или поправить `smoke.yml`) так, чтобы он реально делал полный прогон, включая run/test.
        

---

## Если хочешь — могу быстро сделать “ревью-дифф” по фикс-пойнтам

Без вопросов могу подготовить конкретные патчи (в стиле твоего проекта) на:

- `run_host.yml` (исправить member)
    
- `CBLMQDB2.jcl.j2` (PACKAGE+PLAN и убрать hardcode)
    
- `BINDPLAN.jcl.j2` (STEPLIB через `db2.loadlib`)
    
- плюс аккуратно починить `RSP-DATA-LEN` (чтобы MQPUT посылал реальную длину)
    

Скажи только: **ты хочешь, чтобы PLAN был `{{ hlq }}` (стабильно) или `&SYSUID` (как сейчас в RUN JCL)?**  
Я могу выбрать “лучший по умолчанию” (HLQ) и сразу предложить единый контракт “HLQ = schema/collection/plan”.

  

сохрани провблемы и предлжения для фиксов как файл fix_todo.md

  

Готово — сохранил в файл.

Download fix_todo.md 

  

сейчас новая задача - у меня есть работающий CICS регион и я хочу создать тестовую программу с использованием CiCS сейчас схема теста такая - 1)SpingBoot пишет в MQ и ждет ответа 2) я запускаю в ручную на хосте джоб 3) SpringBoot получает ответ из MQ ----------- вместо ручного запоска я хочу создать автоматический запуск через CICS как это сделать?

  

Nachgedacht für 16s

Есть 3 нормальных пути убрать “ручной JOB” и сделать автозапуск на хосте. Самый близкий к твоей текущей схеме **SpringBoot ⇄ MQ ⇄ Host** — это:

## Вариант A (рекомендую): MQ Triggering → CICS Trigger Monitor (CKTI) → твоя CICS транзакция

Идея: **сообщение прилетает в request queue → MQ сам кладёт trigger message в initiation queue → CICS (CKTI) читает initiation queue и стартует транзакцию → транзакция берёт исходное сообщение из request queue, делает DB2, пишет reply.**

Это прямо “автозапуск по приходу сообщения” без polling в Java и без batch.

---

# Как сделать (пошагово)

## 0) Предварительные условия

- CICS регион уже работает (у тебя `APPLID=CICSTS62`).
    
- Есть IBM MQ queue manager, доступный для CICS.
    
- В CICS установлен/доступен IBM MQ adapter (обычно в CICS TS он есть, но может быть не активирован).
    
- У тебя есть права определять ресурсы (или кто-то из админов сделает DEFINE/INSTALL).
    

---

## 1) MQ: включить triggering на request queue

Тебе нужно (минимум):

- **REQUEST.Q** — куда пишет SpringBoot
    
- **REPLY.Q** — откуда читает SpringBoot
    
- **INIT.Q** — initiation queue (куда MQ кладёт trigger messages)
    
- **PROCESS** — объект процесса, который скажет “запускать CICS transid XXX”
    

Пример MQSC (как шаблон, имена подставь свои):

* initiation queue  
DEFINE QLOCAL(CICS.INITQ) DEFPSIST(YES)  
  
* process definition: tell MQ to start CICS transid  
DEFINE PROCESS(CICS.LIBPROC) APPLTYPE(CICS) APPLICID(LIBT)  
  
* request queue with trigger  
ALTER QLOCAL(LIB.REQ.Q) TRIGGER TRIGTYPE(FIRST) INITQ(CICS.INITQ) PROCESS(CICS.LIBPROC) DEFPSIST(YES)  
  
* reply queue (обычная, без trigger)  
DEFINE QLOCAL(LIB.REP.Q) DEFPSIST(YES)

Пояснения:

- `TRIGTYPE(FIRST)` = стартует обработчик, когда очередь переходит из 0 в 1 сообщение (обычный вариант, чтобы не стартовать транзакцию на каждое сообщение).
    
- Можно `TRIGTYPE(EVERY)` (но чаще не надо).
    

---

## 2) CICS: настроить CKTI (Trigger Monitor)

В CICS должен быть доступен **CKTI** (IBM MQ Trigger Monitor для CICS).  
Задача CKTI: читать `CICS.INITQ` и по trigger message делать `START TRANSID(LIBT)`.

Что нужно:

1. **TRANSACTION CKTI** (обычно уже есть)
    
2. Настроить CKTI на чтение нужной initiation queue (зависит от установки; иногда через параметры/таблицы/ресурсы)
    

Практически:

- Проверка наличия: попробуй в CICS выполнить `CKTI` (как транзакцию). Если “not found/not authorized” — надо определить/разрешить.
    
- Идеально: включить CKTI **автостартом при старте региона** (PLTPI), чтобы он всегда слушал INITQ.
    

---

## 3) CICS: создать свои ресурсы (PROGRAM + TRANSACTION)

Тебе нужно определить:

- `PROGRAM(LIBMQCIC)` — твоя новая CICS COBOL программа (под CICS)
    
- `TRANSACTION(LIBT)` — транзакция, которую будет стартовать CKTI
    
- (часто) `MQCONN` ресурс — связь CICS↔MQ queue manager (зависит от версии/настроек)
    

Минимум: TRANSACTION `LIBT` должен запускать PROGRAM `LIBMQCIC`.

---

## 4) Логика CICS-программы (что она должна делать)

Внутри CICS ты можешь использовать **MQI вызовы** (MQCONN/MQOPEN/MQGET/MQPUT), но commit/rollback лучше делать через CICS:

- Получила сообщение из `LIB.REQ.Q`
    
- Считала payload (как сейчас)
    
- Сделала DB2
    
- Положила ответ в `LIB.REP.Q` (с CorrelId = MsgId как у тебя)
    
- `EXEC CICS SYNCPOINT` (commit сразу MQ + DB2)
    
- На ошибке: `EXEC CICS SYNCPOINT ROLLBACK`
    

**Важно:** под CICS лучше не делать “бесконечный wait” в одном task. Типовой паттерн:

- транзакция стартовала → обработала 1 сообщение (или небольшой batch) → завершилась.  
    Triggering сам обеспечит новый старт при новых сообщениях.
    

---

# Как это будет выглядеть end-to-end

1. SpringBoot PUT в `LIB.REQ.Q`, ждёт reply по `CorrelId`.
    
2. MQ видит, что очередь стала non-empty → кладёт trigger в `CICS.INITQ`.
    
3. CKTI в CICS читает `CICS.INITQ` → `START TRANSID(LIBT)`.
    
4. `LIBT` запускает `LIBMQCIC` → MQGET из `LIB.REQ.Q` → DB2 → MQPUT в `LIB.REP.Q`(CorrelId=MsgId) → SYNCPOINT.
    
5. SpringBoot получает сообщение из `LIB.REP.Q` по `CorrelId`.
    

---

# Что выбрать как “самый быстрый MVP”

**Сначала сделай “ручной запуск транзакции LIBT”** (без triggering):

- вручную запускаешь `LIBT` в CICS,
    
- она берёт 1 сообщение из request queue и отвечает.
    

Когда это заработает — добавляешь MQ triggering + CKTI и получаешь автоматизацию.

---

# Если скажешь 2 вещи — я дам тебе конкретный минимальный набор DEFINE’ов и скелет CICS COBOL

1. **Имя queue manager** для CICS и имена очередей (`REQ`, `REP`)
    
2. Каким способом ты сейчас компилишь/линкуешь (какой PROC/JCL и есть ли уже CICS compile proc)
    

И я прямо дам:

- MQSC для объектов (INITQ/PROCESS/TRIGGER на request queue)
    
- CICS resource definitions (PROGRAM/TRANSACTION + что нужно для MQCONN)
    
- скелет COBOL под CICS (обработка 1 сообщения + SYNCPOINT + MQMD CorrelId=MsgId как у тебя)
    

  

02_Flow_Spec_Template.md

Datei

021_Flow_Specification_Methodology.md

Datei

Что выбрать как “самый быстрый MVP” Сначала сделай “ручной запуск транзакции LIBT” (без triggering): • вручную запускаешь LIBT в CICS, • она берёт 1 сообщение из request queue и отвечает. Когда это заработает — добавляешь MQ triggering + CKTI и получаешь автоматизацию. да будем так делать - по такому плану. создай описание этого процесса как новое FLOW-01 ( ручной запуск , потом автоматизация MQ-CKTI ) по образцу документов дай мне ссылку для скачивания

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 15s

Готово — оформил процесс как новый Flow-документ.

Download FLOW-01_CICS_MQ_Manual_Then_CKTI.md 

  

cделай скелет CICS COBOL - возми логику из моей программы и добавь все нужное для CICS - дай для скачивания

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 13s

Denkvorgang abgeschlossen

Готово — сделал **скелет CICS COBOL** `LIBMQCIC.cbl`, взял бизнес-логику/SQL и построение ответа из твоего `LIBMQTST`, добавил CICS-часть (DFHEIBLK/DFHCOMMAREA, HANDLE ABEND, SYNCPOINT commit/rollback, RETURN вместо GOBACK/STOP RUN) и MQGET/MQPUT под CICS-паттерн “обработать 1 сообщение”.

Download LIBMQCIC.cbl 

  

/
  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 24s

Коротко: новую `LIBMQCIC` (с `EXEC CICS …`, DB2 `EXEC SQL …` и MQI) **нельзя** собирать “как батч” 1-в-1. Нужно:

1. **CICS translation** (интегрированный переводчик или DFHECP1)
    
2. **Link-edit с CICS stub DFHELII** 
    
3. Для MQ под CICS — **stub CSQCSTUB (а не CSQBSTUB)** 
    
4. DB2 bind остаётся, но обычно ты биндишь PACKAGE (и/или PLAN — как мы обсуждали ранее)
    

Ниже — два практичных пути. Для “самого быстрого MVP” бери **Вариант A**.

---

## Вариант A (рекомендую, самый быстрый): Integrated CICS translator + DB2 coprocessor

IBM/CICS обычно поставляет готовую PROC/JCL для этого в `SDFHPROC` (например, `DFHZITCL`) — это и есть “правильный шаблон”. 

### Что поменять в твоём job (минимально)

### 1) Compile step

- Меняешь SYSIN/DBRMLIB с `LIBMQTST` на `LIBMQCIC`
    
- В PARM добавляешь CICS translation (в зависимости от стенда это бывает `CICS`/`CICST`/через процедуру из SDFHPROC). На практике проще всего: **использовать штатный PROC из SDFHPROC**. 
    

Плюс **SYSLIB** должен включать CICS copybook libs (обычно `…SDFHCOB` / `…SDFHMAC` — точные DSN зависят от установки).

### 2) Link-edit step (ключевое!)

У тебя сейчас:

INCLUDE SYSLIB(CSQBSTUB)  
ENTRY  LIBMQTST  
NAME   LIBMQTST(R)

Для CICS надо:

- добавить `DFHELII` (CICS-required stub) 
    
- заменить MQ stub на **CSQCSTUB** (CICS MQ stub) 
    
- ENTRY/NAME заменить на `LIBMQCIC`
    

Пример управляющих карт линковки:

  INCLUDE SYSLIB(DFHELII)  
  INCLUDE SYSLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)

И в `LKED.SYSLIB` должен быть CICS loadlib (`…SDFHLOAD`), иначе `DFHELII` не найдётся.

### 3) Bind step

Тут ты уже делаешь `BIND PACKAGE(...) MEMBER(...)`. Для новой программы:

- `DBRMLIB DD ... (LIBMQCIC)`
    
- `BIND PACKAGE(Z88011) MEMBER(LIBMQCIC) ...`
    

⚠️ И ещё важное: у тебя в BIND step сейчас **ошибка в STEPLIB**:

//STEPLIB  DD  DSN=DSND10.SDSNLOAD(LIBMQTST),DISP=SHR

`SDSNLOAD` — это **load library dataset**, а не PDS-member для STEPLIB. Должно быть просто:

//STEPLIB  DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//         DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR   (если нужно)

---

## Вариант B (классика): DFHECP1 (CICS translator) → IGYCRCTL(SQL) → Link → Bind

Если на стенде нет интегрированного переводчика, делают отдельный шаг translator DFHECP1. IBM описывает CICS translators и их опции.   
Но для MVP это обычно “лишний геморрой”, поэтому я бы сначала искал PROC `DFHZITCL` в `SDFHPROC`. 

---

## TL;DR — конкретно “что править в твоём job”

1. Везде заменить `LIBMQTST` → `LIBMQCIC` (SYSIN/DBRMLIB/ENTRY/NAME/SYSLMOD).
    
2. В LKED:
    
    - добавить `…SDFHLOAD` в `SYSLIB`
        
    - заменить `CSQBSTUB` → `CSQCSTUB` 
        
    - добавить `DFHELII` 
        
3. В COBOL compile: использовать **integrated translator PROC** (лучше всего) 
    
4. В BIND step исправить `STEPLIB` (без `(member)`), и биндинг на `MEMBER(LIBMQCIC)`.
    

---

Если хочешь, я сделаю тебе **готовый JCL job** “compile+link+bind” именно под `LIBMQCIC` (как отдельный файл для скачивания), но мне нужны 3 DSN из твоего окружения:

1. CICS `SDFHLOAD` (loadlib)
    
2. CICS `SDFHCOB` (copybooks)
    
3. DB2 `SDSNLOAD` / `SDSNEXIT` (у тебя уже видно `DSND10...`, но лучше подтвердить)
    

С этими 3 DSN я соберу джоб так, чтобы он запускался сразу.

  

LIBMQCIC.cbl

Datei

эта программа будет работать?

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 1m 10s

Она **может** заработать в CICS, но **в текущем виде “сама по себе” — ещё не гарантированно**, потому что успех зависит не столько от COBOL-кода, сколько от **правильной сборки/линковки под CICS** и от **настроек региона (DB2/MQ attach, security, ресурсы)**.

Ниже — честная оценка по твоему `LIBMQCIC.cbl` и что надо сделать, чтобы она реально пошла.

## Что в коде уже ок (по сути логики)

- MQGET делает **NO-WAIT** и добавляет `MQGMO-SYNCPOINT` — это правильно для CICS + `EXEC CICS SYNCPOINT`.
    
- Reply correlation сделан правильно:
    
    - `MOVE MQMD-MSGID TO MQMD-CORRELID`
        
    - `MOVE MQMI-NONE TO MQMD-MSGID`
        
- В конце делаешь `EXEC CICS SYNCPOINT` / `ROLLBACK`.
    

## 3 вещи, из-за которых “может не взлететь”

### 1) Компиляция под CICS (translator)

В программе есть `EXEC CICS ...`, значит её **нельзя** компилировать только `IGYCRCTL PARM='SQL'` как батч.  
Нужен **CICS translator** (integrated translator или DFHECP1), иначе компилятор/линкер упадёт или получишь нерабочий load module.

### 2) Link-edit: нужен CICS stub + правильный MQ stub

Для CICS программа должна быть слинкована минимум с:

- `DFHELII` (CICS stub)
    
- **и** MQ stub именно для CICS: `CSQCSTUB` (а не `CSQBSTUB`, который ты сейчас используешь для batch)
    

Если слинкуешь “как раньше” с `CSQBSTUB`, в CICS это часто заканчивается S0C/S0C4 или странными MQ RC.

### 3) DB2 package/plan под CICS userid

Даже если пакет собран, под CICS будет другой authid/attach-context, и легко получить:

- `-805` (package not found) / `-818` и т.п.
    

Нужно, чтобы bind (PACKAGE/PLAN) был согласован с тем, **как CICS подключён к DB2** (и какой PLAN используется).

---

## 2 важных правки прямо в коде (чтобы не словить грабли)

### A) Длина MQPUT сейчас всегда 8192

У тебя:

COMPUTE RSP-DATA-LEN = FUNCTION LENGTH(RSP-DATA).

Это почти всегда даст **8192** (потому что поле фиксированное), и ты отправишь гору пробелов после XML.

Надо считать реальную длину (через pointer после `STRING ... WITH POINTER`, как мы обсуждали) или “trim”.

### B) FILE SECTION / PARAMSFILE

В твоём `LIBMQCIC.cbl` всё ещё есть `FILE-CONTROL` / `FD PARAMSFILE` (остаток от батча).  
Если ты его не используешь — лучше **выкинуть**, чтобы не было сюрпризов и лишних требований к DD/FCT.

---

## Итоговый ответ на “будет работать?”

**Да, логика в целом пригодна для CICS MVP**, но **заработает только если**:

1. ты соберёшь её через CICS translator,
    
2. слинкуешь с `DFHELII` + `CSQCSTUB`,
    
3. правильно сделаешь DB2 bind (package/plan) для CICS окружения,
    
4. поправишь `RSP-DATA-LEN` (иначе будет “работает, но мусор в ответе”).
    

---

## Дальше (самый практичный следующий шаг)

Я могу прямо сейчас сделать тебе:

1. **новый compile+link+bind JCL** для `LIBMQCIC` (на базе твоего job),
    
2. **минимальные CICS resource definitions** (TRANSACTION/PROGRAM),
    
3. небольшой патч `LIBMQCIC.cbl` (убрать FILE SECTION + правильный RSP-DATA-LEN).
    

Но мне нужно только одно: **какие DSN у CICS библиотек** в твоём стенде:

- `SDFHLOAD` (чтобы взять DFHELII)
    
- `SDFHCOB` (copybooks, если надо)
    
- и подтверждение MQ loadlib (у тебя `CSQ920.SCSQLOAD` уже есть — ок)
    

Скажи DSN `SDFHLOAD` (хотя бы один), и я соберу готовый JCL + обновлённый `LIBMQCIC.cbl` для скачивания.

  

END PROGRAM LIBMQCIC. - это нормально для CICS

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, **`END PROGRAM LIBMQCIC.` — нормально для CICS**.

Это **чисто синтаксис COBOL** (завершение compilation unit), CICS на это никак не “обижается”. В CICS важно другое:

- **Как ты выходишь из программы во время выполнения**: правильно — через  
    `EXEC CICS RETURN END-EXEC`  
    (а не `STOP RUN`).
    
- `GOBACK` обычно тоже “работает”, но для CICS **лучше и привычнее `EXEC CICS RETURN`**, особенно если программа вызывается транзакцией.
    

`END PROGRAM ...` можно оставлять. Единственный нюанс — если компилятор очень старый/режим совместимости, он мог не поддерживать `END PROGRAM`, но на современных Enterprise COBOL это стандартно и ок.

  


Да — **`DFH620.CICS.SDFHLOAD` это как раз “правильная” библиотека CICS runtime/load modules**, и то, что ты видишь там `DFHECP1$`, `DFHECIS`, и т.п. — хороший признак.

Но для твоей задачи важнее не эти модули, а наличие **CICS link stub**:

## 1) Проверь, что в SDFHLOAD есть `DFHELII`

Сделай поиск по имени на панели Browse (или в 3.4):

- `DFHELII`
    

Если **`DFHELII` есть** → это именно то, что нужно для **линковки CICS COBOL программы** (в LKED `INCLUDE SYSLIB(DFHELII)`).

Если **не найдётся**, иногда stub лежит в другом CICS loadlib (но обычно он именно в SDFHLOAD).

## 2) Для компиляции/трансляции тебе нужна ещё библиотека PROC

То, что ты показал, — **LOADLIB**. Для “integrated translator” обычно используется PROC из:

- `...SDFHPROC`
    

Там часто есть процедуры типа `DFH*` (в зависимости от версии).

## 3) Что ответить на твой вопрос “подходящая LIB?”

- **Да, SDFHLOAD подходит** для шага **LINK-EDIT** (DFHELII, и другие CICS runtime modules).
    
- Для **copybooks** (если понадобятся) обычно отдельная `SDFHCOB`/`SDFHC370` (имя зависит от установки).
    
- Для **translator** (если не integrated) могут быть отдельные load modules (`DFHECP1`, и т.п.) — они у тебя тоже в SDFHLOAD видны.
    

---

### Самый короткий next step

1. Найди `DFHELII` в `DFH620.CICS.SDFHLOAD`.
    
2. Скажи, есть ли он.
    

Если есть — я дам тебе готовые **LKED cards** (с `DFHELII + CSQCSTUB`) и обновлённый compile+link JCL под `LIBMQCIC` с твоими DSN.

  

есть такой джоб //CICSCBL PROC LNGPRFX='IGY640', // LIBPRFX='CEE', // CICSPRX='DFH620.CICS', // PGMLIB='&&GOSET',GOPGM=GO //* //* CBL CICS >>> Must be first line in COBOL ource code //* //* CALLER MUST SUPPLY //* //COBOL.SYSIN DD >>> COBOL Source Code //* //COBOL.SYSLIB DD >>> COPY statements //* //LKED.SYSLMOD DD >>> Executable load module library //* //COBOL EXEC PGM=IGYCRCTL,REGION=0M //STEPLIB DD DSNAME=&LNGPRFX..SIGYCOMP,DISP=SHR // DD DSNAME=&LIBPRFX..SCEERUN,DISP=SHR // DD DSNAME=&LIBPRFX..SCEERUN2,DISP=SHR // DD DSNAME=&CICSPFX..SDFHLOAD,DISP=SHR //SYSPRINT DD SYSOUT=* //SYSLIN DD DSNAME=&&LOADSET,UNIT=SYSALLDA, // DISP=(MOD,PASS),SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT1 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT2 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT3 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT4 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT5 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT6 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT7 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT8 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT9 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT10 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT11 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT12 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT13 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT14 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSUT15 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //SYSMDECK DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)),VOL=(,,,1) //LKED EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M //SYSLIB DD DSNAME=&LIBPRFX..SCEELKEX,DISP=SHR // DD DSNAME=&LIBPRFX..SCEELKED,DISP=SHR // DD DSNAME=&CICSPFX..SDFHLOAD,DISP=SHR //SYSPRINT DD SYSOUT=* //SYSLIN DD DSNAME=&&LOADSET,DISP=(OLD,DELETE) // DD DDNAME=SYSIN //SYSLMOD DD DSNAME=&PGMLIB(&GOPGM), // SPACE=(CYL,(1,1,1)), // UNIT=SYSALLDA,DISP=(MOD,PASS),DSNTYPE=LIBRARY

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, это **хорошая отправная точка**, но в текущем виде этот PROC делает только **COBOL compile + link**“под CICS-среду” (подцепляет `SDFHLOAD`), **а тебе нужно ещё 3 вещи**, чтобы собрать `LIBMQCIC` (CICS + DB2 + MQ):

1. **CICS translation** (`CBL CICS` или встроенный translator) — иначе `EXEC CICS` не переведётся
    
2. **DB2 SQL** (coprocessor / precompiler) — иначе `EXEC SQL` не обработается и не создастся DBRM
    
3. **MQ stub для CICS** — в link step надо добавить `CSQCSTUB` (а не batch `CSQBSTUB`)
    

Ниже — как именно использовать твой PROC для MVP.

---

## 1) Исправь мелкую ошибку в PROC

У тебя параметр называется `CICSPRX`, а в DD’ах используется `&CICSPFX` — это опечатка.

Должно быть **одно имя**. Например так:

//CICSCBL PROC  LNGPRFX='IGY640',  
//              LIBPRFX='CEE',  
//              CICSPFX='DFH620.CICS',  
//              PGMLIB='&&GOSET',GOPGM=GO

и в DD:

//         DD  DSNAME=&CICSPFX..SDFHLOAD,DISP=SHR

---

## 2) Как собрать `LIBMQCIC` быстро (MVP): отдельный JOB на базе этого PROC

### Шаг A: CICS translator + COBOL compile + DB2 SQL

Самый быстрый способ на твоём стенде обычно такой:

- **первая строка в исходнике**: `CBL CICS SQL`  
    (или `CBL CICS` + компайл с `PARM='SQL'` — зависит от того, как у вас настроен компилятор)
    

Твой PROC сейчас запускает:

//COBOL  EXEC PGM=IGYCRCTL

Если у тебя реально работает “первая строка `CBL CICS`”, то это уже включает integrated translator для CICS.  
А DB2 (`SQL`) — у тебя пока **нет DSNEXIT/SDSNLOAD** в STEPLIB, как в твоём старом job.

➡️ Значит для `LIBMQCIC` тебе нужно расширить COBOL.STEPLIB как в твоём batch-job:

- `...SDSNEXIT`
    
- `...SDSNLOAD`
    

(и DBRMLIB DD для DBRM)

### Шаг B: Link-edit — добавить stubs

В `LKED.SYSLIB` уже есть `SDFHLOAD` (хорошо).  
Нужно добавить MQ loadlib, где лежит **CSQCSTUB** (у тебя это, похоже, `CSQ920.SCSQLOAD`).

И в link control cards (SYSIN) добавить:

INCLUDE SYSLIB(DFHELII)  
INCLUDE SYSLIB(CSQCSTUB)  
ENTRY  LIBMQCIC  
NAME   LIBMQCIC(R)

> `DFHELII` — CICS link stub  
> `CSQCSTUB` — MQ stub для CICS

### Шаг C: DB2 BIND

После compile нужен DBRM:

- `DBRMLIB DD ... (LIBMQCIC)`
    

И bind:

BIND PACKAGE(Z88011) MEMBER(LIBMQCIC) ACT(REP) ISO(CS) ENCODING(EBCDIC)

---

## 3) Важный момент про твой PROC: он “GOSET” и DSNTYPE=LIBRARY

Сейчас `SYSLMOD` пишется в `&&GOSET(GO)` и DISP=PASS — это для “одноджобного GO”.  
Для CICS тебе надо писать в **постоянный LOADLIB**, например:

- `Z88011.LOAD(LIBMQCIC)` (как ты делал для batch)
    

То есть `PGMLIB` должен быть твоим loadlib, а `GOPGM` — `LIBMQCIC`.

---

## 4) Что я предлагаю сделать прямо сейчас

Чтобы ты не собирал это вручную, я могу сделать тебе готовый **JOB** (compile+link+bind) для `LIBMQCIC`на основе твоих DSN (как в batch-job), используя:

- `IGY640.SIGYCOMP`
    
- `DFH620.CICS.SDFHLOAD`
    
- `DSND10.DBDG.SDSNEXIT`
    
- `DSND10.SDSNLOAD`
    
- `CSQ920.SCSQLOAD`
    
- твои datasets: `Z88011.CBL`, `Z88011.DBRMLIB`, `Z88011.LOAD`
    

Но мне нужно уточнить только 2 вещи (без них можно ошибиться):

1. DB2 subsystem у тебя **DBDG** (как в примере) — это точно?
    
2. MQ loadlib с `CSQCSTUB` — это точно `CSQ920.SCSQLOAD` (или другой CSQxxx)?
    

Если не хочешь уточнять — я сделаю “best effort” job под `DBDG` и `CSQ920.SCSQLOAD` (как у тебя в старом JCL) и дам файл для скачивания.

  

вот мой джоб для MQ + DB2

  

//CBLMQDB2 JOB 1,NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H,TIME=1440 //******************************************************************** //* Compile + Link-edit + Bind (DB2) for COBOL MQ program //* This is the canonical "compile+link+bind" job used by Ansible. //* Variables are injected by Ansible/Jinja2 (no hardcoded DSNs here). //******************************************************************** //******************************************************************** //* COMPILE - COBOL + embedded SQL * //******************************************************************** //COBOL EXEC PGM=IGYCRCTL,REGION=0M,PARM='SQL' //STEPLIB DD DSN=IGY640.SIGYCOMP,DISP=SHR // DD DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR // DD DSN=DSND10.SDSNLOAD,DISP=SHR // DD DSN=CEE.SCEERUN,DISP=SHR // DD DSN=CEE.SCEERUN2,DISP=SHR //SYSIN DD DISP=SHR,DSN=Z88011.CBL(LIBMQTST) //DBRMLIB DD DISP=SHR,DSN=Z88011.DBRMLIB(LIBMQTST) //SYSLIB DD DSN=CSQ920.SCSQCOBC,DISP=SHR // DD DSN=Z88011.CBL,DISP=SHR //SYSPRINT DD SYSOUT=* //SYSLIN DD DSN=&&LOADSET,UNIT=SYSALLDA, // DISP=(MOD,PASS),SPACE=(CYL,(1,1)) //SYSUT1 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT2 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT3 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT4 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT5 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT6 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT7 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT8 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT9 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT10 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT11 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT12 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT13 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT14 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSUT15 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSMDECK DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //******************************************************************** //* LINK-EDIT * //******************************************************************** //LKED EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M //SYSLIB DD DSN=CEE.SCEELKED,DISP=SHR // DD DSN=DSND10.SDSNLOAD,DISP=SHR // DD DSN=CSQ920.SCSQLOAD,DISP=SHR //SYSPRINT DD SYSOUT=* //SYSUT1 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1)) //SYSLIN DD DSN=&&LOADSET,DISP=(OLD,DELETE) // DD * INCLUDE SYSLIB(CSQBSTUB) ENTRY LIBMQTST NAME LIBMQTST(R) /* //SYSLMOD DD DSN=Z88011.LOAD(LIBMQTST),DISP=SHR //******************************************************************** //* BIND DB2 PLAN * //******************************************************************** //BIND EXEC PGM=IKJEFT01,COND=(8,LT,LKED) //STEPLIB DD DSN=DSND10.SDSNLOAD(LIBMQTST),DISP=SHR //DBRMLIB DD DSN=Z88011.DBRMLIB(LIBMQTST),DISP=SHR //SYSUDUMP DD DUMMY //SYSTSPRT DD SYSOUT=* //SYSPRINT DD SYSOUT=* //SYSTSIN DD *,SYMBOLS=EXECSYS DSN SYSTEM(DBDG) BIND PACKAGE(Z88011) MEMBER(LIBMQTST) ACT(REP) ISO(CS) ENCODING(EBCDIC) /*

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 10s

Твой текущий job **для batch MQ+DB2** — ок, но для CICS-программы `LIBMQCIC` его нужно переделать так:

### Что меняется принципиально

1. **CICS translation**: в исходнике `LIBMQCIC` первой строкой должно быть `CBL CICS SQL` (или хотя бы `CBL CICS`). Тогда `EXEC CICS` будет корректно переведён.
    
2. **Link-edit stubs**:
    
    - добавить `DFHELII` (CICS stub)
        
    - заменить `CSQBSTUB` (batch) → **`CSQCSTUB`** (CICS MQ stub)
        
3. **BIND STEPLIB**: у тебя сейчас ошибка `DSND10.SDSNLOAD(LIBMQTST)` — так нельзя. Должно быть просто `DSND10.SDSNLOAD` (без member).
    

Я уже собрал тебе готовый job на базе твоего, под `LIBMQCIC` (с твоими DSN: IGY640, DSND10/DBDG, DFH620.CICS.SDFHLOAD, CSQ920.*).

Download CBLMQCIC.jcl

### Как пользоваться

1. Скопируй `LIBMQCIC.cbl` в `Z88011.CBL(LIBMQCIC)` и **вставь первой строкой**:
    

CBL CICS SQL

2. Запусти job `CBLMQCIC.jcl`.
    
3. В результате получишь:
    

- `Z88011.DBRMLIB(LIBMQCIC)` (DBRM)
    
- `Z88011.LOAD(LIBMQCIC)` (load module для CICS)
    

Если хочешь, следующим шагом я сделаю:

- минимальные **CICS definitions** (`PROGRAM(LIBMQCIC)` + `TRANSACTION(LIBT)`) и checklist команд для проверки/установки в регионе. 
    

  

CICS translation: в исходнике LIBMQCIC первой строкой должно быть CBL CICS SQL (или хотя бы CBL CICS). Тогда EXEC CICS будет корректно переведён. так нормально? CBL CICS SQL NOXREF NOMAP NOOFFSET NOSOURCE

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, **так нормально**:

CBL CICS SQL NOXREF NOMAP NOOFFSET NOSOURCE

Это валидная “compiler-directing statement” строка, и она как раз:

- включает **CICS translation** (`CICS`)
    
- включает обработку **embedded SQL** (`SQL`)
    
- отключает лишний листинг (`NOXREF NOMAP NOOFFSET NOSOURCE`)
    

### 2 маленьких замечания

1. Убедись, что это **самая первая строка** в member’е (до `IDENTIFICATION DIVISION.` и без пустых строк сверху).
    
2. Если у вас компилятор/настройки требуют апострофы, иногда пишут так (но у тебя и без них обычно ок):
    

CBL CICS,SQL,NOXREF,NOMAP,NOOFFSET,NOSOURCE

Если компиляция пойдёт и в SYSPRINT не будет сообщений типа “invalid option CICS/SQL”, значит всё сделано правильно.

  

08.22.12 JOB03828 ---- SATURDAY, 04 APR 2026 ---- 08.22.12 JOB03828 IRR010I USERID Z88011 IS ASSIGNED TO THIS JOB. 08.22.14 JOB03828 ICH70001I Z88011 LAST ACCESS AT 07:39:21 ON SATURDAY, APRIL 4, 2026 08.22.14 JOB03828 $HASP373 CBLMQCIC STARTED - INIT 2 - CLASS A - SYS S0W1 08.22.17 JOB03828 IEF764I CBLMQCIC COBOL DFHAPIR DFHEIMOD PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND. 08.22.17 JOB03828 IEF764I CBLMQCIC COBOL DFHAPIR DFHEIMOD PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Сообщение очень конкретное:

> `DFHEIMOD PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND`

Это **CICS translator (integrated)** пытается прочитать свой параметрический member **DFHAPIR** из **CICS PARMLIB**, но в твоём compile job **нет DD на PARMLIB**, либо он указывает не туда.

То есть проблема не в твоём `CBL CICS SQL ...`, а в JCL: переводчик CICS не знает, где брать свои параметры.

## Что сделать (самый быстрый фикс)

### 1) В compile step добавь DD на CICS PARMLIB

В шаге `//COBOL EXEC PGM=IGYCRCTL...` добавь:

//DFHPLT   DD  DSN=DFH620.CICS.SDFHPARM,DISP=SHR

⚠️ Название DD может отличаться на твоём стенде. Чаще всего для integrated translator нужно **`DFHPARM`**или **`DFHPLT`**/**`DFHPRM`** (зависит от инсталляции/процедуры). Но по твоему сообщению явно ищется **PARMLIB member**, значит нужен именно dataset типа `...SDFHPARM` (или `...DFHPARM`).

Самый надёжный способ: найти реальный dataset, где лежит member `DFHAPIR`.

## Как найти, где лежит DFHAPIR (2 минуты)

В ISPF 3.4 сделай:

- Dataset name: `DFH620.CICS.*`
    
- затем **Command = `F DFHAPIR`** (или “Search-for member” если у тебя есть утилита)
    

Часто это будет один из:

- `DFH620.CICS.SDFHPARM`
    
- `DFH620.CICS.DFHPARM`
    
- `DFH620.CICS.SDFHPARMU` (site/user overrides)
    

Как только найдёшь dataset с member `DFHAPIR`, его и подставляешь в DD.

## Почему у тебя сейчас падает

Ты добавил в STEPLIB `...SDFHLOAD` (это правильно для DFHELII/модулей), **но translator ещё требует PARMLIB** (настройки/таблицы), и её JCL не видит.

---

## Быстрый “best effort” патч для твоего `CBLMQCIC.jcl`

В step COBOL вставь **одну из этих строк** (первую, если существует dataset):

//DFHPARM  DD  DSN=DFH620.CICS.SDFHPARM,DISP=SHR

Если `SDFHPARM` у вас называется иначе — поменяешь DSN на тот, где лежит `DFHAPIR`.

---

Если ты скажешь, **есть ли dataset `DFH620.CICS.SDFHPARM`** и виден ли там member `DFHAPIR`, я дам точный готовый кусок JCL (с правильным DDNAME), чтобы компиляция прошла с первого раза.

  

BROWSE DFH620.CICS.SDFHLOAD Row 0000138 of 0001090 Name Prompt Alias-of Size TTR AC AM RM _________ DFHAPIC *Browsed 00000678 0004CC 00 31 ANY _________ DFHAPID 00000990 0000CF 00 31 ANY _________ DFHAPIN 00000558 0000D0 00 31 ANY _________ DFHAPIQ *Browsed 00000678 00029F 00 31 ANY _________ DFHAPJC 000009C8 0002A0 00 31 ANY _________ DFHAPLI 0000C818 000412 00 31 ANY _________ DFHAPLJ 00004A88 000413 00 31 ANY _________ DFHAPLX 00006AD0 00040C 00 31 ANY _________ DFHAPNT 000005B0 0002A1 00 31 ANY _________ DFHAPPG 00000A10 0002A2 00 31 ANY _________ DFHAPPIV 00000078 0000D1 00 31 24 _________ DFHAPRA 00003C68 0000D2 00 31 ANY _________ DFHAPRC 00001AD0 0000D3 00 31 ANY _________ DFHAPRDR 00005358 0002A3 00 31 ANY _________ DFHAPRL 0003CB50 0005EA 00 31 ANY _________ DFHAPRP 00000818 0000D5 00 31 ANY DFHAPIR нет

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, ты правильно проверил: **в `SDFHLOAD` его и не должно быть**, потому что ошибка говорит про **PARMLIB**, а не про loadlib.

Твой вывод “DFHAPIR нет” в `DFH620.CICS.SDFHLOAD` — **нормально**.

## Что это означает

Integrated CICS translator при компиляции пытается прочитать **member `DFHAPIR` из CICS PARMLIB**(обычно dataset типа `...SDFHPARM` / `...DFHPARM`), но:

- либо JCL не даёт ему DD на PARMLIB,
    
- либо у тебя **нет доступа** к нужному PARMLIB,
    
- либо member называется/лежит в другом датасете.
    

---

## Что делать дальше (без гаданий)

### 1) Найти датасет, где лежит member DFHAPIR

В ISPF 3.4 сделай **поиск по всем датасетам CICS**:

**A. Список датасетов**

- `ISPF 3.4`
    
- Dataset name level:  
    `DFH620.CICS.*`
    

**B. Искать member**  
Там есть два типичных способа:

**Способ 1 (если у тебя работает “Find member”):**

- В списке датасетов поставь `M` (Member list) на кандидатов вида:
    
    - `DFH620.CICS.SDFHPARM*`
        
    - `DFH620.CICS.DFHPARM*`
        
    - `DFH620.CICS.SDFHPLIB*` (иногда)
        
- В member list сделай `F DFHAPIR`
    

**Способ 2 (универсальный):**

- Открой каждый подозрительный `...PARM...` датасет и смотри member list.
    

👉 Тебе нужен **любой dataset**, где реально есть **member `DFHAPIR`**.

---

## 2) Когда найдёшь dataset — добавим правильный DD в JCL

В шаг `//COBOL EXEC PGM=IGYCRCTL...` добавишь DD на этот PARMLIB.

Чаще всего DDNAME одно из таких (зависит от установки):

- `DFHPARM`
    
- `DFHPRM`
    
- `DFHPLIB`
    

И DSN будет что-то вроде:

- `DFH620.CICS.SDFHPARM`
    
- или `DFH620.CICS.DFHPARM`
    

Пример (пока шаблон):

//DFHPARM DD DSN=DFH620.CICS.SDFHPARM,DISP=SHR

---

## 3) Самый вероятный исход на учебном стенде

На IBM Z Xplore часто:

- PARMLIB для translator’а лежит в **другом HLQ**, не `DFH620.CICS.*`
    
- или доступ к нему ограничен
    

Поэтому если ты **не находишь ни одного** `...PARM...` датасета под `DFH620.CICS.*`, это тоже норм — просто надо узнать “правильный” dataset у стенда.

---

## Что пришли мне, и я дам точный JCL патч

Скажи одно:

- есть ли в `DFH620.CICS.*` датасеты с именем, содержащим `PARM` (например `SDFHPARM`, `DFHPARM`, `SDFHPARMU`), и если да — какие именно.
    


Ок, теперь всё ясно и хорошо: **PARMLIB у тебя есть**, это:

- `DFH620.CICS.ADFHPARM`
    

И “Member not found” означает, что **в этом PARMLIB действительно нет `DFHAPIR`** (по крайней мере под этим HLQ/версией).

При этом компилятор/translator **жёстко ожидает member `DFHAPIR`** → значит мы запускаем _не тот_режим/не тот translator-путь.

### Почему так бывает

`CBL CICS ...` включает **Integrated CICS translator**, который требует свой **API restriction/translator option member** `DFHAPIR` в CICS PARMLIB. На некоторых стендах этот member:

- лежит **в другом PARMLIB** (не `ADFHPARM`),
    
- или называется иначе/идёт в другом комплекте,
    
- или integrated translator **не установлен/не сконфигурирован**, но попытка его использовать остаётся.
    

---

# Самый быстрый рабочий обход (MVP): компилировать через DFHECP1 (external translator)

У тебя в `SDFHLOAD` есть `DFHECP1$` — это как раз CICS translator. Значит можно сделать “классический” 2-шаговый путь:

1. **DFHECP1** переводит `EXEC CICS` → в чистый COBOL
    
2. **IGYCRCTL PARM='SQL'** компилирует уже переведённый исходник + DB2 SQL coprocessor
    
3. **LKED** как мы уже сделали (DFHELII + CSQCSTUB)
    
4. **BIND PACKAGE** как в твоём job
    

Это почти всегда проходит даже там, где integrated translator “ломается” на PARMLIB.

---

## Что нужно поменять в твоих файлах прямо сейчас

### 1) Убрать `CICS` из первой строки исходника

Сделай первую строку так:

CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE

(Потому что CICS перевод будет делать отдельный шаг DFHECP1.)

### 2) Добавить шаг TRANSLATE перед COBOL compile

Новый шаг в JCL перед `//COBOL EXEC PGM=IGYCRCTL`:

- вход: `Z88011.CBL(LIBMQCIC)`
    
- выход: временный dataset `&&CICSTRN` (переведённый исходник)
    

Пример (минимальный):

//TRANSL   EXEC PGM=DFHECP1$,REGION=0M  
//STEPLIB  DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSIN    DD  DISP=SHR,DSN=Z88011.CBL(LIBMQCIC)  
//SYSLIN   DD  DSN=&&CICSTRN,UNIT=SYSALLDA,DISP=(,PASS),  
//             SPACE=(CYL,(1,1))  
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))

А потом в compile step заменить SYSIN на `&&CICSTRN`:

//SYSIN DD DSN=&&CICSTRN,DISP=(OLD,DELETE)

---

# Что я предлагаю сделать для тебя сейчас

Чтобы не править руками и не промахнуться с DDNAME’ами, я сделаю тебе **новый готовый job**:

- `CBLMQCIC_XLAT_DB2_MQ.jcl`
    
    - TRANSLATE DFHECP1$
        
    - COMPILE IGYCRCTL PARM='SQL'
        
    - LKED (DFHELII + CSQCSTUB)
        
    - BIND PACKAGE (исправленный STEPLIB)
        

И дам ссылку на скачивание.

Скажи только одно (чтобы я не гадал):  
в `SDFHLOAD` у тебя translator точно называется **`DFHECP1$`** (с долларом), как ты видел в листинге? Если да — я беру именно его.

  

да - DFH620.CICS.SDFHLOAD(DFHECP1$)

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — тогда делаем “правильный обход” через **внешний CICS translator `DFHECP1$`** (без зависимости от PARMLIB member `DFHAPIR`).

Я подготовил готовый job:

- Шаг 1: `DFHECP1$` переводит `EXEC CICS`
    
- Шаг 2: `IGYCRCTL PARM='SQL'` компилирует + DB2 SQL и пишет DBRM
    
- Шаг 3: LKED с `DFHELII` + `CSQCSTUB`
    
- Шаг 4: BIND PACKAGE (STEPLIB исправлен: без `(member)`)
    

Download CBLMQCIC_XLAT.jcl

### Важно про первую строку исходника

Раз ты используешь **DFHECP1$**, то в исходнике **не нужно** `CBL CICS ...`.

Оставь, например:

CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE

(или вообще можешь убрать `SQL` с первой строки, потому что он уже в JCL `PARM='SQL'`, но оставлять — ок.)

Если после запуска этого job прилетит ошибка линковки (не найден DFHELII или CSQCSTUB), просто скинь 5–10 строк из LKED SYSPRINT — подскажу, какой именно модуль/библиотека не резолвится. 

  

STMT NO. MESSAGE 2 IEFC019I MISPLACED DD STATEMENT

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 17s

`IEFC019I MISPLACED DD STATEMENT` означает: **в каком-то step’е DD идёт “не там”** — чаще всего потому что **JES не распознал строку `EXEC`**, и следующая строка `//... DD` оказалась “вне шага”.

### Самые частые причины (проверь у себя в job)

1. Перед `//TRANSL EXEC ...` или `//COBOL EXEC ...` есть **пробелы в колонке 1** (JCL должна начинаться строго с `//` в col 1–2).
    
2. В строке `EXEC` **нет ключевого слова `EXEC`** (опечатка/обрезалось).
    
3. Между `//TRANSL EXEC ...` и первым `//DD...` есть строка, начинающаяся с `//`, но **не являющаяся корректным JCL statement** (например, `//******` вместо `//*...`).
    

---

## Вторая проблема в моём “XLAT” job: DFHECP1$ обычно пишет в SYSPUNCH, не в SYSLIN

Для внешнего CICS translator `DFHECP1$` типовой DD для выходного переведённого исходника — **`SYSPUNCH`**, а не `SYSLIN`. Лучше исправить на канонический вариант — так меньше шансов на JCL/step-ошибки.

Вот “железобетонный” шаблон первых двух шагов (можешь прямо заменить у себя):

//TRANSL   EXEC PGM=DFHECP1$,REGION=0M  
//STEPLIB  DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSPUNCH DD  DSN=&&CICSTRN,UNIT=SYSALLDA,DISP=(,PASS),  
//             SPACE=(CYL,(1,1))  
//SYSIN    DD  DISP=SHR,DSN=Z88011.CBL(LIBMQCIC)  
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))  
//SYSUT2   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))  
  
//COBOL    EXEC PGM=IGYCRCTL,REGION=0M,PARM='SQL'  
//STEPLIB  DD  DSN=IGY640.SIGYCOMP,DISP=SHR  
//         DD  DSN=DSND10.DBDG.SDSNEXIT,DISP=SHR  
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//         DD  DSN=CEE.SCEERUN,DISP=SHR  
//         DD  DSN=CEE.SCEERUN2,DISP=SHR  
//SYSIN    DD  DSN=&&CICSTRN,DISP=(OLD,DELETE)  
//DBRMLIB  DD  DISP=SHR,DSN=Z88011.DBRMLIB(LIBMQCIC)  
//SYSLIB   DD  DSN=CSQ920.SCSQCOBC,DISP=SHR  
//         DD  DSN=Z88011.CBL,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSLIN   DD  DSN=&&LOADSET,UNIT=SYSALLDA,DISP=(MOD,PASS),  
//             SPACE=(CYL,(1,1))

**Важно:** убедись, что **каждая** из этих строк начинается с `//` **с первой колонки**, без пробелов слева.

---

## Чтобы я сказал точно, где ошибка у тебя

Пришли, пожалуйста, **первые ~15 строк job’а как он реально ушёл в JES** (Job card + начало TRANSL step).  
По `STMT 2` почти наверняка видно, что `EXEC` не распознался из-за форматирования (обычно пробелы/опечатка).

Если хочешь, я прямо сейчас перегенерирую тебе обновлённый файл `CBLMQCIC_XLAT.jcl` с `SYSPUNCH`и без спорных мест.

  





---

## 1) `TRANSL ... PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND`

Это сообщение **остаётся**, но обрати внимание:

- **TRANSL RC=00** (в статистике) ✅  
    Значит для `DFHECP1$` это **не фатально** (скорее warning/diagnostic). Translator отработал и дальше пошёл компайл.
    

➡️ На этом этапе **можно не зацикливаться**: оно не ломает job.

---

## 2) Реальная причина падения: `IEC130I SYSMDECK DD STATEMENT MISSING` → потом S0C4 в IGYCRCTL

Вот это уже критично:

- компилятор `IGYCRCTL` ожидает DD `SYSMDECK`
    
- DD нет → дальше он валится (у тебя даже S0C4)
    

### Как исправить (самое быстрое)

В шаг `//COBOL EXEC PGM=IGYCRCTL...` добавь:

//SYSMDECK DD DUMMY

или (как у тебя было в старом job):

//SYSMDECK DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))

**Я рекомендую для MVP `DD DUMMY`**, чтобы не плодить лишние датасеты/спейс.

---

## 3) Ещё одно: ты судя по JCL-листингу запускаешь НЕ “fixed” вариант

В твоём листинге снова есть опасные строки типа:

- `//********************************************************************` (это НЕ комментарий, должен быть `//*...`)
    
- в LKED у тебя:
    
    - `// DD *` (без DDNAME)
        

Это ровно те грабли, из-за которых у тебя раньше был `MISPLACED DD`.

➡️ Убедись, что ты реально запускаешь файл **`CBLMQCIC_XLAT_FIXED.jcl`**, который я дал, **или** приведи свой job к такому виду:

### В LKED должно быть так (обязательно!)

//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)  
//SYSIN    DD *  
  INCLUDE SYSLIB(DFHELII)  
  INCLUDE SYSLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)  
/*

а не `// DD *`.

---

## 4) Что делать прямо сейчас (минимальный “патч” твоего job)

1. В шаг `COBOL` добавь строку:
    

//SYSMDECK DD DUMMY

2. Проверь LKED: `//SYSIN DD *` и `/*` закрытие.
    
3. Комментарии: все “баннеры” делай как `//* ...`, а не `//****...`.
    

---

## 5) Про исходник: какая первая строка должна быть сейчас

Раз мы используем **DFHECP1$**, то в `LIBMQCIC` **НЕ нужно** `CBL CICS ...`.

Поставь первой строкой, например:

CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE

---


Да, теперь причина **на 100% понятна**: LKED не смог подтянуть **MQI stub**, поэтому у тебя неразрешённые внешние ссылки на `MQCONN/MQOPEN/MQGET/MQPUT/MQCLOSE/MQDISC`.

Ключевая строка:

> `MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY.`

Это значит: твой `INCLUDE SYSLIB(CSQCSTUB)` **не нашёл member `CSQCSTUB` ни в одной библиотеке, перечисленной в LKED.SYSLIB** (хотя `CSQ920.SCSQLOAD` у тебя подключён).

---

## 1) Что сделать (самый быстрый фикс)

### Шаг A — найти, где реально лежит `CSQCSTUB`

В ISPF 3.4 попробуй:

- `DSLIST` по `CSQ920.*`
    
- затем команда:
    
    - `M CSQCSTUB`
        

или открой member list для кандидатов:

- `CSQ920.SCSQLOAD`
    
- `CSQ920.SCSQAUTH`
    
- (если есть) `CSQ920.SCSQANL`, `CSQ920.SCSQxxxx`
    

Тебе нужно увидеть **member CSQCSTUB**.

> Очень часто stubs/authorized части лежат именно в **SCSQAUTH**, а не в SCSQLOAD.

### Шаг B — добавь правильную библиотеку в LKED.SYSLIB

Как только найдёшь, например что `CSQCSTUB` лежит в `CSQ920.SCSQAUTH`, добавь в LKED:

//         DD  DSN=CSQ920.SCSQAUTH,DISP=SHR

и оставь `INCLUDE SYSLIB(CSQCSTUB)` как есть.

После этого `MQCONN...` должны резолвиться.

---

## 2) Про сообщение `IEW2638S ... executable version exists ... cannot be replaced`

Это следствие того, что линковка собрала **неисполняемый** модуль (из-за unresolved). Когда stub подтянется и unresolved уйдут — это сообщение обычно **пропадает само**.

Если вдруг останется даже при “чистой” линковке, тогда просто:

- удали member `Z88011.LOAD(LIBMQCIC)` перед прогоном **или**
    
- линковку делай с `SYSLMOD DD DISP=OLD` (чтобы точно replace), но обычно удаление проще.
    

---

## 3) Важно: MQI stub для CICS ≠ batch stub

То, что твой batch job линковался с `CSQBSTUB` — для CICS так делать не надо. Правильная цель — именно **`CSQCSTUB`**, просто ты сейчас не попал в правильную либу.

---


Да — **этот job “находит” MQI**, потому что он линкуется **с другим stub’ом**:

- batch job использует: `INCLUDE SYSLIB(CSQBSTUB)`
    
- CICS job должен использовать: `INCLUDE SYSLIB(CSQCSTUB)`
    

У тебя `CSQBSTUB` **есть** в `CSQ920.SCSQLOAD`, поэтому batch линковка проходит.

А вот `CSQCSTUB` в **той же** `CSQ920.SCSQLOAD` у тебя, судя по ошибке binder, **не лежит** — поэтому CICS-линковка и валится с unresolved `MQCONN/MQOPEN/...`.

### Что это значит practically

- `CSQBSTUB` (batch) → ок, найден.
    
- `CSQCSTUB` (CICS) → **не найден в SCSQLOAD**, значит лежит в **другой библиотеке** (очень часто в `CSQ920.SCSQAUTH`).
    

---

## Что делать

1. В ISPF 3.4 открой member list для:
    
    - `CSQ920.SCSQAUTH` (и всех `CSQ920.SCSQ*`, которые видишь)
        
2. Найди member `CSQCSTUB`.
    
3. Когда найдёшь — добавь этот DSN в `LKED.SYSLIB` твоего CICS job **перед** `SCSQLOAD` (порядок обычно не критичен, но так привычнее).
    

Пример, если найдётся в `SCSQAUTH`:

//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR  
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//         DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//         DD  DSN=CSQ920.SCSQAUTH,DISP=SHR  
//         DD  DSN=CSQ920.SCSQLOAD,DISP=SHR

и оставить:

  INCLUDE SYSLIB(CSQCSTUB)

---

## Бонус: у batch job ещё одна ошибка (на будущее)

У тебя в BIND step:

//STEPLIB  DD  DSN=DSND10.SDSNLOAD(LIBMQTST),DISP=SHR

Так нельзя — `SDSNLOAD` указывается **без member**:

//STEPLIB  DD  DSN=DSND10.SDSNLOAD,DISP=SHR

---

Если ты пришлёшь список датасетов `CSQ920.SCSQ*` (что есть кроме `SCSQLOAD`/`SCSQCOBC`), я сразу скажу, где почти наверняка лежит `CSQCSTUB` и какой DSN добавить.

  

DSLIST - Data Sets Matching CSQ920.SCSQ* Member(s) found Command - Enter "/" to select action Message Volume ------------------------------------------------------------------------------- CSQ920.SCSQLOAD Member: CSQCSTUB VTMQ9C

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — значит `CSQCSTUB` **есть** именно в `CSQ920.SCSQLOAD`. Тогда причина unresolved **не в том, что member отсутствует**, а в том, что **binder не смог его INCLUDE’нуть** из “designated call library”.

Это почти всегда одна из двух вещей:

## 1) В LKED control cards `INCLUDE SYSLIB(CSQCSTUB)` реально не дошли до binder

У тебя раньше в листинге JCL было видно опасное место:

- `//SYSLIN DD ...`
    
- `// DD *` ← без DDNAME
    

Если control cards “поплыли”, binder мог вообще не увидеть `INCLUDE ...` и тогда MQxxxx остаются unresolved.

✅ Исправление: в LKED должно быть строго так:

//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)  
//SYSIN    DD  *  
  INCLUDE SYSLIB(DFHELII)  
  INCLUDE SYSLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)  
/*

Обрати внимание: **именно `SYSIN DD *`**, а не “`DD *` без имени”.

## 2) Binder “не видит” CSQ920.SCSQLOAD в SYSLIB именно для LKED

Хотя в твоём job оно было, но проверь две детали:

- DDNAME в LKED должен быть **SYSLIB**, и в нём должен быть `CSQ920.SCSQLOAD`
    
- строка должна быть **без опечаток** (DSN=..., DISP=SHR)
    

Пример правильного LKED блока:

//LKED     EXEC PGM=IEWBLINK,COND=(8,LT,COBOL),REGION=0M  
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR  
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//         DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//         DD  DSN=CSQ920.SCSQLOAD,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))  
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)  
//SYSIN    DD  *  
  INCLUDE SYSLIB(DFHELII)  
  INCLUDE SYSLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)  
/*  
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQCIC),DISP=SHR

---

# Что сделать сейчас (минимальный практический шаг)

1. Открой в spool **полный SYSPRINT шага LKED** и проверь, печатает ли он твои control cards (обычно binder в листинге показывает входные statements).
    
2. Если там **нет строк `INCLUDE SYSLIB(CSQCSTUB)`** — значит они не попали (проблема #1).
    
3. Если они есть, но всё равно unresolved — пришли первые ~30 строк LKED SYSPRINT до ошибок, там будет видно, какие именно библиотеки binder реально принял как SYSLIB.
    

---

Если хочешь без разборов: просто возьми мой **CBLMQCIC_XLAT_FIXED.jcl** и в нём проверь/оставь LKED секцию ровно как выше. Судя по твоей находке, **этого должно хватить**, и unresolved MQxxxx уйдут.

  

1z/OS V3 R1 BINDER 09:19:08 SATURDAY APRIL 4, 2026 BATCH EMULATOR JOB(CBLMQCIX) STEP(LKED ) PGM= IEWBLINK IEW2456E 9207 SYMBOL MQCONN UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2456E 9207 SYMBOL MQOPEN UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2456E 9207 SYMBOL MQGET UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2456E 9207 SYMBOL MQPUT UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2456E 9207 SYMBOL MQCLOSE UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2456E 9207 SYMBOL MQDISC UNRESOLVED. MEMBER COULD NOT BE INCLUDED FROM THE DESIGNATED CALL LIBRARY. IEW2638S 5384 AN EXECUTABLE VERSION OF MODULE *NULL* EXISTS AND CANNOT BE REPLACED BY THE NON-EXECUTABLE MODULE JUST CREATED. *** O P E R A T I O N S U M M A R Y R E P O R T *** 1PROCESSING OPTIONS: ALIASES NO ALIGN2 NO AMODE UNSPECIFIED CALL YES CASE UPPER COMPAT UNSPECIFIED COMPRESS AUTO DCBS NO DYNAM NO EXTATTR UNSPECIFIED EXITS: NONE FILL NONE GID UNSPECIFIED HOBSET NO INFO NO LET 04 LINECT 060 LIST SUMMARY LISTPRIV NO LONGPARM NO MAP NO MAXBLK 032760 MODMAP NO MSGLEVEL 00 OVLY NO PRINT YES RES NO REUSABILITY UNSPECIFIED RMODE UNSPECIFIED RMODEX NO SIGN NO STORENX NOREPLACE STRIPCL NO STRIPSEC NO SYMTRACE TERM NO TRAP ON UID UNSPECIFIED UPCASE NO WKSPACE 000000K,000000K XCAL NO XREF NO ***END OF OPTIONS*** *** E N D O F O P E R A T I O N S U M M A R Y R E P O R T *** 1z/OS V3 R1 BINDER 09:19:08 SATURDAY APRIL 4, 2026 BATCH EMULATOR JOB(CBLMQCIX) STEP(LKED ) PGM= IEWBLINK IEW2008I 0F03 PROCESSING COMPLETED. RETURN CODE = 12. 1---------------------- MESSAGE SUMMARY REPORT ---------------------- TERMINAL MESSAGES (SEVERITY = 16) NONE SEVERE MESSAGES (SEVERITY = 12) 2638 ERROR MESSAGES (SEVERITY = 08) 2456 WARNING MESSAGES (SEVERITY = 04) NONE INFORMATIONAL MESSAGES (SEVERITY = 00) 2008 **** END OF MESSAGE SUMMARY REPORT ****

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 36s

Супер, что ты нашёл `CSQCSTUB` в `CSQ920.SCSQLOAD` — значит проблема **не “нет модуля”**, а что **binder его не включает**.

По твоему LKED-логу видно два факта:

1. `MQCONN/MQOPEN/...` **UNRESOLVED** ⇒ `CSQCSTUB` **не был реально подлинкован**
    
2. `IEW2638S ... STORENX NOREPLACE` ⇒ в `Z88011.LOAD(LIBMQCIC)` уже есть исполняемый модуль, а текущая сборка получается “неисполняемой” из-за unresolved и binder **не может перезаписать**.
    

Ниже — самый надёжный фикс (и он обычно “убивает” обе проблемы).

---

## ✅ Fix 1: В LKED использовать отдельный DDNAME для MQ stub (не через SYSLIB)

Иногда `INCLUDE SYSLIB(...)` в сочетании с concatenation ведёт себя не так, как ожидаешь (особенно на стендах/с program objects). Самый надёжный способ — дать библиотеку MQ отдельным DD и INCLUDE от него.

**LKED step сделай так:**

//LKED     EXEC PGM=IEWBLINK,REGION=0M,PARM='LIST,LET,MAP,STORENX=REPLACE'  
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR  
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//CICSLIB  DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//MQLIB    DD  DSN=CSQ920.SCSQLOAD,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))  
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)  
//SYSIN    DD  *  
  INCLUDE CICSLIB(DFHELII)  
  INCLUDE MQLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)  
/*  
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQCIC),DISP=SHR

Ключевые изменения:

- `CICSLIB` и `MQLIB` — отдельные DDNAME
    
- `INCLUDE MQLIB(CSQCSTUB)` — без “designated call library” двусмысленности
    
- `PARM=...STORENX=REPLACE` — чтобы убрать `IEW2638S` (разрешить replace)
    

---

## ✅ Fix 2: если всё равно увидишь IEW2638S

Самый простой “ручной” способ:

- удали member `Z88011.LOAD(LIBMQCIC)` перед линковкой (или переименуй)
    
- затем снова LKED
    

Но обычно `STORENX=REPLACE` уже решает.

---

## Почему это должно сработать

Потому что сейчас binder явно говорит: _“member could not be included from designated call library”_ — т.е. он **не смог включить CSQCSTUB через тот механизм, которым ты его подключал**.  
Когда ты даёшь `MQLIB DD DSN=...` и делаешь `INCLUDE MQLIB(CSQCSTUB)`, путь становится прямым и однозначным.

---

## Быстрый контроль после прогона

В LKED SYSPRINT должно исчезнуть:

- все `IEW2456E 9207 SYMBOL MQ... UNRESOLVED`
    

и RC станет **0** (или максимум 4 из-за предупреждений, но не 12).

---

Если хочешь — кинь свой текущий LKED JCL-блок (5–15 строк), я верну его в готовом виде “как вставить” без риска сломать остальные шаги.

  

![Hochgeladenes Bild](https://chatgpt.com/backend-api/estuary/content?id=file_00000000721072468d9d3730178803be&ts=493167&p=fs&cid=1&sig=c2d5d5cf20627f195d124fc8b8985058b14fb71a6075679080eb7cc3cda05449&v=0)

как правельно перенести строку в JCL:

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

В JCL “перенос строки” делается не как в языках программирования, а **просто продолжаешь statement на следующей строке**, соблюдая 2 правила:

1. **все строки statement должны начинаться с `//` в колонке 1**
    
2. **имя шага/ DDNAME указываешь только в первой строке**, а на продолжениях ставишь `//` + пробелы (без имени)
    

Для твоего случая (длинный `PARM=`) делай так:

//LKED     EXEC PGM=IEWBLINK,REGION=0M,  
//             PARM='LIST,LET,MAP,STORENX=REPLACE'

Это самый простой и правильный вариант.

### Если PARM ещё длиннее

Можно дробить и на 3 строки:

//LKED     EXEC PGM=IEWBLINK,REGION=0M,  
//             PARM='LIST,LET,MAP',  
//             'STORENX=REPLACE'

(Внутри апострофов это одна строка параметров для IEWBLINK; второй вариант с двумя строками в кавычках обычно тоже проходит, но первый вариант предпочтительнее.)

### 1) Binder **вообще не видит твои CICSLIB/MQLIB**

Смотри блок:

*** DATA SET SUMMARY ***  
SYSLIB 01 CEE.SCEELKED  
SYSLIB 02 DSND10.SDSNLOAD  
SYSLIN 01 ...

Там **нет** ни `DFH620.CICS.SDFHLOAD`, ни `CSQ920.SCSQLOAD`.

➡️ Значит, в твоём JCL строки

//CICSLIB DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//MQLIB   DD DSN=CSQ920.SCSQLOAD,DISP=SHR

**не попали как DD в шаг LKED** (или были написаны так, что JES их не распознал как DD этого шага).

99% случаев: **они не в колонке 1** (есть пробелы слева) или между ними и `//LKED EXEC` есть “плохие” строки `//*****` без `//*`.

---

## 2) У тебя неправильный синтаксис STORENX

Ошибка:

`IEW2292E OPTION VALUE MISSING OR INVALID FOR OPTION STORENX.`

В binder **не принимается** `STORENX=REPLACE` в таком виде.

Самый безопасный вариант:

- вообще **убери STORENX** и решай replace через DISP/удаление member’а
    
- или используй **правильный параметр для замены**: `REPLACE` (как опция), а не `STORENX=...`
    

Для IEWBLINK обычно достаточно:

//LKED EXEC PGM=IEWBLINK,REGION=0M,PARM='LIST,LET,MAP,REPLACE'

---

# Как должно выглядеть (канонический LKED step)

Скопируй **в точности**, без пробелов перед `//`:

//LKED     EXEC PGM=IEWBLINK,REGION=0M,PARM='LIST,LET,MAP,REPLACE'  
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR  
//         DD  DSN=DSND10.SDSNLOAD,DISP=SHR  
//CICSLIB  DD  DSN=DFH620.CICS.SDFHLOAD,DISP=SHR  
//MQLIB    DD  DSN=CSQ920.SCSQLOAD,DISP=SHR  
//SYSPRINT DD  SYSOUT=*  
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))  
//SYSLIN   DD  DSN=&&LOADSET,DISP=(OLD,DELETE)  
//SYSIN    DD  *  
  INCLUDE CICSLIB(DFHELII)  
  INCLUDE MQLIB(CSQCSTUB)  
  ENTRY  LIBMQCIC  
  NAME   LIBMQCIC(R)  
/*  
//SYSLMOD  DD  DSN=Z88011.LOAD(LIBMQCIC),DISP=SHR

### Проверка, что всё “подцепилось”

В следующем LKED SYSPRINT в `DATA SET SUMMARY` ты обязан увидеть:

- `CICSLIB ... DFH620.CICS.SDFHLOAD`
    
- `MQLIB ... CSQ920.SCSQLOAD`
    

И ошибки `MQCONN UNRESOLVED` + `DFHEI1 UNRESOLVED` исчезнут.

---

# Почему ещё возник `DFHEI1 UNRESOLVED`

`DFHEI1` — это как раз CICS runtime символ/entry, который закрывается через **DFHELII** и CICS loadlib. Раз binder не видел `DFH620.CICS.SDFHLOAD`, он и не мог это подтянуть.

---

Отлично — **это успех**. Ты нашёл рабочий путь, который обходит проблему `BINDADD` на `BIND PACKAGE`.

### Что произошло и почему это сработало

Ты сделал:

BIND PLAN(Z88011) PKLIST(Z88011.*) MEMBER(LIBMQCIC) ...

DB2 в таком режиме **конвертирует DBRM в PACKAGE автоматически** (“DBRMS ARE CONVERTED INTO PACKAGES BEFORE BIND PLAN…”), и создал package в коллекции:

- `ZXPDB2.DSN_DEFAULT_COLLID_Z88011.LIBMQCIC.()`
    

и затем успешно сделал:

- `BIND FOR PLAN Z88011 SUCCESSFUL`
    

То есть теперь у тебя есть:

- **PACKAGE** для `LIBMQCIC`
    
- **PLAN Z88011**, который его включает
    
- и всё это прошло под твоими правами (видимо, на план у тебя есть нужная authority, а на “чистый” BINDADD в коллекции `ZXPDB2.Z88011` — нет).
    

### Про предупреждения

- `MEMBER option is deprecated` — просто предупреждение (старый стиль “bind plan from DBRM member”). На MVP можно игнорировать.
    
- `BIND WARNING ... DBRMS ARE CONVERTED INTO PACKAGES...` — информационное.
    

---

## Что делать дальше (чтобы CICS реально запустил программу)

1. **Запомни план**, который должен использоваться при выполнении SQL под CICS:
    

- теперь это `PLAN(Z88011)` (как в логе)
    

2. В CICS/DB2 attachment надо убедиться, что регион использует план, который включает твой пакет. В зависимости от настройки стенда это может быть:
    

- общий план региона (часто фиксированный), или
    
- “thread plan”/dynamic plan, или
    
- вызов через DSN statement в RCT (зависит от конфигурации).
    

Для быстрой проверки: когда запустишь транзакцию и увидишь DB2 `-805`, это будет означать “CICS выполняет под другим plan”. Тогда надо согласовать plan в настройке CICS-DB2.

---

## Рекомендую зафиксировать в твоём compile job

В шаге BIND вместо `BIND PACKAGE...` сделай ровно то, что сработало:

DSN SYSTEM(DBDG)  
BIND PLAN(Z88011) PKLIST(Z88011.*) ACTION(REPLACE) ISO(CS) ENCODING(EBCDIC)  
END

(И больше не мучиться с `BINDADD`.)

---

Если хочешь — следующий шаг я оформлю как “mini-runbook”:

- какие CICS ресурсы создать (`PROGRAM LIBMQCIC`, `TRANSACTION LIBT`)
    
- как проверить в CICS, что DB2 attach активен
    
- как быстро понять по ошибке `-805/-811` какой plan реально используется, и куда его менять.
    

  

сделай Если хочешь — следующий шаг я оформлю как “mini-runbook”: • какие CICS ресурсы создать (PROGRAM LIBMQCIC, TRANSACTION LIBT) • как проверить в CICS, что DB2 attach активен • как быстро понять по ошибке -805/-811 какой plan реально используется, и куда его менять.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — оформил mini-runbook в отдельный файл.

Download mini_runbook_cics_libmqcic.md 

  

я стартовал уже cemt - как мне теперь вызвать ceda

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Если ты уже в CICS и у тебя открыт **CEMT**, то вызвать **CEDA** проще всего так же, как любую транзакцию:

### Вариант 1 (самый простой)

1. Нажми **Clear** (или введи `CEBR`/другую команду, чтобы очистить экран)
    
2. Введи в командной строке:
    

CEDA

и Enter.

### Вариант 2 (если ты в “CEMT transaction display” и не выходит)

- Нажми **PF3 (End)** один/несколько раз, чтобы выйти из экранов CEMT обратно на “чистый” CICS экран,
    
- затем введи:
    

CEDA

### Если пишет “NOT AUTHORIZED” или “TRANSACTION NOT FOUND”

Это значит одно из двух:

- тебе **не разрешена** транзакция CEDA (часто так и бывает),
    
- или CEDA не установлена/переименована в этом регионе.
    

Тогда попробуй альтернативы (иногда разрешают только просмотр):

CEDA I GROUP(…)  
CEDA I PROGRAM(LIBMQCIC)

Если и это не пускает — пришли точное сообщение (DFH… / NOTAUTH / NOTFND), и я скажу, что просить у админа (обычно доступ на транзакцию CEDA + права на группу).

  

ENTER ONE OF THE FOLLOWING ADd ALter APpend CHeck COpy DEFine DELete DIsplay Expand Install Lock Move REMove REName UNlock USerdefine View SYSID=S750 APPLID=CXZ88011 DSN=Z88011.CICS.DFHCSD PF 1 HELP 3 END 6 CRSR 9 MSG 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Ты уже **в CEDA** ✅ (это главное).

Экран “ENTER ONE OF THE FOLLOWING (ADD / ALTER / DEFINE / INSTALL …)” — это **главное меню CEDA**.

Дальше тебе нужно сделать **две вещи**: определить `PROGRAM(LIBMQCIC)` и `TRANSACTION(LIBT)`, потом **INSTALL**.

---

## 1) Определить PROGRAM(LIBMQCIC)

1. Введи (в командной строке CEDA):
    

DEFine PROGram(LIBMQCIC) GROup(Z88011)

(или выбери **DEFine** из меню и дальше введи тип/имя/группу)

2. На панели атрибутов задай минимум:
    

- **Language** = `COBOL`
    
- **Execution key** = обычно `USER` (для MVP)
    
- Остальное можно оставить дефолтным
    

3. Сохрани (Enter).
    

---

## 2) Определить TRANSACTION(LIBT)

1. В командной строке:
    

DEFine TRANsaction(LIBT) PROGram(LIBMQCIC) GROup(Z88011)

2. На панели атрибутов проверь/задай минимум:
    

- **Program** = `LIBMQCIC`
    
- **Profile** = дефолт
    
- **Taskdata key** / **Storage** = дефолт (MVP)
    

Сохрани (Enter).

---

## 3) INSTALL (чтобы реально заработало)

После DEFINE сделай:

INStall PROGram(LIBMQCIC)  
INStall TRANsaction(LIBT)

Потом быстрая проверка через CEMT:

CEMT I PROG(LIBMQCIC)  
CEMT I TRANS(LIBT)

---

## Важный момент, который может остановить запуск

CICS должен **видеть load module** `LIBMQCIC` в одном из DFHRPL (runtime loadlibs).  
Если при INSTALL/запуске LIBT получишь ошибки типа “program not found / not in DFHRPL” — тогда нужно либо:

- добавить `Z88011.LOAD` в DFHRPL (обычно админ), либо
    
- скопировать member `LIBMQCIC` в уже разрешённый DFHRPL loadlib.
    

---

Если хочешь, напиши: **какую группу лучше использовать** (у тебя на экране видно `DSN=Z88011.CICS.DFHCSD`, значит свой CSD у тебя есть — скорее всего группа `Z88011` подходит).  
Или просто выполни команды выше — и пришли, если CEDA покажет какое-то DFH-сообщение при DEFINE/INSTALL.

  

DEFine PROGram(LIBMQCIC) GROup(Z88011) OVERTYPE TO MODIFY CICS RELEASE = 0750 CEDA DEFine PROGram( LIBMQCIC ) PROGram : LIBMQCIC Group : Z88011 DEScription ==> Language ==> CObol | Assembler | Le370 | C | Pli RELoad ==> No No | Yes RESident ==> No No | Yes USAge ==> Normal Normal | Transient USElpacopy ==> No No | Yes Status ==> Enabled Enabled | Disabled RSl : 00 0-24 | Public CEdf ==> Yes Yes | No DAtalocation ==> Any Below | Any EXECKey ==> User User | Cics COncurrency ==> Quasirent Quasirent | Threadsafe | Required Api ==> Cicsapi Cicsapi | Openapi REMOTE ATTRIBUTES DYnamic ==> No No | Yes I New group Z88011 created. SYSID=S750 APPLID=CXZ88011

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — **PROGRAM уже определён**, и CEDA даже создал новую группу `Z88011` ✅

Что сделать на этой панели:

## 1) Заполни обязательное поле `Language`

Сейчас `Language ==>` пустое — его нужно поставить в **Cobol**:

- в поле **Language** введи:
    

Cobol

(можно просто `CObol` как в подсказке — регистр не важен)

Остальные значения для MVP можно оставить как есть:

- `RELoad No`, `RESident No`, `Status Enabled`, `EXECKey User` — ок.
    

Нажми **Enter**.

---

## 2) Сохранить определение (в CSD)

После Enter CEDA обычно покажет подтверждение/вернёт в меню.

Если попросит “confirm” — подтверди.

---

## 3) Установить PROGRAM в регион (INSTALL)

На командной строке CEDA:

INStall PROGram(LIBMQCIC)

---

## 4) Дальше — определить TRANSACTION

Потом:

DEFine TRANsaction(LIBT) PROGram(LIBMQCIC) GROup(Z88011)

и после сохранения:

INStall TRANsaction(LIBT)

---

## Если на INSTALL будет ошибка “program not found”

Это значит, что CICS не находит load module `LIBMQCIC` в DFHRPL. Тогда решение одно из:

- добавить `Z88011.LOAD` в DFHRPL (обычно админ),
    
- или скопировать `LIBMQCIC` в уже подключённый DFHRPL loadlib.
    

---

Сделай сейчас **Language=Cobol → Enter**, затем `INSTALL PROGRAM(LIBMQCIC)` и пришли, что ответил CEDA (DFH… сообщение).

  

INStall PROGram(LIBMQCIC) OVERTYPE TO MODIFY CEDA Install ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> LIBrary ==> LSrpool ==> S GROUP or LIST must be specified. SYSID=S750 APPLID=CXZ88011 DSN=Z88011.CICS.DFHCSD F 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Ты попал на **общую панель INSTALL**, и она говорит правильно:

> **“GROUP or LIST must be specified.”**

То есть CEDA ждёт, _что именно_ инсталлировать — по группе или по списку ресурсов.

## Самый простой способ: INSTALL по группе

В командной строке (наверху) введи:

INStall GROup(Z88011)

Нажми Enter — CICS установит **все ресурсы**, которые ты определил в группе `Z88011` (сейчас там хотя бы PROGRAM).

## Если хочешь инсталлировать только один PROGRAM

Есть два рабочих варианта:

### Вариант A (через список)

1. Сначала сделай список:
    

DIsplay PROGram(LIBMQCIC)

2. Затем:
    

INStall LIST

(на практике CEDA делает “LIST” как текущий список из Display)

### Вариант B (коротко через команду INSTALL PROGRAM + GROUP)

Некоторые системы принимают так:

INStall PROGram(LIBMQCIC) GROup(Z88011)

Но раз тебя уже перекинуло на “Install panel”, проще и надёжнее — `INSTALL GROUP(Z88011)`.

---

## Следующий шаг после INSTALL

Проверь в CEMT:

CEMT I PROG(LIBMQCIC)

Если увидишь “NOT FOUND” или “DISABLED”, скажи сообщение — подскажу, что поправить (обычно DFHRPL / loadlib).

Хочешь — сразу после этого перейдём к `DEFINE TRANSACTION(LIBT)` и тоже `INSTALL GROUP(Z88011)`второй раз.

  

INStall GROup(Z88011) OVERTYPE TO MODIFY CEDA Install ALl ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> LIBrary ==> SYSID=S750 APPLID=CXZ88011 INSTALL SUCCESSFUL DSN=Z88011.CICS.DFHCSD F 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — **PROGRAM(LIBMQCIC) установлен в регион** ✅ (`INSTALL SUCCESSFUL`).

Теперь следующий шаг — **создать и установить транзакцию `LIBT`**, которая будет запускать `LIBMQCIC`.

---

## 1) В CEDA определить TRANSACTION(LIBT)

В командной строке CEDA введи:

DEFine TRANsaction(LIBT) GROup(Z88011)

На панели атрибутов заполни минимум:

- **PROGram** ⇒ `LIBMQCIC`
    
- Остальное оставь по умолчанию (для MVP)
    

Нажми Enter, чтобы сохранить.

---

## 2) Установить транзакцию (INSTALL)

Самый простой способ — снова по группе:

INStall GROup(Z88011)

(установит и транзакцию тоже; program уже установлен — это ок.)

---

## 3) Проверка через CEMT

Выйди/перейди в CEMT и проверь:

CEMT I PROG(LIBMQCIC)  
CEMT I TRANS(LIBT)

---

## 4) Первый запуск (ручной MVP)

На “чистом” CICS экране просто введи:

LIBT

Если CICS скажет **program not found** / **not in DFHRPL** — значит loadlib не виден региону (тогда будем решать DFHRPL).  
Если получишь **DB2 -805** — значит plan для CICS не включает твой package (тогда будем настраивать DB2ENTRY/DB2TRAN/plan).

Сделай сейчас `DEFINE TRANSACTION(LIBT)` и пришли, что на панели CEDA попросит заполнить (там обычно 1–2 обязательных поля).

  

INStall GROup(Z88011) OVERTYPE TO MODIFY CEDA Install ALl ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> LIBrary ==> SYSID=S750 APPLID=CXZ88011 INSTALL SUCCESSFUL DSN=Z88011.CICS.DFHCSD F 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — группа `Z88011` снова **успешно установилась** ✅

Но важный момент: **INSTALL не создаёт транзакцию сам по себе**. Он устанавливает то, что **уже определено** в CSD в этой группе. Поэтому сейчас следующий шаг — убедиться, что в группе действительно есть **TRANSACTION(LIBT)**.

## 1) Проверь, что TRANSACTION(LIBT) вообще определён

В командной строке CEDA:

DIsplay TRANsaction(LIBT)

### Если покажет экран атрибутов транзакции — значит LIBT есть

Тогда сразу проверь, что `PROGRAM` = `LIBMQCIC`.

### Если скажет NOT FOUND

Тогда надо её создать:

DEFine TRANsaction(LIBT) GROup(Z88011)

На панели заполни минимум:

- `PROGram ==> LIBMQCIC`
    

Enter → сохранить.

После этого снова:

INStall GROup(Z88011)

## 2) Проверка через CEMT

В CEMT:

CEMT I TRANS(LIBT)  
CEMT I PROG(LIBMQCIC)

## 3) Запуск

На чистом CICS экране просто введи:

LIBT

Если пришлёшь результат `DISPLAY TRANSACTION(LIBT)` (покажет или not found), я скажу следующий точный шаг без вариантов.

  

DIsplay TRANsaction(LIBT) ENTER COMMANDS NAME TYPE GROUP LAST CHANGE LIBT TRANSACTION Z88011 04/04/26 12:10:11 SYSID=S750 APPLID=CXZ88011 RESULTS: 1 TO 1 OF 1 DSN=Z88011.CICS.DFHCSD F 1 HELP 2 SIG 3 END 4 TOP 5 BOT 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — **TRANSACTION LIBT существует** и лежит в группе `Z88011` ✅

Теперь нужно проверить **на что она ссылается** (какую PROGRAM запускает) и что она реально установлена/включена.

## 1) Посмотреть детали транзакции (чтобы увидеть PROGRAM)

На этом экране (список результатов) сделай так:

- Поставь `S` слева от строки `LIBT` (или `X` — зависит от настроек CEDA) и Enter  
    _(в CEDA “Display list” обычно `S` = показать детали выбранного ресурса)_
    

Если `S` не работает, попробуй:

- `B` (browse) или просто Enter с курсором на строке.
    

Там на панели атрибутов ищи поле:

- **PROGram ==> ...**  
    Оно должно быть: **`LIBMQCIC`**.
    

## 2) Проверить, что транзакция установлена

В CEMT:

CEMT I TRANS(LIBT)

Должно быть `ENABLED`.

## 3) Запуск (ручной MVP)

На чистом CICS экране просто введи:

LIBT

### Если будет ошибка

- **“Program not found / not in DFHRPL”** → CICS не видит load module `LIBMQCIC` (нужно DFHRPL/копирование в RPL).
    
- **DB2 SQLCODE -805** → CICS DB2 thread использует другой PLAN, не `Z88011`.
    
- **MQCONN / MQOPEN RC=…** → проблема MQ attach/очереди/авторизация.
    

Сделай шаг 1 (открой детали LIBT и посмотри PROGRAM). Напиши, что стоит в `PROGram ==>` — и дальше скажу, что именно править (если не `LIBMQCIC`).

  

CEMT I TRANS(LIBT) STATUS: RESULTS - OVERTYPE TO MODIFY Tra(LIBT) Pri( 001 ) Pro(LIBMQCIC) Tcl( DFHTCL00 ) Ena Sta Pur Prf(DFHCICST) Uda Any Iso Bac Wai SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 15.17.41 DATE: 04/04/26 PF 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — **транзакция LIBT активна и правильно привязана** ✅

Ты видишь:

- `Tra(LIBT) ... Pro(LIBMQCIC) ... Ena`
    
- `RESPONSE: NORMAL`
    

То есть:

- транзакция **ENABLED**
    
- запускает **LIBMQCIC**
    
- CICS её “видит” и принимает
    

## Следующий шаг: запустить LIBT

Выйди на “чистый” CICS экран (Clear / PF3 несколько раз) и просто введи:

LIBT

### Что дальше может случиться (и что это значит)

1. **Если сразу вернётся без сообщений** — программа стартовала и, скорее всего, сделала MQGET NO-WAIT и не нашла сообщений (это ок).
    
2. **DFH… “program not found / load fail”** — CICS не может загрузить `LIBMQCIC` из DFHRPL (нужно добавить `Z88011.LOAD` в DFHRPL или скопировать модуль в RPL-библиотеку).
    
3. **MQCONN/MQOPEN RC=xxxx** — проблема MQ attach/очередей/прав (в этом случае пришли RC).
    
4. **DB2 SQLCODE -805** — CICS использует не тот DB2 plan (нужно настроить DB2ENTRY/DB2TRAN на план `Z88011` или пересобрать пакет под план региона).
    

## Чтобы тест был “не пустой”

Перед запуском `LIBT` положи 1 сообщение в `LIB.REQ.Q` (как делает Spring Boot).  
Потом `LIBT` должен обработать одно сообщение и положить ответ в `LIB.REP.Q`.

Сделай запуск и пришли, что появилось на экране/в сообщениях (лучше 2–3 строки DFH… или RC/SQLCODE) — дальше скажу точный следующий фикс.

  

оригинальная батч программа читала параметры из джоба, как мы их передадим в CICS?

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

В batch ты передавал параметры через **SYSIN** (QMGR, имена очередей, WAIT_MS). В CICS **SYSIN нет**, поэтому параметры обычно делают одним из этих способов (по скорости MVP → по “правильности”):

## MVP-вариант 1 (самый быстрый): хардкод + потом вынести

Для первого запуска в CICS оставь в `LIBMQCIC`:

- `WS-REQ-QUEUE = 'LIB.REQ.Q'`
    
- `WS-REP-QUEUE = 'LIB.REP.Q'`
    
- `WS-QMGR-NAME = SPACES` (по умолчанию, MQCONN к default QM)
    

Это уже есть у тебя как MVP-схема. Минус: менять — только пересборкой.

---

## MVP-вариант 2 (быстро и “по-CICS”): параметры в COMMAREA (через transaction)

Если ты хочешь передавать параметры “как SYSIN”, но вручную/скриптом:

1. В CICS определяешь `TRANSACTION(LIBT)` с **COMMAREA length**, например 100.
    
2. Запускаешь транзакцию через `EXEC CICS START TRANS
    

  

//LIBMQTST JOB (ACCT),'RUN LIBMQTST', // CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID //*-------------------------------------------------------------* //* Run MQ+DB2 test LIBMQTST (XML -> copybook -> DB2) //* Tokens replaced by Ansible: //* HLQ, COBLOAD, MQLOAD, DB2LOAD, //* SYSIN (QMGR/REQ/RPLY/WAIT_MS) //*-------------------------------------------------------------* //VARS SET HLQ=Z88011 // SET DB2LOAD=DSND10.SDSNLOAD // SET COBLOAD=&HLQ..LOAD // SET MQLOAD=CSQ920.SCSQLOAD //*-------------------------------------------------------------* //RUN EXEC PGM=IKJEFT01 //STEPLIB DD DSN=&COBLOAD,DISP=SHR // DD DSN=&MQLOAD,DISP=SHR // DD DSN=&DB2LOAD,DISP=SHR //REPORT DD SYSOUT=* //SYSTSIN DD *,SYMBOLS=CNVTSYS DSN SYSTEM(DBDG) RUN PROGRAM(LIBMQTST) PLAN(&SYSUID) LIB('&SYSUID..LOAD') END //SYSIN DD DUMMY //SYSUDUMP DD DUMMY //CEEDUMP DD DUMMY //SYSTSPRT DD SYSOUT=* //SYSPRINT DD SYSOUT=* //SYSOUT DD SYSOUT=*,OUTLIM=15000 //PARAMS DD * QMGR=CSQ9 REQ=Z88011.MQZ3.QLOCAL RPLY=Z88011.MQZ3.REPLYTO.QLOCAL WAIT_MS=30000 /* //*

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Понял — в batch ты фактически передавал параметры не через `SYSIN`, а через **DD `PARAMS` с in-stream данными** (QMGR/REQ/RPLY/WAIT_MS), а программа читала их как sequential file (`PARAMSFILE`).

В CICS такой DD из JCL ты “на лету” не подсунешь. Значит, параметры надо перенести в один из стандартных CICS-механизмов. Ниже — варианты **в порядке “самый быстрый MVP” → “правильно на будущее”** и как это маппится на твой текущий набор параметров.

---

## Вариант A (самый быстрый MVP): захардкодить в программе

Для первого запуска CICS (ручной `LIBT`) это реально самый быстрый путь:

- `QMGR` = `'CSQ9'` или SPACES (default QM)
    
- `REQ` = `'Z88011.MQZ3.QLOCAL'`
    
- `RPLY` = `'Z88011.MQZ3.REPLYTO.QLOCAL'`
    
- `WAIT_MS` = `0` (поскольку в CICS MVP мы делаем MQGET NO-WAIT)
    

Плюсы: работает сразу.  
Минус: менять — только перекомпиляция.

---

## Вариант B (MVP+, “как SYSIN”, но по-CICS): таблица параметров в VSAM/TSQ и чтение при старте

Ты делаешь “параметрический файл” один раз, а CICS программа его читает:

### B1) TSQ (Temporary Storage Queue)

- Один TSQ, например `LIBM` или `LIBMQCFG`
    
- В нём хранить текст вида:
    
    QMGR=CSQ9  
    REQ=...  
    RPLY=...  
    WAIT_MS=...
    
- Программа в начале делает `EXEC CICS READQ TS ...` и парсит.
    

Плюсы: очень быстро реализовать, не нужен админ VSAM.  
Минусы: TSQ может чиститься, это не “конфиг навсегда”.

### B2) VSAM KSDS (постоянно)

- VSAM dataset с ключом, например `ENV=DEV`, значением “параметры”
    
- Программа читает через `EXEC CICS READ FILE(...)`
    

Плюсы: “правильно” и устойчиво.  
Минус: нужно определить FILE ресурс и сам VSAM.

---

## Вариант C (самый “правильный” для CICS): COMMAREA / Channels & Containers

Если параметры нужны **на каждый запуск** или хочешь иметь несколько конфигураций:

- Создаёшь маленькую “driver” программу/транзакцию, которая:
    
    - принимает COMMAREA/Container (qmgr/req/rply/wait)
        
    - `EXEC CICS LINK PROGRAM('LIBMQCIC') COMMAREA(...)`
        
- А `LIBMQCIC` читает параметры из COMMAREA вместо PARAMS DD.
    

Плюсы: гибко, можно запускать разные очереди/кью-менеджеры.  
Минус: для ручного запуска с терминала неудобнее (нужен драйвер/старт через START).

---

## Вариант D (CICS MQ Triggering, stage 2): параметры в MQMD / in message

Когда перейдёшь к CKTI/triggering:

- `REQ/RPLY/QMGR` обычно фиксируются конфигом региона
    
- А “переменные” можно класть в payload или headers
    

---

# Что я бы сделал для твоего текущего плана (manual MVP → CKTI)

1. **Сейчас (manual MVP)**:
    
    - убрать чтение `PARAMSFILE` совсем
        
    - задать `REQ/RPLY/QMGR` в WS (или через TSQ, если хочешь без перекомпиляции)
        
    - `WAIT_MS` для CICS поставить 0 / не использовать (NO-WAIT)
        
2. **Потом (автоматизация CKTI)**:
    
    - `REQ/RPLY/QMGR` сделать config на уровне региона (TSQ/VSAM)
        
    - CKTI будет просто стартовать LIBT, а LIBMQCIC читает конфиг.
        

---

## Конкретно по твоему batch JCL (PARAMS DD)

Твои поля:

- `QMGR=CSQ9`
    
- `REQ=Z88011.MQZ3.QLOCAL`
    
- `RPLY=Z88011.MQZ3.REPLYTO.QLOCAL`
    
- `WAIT_MS=30000`
    

Для CICS MVP я предлагаю:

- `QMGR` оставить (или SPACES для default)
    
- `REQ/RPLY` оставить
    
- `WAIT_MS` игнорировать (NO-WAIT)
    

---

Если хочешь, я могу:

- предложить **минимальный патч** в `LIBMQCIC` “убрать PARAMSFILE и READ-CONFIG, использовать WS константы”,  
    или
    
- сделать вариант **TSQ-конфига** (очень быстрый и без админ-VSAM), с примером команд как “записать конфиг” и кодом `READQ TS`.
    

  

LIBMQCIC.cbl

Datei

сделай патч программы с константами дай мне ссылку для скачивания

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — сделал патч `LIBMQCIC` с константами (QMGR/REQ/RPLY) вместо чтения параметров из batch `DD PARAMS`.

Скачать:

- LIBMQCIC_constants.cbl
    
- (дополнительно) LIBMQCIC_constants.diff 
    

  

LIBMQCIC.cbl

Datei

была неправильная копия программы - сделай патч еще раз и дай мне ссылку

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Сделал патч заново на свежей `LIBMQCIC.cbl` и собрал новую версию с константами.

Скачать:

- LIBMQCIC_constants_v2.cbl
    
- (дополнительно) LIBMQCIC_constants_v2.diff 
    

  

похоже что чтение файла параметров уже было удалено из программы до ? этого

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Похоже, **нет — в текущей `LIBMQCIC.cbl` чтение “параметрического файла” ещё не вычищено полностью**.

Я проверил твой актуальный member и там всё ещё есть:

- `FILE-CONTROL.`
    
- `SELECT PARAMSFILE ASSIGN TO PARAMS`
    
- `FILE SECTION.`
    
- `FD PARAMSFILE ...`
    
- `PARAMS-STATUS`
    

То есть “batch-скелет” для DD `PARAMS` **ещё присутствует** (хотя реального `READ PARAMS...` в коде может уже не быть). Это нормально: могли убрать логику чтения, но оставить I/O объявления.

### Что это значит practically

- Если ты хочешь **только константы** и вообще не зависеть от DD `PARAMS`, то стоит:
    
    1. удалить `INPUT-OUTPUT SECTION / FILE-CONTROL / FILE SECTION / FD PARAMSFILE`
        
    2. удалить `PARAMS-STATUS` и всё, что с ним связано
        
    3. оставить только константные `WS-QMGR-NAME / WS-REQ-QUEUE / WS-REP-QUEUE`
        

Если хочешь — я сделаю **ещё один патч**: “полное выпиливание PARAMSFILE + константы” и дам ссылку для скачивания. 

  

сделай еще раз runbook_LIBT.md - как мы установили LIBT - что мы делали шаг за шагом и что проверяли

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — собрал пошаговый runbook именно по тому, как мы устанавливали `LIBT` (что вводили в CEDA/CEMT и что проверяли).

Download runbook_LIBT.md 

  

LIBT DFHAC2016 04/04/2026 15:49:46 CXZ88011 Transaction LIBT cannot run because program LIBMQCIC is not available.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Сообщение **DFHAC2016** означает простое: **CICS не может загрузить/найти load module `LIBMQCIC` в runtime библиотеках региона** (DFHRPL), поэтому транзакция `LIBT` не стартует программу.

Это **не про CEDA/CEMT**, а про **RPL / loadlib доступность**.

---

## 1) Быстрая проверка (что именно “не доступно”)

### A) Программа установлена, но не найдена в DFHRPL

Выполни:

CEMT I PROG(LIBMQCIC)

Если будет `NOT FOUND` или что-то про `DISABLED / NOTAVAILABLE` — это подтверждение.

### B) Убедись, что load module реально есть в твоём LOAD

Ты собирал его в:

- `Z88011.LOAD(LIBMQCIC)`
    

Проверь в ISPF 3.4, что member есть и он “PROGRAM OBJECT / LOAD”.

---

## 2) Что делать (2 рабочих варианта)

### Вариант A (самый быстрый для учебного стенда): скопировать модуль в библиотеку, которая уже в DFHRPL

У региона почти всегда есть стандартная RPL библиотека (типа `DFH620.CICS.SDFHLOAD` или отдельная site `...RPL...`).

Нужно **узнать, какие библиотеки в DFHRPL**. Если у тебя есть доступ к CEMT, попробуй:

CEMT I SYSTEM

и ищи упоминание `RPL`/`DFHRPL` (не всегда выводит).  
Часто проще: попросить админа сказать “какие loadlibs в DFHRPL”.

Потом копируешь:

- из `Z88011.LOAD(LIBMQCIC)`
    
- в одну из DFHRPL библиотек (например `DFH620.CICS.ADFHLOAD`/site loadlib).
    

### Вариант B (правильно, но требует админа): добавить `Z88011.LOAD` в DFHRPL

Это изменение конфигурации региона (обычно через SIT/DFHRPL или через динамическую установку LIBRARY ресурсов) — почти всегда требует админских прав.

---

## 3) “По-CICS” способ без трогания DFHRPL (если разрешено): CEDA DEFINE LIBRARY

Если в регионе разрешены ресурсы **LIBRARY** (CICS TS поддерживает dynamic program LIBRARY), можно подключить твой loadlib как LIBRARY resource.

В CEDA:

1. `DEFine LIBrary(Z88011LD) GROup(Z88011)`
    
2. Указать dataset: `Z88011.LOAD`
    
3. `INStall GROup(Z88011)`
    

⚠️ Это работает только если политика стенда позволяет LIBRARY и у тебя есть права.

---

## 4) Что попросить у админа (если сам не можешь)

Скопируй им:

> “В регионе CXZ88011 транзакция LIBT не стартует: DFHAC2016 program LIBMQCIC not available.  
> Load module лежит в `Z88011.LOAD(LIBMQCIC)`.  
> Нужно либо добавить `Z88011.LOAD` в DFHRPL, либо скопировать member `LIBMQCIC` в любую библиотеку DFHRPL региона.”

---

## Самый быстрый следующий шаг прямо сейчас

Сделай `CEMT I PROG(LIBMQCIC)` и пришли вывод.  
Если там видно, что программа installed/enabled, но “not found in DFHRPL”, я скажу, какой именно вариант (A/B/Library) тебе подходит на твоём стенде и какие команды/шаги сделать.

  

I PROG(LIBMQCIC) STATUS: RESULTS - OVERTYPE TO MODIFY Prog(LIBMQCIC) Leng(0000000000) Cob Pro Ena Pri Req Ced Resc(0000) Use(0000000000) Any Uex Ful Qua Cic SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 15.51.05 DATE: 04/04/26 PF 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

По `CEMT I PROG(LIBMQCIC)` видно важное:

- `Prog(LIBMQCIC) ... Ena` ✅ (ресурс PROGRAM установлен и enabled)
    
- **`Leng(0000000000)`** ❌
    

Нулевая длина почти всегда означает: **CICS не смог определить/загрузить сам load module**. То есть ресурс есть, но **сама программа в DFHRPL (или LIBRARY) недоступна** — ровно поэтому `LIBT` и падает с DFHAC2016.

## Что делать дальше

### 1) Проверить, видит ли CICS твой loadlib как LIBRARY

Если у вас включены LIBRARY resources, самый “правильный” путь — подключить `Z88011.LOAD` как CICS LIBRARY.

В CEDA:

1. `DEFine LIBrary(Z88011LD) GROup(Z88011)`
    
2. На панели укажи dataset:
    
    - `DSName ==> Z88011.LOAD`
        
    - (если есть поле “Search position / Rank” — оставь дефолт)
        
3. `INStall GROup(Z88011)`
    

Затем попробуй снова `LIBT`.

> Если CEDA не даёт DEFINE LIBRARY или INSTALL ругается — значит этот путь запрещён политикой стенда.

### 2) Самый быстрый workaround: скопировать load module в DFHRPL библиотеку

Если LIBRARY нельзя, то остаётся классика:

- найти библиотеку, которая уже в DFHRPL региона (обычно какая-то `...CICS...LOAD...` или site RPL)
    
- скопировать туда member `LIBMQCIC` из `Z88011.LOAD`
    

После этого:

- `CEMT I PROG(LIBMQCIC)` покажет **ненулевой Leng(...)**
    
- `LIBT` начнёт выполняться
    

### 3) Что точно НЕ поможет

- переустановка PROGRAM/TRANSACTION через CEDA (ты это уже сделал) — ресурс есть, проблема именно в **runtime load path**.
    

---

## Быстрый диагностический шаг (чтобы не гадать)

В CEDA попробуй показать LIBRARY resources:

DIsplay LIBrary(*)

Если покажет список — LIBRARY механизм доступен и мы можем подключить `Z88011.LOAD`.  
Если “resource type not known / not authorized” — значит нужен вариант с копированием в DFHRPL/помощь админа.

---

## Если нужен админ (текст запроса)

> В регионе CXZ88011 транзакция LIBT не запускается: DFHAC2016 program LIBMQCIC not available.  
> `CEMT I PROG(LIBMQCIC)` показывает `Leng(0)`, то есть load module не находится в DFHRPL/LIBRARY.  
> Load module лежит в `Z88011.LOAD(LIBMQCIC)`.  
> Прошу либо добавить `Z88011.LOAD` в DFHRPL (или определить LIBRARY на этот dataset), либо скопировать member `LIBMQCIC` в существующую DFHRPL библиотеку.

---

Скажи, что получается на `CEDA DIsplay LIBrary(*)` (показывает список или ошибка) — и я дам точные шаги под твой случай.

  

так ? DEFine LIBrary(Z88011LD) GROup(Z88011) OVERTYPE TO MODIFY CICS RELEASE = 0750 CEDA DEFine LIbrary( Z88011LD ) LIbrary ==> Z88011LD Group ==> Z88011 DEScription ==> Ranking ==> 50 1-9 | 11-99 CRitical ==> No No | Yes Status ==> Enabled Enabled | Disabled DATA SET NAMES DSNAME01 ==> Z88011.LOAD DSNAME02 ==> DSNAME03 ==> DSNAME04 ==> DSNAME05 ==> DSNAME06 ==> DSNAME07 ==> DSNAME08 ==> DSNAME09 ==> DSNAME10 ==> S THERE MUST BE AT LEAST ONE DSNAME SPECIFIED. SYSID=S750 APPLID=CXZ88011 DSN=Z88011.CICS.DFHCSD F 1 HELP 2 COM 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, **всё правильно** — ты на нужной панели **CEDA DEFINE LIBRARY** и `DSNAME01 ==> Z88011.LOAD` задан верно ✅

Сообщение внизу:

> **“THERE MUST BE AT LEAST ONE DSNAME SPECIFIED.”**

появляется **пока ты не подтвердил ввод** (или если в поле были пробелы/не теми символами). Раз у тебя `DSNAME01` заполнено, дальше просто:

## 1) Сохрани определение LIBRARY

Нажми **Enter** на этой панели (после ввода `DSNAME01`).

Если всё ок — сообщение исчезнет, и CEDA сохранит ресурс в CSD.

## 2) Установи LIBRARY в регион

В командной строке CEDA:

INStall GROup(Z88011)

(или точечно: `INStall LIbrary(Z88011LD)` — но через группу проще.)

Должно быть `INSTALL SUCCESSFUL`.

## 3) Проверка: появилась ли “ненулевая длина” у программы

Сразу после install:

CEMT I PROG(LIBMQCIC)

Ожидаем, что `Leng(...)` станет **не 0**.

## 4) Запуск

Потом на чистом экране:

LIBT

---

### Если после `INSTALL GROUP(Z88011)` появится ошибка на LIBRARY

Типичные варианты:

- dataset не “APF-authorized” (иногда требуется)
    
- нет доступа к `Z88011.LOAD`
    
- LIBRARY feature/права ограничены
    

Тогда пришли точный текст DFH/сообщения — и скажу, что именно нужно (часто достаточно “дать CICS read на dataset” или скопировать модуль в уже разрешённый DFHRPL loadlib).

Но твой шаг **абсолютно правильный**: `LIBRARY(Z88011LD)` + `DSNAME01=Z88011.LOAD` — это и есть “CICS way” подключить твой loadlib без правки SIT/DFHRPL.

  

I PROG(LIBMQCIC) STATUS: RESULTS - OVERTYPE TO MODIFY Prog(LIBMQCIC) Leng(0000000000) Cob Pro Ena Pri Ced Resc(0000) Use(0000000000) Any Uex Ful Qua Cic SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 16.02.39 DATE: 04/04/26 F 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

`Leng(0000000000)` **не изменился**, значит CICS **всё ещё не может загрузить** `LIBMQCIC`. Это обычно означает одно из двух:

1. **LIBRARY ресурс не установлен/не активен в рантайме** (или не “включён” в поисковый путь), _или_
    
2. `Z88011.LOAD` **не является подходящей runtime библиотекой для CICS** (часто: не тот тип — PDS vs PDSE, не program object format, нет прав чтения, или CICS “не видит” библиотеку из-за ограничений).
    

Раз ты смог определить LIBRARY — давай сделаем 3 быстрые проверки, которые сразу покажут, где именно затык.

---

## 1) Убедиться, что LIBRARY реально установлена

В CEMT выполни:

CEMT I LIBRARY(Z88011LD)

Ожидаем увидеть `Ena` и статус.  
Если скажет `NOT FOUND` — значит ты **не сделал INSTALL** после DEFINE, или установил не ту группу.

Если `Ena`, но “не open / not usable” — пришли строку, там будет причина.

---

## 2) Проверить, что `Z88011LD` реально используется для program search

Проверь, видит ли CICS сам ресурс PROGRAM правильно:

CEMT I PROG(LIBMQCIC) FULL

(или просто `CEMT I PROG(LIBMQCIC)` и затем PF5 VAR/PF11 SF, зависит от терминала)

Смысл: нам нужны поля типа **LIBRARY / RPL / LOCATION / LOADPOINT** (как они называются в твоём release), чтобы понять откуда CICS пытается грузить.

---

## 3) Проверить саму библиотеку `Z88011.LOAD`

В ISPF 3.4 посмотри свойства `Z88011.LOAD`:

- это **PDSE (DSNTYPE=LIBRARY)**? (для program objects это обычно лучше)
    
- member `LIBMQCIC` там точно есть и он **executable**?
    

Если `Z88011.LOAD` — обычный PDS, а binder у тебя писал “PROGRAM OBJECT (FORMAT 3)”, то это должно быть **PDSE**. Если не PDSE — CICS может не подхватить так, как ожидается.

---

## Самый вероятный сценарий (по учебным стендам)

LIBRARY определён, но CICS не использует его для program load, пока не задано/не разрешено. Иногда нужно:

- `CEDA INSTALL LIBRARY(Z88011LD)` (или `INSTALL GROUP(Z88011)` ещё раз) и проверить `CEMT I LIBRARY`
    
- иногда `Ranking`/конфликт с другими LIBRARY тоже влияет (но Leng=0 обычно “не видит вообще”).
    

---

## Если `CEMT I LIBRARY(Z88011LD)` покажет, что всё OK, но Leng всё равно 0

Тогда самый быстрый рабочий обход:

### Скопировать `LIBMQCIC` в библиотеку, которая уже точно в DFHRPL

Это гарантированно заставит `Leng` стать ненулевым.

---

### Что пришли мне, и я скажу точный следующий шаг

1. Вывод `CEMT I LIBRARY(Z88011LD)`
    
2. Коротко: `Z88011.LOAD` — это PDS или PDSE?
    

После этого можно будет либо добить LIBRARY, либо сразу выбрать “копировать в DFHRPL” как железобетонный MVP.

  

INSTALL LIBRARY(Z88011LD) OVERTYPE TO MODIFY CEDA Install ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> LIBrary ==> Z88011LD + LSrpool ==> S GROUP or LIST must be specified. SYSID=S750 APPLID=CXZ88011 DSN=Z88011.CICS.DFHCSD PF 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Ты всё сделал правильно — просто **команда INSTALL в CEDA работает только через GROUP или LIST**, даже если ты указал `LIBRARY => Z88011LD`.

Сообщение:

> `GROUP or LIST must be specified.`

означает: CEDA хочет, чтобы ты установил ресурс **из CSD по группе** (или предварительно собрал LIST).

## Самый простой способ

Раз `Z88011LD` у тебя в группе `Z88011`, просто делай:

INStall GROup(Z88011)

После этого проверь, что LIBRARY реально установилась:

CEMT I LIBRARY(Z88011LD)

---

## Если хочешь “точечно” установить только LIBRARY (через LIST)

1. Сделай список:
    

DIsplay LIBrary(Z88011LD)

2. Затем:
    

INStall LIST

---

## Почему `Leng` всё ещё 0

Пока LIBRARY не установлена (или установлена, но не ACTIVE), CICS по-прежнему **не видит**`Z88011.LOAD` как источник программ.

### Следующий контрольный шаг

Сделай:

1. `INSTALL GROUP(Z88011)`
    
2. затем `CEMT I LIBRARY(Z88011LD)`
    
3. затем `CEMT I PROG(LIBMQCIC)`
    

И пришли вывод пункта (2) — там будет видно, активна ли библиотека и какие датасеты реально подцеплены.

  

INStall GROup(Z88011) OVERTYPE TO MODIFY CEDA Install ALl ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> LIBrary ==> MESSAGES: 1 SEVERE 1 WARNING SYSID=S750 APPLID=CXZ88011 INSTALL UNSUCCESSFUL DSN=Z88011.CICS.DFHCSD F 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Ок — теперь CEDA говорит главное: **INSTALL GROUP(Z88011) не прошёл**, и он явно пишет:

> `MESSAGES: 1 SEVERE 1 WARNING`  
> `INSTALL UNSUCCESSFUL`

Это почти всегда означает: **по LIBRARY ресурсу (или по одному из ресурсов группы) есть конкретная причина** (нет доступа к dataset, неправильный тип, не APF/не разрешено, конфликт ранга, и т.п.).

### Следующий шаг — посмотреть текст сообщений CEDA

На этом экране нажми:

- **PF9 = MSG** (у тебя внизу видно `9 MSG`)
    

Там будет ровно 2 сообщения: одно WARNING и одно SEVERE.  
Скопируй сюда эти строки (обычно начинаются с `DFH...`).

---

## Самые частые причины именно при INSTALL LIBRARY

Пока ты открываешь PF9, вот что обычно всплывает:

1. **Нет READ-доступа CICS region userid к `Z88011.LOAD`**
    
    - Тогда нужно дать RACF/ACF2 разрешение на чтение dataset’а для region user (часто `CICSUSER`/`DFH...`).
        
2. **Неподходящий тип библиотеки**
    
    - Если `Z88011.LOAD` не PDSE/не program-object library для такого режима, CICS может отказать.
        
3. **LIBRARY resources запрещены политикой региона**
    
    - Бывает: CEDA DEFINE разрешён, но INSTALL запрещён.
        
4. **Конфликт/невалидный Ranking / Critical**
    
    - Реже, но бывает.
        

---

## Если окажется, что LIBRARY нельзя/не дают доступ

Тогда для MVP остаётся железобетонное решение:

### Workaround MVP: скопировать `LIBMQCIC` в DFHRPL loadlib региона

То есть в библиотеку, которая уже в DFHRPL (обычно `DFH620.CICS.SDFHLOAD` или site `...RPL...`).  
После копирования `CEMT I PROG(LIBMQCIC)` покажет **ненулевой Leng**, и `LIBT` стартанёт.

Но сначала давай возьмём точную причину из PF9.

---

### Сделай сейчас

1. PF9 (MSG)
    
2. пришли 2 строки сообщений (SEVERE + WARNING)
    

И я скажу точный фикс (права / другой dataset / другой путь).

  

INStall GROup(Z88011) MESSAGES - USE ENTER TO RETURN S Install of LIBRARY Z88011LD failed because the installed definition is not disabled. W GROUP Z88011 has been partially installed. SYSID=S750 APPLID=CXZ88011 DSN=Z88011.CICS.DFHCSD PF 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Сообщение CEDA очень конкретное:

> **S** Install of LIBRARY Z88011LD failed because the installed definition is **not disabled**.  
> **W** GROUP Z88011 has been partially installed.

Это означает: **в регионе уже есть установленный LIBRARY(Z88011LD)** (или “installed definition”), и CICS **не даёт переустановить/заменить его**, пока он **не DISABLED**.

### Что сделать (быстро и правильно)

## 1) Сначала DISABLE LIBRARY(Z88011LD)

В CEMT (или через CEDA alter), попробуй:

CEMT SET LIBRARY(Z88011LD) DISABLED

Если команда `SET LIBRARY` не распознаётся, сделай через CEDA:

- `CEDA`
    
- `ALTer LIBrary(Z88011LD)`
    
- `Status ==> Disabled`
    
- Enter (сохранить)
    
- затем `INStall GROup(Z88011)`
    

## 2) Потом снова INSTALL GROUP(Z88011)

INStall GROup(Z88011)

## 3) Потом снова ENABLE (если нужно)

CEMT SET LIBRARY(Z88011LD) ENABLED

И проверь:

CEMT I LIBRARY(Z88011LD)  
CEMT I PROG(LIBMQCIC)

Ожидаем, что у `LIBMQCIC` **Leng станет ненулевой**.

---

### Если DISABLE не разрешат (NOT AUTH / INVALID)

Тогда у тебя нет прав менять установленный LIBRARY. В этом случае самый простой MVP-обход:

- **переименуй** библиотеку в новый ресурс, например `Z88011L2`, и ставь его:
    
    - `DEFine LIBrary(Z88011L2) GROup(Z88011)`
        
    - `DSNAME01=Z88011.LOAD`
        
    - `INStall GROup(Z88011)`
        

(потому что конфликт именно по имени `Z88011LD`.)

---

Сделай сначала **`CEMT I LIBRARY(Z88011LD)`** и пришли вывод (1–2 строки). Я скажу, можно ли через `CEMT SET ... DISABLED`, или лучше сразу идти путём “новое имя LIBRARY”.

  

можно посмотреть текущий DSN для LIBRARY(Z88011LD)

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да — можно.

## Через CEMT (самое быстрое)

Попробуй:

CEMT I LIBRARY(Z88011LD)

Обычно CEMT покажет статус и **DSNAME(…)** (иногда не на первом экране). Если видишь только краткий вывод — пролистай **PF8** / или нажми **PF11 SF** (scroll forward), либо **PF5 VAR** — в разных конфигурациях CEMT детальные поля выводятся на следующих “страницах”.

Если в выводе есть поле типа `DSname(…)` / `Dsn(…)` / `Dsnam(…)` — это и есть текущий dataset.

## Через CEDA (гарантированно показывает DSNAME01..)

В CEDA:

DIsplay LIBrary(Z88011LD)

(или `ALTer LIBrary(Z88011LD)` — но это уже редактирование).  
На панели увидишь:

- `DSNAME01 ==> ...`
    
- `DSNAME02 ==> ...`  
    … — это текущие DSN’ы библиотеки.
    

---

Если пришлёшь вывод `CEMT I LIBRARY(Z88011LD)` (1 экран), я скажу, где именно там смотреть DSN и что делать дальше с “installed definition is not disabled”.

  

I LIBRARY(Z88011LD) STATUS: RESULTS - OVERTYPE TO MODIFY Lib(Z88011LD) Sea(0002) Ran( 50 ) Num(001) Ena Dsname01(Z88011.LOAD ) SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 16.08.47 DATE: 04/04/26 F 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да — ты уже посмотрел ровно то, что нужно. В выводе видно текущий DSN:

- `Lib(Z88011LD) ... Ena`
    
- `Dsname01(Z88011.LOAD)`
    

То есть **LIBRARY Z88011LD уже установлена и ENABLED** и указывает на **`Z88011.LOAD`**.

---

## Почему тогда `LIBMQCIC` всё ещё с `Leng(0)`

Если LIBRARY активна и DSN правильный, остаются самые частые причины:

### 1) В `Z88011.LOAD` нет _исполняемого_ `LIBMQCIC` (не тот member/тип)

Проверь в ISPF 3.4:

- `Z88011.LOAD` → member `LIBMQCIC` реально существует?
    
- Это **program object** (PDSE load module), не “текстовый” или пустой member?
    

### 2) CICS не перезагрузил/не переоценил PROGRAM после того как библиотека стала доступна

Иногда нужно сделать **NEWCOPY**:

CEMT SET PROG(LIBMQCIC) NEWCOPY

Потом снова:

CEMT I PROG(LIBMQCIC)

Ожидаем, что `Leng(...)` станет ненулевой.

### 3) Program definition указывает не туда / конфликт имен

Редко, но бывает, что CICS берёт другой `LIBMQCIC` из более “раннего” источника поиска. Ranking у LIBRARY = 50, search order = 0002 — ок, но если где-то есть другой LIBRARY/RPL с тем же member name, могут быть сюрпризы.

Быстрый тест:

- временно **DISABLE** библиотеку и снова **ENABLE** (если права позволяют), затем NEWCOPY.
    

CEMT SET LIBRARY(Z88011LD) DISABLED  
CEMT SET LIBRARY(Z88011LD) ENABLED  
CEMT SET PROG(LIBMQCIC) NEWCOPY

---

## Самый быстрый следующий шаг

Сделай:

1. `CEMT SET PROG(LIBMQCIC) NEWCOPY`
    
2. `CEMT I PROG(LIBMQCIC)`
    

Если `Leng` всё ещё 0 — тогда почти наверняка проблема в самом `Z88011.LOAD(LIBMQCIC)` (нет/не тот тип). Тогда скажи:

- `Z88011.LOAD` у тебя **PDSE (DSNTYPE=LIBRARY)** или обычный PDS?
    
- member `LIBMQCIC` точно виден в списке?
    

  

SET PROG(LIBMQCIC) NEWCOPY STATUS: RESULTS - OVERTYPE TO MODIFY Prog(LIBMQCIC) Len(0000038796) Cob Pro Ena Pri Ced NORMAL Res(0000) Use(0000000000) Any Uex Ful Qua Cic SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 16.10.03 DATE: 04/04/26 F 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Супер — это именно то, что нужно ✅

Теперь CICS **реально подхватил** load module:

- было `Len(0)`
    
- стало `Len(0000038796)` после `NEWCOPY`
    
- `RESPONSE: NORMAL`
    

То есть проблема была не в LIBRARY/DSN, а в том, что **PROGRAM уже был установлен, но CICS не перечитал модуль из библиотеки**, пока ты не сделал `NEWCOPY`.

## Что дальше

1. Вернись на чистый экран и запусти транзакцию:
    

LIBT

2. Если в request queue нет сообщений — программа, скорее всего, быстро завершится (NO-WAIT MQGET).
    
3. Для “непустого” теста: сначала положи сообщение в `LIB.REQ.Q` (через Spring Boot как обычно), затем снова `LIBT` — должен появиться reply в `LIB.REP.Q`.
    

## Если всплывут ошибки — что они будут означать

- MQ RC (MQCONN/MQOPEN/MQGET…) → MQ-часть/очереди/авторизация
    
- DB2 `-805` → CICS выполняет под планом, который не включает твой package
    
- другие DFH… сообщения → пришли текст, разберём
    

Сделай запуск `LIBT` и скинь, что появилось (или что вернулось в Spring Boot).

  

runbook_LIBT.md

Datei

допиши в runbook команды по установке Load_library / diagnostic / CEMT SET PROG(LIBMQCIC) NEWCOPY все что мы еще доделали сейчас - дай ссылку на новый файл

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — дополнил runbook шагами про LIBRARY/load path, диагностику DFHAC2016/Leng(0) и команду `CEMT SET PROG(LIBMQCIC) NEWCOPY`.

Download runbook_LIBT_v2.md 

  

LIBT STATUS: SESSION ENDED DFHAC2206 16:13:30 CXZ88011 Transaction LIBT failed with abend ASRA. Updates to local recoverable resources backed out.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

`DFHAC2206 ... abend ASRA` = **program check abend** в CICS (по сути: S0C* / protection / addressing / bad call), и CICS откатил ресурсы. Это уже не “конфигурация”, а **падение самой программы** на рантайме.

Дальше надо быстро вытащить **точную причину** (какой именно S0C и где). Делается в 2–3 шага.

---

## 1) Посмотреть детали абенда в CICS message log

Сразу в CICS набери:

CEMT INQ TASK

Если не понятно — проще так: открой **CICS message log** (CSMT) и найди запись про ASRA в 16:13:30.

Самые быстрые команды:

CEMT I TASK

и/или

CEMT I TRAN(LIBT)

Но лучше всего — посмотреть именно DFH… сообщения вокруг абенда (обычно там будет “ASRA abend, program LIBMQCIC, PSW…, Abend code 0C4/0C1/0C7 …”).

---

## 2) Сделать “abend trace” через CEDF (если разрешено)

У тебя на PROGRAM было `CEdf ==> Yes`, значит можно:

1. На чистом экране:
    

CEDF ON

2. Запусти:
    

LIBT

CEDF покажет последнюю выполненную команду `EXEC CICS ...` перед падением (часто сразу видно: на каком MQCALL/DB2 call/RETURN).

---

## 3) Самые вероятные причины ASRA именно для твоего `LIBMQCIC`

По твоей программе наиболее вероятные “первых 5”:

1. **MQI CALL interface mismatch** (параметры/структуры/копибуки не те под CICS, особенно если копибуки/CMQ* версии не совпадают с runtime) → часто приводит к ASRA.
    
2. **Неверный формат/инициализация MQOD/MQMD** (например, не обнулил структуру, оставил мусор, не задал StrucId/Version корректно) → MQOPEN/MQGET может вызвать protection.
    
3. **DB2 attach context**: первый `EXEC SQL` падает из-за неправильного окружения/план/attach — обычно даёт SQLCODE, но иногда может приводить к abend, если SQLCA не там/неинициализирована (реже).
    
4. **Pointer/substring bounds** (например, `REQ-DATA(1:300)` когда длина меньше/не то поле, или pointer ушёл за границу при STRING) → может дать 0C4.
    
5. **DFHCOMMAREA handling** (но у тебя COMMAREA “variable length” — обычно ок; если EIBCALEN=0, а программа всё равно читает COMMAREA — тогда да).
    

---

## 4) Что мне нужно от тебя (и я скажу точный фикс)

Пришли **3–10 строк** из CICS message log **вокруг времени 16:13:30**, где видно:

- какой именно **program check code** (0C4/0C1/0C7/…)
    
- какой модуль/offset (LIBMQCIC + offset)
    
- иногда там же будет “last executed command”.
    

Если проще: найди сообщение вида `DFHME...` / `DFHAP...` / `DFH... ASRA` с PSW/offset и вставь сюда.

---

## 5) Параллельно: включи dump (если есть) — чтобы не гадать

Если у вас настроен transaction dump:

- `CEMT SET DUMPCODE(ASRA) TRANDUMP` (если разрешено)
    
- или админом.
    

Но чаще на стендах достаточно CEDF + message log.

---

### Быстрый маршрут “без прав”

Если у тебя нет доступа к логам: включи `CEDF ON`, повтори `LIBT`, и напиши **последнюю строку/команду**, на которой остановилось (что за `EXEC CICS ...` / где именно).

С этого момента можно будет точечно чинить (обычно это либо MQCONN/MQOPEN блок, либо обработка строки запроса).

  

I TASK STATUS: RESULTS - OVERTYPE TO MODIFY Tas(0000211) Tra(CEMT) Fac(1011) Run Ter Pri( 255 ) Sta(TO) Use(Z88011 ) Uow(E27B9359FE798757) SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 16.14.56 DATE: 04/04/26 F 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

`CEMT I TASK` сейчас показывает **только твою текущую задачу CEMT** (`Tra(CEMT)`), а не упавшую `LIBT`. После ASRA та task уже завершилась, поэтому её тут нет.

Чтобы поймать именно **abend-task**, есть 3 быстрых способа.

## 1) Посмотреть “Recent” tasks и найти LIBT (если доступно)

Попробуй:

CEMT I TASK ALL

или (если ALL запрещён):

CEMT I TASK

и затем **PF8** / **PF11 SF** (иногда показывает список, если их несколько).

Ищи строки с:

- `Tra(LIBT)` или
    
- `Abn` / `ASRA` / `Purged`
    

Если увидишь `Tas(....) Tra(LIBT)` — открой детали (обычно `S` слева или overtype).

## 2) Самый надёжный: включить CEDF и повторить

У тебя для `PROGRAM(LIBMQCIC)` стоит `CEdf Yes`, значит:

CEDF ON  
LIBT

CEDF остановит выполнение на каждом `EXEC CICS ...` и покажет **последнюю выполненную команду перед ASRA**. Это лучший “debugger без dumps”.

После падения пришли сюда:

- последнюю показанную CEDF команду (и что было на экране)
    

## 3) Посмотреть message log (CSMT) / transient data

Нужны сообщения вокруг `16:13:30` (у тебя DFHAC2206 с временем). Обычно там есть строки типа:

- `DFHME...` / `DFHAP...` / `DFH...` с **abend code 0C4/0C1/0C7** и **offset** в `LIBMQCIC`.
    

Если у тебя есть транзакция просмотра лога (часто `CEMT I TRANS(CSMT)` не то; бывает `CEBR`/`CMSG`/`CSMG` в зависимости от установки) — открой и пришли 5–10 строк вокруг abend.

---

### Почему это важно

ASRA без кода (0C4/0C7) и offset — это “программа упала”, но _где_ именно (MQCALL, DB2, pointer/substring) — не угадаешь. CEDF или log сразу даст точку.

---

## Что сделать прямо сейчас (самый быстрый путь)

1. Выполни:
    

CEDF ON  
LIBT

2. Сфоткай/скопируй **последний экран CEDF** перед тем как сессия снова “ENDED”.
    

И я скажу точный фикс в коде (90% — это либо неверная MQ структура/версия/инициализация, либо bounds/pointer в обработке строки, либо не тот вызов MQDISC/MQCONN параметры).

  

TRANSACTION: LIBT PROGRAM: LIBMQCIC TASK: 0000215 APPLID: CXZ88011 DISPLAY: 00 STATUS: PROGRAM INITIATION EIBTIME = 161720 EIBDATE = 0126094 EIBTRNID = 'LIBT' EIBTASKN = 215 EIBTRMID = '1011' EIBCPOSN = 5 EIBCALEN = 0 EIBAID = X'7D' AT X'1C90011A' EIBFN = X'0000' AT X'1C90011B' EIBRCODE = X'000000000000' AT X'1C90011D' EIBDS = '........' + EIBREQID = '........' ENTER: CONTINUE PF1 : UNDEFINED PF2 : SWITCH HEX/CHAR PF3 : END EDF SESSION PF4 : SUPPRESS DISPLAYS PF5 : WORKING STORAGE PF6 : USER DISPLAY PF7 : SCROLL BACK PF8 : SCROLL FORWARD PF9 : STOP CONDITIONS PF10: PREVIOUS DISPLAY PF11: EIB DISPLAY PF12: UNDEFINED

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично — ты уже в **CEDF** и видишь **PROGRAM INITIATION**. Это первый стоп: CICS только запускает `LIBMQCIC`, и пока ещё ничего “плохого” не произошло. Видно важное:

- `EIBCALEN = 0` → **COMMAREA нет** (это нормально для твоего MVP).
    
- Дальше надо **пройти несколько “CONTINUE”**, пока не дойдём до места, где падает ASRA.
    

## Что делать сейчас (пошагово)

### 1) Жми Enter несколько раз (CONTINUE)

На каждом экране CEDF будет показывать следующий `EXEC CICS ...` или “USER DISPLAY”.

Твоя цель — поймать **последний экран перед “SESSION ENDED / ASRA”**.

### 2) Если увидишь экран с “EXEC CICS …”

Сфоткай/скопируй именно его. Особенно интересны команды типа:

- `EXEC CICS SYNCPOINT`
    
- `EXEC CICS RETURN`
    
- любые `EXEC CICS …` связанные с обработкой ошибок
    

Но ещё важнее: **если CEDF покажет, что падение происходит во время MQCALL** (обычно это будет не как `EXEC CICS`, а как “program check” после `CALL 'MQCONN' / 'MQOPEN' …`).

### 3) Включи “WORKING STORAGE” в момент перед падением

Если видно, что вот-вот будет MQCONN/MQOPEN, нажми:

- **PF5 (WORKING STORAGE)**
    

И посмотри значения:

- `COMPCODE`
    
- `REASON`
    
- `HCONN`, `HOBJ-REQ`, `HOBJ-REP`
    
- `WS-QMGR-NAME`, `WS-REQ-QUEUE`, `WS-REP-QUEUE`
    

Если ASRA случается сразу после MQCALL — это почти всегда “интерфейс/параметры не те”.

---

## Самая вероятная причина ASRA в твоём `LIBMQCIC` (90%)

У тебя в программе MQ структуры берутся из `CMQ*V` copybooks, но **ты не инициализируешь**MQOD/MQMD/MQGMO/MQPMO через их default values.

В batch это иногда “случайно прокатывает”, а в CICS часто приводит к S0C4/ASRA на `MQOPEN/MQGET`, потому что:

- `MQOD-STRUCID`, `MQMD-STRUCID`, `MQGMO-STRUCID`, `MQPMO-STRUCID` должны быть корректны
    
- version/поля должны быть согласованы
    

### Мини-патч (который обычно сразу убирает ASRA)

Перед первым `MQCONN` добавь:

MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR  
MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR  
MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS  
MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS

(точные имена зависят от copybook версии; иногда это `MQMD-DEFAULT`, `MQOD-DEFAULT`, … — у тебя это есть в `CMQMDV/CMQODV/CMQGMOV/CMQPMOV`).

Плюс: перед `MOVE WS-REQ-QUEUE TO MQOD-OBJECTNAME` нужно убедиться, что `MQOD-OBJECTNAME`именно `PIC X(48)` и ты туда кладёшь 48-символьное имя (у тебя ок).

Но прежде чем патчить “вслепую”, давай поймаем точку падения через CEDF.

---

## Что пришли мне дальше

Продолжай CEDF:

1. Enter… Enter… пока не упадёт/закончится
    
2. Пришли **последний экран CEDF перед ASRA** (или тот, где видно, что после какого действия упало).
    

Если получится — пришли ещё экран PF5 (working storage) с `COMPCODE/REASON` сразу после первого MQCALL.

И я скажу:

- где именно падает
    
- какой минимальный патч в `LIBMQCIC` сделать (инициализация структур / параметры MQCALL / порядок CLOSE/DISC / и т.п.).
    

  

TRANSACTION: LIBT TASK: 0000215 APPLID: CXZ88011 DISPLAY: 00 STATUS: ABNORMAL TASK TERMINATION EIBTIME = 161720 EIBDATE = 0126094 EIBTRNID = 'LIBT' EIBTASKN = 215 EIBTRMID = '1011' EIBCPOSN = 5 EIBCALEN = 0 EIBAID = X'7D' AT X'1C90011A' EIBFN = X'0000' AT X'1C90011B' EIBRCODE = X'000000000000' AT X'1C90011D' EIBDS = '........' + EIBREQID = '........' INTERRUPT: PROTECTION ABEND : ASRA PSW: X'07952000 80000000 00000000 1D44A502 00040004' CONTINUE EDF? (ENTER YES OR NO) REPLY: YES ENTER: CONTINUE PF1 : UNDEFINED PF2 : SWITCH HEX/CHAR PF3 : END EDF SESSION PF4 : SUPPRESS DISPLAYS PF5 : WORKING STORAGE PF6 : USER DISPLAY PF7 : SCROLL BACK PF8 : SCROLL FORWARD PF9 : STOP CONDITIONS PF10: PREVIOUS DISPLAY PF11: EIB DISPLAY PF12: UNDEFINED

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Отлично, это уже “золотая” информация: **ASRA + INTERRUPT: PROTECTION** ⇒ это почти наверняка **0C4 (protection exception)**, т.е. программа попыталась обратиться к памяти “не туда” (плохой адрес, неинициализированная структура, неверный интерфейс вызова и т.п.).

CEDF показывает PSW:

- `ABEND: ASRA`
    
- `INTERRUPT: PROTECTION`
    
- `PSW … 1D44A502 …`
    

Это говорит: **упали на конкретной инструкции** (адрес `1D44A502`). Теперь задача — сопоставить этот адрес/offset с `LIBMQCIC` и понять, на каком месте падает (обычно это один из MQCALL’ов или обработка строки).

---

## Что сделать прямо сейчас (без админа, самый быстрый путь)

### 1) Включи Working-Storage прямо на этом экране (PF5)

Нажми **PF5 (WORKING STORAGE)** и посмотри значения (или сфоткай):

- `COMPCODE`
    
- `REASON`
    
- `HCONN`
    
- `HOBJ-REQ`, `HOBJ-REP`
    

Если падение происходит **до первого MQCALL**, то `COMPCODE/REASON` будут нули, но это тоже полезно (значит проблема не “RC”, а именно интерфейс/память).

### 2) Поставь “USER DISPLAY” (PF6) и повтори запуск

В твоём коде уже есть `DISPLAY 'LIBMQCIC START ...'`. Но CEDF не всегда показывает “на каком операторе COBOL” мы были.

Самый быстрый “трассирующий” патч в код (потом можно убрать):

- перед `MQCONN`
    
- сразу после `MQCONN`
    
- перед/после `MQOPEN REQ`
    
- перед/после `MQOPEN REP`
    
- перед `MQGET`
    

Например:

DISPLAY 'BEFORE MQCONN'.  
CALL 'MQCONN' ...  
DISPLAY 'AFTER MQCONN CC=' COMPCODE ' RC=' REASON.

Так ты точно увидишь, **на каком вызове падает** (если сообщение “BEFORE MQOPEN” появилось, а “AFTER” нет — значит падение внутри/на вызове).

---

## Самая вероятная причина твоего ASRA (и самый эффективный патч)

Для MQI под CICS **критично** правильно **инициализировать MQ структуры дефолтами**(StrucId/Version/Options). Если структура “грязная”, MQOPEN/MQGET часто приводит к protection.

### Минимальный патч (рекомендую сделать первым)

Сразу в начале (до первого `MQCONN/MQOPEN/MQGET/MQPUT`) добавь инициализацию:

MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR  
MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR  
MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS  
MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS

И дальше **уже поверх** дефолтов меняй нужные поля (OBJECTNAME, OPTIONS, CCSID, ENCODING и т.д.).

Если в твоих copybooks имена дефолтов чуть другие (например `MQMD-DEFAULTS`), ориентируйся по `CMQMDV/CMQODV/...` — там всегда есть “DEFAULT”.

### Второй частый триггер ASRA

Неверный “version” без дефолтов. Например ты делаешь:

- `MOVE MQOD-VERSION-4 TO MQOD-VERSION`  
    но **не заполнил MQOD-STRUCID** → MQ считает структуру невалидной → и может упасть.
    

Дефолт-инициализация это чинит.

---

## Как получить “точно где упали” (если доступно)

Если у тебя есть права на dump:

1. Разрешить dumpcode ASRA на transaction dump:
    

- (если разрешено) `CEMT SET DUMPCODE(ASRA) TRANDUMP`
    

2. Повторить `LIBT`.
    

Потом посмотреть dump (обычно через IPCS или через стендовые утилиты). В dump будет:

- модуль + offset (в `LIBMQCIC`), что сразу укажет строку/секцию.
    

Но на учебных стендах часто dump/IPCS недоступны, поэтому практичнее “DISPLAY-трасса + дефолт MQ structures”.

---

## Что пришли мне сейчас

1. Скрин/текст **PF5 Working Storage** с полями `COMPCODE/REASON/HCONN/HOBJ*` на экране ABEND.
    
2. Подтверди: **успеваешь ли увидеть хоть один из твоих DISPLAY**, например `LIBMQCIC START...`?
    

И я скажу, в какую сторону точно копать (MQI интерфейс / DB2 / bounds).  
Но я бы **сразу** сделал патч “MOVE MQxx-DEFAULT …” — это самый частый и самый быстрый фикс для ASRA на MQI в CICS.

  

TRANSACTION: LIBT TASK: 0000215 APPLID: CXZ88011 DISPLAY: 00 ADDRESS: 00000000 WORKING STORAGE WORKING STORAGE IS NOT AVAILABLE ENTER: CURRENT DISPLAY PF1 : UNDEFINED PF2 : BROWSE TEMP STORAGE PF3 : UNDEFINED PF4 : EIB DISPLAY PF5 : INVOKE CECI PF6 : USER DISPLAY PF7 : SCROLL BACK HALF PF8 : SCROLL FORWARD HALF PF9 : UNDEFINED PF10: SCROLL BACK FULL PF11: SCROLL FORWARD FULL PF12: REMEMBER DISPLAY

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 19s

Это нормальная (хоть и неприятная) ситуация для CEDF при **ASRA/PROTECTION**:

### Почему CEDF показывает `WORKING STORAGE IS NOT AVAILABLE` и `ADDRESS: 00000000`

CEDF умеет показывать Working-Storage **только если он может “привязаться” к COBOL-окружению**(адреса секций/таблицы отладки/якоря LE).  
При **ASRA (protection)** очень рано — часто **до того, как LE/COBOL runtime успел корректно инициализировать структуру программы**, либо модуль “падает” на внешнем вызове/интерфейсе так, что CEDF уже не может вычислить адрес WS → и ты видишь `ADDRESS: 00000000`.

Это **не значит**, что WS “нет вообще” — это значит, что **CEDF не может её найти в этом состоянии**.

---

## Что делать дальше (самый практичный путь)

### 1) Временно пересобрать программу “для диагностики”

Собери `LIBMQCIC` с отладочной информацией, чтобы CEDF/логирование стали полезнее:

**в первую строку** (на время диагностики) поставь, например:

CBL SQL LIST OFFSET TEST

- `TEST` даст отладочные метки для runtime/инструментов
    
- `LIST/OFFSET` облегчит сопоставление “где упало” (потом вернёшь NOXREF/NOMAP)
    

После того как поймаем причину — можно вернуть “маленький” листинг.

### 2) Добавить “маячки” (DISPLAY/WRITE OPERATOR) вокруг мест, где вероятнее всего падает

CEDF сейчас не даёт WS, значит нужно понять **на каком шаге** всё падает.  
Добавь в код **очень ранние** метки:

- прямо в начале `MAIN-SECTION`:
    
    - `DISPLAY 'A: START'`
        
- перед `CALL 'MQCONN'`:
    
    - `DISPLAY 'B: BEFORE MQCONN'`
        
- сразу после:
    
    - `DISPLAY 'C: AFTER MQCONN CC=' COMPCODE ' RC=' REASON`
        
- аналогично перед/после `MQOPEN/MQGET/...`
    

Если ты увидишь только `A`, но не увидишь `B` — значит падает до MQ.  
Если увидишь `B`, но не `C` — значит падение **внутри MQCONN** (частый случай при неверном интерфейсе/структурах).

### 3) Самый частый фикс для PROTECTION на MQI в CICS

Очень часто ASRA происходит из-за “грязных” MQ-структур.  
Перед первым MQCALL сделай инициализацию дефолтами:

MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR  
MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR  
MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS  
MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS

И только потом задавай `MQOD-OBJECTNAME`, `MQGMO-OPTIONS`, `MQPMO-OPTIONS`, `CCSID/ENCODING` и т.п.

### 4) Если хочешь “железобетонно”: сделать dump на ASRA

Если разрешено:

- включить transaction dump на ASRA (через DUMPCODE)
    
- повторить LIBT  
    Тогда в dump будет модуль/offset, и мы точно скажем “упало на MQOPEN” или “на строке X”.
    

---

## Что мне от тебя нужно, чтобы сказать точно

1. Ты видишь **хоть один** `DISPLAY` из программы перед “SESSION ENDED”? (например `LIBMQCIC START...`)
    
2. Если нет — давай добавим маячки как выше и ты пришлёшь, на каком “маячке” обрывается.
    

Если хочешь — я прямо сделаю патч `LIBMQCIC` с:

- MQ*-DEFAULT инициализацией
    
- маячками вокруг MQ calls  
    и дам файл для скачивания.
    

  

сейчас так CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Ок — сейчас у тебя в первой строке стоит “минимальный” режим:

CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE

Для диагностики ASRA в CICS этого **маловато**. Тебе нужно временно включить хотя бы **OFFSET + LIST + TEST**, чтобы:

- легче сопоставлять место падения (offset в листинге),
    
- CEDF/отладочные инструменты лучше цеплялись за модуль.
    

## Рекомендую на время отладки поставить так

Самый практичный вариант:

CBL SQL LIST OFFSET TEST

Если листинг будет слишком большим, можно чуть “приглушить”, но **OFFSET+TEST** я бы оставил:

CBL SQL OFFSET TEST NOXREF NOMAP

(главное — чтобы `OFFSET` и `TEST` были.)

---

## Почему это поможет именно тебе

У тебя CEDF на абенде показывает `WORKING STORAGE IS NOT AVAILABLE` — это часто бывает, когда у модуля нет подходящих “debug hooks”. `TEST` обычно улучшает ситуацию.

---

## И параллельно (это ключ к ASRA) — патч MQ-структур

Независимо от опций компиляции, самый частый фикс для ASRA/PROTECTION на MQI в CICS:

Перед первым MQCALL:

MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR  
MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR  
MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS  
MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS

И добавь 2–3 `DISPLAY` “маячка” вокруг `MQCONN/MQOPEN/MQGET`, чтобы понять, на каком вызове падает.

---

Если хочешь — я сделаю готовый патч `LIBMQCIC` (MQ*-DEFAULT + маячки) и дам файл для скачивания. Просто пришли актуальный `LIBMQCIC.cbl` (тот, который ты реально компилируешь сейчас).

  

CBL SQL OFFSET TEST NOXREF NOMAP IDENTIFICATION DIVISION. PROGRAM-ID. LIBMQCIC. ENVIRONMENT DIVISION. INPUT-OUTPUT SECTION. FILE-CONTROL. SELECT PARAMSFILE ASSIGN TO PARAMS ORGANIZATION IS SEQUENTIAL ACCESS IS SEQUENTIAL FILE STATUS IS PARAMS-STATUS. DATA DIVISION. FILE SECTION. FD PARAMSFILE RECORDING MODE IS F RECORD CONTAINS 80 CHARACTERS. 01 PARAMS-REC PIC X(80). WORKING-STORAGE SECTION. EXEC SQL INCLUDE SQLCA END-EXEC. 01 PARAMS-STATUS PIC XX. 01 WS-SQLCODE-EDIT PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY. 01 MQM-CONSTANTS. COPY CMQV. 01 MQM-OBJECT-DESCRIPTOR. COPY CMQODV. 01 MQM-MESSAGE-DESCRIPTOR. COPY CMQMDV. 01 MQM-GET-MESSAGE-OPTIONS. COPY CMQGMOV. 01 MQM-PUT-MESSAGE-OPTIONS. COPY CMQPMOV. 01 WS-QMGR-NAME PIC X(48) VALUE SPACES. 01 WS-REQ-QUEUE PIC X(48) VALUE 'LIB.REQ.TEST'. 01 WS-REP-QUEUE PIC X(48) VALUE 'LIB.REP.TEST'. 01 WS-WAIT-MS-DISP PIC 9(9) VALUE 0. 01 WS-WAIT-VAL-STR PIC X(9). 01 WS-WAIT-LEN PIC S9(4) COMP. 01 WS-WAIT-MS PIC S9(9) COMP-5 VALUE 0. 01 WS-CTL-LINE PIC X(256). 01 WS-VAL PIC X(200). 01 WS-EOF PIC X VALUE 'N'. 01 WS-KEY PIC X(16). 01 WS-REQUEST-TYPE PIC X(6) VALUE SPACES. COPY LIBLOAN. EXEC SQL DECLARE CUR-ACTIVE-LOANS CURSOR FOR SELECT LOAN_ID_NUM, BOOK_ID FROM LOAN WHERE USER_ID = :HAU-USER-ID AND RETURN_DATE IS NULL ORDER BY LOAN_ID_NUM END-EXEC. 01 HCONN PIC S9(9) COMP. 01 HOBJ-REQ PIC S9(9) COMP. 01 HOBJ-REP PIC S9(9) COMP. 01 COMPCODE PIC S9(9) COMP. 01 REASON PIC S9(9) COMP. 01 REQ-DATA PIC X(8192). 01 RSP-DATA PIC X(8192). 01 REQ-DATA-LEN PIC S9(9) COMP VALUE 8192. 01 RSP-DATA-LEN PIC S9(9) COMP VALUE 0. 01 WS-ACTIVE-COUNT PIC S9(9) COMP VALUE 0. 01 WS-LOAN-ID-NUM PIC S9(9) COMP VALUE 0. 01 WS-NEW-LOAN-NUM PIC 9(9) VALUE 0. 01 WS-NEW-LOAN-ID PIC X(10) VALUE SPACES. 01 WS-PADDED PIC X(9) VALUE SPACES. 01 WS-ACTIVE-LOAN-COUNT PIC 9(2) COMP VALUE 0. 01 WS-ACTIVE-LOAN-ID-NUM PIC S9(9) COMP VALUE 0. 01 WS-ACTIVE-BOOK-ID PIC X(10) VALUE SPACES. 01 WS-SQL-MSG PIC X(80) VALUE SPACES. 01 WS-XML-REQUEST PIC X(8192) VALUE SPACES. 01 WS-XML-RESPONSE PIC X(8192) VALUE SPACES. 01 WS-XML PIC X(8192) VALUE SPACES. 01 WS-XML-LEN PIC S9(9) COMP. 01 WS-PTR PIC S9(9) COMP. 01 WS-INDEX PIC 9(2) COMP VALUE 0. 01 WS-RETURN-COUNT PIC S9(9) COMP VALUE 0. 01 WS-ACTIVE-REQ-COUNT PIC S9(9) COMP VALUE 0. 01 WS-TAG-USER-START PIC X(10) VALUE "<user><id>". 01 WS-TAG-USER-END PIC X(12) VALUE "</id></user>". 01 WS-TAG-BOOK-START PIC X(10) VALUE "<book><id>". 01 WS-TAG-BOOK-END PIC X(12) VALUE "</id></book>". 01 WS-TAG-ACTIVE-USERID-START PIC X(8) VALUE "<userId>". 01 WS-TAG-ACTIVE-USERID-END PIC X(9) VALUE "</userId>". 01 WS-TAG-LOANID-START PIC X(8) VALUE "<loanId>". 01 WS-TAG-LOANID-END PIC X(9) VALUE "</loanId>". 01 WS-START PIC S9(9) COMP VALUE 0. 01 WS-END PIC S9(9) COMP VALUE 0. 01 WS-LEN PIC S9(9) COMP VALUE 0. * * W03 - MQ API fields * 01 W03-BUFFER-LENGTH PIC S9(9) BINARY VALUE 80. 01 W03-HCONN PIC S9(9) COMP-5. 01 W03-OPTIONS PIC S9(9) BINARY. 01 W03-HOBJ PIC S9(9) BINARY. 01 W03-DATA-LENGTH PIC S9(9) BINARY. 01 W03-COMPCODE PIC S9(9) BINARY. 01 W03-REASON PIC S9(9) BINARY. 01 W03-MESSAGE-DATA PIC X(80) VALUE SPACES. PROCEDURE DIVISION. MAIN-SECTION. DISPLAY 'LIBMQCIC STARTING (CICS MVP)'. DISPLAY 'MQ QMGR=' WS-QMGR-NAME ' REQQ=' WS-REQ-QUEUE ' RPLYQ=' WS-REP-QUEUE ' MODE=NO-WAIT'. CALL 'MQCONN' USING WS-QMGR-NAME HCONN COMPCODE REASON. IF COMPCODE NOT = MQCC-OK DISPLAY 'MQCONN FAILED, REASON=' REASON EXEC CICS RETURN END-EXEC END-IF. DISPLAY 'MQCONN SUCCEEDED, HCONN=' HCONN. MOVE MQOD-VERSION-4 TO MQOD-VERSION. MOVE WS-REQ-QUEUE TO MQOD-OBJECTNAME. CALL 'MQOPEN' USING HCONN MQM-OBJECT-DESCRIPTOR MQOO-INPUT-SHARED HOBJ-REQ COMPCODE REASON. IF COMPCODE NOT = MQCC-OK DISPLAY 'MQOPEN REQ FAILED, REASON=' REASON GO TO MQ-DISCONNECT END-IF. MOVE MQOD-VERSION-4 TO MQOD-VERSION. MOVE WS-REP-QUEUE TO MQOD-OBJECTNAME. CALL 'MQOPEN' USING HCONN MQM-OBJECT-DESCRIPTOR MQOO-OUTPUT HOBJ-REP COMPCODE REASON. IF COMPCODE NOT = MQCC-OK DISPLAY 'MQOPEN REP FAILED, REASON=' REASON GO TO MQ-CLOSE-REQ END-IF. DISPLAY 'MQOPEN SUCCEEDED FOR BOTH QUEUES'. MOVE MQGMO-VERSION-1 TO MQGMO-VERSION. MOVE MQMT-DATAGRAM TO MQMD-MSGTYPE. MOVE MQGMO-NO-WAIT TO MQGMO-OPTIONS ADD MQGMO-CONVERT TO MQGMO-OPTIONS ADD MQGMO-FAIL-IF-QUIESCING TO MQGMO-OPTIONS ADD MQGMO-SYNCPOINT TO MQGMO-OPTIONS. MOVE 1047 TO MQMD-CODEDCHARSETID MOVE MQENC-NATIVE TO MQMD-ENCODING. CALL 'MQGET' USING HCONN HOBJ-REQ MQM-MESSAGE-DESCRIPTOR MQM-GET-MESSAGE-OPTIONS REQ-DATA-LEN REQ-DATA W03-DATA-LENGTH COMPCODE REASON. IF COMPCODE NOT = MQCC-OK IF REASON = MQRC-NO-MSG-AVAILABLE DISPLAY 'MQGET: NO MESSAGE AVAILABLE' GO TO MQ-CLOSE-BOTH END-IF DISPLAY 'MQGET failed CC=' COMPCODE ' RC=' REASON EXEC CICS SYNCPOINT ROLLBACK END-EXEC GO TO MQ-CLOSE-BOTH ELSE DISPLAY 'Got ' W03-DATA-LENGTH ' bytes (converted to CCSID ' MQMD-CODEDCHARSETID ')' DISPLAY 'MSG: ' REQ-DATA(1:W03-DATA-LENGTH) END-IF. MOVE MQMD-MSGID TO MQMD-CORRELID. MOVE MQMI-NONE TO MQMD-MSGID. MOVE REQ-DATA(1:W03-DATA-LENGTH) TO WS-XML-REQUEST. PERFORM PARSE-XML-REQUEST. IF WS-REQUEST-TYPE = 'ACTIVE' DISPLAY 'PARSE COMPLETE, STATUS=' HAU-STATUS-CODE ELSE IF WS-REQUEST-TYPE = 'RETURN' DISPLAY 'PARSE COMPLETE, STATUS=' HRR-STATUS-CODE ELSE DISPLAY 'PARSE COMPLETE, STATUS=' HBR-STATUS-CODE END-IF END-IF IF WS-REQUEST-TYPE = 'ACTIVE' IF HAU-STATUS-CODE NOT = 'ERR ' PERFORM PROCESS-ACTIVE-BY-USER END-IF ELSE IF WS-REQUEST-TYPE = 'RETURN' IF HRR-STATUS-CODE NOT = 'ERR ' PERFORM PROCESS-RETURN END-IF ELSE IF HBR-STATUS-CODE NOT = 'ERR ' PERFORM PROCESS-BORROW END-IF END-IF END-IF IF WS-REQUEST-TYPE = 'ACTIVE' DISPLAY 'PROCESS COMPLETE, STATUS=' HAU-STATUS-CODE ELSE IF WS-REQUEST-TYPE = 'RETURN' DISPLAY 'PROCESS COMPLETE, STATUS=' HRR-STATUS-CODE ELSE DISPLAY 'PROCESS COMPLETE, STATUS=' HBR-STATUS-CODE END-IF END-IF PERFORM BUILD-XML-RESPONSE. MOVE MQPMO-VERSION-1 TO MQPMO-VERSION. MOVE MQPMO-NO-SYNCPOINT TO MQPMO-OPTIONS. ADD MQPMO-SYNCPOINT TO MQPMO-OPTIONS. ADD MQPMO-FAIL-IF-QUIESCING TO MQPMO-OPTIONS. COMPUTE RSP-DATA-LEN = FUNCTION LENGTH(RSP-DATA). CALL 'MQPUT' USING HCONN HOBJ-REP MQM-MESSAGE-DESCRIPTOR MQM-PUT-MESSAGE-OPTIONS RSP-DATA-LEN RSP-DATA COMPCODE REASON. IF COMPCODE NOT = MQCC-OK DISPLAY 'MQPUT FAILED, REASON=' REASON EXEC CICS SYNCPOINT ROLLBACK END-EXEC ELSE DISPLAY 'REPLY SENT, CORRELID SET FROM REQUEST MSGID' EXEC CICS SYNCPOINT END-EXEC END-IF. MQ-CLOSE-BOTH. CALL 'MQCLOSE' USING HCONN HOBJ-REP MQCO-NONE COMPCODE REASON. MQ-CLOSE-REQ. CALL 'MQCLOSE' USING HCONN HOBJ-REQ MQCO-NONE COMPCODE REASON. MQ-DISCONNECT. CALL 'MQDISC' USING HCONN COMPCODE REASON. DISPLAY 'LIBMQCIC ENDING'. EXEC CICS RETURN END-EXEC. ****************************************************************** ** Process the request using DB2 and build response ****************************************************************** PROCESS-BORROW. MOVE SPACES TO HOST-BORROW-RESPONSE. MOVE HBR-USER-ID TO HBR-USER-ID-R. MOVE HBR-BOOK-ID TO HBR-BOOK-ID-R. EXEC SQL SELECT COUNT(*) INTO :WS-ACTIVE-COUNT FROM LOAN WHERE BOOK_ID = :HBR-BOOK-ID AND RETURN_DATE IS NULL END-EXEC DISPLAY 'sqlcode after select= ' SQLCODE DISPLAY 'ACTIVE COUNT=' WS-ACTIVE-COUNT IF SQLCODE NOT = 0 PERFORM SQL-ERROR PERFORM BUILD-RESPONSE EXIT END-IF IF WS-ACTIVE-COUNT > 0 MOVE 'BUSY' TO HBR-STATUS-CODE MOVE 'Book already on loan' TO HBR-MESSAGE DISPLAY 'BOOK ' HBR-BOOK-ID ' ALREADY ON LOAN' PERFORM BUILD-RESPONSE EXIT END-IF EXEC SQL INSERT INTO LOAN (USER_ID, BOOK_ID, LOAN_DATE, DUE_DATE, RETURN_DATE) VALUES (:HBR-USER-ID, :HBR-BOOK-ID, CURRENT DATE, CURRENT DATE + 14 DAYS, NULL) END-EXEC DISPLAY 'sqlcode after insert= ' SQLCODE IF SQLCODE NOT = 0 PERFORM SQL-ERROR PERFORM BUILD-RESPONSE EXIT END-IF EXEC SQL VALUES IDENTITY_VAL_LOCAL() INTO :WS-LOAN-ID-NUM END-EXEC DISPLAY 'sqlcode after IDENTITY_VAL_LOCAL= ' SQLCODE IF SQLCODE NOT = 0 PERFORM SQL-ERROR PERFORM BUILD-RESPONSE EXIT END-IF MOVE WS-LOAN-ID-NUM TO WS-NEW-LOAN-NUM DISPLAY 'NEW LOAN NUM=' WS-NEW-LOAN-NUM MOVE SPACES TO WS-NEW-LOAN-ID MOVE 'L' TO WS-NEW-LOAN-ID (1:1) MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9) DISPLAY 'WS-NEW-LOAN-ID=' WS-NEW-LOAN-ID MOVE WS-NEW-LOAN-ID TO HBR-LOAN-ID MOVE 'OK' TO HBR-STATUS-CODE MOVE 'Loan created' TO HBR-MESSAGE DISPLAY 'LOAN CREATED, ID=' HBR-LOAN-ID CONTINUE. PROCESS-RETURN. MOVE SPACES TO HOST-RETURN-RESPONSE. MOVE HRR-LOAN-ID TO HRR-LOAN-ID-R. MOVE SPACES TO HRR-USER-ID-R HRR-BOOK-ID-R. IF HRR-LOAN-ID = SPACES MOVE 'ERR ' TO HRR-STATUS-CODE MOVE 'Missing loanId' TO HRR-MESSAGE EXIT END-IF MOVE SPACES TO WS-PADDED IF HRR-LOAN-ID(1:1) = 'L' MOVE HRR-LOAN-ID(2:9) TO WS-PADDED ELSE MOVE HRR-LOAN-ID TO WS-PADDED END-IF IF WS-PADDED IS NOT NUMERIC MOVE 'ERR ' TO HRR-STATUS-CODE MOVE 'Invalid loanId' TO HRR-MESSAGE EXIT END-IF MOVE WS-PADDED TO WS-LOAN-ID-NUM EXEC SQL SELECT USER_ID, BOOK_ID INTO :HRR-USER-ID-R, :HRR-BOOK-ID-R FROM LOAN WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM AND RETURN_DATE IS NULL END-EXEC DISPLAY 'sqlcode after select= ' SQLCODE IF SQLCODE = 100 MOVE 'NOTF' TO HRR-STATUS-CODE MOVE 'Loan not found or already returned' TO HRR-MESSAGE EXIT END-IF IF SQLCODE NOT = 0 PERFORM SQL-ERROR EXIT END-IF EXEC SQL UPDATE LOAN SET RETURN_DATE = CURRENT DATE WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM AND RETURN_DATE IS NULL END-EXEC DISPLAY 'sqlcode after update= ' SQLCODE IF SQLCODE NOT = 0 PERFORM SQL-ERROR EXIT END-IF MOVE 'OK' TO HRR-STATUS-CODE MOVE 'Loan returned' TO HRR-MESSAGE DISPLAY 'LOAN RETURNED, ID=' HRR-LOAN-ID-R CONTINUE. PROCESS-ACTIVE-BY-USER. MOVE SPACES TO HOST-ACTIVE-BY-USER-RESPONSE. MOVE HAU-USER-ID TO HAU-USER-ID-R. MOVE 0 TO WS-ACTIVE-LOAN-COUNT HAU-LOAN-COUNT. MOVE SPACES TO HAU-LOANS. IF HAU-USER-ID = SPACES MOVE 'ERR ' TO HAU-STATUS-CODE MOVE 'Missing userId' TO HAU-MESSAGE EXIT END-IF EXEC SQL OPEN CUR-ACTIVE-LOANS END-EXEC IF SQLCODE NOT = 0 PERFORM SQL-ERROR EXIT END-IF PERFORM UNTIL WS-ACTIVE-LOAN-COUNT >= 50 EXEC SQL FETCH CUR-ACTIVE-LOANS INTO :WS-ACTIVE-LOAN-ID-NUM, :WS-ACTIVE-BOOK-ID END-EXEC IF SQLCODE = 0 ADD 1 TO WS-ACTIVE-LOAN-COUNT MOVE WS-ACTIVE-LOAN-ID-NUM TO WS-NEW-LOAN-NUM MOVE SPACES TO WS-NEW-LOAN-ID MOVE 'L' TO WS-NEW-LOAN-ID (1:1) MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9) MOVE WS-NEW-LOAN-ID TO HAU-LOAN-ID (WS-ACTIVE-LOAN-COUNT) MOVE WS-ACTIVE-BOOK-ID TO HAU-BOOK-ID (WS-ACTIVE-LOAN-COUNT) ELSE IF SQLCODE = 100 EXIT PERFORM ELSE PERFORM SQL-ERROR EXIT PERFORM END-IF END-IF END-PERFORM EXEC SQL CLOSE CUR-ACTIVE-LOANS END-EXEC IF HAU-STATUS-CODE NOT = 'ERR ' MOVE WS-ACTIVE-LOAN-COUNT TO HAU-LOAN-COUNT MOVE 'OK' TO HAU-STATUS-CODE MOVE 'Active loans returned' TO HAU-MESSAGE END-IF EXIT. BUILD-RESPONSE. MOVE SPACES TO RSP-DATA. IF WS-REQUEST-TYPE = 'ACTIVE' MOVE HOST-ACTIVE-BY-USER-RESPONSE TO RSP-DATA ELSE IF WS-REQUEST-TYPE = 'RETURN' MOVE HOST-RETURN-RESPONSE TO RSP-DATA ELSE MOVE HOST-BORROW-RESPONSE TO RSP-DATA END-IF END-IF. EXIT. SQL-ERROR. MOVE SPACES TO WS-SQL-MSG. MOVE SQLCODE TO WS-SQLCODE-EDIT. STRING 'SQL ERROR ' DELIMITED BY SIZE WS-SQLCODE-EDIT DELIMITED BY SIZE INTO WS-SQL-MSG. IF WS-REQUEST-TYPE = 'ACTIVE' MOVE 'ERR ' TO HAU-STATUS-CODE MOVE WS-SQL-MSG TO HAU-MESSAGE ELSE IF WS-REQUEST-TYPE = 'RETURN' MOVE 'ERR ' TO HRR-STATUS-CODE MOVE WS-SQL-MSG TO HRR-MESSAGE ELSE MOVE 'ERR ' TO HBR-STATUS-CODE MOVE WS-SQL-MSG TO HBR-MESSAGE END-IF END-IF. CONTINUE. EXIT. ****************************************************************** ** Parse XML request into HOST-BORROW-REQUEST ****************************************************************** PARSE-XML-REQUEST. MOVE SPACES TO HOST-BORROW-REQUEST HOST-RETURN-REQUEST HOST-ACTIVE-BY-USER-REQUEST. MOVE 'OK' TO HBR-STATUS-CODE HRR-STATUS-CODE HAU-STATUS-CODE. MOVE SPACES TO HBR-MESSAGE HRR-MESSAGE HAU-MESSAGE. MOVE SPACES TO WS-REQUEST-TYPE. MOVE 0 TO WS-ACTIVE-REQ-COUNT. INSPECT WS-XML-REQUEST TALLYING WS-ACTIVE-REQ-COUNT FOR ALL "<HostActiveLoansByUserRequest". MOVE 0 TO WS-RETURN-COUNT. INSPECT WS-XML-REQUEST TALLYING WS-RETURN-COUNT FOR ALL "<HostReturnRequest". IF WS-ACTIVE-REQ-COUNT > 0 MOVE 'ACTIVE' TO WS-REQUEST-TYPE PERFORM EXTRACT-ACTIVE-USER-ID IF HAU-USER-ID = SPACES MOVE 'ERR ' TO HAU-STATUS-CODE MOVE 'Invalid XML' TO HAU-MESSAGE END-IF ELSE IF WS-RETURN-COUNT > 0 MOVE 'RETURN' TO WS-REQUEST-TYPE PERFORM EXTRACT-LOAN-ID IF HRR-LOAN-ID = SPACES MOVE 'ERR ' TO HRR-STATUS-CODE MOVE 'Invalid XML' TO HRR-MESSAGE END-IF ELSE MOVE 'BORROW' TO WS-REQUEST-TYPE PERFORM EXTRACT-USER PERFORM EXTRACT-BOOK IF HBR-USER-ID = SPACES OR HBR-BOOK-ID = SPACES MOVE 'ERR ' TO HBR-STATUS-CODE MOVE 'Invalid XML' TO HBR-MESSAGE END-IF END-IF END-IF. EXIT. EXTRACT-USER. MOVE 0 TO WS-START WS-END WS-LEN. INSPECT WS-XML-REQUEST TALLYING WS-START FOR CHARACTERS BEFORE WS-TAG-USER-START. IF WS-START >= LENGTH OF WS-XML-REQUEST EXIT END-IF COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-USER-START. INSPECT WS-XML-REQUEST TALLYING WS-END FOR CHARACTERS BEFORE WS-TAG-USER-END. IF WS-END <= WS-START EXIT END-IF COMPUTE WS-LEN = WS-END - WS-START. IF WS-LEN > 0 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-USER-ID END-IF DISPLAY 'EXTRACT-USER: ' HBR-USER-ID EXIT. EXTRACT-BOOK. MOVE 0 TO WS-START WS-END WS-LEN. INSPECT WS-XML-REQUEST TALLYING WS-START FOR CHARACTERS BEFORE WS-TAG-BOOK-START. IF WS-START >= LENGTH OF WS-XML-REQUEST EXIT END-IF COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-BOOK-START. INSPECT WS-XML-REQUEST TALLYING WS-END FOR CHARACTERS BEFORE WS-TAG-BOOK-END. IF WS-END <= WS-START EXIT END-IF COMPUTE WS-LEN = WS-END - WS-START. IF WS-LEN > 0 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-BOOK-ID END-IF DISPLAY 'EXTRACT-BOOK: ' HBR-BOOK-ID EXIT. EXTRACT-ACTIVE-USER-ID. MOVE 0 TO WS-START WS-END WS-LEN. INSPECT WS-XML-REQUEST TALLYING WS-START FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-START. IF WS-START >= LENGTH OF WS-XML-REQUEST EXIT END-IF COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-ACTIVE-USERID-START. INSPECT WS-XML-REQUEST TALLYING WS-END FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-END. IF WS-END <= WS-START EXIT END-IF COMPUTE WS-LEN = WS-END - WS-START. IF WS-LEN > 0 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HAU-USER-ID END-IF DISPLAY 'EXTRACT-ACTIVE-USER-ID: ' HAU-USER-ID EXIT. EXTRACT-LOAN-ID. MOVE 0 TO WS-START WS-END WS-LEN. INSPECT WS-XML-REQUEST TALLYING WS-START FOR CHARACTERS BEFORE WS-TAG-LOANID-START. IF WS-START >= LENGTH OF WS-XML-REQUEST EXIT END-IF COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-LOANID-START. INSPECT WS-XML-REQUEST TALLYING WS-END FOR CHARACTERS BEFORE WS-TAG-LOANID-END. IF WS-END <= WS-START EXIT END-IF COMPUTE WS-LEN = WS-END - WS-START. IF WS-LEN > 0 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HRR-LOAN-ID END-IF DISPLAY 'EXTRACT-LOAN-ID: ' HRR-LOAN-ID EXIT. ****************************************************************** ** Build XML response from HOST-BORROW-RESPONSE ****************************************************************** BUILD-XML-RESPONSE. MOVE SPACES TO WS-XML-RESPONSE. IF WS-REQUEST-TYPE = 'ACTIVE' MOVE 1 TO WS-PTR STRING '<HostActiveLoansByUserResponse ' DELIMITED BY SIZE ' xmlns="http://company.com/library/host/schema">' DELIMITED BY SIZE '<statusCode>' DELIMITED BY SIZE FUNCTION TRIM(HAU-STATUS-CODE) DELIMITED BY SIZE '</statusCode>' DELIMITED BY SIZE '<message>' DELIMITED BY SIZE FUNCTION TRIM(HAU-MESSAGE) DELIMITED BY SIZE '</message>' DELIMITED BY SIZE '<userId>' DELIMITED BY SIZE FUNCTION TRIM(HAU-USER-ID-R) DELIMITED BY SIZE '</userId>' DELIMITED BY SIZE INTO WS-XML-RESPONSE WITH POINTER WS-PTR END-STRING MOVE 1 TO WS-INDEX PERFORM UNTIL WS-INDEX > HAU-LOAN-COUNT STRING '<loan>' DELIMITED BY SIZE '<loanId>' DELIMITED BY SIZE FUNCTION TRIM(HAU-LOAN-ID (WS-INDEX)) DELIMITED BY SIZE '</loanId>' DELIMITED BY SIZE '<bookId>' DELIMITED BY SIZE FUNCTION TRIM(HAU-BOOK-ID (WS-INDEX)) DELIMITED BY SIZE '</bookId>' DELIMITED BY SIZE '</loan>' DELIMITED BY SIZE INTO WS-XML-RESPONSE WITH POINTER WS-PTR END-STRING ADD 1 TO WS-INDEX END-PERFORM STRING '</HostActiveLoansByUserResponse>' DELIMITED BY SIZE INTO WS-XML-RESPONSE WITH POINTER WS-PTR END-STRING ELSE IF WS-REQUEST-TYPE = 'RETURN' STRING '<HostReturnResponse ' DELIMITED BY SIZE ' xmlns="http://company.com/library/host/schema">' DELIMITED BY SIZE '<loan>' DELIMITED BY SIZE '<loanId>' DELIMITED BY SIZE HRR-LOAN-ID-R DELIMITED BY SIZE '</loanId>' DELIMITED BY SIZE '<user>' DELIMITED BY SIZE '<id>' DELIMITED BY SIZE HRR-USER-ID-R DELIMITED BY SIZE '</id>' DELIMITED BY SIZE '</user>' DELIMITED BY SIZE '<book>' DELIMITED BY SIZE '<id>' DELIMITED BY SIZE HRR-BOOK-ID-R DELIMITED BY SIZE '</id>' DELIMITED BY SIZE '</book>' DELIMITED BY SIZE '</loan>' DELIMITED BY SIZE '<statusCode>' DELIMITED BY SIZE FUNCTION TRIM(HRR-STATUS-CODE) DELIMITED BY SIZE '</statusCode>' DELIMITED BY SIZE '<message>' DELIMITED BY SIZE FUNCTION TRIM(HRR-MESSAGE) DELIMITED BY SIZE '</message>' DELIMITED BY SIZE '</HostReturnResponse>' DELIMITED BY SIZE INTO WS-XML-RESPONSE END-STRING ELSE STRING '<HostBorrowResponse ' DELIMITED BY SIZE ' xmlns="http://company.com/library/host/schema">' DELIMITED BY SIZE '<loan>' DELIMITED BY SIZE '<loanId>' DELIMITED BY SIZE HBR-LOAN-ID DELIMITED BY SIZE '</loanId>' DELIMITED BY SIZE '<user>' DELIMITED BY SIZE '<id>' DELIMITED BY SIZE HBR-USER-ID-R DELIMITED BY SIZE '</id>' DELIMITED BY SIZE '</user>' DELIMITED BY SIZE '<book>' DELIMITED BY SIZE '<id>' DELIMITED BY SIZE HBR-BOOK-ID-R DELIMITED BY SIZE '</id>' DELIMITED BY SIZE '</book>' DELIMITED BY SIZE '</loan>' DELIMITED BY SIZE '<statusCode>' DELIMITED BY SIZE FUNCTION TRIM(HBR-STATUS-CODE) DELIMITED BY SIZE '</statusCode>' DELIMITED BY SIZE '<message>' DELIMITED BY SIZE FUNCTION TRIM(HBR-MESSAGE) DELIMITED BY SIZE '</message>' DELIMITED BY SIZE '</HostBorrowResponse>' DELIMITED BY SIZE INTO WS-XML-RESPONSE END-STRING END-IF END-IF. MOVE SPACES TO RSP-DATA. MOVE WS-XML-RESPONSE TO RSP-DATA. EXIT. END PROGRAM LIBMQCIC.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Да, по этому фрагменту **ASRA/PROTECTION почти наверняка происходит на MQI-вызове из-за “грязных” MQ-структур** (неинициализированные `MQOD/MQMD/MQGMO/MQPMO`, неверные `STRUCID/VERSION/OPTIONS` в памяти). В batch это иногда “случайно” прокатывает, а в CICS чаще падает 0C4.

### Что именно в твоём коде сейчас рискованно

Ты делаешь, например:

MOVE MQOD-VERSION-4 TO MQOD-VERSION.  
MOVE WS-REQ-QUEUE   TO MQOD-OBJECTNAME.  
CALL 'MQOPEN' USING ... MQM-OBJECT-DESCRIPTOR ...

Но **до этого ты не загрузил MQOD дефолтами**, поэтому `MQOD-STRUCID`/прочие поля могут быть мусором → MQOPEN уходит в protection.

---

## Минимальный патч, который обычно сразу убирает ASRA

### 1) Сразу после стартовых DISPLAY добавь инициализацию дефолтами

Прямо **перед `CALL 'MQCONN'`**:

           DISPLAY 'A: INIT MQ STRUCTS (DEFAULTS)'.  
  
           MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR.  
           MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR.  
           MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS.  
           MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS.

> Имена `MQOD-DEFAULT/MQMD-DEFAULT/MQGMO-DEFAULT/MQPMO-DEFAULT` обычно есть в `CMQODV/CMQMDV/CMQGMOV/CMQPMOV`.  
> Если у тебя они называются чуть иначе (например `...-DEFAULTS`), найди их в copybook (это самый быстрый поиск по `DEFAULT`).

### 2) Добавь “маячки” вокруг MQCALL’ов (чтобы точно увидеть, на каком падает)

Это поможет, даже если CEDF WS недоступен:

           DISPLAY 'B: BEFORE MQCONN QMGR=[' WS-QMGR-NAME ']'.  
           CALL 'MQCONN' USING WS-QMGR-NAME HCONN COMPCODE REASON.  
           DISPLAY 'C: AFTER  MQCONN CC=' COMPCODE ' RC=' REASON.  
  
           DISPLAY 'D: BEFORE MQOPEN REQ [' WS-REQ-QUEUE ']'.  
           ...  
           DISPLAY 'E: AFTER  MQOPEN REQ CC=' COMPCODE ' RC=' REASON.

Если ты увидишь `B`, но не увидишь `C` — значит падение **внутри MQCONN**, и тогда почти 100% это интерфейс/структуры/линковка.

### 3) MQMD для MQGET: лучше тоже задать тип/опции после дефолтов

После `MOVE MQMD-DEFAULT ...` твои:

MOVE MQMT-DATAGRAM TO MQMD-MSGTYPE.  
MOVE 1047          TO MQMD-CODEDCHARSETID  
MOVE MQENC-NATIVE  TO MQMD-ENCODING

— уже будут безопаснее.

---

## Ещё 2 быстрых sanity checks (без патча кода)

1. **Очереди**: `WS-REQ-QUEUE`/`WS-REP-QUEUE` должны быть ровно теми, что реально существуют/доступны. Сейчас у тебя `'LIB.REQ.TEST'`/`'LIB.REP.TEST'` — ок, если ты их создал.
    
2. **QMGR**: `WS-QMGR-NAME = SPACES` означает “подключиться к default QM”. На стенде это обычно нормально. Если хочешь явно: `VALUE 'CSQ9'`.
    

---

## Почему CEDF Working-Storage был недоступен

Это классика при 0C4 очень рано/на внешнем вызове: CEDF уже показывает ASRA, но не может вычислить адрес WS (видел `ADDRESS: 00000000`). Поэтому “маячки” + дефолты — самый практичный способ.

---

Если хочешь, я сделаю тебе **готовый пропатченный `LIBMQCIC.cbl`** (с `MQxx-DEFAULT` + маячками) и дам ссылку для скачивания — просто скажи, что в твоих copybooks точно называется дефолт (например, существует ли `MQOD-DEFAULT` как поле/литерал).

  

дай мне ссылку на новый вариант

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — вот новый вариант `LIBMQCIC` с **инициализацией MQ структур через MQxx-DEFAULT** + **маячки DISPLAY** вокруг `MQCONN/MQOPEN/MQGET`, чтобы быстро поймать место ASRA.

Скачать:

- LIBMQCIC_mqdefaults_trace.cbl
    
- (дополнительно) LIBMQCIC_mqdefaults_trace.diff 
    

  

нужно CBL SQL OFFSET TEST NOXREF NOMAP?

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Для **диагностики ASRA** — да, такой набор опций вполне ок:

CBL SQL OFFSET TEST NOXREF NOMAP

### Что здесь реально важно

- **TEST** — полезно для отладки/инструментов, иногда помогает CEDF/дампам.
    
- **OFFSET** — очень полезно, чтобы сопоставлять адрес/offset из сообщений/дампа с листингом.
    
- **SQL** — нужно, раз у тебя embedded SQL.
    

### Что опционально

- `NOXREF NOMAP` — нормально, уменьшает шум.
    
- `LIST` — _не обязателен_, но иногда удобен. Если тебе нужно быстрее сопоставлять — можно временно добавить `LIST`, но листинг раздуется.
    

### Рекомендация по режимам

- **На время отладки**:  
    `CBL SQL OFFSET TEST NOXREF NOMAP` _(или добавить `LIST`, если хочешь больше информации)_
    
- **После стабилизации** (когда ASRA уйдёт):  
    вернуть “тихий” вариант без TEST/OFFSET, например `CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE`.
    

Если хочешь, я могу подсказать ещё и минимальные JCL-параметры компиляции/линковки под debug (например, чтобы точно были offsets в листинге).

  

1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 1 0Invocation parameters: SQL 0PROCESS(CBL) statements: CBL SQL OFFSET TEST NOXREF NOMAP Process rent,nodynam 0Options in effect: NOADATA ADV AFP(NOVOLATILE) QUOTE ARCH(10) ARITH(COMPAT) NOAWO NOBLOCK0 BUFSIZE(4096) NOCICS CODEPAGE(1140) NOCOMPILE(S) CONDCOMP(NOSKIPSRC) NOCOPYLOC NOCOPYRIGHT NOCURRENCY DATA(31) DBCS NODECK NODEFINE NODIAGTRUNC DISPSIGN(COMPAT) NODLL NODUMP NODYNAM NOEXIT NOEXPORTALL NOFASTSRT FLAG(I,I) NOFLAGSTD HGPR(PRESERVE) NOINITCHECK NOINITIAL INLINE INTDATE(ANSI) NOINVDATA NOJAVAIOP LANGUAGE(EN) LINECOUNT(60) NOLIST LP(32) NOLSACHECK NOMAP MAXPCF(100000) NOMDECK NONAME NSYMBOL(NATIONAL) NONUMBER NONUMCHECK NUMPROC(NOPFD) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 2 0 OBJECT OFFSET OPTIMIZE(0) OUTDD(SYSOUT) NOPARMCHECK PGMNAME(COMPAT) QUALIFY(COMPAT) RENT RMODE(AUTO) NORULES NOSERVICE SEQUENCE SMARTBIN(NONAMES) SOURCE(DEC) SPACE(1) SQL SQLCCSID NOSQLIMS NOSSRANGE NOSTGOPT SUPPRESS NOTERM TEST(NOEJPD,DWARF,SOURCE,NOSEPARATE) NOTHREAD TRUNC(STD) TUNE(10) NOVBREF VLR(STANDARD) VSAMOPENFS(COMPAT) NOWORD XMLPARSE(XMLSS) NOXREF ZWB IGYOS4077-I DSNH4790I DSNHPSRV DSNHDECP HAS CCSID 1047 IN EFFECT IGYOS4078-W DSNH4791I DSNHPSRV CCSID 1140 IS USED TO PROCESS SQL, BUT DSNHDECP HAS EBCDIC CCSID 1047 IN EFFECT IGYOS4077-I DSNH4760I DSNHPSRV THE DB2 SQL COPROCESSOR IS USING THE LEVEL 2 INTERFACE UNDER DB2 V13 -SQL Options in effect: ATTACH(TSO) CCSID(1140) CONNECT(2) DEC(15) DECP(DSNHDECP) SQLLEVEL(V13R1M504) ONEPASS PERIOD QUOTESQL STDSQL(NO) SQL(DB2) NOXREF NOSOURCE 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 3 0 DSNHDECP LOADED FROM - (DSND10.DBDG.SDSNEXIT(DSNHDECP)) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 4 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000001 IDENTIFICATION DIVISION. 000002 PROGRAM-ID. LIBMQCIC. 000003 000004 ENVIRONMENT DIVISION. 000005 INPUT-OUTPUT SECTION. 000006 FILE-CONTROL. 000007 SELECT PARAMSFILE ASSIGN TO PARAMS 000008 ORGANIZATION IS SEQUENTIAL 000009 ACCESS IS SEQUENTIAL 000010 FILE STATUS IS PARAMS-STATUS. 000011 000012 DATA DIVISION. 000013 FILE SECTION. 000014 FD PARAMSFILE 000015 RECORDING MODE IS F 000016 RECORD CONTAINS 80 CHARACTERS. 000017 01 PARAMS-REC PIC X(80). 000018 000019 WORKING-STORAGE SECTION. 000020 000021 EXEC SQL INCLUDE SQLCA END-EXEC. 000022C 01 SQLCA GLOBAL VOLATILE. 000023C 05 SQLCAID PIC X(8). 000024C 05 SQLCABC PIC S9(9) COMP-5. 000025C 05 SQLCODE PIC S9(9) COMP-5. 000026C 05 SQLERRM. 000027C 49 SQLERRML PIC S9(4) COMP-5. 000028C 49 SQLERRMC PIC X(70). 000029C 05 SQLERRP PIC X(8). 000030C 05 SQLERRD PIC S9(9) COMP-5 000031C OCCURS 6 TIMES. 000032C 05 SQLWARN. 000033C 10 SQLWARN0 PIC X. 000034C 10 SQLWARN1 PIC X. 000035C 10 SQLWARN2 PIC X. 000036C 10 SQLWARN3 PIC X. 000037C 10 SQLWARN4 PIC X. 000038C 10 SQLWARN5 PIC X. 000039C 10 SQLWARN6 PIC X. 000040C 10 SQLWARN7 PIC X. 000041C 05 SQLEXT. 000042C 10 SQLWARN8 PIC X. 000043C 10 SQLWARN9 PIC X. 000044C 10 SQLWARNA PIC X. 000045C 10 SQLSTATE PIC X(5). 000046 000047 01 PARAMS-STATUS PIC XX. 000048 01 WS-SQLCODE-EDIT PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY. 000049 000050 01 MQM-CONSTANTS. 000051 COPY CMQV. 000052C ****************************************************************** 000053C ** ** 000054C ** IBM MQ for z/OS ** 000055C ** ** 000056C ** FILE NAME: CMQV ** 000057C ** ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 5 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000058C ** DESCRIPTION: Declarations for Main MQI ** 000059C ** ** 000060C ****************************************************************** 000061C ** @START_COPYRIGHT@ ** 000062C ** Statement: Licensed Materials - Property of IBM ** 000063C ** ** 000064C ** 5655-MQ9 ** 000065C ** (C) Copyright IBM Corporation. 1997, 2026 ** 000066C ** @END_COPYRIGHT@ ** 000067C ****************************************************************** 000068C ** ** 000069C ** FUNCTION: This file declares the functions, ** 000070C ** structures and named constants for the ** 000071C ** main MQI. ** 000072C ** ** 000073C ** PROCESSOR: COBOL ** 000074C ** ** 000075C ****************************************************************** 000076C 000077C ****************************************************************** 000078C ** Values Related to MQAIR Structure 000079C ****************************************************************** 000080C ** Structure Identifier 000081C 10 MQAIR-STRUC-ID PIC X(4) VALUE 'AIR '. 000082C 000083C ** Structure Version Number 000084C 10 MQAIR-VERSION-1 PIC S9(9) BINARY VALUE 1. 000085C 10 MQAIR-VERSION-2 PIC S9(9) BINARY VALUE 2. 000086C 10 MQAIR-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000087C 000088C ** Structure Length 000089C 10 MQAIR-LENGTH-1 PIC S9(9) BINARY VALUE 320. 000090C 10 MQAIR-LENGTH-2 PIC S9(9) BINARY VALUE 576. 000091C 10 MQAIR-CURRENT-LENGTH PIC S9(9) BINARY VALUE 576. 000092C 000093C ** Authentication Information Type 000094C 10 MQAIT-ALL PIC S9(9) BINARY VALUE 0. 000095C 10 MQAIT-CRL-LDAP PIC S9(9) BINARY VALUE 1. 000096C 10 MQAIT-OCSP PIC S9(9) BINARY VALUE 2. 000097C 10 MQAIT-IDPW-OS PIC S9(9) BINARY VALUE 3. 000098C 10 MQAIT-IDPW-LDAP PIC S9(9) BINARY VALUE 4. 000099C 000100C ****************************************************************** 000101C ** Values Related to MQBNO Structure 000102C ****************************************************************** 000103C ** Structure Identifier 000104C 10 MQBNO-STRUC-ID PIC X(4) VALUE 'BNO '. 000105C 000106C ** Structure Version Number 000107C 10 MQBNO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000108C 10 MQBNO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000109C 000110C ** Structure Length 000111C 10 MQBNO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 000112C 10 MQBNO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 000113C 000114C ** MQ Balancing Options 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 6 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000115C 10 MQBNO-OPTIONS-NONE PIC S9(9) BINARY VALUE 0. 000116C 10 MQBNO-OPTIONS-IGNORE-TRANS PIC S9(9) BINARY VALUE 1. 000117C 000118C ** MQ Balancing Application Type 000119C 10 MQBNO-BALTYPE-SIMPLE PIC S9(9) BINARY VALUE 0. 000120C 10 MQBNO-BALTYPE-REQREP PIC S9(9) BINARY VALUE 1. 000121C 10 MQBNO-BALTYPE-RA-MANAGED PIC S9(9) BINARY VALUE 65536. 000122C 000123C ** MQ Balancing Timeout 000124C 10 MQBNO-TIMEOUT-AS-DEFAULT PIC S9(9) BINARY VALUE -1. 000125C 10 MQBNO-TIMEOUT-IMMEDIATE PIC S9(9) BINARY VALUE 0. 000126C 10 MQBNO-TIMEOUT-NEVER PIC S9(9) BINARY VALUE -2. 000127C 000128C ****************************************************************** 000129C ** Values Related to MQBMHO Structure 000130C ****************************************************************** 000131C ** Structure Identifier 000132C 10 MQBMHO-STRUC-ID PIC X(4) VALUE 'BMHO'. 000133C 000134C ** Structure Version Number 000135C 10 MQBMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000136C 10 MQBMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000137C 000138C ** Structure Length 000139C 10 MQBMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000140C 10 MQBMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000141C 000142C ** Buffer To Message Handle Options 000143C 10 MQBMHO-NONE PIC S9(9) BINARY VALUE 0. 000144C 10 MQBMHO-DELETE-PROPERTIES PIC S9(9) BINARY VALUE 1. 000145C 000146C ****************************************************************** 000147C ** Values Related to MQCBC Structure 000148C ****************************************************************** 000149C ** Structure Identifier 000150C 10 MQCBC-STRUC-ID PIC X(4) VALUE 'CBC '. 000151C 000152C ** Structure Version Number 000153C 10 MQCBC-VERSION-1 PIC S9(9) BINARY VALUE 1. 000154C 10 MQCBC-VERSION-2 PIC S9(9) BINARY VALUE 2. 000155C 10 MQCBC-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000156C 000157C ** Structure Length 000158C 10 MQCBC-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000159C 10 MQCBC-LENGTH-2 PIC S9(9) BINARY VALUE 52. 000160C 10 MQCBC-CURRENT-LENGTH PIC S9(9) BINARY VALUE 52. 000161C 000162C ** Flags 000163C 10 MQCBCF-NONE PIC S9(9) BINARY VALUE 0. 000164C 10 MQCBCF-READA-BUFFER-EMPTY PIC S9(9) BINARY VALUE 1. 000165C 000166C ** Callback type 000167C 10 MQCBCT-START-CALL PIC S9(9) BINARY VALUE 1. 000168C 10 MQCBCT-STOP-CALL PIC S9(9) BINARY VALUE 2. 000169C 10 MQCBCT-REGISTER-CALL PIC S9(9) BINARY VALUE 3. 000170C 10 MQCBCT-DEREGISTER-CALL PIC S9(9) BINARY VALUE 4. 000171C 10 MQCBCT-EVENT-CALL PIC S9(9) BINARY VALUE 5. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 7 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000172C 10 MQCBCT-MSG-REMOVED PIC S9(9) BINARY VALUE 6. 000173C 10 MQCBCT-MSG-NOT-REMOVED PIC S9(9) BINARY VALUE 7. 000174C 10 MQCBCT-MC-EVENT-CALL PIC S9(9) BINARY VALUE 8. 000175C 000176C ** Consumer state 000177C 10 MQCS-NONE PIC S9(9) BINARY VALUE 0. 000178C 10 MQCS-SUSPENDED-TEMPORARY PIC S9(9) BINARY VALUE 1. 000179C 10 MQCS-SUSPENDED-USER-ACTION PIC S9(9) BINARY VALUE 2. 000180C 10 MQCS-SUSPENDED PIC S9(9) BINARY VALUE 3. 000181C 10 MQCS-STOPPED PIC S9(9) BINARY VALUE 4. 000182C 000183C ** Reconnect delay 000184C 10 MQRD-NO-RECONNECT PIC S9(9) BINARY VALUE -1. 000185C 10 MQRD-NO-DELAY PIC S9(9) BINARY VALUE 0. 000186C 000187C ****************************************************************** 000188C ** Values Related to MQCBD Structure 000189C ****************************************************************** 000190C ** Structure Identifier 000191C 10 MQCBD-STRUC-ID PIC X(4) VALUE 'CBD '. 000192C 000193C ** Structure Version Number 000194C 10 MQCBD-VERSION-1 PIC S9(9) BINARY VALUE 1. 000195C 10 MQCBD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000196C 000197C ** Structure Length 000198C 10 MQCBD-LENGTH-1 PIC S9(9) BINARY VALUE 156. 000199C 10 MQCBD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 156. 000200C 000201C ** Callback Options 000202C 10 MQCBDO-NONE PIC S9(9) BINARY VALUE 0. 000203C 10 MQCBDO-START-CALL PIC S9(9) BINARY VALUE 1. 000204C 10 MQCBDO-STOP-CALL PIC S9(9) BINARY VALUE 4. 000205C 10 MQCBDO-REGISTER-CALL PIC S9(9) BINARY VALUE 256. 000206C 10 MQCBDO-DEREGISTER-CALL PIC S9(9) BINARY VALUE 512. 000207C 10 MQCBDO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000208C 10 MQCBDO-EVENT-CALL PIC S9(9) BINARY VALUE 16384. 000209C 10 MQCBDO-MC-EVENT-CALL PIC S9(9) BINARY VALUE 32768. 000210C 000211C ** This is the type of the Callback Function 000212C 10 MQCBT-MESSAGE-CONSUMER PIC S9(9) BINARY VALUE 1. 000213C 10 MQCBT-EVENT-HANDLER PIC S9(9) BINARY VALUE 2. 000214C 000215C ** Buffer size values 000216C 10 MQCBD-FULL-MSG-LENGTH PIC S9(9) BINARY VALUE -1. 000217C 000218C ****************************************************************** 000219C ** Values Related to MQCHARV Structure 000220C ****************************************************************** 000221C ** Variable String Length 000222C 10 MQVS-NULL-TERMINATED PIC S9(9) BINARY VALUE -1. 000223C 000224C ****************************************************************** 000225C ** Values Related to MQCIH Structure 000226C ****************************************************************** 000227C ** Structure Identifier 000228C 10 MQCIH-STRUC-ID PIC X(4) VALUE 'CIH '. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 8 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000229C 000230C ** Structure Version Number 000231C 10 MQCIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000232C 10 MQCIH-VERSION-2 PIC S9(9) BINARY VALUE 2. 000233C 10 MQCIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000234C 000235C ** Structure Length 000236C 10 MQCIH-LENGTH-1 PIC S9(9) BINARY VALUE 164. 000237C 10 MQCIH-LENGTH-2 PIC S9(9) BINARY VALUE 180. 000238C 10 MQCIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 180. 000239C 000240C ** Flags 000241C 10 MQCIH-NONE PIC S9(9) BINARY VALUE 0. 000242C 10 MQCIH-PASS-EXPIRATION PIC S9(9) BINARY VALUE 1. 000243C 10 MQCIH-UNLIMITED-EXPIRATION PIC S9(9) BINARY VALUE 0. 000244C 10 MQCIH-REPLY-WITHOUT-NULLS PIC S9(9) BINARY VALUE 2. 000245C 10 MQCIH-REPLY-WITH-NULLS PIC S9(9) BINARY VALUE 0. 000246C 10 MQCIH-SYNC-ON-RETURN PIC S9(9) BINARY VALUE 4. 000247C 10 MQCIH-NO-SYNC-ON-RETURN PIC S9(9) BINARY VALUE 0. 000248C 000249C ** Return Codes 000250C 10 MQCRC-OK PIC S9(9) BINARY VALUE 0. 000251C 10 MQCRC-CICS-EXEC-ERROR PIC S9(9) BINARY VALUE 1. 000252C 10 MQCRC-MQ-API-ERROR PIC S9(9) BINARY VALUE 2. 000253C 10 MQCRC-BRIDGE-ERROR PIC S9(9) BINARY VALUE 3. 000254C 10 MQCRC-BRIDGE-ABEND PIC S9(9) BINARY VALUE 4. 000255C 10 MQCRC-APPLICATION-ABEND PIC S9(9) BINARY VALUE 5. 000256C 10 MQCRC-SECURITY-ERROR PIC S9(9) BINARY VALUE 6. 000257C 10 MQCRC-PROGRAM-NOT-AVAILABLE PIC S9(9) BINARY VALUE 7. 000258C 10 MQCRC-BRIDGE-TIMEOUT PIC S9(9) BINARY VALUE 8. 000259C 10 MQCRC-TRANSID-NOT-AVAILABLE PIC S9(9) BINARY VALUE 9. 000260C 000261C ** Unit-of-Work Controls 000262C 10 MQCUOWC-ONLY PIC S9(9) BINARY VALUE 273. 000263C 10 MQCUOWC-CONTINUE PIC S9(9) BINARY VALUE 65536. 000264C 10 MQCUOWC-FIRST PIC S9(9) BINARY VALUE 17. 000265C 10 MQCUOWC-MIDDLE PIC S9(9) BINARY VALUE 16. 000266C 10 MQCUOWC-LAST PIC S9(9) BINARY VALUE 272. 000267C 10 MQCUOWC-COMMIT PIC S9(9) BINARY VALUE 256. 000268C 10 MQCUOWC-BACKOUT PIC S9(9) BINARY VALUE 4352. 000269C 000270C ** Get Wait Interval 000271C 10 MQCGWI-DEFAULT PIC S9(9) BINARY VALUE -2. 000272C 000273C ** Link Types 000274C 10 MQCLT-PROGRAM PIC S9(9) BINARY VALUE 1. 000275C 10 MQCLT-TRANSACTION PIC S9(9) BINARY VALUE 2. 000276C 000277C ** Output Data Length 000278C 10 MQCODL-AS-INPUT PIC S9(9) BINARY VALUE -1. 000279C 000280C ** ADS Descriptors 000281C 10 MQCADSD-NONE PIC S9(9) BINARY VALUE 0. 000282C 10 MQCADSD-SEND PIC S9(9) BINARY VALUE 1. 000283C 10 MQCADSD-RECV PIC S9(9) BINARY VALUE 16. 000284C 10 MQCADSD-MSGFORMAT PIC S9(9) BINARY VALUE 256. 000285C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 9 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000286C ** Conversational Task Options 000287C 10 MQCCT-YES PIC S9(9) BINARY VALUE 1. 000288C 10 MQCCT-NO PIC S9(9) BINARY VALUE 0. 000289C 000290C ** Task End Status 000291C 10 MQCTES-NOSYNC PIC S9(9) BINARY VALUE 0. 000292C 10 MQCTES-COMMIT PIC S9(9) BINARY VALUE 256. 000293C 10 MQCTES-BACKOUT PIC S9(9) BINARY VALUE 4352. 000294C 10 MQCTES-ENDTASK PIC S9(9) BINARY VALUE 65536. 000295C 000296C ** Facility 000297C 10 MQCFAC-NONE PIC X(8) VALUE LOW-VALUES. 000298C 000299C ** Functions 000300C 10 MQCFUNC-MQCONN PIC X(4) VALUE 'CONN'. 000301C 10 MQCFUNC-MQGET PIC X(4) VALUE 'GET '. 000302C 10 MQCFUNC-MQINQ PIC X(4) VALUE 'INQ '. 000303C 10 MQCFUNC-MQOPEN PIC X(4) VALUE 'OPEN'. 000304C 10 MQCFUNC-MQPUT PIC X(4) VALUE 'PUT '. 000305C 10 MQCFUNC-MQPUT1 PIC X(4) VALUE 'PUT1'. 000306C 10 MQCFUNC-NONE PIC X(4) VALUE SPACES. 000307C 000308C ** Start Codes 000309C 10 MQCSC-START PIC X(4) VALUE 'S '. 000310C 10 MQCSC-STARTDATA PIC X(4) VALUE 'SD '. 000311C 10 MQCSC-TERMINPUT PIC X(4) VALUE 'TD '. 000312C 10 MQCSC-NONE PIC X(4) VALUE SPACES. 000313C 000314C ****************************************************************** 000315C ** Values Related to MQCMHO Structure 000316C ****************************************************************** 000317C ** Structure Identifier 000318C 10 MQCMHO-STRUC-ID PIC X(4) VALUE 'CMHO'. 000319C 000320C ** Structure Version Number 000321C 10 MQCMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000322C 10 MQCMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000323C 000324C ** Structure Length 000325C 10 MQCMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000326C 10 MQCMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000327C 000328C ** Create Message Handle Options 000329C 10 MQCMHO-DEFAULT-VALIDATION PIC S9(9) BINARY VALUE 0. 000330C 10 MQCMHO-NO-VALIDATION PIC S9(9) BINARY VALUE 1. 000331C 10 MQCMHO-VALIDATE PIC S9(9) BINARY VALUE 2. 000332C 10 MQCMHO-NONE PIC S9(9) BINARY VALUE 0. 000333C 000334C ****************************************************************** 000335C ** Values Related to MQCTLO Structure 000336C ****************************************************************** 000337C ** Structure Identifier 000338C 10 MQCTLO-STRUC-ID PIC X(4) VALUE 'CTLO'. 000339C 000340C ** Structure Version Number 000341C 10 MQCTLO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000342C 10 MQCTLO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 10 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000343C 000344C ** Structure Length 000345C 10 MQCTLO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 000346C 10 MQCTLO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 000347C 000348C ** Consumer Control Options 000349C 10 MQCTLO-NONE PIC S9(9) BINARY VALUE 0. 000350C 10 MQCTLO-THREAD-AFFINITY PIC S9(9) BINARY VALUE 1. 000351C 10 MQCTLO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000352C 000353C ****************************************************************** 000354C ** Values Related to MQSCO Structure 000355C ****************************************************************** 000356C ** Structure Identifier 000357C 10 MQSCO-STRUC-ID PIC X(4) VALUE 'SCO '. 000358C 000359C ** Structure Version Number 000360C 10 MQSCO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000361C 10 MQSCO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000362C 10 MQSCO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000363C 10 MQSCO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000364C 10 MQSCO-VERSION-5 PIC S9(9) BINARY VALUE 5. 000365C 10 MQSCO-VERSION-6 PIC S9(9) BINARY VALUE 6. 000366C 10 MQSCO-VERSION-7 PIC S9(9) BINARY VALUE 7. 000367C 10 MQSCO-CURRENT-VERSION PIC S9(9) BINARY VALUE 7. 000368C 000369C ** Structure Length 000370C 10 MQSCO-LENGTH-1 PIC S9(9) BINARY VALUE 532. 000371C 10 MQSCO-LENGTH-2 PIC S9(9) BINARY VALUE 540. 000372C 10 MQSCO-LENGTH-3 PIC S9(9) BINARY VALUE 556. 000373C 10 MQSCO-LENGTH-4 PIC S9(9) BINARY VALUE 560. 000374C 10 MQSCO-LENGTH-5 PIC S9(9) BINARY VALUE 624. 000375C 10 MQSCO-LENGTH-6 PIC S9(9) BINARY VALUE 636. 000376C 10 MQSCO-LENGTH-7 PIC S9(9) BINARY VALUE 656. 000377C 10 MQSCO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 656. 000378C 000379C ** SuiteB Type 000380C 10 MQ-SUITE-B-NOT-AVAILABLE PIC S9(9) BINARY VALUE 0. 000381C 10 MQ-SUITE-B-NONE PIC S9(9) BINARY VALUE 1. 000382C 10 MQ-SUITE-B-128-BIT PIC S9(9) BINARY VALUE 2. 000383C 10 MQ-SUITE-B-192-BIT PIC S9(9) BINARY VALUE 4. 000384C 000385C ** Key Reset Count 000386C 10 MQSCO-RESET-COUNT-DEFAULT PIC S9(9) BINARY VALUE 0. 000387C 000388C ** Certificate Validation Policy Type 000389C 10 MQ-CERT-VAL-POLICY-DEFAULT PIC S9(9) BINARY VALUE 0. 000390C 10 MQ-CERT-VAL-POLICY-ANY PIC S9(9) BINARY VALUE 0. 000391C 10 MQ-CERT-VAL-POLICY-RFC5280 PIC S9(9) BINARY VALUE 1. 000392C 10 MQ-CERT-VAL-POLICY-NONE PIC S9(9) BINARY VALUE 2. 000393C 000394C ** HTTPS Certificate Validation Type 000395C 10 MQ-HTTPSCERTVAL-DEFAULT PIC S9(9) BINARY VALUE 0. 000396C 10 MQ-HTTPSCERTVAL-ANY PIC S9(9) BINARY VALUE 1. 000397C 10 MQ-HTTPSCERTVAL-NONE PIC S9(9) BINARY VALUE 2. 000398C 10 MQ-HTTPSCERTVAL-HOSTNAMECN PIC S9(9) BINARY VALUE 3. 000399C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 11 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000400C ** HTTPS Certificate Revocation Type 000401C 10 MQ-HTTPSCERTREV-DEFAULT PIC S9(9) BINARY VALUE 0. 000402C 10 MQ-HTTPSCERTREV-REQUIRED PIC S9(9) BINARY VALUE 1. 000403C 10 MQ-HTTPSCERTREV-DISABLED PIC S9(9) BINARY VALUE 2. 000404C 10 MQ-HTTPSCERTREV-OPTIONAL PIC S9(9) BINARY VALUE 3. 000405C 000406C ****************************************************************** 000407C ** Values Related to MQCSP Structure 000408C ****************************************************************** 000409C ** Structure Identifier 000410C 10 MQCSP-STRUC-ID PIC X(4) VALUE 'CSP '. 000411C 000412C ** Structure Version Number 000413C 10 MQCSP-VERSION-1 PIC S9(9) BINARY VALUE 1. 000414C 10 MQCSP-VERSION-2 PIC S9(9) BINARY VALUE 2. 000415C 10 MQCSP-VERSION-3 PIC S9(9) BINARY VALUE 3. 000416C 10 MQCSP-CURRENT-VERSION PIC S9(9) BINARY VALUE 3. 000417C 000418C ** Structure Length 000419C 10 MQCSP-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000420C 10 MQCSP-LENGTH-2 PIC S9(9) BINARY VALUE 68. 000421C 10 MQCSP-LENGTH-3 PIC S9(9) BINARY VALUE 88. 000422C 10 MQCSP-CURRENT-LENGTH PIC S9(9) BINARY VALUE 88. 000423C 000424C ** Authentication Types 000425C 10 MQCSP-AUTH-NONE PIC S9(9) BINARY VALUE 0. 000426C 10 MQCSP-AUTH-USER-ID-AND-PWD PIC S9(9) BINARY VALUE 1. 000427C 10 MQCSP-AUTH-ID-TOKEN PIC S9(9) BINARY VALUE 2. 000428C 000429C ****************************************************************** 000430C ** Values Related to MQCNO Structure 000431C ****************************************************************** 000432C ** Structure Identifier 000433C 10 MQCNO-STRUC-ID PIC X(4) VALUE 'CNO '. 000434C 000435C ** Structure Version Number 000436C 10 MQCNO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000437C 10 MQCNO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000438C 10 MQCNO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000439C 10 MQCNO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000440C 10 MQCNO-VERSION-5 PIC S9(9) BINARY VALUE 5. 000441C 10 MQCNO-VERSION-6 PIC S9(9) BINARY VALUE 6. 000442C 10 MQCNO-VERSION-7 PIC S9(9) BINARY VALUE 7. 000443C 10 MQCNO-VERSION-8 PIC S9(9) BINARY VALUE 8. 000444C 10 MQCNO-CURRENT-VERSION PIC S9(9) BINARY VALUE 8. 000445C 000446C ** Structure Length 000447C 10 MQCNO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000448C 10 MQCNO-LENGTH-2 PIC S9(9) BINARY VALUE 20. 000449C 10 MQCNO-LENGTH-3 PIC S9(9) BINARY VALUE 148. 000450C 10 MQCNO-LENGTH-4 PIC S9(9) BINARY VALUE 156. 000451C 10 MQCNO-LENGTH-5 PIC S9(9) BINARY VALUE 188. 000452C 10 MQCNO-LENGTH-6 PIC S9(9) BINARY VALUE 208. 000453C 10 MQCNO-LENGTH-7 PIC S9(9) BINARY VALUE 240. 000454C 10 MQCNO-LENGTH-8 PIC S9(9) BINARY VALUE 252. 000455C 10 MQCNO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 252. 000456C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 12 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000457C ** Connect Options 000458C 10 MQCNO-STANDARD-BINDING PIC S9(9) BINARY VALUE 0. 000459C 10 MQCNO-FASTPATH-BINDING PIC S9(9) BINARY VALUE 1. 000460C 10 MQCNO-SERIALIZE-CONN-TAG-Q-MGR PIC S9(9) BINARY VALUE 2. 000461C 10 MQCNO-SERIALIZE-CONN-TAG-QSG PIC S9(9) BINARY VALUE 4. 000462C 10 MQCNO-RESTRICT-CONN-TAG-Q-MGR PIC S9(9) BINARY VALUE 8. 000463C 10 MQCNO-RESTRICT-CONN-TAG-QSG PIC S9(9) BINARY VALUE 16. 000464C 10 MQCNO-HANDLE-SHARE-NONE PIC S9(9) BINARY VALUE 32. 000465C 10 MQCNO-HANDLE-SHARE-BLOCK PIC S9(9) BINARY VALUE 64. 000466C 10 MQCNO-HANDLE-SHARE-NO-BLOCK PIC S9(9) BINARY VALUE 128. 000467C 10 MQCNO-SHARED-BINDING PIC S9(9) BINARY VALUE 256. 000468C 10 MQCNO-ISOLATED-BINDING PIC S9(9) BINARY VALUE 512. 000469C 10 MQCNO-LOCAL-BINDING PIC S9(9) BINARY VALUE 1024. 000470C 10 MQCNO-CLIENT-BINDING PIC S9(9) BINARY VALUE 2048. 000471C 10 MQCNO-ACCOUNTING-MQI-ENABLED PIC S9(9) BINARY VALUE 4096. 000472C 10 MQCNO-ACCOUNTING-MQI-DISABLED PIC S9(9) BINARY VALUE 8192. 000473C 10 MQCNO-ACCOUNTING-Q-ENABLED PIC S9(9) BINARY VALUE 16384. 000474C 10 MQCNO-ACCOUNTING-Q-DISABLED PIC S9(9) BINARY VALUE 32768. 000475C 10 MQCNO-NO-CONV-SHARING PIC S9(9) BINARY VALUE 65536. 000476C 10 MQCNO-ALL-CONVS-SHARE PIC S9(9) BINARY VALUE 262144. 000477C 10 MQCNO-CD-FOR-OUTPUT-ONLY PIC S9(9) BINARY VALUE 524288. 000478C 10 MQCNO-USE-CD-SELECTION PIC S9(9) BINARY VALUE 1048576. 000479C 10 MQCNO-GENERATE-CONN-TAG PIC S9(9) BINARY VALUE 2097152. 000480C 10 MQCNO-RECONNECT-AS-DEF PIC S9(9) BINARY VALUE 0. 000481C 10 MQCNO-RECONNECT PIC S9(9) BINARY VALUE 16777216. 000482C 10 MQCNO-RECONNECT-DISABLED PIC S9(9) BINARY VALUE 33554432. 000483C 10 MQCNO-RECONNECT-Q-MGR PIC S9(9) BINARY VALUE 67108864. 000484C 10 MQCNO-ACTIVITY-TRACE-ENABLED PIC S9(9) BINARY 000485C VALUE 134217728. 000486C 10 MQCNO-ACTIVITY-TRACE-DISABLED PIC S9(9) BINARY 000487C VALUE 268435456. 000488C 10 MQCNO-NONE PIC S9(9) BINARY VALUE 0. 000489C 000490C ** Queue Manager Connection Tag 000491C 10 MQCT-NONE PIC X(128) VALUE LOW-VALUES. 000492C 000493C ** Connection Identifier 000494C 10 MQCONNID-NONE PIC X(24) VALUE LOW-VALUES. 000495C 000496C ** Application Name 000497C 10 MQAN-NONE PIC X(28) VALUE SPACES. 000498C 000499C ****************************************************************** 000500C ** Values Related to MQDH Structure 000501C ****************************************************************** 000502C ** Structure Identifier 000503C 10 MQDH-STRUC-ID PIC X(4) VALUE 'DH '. 000504C 000505C ** Structure Version Number 000506C 10 MQDH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000507C 10 MQDH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000508C 000509C ** Structure Length 000510C 10 MQDH-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000511C 10 MQDH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 48. 000512C 000513C ** Flags 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 13 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000514C 10 MQDHF-NEW-MSG-IDS PIC S9(9) BINARY VALUE 1. 000515C 10 MQDHF-NONE PIC S9(9) BINARY VALUE 0. 000516C 000517C ****************************************************************** 000518C ** Values Related to MQDLH Structure 000519C ****************************************************************** 000520C ** Structure Identifier 000521C 10 MQDLH-STRUC-ID PIC X(4) VALUE 'DLH '. 000522C 000523C ** Structure Version Number 000524C 10 MQDLH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000525C 10 MQDLH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000526C 000527C ** Structure Length 000528C 10 MQDLH-LENGTH-1 PIC S9(9) BINARY VALUE 172. 000529C 10 MQDLH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 172. 000530C 000531C ****************************************************************** 000532C ** Values Related to MQDMHO Structure 000533C ****************************************************************** 000534C ** Structure Identifier 000535C 10 MQDMHO-STRUC-ID PIC X(4) VALUE 'DMHO'. 000536C 000537C ** Structure Version Number 000538C 10 MQDMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000539C 10 MQDMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000540C 000541C ** Structure Length 000542C 10 MQDMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000543C 10 MQDMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000544C 000545C ** Delete Message Handle Options 000546C 10 MQDMHO-NONE PIC S9(9) BINARY VALUE 0. 000547C 000548C ****************************************************************** 000549C ** Values Related to MQDMPO Structure 000550C ****************************************************************** 000551C ** Structure Identifier 000552C 10 MQDMPO-STRUC-ID PIC X(4) VALUE 'DMPO'. 000553C 000554C ** Structure Version Number 000555C 10 MQDMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000556C 10 MQDMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000557C 000558C ** Structure Length 000559C 10 MQDMPO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000560C 10 MQDMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000561C 000562C ** Delete Message Property Options 000563C 10 MQDMPO-DEL-FIRST PIC S9(9) BINARY VALUE 0. 000564C 10 MQDMPO-DEL-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 1. 000565C 10 MQDMPO-NONE PIC S9(9) BINARY VALUE 0. 000566C 000567C ****************************************************************** 000568C ** Values Related to MQGMO Structure 000569C ****************************************************************** 000570C ** Structure Identifier 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 14 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000571C 10 MQGMO-STRUC-ID PIC X(4) VALUE 'GMO '. 000572C 000573C ** Structure Version Number 000574C 10 MQGMO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000575C 10 MQGMO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000576C 10 MQGMO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000577C 10 MQGMO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000578C 10 MQGMO-CURRENT-VERSION PIC S9(9) BINARY VALUE 4. 000579C 000580C ** Structure Length 000581C 10 MQGMO-LENGTH-1 PIC S9(9) BINARY VALUE 72. 000582C 10 MQGMO-LENGTH-2 PIC S9(9) BINARY VALUE 80. 000583C 10 MQGMO-LENGTH-3 PIC S9(9) BINARY VALUE 100. 000584C 10 MQGMO-LENGTH-4 PIC S9(9) BINARY VALUE 112. 000585C 10 MQGMO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 112. 000586C 000587C ** Get Message Options 000588C 10 MQGMO-WAIT PIC S9(9) BINARY VALUE 1. 000589C 10 MQGMO-NO-WAIT PIC S9(9) BINARY VALUE 0. 000590C 10 MQGMO-SET-SIGNAL PIC S9(9) BINARY VALUE 8. 000591C 10 MQGMO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000592C 10 MQGMO-SYNCPOINT PIC S9(9) BINARY VALUE 2. 000593C 10 MQGMO-SYNCPOINT-IF-PERSISTENT PIC S9(9) BINARY VALUE 4096. 000594C 10 MQGMO-NO-SYNCPOINT PIC S9(9) BINARY VALUE 4. 000595C 10 MQGMO-MARK-SKIP-BACKOUT PIC S9(9) BINARY VALUE 128. 000596C 10 MQGMO-BROWSE-FIRST PIC S9(9) BINARY VALUE 16. 000597C 10 MQGMO-BROWSE-NEXT PIC S9(9) BINARY VALUE 32. 000598C 10 MQGMO-BROWSE-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2048. 000599C 10 MQGMO-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 256. 000600C 10 MQGMO-LOCK PIC S9(9) BINARY VALUE 512. 000601C 10 MQGMO-UNLOCK PIC S9(9) BINARY VALUE 1024. 000602C 10 MQGMO-ACCEPT-TRUNCATED-MSG PIC S9(9) BINARY VALUE 64. 000603C 10 MQGMO-CONVERT PIC S9(9) BINARY VALUE 16384. 000604C 10 MQGMO-LOGICAL-ORDER PIC S9(9) BINARY VALUE 32768. 000605C 10 MQGMO-COMPLETE-MSG PIC S9(9) BINARY VALUE 65536. 000606C 10 MQGMO-ALL-MSGS-AVAILABLE PIC S9(9) BINARY VALUE 131072. 000607C 10 MQGMO-ALL-SEGMENTS-AVAILABLE PIC S9(9) BINARY VALUE 262144. 000608C 10 MQGMO-MARK-BROWSE-HANDLE PIC S9(9) BINARY VALUE 1048576. 000609C 10 MQGMO-MARK-BROWSE-CO-OP PIC S9(9) BINARY VALUE 2097152. 000610C 10 MQGMO-UNMARK-BROWSE-CO-OP PIC S9(9) BINARY VALUE 4194304. 000611C 10 MQGMO-UNMARK-BROWSE-HANDLE PIC S9(9) BINARY VALUE 8388608. 000612C 10 MQGMO-UNMARKED-BROWSE-MSG PIC S9(9) BINARY VALUE 16777216. 000613C 10 MQGMO-PROPERTIES-FORCE-MQRFH2 PIC S9(9) BINARY 000614C VALUE 33554432. 000615C 10 MQGMO-NO-PROPERTIES PIC S9(9) BINARY VALUE 67108864. 000616C 10 MQGMO-PROPERTIES-IN-HANDLE PIC S9(9) BINARY 000617C VALUE 134217728. 000618C 10 MQGMO-PROPERTIES-COMPATIBILITY PIC S9(9) BINARY 000619C VALUE 268435456. 000620C 10 MQGMO-PROPERTIES-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 000621C 10 MQGMO-NONE PIC S9(9) BINARY VALUE 0. 000622C 10 MQGMO-BROWSE-HANDLE PIC S9(9) BINARY VALUE 17825808. 000623C 10 MQGMO-BROWSE-CO-OP PIC S9(9) BINARY VALUE 18874384. 000624C 000625C ** Wait Interval 000626C 10 MQWI-UNLIMITED PIC S9(9) BINARY VALUE -1. 000627C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 15 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000628C ** Signal Values 000629C 10 MQEC-MSG-ARRIVED PIC S9(9) BINARY VALUE 2. 000630C 10 MQEC-WAIT-INTERVAL-EXPIRED PIC S9(9) BINARY VALUE 3. 000631C 10 MQEC-WAIT-CANCELED PIC S9(9) BINARY VALUE 4. 000632C 10 MQEC-Q-MGR-QUIESCING PIC S9(9) BINARY VALUE 5. 000633C 10 MQEC-CONNECTION-QUIESCING PIC S9(9) BINARY VALUE 6. 000634C 000635C ** Match Options 000636C 10 MQMO-MATCH-MSG-ID PIC S9(9) BINARY VALUE 1. 000637C 10 MQMO-MATCH-CORREL-ID PIC S9(9) BINARY VALUE 2. 000638C 10 MQMO-MATCH-GROUP-ID PIC S9(9) BINARY VALUE 4. 000639C 10 MQMO-MATCH-MSG-SEQ-NUMBER PIC S9(9) BINARY VALUE 8. 000640C 10 MQMO-MATCH-OFFSET PIC S9(9) BINARY VALUE 16. 000641C 10 MQMO-MATCH-MSG-TOKEN PIC S9(9) BINARY VALUE 32. 000642C 10 MQMO-NONE PIC S9(9) BINARY VALUE 0. 000643C 000644C ** Group Status 000645C 10 MQGS-NOT-IN-GROUP PIC X VALUE ' '. 000646C 10 MQGS-MSG-IN-GROUP PIC X VALUE 'G'. 000647C 10 MQGS-LAST-MSG-IN-GROUP PIC X VALUE 'L'. 000648C 000649C ** Segment Status 000650C 10 MQSS-NOT-A-SEGMENT PIC X VALUE ' '. 000651C 10 MQSS-SEGMENT PIC X VALUE 'S'. 000652C 10 MQSS-LAST-SEGMENT PIC X VALUE 'L'. 000653C 000654C ** Segmentation 000655C 10 MQSEG-INHIBITED PIC X VALUE ' '. 000656C 10 MQSEG-ALLOWED PIC X VALUE 'A'. 000657C 000658C ** Message Token 000659C 10 MQMTOK-NONE PIC X(16) VALUE LOW-VALUES. 000660C 000661C ** Returned Length 000662C 10 MQRL-UNDEFINED PIC S9(9) BINARY VALUE -1. 000663C 000664C ****************************************************************** 000665C ** Values Related to MQIIH Structure 000666C ****************************************************************** 000667C ** Structure Identifier 000668C 10 MQIIH-STRUC-ID PIC X(4) VALUE 'IIH '. 000669C 000670C ** Structure Version Number 000671C 10 MQIIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000672C 10 MQIIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000673C 000674C ** Structure Length 000675C 10 MQIIH-LENGTH-1 PIC S9(9) BINARY VALUE 84. 000676C 10 MQIIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 84. 000677C 000678C ** Flags 000679C 10 MQIIH-NONE PIC S9(9) BINARY VALUE 0. 000680C 10 MQIIH-PASS-EXPIRATION PIC S9(9) BINARY VALUE 1. 000681C 10 MQIIH-UNLIMITED-EXPIRATION PIC S9(9) BINARY VALUE 0. 000682C 10 MQIIH-REPLY-FORMAT-NONE PIC S9(9) BINARY VALUE 8. 000683C 10 MQIIH-IGNORE-PURG PIC S9(9) BINARY VALUE 16. 000684C 10 MQIIH-CM0-REQUEST-RESPONSE PIC S9(9) BINARY VALUE 32. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 16 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000685C 000686C ** Authenticator 000687C 10 MQIAUT-NONE PIC X(8) VALUE SPACES. 000688C 000689C ** Transaction Instance Identifier 000690C 10 MQITII-NONE PIC X(16) VALUE LOW-VALUES. 000691C 000692C ** Transaction States 000693C 10 MQITS-IN-CONVERSATION PIC X VALUE 'C'. 000694C 10 MQITS-NOT-IN-CONVERSATION PIC X VALUE ' '. 000695C 10 MQITS-ARCHITECTED PIC X VALUE 'A'. 000696C 000697C ** Commit Modes 000698C 10 MQICM-COMMIT-THEN-SEND PIC X VALUE '0'. 000699C 10 MQICM-SEND-THEN-COMMIT PIC X VALUE '1'. 000700C 000701C ** Security Scopes 000702C 10 MQISS-CHECK PIC X VALUE 'C'. 000703C 10 MQISS-FULL PIC X VALUE 'F'. 000704C 000705C ****************************************************************** 000706C ** Values Related to MQIMPO Structure 000707C ****************************************************************** 000708C ** Structure Identifier 000709C 10 MQIMPO-STRUC-ID PIC X(4) VALUE 'IMPO'. 000710C 000711C ** Structure Version Number 000712C 10 MQIMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000713C 10 MQIMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000714C 000715C ** Structure Length 000716C 10 MQIMPO-LENGTH-1 PIC S9(9) BINARY VALUE 60. 000717C 10 MQIMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 60. 000718C 000719C ** Inquire Message Property Options 000720C 10 MQIMPO-CONVERT-TYPE PIC S9(9) BINARY VALUE 2. 000721C 10 MQIMPO-QUERY-LENGTH PIC S9(9) BINARY VALUE 4. 000722C 10 MQIMPO-INQ-FIRST PIC S9(9) BINARY VALUE 0. 000723C 10 MQIMPO-INQ-NEXT PIC S9(9) BINARY VALUE 8. 000724C 10 MQIMPO-INQ-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 16. 000725C 10 MQIMPO-CONVERT-VALUE PIC S9(9) BINARY VALUE 32. 000726C 10 MQIMPO-NONE PIC S9(9) BINARY VALUE 0. 000727C 000728C ****************************************************************** 000729C ** Values Related to MQMD Structure 000730C ****************************************************************** 000731C ** Structure Identifier 000732C 10 MQMD-STRUC-ID PIC X(4) VALUE 'MD '. 000733C 000734C ** Structure Version Number 000735C 10 MQMD-VERSION-1 PIC S9(9) BINARY VALUE 1. 000736C 10 MQMD-VERSION-2 PIC S9(9) BINARY VALUE 2. 000737C 10 MQMD-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000738C 000739C ** Structure Length 000740C 10 MQMD-LENGTH-1 PIC S9(9) BINARY VALUE 324. 000741C 10 MQMD-LENGTH-2 PIC S9(9) BINARY VALUE 364. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 17 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000742C 10 MQMD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 364. 000743C 000744C ** Report Options 000745C 10 MQRO-EXCEPTION PIC S9(9) BINARY VALUE 16777216. 000746C 10 MQRO-EXCEPTION-WITH-DATA PIC S9(9) BINARY VALUE 50331648. 000747C 10 MQRO-EXCEPTION-WITH-FULL-DATA PIC S9(9) BINARY 000748C VALUE 117440512. 000749C 10 MQRO-EXPIRATION PIC S9(9) BINARY VALUE 2097152. 000750C 10 MQRO-EXPIRATION-WITH-DATA PIC S9(9) BINARY VALUE 6291456. 000751C 10 MQRO-EXPIRATION-WITH-FULL-DATA PIC S9(9) BINARY 000752C VALUE 14680064. 000753C 10 MQRO-COA PIC S9(9) BINARY VALUE 256. 000754C 10 MQRO-COA-WITH-DATA PIC S9(9) BINARY VALUE 768. 000755C 10 MQRO-COA-WITH-FULL-DATA PIC S9(9) BINARY VALUE 1792. 000756C 10 MQRO-COD PIC S9(9) BINARY VALUE 2048. 000757C 10 MQRO-COD-WITH-DATA PIC S9(9) BINARY VALUE 6144. 000758C 10 MQRO-COD-WITH-FULL-DATA PIC S9(9) BINARY VALUE 14336. 000759C 10 MQRO-PAN PIC S9(9) BINARY VALUE 1. 000760C 10 MQRO-NAN PIC S9(9) BINARY VALUE 2. 000761C 10 MQRO-ACTIVITY PIC S9(9) BINARY VALUE 4. 000762C 10 MQRO-NEW-MSG-ID PIC S9(9) BINARY VALUE 0. 000763C 10 MQRO-PASS-MSG-ID PIC S9(9) BINARY VALUE 128. 000764C 10 MQRO-COPY-MSG-ID-TO-CORREL-ID PIC S9(9) BINARY VALUE 0. 000765C 10 MQRO-PASS-CORREL-ID PIC S9(9) BINARY VALUE 64. 000766C 10 MQRO-DEAD-LETTER-Q PIC S9(9) BINARY VALUE 0. 000767C 10 MQRO-DISCARD-MSG PIC S9(9) BINARY VALUE 134217728. 000768C 10 MQRO-PASS-DISCARD-AND-EXPIRY PIC S9(9) BINARY VALUE 16384. 000769C 10 MQRO-NONE PIC S9(9) BINARY VALUE 0. 000770C 000771C ** Report Options Masks 000772C 10 MQRO-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE 270270464. 000773C 10 MQRO-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE -270532353. 000774C 10 MQRO-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 000775C VALUE 261888. 000776C 000777C ** Message Types 000778C 10 MQMT-SYSTEM-FIRST PIC S9(9) BINARY VALUE 1. 000779C 10 MQMT-REQUEST PIC S9(9) BINARY VALUE 1. 000780C 10 MQMT-REPLY PIC S9(9) BINARY VALUE 2. 000781C 10 MQMT-DATAGRAM PIC S9(9) BINARY VALUE 8. 000782C 10 MQMT-REPORT PIC S9(9) BINARY VALUE 4. 000783C 10 MQMT-MQE-FIELDS-FROM-MQE PIC S9(9) BINARY VALUE 112. 000784C 10 MQMT-MQE-FIELDS PIC S9(9) BINARY VALUE 113. 000785C 10 MQMT-SYSTEM-LAST PIC S9(9) BINARY VALUE 65535. 000786C 10 MQMT-APPL-FIRST PIC S9(9) BINARY VALUE 65536. 000787C 10 MQMT-APPL-LAST PIC S9(9) BINARY VALUE 999999999. 000788C 000789C ** Expiry 000790C 10 MQEI-UNLIMITED PIC S9(9) BINARY VALUE -1. 000791C 000792C ** Feedback Values 000793C 10 MQFB-NONE PIC S9(9) BINARY VALUE 0. 000794C 10 MQFB-SYSTEM-FIRST PIC S9(9) BINARY VALUE 1. 000795C 10 MQFB-QUIT PIC S9(9) BINARY VALUE 256. 000796C 10 MQFB-EXPIRATION PIC S9(9) BINARY VALUE 258. 000797C 10 MQFB-COA PIC S9(9) BINARY VALUE 259. 000798C 10 MQFB-COD PIC S9(9) BINARY VALUE 260. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 18 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000799C 10 MQFB-CHANNEL-COMPLETED PIC S9(9) BINARY VALUE 262. 000800C 10 MQFB-CHANNEL-FAIL-RETRY PIC S9(9) BINARY VALUE 263. 000801C 10 MQFB-CHANNEL-FAIL PIC S9(9) BINARY VALUE 264. 000802C 10 MQFB-APPL-CANNOT-BE-STARTED PIC S9(9) BINARY VALUE 265. 000803C 10 MQFB-TM-ERROR PIC S9(9) BINARY VALUE 266. 000804C 10 MQFB-APPL-TYPE-ERROR PIC S9(9) BINARY VALUE 267. 000805C 10 MQFB-STOPPED-BY-MSG-EXIT PIC S9(9) BINARY VALUE 268. 000806C 10 MQFB-ACTIVITY PIC S9(9) BINARY VALUE 269. 000807C 10 MQFB-XMIT-Q-MSG-ERROR PIC S9(9) BINARY VALUE 271. 000808C 10 MQFB-PAN PIC S9(9) BINARY VALUE 275. 000809C 10 MQFB-NAN PIC S9(9) BINARY VALUE 276. 000810C 10 MQFB-STOPPED-BY-CHAD-EXIT PIC S9(9) BINARY VALUE 277. 000811C 10 MQFB-STOPPED-BY-PUBSUB-EXIT PIC S9(9) BINARY VALUE 279. 000812C 10 MQFB-NOT-A-REPOSITORY-MSG PIC S9(9) BINARY VALUE 280. 000813C 10 MQFB-BIND-OPEN-CLUSRCVR-DEL PIC S9(9) BINARY VALUE 281. 000814C 10 MQFB-MAX-ACTIVITIES PIC S9(9) BINARY VALUE 282. 000815C 10 MQFB-NOT-FORWARDED PIC S9(9) BINARY VALUE 283. 000816C 10 MQFB-NOT-DELIVERED PIC S9(9) BINARY VALUE 284. 000817C 10 MQFB-UNSUPPORTED-FORWARDING PIC S9(9) BINARY VALUE 285. 000818C 10 MQFB-UNSUPPORTED-DELIVERY PIC S9(9) BINARY VALUE 286. 000819C 10 MQFB-DATA-LENGTH-ZERO PIC S9(9) BINARY VALUE 291. 000820C 10 MQFB-DATA-LENGTH-NEGATIVE PIC S9(9) BINARY VALUE 292. 000821C 10 MQFB-DATA-LENGTH-TOO-BIG PIC S9(9) BINARY VALUE 293. 000822C 10 MQFB-BUFFER-OVERFLOW PIC S9(9) BINARY VALUE 294. 000823C 10 MQFB-LENGTH-OFF-BY-ONE PIC S9(9) BINARY VALUE 295. 000824C 10 MQFB-IIH-ERROR PIC S9(9) BINARY VALUE 296. 000825C 10 MQFB-NOT-AUTHORIZED-FOR-IMS PIC S9(9) BINARY VALUE 298. 000826C 10 MQFB-DATA-LENGTH-TOO-SHORT PIC S9(9) BINARY VALUE 299. 000827C 10 MQFB-IMS-ERROR PIC S9(9) BINARY VALUE 300. 000828C 10 MQFB-IMS-FIRST PIC S9(9) BINARY VALUE 301. 000829C 10 MQFB-IMS-LAST PIC S9(9) BINARY VALUE 399. 000830C 10 MQFB-CICS-INTERNAL-ERROR PIC S9(9) BINARY VALUE 401. 000831C 10 MQFB-CICS-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 402. 000832C 10 MQFB-CICS-BRIDGE-FAILURE PIC S9(9) BINARY VALUE 403. 000833C 10 MQFB-CICS-CORREL-ID-ERROR PIC S9(9) BINARY VALUE 404. 000834C 10 MQFB-CICS-CCSID-ERROR PIC S9(9) BINARY VALUE 405. 000835C 10 MQFB-CICS-ENCODING-ERROR PIC S9(9) BINARY VALUE 406. 000836C 10 MQFB-CICS-CIH-ERROR PIC S9(9) BINARY VALUE 407. 000837C 10 MQFB-CICS-UOW-ERROR PIC S9(9) BINARY VALUE 408. 000838C 10 MQFB-CICS-COMMAREA-ERROR PIC S9(9) BINARY VALUE 409. 000839C 10 MQFB-CICS-APPL-NOT-STARTED PIC S9(9) BINARY VALUE 410. 000840C 10 MQFB-CICS-APPL-ABENDED PIC S9(9) BINARY VALUE 411. 000841C 10 MQFB-CICS-DLQ-ERROR PIC S9(9) BINARY VALUE 412. 000842C 10 MQFB-CICS-UOW-BACKED-OUT PIC S9(9) BINARY VALUE 413. 000843C 10 MQFB-PUBLICATIONS-ON-REQUEST PIC S9(9) BINARY VALUE 501. 000844C 10 MQFB-SUBSCRIBER-IS-PUBLISHER PIC S9(9) BINARY VALUE 502. 000845C 10 MQFB-MSG-SCOPE-MISMATCH PIC S9(9) BINARY VALUE 503. 000846C 10 MQFB-SELECTOR-MISMATCH PIC S9(9) BINARY VALUE 504. 000847C 10 MQFB-NOT-A-GROUPUR-MSG PIC S9(9) BINARY VALUE 505. 000848C 10 MQFB-IMS-NACK-1A-REASON-FIRST PIC S9(9) BINARY VALUE 600. 000849C 10 MQFB-IMS-NACK-1A-REASON-LAST PIC S9(9) BINARY VALUE 855. 000850C 10 MQFB-SYSTEM-LAST PIC S9(9) BINARY VALUE 65535. 000851C 10 MQFB-APPL-FIRST PIC S9(9) BINARY VALUE 65536. 000852C 10 MQFB-APPL-LAST PIC S9(9) BINARY VALUE 999999999. 000853C 000854C ** Encoding 000855C 10 MQENC-NATIVE PIC S9(9) BINARY VALUE 785. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 19 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000856C 000857C ** Encoding Masks 000858C 10 MQENC-INTEGER-MASK PIC S9(9) BINARY VALUE 15. 000859C 10 MQENC-DECIMAL-MASK PIC S9(9) BINARY VALUE 240. 000860C 10 MQENC-FLOAT-MASK PIC S9(9) BINARY VALUE 3840. 000861C 10 MQENC-RESERVED-MASK PIC S9(9) BINARY VALUE -4096. 000862C 000863C ** Encodings for Binary Integers 000864C 10 MQENC-INTEGER-UNDEFINED PIC S9(9) BINARY VALUE 0. 000865C 10 MQENC-INTEGER-NORMAL PIC S9(9) BINARY VALUE 1. 000866C 10 MQENC-INTEGER-REVERSED PIC S9(9) BINARY VALUE 2. 000867C 000868C ** Encodings for Packed Decimal Integers 000869C 10 MQENC-DECIMAL-UNDEFINED PIC S9(9) BINARY VALUE 0. 000870C 10 MQENC-DECIMAL-NORMAL PIC S9(9) BINARY VALUE 16. 000871C 10 MQENC-DECIMAL-REVERSED PIC S9(9) BINARY VALUE 32. 000872C 000873C ** Encodings for Floating Point Numbers 000874C 10 MQENC-FLOAT-UNDEFINED PIC S9(9) BINARY VALUE 0. 000875C 10 MQENC-FLOAT-IEEE-NORMAL PIC S9(9) BINARY VALUE 256. 000876C 10 MQENC-FLOAT-IEEE-REVERSED PIC S9(9) BINARY VALUE 512. 000877C 10 MQENC-FLOAT-S390 PIC S9(9) BINARY VALUE 768. 000878C 10 MQENC-FLOAT-TNS PIC S9(9) BINARY VALUE 1024. 000879C 000880C ** Encodings for Multicast 000881C 10 MQENC-NORMAL PIC S9(9) BINARY VALUE 273. 000882C 10 MQENC-REVERSED PIC S9(9) BINARY VALUE 546. 000883C 10 MQENC-S390 PIC S9(9) BINARY VALUE 785. 000884C 10 MQENC-TNS PIC S9(9) BINARY VALUE 1041. 000885C 10 MQENC-AS-PUBLISHED PIC S9(9) BINARY VALUE -1. 000886C 000887C ** Coded Character Set Identifiers 000888C 10 MQCCSI-UNDEFINED PIC S9(9) BINARY VALUE 0. 000889C 10 MQCCSI-DEFAULT PIC S9(9) BINARY VALUE 0. 000890C 10 MQCCSI-Q-MGR PIC S9(9) BINARY VALUE 0. 000891C 10 MQCCSI-INHERIT PIC S9(9) BINARY VALUE -2. 000892C 10 MQCCSI-EMBEDDED PIC S9(9) BINARY VALUE -1. 000893C 10 MQCCSI-APPL PIC S9(9) BINARY VALUE -3. 000894C 10 MQCCSI-AS-PUBLISHED PIC S9(9) BINARY VALUE -4. 000895C 000896C ** Formats 000897C 10 MQFMT-NONE PIC X(8) VALUE SPACES. 000898C 10 MQFMT-ADMIN PIC X(8) VALUE 'MQADMIN '. 000899C 10 MQFMT-AMQP PIC X(8) VALUE 'MQAMQP '. 000900C 10 MQFMT-CHANNEL-COMPLETED PIC X(8) VALUE 'MQCHCOM '. 000901C 10 MQFMT-CICS PIC X(8) VALUE 'MQCICS '. 000902C 10 MQFMT-COMMAND-1 PIC X(8) VALUE 'MQCMD1 '. 000903C 10 MQFMT-COMMAND-2 PIC X(8) VALUE 'MQCMD2 '. 000904C 10 MQFMT-DEAD-LETTER-HEADER PIC X(8) VALUE 'MQDEAD '. 000905C 10 MQFMT-DIST-HEADER PIC X(8) VALUE 'MQHDIST '. 000906C 10 MQFMT-EMBEDDED-PCF PIC X(8) VALUE 'MQHEPCF '. 000907C 10 MQFMT-EVENT PIC X(8) VALUE 'MQEVENT '. 000908C 10 MQFMT-IMS PIC X(8) VALUE 'MQIMS '. 000909C 10 MQFMT-IMS-VAR-STRING PIC X(8) VALUE 'MQIMSVS '. 000910C 10 MQFMT-MD-EXTENSION PIC X(8) VALUE 'MQHMDE '. 000911C 10 MQFMT-PCF PIC X(8) VALUE 'MQPCF '. 000912C 10 MQFMT-REF-MSG-HEADER PIC X(8) VALUE 'MQHREF '. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 20 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000913C 10 MQFMT-RF-HEADER PIC X(8) VALUE 'MQHRF '. 000914C 10 MQFMT-RF-HEADER-1 PIC X(8) VALUE 'MQHRF '. 000915C 10 MQFMT-RF-HEADER-2 PIC X(8) VALUE 'MQHRF2 '. 000916C 10 MQFMT-STRING PIC X(8) VALUE 'MQSTR '. 000917C 10 MQFMT-TRIGGER PIC X(8) VALUE 'MQTRIG '. 000918C 10 MQFMT-WORK-INFO-HEADER PIC X(8) VALUE 'MQHWIH '. 000919C 10 MQFMT-XMIT-Q-HEADER PIC X(8) VALUE 'MQXMIT '. 000920C 000921C ** Priority 000922C 10 MQPRI-PRIORITY-AS-Q-DEF PIC S9(9) BINARY VALUE -1. 000923C 10 MQPRI-PRIORITY-AS-PARENT PIC S9(9) BINARY VALUE -2. 000924C 10 MQPRI-PRIORITY-AS-PUBLISHED PIC S9(9) BINARY VALUE -3. 000925C 10 MQPRI-PRIORITY-AS-TOPIC-DEF PIC S9(9) BINARY VALUE -1. 000926C 000927C ** Persistence Values 000928C 10 MQPER-PERSISTENCE-AS-PARENT PIC S9(9) BINARY VALUE -1. 000929C 10 MQPER-NOT-PERSISTENT PIC S9(9) BINARY VALUE 0. 000930C 10 MQPER-PERSISTENT PIC S9(9) BINARY VALUE 1. 000931C 10 MQPER-PERSISTENCE-AS-Q-DEF PIC S9(9) BINARY VALUE 2. 000932C 10 MQPER-PERSISTENCE-AS-TOPIC-DEF PIC S9(9) BINARY VALUE 2. 000933C 000934C ** Put Response Values 000935C 10 MQPRT-RESPONSE-AS-PARENT PIC S9(9) BINARY VALUE 0. 000936C 10 MQPRT-SYNC-RESPONSE PIC S9(9) BINARY VALUE 1. 000937C 10 MQPRT-ASYNC-RESPONSE PIC S9(9) BINARY VALUE 2. 000938C 000939C ** Message Identifier 000940C 10 MQMI-NONE PIC X(24) VALUE LOW-VALUES. 000941C 000942C ** Correlation Identifier 000943C 10 MQCI-NONE PIC X(24) VALUE LOW-VALUES. 000944C 10 MQCI-NEW-SESSION PIC X(24) 000945C VALUE X'414D51214E45575F53455353494F4E5F434F5252454C4944'. 000946C 000947C ** Accounting Token 000948C 10 MQACT-NONE PIC X(32) VALUE LOW-VALUES. 000949C 000950C ** Put Application Types 000951C 10 MQAT-UNKNOWN PIC S9(9) BINARY VALUE -1. 000952C 10 MQAT-NO-CONTEXT PIC S9(9) BINARY VALUE 0. 000953C 10 MQAT-CICS PIC S9(9) BINARY VALUE 1. 000954C 10 MQAT-MVS PIC S9(9) BINARY VALUE 2. 000955C 10 MQAT-OS390 PIC S9(9) BINARY VALUE 2. 000956C 10 MQAT-ZOS PIC S9(9) BINARY VALUE 2. 000957C 10 MQAT-IMS PIC S9(9) BINARY VALUE 3. 000958C 10 MQAT-OS2 PIC S9(9) BINARY VALUE 4. 000959C 10 MQAT-DOS PIC S9(9) BINARY VALUE 5. 000960C 10 MQAT-AIX PIC S9(9) BINARY VALUE 6. 000961C 10 MQAT-UNIX PIC S9(9) BINARY VALUE 6. 000962C 10 MQAT-QMGR PIC S9(9) BINARY VALUE 7. 000963C 10 MQAT-OS400 PIC S9(9) BINARY VALUE 8. 000964C 10 MQAT-WINDOWS PIC S9(9) BINARY VALUE 9. 000965C 10 MQAT-CICS-VSE PIC S9(9) BINARY VALUE 10. 000966C 10 MQAT-WINDOWS-NT PIC S9(9) BINARY VALUE 11. 000967C 10 MQAT-VMS PIC S9(9) BINARY VALUE 12. 000968C 10 MQAT-GUARDIAN PIC S9(9) BINARY VALUE 13. 000969C 10 MQAT-NSK PIC S9(9) BINARY VALUE 13. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 21 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000970C 10 MQAT-VOS PIC S9(9) BINARY VALUE 14. 000971C 10 MQAT-OPEN-TP1 PIC S9(9) BINARY VALUE 15. 000972C 10 MQAT-VM PIC S9(9) BINARY VALUE 18. 000973C 10 MQAT-IMS-BRIDGE PIC S9(9) BINARY VALUE 19. 000974C 10 MQAT-XCF PIC S9(9) BINARY VALUE 20. 000975C 10 MQAT-CICS-BRIDGE PIC S9(9) BINARY VALUE 21. 000976C 10 MQAT-NOTES-AGENT PIC S9(9) BINARY VALUE 22. 000977C 10 MQAT-TPF PIC S9(9) BINARY VALUE 23. 000978C 10 MQAT-USER PIC S9(9) BINARY VALUE 25. 000979C 10 MQAT-BROKER PIC S9(9) BINARY VALUE 26. 000980C 10 MQAT-QMGR-PUBLISH PIC S9(9) BINARY VALUE 26. 000981C 10 MQAT-JAVA PIC S9(9) BINARY VALUE 28. 000982C 10 MQAT-DQM PIC S9(9) BINARY VALUE 29. 000983C 10 MQAT-CHANNEL-INITIATOR PIC S9(9) BINARY VALUE 30. 000984C 10 MQAT-WLM PIC S9(9) BINARY VALUE 31. 000985C 10 MQAT-BATCH PIC S9(9) BINARY VALUE 32. 000986C 10 MQAT-RRS-BATCH PIC S9(9) BINARY VALUE 33. 000987C 10 MQAT-SIB PIC S9(9) BINARY VALUE 34. 000988C 10 MQAT-SYSTEM-EXTENSION PIC S9(9) BINARY VALUE 35. 000989C 10 MQAT-MCAST-PUBLISH PIC S9(9) BINARY VALUE 36. 000990C 10 MQAT-AMQP PIC S9(9) BINARY VALUE 37. 000991C 10 MQAT-DEFAULT PIC S9(9) BINARY VALUE 2. 000992C 10 MQAT-USER-FIRST PIC S9(9) BINARY VALUE 65536. 000993C 10 MQAT-USER-LAST PIC S9(9) BINARY VALUE 999999999. 000994C 000995C ** Group Identifier 000996C 10 MQGI-NONE PIC X(24) VALUE LOW-VALUES. 000997C 000998C ** Message Flags 000999C 10 MQMF-SEGMENTATION-INHIBITED PIC S9(9) BINARY VALUE 0. 001000C 10 MQMF-SEGMENTATION-ALLOWED PIC S9(9) BINARY VALUE 1. 001001C 10 MQMF-MSG-IN-GROUP PIC S9(9) BINARY VALUE 8. 001002C 10 MQMF-LAST-MSG-IN-GROUP PIC S9(9) BINARY VALUE 16. 001003C 10 MQMF-SEGMENT PIC S9(9) BINARY VALUE 2. 001004C 10 MQMF-LAST-SEGMENT PIC S9(9) BINARY VALUE 4. 001005C 10 MQMF-NONE PIC S9(9) BINARY VALUE 0. 001006C 001007C ** Message Flags Masks 001008C 10 MQMF-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE 4095. 001009C 10 MQMF-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE -1048576. 001010C 10 MQMF-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 001011C VALUE 1044480. 001012C 001013C ** Original Length 001014C 10 MQOL-UNDEFINED PIC S9(9) BINARY VALUE -1. 001015C 001016C ****************************************************************** 001017C ** Values Related to MQMDE Structure 001018C ****************************************************************** 001019C ** Structure Identifier 001020C 10 MQMDE-STRUC-ID PIC X(4) VALUE 'MDE '. 001021C 001022C ** Structure Version Number 001023C 10 MQMDE-VERSION-2 PIC S9(9) BINARY VALUE 2. 001024C 10 MQMDE-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 001025C 001026C ** Structure Length 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 22 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001027C 10 MQMDE-LENGTH-2 PIC S9(9) BINARY VALUE 72. 001028C 10 MQMDE-CURRENT-LENGTH PIC S9(9) BINARY VALUE 72. 001029C 001030C ** Flags 001031C 10 MQMDEF-NONE PIC S9(9) BINARY VALUE 0. 001032C 001033C ****************************************************************** 001034C ** Values Related to MQMD1 Structure 001035C ****************************************************************** 001036C ** Structure Length 001037C 10 MQMD1-LENGTH-1 PIC S9(9) BINARY VALUE 324. 001038C 10 MQMD1-CURRENT-LENGTH PIC S9(9) BINARY VALUE 324. 001039C 001040C ****************************************************************** 001041C ** Values Related to MQMD2 Structure 001042C ****************************************************************** 001043C ** Structure Length 001044C 10 MQMD2-LENGTH-1 PIC S9(9) BINARY VALUE 324. 001045C 10 MQMD2-LENGTH-2 PIC S9(9) BINARY VALUE 364. 001046C 10 MQMD2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 364. 001047C 001048C ****************************************************************** 001049C ** Values Related to MQMHBO Structure 001050C ****************************************************************** 001051C ** Structure Identifier 001052C 10 MQMHBO-STRUC-ID PIC X(4) VALUE 'MHBO'. 001053C 001054C ** Structure Version Number 001055C 10 MQMHBO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001056C 10 MQMHBO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001057C 001058C ** Structure Length 001059C 10 MQMHBO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 001060C 10 MQMHBO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 001061C 001062C ** Message Handle To Buffer Options 001063C 10 MQMHBO-PROPERTIES-IN-MQRFH2 PIC S9(9) BINARY VALUE 1. 001064C 10 MQMHBO-DELETE-PROPERTIES PIC S9(9) BINARY VALUE 2. 001065C 10 MQMHBO-NONE PIC S9(9) BINARY VALUE 0. 001066C 001067C ****************************************************************** 001068C ** Values Related to MQOD Structure 001069C ****************************************************************** 001070C ** Structure Identifier 001071C 10 MQOD-STRUC-ID PIC X(4) VALUE 'OD '. 001072C 001073C ** Structure Version Number 001074C 10 MQOD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001075C 10 MQOD-VERSION-2 PIC S9(9) BINARY VALUE 2. 001076C 10 MQOD-VERSION-3 PIC S9(9) BINARY VALUE 3. 001077C 10 MQOD-VERSION-4 PIC S9(9) BINARY VALUE 4. 001078C 10 MQOD-CURRENT-VERSION PIC S9(9) BINARY VALUE 4. 001079C 001080C ** Structure Length 001081C 10 MQOD-LENGTH-1 PIC S9(9) BINARY VALUE 168. 001082C 10 MQOD-LENGTH-2 PIC S9(9) BINARY VALUE 200. 001083C 10 MQOD-LENGTH-3 PIC S9(9) BINARY VALUE 336. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 23 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001084C 10 MQOD-LENGTH-4 PIC S9(9) BINARY VALUE 400. 001085C 10 MQOD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 400. 001086C 001087C ** Obsolete DB2 Messages options on Inquire Group 001088C 10 MQOM-NO PIC S9(9) BINARY VALUE 0. 001089C 10 MQOM-YES PIC S9(9) BINARY VALUE 1. 001090C 001091C ** Object Types 001092C 10 MQOT-NONE PIC S9(9) BINARY VALUE 0. 001093C 10 MQOT-Q PIC S9(9) BINARY VALUE 1. 001094C 10 MQOT-NAMELIST PIC S9(9) BINARY VALUE 2. 001095C 10 MQOT-PROCESS PIC S9(9) BINARY VALUE 3. 001096C 10 MQOT-STORAGE-CLASS PIC S9(9) BINARY VALUE 4. 001097C 10 MQOT-Q-MGR PIC S9(9) BINARY VALUE 5. 001098C 10 MQOT-CHANNEL PIC S9(9) BINARY VALUE 6. 001099C 10 MQOT-AUTH-INFO PIC S9(9) BINARY VALUE 7. 001100C 10 MQOT-TOPIC PIC S9(9) BINARY VALUE 8. 001101C 10 MQOT-COMM-INFO PIC S9(9) BINARY VALUE 9. 001102C 10 MQOT-CF-STRUC PIC S9(9) BINARY VALUE 10. 001103C 10 MQOT-LISTENER PIC S9(9) BINARY VALUE 11. 001104C 10 MQOT-SERVICE PIC S9(9) BINARY VALUE 12. 001105C 10 MQOT-RESERVED-1 PIC S9(9) BINARY VALUE 999. 001106C 001107C ** Extended Object Types 001108C 10 MQOT-ALL PIC S9(9) BINARY VALUE 1001. 001109C 10 MQOT-ALIAS-Q PIC S9(9) BINARY VALUE 1002. 001110C 10 MQOT-MODEL-Q PIC S9(9) BINARY VALUE 1003. 001111C 10 MQOT-LOCAL-Q PIC S9(9) BINARY VALUE 1004. 001112C 10 MQOT-REMOTE-Q PIC S9(9) BINARY VALUE 1005. 001113C 10 MQOT-SENDER-CHANNEL PIC S9(9) BINARY VALUE 1007. 001114C 10 MQOT-SERVER-CHANNEL PIC S9(9) BINARY VALUE 1008. 001115C 10 MQOT-REQUESTER-CHANNEL PIC S9(9) BINARY VALUE 1009. 001116C 10 MQOT-RECEIVER-CHANNEL PIC S9(9) BINARY VALUE 1010. 001117C 10 MQOT-CURRENT-CHANNEL PIC S9(9) BINARY VALUE 1011. 001118C 10 MQOT-SAVED-CHANNEL PIC S9(9) BINARY VALUE 1012. 001119C 10 MQOT-SVRCONN-CHANNEL PIC S9(9) BINARY VALUE 1013. 001120C 10 MQOT-CLNTCONN-CHANNEL PIC S9(9) BINARY VALUE 1014. 001121C 10 MQOT-SHORT-CHANNEL PIC S9(9) BINARY VALUE 1015. 001122C 10 MQOT-CHLAUTH PIC S9(9) BINARY VALUE 1016. 001123C 10 MQOT-REMOTE-Q-MGR-NAME PIC S9(9) BINARY VALUE 1017. 001124C 10 MQOT-PROT-POLICY PIC S9(9) BINARY VALUE 1019. 001125C 10 MQOT-TT-CHANNEL PIC S9(9) BINARY VALUE 1020. 001126C 10 MQOT-AMQP-CHANNEL PIC S9(9) BINARY VALUE 1021. 001127C 10 MQOT-AUTH-REC PIC S9(9) BINARY VALUE 1022. 001128C 001129C ****************************************************************** 001130C ** Values Related to MQPD Structure 001131C ****************************************************************** 001132C ** Structure Identifier 001133C 10 MQPD-STRUC-ID PIC X(4) VALUE 'PD '. 001134C 001135C ** Structure Version Number 001136C 10 MQPD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001137C 10 MQPD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001138C 001139C ** Structure Length 001140C 10 MQPD-LENGTH-1 PIC S9(9) BINARY VALUE 24. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 24 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001141C 10 MQPD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 24. 001142C 001143C ** Property Descriptor Options 001144C 10 MQPD-NONE PIC S9(9) BINARY VALUE 0. 001145C 001146C ** Property Support Options 001147C 10 MQPD-SUPPORT-OPTIONAL PIC S9(9) BINARY VALUE 1. 001148C 10 MQPD-SUPPORT-REQUIRED PIC S9(9) BINARY VALUE 1048576. 001149C 10 MQPD-SUPPORT-REQUIRED-IF-LOCAL PIC S9(9) BINARY VALUE 1024. 001150C 10 MQPD-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE -1048576. 001151C 10 MQPD-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 001152C VALUE 1047552. 001153C 10 MQPD-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE 1023. 001154C 001155C ** Property Context 001156C 10 MQPD-NO-CONTEXT PIC S9(9) BINARY VALUE 0. 001157C 10 MQPD-USER-CONTEXT PIC S9(9) BINARY VALUE 1. 001158C 001159C ** Property Copy Options 001160C 10 MQCOPY-NONE PIC S9(9) BINARY VALUE 0. 001161C 10 MQCOPY-ALL PIC S9(9) BINARY VALUE 1. 001162C 10 MQCOPY-FORWARD PIC S9(9) BINARY VALUE 2. 001163C 10 MQCOPY-PUBLISH PIC S9(9) BINARY VALUE 4. 001164C 10 MQCOPY-REPLY PIC S9(9) BINARY VALUE 8. 001165C 10 MQCOPY-REPORT PIC S9(9) BINARY VALUE 16. 001166C 10 MQCOPY-DEFAULT PIC S9(9) BINARY VALUE 22. 001167C 001168C ****************************************************************** 001169C ** Values Related to MQPMO Structure 001170C ****************************************************************** 001171C ** Structure Identifier 001172C 10 MQPMO-STRUC-ID PIC X(4) VALUE 'PMO '. 001173C 001174C ** Structure Version Number 001175C 10 MQPMO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001176C 10 MQPMO-VERSION-2 PIC S9(9) BINARY VALUE 2. 001177C 10 MQPMO-VERSION-3 PIC S9(9) BINARY VALUE 3. 001178C 10 MQPMO-CURRENT-VERSION PIC S9(9) BINARY VALUE 3. 001179C 001180C ** Structure Length 001181C 10 MQPMO-LENGTH-1 PIC S9(9) BINARY VALUE 128. 001182C 10 MQPMO-LENGTH-2 PIC S9(9) BINARY VALUE 152. 001183C 10 MQPMO-LENGTH-3 PIC S9(9) BINARY VALUE 176. 001184C 10 MQPMO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 176. 001185C 001186C ** Put Message Options 001187C 10 MQPMO-SYNCPOINT PIC S9(9) BINARY VALUE 2. 001188C 10 MQPMO-NO-SYNCPOINT PIC S9(9) BINARY VALUE 4. 001189C 10 MQPMO-DEFAULT-CONTEXT PIC S9(9) BINARY VALUE 32. 001190C 10 MQPMO-NEW-MSG-ID PIC S9(9) BINARY VALUE 64. 001191C 10 MQPMO-NEW-CORREL-ID PIC S9(9) BINARY VALUE 128. 001192C 10 MQPMO-PASS-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 256. 001193C 10 MQPMO-PASS-ALL-CONTEXT PIC S9(9) BINARY VALUE 512. 001194C 10 MQPMO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 1024. 001195C 10 MQPMO-SET-ALL-CONTEXT PIC S9(9) BINARY VALUE 2048. 001196C 10 MQPMO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY VALUE 4096. 001197C 10 MQPMO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 25 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001198C 10 MQPMO-NO-CONTEXT PIC S9(9) BINARY VALUE 16384. 001199C 10 MQPMO-LOGICAL-ORDER PIC S9(9) BINARY VALUE 32768. 001200C 10 MQPMO-ASYNC-RESPONSE PIC S9(9) BINARY VALUE 65536. 001201C 10 MQPMO-SYNC-RESPONSE PIC S9(9) BINARY VALUE 131072. 001202C 10 MQPMO-RESOLVE-LOCAL-Q PIC S9(9) BINARY VALUE 262144. 001203C 10 MQPMO-WARN-IF-NO-SUBS-MATCHED PIC S9(9) BINARY 001204C VALUE 524288. 001205C 10 MQPMO-RETAIN PIC S9(9) BINARY VALUE 2097152. 001206C 10 MQPMO-MD-FOR-OUTPUT-ONLY PIC S9(9) BINARY VALUE 8388608. 001207C 10 MQPMO-SCOPE-QMGR PIC S9(9) BINARY VALUE 67108864. 001208C 10 MQPMO-SUPPRESS-REPLYTO PIC S9(9) BINARY VALUE 134217728. 001209C 10 MQPMO-NOT-OWN-SUBS PIC S9(9) BINARY VALUE 268435456. 001210C 10 MQPMO-RESPONSE-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 001211C 10 MQPMO-RESPONSE-AS-TOPIC-DEF PIC S9(9) BINARY VALUE 0. 001212C 10 MQPMO-NONE PIC S9(9) BINARY VALUE 0. 001213C 001214C ** Put Message Options for publish mask 001215C 10 MQPMO-PUB-OPTIONS-MASK PIC S9(9) BINARY VALUE 2097152. 001216C 001217C ** Put Message Record Fields 001218C 10 MQPMRF-MSG-ID PIC S9(9) BINARY VALUE 1. 001219C 10 MQPMRF-CORREL-ID PIC S9(9) BINARY VALUE 2. 001220C 10 MQPMRF-GROUP-ID PIC S9(9) BINARY VALUE 4. 001221C 10 MQPMRF-FEEDBACK PIC S9(9) BINARY VALUE 8. 001222C 10 MQPMRF-ACCOUNTING-TOKEN PIC S9(9) BINARY VALUE 16. 001223C 10 MQPMRF-NONE PIC S9(9) BINARY VALUE 0. 001224C 001225C ** Action 001226C 10 MQACTP-NEW PIC S9(9) BINARY VALUE 0. 001227C 10 MQACTP-FORWARD PIC S9(9) BINARY VALUE 1. 001228C 10 MQACTP-REPLY PIC S9(9) BINARY VALUE 2. 001229C 10 MQACTP-REPORT PIC S9(9) BINARY VALUE 3. 001230C 001231C ****************************************************************** 001232C ** Values Related to MQRFH Structure 001233C ****************************************************************** 001234C ** Structure Identifier 001235C 10 MQRFH-STRUC-ID PIC X(4) VALUE 'RFH '. 001236C 001237C ** Structure Version Number 001238C 10 MQRFH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001239C 10 MQRFH-VERSION-2 PIC S9(9) BINARY VALUE 2. 001240C 001241C ** Structure Length 001242C 10 MQRFH-STRUC-LENGTH-FIXED PIC S9(9) BINARY VALUE 32. 001243C 10 MQRFH-STRUC-LENGTH-FIXED-2 PIC S9(9) BINARY VALUE 36. 001244C 10 MQRFH-LENGTH-1 PIC S9(9) BINARY VALUE 32. 001245C 10 MQRFH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 32. 001246C 001247C ** Flags 001248C 10 MQRFH-NONE PIC S9(9) BINARY VALUE 0. 001249C 10 MQRFH-NO-FLAGS PIC S9(9) BINARY VALUE 0. 001250C 10 MQRFH-FLAGS-RESTRICTED-MASK PIC S9(9) BINARY VALUE -65536. 001251C ** MQRFH2 flags in the restricted mask are reserved for MQ use: 001252C 001253C ** 0x80000000 - MQRFH_INTERNAL - This flag indicates the RFH2 001254C ** header was created by IBM MQ for internal use. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 26 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001255C 001256C 001257C ** Names for Name/Value String 001258C 10 MQNVS-APPL-TYPE PIC X(12) VALUE 'OPT_APP_GRP '. 001259C 10 MQNVS-MSG-TYPE PIC X(13) VALUE 'OPT_MSG_TYPE '. 001260C 001261C ****************************************************************** 001262C ** Values Related to MQRFH2 Structure 001263C ****************************************************************** 001264C ** Structure Length 001265C 10 MQRFH2-LENGTH-2 PIC S9(9) BINARY VALUE 36. 001266C 10 MQRFH2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 36. 001267C 001268C ****************************************************************** 001269C ** Values Related to MQRMH Structure 001270C ****************************************************************** 001271C ** Structure Identifier 001272C 10 MQRMH-STRUC-ID PIC X(4) VALUE 'RMH '. 001273C 001274C ** Structure Version Number 001275C 10 MQRMH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001276C 10 MQRMH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001277C 001278C ** Structure Length 001279C 10 MQRMH-LENGTH-1 PIC S9(9) BINARY VALUE 108. 001280C 10 MQRMH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 108. 001281C 001282C ** Flags 001283C 10 MQRMHF-LAST PIC S9(9) BINARY VALUE 1. 001284C 10 MQRMHF-NOT-LAST PIC S9(9) BINARY VALUE 0. 001285C 001286C ** Object Instance Identifier 001287C 10 MQOII-NONE PIC X(24) VALUE LOW-VALUES. 001288C 001289C ****************************************************************** 001290C ** Values Related to MQSD Structure 001291C ****************************************************************** 001292C ** Structure Identifier 001293C 10 MQSD-STRUC-ID PIC X(4) VALUE 'SD '. 001294C 001295C ** Structure Version Number 001296C 10 MQSD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001297C 10 MQSD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001298C 001299C ** Structure Length 001300C 10 MQSD-LENGTH-1 PIC S9(9) BINARY VALUE 312. 001301C 10 MQSD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 312. 001302C 001303C ** Security Identifier 001304C 10 MQSID-NONE PIC X(40) VALUE LOW-VALUES. 001305C 001306C ** Security Identifier Types 001307C 10 MQSIDT-NONE PIC X VALUE X'00'. 001308C 10 MQSIDT-NT-SECURITY-ID PIC X VALUE X'01'. 001309C 10 MQSIDT-WAS-SECURITY-ID PIC X VALUE X'02'. 001310C 001311C ****************************************************************** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 27 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001312C ** Values Related to MQSMPO Structure 001313C ****************************************************************** 001314C ** Structure Identifier 001315C 10 MQSMPO-STRUC-ID PIC X(4) VALUE 'SMPO'. 001316C 001317C ** Structure Version Number 001318C 10 MQSMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001319C 10 MQSMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001320C 001321C ** Structure Length 001322C 10 MQSMPO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 001323C 10 MQSMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 001324C 001325C ** Set Message Property Options 001326C 10 MQSMPO-SET-FIRST PIC S9(9) BINARY VALUE 0. 001327C 10 MQSMPO-SET-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 1. 001328C 10 MQSMPO-SET-PROP-AFTER-CURSOR PIC S9(9) BINARY VALUE 2. 001329C 10 MQSMPO-APPEND-PROPERTY PIC S9(9) BINARY VALUE 4. 001330C 10 MQSMPO-SET-PROP-BEFORE-CURSOR PIC S9(9) BINARY VALUE 8. 001331C 10 MQSMPO-NONE PIC S9(9) BINARY VALUE 0. 001332C 001333C ****************************************************************** 001334C ** Values Related to MQSRO Structure 001335C ****************************************************************** 001336C ** Structure Identifier 001337C 10 MQSRO-STRUC-ID PIC X(4) VALUE 'SRO '. 001338C 001339C ** Structure Version Number 001340C 10 MQSRO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001341C 10 MQSRO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001342C 001343C ** Structure Length 001344C 10 MQSRO-LENGTH-1 PIC S9(9) BINARY VALUE 16. 001345C 10 MQSRO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 16. 001346C 001347C ** Subscription Request Options 001348C 10 MQSRO-NONE PIC S9(9) BINARY VALUE 0. 001349C 10 MQSRO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 001350C 001351C ****************************************************************** 001352C ** Values Related to MQSTS Structure 001353C ****************************************************************** 001354C ** Structure Identifier 001355C 10 MQSTS-STRUC-ID PIC X(4) VALUE 'STAT'. 001356C 001357C ** Structure Version Number 001358C 10 MQSTS-VERSION-1 PIC S9(9) BINARY VALUE 1. 001359C 10 MQSTS-VERSION-2 PIC S9(9) BINARY VALUE 2. 001360C 10 MQSTS-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 001361C 001362C ** Structure Length 001363C 10 MQSTS-LENGTH-1 PIC S9(9) BINARY VALUE 224. 001364C 10 MQSTS-LENGTH-2 PIC S9(9) BINARY VALUE 272. 001365C 10 MQSTS-CURRENT-LENGTH PIC S9(9) BINARY VALUE 272. 001366C 001367C ****************************************************************** 001368C ** Values Related to MQTM Structure 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 28 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001369C ****************************************************************** 001370C ** Structure Identifier 001371C 10 MQTM-STRUC-ID PIC X(4) VALUE 'TM '. 001372C 001373C ** Structure Version Number 001374C 10 MQTM-VERSION-1 PIC S9(9) BINARY VALUE 1. 001375C 10 MQTM-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001376C 001377C ** Structure Length 001378C 10 MQTM-LENGTH-1 PIC S9(9) BINARY VALUE 684. 001379C 10 MQTM-CURRENT-LENGTH PIC S9(9) BINARY VALUE 684. 001380C 001381C ****************************************************************** 001382C ** Values Related to MQTMC2 Structure 001383C ****************************************************************** 001384C ** Structure Identifier 001385C 10 MQTMC-STRUC-ID PIC X(4) VALUE 'TMC '. 001386C 001387C ** Structure Length 001388C 10 MQTMC2-LENGTH-1 PIC S9(9) BINARY VALUE 684. 001389C 10 MQTMC2-LENGTH-2 PIC S9(9) BINARY VALUE 732. 001390C 10 MQTMC2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 732. 001391C 001392C ** Structure Version Number 001393C 10 MQTMC-VERSION-1 PIC X(4) VALUE ' 1'. 001394C 10 MQTMC-VERSION-2 PIC X(4) VALUE ' 2'. 001395C 10 MQTMC-CURRENT-VERSION PIC X(4) VALUE ' 2'. 001396C 001397C ****************************************************************** 001398C ** Values Related to MQWIH Structure 001399C ****************************************************************** 001400C ** Structure Identifier 001401C 10 MQWIH-STRUC-ID PIC X(4) VALUE 'WIH '. 001402C 001403C ** Structure Version Number 001404C 10 MQWIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001405C 10 MQWIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001406C 001407C ** Structure Length 001408C 10 MQWIH-LENGTH-1 PIC S9(9) BINARY VALUE 120. 001409C 10 MQWIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 120. 001410C 001411C ** Flags 001412C 10 MQWIH-NONE PIC S9(9) BINARY VALUE 0. 001413C 001414C ****************************************************************** 001415C ** Values Related to MQXQH Structure 001416C ****************************************************************** 001417C ** Structure Identifier 001418C 10 MQXQH-STRUC-ID PIC X(4) VALUE 'XQH '. 001419C 001420C ** Structure Version Number 001421C 10 MQXQH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001422C 10 MQXQH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001423C 001424C ** Structure Length 001425C 10 MQXQH-LENGTH-1 PIC S9(9) BINARY VALUE 428. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 29 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001426C 10 MQXQH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 428. 001427C 001428C ** 001429C 001430C ****************************************************************** 001431C ** Values Related to All Functions 001432C ****************************************************************** 001433C ** Connection Handles 001434C 10 MQHC-DEF-HCONN PIC S9(9) COMP-5 VALUE 0. 001435C 10 MQHC-UNUSABLE-HCONN PIC S9(9) COMP-5 VALUE -1. 001436C 10 MQHC-UNASSOCIATED-HCONN PIC S9(9) COMP-5 VALUE -3. 001437C 001438C ** String Lengths 001439C 10 MQ-OPERATOR-MESSAGE-LENGTH PIC S9(9) BINARY VALUE 4. 001440C 10 MQ-ABEND-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001441C 10 MQ-ACCOUNTING-TOKEN-LENGTH PIC S9(9) BINARY VALUE 32. 001442C 10 MQ-APPL-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001443C 10 MQ-APPL-IDENTITY-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001444C 10 MQ-APPL-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001445C 10 MQ-APPL-ORIGIN-DATA-LENGTH PIC S9(9) BINARY VALUE 4. 001446C 10 MQ-APPL-TAG-LENGTH PIC S9(9) BINARY VALUE 28. 001447C 10 MQ-ARM-SUFFIX-LENGTH PIC S9(9) BINARY VALUE 2. 001448C 10 MQ-ATTENTION-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001449C 10 MQ-AUTH-INFO-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 264. 001450C 10 MQ-AUTH-INFO-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001451C 10 MQ-AUTH-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001452C 10 MQ-AUTH-INFO-OCSP-URL-LENGTH PIC S9(9) BINARY VALUE 256. 001453C 10 MQ-AUTHENTICATOR-LENGTH PIC S9(9) BINARY VALUE 8. 001454C 10 MQ-AUTO-REORG-CATALOG-LENGTH PIC S9(9) BINARY VALUE 44. 001455C 10 MQ-AUTO-REORG-TIME-LENGTH PIC S9(9) BINARY VALUE 4. 001456C 10 MQ-BATCH-INTERFACE-ID-LENGTH PIC S9(9) BINARY VALUE 8. 001457C 10 MQ-BRIDGE-NAME-LENGTH PIC S9(9) BINARY VALUE 24. 001458C 10 MQ-CANCEL-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001459C 10 MQ-CF-STRUC-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001460C 10 MQ-CF-STRUC-NAME-LENGTH PIC S9(9) BINARY VALUE 12. 001461C 10 MQ-CHANNEL-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001462C 10 MQ-CHANNEL-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001463C 10 MQ-CHANNEL-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001464C 10 MQ-CHANNEL-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001465C 10 MQ-CHINIT-SERVICE-PARM-LENGTH PIC S9(9) BINARY VALUE 32. 001466C 10 MQ-CICS-FILE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001467C 10 MQ-AMQP-CLIENT-ID-LENGTH PIC S9(9) BINARY VALUE 256. 001468C 10 MQ-CLIENT-ID-LENGTH PIC S9(9) BINARY VALUE 23. 001469C 10 MQ-CLIENT-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001470C 10 MQ-CLUSTER-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001471C 10 MQ-COMM-INFO-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001472C 10 MQ-COMM-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001473C 10 MQ-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 264. 001474C 10 MQ-CONN-TAG-LENGTH PIC S9(9) BINARY VALUE 128. 001475C 10 MQ-CONNECTION-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001476C 10 MQ-CORREL-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001477C 10 MQ-CREATION-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001478C 10 MQ-CREATION-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001479C 10 MQ-CSP-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 256. 001480C 10 MQ-CSP-TOKEN-LENGTH PIC S9(9) BINARY VALUE 8192. 001481C 10 MQ-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001482C 10 MQ-DISTINGUISHED-NAME-LENGTH PIC S9(9) BINARY VALUE 1024. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 30 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001483C 10 MQ-DNS-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 18. 001484C 10 MQ-EXIT-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001485C 10 MQ-EXIT-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001486C 10 MQ-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001487C 10 MQ-EXIT-PD-AREA-LENGTH PIC S9(9) BINARY VALUE 48. 001488C 10 MQ-EXIT-USER-AREA-LENGTH PIC S9(9) BINARY VALUE 16. 001489C 10 MQ-FACILITY-LENGTH PIC S9(9) BINARY VALUE 8. 001490C 10 MQ-FACILITY-LIKE-LENGTH PIC S9(9) BINARY VALUE 4. 001491C 10 MQ-FORMAT-LENGTH PIC S9(9) BINARY VALUE 8. 001492C 10 MQ-FUNCTION-LENGTH PIC S9(9) BINARY VALUE 4. 001493C 10 MQ-GROUP-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001494C 10 MQ-APPL-FUNCTION-NAME-LENGTH PIC S9(9) BINARY VALUE 10. 001495C 10 MQ-INITIAL-KEY-LENGTH PIC S9(9) BINARY VALUE 256. 001496C 10 MQ-INSTALLATION-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001497C 10 MQ-INSTALLATION-NAME-LENGTH PIC S9(9) BINARY VALUE 16. 001498C 10 MQ-INSTALLATION-PATH-LENGTH PIC S9(9) BINARY VALUE 256. 001499C 10 MQ-ISOTIME-LENGTH PIC S9(9) BINARY VALUE 64. 001500C 10 MQ-JAAS-CONFIG-LENGTH PIC S9(9) BINARY VALUE 1024. 001501C 10 MQ-LDAP-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 32. 001502C 10 MQ-LDAP-BASE-DN-LENGTH PIC S9(9) BINARY VALUE 1024. 001503C 10 MQ-LDAP-FIELD-LENGTH PIC S9(9) BINARY VALUE 128. 001504C 10 MQ-LDAP-CLASS-LENGTH PIC S9(9) BINARY VALUE 128. 001505C 10 MQ-LISTENER-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001506C 10 MQ-LISTENER-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001507C 10 MQ-LOCAL-ADDRESS-LENGTH PIC S9(9) BINARY VALUE 48. 001508C 10 MQ-LTERM-OVERRIDE-LENGTH PIC S9(9) BINARY VALUE 8. 001509C 10 MQ-LU-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001510C 10 MQ-LUWID-LENGTH PIC S9(9) BINARY VALUE 16. 001511C 10 MQ-MAX-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 128. 001512C 10 MQ-MAX-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 64. 001513C 10 MQ-MAX-LDAP-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001514C 10 MQ-MAX-PROPERTY-NAME-LENGTH PIC S9(9) BINARY VALUE 4095. 001515C 10 MQ-MAX-USER-ID-LENGTH PIC S9(9) BINARY VALUE 64. 001516C 10 MQ-MCA-JOB-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001517C 10 MQ-MCA-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001518C 10 MQ-MCA-USER-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001519C 10 MQ-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001520C 10 MQ-LDAP-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001521C 10 MQ-MFS-MAP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001522C 10 MQ-MODE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001523C 10 MQ-MSG-HEADER-LENGTH PIC S9(9) BINARY VALUE 4000. 001524C 10 MQ-MSG-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001525C 10 MQ-MSG-TOKEN-LENGTH PIC S9(9) BINARY VALUE 16. 001526C 10 MQ-NAMELIST-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001527C 10 MQ-NAMELIST-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001528C 10 MQ-NHA-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001529C 10 MQ-NHA-INSTANCE-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001530C 10 MQ-OBJECT-INSTANCE-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001531C 10 MQ-OBJECT-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001532C 10 MQ-PASS-TICKET-APPL-LENGTH PIC S9(9) BINARY VALUE 8. 001533C 10 MQ-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 12. 001534C 10 MQ-PROCESS-APPL-ID-LENGTH PIC S9(9) BINARY VALUE 256. 001535C 10 MQ-PROCESS-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001536C 10 MQ-PROCESS-ENV-DATA-LENGTH PIC S9(9) BINARY VALUE 128. 001537C 10 MQ-PROCESS-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001538C 10 MQ-PROCESS-USER-DATA-LENGTH PIC S9(9) BINARY VALUE 128. 001539C 10 MQ-PROGRAM-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 31 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001540C 10 MQ-PUT-APPL-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001541C 10 MQ-PUT-DATE-LENGTH PIC S9(9) BINARY VALUE 8. 001542C 10 MQ-PUT-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001543C 10 MQ-Q-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001544C 10 MQ-Q-MGR-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001545C 10 MQ-Q-MGR-IDENTIFIER-LENGTH PIC S9(9) BINARY VALUE 48. 001546C 10 MQ-Q-MGR-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001547C 10 MQ-Q-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001548C 10 MQ-QSG-NAME-LENGTH PIC S9(9) BINARY VALUE 4. 001549C 10 MQ-REMOTE-SYS-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001550C 10 MQ-SECURITY-ID-LENGTH PIC S9(9) BINARY VALUE 40. 001551C 10 MQ-SELECTOR-LENGTH PIC S9(9) BINARY VALUE 10240. 001552C 10 MQ-SERVICE-ARGS-LENGTH PIC S9(9) BINARY VALUE 255. 001553C 10 MQ-SERVICE-COMMAND-LENGTH PIC S9(9) BINARY VALUE 255. 001554C 10 MQ-SERVICE-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001555C 10 MQ-SERVICE-NAME-LENGTH PIC S9(9) BINARY VALUE 32. 001556C 10 MQ-SERVICE-PATH-LENGTH PIC S9(9) BINARY VALUE 255. 001557C 10 MQ-SERVICE-STEP-LENGTH PIC S9(9) BINARY VALUE 8. 001558C 10 MQ-SHORT-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001559C 10 MQ-SHORT-DNAME-LENGTH PIC S9(9) BINARY VALUE 256. 001560C 10 MQ-SSL-CIPHER-SPEC-LENGTH PIC S9(9) BINARY VALUE 32. 001561C 10 MQ-SSL-CIPHER-SUITE-LENGTH PIC S9(9) BINARY VALUE 32. 001562C 10 MQ-SSL-CRYPTO-HARDWARE-LENGTH PIC S9(9) BINARY VALUE 256. 001563C 10 MQ-SSL-ENCRYP-KEY-REPO-PWD-LEN PIC S9(9) BINARY VALUE 1536. 001564C 10 MQ-SSL-HANDSHAKE-STAGE-LENGTH PIC S9(9) BINARY VALUE 32. 001565C 10 MQ-SSL-KEY-LIBRARY-LENGTH PIC S9(9) BINARY VALUE 44. 001566C 10 MQ-SSL-KEY-MEMBER-LENGTH PIC S9(9) BINARY VALUE 8. 001567C 10 MQ-SSL-KEY-REPOSITORY-LENGTH PIC S9(9) BINARY VALUE 256. 001568C 10 MQ-SSL-KEY-REPO-PWD-LEN PIC S9(9) BINARY VALUE 1024. 001569C 10 MQ-SSL-PEER-NAME-LENGTH PIC S9(9) BINARY VALUE 1024. 001570C 10 MQ-SSL-SHORT-PEER-NAME-LENGTH PIC S9(9) BINARY VALUE 256. 001571C 10 MQ-START-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001572C 10 MQ-STORAGE-CLASS-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001573C 10 MQ-STORAGE-CLASS-LENGTH PIC S9(9) BINARY VALUE 8. 001574C 10 MQ-SUB-IDENTITY-LENGTH PIC S9(9) BINARY VALUE 128. 001575C 10 MQ-SUB-POINT-LENGTH PIC S9(9) BINARY VALUE 128. 001576C 10 MQ-TCP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001577C 10 MQ-TEMPORARY-Q-PREFIX-LENGTH PIC S9(9) BINARY VALUE 32. 001578C 10 MQ-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001579C 10 MQ-TOPIC-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001580C 10 MQ-TOPIC-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001581C 10 MQ-TOPIC-STR-LENGTH PIC S9(9) BINARY VALUE 10240. 001582C 10 MQ-TOTAL-EXIT-DATA-LENGTH PIC S9(9) BINARY VALUE 999. 001583C 10 MQ-TOTAL-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 999. 001584C 10 MQ-TP-NAME-LENGTH PIC S9(9) BINARY VALUE 64. 001585C 10 MQ-TPIPE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001586C 10 MQ-TRAN-INSTANCE-ID-LENGTH PIC S9(9) BINARY VALUE 16. 001587C 10 MQ-TRANSACTION-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001588C 10 MQ-TRIGGER-DATA-LENGTH PIC S9(9) BINARY VALUE 64. 001589C 10 MQ-TRIGGER-PROGRAM-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001590C 10 MQ-TRIGGER-TERM-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001591C 10 MQ-TRIGGER-TRANS-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001592C 10 MQ-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001593C 10 MQ-LONG-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001594C 10 MQ-VERSION-LENGTH PIC S9(9) BINARY VALUE 8. 001595C 10 MQ-XCF-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001596C 10 MQ-XCF-MEMBER-NAME-LENGTH PIC S9(9) BINARY VALUE 16. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 32 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001597C 10 MQ-SMDS-NAME-LENGTH PIC S9(9) BINARY VALUE 4. 001598C 10 MQ-CHLAUTH-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001599C 10 MQ-CUSTOM-LENGTH PIC S9(9) BINARY VALUE 128. 001600C 10 MQ-SUITE-B-SIZE PIC S9(9) BINARY VALUE 4. 001601C 10 MQ-CERT-LABEL-LENGTH PIC S9(9) BINARY VALUE 32. 001602C 001603C ** Completion Codes 001604C 10 MQCC-OK PIC S9(9) BINARY VALUE 0. 001605C 10 MQCC-WARNING PIC S9(9) BINARY VALUE 1. 001606C 10 MQCC-FAILED PIC S9(9) BINARY VALUE 2. 001607C 10 MQCC-UNKNOWN PIC S9(9) BINARY VALUE -1. 001608C 001609C ** Reason Codes 001610C 10 MQRC-NONE PIC S9(9) BINARY VALUE 0. 001611C 10 MQRC-APPL-FIRST PIC S9(9) BINARY VALUE 900. 001612C 10 MQRC-APPL-LAST PIC S9(9) BINARY VALUE 999. 001613C 10 MQRC-ALIAS-BASE-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2001. 001614C 10 MQRC-ALREADY-CONNECTED PIC S9(9) BINARY VALUE 2002. 001615C 10 MQRC-BACKED-OUT PIC S9(9) BINARY VALUE 2003. 001616C 10 MQRC-BUFFER-ERROR PIC S9(9) BINARY VALUE 2004. 001617C 10 MQRC-BUFFER-LENGTH-ERROR PIC S9(9) BINARY VALUE 2005. 001618C 10 MQRC-CHAR-ATTR-LENGTH-ERROR PIC S9(9) BINARY VALUE 2006. 001619C 10 MQRC-CHAR-ATTRS-ERROR PIC S9(9) BINARY VALUE 2007. 001620C 10 MQRC-CHAR-ATTRS-TOO-SHORT PIC S9(9) BINARY VALUE 2008. 001621C 10 MQRC-CONNECTION-BROKEN PIC S9(9) BINARY VALUE 2009. 001622C 10 MQRC-DATA-LENGTH-ERROR PIC S9(9) BINARY VALUE 2010. 001623C 10 MQRC-DYNAMIC-Q-NAME-ERROR PIC S9(9) BINARY VALUE 2011. 001624C 10 MQRC-ENVIRONMENT-ERROR PIC S9(9) BINARY VALUE 2012. 001625C 10 MQRC-EXPIRY-ERROR PIC S9(9) BINARY VALUE 2013. 001626C 10 MQRC-FEEDBACK-ERROR PIC S9(9) BINARY VALUE 2014. 001627C 10 MQRC-GET-INHIBITED PIC S9(9) BINARY VALUE 2016. 001628C 10 MQRC-HANDLE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2017. 001629C 10 MQRC-HCONN-ERROR PIC S9(9) BINARY VALUE 2018. 001630C 10 MQRC-HOBJ-ERROR PIC S9(9) BINARY VALUE 2019. 001631C 10 MQRC-INHIBIT-VALUE-ERROR PIC S9(9) BINARY VALUE 2020. 001632C 10 MQRC-INT-ATTR-COUNT-ERROR PIC S9(9) BINARY VALUE 2021. 001633C 10 MQRC-INT-ATTR-COUNT-TOO-SMALL PIC S9(9) BINARY VALUE 2022. 001634C 10 MQRC-INT-ATTRS-ARRAY-ERROR PIC S9(9) BINARY VALUE 2023. 001635C 10 MQRC-SYNCPOINT-LIMIT-REACHED PIC S9(9) BINARY VALUE 2024. 001636C 10 MQRC-MAX-CONNS-LIMIT-REACHED PIC S9(9) BINARY VALUE 2025. 001637C 10 MQRC-MD-ERROR PIC S9(9) BINARY VALUE 2026. 001638C 10 MQRC-MISSING-REPLY-TO-Q PIC S9(9) BINARY VALUE 2027. 001639C 10 MQRC-MSG-TYPE-ERROR PIC S9(9) BINARY VALUE 2029. 001640C 10 MQRC-MSG-TOO-BIG-FOR-Q PIC S9(9) BINARY VALUE 2030. 001641C 10 MQRC-MSG-TOO-BIG-FOR-Q-MGR PIC S9(9) BINARY VALUE 2031. 001642C 10 MQRC-NO-MSG-AVAILABLE PIC S9(9) BINARY VALUE 2033. 001643C 10 MQRC-NO-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2034. 001644C 10 MQRC-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 2035. 001645C 10 MQRC-NOT-OPEN-FOR-BROWSE PIC S9(9) BINARY VALUE 2036. 001646C 10 MQRC-NOT-OPEN-FOR-INPUT PIC S9(9) BINARY VALUE 2037. 001647C 10 MQRC-NOT-OPEN-FOR-INQUIRE PIC S9(9) BINARY VALUE 2038. 001648C 10 MQRC-NOT-OPEN-FOR-OUTPUT PIC S9(9) BINARY VALUE 2039. 001649C 10 MQRC-NOT-OPEN-FOR-SET PIC S9(9) BINARY VALUE 2040. 001650C 10 MQRC-OBJECT-CHANGED PIC S9(9) BINARY VALUE 2041. 001651C 10 MQRC-OBJECT-IN-USE PIC S9(9) BINARY VALUE 2042. 001652C 10 MQRC-OBJECT-TYPE-ERROR PIC S9(9) BINARY VALUE 2043. 001653C 10 MQRC-OD-ERROR PIC S9(9) BINARY VALUE 2044. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 33 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001654C 10 MQRC-OPTION-NOT-VALID-FOR-TYPE PIC S9(9) BINARY VALUE 2045. 001655C 10 MQRC-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2046. 001656C 10 MQRC-PERSISTENCE-ERROR PIC S9(9) BINARY VALUE 2047. 001657C 10 MQRC-PERSISTENT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2048. 001658C 10 MQRC-PRIORITY-EXCEEDS-MAXIMUM PIC S9(9) BINARY VALUE 2049. 001659C 10 MQRC-PRIORITY-ERROR PIC S9(9) BINARY VALUE 2050. 001660C 10 MQRC-PUT-INHIBITED PIC S9(9) BINARY VALUE 2051. 001661C 10 MQRC-Q-DELETED PIC S9(9) BINARY VALUE 2052. 001662C 10 MQRC-Q-FULL PIC S9(9) BINARY VALUE 2053. 001663C 10 MQRC-Q-NOT-EMPTY PIC S9(9) BINARY VALUE 2055. 001664C 10 MQRC-Q-SPACE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2056. 001665C 10 MQRC-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2057. 001666C 10 MQRC-Q-MGR-NAME-ERROR PIC S9(9) BINARY VALUE 2058. 001667C 10 MQRC-Q-MGR-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2059. 001668C 10 MQRC-REPORT-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2061. 001669C 10 MQRC-SECOND-MARK-NOT-ALLOWED PIC S9(9) BINARY VALUE 2062. 001670C 10 MQRC-SECURITY-ERROR PIC S9(9) BINARY VALUE 2063. 001671C 10 MQRC-TOKEN-TIMESTAMP-NOT-VALID PIC S9(9) BINARY VALUE 2064. 001672C 10 MQRC-SELECTOR-COUNT-ERROR PIC S9(9) BINARY VALUE 2065. 001673C 10 MQRC-SELECTOR-LIMIT-EXCEEDED PIC S9(9) BINARY VALUE 2066. 001674C 10 MQRC-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2067. 001675C 10 MQRC-SELECTOR-NOT-FOR-TYPE PIC S9(9) BINARY VALUE 2068. 001676C 10 MQRC-SIGNAL-OUTSTANDING PIC S9(9) BINARY VALUE 2069. 001677C 10 MQRC-SIGNAL-REQUEST-ACCEPTED PIC S9(9) BINARY VALUE 2070. 001678C 10 MQRC-STORAGE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2071. 001679C 10 MQRC-SYNCPOINT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2072. 001680C 10 MQRC-TRIGGER-CONTROL-ERROR PIC S9(9) BINARY VALUE 2075. 001681C 10 MQRC-TRIGGER-DEPTH-ERROR PIC S9(9) BINARY VALUE 2076. 001682C 10 MQRC-TRIGGER-MSG-PRIORITY-ERR PIC S9(9) BINARY VALUE 2077. 001683C 10 MQRC-TRIGGER-TYPE-ERROR PIC S9(9) BINARY VALUE 2078. 001684C 10 MQRC-TRUNCATED-MSG-ACCEPTED PIC S9(9) BINARY VALUE 2079. 001685C 10 MQRC-TRUNCATED-MSG-FAILED PIC S9(9) BINARY VALUE 2080. 001686C 10 MQRC-UNKNOWN-ALIAS-BASE-Q PIC S9(9) BINARY VALUE 2082. 001687C 10 MQRC-UNKNOWN-OBJECT-NAME PIC S9(9) BINARY VALUE 2085. 001688C 10 MQRC-UNKNOWN-OBJECT-Q-MGR PIC S9(9) BINARY VALUE 2086. 001689C 10 MQRC-UNKNOWN-REMOTE-Q-MGR PIC S9(9) BINARY VALUE 2087. 001690C 10 MQRC-WAIT-INTERVAL-ERROR PIC S9(9) BINARY VALUE 2090. 001691C 10 MQRC-XMIT-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2091. 001692C 10 MQRC-XMIT-Q-USAGE-ERROR PIC S9(9) BINARY VALUE 2092. 001693C 10 MQRC-NOT-OPEN-FOR-PASS-ALL PIC S9(9) BINARY VALUE 2093. 001694C 10 MQRC-NOT-OPEN-FOR-PASS-IDENT PIC S9(9) BINARY VALUE 2094. 001695C 10 MQRC-NOT-OPEN-FOR-SET-ALL PIC S9(9) BINARY VALUE 2095. 001696C 10 MQRC-NOT-OPEN-FOR-SET-IDENT PIC S9(9) BINARY VALUE 2096. 001697C 10 MQRC-CONTEXT-HANDLE-ERROR PIC S9(9) BINARY VALUE 2097. 001698C 10 MQRC-CONTEXT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2098. 001699C 10 MQRC-SIGNAL1-ERROR PIC S9(9) BINARY VALUE 2099. 001700C 10 MQRC-OBJECT-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2100. 001701C 10 MQRC-OBJECT-DAMAGED PIC S9(9) BINARY VALUE 2101. 001702C 10 MQRC-RESOURCE-PROBLEM PIC S9(9) BINARY VALUE 2102. 001703C 10 MQRC-ANOTHER-Q-MGR-CONNECTED PIC S9(9) BINARY VALUE 2103. 001704C 10 MQRC-UNKNOWN-REPORT-OPTION PIC S9(9) BINARY VALUE 2104. 001705C 10 MQRC-STORAGE-CLASS-ERROR PIC S9(9) BINARY VALUE 2105. 001706C 10 MQRC-COD-NOT-VALID-FOR-XCF-Q PIC S9(9) BINARY VALUE 2106. 001707C 10 MQRC-XWAIT-CANCELED PIC S9(9) BINARY VALUE 2107. 001708C 10 MQRC-XWAIT-ERROR PIC S9(9) BINARY VALUE 2108. 001709C 10 MQRC-SUPPRESSED-BY-EXIT PIC S9(9) BINARY VALUE 2109. 001710C 10 MQRC-FORMAT-ERROR PIC S9(9) BINARY VALUE 2110. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 34 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001711C 10 MQRC-SOURCE-CCSID-ERROR PIC S9(9) BINARY VALUE 2111. 001712C 10 MQRC-SOURCE-INTEGER-ENC-ERROR PIC S9(9) BINARY VALUE 2112. 001713C 10 MQRC-SOURCE-DECIMAL-ENC-ERROR PIC S9(9) BINARY VALUE 2113. 001714C 10 MQRC-SOURCE-FLOAT-ENC-ERROR PIC S9(9) BINARY VALUE 2114. 001715C 10 MQRC-TARGET-CCSID-ERROR PIC S9(9) BINARY VALUE 2115. 001716C 10 MQRC-TARGET-INTEGER-ENC-ERROR PIC S9(9) BINARY VALUE 2116. 001717C 10 MQRC-TARGET-DECIMAL-ENC-ERROR PIC S9(9) BINARY VALUE 2117. 001718C 10 MQRC-TARGET-FLOAT-ENC-ERROR PIC S9(9) BINARY VALUE 2118. 001719C 10 MQRC-NOT-CONVERTED PIC S9(9) BINARY VALUE 2119. 001720C 10 MQRC-CONVERTED-MSG-TOO-BIG PIC S9(9) BINARY VALUE 2120. 001721C 10 MQRC-TRUNCATED PIC S9(9) BINARY VALUE 2120. 001722C 10 MQRC-NO-EXTERNAL-PARTICIPANTS PIC S9(9) BINARY VALUE 2121. 001723C 10 MQRC-PARTICIPANT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2122. 001724C 10 MQRC-OUTCOME-MIXED PIC S9(9) BINARY VALUE 2123. 001725C 10 MQRC-OUTCOME-PENDING PIC S9(9) BINARY VALUE 2124. 001726C 10 MQRC-BRIDGE-STARTED PIC S9(9) BINARY VALUE 2125. 001727C 10 MQRC-BRIDGE-STOPPED PIC S9(9) BINARY VALUE 2126. 001728C 10 MQRC-ADAPTER-STORAGE-SHORTAGE PIC S9(9) BINARY VALUE 2127. 001729C 10 MQRC-UOW-IN-PROGRESS PIC S9(9) BINARY VALUE 2128. 001730C 10 MQRC-ADAPTER-CONN-LOAD-ERROR PIC S9(9) BINARY VALUE 2129. 001731C 10 MQRC-ADAPTER-SERV-LOAD-ERROR PIC S9(9) BINARY VALUE 2130. 001732C 10 MQRC-ADAPTER-DEFS-ERROR PIC S9(9) BINARY VALUE 2131. 001733C 10 MQRC-ADAPTER-DEFS-LOAD-ERROR PIC S9(9) BINARY VALUE 2132. 001734C 10 MQRC-ADAPTER-CONV-LOAD-ERROR PIC S9(9) BINARY VALUE 2133. 001735C 10 MQRC-BO-ERROR PIC S9(9) BINARY VALUE 2134. 001736C 10 MQRC-DH-ERROR PIC S9(9) BINARY VALUE 2135. 001737C 10 MQRC-MULTIPLE-REASONS PIC S9(9) BINARY VALUE 2136. 001738C 10 MQRC-OPEN-FAILED PIC S9(9) BINARY VALUE 2137. 001739C 10 MQRC-ADAPTER-DISC-LOAD-ERROR PIC S9(9) BINARY VALUE 2138. 001740C 10 MQRC-CNO-ERROR PIC S9(9) BINARY VALUE 2139. 001741C 10 MQRC-CICS-WAIT-FAILED PIC S9(9) BINARY VALUE 2140. 001742C 10 MQRC-DLH-ERROR PIC S9(9) BINARY VALUE 2141. 001743C 10 MQRC-HEADER-ERROR PIC S9(9) BINARY VALUE 2142. 001744C 10 MQRC-SOURCE-LENGTH-ERROR PIC S9(9) BINARY VALUE 2143. 001745C 10 MQRC-TARGET-LENGTH-ERROR PIC S9(9) BINARY VALUE 2144. 001746C 10 MQRC-SOURCE-BUFFER-ERROR PIC S9(9) BINARY VALUE 2145. 001747C 10 MQRC-TARGET-BUFFER-ERROR PIC S9(9) BINARY VALUE 2146. 001748C 10 MQRC-INCOMPLETE-TRANSACTION PIC S9(9) BINARY VALUE 2147. 001749C 10 MQRC-IIH-ERROR PIC S9(9) BINARY VALUE 2148. 001750C 10 MQRC-PCF-ERROR PIC S9(9) BINARY VALUE 2149. 001751C 10 MQRC-DBCS-ERROR PIC S9(9) BINARY VALUE 2150. 001752C 10 MQRC-OBJECT-NAME-ERROR PIC S9(9) BINARY VALUE 2152. 001753C 10 MQRC-OBJECT-Q-MGR-NAME-ERROR PIC S9(9) BINARY VALUE 2153. 001754C 10 MQRC-RECS-PRESENT-ERROR PIC S9(9) BINARY VALUE 2154. 001755C 10 MQRC-OBJECT-RECORDS-ERROR PIC S9(9) BINARY VALUE 2155. 001756C 10 MQRC-RESPONSE-RECORDS-ERROR PIC S9(9) BINARY VALUE 2156. 001757C 10 MQRC-ASID-MISMATCH PIC S9(9) BINARY VALUE 2157. 001758C 10 MQRC-PMO-RECORD-FLAGS-ERROR PIC S9(9) BINARY VALUE 2158. 001759C 10 MQRC-PUT-MSG-RECORDS-ERROR PIC S9(9) BINARY VALUE 2159. 001760C 10 MQRC-CONN-ID-IN-USE PIC S9(9) BINARY VALUE 2160. 001761C 10 MQRC-Q-MGR-QUIESCING PIC S9(9) BINARY VALUE 2161. 001762C 10 MQRC-Q-MGR-STOPPING PIC S9(9) BINARY VALUE 2162. 001763C 10 MQRC-DUPLICATE-RECOV-COORD PIC S9(9) BINARY VALUE 2163. 001764C 10 MQRC-PMO-ERROR PIC S9(9) BINARY VALUE 2173. 001765C 10 MQRC-API-EXIT-NOT-FOUND PIC S9(9) BINARY VALUE 2182. 001766C 10 MQRC-API-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2183. 001767C 10 MQRC-REMOTE-Q-NAME-ERROR PIC S9(9) BINARY VALUE 2184. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 35 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001768C 10 MQRC-INCONSISTENT-PERSISTENCE PIC S9(9) BINARY VALUE 2185. 001769C 10 MQRC-GMO-ERROR PIC S9(9) BINARY VALUE 2186. 001770C 10 MQRC-CICS-BRIDGE-RESTRICTION PIC S9(9) BINARY VALUE 2187. 001771C 10 MQRC-STOPPED-BY-CLUSTER-EXIT PIC S9(9) BINARY VALUE 2188. 001772C 10 MQRC-CLUSTER-RESOLUTION-ERROR PIC S9(9) BINARY VALUE 2189. 001773C 10 MQRC-CONVERTED-STRING-TOO-BIG PIC S9(9) BINARY VALUE 2190. 001774C 10 MQRC-TMC-ERROR PIC S9(9) BINARY VALUE 2191. 001775C 10 MQRC-STORAGE-MEDIUM-FULL PIC S9(9) BINARY VALUE 2192. 001776C 10 MQRC-PAGESET-FULL PIC S9(9) BINARY VALUE 2192. 001777C 10 MQRC-PAGESET-ERROR PIC S9(9) BINARY VALUE 2193. 001778C 10 MQRC-NAME-NOT-VALID-FOR-TYPE PIC S9(9) BINARY VALUE 2194. 001779C 10 MQRC-UNEXPECTED-ERROR PIC S9(9) BINARY VALUE 2195. 001780C 10 MQRC-UNKNOWN-XMIT-Q PIC S9(9) BINARY VALUE 2196. 001781C 10 MQRC-UNKNOWN-DEF-XMIT-Q PIC S9(9) BINARY VALUE 2197. 001782C 10 MQRC-DEF-XMIT-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2198. 001783C 10 MQRC-DEF-XMIT-Q-USAGE-ERROR PIC S9(9) BINARY VALUE 2199. 001784C 10 MQRC-MSG-MARKED-BROWSE-CO-OP PIC S9(9) BINARY VALUE 2200. 001785C 10 MQRC-NAME-IN-USE PIC S9(9) BINARY VALUE 2201. 001786C 10 MQRC-CONNECTION-QUIESCING PIC S9(9) BINARY VALUE 2202. 001787C 10 MQRC-CONNECTION-STOPPING PIC S9(9) BINARY VALUE 2203. 001788C 10 MQRC-ADAPTER-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2204. 001789C 10 MQRC-MSG-ID-ERROR PIC S9(9) BINARY VALUE 2206. 001790C 10 MQRC-CORREL-ID-ERROR PIC S9(9) BINARY VALUE 2207. 001791C 10 MQRC-FILE-SYSTEM-ERROR PIC S9(9) BINARY VALUE 2208. 001792C 10 MQRC-NO-MSG-LOCKED PIC S9(9) BINARY VALUE 2209. 001793C 10 MQRC-SOAP-DOTNET-ERROR PIC S9(9) BINARY VALUE 2210. 001794C 10 MQRC-SOAP-AXIS-ERROR PIC S9(9) BINARY VALUE 2211. 001795C 10 MQRC-SOAP-URL-ERROR PIC S9(9) BINARY VALUE 2212. 001796C 10 MQRC-FILE-NOT-AUDITED PIC S9(9) BINARY VALUE 2216. 001797C 10 MQRC-CONNECTION-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 2217. 001798C 10 MQRC-MSG-TOO-BIG-FOR-CHANNEL PIC S9(9) BINARY VALUE 2218. 001799C 10 MQRC-CALL-IN-PROGRESS PIC S9(9) BINARY VALUE 2219. 001800C 10 MQRC-RMH-ERROR PIC S9(9) BINARY VALUE 2220. 001801C 10 MQRC-Q-MGR-ACTIVE PIC S9(9) BINARY VALUE 2222. 001802C 10 MQRC-Q-MGR-NOT-ACTIVE PIC S9(9) BINARY VALUE 2223. 001803C 10 MQRC-Q-DEPTH-HIGH PIC S9(9) BINARY VALUE 2224. 001804C 10 MQRC-Q-DEPTH-LOW PIC S9(9) BINARY VALUE 2225. 001805C 10 MQRC-Q-SERVICE-INTERVAL-HIGH PIC S9(9) BINARY VALUE 2226. 001806C 10 MQRC-Q-SERVICE-INTERVAL-OK PIC S9(9) BINARY VALUE 2227. 001807C 10 MQRC-RFH-HEADER-FIELD-ERROR PIC S9(9) BINARY VALUE 2228. 001808C 10 MQRC-RAS-PROPERTY-ERROR PIC S9(9) BINARY VALUE 2229. 001809C 10 MQRC-UNIT-OF-WORK-NOT-STARTED PIC S9(9) BINARY VALUE 2232. 001810C 10 MQRC-CHANNEL-AUTO-DEF-OK PIC S9(9) BINARY VALUE 2233. 001811C 10 MQRC-CHANNEL-AUTO-DEF-ERROR PIC S9(9) BINARY VALUE 2234. 001812C 10 MQRC-CFH-ERROR PIC S9(9) BINARY VALUE 2235. 001813C 10 MQRC-CFIL-ERROR PIC S9(9) BINARY VALUE 2236. 001814C 10 MQRC-CFIN-ERROR PIC S9(9) BINARY VALUE 2237. 001815C 10 MQRC-CFSL-ERROR PIC S9(9) BINARY VALUE 2238. 001816C 10 MQRC-CFST-ERROR PIC S9(9) BINARY VALUE 2239. 001817C 10 MQRC-INCOMPLETE-GROUP PIC S9(9) BINARY VALUE 2241. 001818C 10 MQRC-INCOMPLETE-MSG PIC S9(9) BINARY VALUE 2242. 001819C 10 MQRC-INCONSISTENT-CCSIDS PIC S9(9) BINARY VALUE 2243. 001820C 10 MQRC-INCONSISTENT-ENCODINGS PIC S9(9) BINARY VALUE 2244. 001821C 10 MQRC-INCONSISTENT-UOW PIC S9(9) BINARY VALUE 2245. 001822C 10 MQRC-INVALID-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2246. 001823C 10 MQRC-MATCH-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2247. 001824C 10 MQRC-MDE-ERROR PIC S9(9) BINARY VALUE 2248. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 36 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001825C 10 MQRC-MSG-FLAGS-ERROR PIC S9(9) BINARY VALUE 2249. 001826C 10 MQRC-MSG-SEQ-NUMBER-ERROR PIC S9(9) BINARY VALUE 2250. 001827C 10 MQRC-OFFSET-ERROR PIC S9(9) BINARY VALUE 2251. 001828C 10 MQRC-ORIGINAL-LENGTH-ERROR PIC S9(9) BINARY VALUE 2252. 001829C 10 MQRC-SEGMENT-LENGTH-ZERO PIC S9(9) BINARY VALUE 2253. 001830C 10 MQRC-UOW-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2255. 001831C 10 MQRC-WRONG-GMO-VERSION PIC S9(9) BINARY VALUE 2256. 001832C 10 MQRC-WRONG-MD-VERSION PIC S9(9) BINARY VALUE 2257. 001833C 10 MQRC-GROUP-ID-ERROR PIC S9(9) BINARY VALUE 2258. 001834C 10 MQRC-INCONSISTENT-BROWSE PIC S9(9) BINARY VALUE 2259. 001835C 10 MQRC-XQH-ERROR PIC S9(9) BINARY VALUE 2260. 001836C 10 MQRC-SRC-ENV-ERROR PIC S9(9) BINARY VALUE 2261. 001837C 10 MQRC-SRC-NAME-ERROR PIC S9(9) BINARY VALUE 2262. 001838C 10 MQRC-DEST-ENV-ERROR PIC S9(9) BINARY VALUE 2263. 001839C 10 MQRC-DEST-NAME-ERROR PIC S9(9) BINARY VALUE 2264. 001840C 10 MQRC-TM-ERROR PIC S9(9) BINARY VALUE 2265. 001841C 10 MQRC-CLUSTER-EXIT-ERROR PIC S9(9) BINARY VALUE 2266. 001842C 10 MQRC-CLUSTER-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2267. 001843C 10 MQRC-CLUSTER-PUT-INHIBITED PIC S9(9) BINARY VALUE 2268. 001844C 10 MQRC-CLUSTER-RESOURCE-ERROR PIC S9(9) BINARY VALUE 2269. 001845C 10 MQRC-NO-DESTINATIONS-AVAILABLE PIC S9(9) BINARY VALUE 2270. 001846C 10 MQRC-CONN-TAG-IN-USE PIC S9(9) BINARY VALUE 2271. 001847C 10 MQRC-PARTIALLY-CONVERTED PIC S9(9) BINARY VALUE 2272. 001848C 10 MQRC-CONNECTION-ERROR PIC S9(9) BINARY VALUE 2273. 001849C 10 MQRC-OPTION-ENVIRONMENT-ERROR PIC S9(9) BINARY VALUE 2274. 001850C 10 MQRC-CD-ERROR PIC S9(9) BINARY VALUE 2277. 001851C 10 MQRC-CLIENT-CONN-ERROR PIC S9(9) BINARY VALUE 2278. 001852C 10 MQRC-CHANNEL-STOPPED-BY-USER PIC S9(9) BINARY VALUE 2279. 001853C 10 MQRC-HCONFIG-ERROR PIC S9(9) BINARY VALUE 2280. 001854C 10 MQRC-FUNCTION-ERROR PIC S9(9) BINARY VALUE 2281. 001855C 10 MQRC-CHANNEL-STARTED PIC S9(9) BINARY VALUE 2282. 001856C 10 MQRC-CHANNEL-STOPPED PIC S9(9) BINARY VALUE 2283. 001857C 10 MQRC-CHANNEL-CONV-ERROR PIC S9(9) BINARY VALUE 2284. 001858C 10 MQRC-SERVICE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2285. 001859C 10 MQRC-INITIALIZATION-FAILED PIC S9(9) BINARY VALUE 2286. 001860C 10 MQRC-TERMINATION-FAILED PIC S9(9) BINARY VALUE 2287. 001861C 10 MQRC-UNKNOWN-Q-NAME PIC S9(9) BINARY VALUE 2288. 001862C 10 MQRC-SERVICE-ERROR PIC S9(9) BINARY VALUE 2289. 001863C 10 MQRC-Q-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2290. 001864C 10 MQRC-USER-ID-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2291. 001865C 10 MQRC-UNKNOWN-ENTITY PIC S9(9) BINARY VALUE 2292. 001866C 10 MQRC-UNKNOWN-AUTH-ENTITY PIC S9(9) BINARY VALUE 2293. 001867C 10 MQRC-UNKNOWN-REF-OBJECT PIC S9(9) BINARY VALUE 2294. 001868C 10 MQRC-CHANNEL-ACTIVATED PIC S9(9) BINARY VALUE 2295. 001869C 10 MQRC-CHANNEL-NOT-ACTIVATED PIC S9(9) BINARY VALUE 2296. 001870C 10 MQRC-UOW-CANCELED PIC S9(9) BINARY VALUE 2297. 001871C 10 MQRC-FUNCTION-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2298. 001872C 10 MQRC-SELECTOR-TYPE-ERROR PIC S9(9) BINARY VALUE 2299. 001873C 10 MQRC-COMMAND-TYPE-ERROR PIC S9(9) BINARY VALUE 2300. 001874C 10 MQRC-MULTIPLE-INSTANCE-ERROR PIC S9(9) BINARY VALUE 2301. 001875C 10 MQRC-SYSTEM-ITEM-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2302. 001876C 10 MQRC-BAG-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2303. 001877C 10 MQRC-SELECTOR-OUT-OF-RANGE PIC S9(9) BINARY VALUE 2304. 001878C 10 MQRC-SELECTOR-NOT-UNIQUE PIC S9(9) BINARY VALUE 2305. 001879C 10 MQRC-INDEX-NOT-PRESENT PIC S9(9) BINARY VALUE 2306. 001880C 10 MQRC-STRING-ERROR PIC S9(9) BINARY VALUE 2307. 001881C 10 MQRC-ENCODING-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2308. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 37 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001882C 10 MQRC-SELECTOR-NOT-PRESENT PIC S9(9) BINARY VALUE 2309. 001883C 10 MQRC-OUT-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2310. 001884C 10 MQRC-STRING-TRUNCATED PIC S9(9) BINARY VALUE 2311. 001885C 10 MQRC-SELECTOR-WRONG-TYPE PIC S9(9) BINARY VALUE 2312. 001886C 10 MQRC-INCONSISTENT-ITEM-TYPE PIC S9(9) BINARY VALUE 2313. 001887C 10 MQRC-INDEX-ERROR PIC S9(9) BINARY VALUE 2314. 001888C 10 MQRC-SYSTEM-BAG-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2315. 001889C 10 MQRC-ITEM-COUNT-ERROR PIC S9(9) BINARY VALUE 2316. 001890C 10 MQRC-FORMAT-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2317. 001891C 10 MQRC-SELECTOR-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2318. 001892C 10 MQRC-ITEM-VALUE-ERROR PIC S9(9) BINARY VALUE 2319. 001893C 10 MQRC-HBAG-ERROR PIC S9(9) BINARY VALUE 2320. 001894C 10 MQRC-PARAMETER-MISSING PIC S9(9) BINARY VALUE 2321. 001895C 10 MQRC-CMD-SERVER-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2322. 001896C 10 MQRC-STRING-LENGTH-ERROR PIC S9(9) BINARY VALUE 2323. 001897C 10 MQRC-INQUIRY-COMMAND-ERROR PIC S9(9) BINARY VALUE 2324. 001898C 10 MQRC-NESTED-BAG-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2325. 001899C 10 MQRC-BAG-WRONG-TYPE PIC S9(9) BINARY VALUE 2326. 001900C 10 MQRC-ITEM-TYPE-ERROR PIC S9(9) BINARY VALUE 2327. 001901C 10 MQRC-SYSTEM-BAG-NOT-DELETABLE PIC S9(9) BINARY VALUE 2328. 001902C 10 MQRC-SYSTEM-ITEM-NOT-DELETABLE PIC S9(9) BINARY VALUE 2329. 001903C 10 MQRC-CODED-CHAR-SET-ID-ERROR PIC S9(9) BINARY VALUE 2330. 001904C 10 MQRC-MSG-TOKEN-ERROR PIC S9(9) BINARY VALUE 2331. 001905C 10 MQRC-MISSING-WIH PIC S9(9) BINARY VALUE 2332. 001906C 10 MQRC-WIH-ERROR PIC S9(9) BINARY VALUE 2333. 001907C 10 MQRC-RFH-ERROR PIC S9(9) BINARY VALUE 2334. 001908C 10 MQRC-RFH-STRING-ERROR PIC S9(9) BINARY VALUE 2335. 001909C 10 MQRC-RFH-COMMAND-ERROR PIC S9(9) BINARY VALUE 2336. 001910C 10 MQRC-RFH-PARM-ERROR PIC S9(9) BINARY VALUE 2337. 001911C 10 MQRC-RFH-DUPLICATE-PARM PIC S9(9) BINARY VALUE 2338. 001912C 10 MQRC-RFH-PARM-MISSING PIC S9(9) BINARY VALUE 2339. 001913C 10 MQRC-CHAR-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2340. 001914C 10 MQRC-UCS2-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2341. 001915C 10 MQRC-DB2-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2342. 001916C 10 MQRC-OBJECT-NOT-UNIQUE PIC S9(9) BINARY VALUE 2343. 001917C 10 MQRC-CONN-TAG-NOT-RELEASED PIC S9(9) BINARY VALUE 2344. 001918C 10 MQRC-CF-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2345. 001919C 10 MQRC-CF-STRUC-IN-USE PIC S9(9) BINARY VALUE 2346. 001920C 10 MQRC-CF-STRUC-LIST-HDR-IN-USE PIC S9(9) BINARY VALUE 2347. 001921C 10 MQRC-CF-STRUC-AUTH-FAILED PIC S9(9) BINARY VALUE 2348. 001922C 10 MQRC-CF-STRUC-ERROR PIC S9(9) BINARY VALUE 2349. 001923C 10 MQRC-CONN-TAG-NOT-USABLE PIC S9(9) BINARY VALUE 2350. 001924C 10 MQRC-GLOBAL-UOW-CONFLICT PIC S9(9) BINARY VALUE 2351. 001925C 10 MQRC-LOCAL-UOW-CONFLICT PIC S9(9) BINARY VALUE 2352. 001926C 10 MQRC-HANDLE-IN-USE-FOR-UOW PIC S9(9) BINARY VALUE 2353. 001927C 10 MQRC-UOW-ENLISTMENT-ERROR PIC S9(9) BINARY VALUE 2354. 001928C 10 MQRC-UOW-MIX-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2355. 001929C 10 MQRC-WXP-ERROR PIC S9(9) BINARY VALUE 2356. 001930C 10 MQRC-CURRENT-RECORD-ERROR PIC S9(9) BINARY VALUE 2357. 001931C 10 MQRC-NEXT-OFFSET-ERROR PIC S9(9) BINARY VALUE 2358. 001932C 10 MQRC-NO-RECORD-AVAILABLE PIC S9(9) BINARY VALUE 2359. 001933C 10 MQRC-OBJECT-LEVEL-INCOMPATIBLE PIC S9(9) BINARY VALUE 2360. 001934C 10 MQRC-NEXT-RECORD-ERROR PIC S9(9) BINARY VALUE 2361. 001935C 10 MQRC-BACKOUT-THRESHOLD-REACHED PIC S9(9) BINARY VALUE 2362. 001936C 10 MQRC-MSG-NOT-MATCHED PIC S9(9) BINARY VALUE 2363. 001937C 10 MQRC-JMS-FORMAT-ERROR PIC S9(9) BINARY VALUE 2364. 001938C 10 MQRC-SEGMENTS-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2365. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 38 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001939C 10 MQRC-WRONG-CF-LEVEL PIC S9(9) BINARY VALUE 2366. 001940C 10 MQRC-CONFIG-CREATE-OBJECT PIC S9(9) BINARY VALUE 2367. 001941C 10 MQRC-CONFIG-CHANGE-OBJECT PIC S9(9) BINARY VALUE 2368. 001942C 10 MQRC-CONFIG-DELETE-OBJECT PIC S9(9) BINARY VALUE 2369. 001943C 10 MQRC-CONFIG-REFRESH-OBJECT PIC S9(9) BINARY VALUE 2370. 001944C 10 MQRC-CHANNEL-SSL-ERROR PIC S9(9) BINARY VALUE 2371. 001945C 10 MQRC-PARTICIPANT-NOT-DEFINED PIC S9(9) BINARY VALUE 2372. 001946C 10 MQRC-CF-STRUC-FAILED PIC S9(9) BINARY VALUE 2373. 001947C 10 MQRC-API-EXIT-ERROR PIC S9(9) BINARY VALUE 2374. 001948C 10 MQRC-API-EXIT-INIT-ERROR PIC S9(9) BINARY VALUE 2375. 001949C 10 MQRC-API-EXIT-TERM-ERROR PIC S9(9) BINARY VALUE 2376. 001950C 10 MQRC-EXIT-REASON-ERROR PIC S9(9) BINARY VALUE 2377. 001951C 10 MQRC-RESERVED-VALUE-ERROR PIC S9(9) BINARY VALUE 2378. 001952C 10 MQRC-NO-DATA-AVAILABLE PIC S9(9) BINARY VALUE 2379. 001953C 10 MQRC-SCO-ERROR PIC S9(9) BINARY VALUE 2380. 001954C 10 MQRC-KEY-REPOSITORY-ERROR PIC S9(9) BINARY VALUE 2381. 001955C 10 MQRC-CRYPTO-HARDWARE-ERROR PIC S9(9) BINARY VALUE 2382. 001956C 10 MQRC-AUTH-INFO-REC-COUNT-ERROR PIC S9(9) BINARY VALUE 2383. 001957C 10 MQRC-AUTH-INFO-REC-ERROR PIC S9(9) BINARY VALUE 2384. 001958C 10 MQRC-AIR-ERROR PIC S9(9) BINARY VALUE 2385. 001959C 10 MQRC-AUTH-INFO-TYPE-ERROR PIC S9(9) BINARY VALUE 2386. 001960C 10 MQRC-AUTH-INFO-CONN-NAME-ERROR PIC S9(9) BINARY VALUE 2387. 001961C 10 MQRC-LDAP-USER-NAME-ERROR PIC S9(9) BINARY VALUE 2388. 001962C 10 MQRC-LDAP-USER-NAME-LENGTH-ERR PIC S9(9) BINARY VALUE 2389. 001963C 10 MQRC-LDAP-PASSWORD-ERROR PIC S9(9) BINARY VALUE 2390. 001964C 10 MQRC-SSL-ALREADY-INITIALIZED PIC S9(9) BINARY VALUE 2391. 001965C 10 MQRC-SSL-CONFIG-ERROR PIC S9(9) BINARY VALUE 2392. 001966C 10 MQRC-SSL-INITIALIZATION-ERROR PIC S9(9) BINARY VALUE 2393. 001967C 10 MQRC-Q-INDEX-TYPE-ERROR PIC S9(9) BINARY VALUE 2394. 001968C 10 MQRC-CFBS-ERROR PIC S9(9) BINARY VALUE 2395. 001969C 10 MQRC-SSL-NOT-ALLOWED PIC S9(9) BINARY VALUE 2396. 001970C 10 MQRC-JSSE-ERROR PIC S9(9) BINARY VALUE 2397. 001971C 10 MQRC-SSL-PEER-NAME-MISMATCH PIC S9(9) BINARY VALUE 2398. 001972C 10 MQRC-SSL-PEER-NAME-ERROR PIC S9(9) BINARY VALUE 2399. 001973C 10 MQRC-UNSUPPORTED-CIPHER-SUITE PIC S9(9) BINARY VALUE 2400. 001974C 10 MQRC-SSL-CERTIFICATE-REVOKED PIC S9(9) BINARY VALUE 2401. 001975C 10 MQRC-SSL-CERT-STORE-ERROR PIC S9(9) BINARY VALUE 2402. 001976C 10 MQRC-CLIENT-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2406. 001977C 10 MQRC-CLIENT-EXIT-ERROR PIC S9(9) BINARY VALUE 2407. 001978C 10 MQRC-UOW-COMMITTED PIC S9(9) BINARY VALUE 2408. 001979C 10 MQRC-SSL-KEY-RESET-ERROR PIC S9(9) BINARY VALUE 2409. 001980C 10 MQRC-UNKNOWN-COMPONENT-NAME PIC S9(9) BINARY VALUE 2410. 001981C 10 MQRC-LOGGER-STATUS PIC S9(9) BINARY VALUE 2411. 001982C 10 MQRC-COMMAND-MQSC PIC S9(9) BINARY VALUE 2412. 001983C 10 MQRC-COMMAND-PCF PIC S9(9) BINARY VALUE 2413. 001984C 10 MQRC-CFIF-ERROR PIC S9(9) BINARY VALUE 2414. 001985C 10 MQRC-CFSF-ERROR PIC S9(9) BINARY VALUE 2415. 001986C 10 MQRC-CFGR-ERROR PIC S9(9) BINARY VALUE 2416. 001987C 10 MQRC-MSG-NOT-ALLOWED-IN-GROUP PIC S9(9) BINARY VALUE 2417. 001988C 10 MQRC-FILTER-OPERATOR-ERROR PIC S9(9) BINARY VALUE 2418. 001989C 10 MQRC-NESTED-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2419. 001990C 10 MQRC-EPH-ERROR PIC S9(9) BINARY VALUE 2420. 001991C 10 MQRC-RFH-FORMAT-ERROR PIC S9(9) BINARY VALUE 2421. 001992C 10 MQRC-CFBF-ERROR PIC S9(9) BINARY VALUE 2422. 001993C 10 MQRC-CLIENT-CHANNEL-CONFLICT PIC S9(9) BINARY VALUE 2423. 001994C 10 MQRC-SD-ERROR PIC S9(9) BINARY VALUE 2424. 001995C 10 MQRC-TOPIC-STRING-ERROR PIC S9(9) BINARY VALUE 2425. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 39 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001996C 10 MQRC-STS-ERROR PIC S9(9) BINARY VALUE 2426. 001997C 10 MQRC-NO-SUBSCRIPTION PIC S9(9) BINARY VALUE 2428. 001998C 10 MQRC-SUBSCRIPTION-IN-USE PIC S9(9) BINARY VALUE 2429. 001999C 10 MQRC-STAT-TYPE-ERROR PIC S9(9) BINARY VALUE 2430. 002000C 10 MQRC-SUB-USER-DATA-ERROR PIC S9(9) BINARY VALUE 2431. 002001C 10 MQRC-SUB-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2432. 002002C 10 MQRC-IDENTITY-MISMATCH PIC S9(9) BINARY VALUE 2434. 002003C 10 MQRC-ALTER-SUB-ERROR PIC S9(9) BINARY VALUE 2435. 002004C 10 MQRC-DURABILITY-NOT-ALLOWED PIC S9(9) BINARY VALUE 2436. 002005C 10 MQRC-NO-RETAINED-MSG PIC S9(9) BINARY VALUE 2437. 002006C 10 MQRC-SRO-ERROR PIC S9(9) BINARY VALUE 2438. 002007C 10 MQRC-SUB-NAME-ERROR PIC S9(9) BINARY VALUE 2440. 002008C 10 MQRC-OBJECT-STRING-ERROR PIC S9(9) BINARY VALUE 2441. 002009C 10 MQRC-PROPERTY-NAME-ERROR PIC S9(9) BINARY VALUE 2442. 002010C 10 MQRC-SEGMENTATION-NOT-ALLOWED PIC S9(9) BINARY VALUE 2443. 002011C 10 MQRC-CBD-ERROR PIC S9(9) BINARY VALUE 2444. 002012C 10 MQRC-CTLO-ERROR PIC S9(9) BINARY VALUE 2445. 002013C 10 MQRC-NO-CALLBACKS-ACTIVE PIC S9(9) BINARY VALUE 2446. 002014C 10 MQRC-CALLBACK-NOT-REGISTERED PIC S9(9) BINARY VALUE 2448. 002015C 10 MQRC-OPTIONS-CHANGED PIC S9(9) BINARY VALUE 2457. 002016C 10 MQRC-READ-AHEAD-MSGS PIC S9(9) BINARY VALUE 2458. 002017C 10 MQRC-SELECTOR-SYNTAX-ERROR PIC S9(9) BINARY VALUE 2459. 002018C 10 MQRC-HMSG-ERROR PIC S9(9) BINARY VALUE 2460. 002019C 10 MQRC-CMHO-ERROR PIC S9(9) BINARY VALUE 2461. 002020C 10 MQRC-DMHO-ERROR PIC S9(9) BINARY VALUE 2462. 002021C 10 MQRC-SMPO-ERROR PIC S9(9) BINARY VALUE 2463. 002022C 10 MQRC-IMPO-ERROR PIC S9(9) BINARY VALUE 2464. 002023C 10 MQRC-PROPERTY-NAME-TOO-BIG PIC S9(9) BINARY VALUE 2465. 002024C 10 MQRC-PROP-VALUE-NOT-CONVERTED PIC S9(9) BINARY VALUE 2466. 002025C 10 MQRC-PROP-TYPE-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2467. 002026C 10 MQRC-PROPERTY-VALUE-TOO-BIG PIC S9(9) BINARY VALUE 2469. 002027C 10 MQRC-PROP-CONV-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2470. 002028C 10 MQRC-PROPERTY-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2471. 002029C 10 MQRC-PROP-NUMBER-FORMAT-ERROR PIC S9(9) BINARY VALUE 2472. 002030C 10 MQRC-PROPERTY-TYPE-ERROR PIC S9(9) BINARY VALUE 2473. 002031C 10 MQRC-PROPERTIES-TOO-BIG PIC S9(9) BINARY VALUE 2478. 002032C 10 MQRC-PUT-NOT-RETAINED PIC S9(9) BINARY VALUE 2479. 002033C 10 MQRC-ALIAS-TARGTYPE-CHANGED PIC S9(9) BINARY VALUE 2480. 002034C 10 MQRC-DMPO-ERROR PIC S9(9) BINARY VALUE 2481. 002035C 10 MQRC-PD-ERROR PIC S9(9) BINARY VALUE 2482. 002036C 10 MQRC-CALLBACK-TYPE-ERROR PIC S9(9) BINARY VALUE 2483. 002037C 10 MQRC-CBD-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2484. 002038C 10 MQRC-MAX-MSG-LENGTH-ERROR PIC S9(9) BINARY VALUE 2485. 002039C 10 MQRC-CALLBACK-ROUTINE-ERROR PIC S9(9) BINARY VALUE 2486. 002040C 10 MQRC-CALLBACK-LINK-ERROR PIC S9(9) BINARY VALUE 2487. 002041C 10 MQRC-OPERATION-ERROR PIC S9(9) BINARY VALUE 2488. 002042C 10 MQRC-BMHO-ERROR PIC S9(9) BINARY VALUE 2489. 002043C 10 MQRC-UNSUPPORTED-PROPERTY PIC S9(9) BINARY VALUE 2490. 002044C 10 MQRC-MSG-LENGTH-ERROR PIC S9(9) BINARY VALUE 2491. 002045C 10 MQRC-PROP-NAME-NOT-CONVERTED PIC S9(9) BINARY VALUE 2492. 002046C 10 MQRC-GET-ENABLED PIC S9(9) BINARY VALUE 2494. 002047C 10 MQRC-MODULE-NOT-FOUND PIC S9(9) BINARY VALUE 2495. 002048C 10 MQRC-MODULE-INVALID PIC S9(9) BINARY VALUE 2496. 002049C 10 MQRC-MODULE-ENTRY-NOT-FOUND PIC S9(9) BINARY VALUE 2497. 002050C 10 MQRC-MIXED-CONTENT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2498. 002051C 10 MQRC-MSG-HANDLE-IN-USE PIC S9(9) BINARY VALUE 2499. 002052C 10 MQRC-HCONN-ASYNC-ACTIVE PIC S9(9) BINARY VALUE 2500. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 40 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002053C 10 MQRC-MHBO-ERROR PIC S9(9) BINARY VALUE 2501. 002054C 10 MQRC-PUBLICATION-FAILURE PIC S9(9) BINARY VALUE 2502. 002055C 10 MQRC-SUB-INHIBITED PIC S9(9) BINARY VALUE 2503. 002056C 10 MQRC-SELECTOR-ALWAYS-FALSE PIC S9(9) BINARY VALUE 2504. 002057C 10 MQRC-XEPO-ERROR PIC S9(9) BINARY VALUE 2507. 002058C 10 MQRC-DURABILITY-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2509. 002059C 10 MQRC-TOPIC-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2510. 002060C 10 MQRC-SUBLEVEL-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2512. 002061C 10 MQRC-PROPERTY-NAME-LENGTH-ERR PIC S9(9) BINARY VALUE 2513. 002062C 10 MQRC-DUPLICATE-GROUP-SUB PIC S9(9) BINARY VALUE 2514. 002063C 10 MQRC-GROUPING-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2515. 002064C 10 MQRC-SELECTOR-INVALID-FOR-TYPE PIC S9(9) BINARY VALUE 2516. 002065C 10 MQRC-HOBJ-QUIESCED PIC S9(9) BINARY VALUE 2517. 002066C 10 MQRC-HOBJ-QUIESCED-NO-MSGS PIC S9(9) BINARY VALUE 2518. 002067C 10 MQRC-SELECTION-STRING-ERROR PIC S9(9) BINARY VALUE 2519. 002068C 10 MQRC-RES-OBJECT-STRING-ERROR PIC S9(9) BINARY VALUE 2520. 002069C 10 MQRC-CONNECTION-SUSPENDED PIC S9(9) BINARY VALUE 2521. 002070C 10 MQRC-INVALID-DESTINATION PIC S9(9) BINARY VALUE 2522. 002071C 10 MQRC-INVALID-SUBSCRIPTION PIC S9(9) BINARY VALUE 2523. 002072C 10 MQRC-SELECTOR-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2524. 002073C 10 MQRC-RETAINED-MSG-Q-ERROR PIC S9(9) BINARY VALUE 2525. 002074C 10 MQRC-RETAINED-NOT-DELIVERED PIC S9(9) BINARY VALUE 2526. 002075C 10 MQRC-RFH-RESTRICTED-FORMAT-ERR PIC S9(9) BINARY VALUE 2527. 002076C 10 MQRC-CONNECTION-STOPPED PIC S9(9) BINARY VALUE 2528. 002077C 10 MQRC-ASYNC-UOW-CONFLICT PIC S9(9) BINARY VALUE 2529. 002078C 10 MQRC-ASYNC-XA-CONFLICT PIC S9(9) BINARY VALUE 2530. 002079C 10 MQRC-PUBSUB-INHIBITED PIC S9(9) BINARY VALUE 2531. 002080C 10 MQRC-MSG-HANDLE-COPY-FAILURE PIC S9(9) BINARY VALUE 2532. 002081C 10 MQRC-DEST-CLASS-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2533. 002082C 10 MQRC-OPERATION-NOT-ALLOWED PIC S9(9) BINARY VALUE 2534. 002083C 10 MQRC-ACTION-ERROR PIC S9(9) BINARY VALUE 2535. 002084C 10 MQRC-CHANNEL-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2537. 002085C 10 MQRC-HOST-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2538. 002086C 10 MQRC-CHANNEL-CONFIG-ERROR PIC S9(9) BINARY VALUE 2539. 002087C 10 MQRC-UNKNOWN-CHANNEL-NAME PIC S9(9) BINARY VALUE 2540. 002088C 10 MQRC-LOOPING-PUBLICATION PIC S9(9) BINARY VALUE 2541. 002089C 10 MQRC-ALREADY-JOINED PIC S9(9) BINARY VALUE 2542. 002090C 10 MQRC-STANDBY-Q-MGR PIC S9(9) BINARY VALUE 2543. 002091C 10 MQRC-RECONNECTING PIC S9(9) BINARY VALUE 2544. 002092C 10 MQRC-RECONNECTED PIC S9(9) BINARY VALUE 2545. 002093C 10 MQRC-RECONNECT-QMID-MISMATCH PIC S9(9) BINARY VALUE 2546. 002094C 10 MQRC-RECONNECT-INCOMPATIBLE PIC S9(9) BINARY VALUE 2547. 002095C 10 MQRC-RECONNECT-FAILED PIC S9(9) BINARY VALUE 2548. 002096C 10 MQRC-CALL-INTERRUPTED PIC S9(9) BINARY VALUE 2549. 002097C 10 MQRC-NO-SUBS-MATCHED PIC S9(9) BINARY VALUE 2550. 002098C 10 MQRC-SELECTION-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2551. 002099C 10 MQRC-CHANNEL-SSL-WARNING PIC S9(9) BINARY VALUE 2552. 002100C 10 MQRC-OCSP-URL-ERROR PIC S9(9) BINARY VALUE 2553. 002101C 10 MQRC-CONTENT-ERROR PIC S9(9) BINARY VALUE 2554. 002102C 10 MQRC-RECONNECT-Q-MGR-REQD PIC S9(9) BINARY VALUE 2555. 002103C 10 MQRC-RECONNECT-TIMED-OUT PIC S9(9) BINARY VALUE 2556. 002104C 10 MQRC-PUBLISH-EXIT-ERROR PIC S9(9) BINARY VALUE 2557. 002105C 10 MQRC-COMMINFO-ERROR PIC S9(9) BINARY VALUE 2558. 002106C 10 MQRC-DEF-SYNCPOINT-INHIBITED PIC S9(9) BINARY VALUE 2559. 002107C 10 MQRC-MULTICAST-ONLY PIC S9(9) BINARY VALUE 2560. 002108C 10 MQRC-DATA-SET-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2561. 002109C 10 MQRC-GROUPING-NOT-ALLOWED PIC S9(9) BINARY VALUE 2562. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 41 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002110C 10 MQRC-GROUP-ADDRESS-ERROR PIC S9(9) BINARY VALUE 2563. 002111C 10 MQRC-MULTICAST-CONFIG-ERROR PIC S9(9) BINARY VALUE 2564. 002112C 10 MQRC-MULTICAST-INTERFACE-ERROR PIC S9(9) BINARY VALUE 2565. 002113C 10 MQRC-MULTICAST-SEND-ERROR PIC S9(9) BINARY VALUE 2566. 002114C 10 MQRC-MULTICAST-INTERNAL-ERROR PIC S9(9) BINARY VALUE 2567. 002115C 10 MQRC-CONNECTION-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2568. 002116C 10 MQRC-SYNCPOINT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2569. 002117C 10 MQRC-SSL-ALT-PROVIDER-REQUIRED PIC S9(9) BINARY VALUE 2570. 002118C 10 MQRC-MCAST-PUB-STATUS PIC S9(9) BINARY VALUE 2571. 002119C 10 MQRC-MCAST-SUB-STATUS PIC S9(9) BINARY VALUE 2572. 002120C 10 MQRC-PRECONN-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2573. 002121C 10 MQRC-PRECONN-EXIT-NOT-FOUND PIC S9(9) BINARY VALUE 2574. 002122C 10 MQRC-PRECONN-EXIT-ERROR PIC S9(9) BINARY VALUE 2575. 002123C 10 MQRC-CD-ARRAY-ERROR PIC S9(9) BINARY VALUE 2576. 002124C 10 MQRC-CHANNEL-BLOCKED PIC S9(9) BINARY VALUE 2577. 002125C 10 MQRC-CHANNEL-BLOCKED-WARNING PIC S9(9) BINARY VALUE 2578. 002126C 10 MQRC-SUBSCRIPTION-CREATE PIC S9(9) BINARY VALUE 2579. 002127C 10 MQRC-SUBSCRIPTION-DELETE PIC S9(9) BINARY VALUE 2580. 002128C 10 MQRC-SUBSCRIPTION-CHANGE PIC S9(9) BINARY VALUE 2581. 002129C 10 MQRC-SUBSCRIPTION-REFRESH PIC S9(9) BINARY VALUE 2582. 002130C 10 MQRC-INSTALLATION-MISMATCH PIC S9(9) BINARY VALUE 2583. 002131C 10 MQRC-NOT-PRIVILEGED PIC S9(9) BINARY VALUE 2584. 002132C 10 MQRC-PROPERTIES-DISABLED PIC S9(9) BINARY VALUE 2586. 002133C 10 MQRC-HMSG-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2587. 002134C 10 MQRC-EXIT-PROPS-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2588. 002135C 10 MQRC-INSTALLATION-MISSING PIC S9(9) BINARY VALUE 2589. 002136C 10 MQRC-FASTPATH-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2590. 002137C 10 MQRC-CIPHER-SPEC-NOT-SUITE-B PIC S9(9) BINARY VALUE 2591. 002138C 10 MQRC-SUITE-B-ERROR PIC S9(9) BINARY VALUE 2592. 002139C 10 MQRC-CERT-VAL-POLICY-ERROR PIC S9(9) BINARY VALUE 2593. 002140C 10 MQRC-PASSWORD-PROTECTION-ERROR PIC S9(9) BINARY VALUE 2594. 002141C 10 MQRC-CSP-ERROR PIC S9(9) BINARY VALUE 2595. 002142C 10 MQRC-CERT-LABEL-NOT-ALLOWED PIC S9(9) BINARY VALUE 2596. 002143C 10 MQRC-ADMIN-TOPIC-STRING-ERROR PIC S9(9) BINARY VALUE 2598. 002144C 10 MQRC-AMQP-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2599. 002145C 10 MQRC-CCDT-URL-ERROR PIC S9(9) BINARY VALUE 2600. 002146C 10 MQRC-Q-MGR-RECONNECT-REQUESTED PIC S9(9) BINARY VALUE 2601. 002147C 10 MQRC-BNO-ERROR PIC S9(9) BINARY VALUE 2602. 002148C 10 MQRC-OUTBOUND-SNI-NOT-VALID PIC S9(9) BINARY VALUE 2603. 002149C 10 MQRC-HTTPS-KEYSTORE-ERROR PIC S9(9) BINARY VALUE 2604. 002150C 10 MQRC-REOPEN-EXCL-INPUT-ERROR PIC S9(9) BINARY VALUE 6100. 002151C 10 MQRC-REOPEN-INQUIRE-ERROR PIC S9(9) BINARY VALUE 6101. 002152C 10 MQRC-REOPEN-SAVED-CONTEXT-ERR PIC S9(9) BINARY VALUE 6102. 002153C 10 MQRC-REOPEN-TEMPORARY-Q-ERROR PIC S9(9) BINARY VALUE 6103. 002154C 10 MQRC-ATTRIBUTE-LOCKED PIC S9(9) BINARY VALUE 6104. 002155C 10 MQRC-CURSOR-NOT-VALID PIC S9(9) BINARY VALUE 6105. 002156C 10 MQRC-ENCODING-ERROR PIC S9(9) BINARY VALUE 6106. 002157C 10 MQRC-STRUC-ID-ERROR PIC S9(9) BINARY VALUE 6107. 002158C 10 MQRC-NULL-POINTER PIC S9(9) BINARY VALUE 6108. 002159C 10 MQRC-NO-CONNECTION-REFERENCE PIC S9(9) BINARY VALUE 6109. 002160C 10 MQRC-NO-BUFFER PIC S9(9) BINARY VALUE 6110. 002161C 10 MQRC-BINARY-DATA-LENGTH-ERROR PIC S9(9) BINARY VALUE 6111. 002162C 10 MQRC-BUFFER-NOT-AUTOMATIC PIC S9(9) BINARY VALUE 6112. 002163C 10 MQRC-INSUFFICIENT-BUFFER PIC S9(9) BINARY VALUE 6113. 002164C 10 MQRC-INSUFFICIENT-DATA PIC S9(9) BINARY VALUE 6114. 002165C 10 MQRC-DATA-TRUNCATED PIC S9(9) BINARY VALUE 6115. 002166C 10 MQRC-ZERO-LENGTH PIC S9(9) BINARY VALUE 6116. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 42 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002167C 10 MQRC-NEGATIVE-LENGTH PIC S9(9) BINARY VALUE 6117. 002168C 10 MQRC-NEGATIVE-OFFSET PIC S9(9) BINARY VALUE 6118. 002169C 10 MQRC-INCONSISTENT-FORMAT PIC S9(9) BINARY VALUE 6119. 002170C 10 MQRC-INCONSISTENT-OBJECT-STATE PIC S9(9) BINARY VALUE 6120. 002171C 10 MQRC-CONTEXT-OBJECT-NOT-VALID PIC S9(9) BINARY VALUE 6121. 002172C 10 MQRC-CONTEXT-OPEN-ERROR PIC S9(9) BINARY VALUE 6122. 002173C 10 MQRC-STRUC-LENGTH-ERROR PIC S9(9) BINARY VALUE 6123. 002174C 10 MQRC-NOT-CONNECTED PIC S9(9) BINARY VALUE 6124. 002175C 10 MQRC-NOT-OPEN PIC S9(9) BINARY VALUE 6125. 002176C 10 MQRC-DISTRIBUTION-LIST-EMPTY PIC S9(9) BINARY VALUE 6126. 002177C 10 MQRC-INCONSISTENT-OPEN-OPTIONS PIC S9(9) BINARY VALUE 6127. 002178C 10 MQRC-WRONG-VERSION PIC S9(9) BINARY VALUE 6128. 002179C 10 MQRC-REFERENCE-ERROR PIC S9(9) BINARY VALUE 6129. 002180C 10 MQRC-XR-NOT-AVAILABLE PIC S9(9) BINARY VALUE 6130. 002181C 10 MQRC-SUB-JOIN-NOT-ALTERABLE PIC S9(9) BINARY VALUE 29440. 002182C 002183C ****************************************************************** 002184C ** Values Related to Queue Attributes 002185C ****************************************************************** 002186C ** Queue Types 002187C 10 MQQT-LOCAL PIC S9(9) BINARY VALUE 1. 002188C 10 MQQT-MODEL PIC S9(9) BINARY VALUE 2. 002189C 10 MQQT-ALIAS PIC S9(9) BINARY VALUE 3. 002190C 10 MQQT-REMOTE PIC S9(9) BINARY VALUE 6. 002191C 10 MQQT-CLUSTER PIC S9(9) BINARY VALUE 7. 002192C 002193C ** Cluster Queue Types 002194C 10 MQCQT-LOCAL-Q PIC S9(9) BINARY VALUE 1. 002195C 10 MQCQT-ALIAS-Q PIC S9(9) BINARY VALUE 2. 002196C 10 MQCQT-REMOTE-Q PIC S9(9) BINARY VALUE 3. 002197C 10 MQCQT-Q-MGR-ALIAS PIC S9(9) BINARY VALUE 4. 002198C 002199C ** Extended Queue Types 002200C 10 MQQT-ALL PIC S9(9) BINARY VALUE 1001. 002201C 002202C ** Queue Definition Types 002203C 10 MQQDT-PREDEFINED PIC S9(9) BINARY VALUE 1. 002204C 10 MQQDT-PERMANENT-DYNAMIC PIC S9(9) BINARY VALUE 2. 002205C 10 MQQDT-TEMPORARY-DYNAMIC PIC S9(9) BINARY VALUE 3. 002206C 10 MQQDT-SHARED-DYNAMIC PIC S9(9) BINARY VALUE 4. 002207C 002208C ** Inhibit Get Values 002209C 10 MQQA-GET-INHIBITED PIC S9(9) BINARY VALUE 1. 002210C 10 MQQA-GET-ALLOWED PIC S9(9) BINARY VALUE 0. 002211C 002212C ** Inhibit Put Values 002213C 10 MQQA-PUT-INHIBITED PIC S9(9) BINARY VALUE 1. 002214C 10 MQQA-PUT-ALLOWED PIC S9(9) BINARY VALUE 0. 002215C 002216C ** Queue Shareability 002217C 10 MQQA-SHAREABLE PIC S9(9) BINARY VALUE 1. 002218C 10 MQQA-NOT-SHAREABLE PIC S9(9) BINARY VALUE 0. 002219C 002220C ** Back-Out Hardening 002221C 10 MQQA-BACKOUT-HARDENED PIC S9(9) BINARY VALUE 1. 002222C 10 MQQA-BACKOUT-NOT-HARDENED PIC S9(9) BINARY VALUE 0. 002223C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 43 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002224C ** Message Delivery Sequence 002225C 10 MQMDS-PRIORITY PIC S9(9) BINARY VALUE 0. 002226C 10 MQMDS-FIFO PIC S9(9) BINARY VALUE 1. 002227C 002228C ** Nonpersistent Message Class 002229C 10 MQNPM-CLASS-NORMAL PIC S9(9) BINARY VALUE 0. 002230C 10 MQNPM-CLASS-HIGH PIC S9(9) BINARY VALUE 10. 002231C 002232C ** Trigger Controls 002233C 10 MQTC-OFF PIC S9(9) BINARY VALUE 0. 002234C 10 MQTC-ON PIC S9(9) BINARY VALUE 1. 002235C 002236C ** Trigger Types 002237C 10 MQTT-NONE PIC S9(9) BINARY VALUE 0. 002238C 10 MQTT-FIRST PIC S9(9) BINARY VALUE 1. 002239C 10 MQTT-EVERY PIC S9(9) BINARY VALUE 2. 002240C 10 MQTT-DEPTH PIC S9(9) BINARY VALUE 3. 002241C 002242C ** Trigger Restart 002243C 10 MQTRIGGER-RESTART-NO PIC S9(9) BINARY VALUE 0. 002244C 10 MQTRIGGER-RESTART-YES PIC S9(9) BINARY VALUE 1. 002245C 002246C ** Queue Usages 002247C 10 MQUS-NORMAL PIC S9(9) BINARY VALUE 0. 002248C 10 MQUS-TRANSMISSION PIC S9(9) BINARY VALUE 1. 002249C 002250C ** Distribution Lists 002251C 10 MQDL-SUPPORTED PIC S9(9) BINARY VALUE 1. 002252C 10 MQDL-NOT-SUPPORTED PIC S9(9) BINARY VALUE 0. 002253C 002254C ** Index Types 002255C 10 MQIT-NONE PIC S9(9) BINARY VALUE 0. 002256C 10 MQIT-MSG-ID PIC S9(9) BINARY VALUE 1. 002257C 10 MQIT-CORREL-ID PIC S9(9) BINARY VALUE 2. 002258C 10 MQIT-MSG-TOKEN PIC S9(9) BINARY VALUE 4. 002259C 10 MQIT-GROUP-ID PIC S9(9) BINARY VALUE 5. 002260C 002261C ** Default Bindings 002262C 10 MQBND-BIND-ON-OPEN PIC S9(9) BINARY VALUE 0. 002263C 10 MQBND-BIND-NOT-FIXED PIC S9(9) BINARY VALUE 1. 002264C 10 MQBND-BIND-ON-GROUP PIC S9(9) BINARY VALUE 2. 002265C 002266C ** Queue Sharing Group Dispositions 002267C 10 MQQSGD-ALL PIC S9(9) BINARY VALUE -1. 002268C 10 MQQSGD-Q-MGR PIC S9(9) BINARY VALUE 0. 002269C 10 MQQSGD-COPY PIC S9(9) BINARY VALUE 1. 002270C 10 MQQSGD-SHARED PIC S9(9) BINARY VALUE 2. 002271C 10 MQQSGD-GROUP PIC S9(9) BINARY VALUE 3. 002272C 10 MQQSGD-PRIVATE PIC S9(9) BINARY VALUE 4. 002273C 10 MQQSGD-LIVE PIC S9(9) BINARY VALUE 6. 002274C 002275C ** Reorganization Controls 002276C 10 MQREORG-DISABLED PIC S9(9) BINARY VALUE 0. 002277C 10 MQREORG-ENABLED PIC S9(9) BINARY VALUE 1. 002278C 002279C ** Max queue file size values 002280C 10 MQQFS-DEFAULT PIC S9(9) BINARY VALUE -1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 44 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002281C 002282C ** Queue cap expiry values 002283C 10 MQCEX-NOLIMIT PIC S9(9) BINARY VALUE -1. 002284C 10 MQCEX-AS-PARENT PIC S9(9) BINARY VALUE -2. 002285C 002286C ** OTELTRAC values 002287C 10 MQOTEL-TRACE-QMGR PIC S9(9) BINARY VALUE 0. 002288C 10 MQOTEL-TRACE-OFF PIC S9(9) BINARY VALUE 1. 002289C 10 MQOTEL-TRACE-ON PIC S9(9) BINARY VALUE 2. 002290C 10 MQOTEL-TRACE-NONE PIC S9(9) BINARY VALUE 3. 002291C 10 MQOTEL-TRACE-AS-PARENT PIC S9(9) BINARY VALUE 4. 002292C 002293C ** OTELPCTL values 002294C 10 MQOTEL-PCTL-QMGR PIC S9(9) BINARY VALUE 0. 002295C 10 MQOTEL-PCTL-MANUAL PIC S9(9) BINARY VALUE 1. 002296C 10 MQOTEL-PCTL-AUTO PIC S9(9) BINARY VALUE 2. 002297C 10 MQOTEL-PCTL-AS-PARENT PIC S9(9) BINARY VALUE 3. 002298C 002299C ** Read Ahead Values 002300C 10 MQREADA-NO PIC S9(9) BINARY VALUE 0. 002301C 10 MQREADA-YES PIC S9(9) BINARY VALUE 1. 002302C 10 MQREADA-DISABLED PIC S9(9) BINARY VALUE 2. 002303C 10 MQREADA-INHIBITED PIC S9(9) BINARY VALUE 3. 002304C 10 MQREADA-BACKLOG PIC S9(9) BINARY VALUE 4. 002305C 002306C ** Queue and Channel Property Control Values 002307C 10 MQPROP-COMPATIBILITY PIC S9(9) BINARY VALUE 0. 002308C 10 MQPROP-NONE PIC S9(9) BINARY VALUE 1. 002309C 10 MQPROP-ALL PIC S9(9) BINARY VALUE 2. 002310C 10 MQPROP-FORCE-MQRFH2 PIC S9(9) BINARY VALUE 3. 002311C 10 MQPROP-V6COMPAT PIC S9(9) BINARY VALUE 4. 002312C 002313C ** Streaming Queue Quality of Service Values 002314C 10 MQST-BEST-EFFORT PIC S9(9) BINARY VALUE 0. 002315C 10 MQST-MUST-DUP PIC S9(9) BINARY VALUE 1. 002316C 002317C ****************************************************************** 002318C ** Values Related to Namelist Attributes 002319C ****************************************************************** 002320C ** Name Count 002321C 10 MQNC-MAX-NAMELIST-NAME-COUNT PIC S9(9) BINARY VALUE 256. 002322C 002323C ** Namelist Types 002324C 10 MQNT-NONE PIC S9(9) BINARY VALUE 0. 002325C 10 MQNT-Q PIC S9(9) BINARY VALUE 1. 002326C 10 MQNT-CLUSTER PIC S9(9) BINARY VALUE 2. 002327C 10 MQNT-AUTH-INFO PIC S9(9) BINARY VALUE 4. 002328C 10 MQNT-ALL PIC S9(9) BINARY VALUE 1001. 002329C 002330C ****************************************************************** 002331C ** Values Related to CF-Structure Attributes 002332C ****************************************************************** 002333C ** CF Recoverability 002334C 10 MQCFR-YES PIC S9(9) BINARY VALUE 1. 002335C 10 MQCFR-NO PIC S9(9) BINARY VALUE 0. 002336C 002337C ** CF Automatic Recovery 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 45 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002338C 10 MQRECAUTO-NO PIC S9(9) BINARY VALUE 0. 002339C 10 MQRECAUTO-YES PIC S9(9) BINARY VALUE 1. 002340C 002341C ** CF Loss of Connectivity Action 002342C 10 MQCFCONLOS-TERMINATE PIC S9(9) BINARY VALUE 0. 002343C 10 MQCFCONLOS-TOLERATE PIC S9(9) BINARY VALUE 1. 002344C 10 MQCFCONLOS-ASQMGR PIC S9(9) BINARY VALUE 2. 002345C 002346C ****************************************************************** 002347C ** Values Related to Service Attributes 002348C ****************************************************************** 002349C ** Service Types 002350C 10 MQSVC-TYPE-COMMAND PIC S9(9) BINARY VALUE 0. 002351C 10 MQSVC-TYPE-SERVER PIC S9(9) BINARY VALUE 1. 002352C 002353C ****************************************************************** 002354C ** Values Related to QueueManager Attributes 002355C ****************************************************************** 002356C ** Adopt New MCA Checks 002357C 10 MQADOPT-CHECK-NONE PIC S9(9) BINARY VALUE 0. 002358C 10 MQADOPT-CHECK-ALL PIC S9(9) BINARY VALUE 1. 002359C 10 MQADOPT-CHECK-Q-MGR-NAME PIC S9(9) BINARY VALUE 2. 002360C 10 MQADOPT-CHECK-NET-ADDR PIC S9(9) BINARY VALUE 4. 002361C 10 MQADOPT-CHECK-CHANNEL-NAME PIC S9(9) BINARY VALUE 8. 002362C 002363C ** Adopt New MCA Types 002364C 10 MQADOPT-TYPE-NO PIC S9(9) BINARY VALUE 0. 002365C 10 MQADOPT-TYPE-ALL PIC S9(9) BINARY VALUE 1. 002366C 10 MQADOPT-TYPE-SVR PIC S9(9) BINARY VALUE 2. 002367C 10 MQADOPT-TYPE-SDR PIC S9(9) BINARY VALUE 4. 002368C 10 MQADOPT-TYPE-RCVR PIC S9(9) BINARY VALUE 8. 002369C 10 MQADOPT-TYPE-CLUSRCVR PIC S9(9) BINARY VALUE 16. 002370C 002371C ** Autostart 002372C 10 MQAUTO-START-NO PIC S9(9) BINARY VALUE 0. 002373C 10 MQAUTO-START-YES PIC S9(9) BINARY VALUE 1. 002374C 002375C ** Channel Auto Definition 002376C 10 MQCHAD-DISABLED PIC S9(9) BINARY VALUE 0. 002377C 10 MQCHAD-ENABLED PIC S9(9) BINARY VALUE 1. 002378C 002379C ** Cluster Workload 002380C 10 MQCLWL-USEQ-LOCAL PIC S9(9) BINARY VALUE 0. 002381C 10 MQCLWL-USEQ-ANY PIC S9(9) BINARY VALUE 1. 002382C 10 MQCLWL-USEQ-AS-Q-MGR PIC S9(9) BINARY VALUE -3. 002383C 002384C ** Command Levels 002385C 10 MQCMDL-LEVEL-1 PIC S9(9) BINARY VALUE 100. 002386C 10 MQCMDL-LEVEL-101 PIC S9(9) BINARY VALUE 101. 002387C 10 MQCMDL-LEVEL-110 PIC S9(9) BINARY VALUE 110. 002388C 10 MQCMDL-LEVEL-114 PIC S9(9) BINARY VALUE 114. 002389C 10 MQCMDL-LEVEL-120 PIC S9(9) BINARY VALUE 120. 002390C 10 MQCMDL-LEVEL-200 PIC S9(9) BINARY VALUE 200. 002391C 10 MQCMDL-LEVEL-201 PIC S9(9) BINARY VALUE 201. 002392C 10 MQCMDL-LEVEL-210 PIC S9(9) BINARY VALUE 210. 002393C 10 MQCMDL-LEVEL-211 PIC S9(9) BINARY VALUE 211. 002394C 10 MQCMDL-LEVEL-220 PIC S9(9) BINARY VALUE 220. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 46 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002395C 10 MQCMDL-LEVEL-221 PIC S9(9) BINARY VALUE 221. 002396C 10 MQCMDL-LEVEL-230 PIC S9(9) BINARY VALUE 230. 002397C 10 MQCMDL-LEVEL-320 PIC S9(9) BINARY VALUE 320. 002398C 10 MQCMDL-LEVEL-420 PIC S9(9) BINARY VALUE 420. 002399C 10 MQCMDL-LEVEL-500 PIC S9(9) BINARY VALUE 500. 002400C 10 MQCMDL-LEVEL-510 PIC S9(9) BINARY VALUE 510. 002401C 10 MQCMDL-LEVEL-520 PIC S9(9) BINARY VALUE 520. 002402C 10 MQCMDL-LEVEL-530 PIC S9(9) BINARY VALUE 530. 002403C 10 MQCMDL-LEVEL-531 PIC S9(9) BINARY VALUE 531. 002404C 10 MQCMDL-LEVEL-600 PIC S9(9) BINARY VALUE 600. 002405C 10 MQCMDL-LEVEL-700 PIC S9(9) BINARY VALUE 700. 002406C 10 MQCMDL-LEVEL-701 PIC S9(9) BINARY VALUE 701. 002407C 10 MQCMDL-LEVEL-710 PIC S9(9) BINARY VALUE 710. 002408C 10 MQCMDL-LEVEL-711 PIC S9(9) BINARY VALUE 711. 002409C 10 MQCMDL-LEVEL-750 PIC S9(9) BINARY VALUE 750. 002410C 10 MQCMDL-LEVEL-800 PIC S9(9) BINARY VALUE 800. 002411C 10 MQCMDL-LEVEL-801 PIC S9(9) BINARY VALUE 801. 002412C 10 MQCMDL-LEVEL-802 PIC S9(9) BINARY VALUE 802. 002413C 10 MQCMDL-LEVEL-900 PIC S9(9) BINARY VALUE 900. 002414C 10 MQCMDL-LEVEL-901 PIC S9(9) BINARY VALUE 901. 002415C 10 MQCMDL-LEVEL-902 PIC S9(9) BINARY VALUE 902. 002416C 10 MQCMDL-LEVEL-903 PIC S9(9) BINARY VALUE 903. 002417C 10 MQCMDL-LEVEL-904 PIC S9(9) BINARY VALUE 904. 002418C 10 MQCMDL-LEVEL-905 PIC S9(9) BINARY VALUE 905. 002419C 10 MQCMDL-LEVEL-910 PIC S9(9) BINARY VALUE 910. 002420C 10 MQCMDL-LEVEL-911 PIC S9(9) BINARY VALUE 911. 002421C 10 MQCMDL-LEVEL-912 PIC S9(9) BINARY VALUE 912. 002422C 10 MQCMDL-LEVEL-913 PIC S9(9) BINARY VALUE 913. 002423C 10 MQCMDL-LEVEL-914 PIC S9(9) BINARY VALUE 914. 002424C 10 MQCMDL-LEVEL-915 PIC S9(9) BINARY VALUE 915. 002425C 10 MQCMDL-LEVEL-920 PIC S9(9) BINARY VALUE 920. 002426C 10 MQCMDL-LEVEL-921 PIC S9(9) BINARY VALUE 921. 002427C 10 MQCMDL-LEVEL-922 PIC S9(9) BINARY VALUE 922. 002428C 10 MQCMDL-LEVEL-923 PIC S9(9) BINARY VALUE 923. 002429C 10 MQCMDL-LEVEL-924 PIC S9(9) BINARY VALUE 924. 002430C 10 MQCMDL-LEVEL-925 PIC S9(9) BINARY VALUE 925. 002431C 10 MQCMDL-LEVEL-930 PIC S9(9) BINARY VALUE 930. 002432C 10 MQCMDL-LEVEL-931 PIC S9(9) BINARY VALUE 931. 002433C 10 MQCMDL-LEVEL-932 PIC S9(9) BINARY VALUE 932. 002434C 10 MQCMDL-LEVEL-933 PIC S9(9) BINARY VALUE 933. 002435C 10 MQCMDL-LEVEL-934 PIC S9(9) BINARY VALUE 934. 002436C 10 MQCMDL-LEVEL-935 PIC S9(9) BINARY VALUE 935. 002437C 10 MQCMDL-LEVEL-940 PIC S9(9) BINARY VALUE 940. 002438C 10 MQCMDL-LEVEL-941 PIC S9(9) BINARY VALUE 941. 002439C 10 MQCMDL-LEVEL-942 PIC S9(9) BINARY VALUE 942. 002440C 10 MQCMDL-LEVEL-943 PIC S9(9) BINARY VALUE 943. 002441C 10 MQCMDL-LEVEL-944 PIC S9(9) BINARY VALUE 944. 002442C 10 MQCMDL-LEVEL-945 PIC S9(9) BINARY VALUE 945. 002443C 10 MQCMDL-CURRENT-LEVEL PIC S9(9) BINARY VALUE 945. 002444C 002445C ** Command Server Options 002446C 10 MQCSRV-CONVERT-NO PIC S9(9) BINARY VALUE 0. 002447C 10 MQCSRV-CONVERT-YES PIC S9(9) BINARY VALUE 1. 002448C 10 MQCSRV-DLQ-NO PIC S9(9) BINARY VALUE 0. 002449C 10 MQCSRV-DLQ-YES PIC S9(9) BINARY VALUE 1. 002450C 002451C ** DNS WLM 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 47 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002452C 10 MQDNSWLM-NO PIC S9(9) BINARY VALUE 0. 002453C 10 MQDNSWLM-YES PIC S9(9) BINARY VALUE 1. 002454C 002455C ** Expiration Scan Interval 002456C 10 MQEXPI-OFF PIC S9(9) BINARY VALUE 0. 002457C 002458C ** Intra-Group Queuing 002459C 10 MQIGQ-DISABLED PIC S9(9) BINARY VALUE 0. 002460C 10 MQIGQ-ENABLED PIC S9(9) BINARY VALUE 1. 002461C 002462C ** Intra-Group Queuing Put Authority 002463C 10 MQIGQPA-DEFAULT PIC S9(9) BINARY VALUE 1. 002464C 10 MQIGQPA-CONTEXT PIC S9(9) BINARY VALUE 2. 002465C 10 MQIGQPA-ONLY-IGQ PIC S9(9) BINARY VALUE 3. 002466C 10 MQIGQPA-ALTERNATE-OR-IGQ PIC S9(9) BINARY VALUE 4. 002467C 002468C ** IP Address Versions 002469C 10 MQIPADDR-IPV4 PIC S9(9) BINARY VALUE 0. 002470C 10 MQIPADDR-IPV6 PIC S9(9) BINARY VALUE 1. 002471C 002472C ** Message Mark-Browse Interval 002473C 10 MQMMBI-UNLIMITED PIC S9(9) BINARY VALUE -1. 002474C 002475C ** Monitoring Values 002476C 10 MQMON-NOT-AVAILABLE PIC S9(9) BINARY VALUE -1. 002477C 10 MQMON-NONE PIC S9(9) BINARY VALUE -1. 002478C 10 MQMON-Q-MGR PIC S9(9) BINARY VALUE -3. 002479C 10 MQMON-OFF PIC S9(9) BINARY VALUE 0. 002480C 10 MQMON-ON PIC S9(9) BINARY VALUE 1. 002481C 10 MQMON-DISABLED PIC S9(9) BINARY VALUE 0. 002482C 10 MQMON-ENABLED PIC S9(9) BINARY VALUE 1. 002483C 10 MQMON-LOW PIC S9(9) BINARY VALUE 17. 002484C 10 MQMON-MEDIUM PIC S9(9) BINARY VALUE 33. 002485C 10 MQMON-HIGH PIC S9(9) BINARY VALUE 65. 002486C 002487C ** Application Function Types 002488C 10 MQFUN-TYPE-UNKNOWN PIC S9(9) BINARY VALUE 0. 002489C 10 MQFUN-TYPE-JVM PIC S9(9) BINARY VALUE 1. 002490C 10 MQFUN-TYPE-PROGRAM PIC S9(9) BINARY VALUE 2. 002491C 10 MQFUN-TYPE-PROCEDURE PIC S9(9) BINARY VALUE 3. 002492C 10 MQFUN-TYPE-USERDEF PIC S9(9) BINARY VALUE 4. 002493C 10 MQFUN-TYPE-COMMAND PIC S9(9) BINARY VALUE 5. 002494C 002495C ** Application Activity Trace Detail 002496C 10 MQACTV-DETAIL-LOW PIC S9(9) BINARY VALUE 1. 002497C 10 MQACTV-DETAIL-MEDIUM PIC S9(9) BINARY VALUE 2. 002498C 10 MQACTV-DETAIL-HIGH PIC S9(9) BINARY VALUE 3. 002499C 002500C ** Platforms 002501C 10 MQPL-MVS PIC S9(9) BINARY VALUE 1. 002502C 10 MQPL-OS390 PIC S9(9) BINARY VALUE 1. 002503C 10 MQPL-ZOS PIC S9(9) BINARY VALUE 1. 002504C 10 MQPL-OS2 PIC S9(9) BINARY VALUE 2. 002505C 10 MQPL-AIX PIC S9(9) BINARY VALUE 3. 002506C 10 MQPL-UNIX PIC S9(9) BINARY VALUE 3. 002507C 10 MQPL-OS400 PIC S9(9) BINARY VALUE 4. 002508C 10 MQPL-WINDOWS PIC S9(9) BINARY VALUE 5. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 48 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002509C 10 MQPL-WINDOWS-NT PIC S9(9) BINARY VALUE 11. 002510C 10 MQPL-VMS PIC S9(9) BINARY VALUE 12. 002511C 10 MQPL-NSK PIC S9(9) BINARY VALUE 13. 002512C 10 MQPL-NSS PIC S9(9) BINARY VALUE 13. 002513C 10 MQPL-OPEN-TP1 PIC S9(9) BINARY VALUE 15. 002514C 10 MQPL-VM PIC S9(9) BINARY VALUE 18. 002515C 10 MQPL-TPF PIC S9(9) BINARY VALUE 23. 002516C 10 MQPL-VSE PIC S9(9) BINARY VALUE 27. 002517C 10 MQPL-APPLIANCE PIC S9(9) BINARY VALUE 28. 002518C 002519C ** Maximum Properties Length 002520C 10 MQPROP-UNRESTRICTED-LENGTH PIC S9(9) BINARY VALUE -1. 002521C 002522C ** Pub/Sub Mode 002523C 10 MQPSM-DISABLED PIC S9(9) BINARY VALUE 0. 002524C 10 MQPSM-COMPAT PIC S9(9) BINARY VALUE 1. 002525C 10 MQPSM-ENABLED PIC S9(9) BINARY VALUE 2. 002526C 002527C ** Pub/Sub clusters 002528C 10 MQPSCLUS-DISABLED PIC S9(9) BINARY VALUE 0. 002529C 10 MQPSCLUS-ENABLED PIC S9(9) BINARY VALUE 1. 002530C 002531C ** Control Options 002532C 10 MQQMOPT-DISABLED PIC S9(9) BINARY VALUE 0. 002533C 10 MQQMOPT-ENABLED PIC S9(9) BINARY VALUE 1. 002534C 10 MQQMOPT-REPLY PIC S9(9) BINARY VALUE 2. 002535C 002536C ** Receive Timeout Types 002537C 10 MQRCVTIME-MULTIPLY PIC S9(9) BINARY VALUE 0. 002538C 10 MQRCVTIME-ADD PIC S9(9) BINARY VALUE 1. 002539C 10 MQRCVTIME-EQUAL PIC S9(9) BINARY VALUE 2. 002540C 002541C ** Recording Options 002542C 10 MQRECORDING-DISABLED PIC S9(9) BINARY VALUE 0. 002543C 10 MQRECORDING-Q PIC S9(9) BINARY VALUE 1. 002544C 10 MQRECORDING-MSG PIC S9(9) BINARY VALUE 2. 002545C 002546C ** Security Case 002547C 10 MQSCYC-UPPER PIC S9(9) BINARY VALUE 0. 002548C 10 MQSCYC-MIXED PIC S9(9) BINARY VALUE 1. 002549C 002550C ** Shared Queue Queue Manager Name 002551C 10 MQSQQM-USE PIC S9(9) BINARY VALUE 0. 002552C 10 MQSQQM-IGNORE PIC S9(9) BINARY VALUE 1. 002553C 002554C ** SSL FIPS Requirements 002555C 10 MQSSL-FIPS-NO PIC S9(9) BINARY VALUE 0. 002556C 10 MQSSL-FIPS-YES PIC S9(9) BINARY VALUE 1. 002557C 002558C ** Syncpoint Availability 002559C 10 MQSP-AVAILABLE PIC S9(9) BINARY VALUE 1. 002560C 10 MQSP-NOT-AVAILABLE PIC S9(9) BINARY VALUE 0. 002561C 002562C ** Service Controls 002563C 10 MQSVC-CONTROL-Q-MGR PIC S9(9) BINARY VALUE 0. 002564C 10 MQSVC-CONTROL-Q-MGR-START PIC S9(9) BINARY VALUE 1. 002565C 10 MQSVC-CONTROL-MANUAL PIC S9(9) BINARY VALUE 2. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 49 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002566C 002567C ** Service Status 002568C 10 MQSVC-STATUS-STOPPED PIC S9(9) BINARY VALUE 0. 002569C 10 MQSVC-STATUS-STARTING PIC S9(9) BINARY VALUE 1. 002570C 10 MQSVC-STATUS-RUNNING PIC S9(9) BINARY VALUE 2. 002571C 10 MQSVC-STATUS-STOPPING PIC S9(9) BINARY VALUE 3. 002572C 10 MQSVC-STATUS-RETRYING PIC S9(9) BINARY VALUE 4. 002573C 002574C ** TCP Keepalive 002575C 10 MQTCPKEEP-NO PIC S9(9) BINARY VALUE 0. 002576C 10 MQTCPKEEP-YES PIC S9(9) BINARY VALUE 1. 002577C 002578C ** TCP Stack Types 002579C 10 MQTCPSTACK-SINGLE PIC S9(9) BINARY VALUE 0. 002580C 10 MQTCPSTACK-MULTIPLE PIC S9(9) BINARY VALUE 1. 002581C 002582C ** Channel Initiator Trace Autostart 002583C 10 MQTRAXSTR-NO PIC S9(9) BINARY VALUE 0. 002584C 10 MQTRAXSTR-YES PIC S9(9) BINARY VALUE 1. 002585C 002586C ** Capability 002587C 10 MQCAP-NOT-SUPPORTED PIC S9(9) BINARY VALUE 0. 002588C 10 MQCAP-SUPPORTED PIC S9(9) BINARY VALUE 1. 002589C 10 MQCAP-EXPIRED PIC S9(9) BINARY VALUE 2. 002590C 002591C ** Media Image Scheduling 002592C 10 MQMEDIMGSCHED-MANUAL PIC S9(9) BINARY VALUE 0. 002593C 10 MQMEDIMGSCHED-AUTO PIC S9(9) BINARY VALUE 1. 002594C 002595C ** Automatic Media Image Interval 002596C 10 MQMEDIMGINTVL-OFF PIC S9(9) BINARY VALUE 0. 002597C 002598C ** Automatic Media Image Log Length 002599C 10 MQMEDIMGLOGLN-OFF PIC S9(9) BINARY VALUE 0. 002600C 002601C ** Media Image Recoverability 002602C 10 MQIMGRCOV-NO PIC S9(9) BINARY VALUE 0. 002603C 10 MQIMGRCOV-YES PIC S9(9) BINARY VALUE 1. 002604C 10 MQIMGRCOV-AS-Q-MGR PIC S9(9) BINARY VALUE 2. 002605C 002606C ****************************************************************** 002607C ** Values Related to Topic Attributes 002608C ****************************************************************** 002609C ** Persistent/Non-persistent Message Delivery 002610C 10 MQDLV-AS-PARENT PIC S9(9) BINARY VALUE 0. 002611C 10 MQDLV-ALL PIC S9(9) BINARY VALUE 1. 002612C 10 MQDLV-ALL-DUR PIC S9(9) BINARY VALUE 2. 002613C 10 MQDLV-ALL-AVAIL PIC S9(9) BINARY VALUE 3. 002614C 002615C ** Master administration 002616C 10 MQMASTER-NO PIC S9(9) BINARY VALUE 0. 002617C 10 MQMASTER-YES PIC S9(9) BINARY VALUE 1. 002618C 002619C ** Publish scope 002620C 10 MQSCOPE-ALL PIC S9(9) BINARY VALUE 0. 002621C 10 MQSCOPE-AS-PARENT PIC S9(9) BINARY VALUE 1. 002622C 10 MQSCOPE-QMGR PIC S9(9) BINARY VALUE 4. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 50 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002623C 002624C ** Durable subscriptions 002625C 10 MQSUB-DURABLE-AS-PARENT PIC S9(9) BINARY VALUE 0. 002626C 10 MQSUB-DURABLE-ALLOWED PIC S9(9) BINARY VALUE 1. 002627C 10 MQSUB-DURABLE-INHIBITED PIC S9(9) BINARY VALUE 2. 002628C 002629C ** Wildcards 002630C 10 MQTA-BLOCK PIC S9(9) BINARY VALUE 1. 002631C 10 MQTA-PASSTHRU PIC S9(9) BINARY VALUE 2. 002632C 002633C ** Subscriptions Allowed 002634C 10 MQTA-SUB-AS-PARENT PIC S9(9) BINARY VALUE 0. 002635C 10 MQTA-SUB-INHIBITED PIC S9(9) BINARY VALUE 1. 002636C 10 MQTA-SUB-ALLOWED PIC S9(9) BINARY VALUE 2. 002637C 002638C ** Proxy Sub Propagation 002639C 10 MQTA-PROXY-SUB-FORCE PIC S9(9) BINARY VALUE 1. 002640C 10 MQTA-PROXY-SUB-FIRSTUSE PIC S9(9) BINARY VALUE 2. 002641C 002642C ** Publications Allowed 002643C 10 MQTA-PUB-AS-PARENT PIC S9(9) BINARY VALUE 0. 002644C 10 MQTA-PUB-INHIBITED PIC S9(9) BINARY VALUE 1. 002645C 10 MQTA-PUB-ALLOWED PIC S9(9) BINARY VALUE 2. 002646C 002647C ** Topic Type 002648C 10 MQTOPT-LOCAL PIC S9(9) BINARY VALUE 0. 002649C 10 MQTOPT-CLUSTER PIC S9(9) BINARY VALUE 1. 002650C 10 MQTOPT-ALL PIC S9(9) BINARY VALUE 2. 002651C 002652C ** Multicast 002653C 10 MQMC-AS-PARENT PIC S9(9) BINARY VALUE 0. 002654C 10 MQMC-ENABLED PIC S9(9) BINARY VALUE 1. 002655C 10 MQMC-DISABLED PIC S9(9) BINARY VALUE 2. 002656C 10 MQMC-ONLY PIC S9(9) BINARY VALUE 3. 002657C 002658C ** CommInfo Type 002659C 10 MQCIT-MULTICAST PIC S9(9) BINARY VALUE 1. 002660C 002661C ****************************************************************** 002662C ** Values Related to Subscription Attributes 002663C ****************************************************************** 002664C ** Destination Class 002665C 10 MQDC-MANAGED PIC S9(9) BINARY VALUE 1. 002666C 10 MQDC-PROVIDED PIC S9(9) BINARY VALUE 2. 002667C 002668C ** Pub/Sub Message Properties 002669C 10 MQPSPROP-NONE PIC S9(9) BINARY VALUE 0. 002670C 10 MQPSPROP-COMPAT PIC S9(9) BINARY VALUE 1. 002671C 10 MQPSPROP-RFH2 PIC S9(9) BINARY VALUE 2. 002672C 10 MQPSPROP-MSGPROP PIC S9(9) BINARY VALUE 3. 002673C 002674C ** Request Only 002675C 10 MQRU-PUBLISH-ON-REQUEST PIC S9(9) BINARY VALUE 1. 002676C 10 MQRU-PUBLISH-ALL PIC S9(9) BINARY VALUE 2. 002677C 002678C ** Durable Subscriptions 002679C 10 MQSUB-DURABLE-ALL PIC S9(9) BINARY VALUE -1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 51 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002680C 10 MQSUB-DURABLE-YES PIC S9(9) BINARY VALUE 1. 002681C 10 MQSUB-DURABLE-NO PIC S9(9) BINARY VALUE 2. 002682C 002683C ** Subscription Scope 002684C 10 MQTSCOPE-QMGR PIC S9(9) BINARY VALUE 1. 002685C 10 MQTSCOPE-ALL PIC S9(9) BINARY VALUE 2. 002686C 002687C ** Variable User ID 002688C 10 MQVU-FIXED-USER PIC S9(9) BINARY VALUE 1. 002689C 10 MQVU-ANY-USER PIC S9(9) BINARY VALUE 2. 002690C 002691C ** Wildcard Schema 002692C 10 MQWS-DEFAULT PIC S9(9) BINARY VALUE 0. 002693C 10 MQWS-CHAR PIC S9(9) BINARY VALUE 1. 002694C 10 MQWS-TOPIC PIC S9(9) BINARY VALUE 2. 002695C 002696C ****************************************************************** 002697C ** Values Related to Channel Authentication Configuration 002698C ** Attributes 002699C ****************************************************************** 002700C ** User Source Options 002701C 10 MQUSRC-MAP PIC S9(9) BINARY VALUE 0. 002702C 10 MQUSRC-NOACCESS PIC S9(9) BINARY VALUE 1. 002703C 10 MQUSRC-CHANNEL PIC S9(9) BINARY VALUE 2. 002704C 002705C ** Warn Options 002706C 10 MQWARN-YES PIC S9(9) BINARY VALUE 1. 002707C 10 MQWARN-NO PIC S9(9) BINARY VALUE 0. 002708C 002709C ** DSBlock Options 002710C 10 MQDSB-DEFAULT PIC S9(9) BINARY VALUE 0. 002711C 10 MQDSB-8K PIC S9(9) BINARY VALUE 1. 002712C 10 MQDSB-16K PIC S9(9) BINARY VALUE 2. 002713C 10 MQDSB-32K PIC S9(9) BINARY VALUE 3. 002714C 10 MQDSB-64K PIC S9(9) BINARY VALUE 4. 002715C 10 MQDSB-128K PIC S9(9) BINARY VALUE 5. 002716C 10 MQDSB-256K PIC S9(9) BINARY VALUE 6. 002717C 10 MQDSB-512K PIC S9(9) BINARY VALUE 7. 002718C 10 MQDSB-1024K PIC S9(9) BINARY VALUE 8. 002719C 10 MQDSB-1M PIC S9(9) BINARY VALUE 8. 002720C 002721C ** DSExpand Options 002722C 10 MQDSE-DEFAULT PIC S9(9) BINARY VALUE 0. 002723C 10 MQDSE-YES PIC S9(9) BINARY VALUE 1. 002724C 10 MQDSE-NO PIC S9(9) BINARY VALUE 2. 002725C 002726C ** OffldUse Options 002727C 10 MQCFOFFLD-NONE PIC S9(9) BINARY VALUE 0. 002728C 10 MQCFOFFLD-SMDS PIC S9(9) BINARY VALUE 1. 002729C 10 MQCFOFFLD-DB2 PIC S9(9) BINARY VALUE 2. 002730C 10 MQCFOFFLD-BOTH PIC S9(9) BINARY VALUE 3. 002731C 002732C ** Use Dead Letter Queue Options 002733C 10 MQUSEDLQ-AS-PARENT PIC S9(9) BINARY VALUE 0. 002734C 10 MQUSEDLQ-NO PIC S9(9) BINARY VALUE 1. 002735C 10 MQUSEDLQ-YES PIC S9(9) BINARY VALUE 2. 002736C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 52 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002737C ****************************************************************** 002738C ** Values Related to MQCLOSE Function 002739C ****************************************************************** 002740C ** Object Handle 002741C 10 MQHO-UNUSABLE-HOBJ PIC S9(9) BINARY VALUE -1. 002742C 10 MQHO-NONE PIC S9(9) BINARY VALUE 0. 002743C 002744C ** Close Options 002745C 10 MQCO-IMMEDIATE PIC S9(9) BINARY VALUE 0. 002746C 10 MQCO-NONE PIC S9(9) BINARY VALUE 0. 002747C 10 MQCO-DELETE PIC S9(9) BINARY VALUE 1. 002748C 10 MQCO-DELETE-PURGE PIC S9(9) BINARY VALUE 2. 002749C 10 MQCO-KEEP-SUB PIC S9(9) BINARY VALUE 4. 002750C 10 MQCO-REMOVE-SUB PIC S9(9) BINARY VALUE 8. 002751C 10 MQCO-QUIESCE PIC S9(9) BINARY VALUE 32. 002752C 002753C ****************************************************************** 002754C ** Values Related to MQCTL and MQCB Functions 002755C ****************************************************************** 002756C ** Operation codes for MQCTL 002757C 10 MQOP-START PIC S9(9) BINARY VALUE 1. 002758C 10 MQOP-START-WAIT PIC S9(9) BINARY VALUE 2. 002759C 10 MQOP-STOP PIC S9(9) BINARY VALUE 4. 002760C 002761C ** Operation codes for MQCB 002762C 10 MQOP-REGISTER PIC S9(9) BINARY VALUE 256. 002763C 10 MQOP-DEREGISTER PIC S9(9) BINARY VALUE 512. 002764C 002765C ** Operation codes for MQCTL and MQCB 002766C 10 MQOP-SUSPEND PIC S9(9) BINARY VALUE 65536. 002767C 10 MQOP-RESUME PIC S9(9) BINARY VALUE 131072. 002768C 002769C ****************************************************************** 002770C ** Values Related to MQDLTMH Function 002771C ****************************************************************** 002772C ** Message handle 002773C 10 MQHM-UNUSABLE-HMSG PIC S9(18) BINARY VALUE -1. 002774C 10 MQHM-NONE PIC S9(18) BINARY VALUE 0. 002775C 002776C ****************************************************************** 002777C ** Values Related to MQINQ Function 002778C ****************************************************************** 002779C ** Byte Attribute Selectors 002780C 10 MQBA-FIRST PIC S9(9) BINARY VALUE 6001. 002781C 10 MQBA-LAST PIC S9(9) BINARY VALUE 8000. 002782C 002783C ** Character Attribute Selectors 002784C 10 MQCA-ADMIN-TOPIC-NAME PIC S9(9) BINARY VALUE 2105. 002785C 10 MQCA-ALTERATION-DATE PIC S9(9) BINARY VALUE 2027. 002786C 10 MQCA-ALTERATION-TIME PIC S9(9) BINARY VALUE 2028. 002787C 10 MQCA-AMQP-SSL-CIPHER-SUITES PIC S9(9) BINARY VALUE 2137. 002788C 10 MQCA-AMQP-VERSION PIC S9(9) BINARY VALUE 2136. 002789C 10 MQCA-APPL-ID PIC S9(9) BINARY VALUE 2001. 002790C 10 MQCA-AUTH-INFO-CONN-NAME PIC S9(9) BINARY VALUE 2053. 002791C 10 MQCA-AUTH-INFO-DESC PIC S9(9) BINARY VALUE 2046. 002792C 10 MQCA-AUTH-INFO-NAME PIC S9(9) BINARY VALUE 2045. 002793C 10 MQCA-AUTH-INFO-OCSP-URL PIC S9(9) BINARY VALUE 2109. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 53 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002794C 10 MQCA-AUTO-REORG-CATALOG PIC S9(9) BINARY VALUE 2091. 002795C 10 MQCA-AUTO-REORG-START-TIME PIC S9(9) BINARY VALUE 2090. 002796C 10 MQCA-BACKOUT-REQ-Q-NAME PIC S9(9) BINARY VALUE 2019. 002797C 10 MQCA-BASE-OBJECT-NAME PIC S9(9) BINARY VALUE 2002. 002798C 10 MQCA-BASE-Q-NAME PIC S9(9) BINARY VALUE 2002. 002799C 10 MQCA-BATCH-INTERFACE-ID PIC S9(9) BINARY VALUE 2068. 002800C 10 MQCA-CERT-LABEL PIC S9(9) BINARY VALUE 2121. 002801C 10 MQCA-CF-STRUC-DESC PIC S9(9) BINARY VALUE 2052. 002802C 10 MQCA-CF-STRUC-NAME PIC S9(9) BINARY VALUE 2039. 002803C 10 MQCA-CHANNEL-AUTO-DEF-EXIT PIC S9(9) BINARY VALUE 2026. 002804C 10 MQCA-CHILD PIC S9(9) BINARY VALUE 2101. 002805C 10 MQCA-CHINIT-SERVICE-PARM PIC S9(9) BINARY VALUE 2076. 002806C 10 MQCA-CHLAUTH-DESC PIC S9(9) BINARY VALUE 2118. 002807C 10 MQCA-CICS-FILE-NAME PIC S9(9) BINARY VALUE 2060. 002808C 10 MQCA-CLUSTER-DATE PIC S9(9) BINARY VALUE 2037. 002809C 10 MQCA-CLUSTER-NAME PIC S9(9) BINARY VALUE 2029. 002810C 10 MQCA-CLUSTER-NAMELIST PIC S9(9) BINARY VALUE 2030. 002811C 10 MQCA-CLUSTER-Q-MGR-NAME PIC S9(9) BINARY VALUE 2031. 002812C 10 MQCA-CLUSTER-TIME PIC S9(9) BINARY VALUE 2038. 002813C 10 MQCA-CLUSTER-WORKLOAD-DATA PIC S9(9) BINARY VALUE 2034. 002814C 10 MQCA-CLUSTER-WORKLOAD-EXIT PIC S9(9) BINARY VALUE 2033. 002815C 10 MQCA-CLUS-CHL-NAME PIC S9(9) BINARY VALUE 2124. 002816C 10 MQCA-COMMAND-INPUT-Q-NAME PIC S9(9) BINARY VALUE 2003. 002817C 10 MQCA-COMMAND-REPLY-Q-NAME PIC S9(9) BINARY VALUE 2067. 002818C 10 MQCA-COMM-INFO-DESC PIC S9(9) BINARY VALUE 2111. 002819C 10 MQCA-COMM-INFO-NAME PIC S9(9) BINARY VALUE 2110. 002820C 10 MQCA-CONN-AUTH PIC S9(9) BINARY VALUE 2125. 002821C 10 MQCA-CREATION-DATE PIC S9(9) BINARY VALUE 2004. 002822C 10 MQCA-CREATION-TIME PIC S9(9) BINARY VALUE 2005. 002823C 10 MQCA-CUSTOM PIC S9(9) BINARY VALUE 2119. 002824C 10 MQCA-DEAD-LETTER-Q-NAME PIC S9(9) BINARY VALUE 2006. 002825C 10 MQCA-DEF-XMIT-Q-NAME PIC S9(9) BINARY VALUE 2025. 002826C 10 MQCA-DNS-GROUP PIC S9(9) BINARY VALUE 2071. 002827C 10 MQCA-ENV-DATA PIC S9(9) BINARY VALUE 2007. 002828C 10 MQCA-FIRST PIC S9(9) BINARY VALUE 2001. 002829C 10 MQCA-IGQ-USER-ID PIC S9(9) BINARY VALUE 2041. 002830C 10 MQCA-INITIAL-KEY PIC S9(9) BINARY VALUE 2054. 002831C 10 MQCA-INITIATION-Q-NAME PIC S9(9) BINARY VALUE 2008. 002832C 10 MQCA-INSTALLATION-DESC PIC S9(9) BINARY VALUE 2115. 002833C 10 MQCA-INSTALLATION-NAME PIC S9(9) BINARY VALUE 2116. 002834C 10 MQCA-INSTALLATION-PATH PIC S9(9) BINARY VALUE 2117. 002835C 10 MQCA-LAST PIC S9(9) BINARY VALUE 4000. 002836C 10 MQCA-LAST-USED PIC S9(9) BINARY VALUE 2138. 002837C 10 MQCA-LDAP-BASE-DN-GROUPS PIC S9(9) BINARY VALUE 2132. 002838C 10 MQCA-LDAP-BASE-DN-USERS PIC S9(9) BINARY VALUE 2126. 002839C 10 MQCA-LDAP-FIND-GROUP-FIELD PIC S9(9) BINARY VALUE 2135. 002840C 10 MQCA-LDAP-GROUP-ATTR-FIELD PIC S9(9) BINARY VALUE 2134. 002841C 10 MQCA-LDAP-GROUP-OBJECT-CLASS PIC S9(9) BINARY VALUE 2133. 002842C 10 MQCA-LDAP-PASSWORD PIC S9(9) BINARY VALUE 2048. 002843C 10 MQCA-LDAP-SHORT-USER-FIELD PIC S9(9) BINARY VALUE 2127. 002844C 10 MQCA-LDAP-USER-ATTR-FIELD PIC S9(9) BINARY VALUE 2129. 002845C 10 MQCA-LDAP-USER-NAME PIC S9(9) BINARY VALUE 2047. 002846C 10 MQCA-LDAP-USER-OBJECT-CLASS PIC S9(9) BINARY VALUE 2128. 002847C 10 MQCA-LU62-ARM-SUFFIX PIC S9(9) BINARY VALUE 2074. 002848C 10 MQCA-LU-GROUP-NAME PIC S9(9) BINARY VALUE 2072. 002849C 10 MQCA-LU-NAME PIC S9(9) BINARY VALUE 2073. 002850C 10 MQCA-MODEL-DURABLE-Q PIC S9(9) BINARY VALUE 2096. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 54 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002851C 10 MQCA-MODEL-NON-DURABLE-Q PIC S9(9) BINARY VALUE 2097. 002852C 10 MQCA-MONITOR-Q-NAME PIC S9(9) BINARY VALUE 2066. 002853C 10 MQCA-NAMELIST-DESC PIC S9(9) BINARY VALUE 2009. 002854C 10 MQCA-NAMELIST-NAME PIC S9(9) BINARY VALUE 2010. 002855C 10 MQCA-NAMES PIC S9(9) BINARY VALUE 2020. 002856C 10 MQCA-PARENT PIC S9(9) BINARY VALUE 2102. 002857C 10 MQCA-PASS-TICKET-APPL PIC S9(9) BINARY VALUE 2086. 002858C 10 MQCA-POLICY-NAME PIC S9(9) BINARY VALUE 2112. 002859C 10 MQCA-PROCESS-DESC PIC S9(9) BINARY VALUE 2011. 002860C 10 MQCA-PROCESS-NAME PIC S9(9) BINARY VALUE 2012. 002861C 10 MQCA-QSG-CERT-LABEL PIC S9(9) BINARY VALUE 2131. 002862C 10 MQCA-QSG-NAME PIC S9(9) BINARY VALUE 2040. 002863C 10 MQCA-Q-DESC PIC S9(9) BINARY VALUE 2013. 002864C 10 MQCA-Q-MGR-DESC PIC S9(9) BINARY VALUE 2014. 002865C 10 MQCA-Q-MGR-IDENTIFIER PIC S9(9) BINARY VALUE 2032. 002866C 10 MQCA-Q-MGR-NAME PIC S9(9) BINARY VALUE 2015. 002867C 10 MQCA-Q-NAME PIC S9(9) BINARY VALUE 2016. 002868C 10 MQCA-RECIPIENT-DN PIC S9(9) BINARY VALUE 2114. 002869C 10 MQCA-REMOTE-Q-MGR-NAME PIC S9(9) BINARY VALUE 2017. 002870C 10 MQCA-REMOTE-Q-NAME PIC S9(9) BINARY VALUE 2018. 002871C 10 MQCA-REPOSITORY-NAME PIC S9(9) BINARY VALUE 2035. 002872C 10 MQCA-REPOSITORY-NAMELIST PIC S9(9) BINARY VALUE 2036. 002873C 10 MQCA-RESUME-DATE PIC S9(9) BINARY VALUE 2098. 002874C 10 MQCA-RESUME-TIME PIC S9(9) BINARY VALUE 2099. 002875C 10 MQCA-SERVICE-DESC PIC S9(9) BINARY VALUE 2078. 002876C 10 MQCA-SERVICE-NAME PIC S9(9) BINARY VALUE 2077. 002877C 10 MQCA-SERVICE-START-ARGS PIC S9(9) BINARY VALUE 2080. 002878C 10 MQCA-SERVICE-START-COMMAND PIC S9(9) BINARY VALUE 2079. 002879C 10 MQCA-SERVICE-STOP-ARGS PIC S9(9) BINARY VALUE 2082. 002880C 10 MQCA-SERVICE-STOP-COMMAND PIC S9(9) BINARY VALUE 2081. 002881C 10 MQCA-SIGNER-DN PIC S9(9) BINARY VALUE 2113. 002882C 10 MQCA-SSL-CERT-ISSUER-NAME PIC S9(9) BINARY VALUE 2130. 002883C 10 MQCA-SSL-CRL-NAMELIST PIC S9(9) BINARY VALUE 2050. 002884C 10 MQCA-SSL-CRYPTO-HARDWARE PIC S9(9) BINARY VALUE 2051. 002885C 10 MQCA-SSL-KEY-LIBRARY PIC S9(9) BINARY VALUE 2069. 002886C 10 MQCA-SSL-KEY-MEMBER PIC S9(9) BINARY VALUE 2070. 002887C 10 MQCA-SSL-KEY-REPOSITORY PIC S9(9) BINARY VALUE 2049. 002888C 10 MQCA-SSL-KEY-REPO-PASSWORD PIC S9(9) BINARY VALUE 2055. 002889C 10 MQCA-STDERR-DESTINATION PIC S9(9) BINARY VALUE 2084. 002890C 10 MQCA-STDOUT-DESTINATION PIC S9(9) BINARY VALUE 2083. 002891C 10 MQCA-STORAGE-CLASS PIC S9(9) BINARY VALUE 2022. 002892C 10 MQCA-STORAGE-CLASS-DESC PIC S9(9) BINARY VALUE 2042. 002893C 10 MQCA-STREAM-QUEUE-NAME PIC S9(9) BINARY VALUE 2138. 002894C 10 MQCA-SYSTEM-LOG-Q-NAME PIC S9(9) BINARY VALUE 2065. 002895C 10 MQCA-TCP-NAME PIC S9(9) BINARY VALUE 2075. 002896C 10 MQCA-TOPIC-DESC PIC S9(9) BINARY VALUE 2093. 002897C 10 MQCA-TOPIC-NAME PIC S9(9) BINARY VALUE 2092. 002898C 10 MQCA-TOPIC-STRING PIC S9(9) BINARY VALUE 2094. 002899C 10 MQCA-TOPIC-STRING-FILTER PIC S9(9) BINARY VALUE 2108. 002900C 10 MQCA-TPIPE-NAME PIC S9(9) BINARY VALUE 2085. 002901C 10 MQCA-TRIGGER-CHANNEL-NAME PIC S9(9) BINARY VALUE 2064. 002902C 10 MQCA-TRIGGER-DATA PIC S9(9) BINARY VALUE 2023. 002903C 10 MQCA-TRIGGER-PROGRAM-NAME PIC S9(9) BINARY VALUE 2062. 002904C 10 MQCA-TRIGGER-TERM-ID PIC S9(9) BINARY VALUE 2063. 002905C 10 MQCA-TRIGGER-TRANS-ID PIC S9(9) BINARY VALUE 2061. 002906C 10 MQCA-USER-DATA PIC S9(9) BINARY VALUE 2021. 002907C 10 MQCA-USER-LIST PIC S9(9) BINARY VALUE 4000. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 55 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002908C 10 MQCA-VERSION PIC S9(9) BINARY VALUE 2120. 002909C 10 MQCA-XCF-GROUP-NAME PIC S9(9) BINARY VALUE 2043. 002910C 10 MQCA-XCF-MEMBER-NAME PIC S9(9) BINARY VALUE 2044. 002911C 10 MQCA-XMIT-Q-NAME PIC S9(9) BINARY VALUE 2024. 002912C 10 MQCA-XR-SSL-CIPHER-SUITES PIC S9(9) BINARY VALUE 2123. 002913C 10 MQCA-XR-VERSION PIC S9(9) BINARY VALUE 2122. 002914C 002915C ** Integer Attribute Selectors 002916C 10 MQIA-ACCOUNTING-CONN-OVERRIDE PIC S9(9) BINARY VALUE 136. 002917C 10 MQIA-ACCOUNTING-INTERVAL PIC S9(9) BINARY VALUE 135. 002918C 10 MQIA-ACCOUNTING-MQI PIC S9(9) BINARY VALUE 133. 002919C 10 MQIA-ACCOUNTING-Q PIC S9(9) BINARY VALUE 134. 002920C 10 MQIA-ACTIVE-CHANNELS PIC S9(9) BINARY VALUE 100. 002921C 10 MQIA-ACTIVITY-CONN-OVERRIDE PIC S9(9) BINARY VALUE 239. 002922C 10 MQIA-ACTIVITY-RECORDING PIC S9(9) BINARY VALUE 138. 002923C 10 MQIA-ACTIVITY-TRACE PIC S9(9) BINARY VALUE 240. 002924C 10 MQIA-ADOPTNEWMCA-CHECK PIC S9(9) BINARY VALUE 102. 002925C 10 MQIA-ADOPTNEWMCA-INTERVAL PIC S9(9) BINARY VALUE 104. 002926C 10 MQIA-ADOPTNEWMCA-TYPE PIC S9(9) BINARY VALUE 103. 002927C 10 MQIA-ADOPT-CONTEXT PIC S9(9) BINARY VALUE 260. 002928C 10 MQIA-ADVANCED-CAPABILITY PIC S9(9) BINARY VALUE 273. 002929C 10 MQIA-AMQP-CAPABILITY PIC S9(9) BINARY VALUE 265. 002930C 10 MQIA-APPL-TYPE PIC S9(9) BINARY VALUE 1. 002931C 10 MQIA-ARCHIVE PIC S9(9) BINARY VALUE 60. 002932C 10 MQIA-AUTHENTICATION-FAIL-DELAY PIC S9(9) BINARY VALUE 259. 002933C 10 MQIA-AUTHENTICATION-METHOD PIC S9(9) BINARY VALUE 266. 002934C 10 MQIA-AUTHOREV-SCOPE PIC S9(9) BINARY VALUE 277. 002935C 10 MQIA-AUTHORITY-EVENT PIC S9(9) BINARY VALUE 47. 002936C 10 MQIA-AUTH-INFO-TYPE PIC S9(9) BINARY VALUE 66. 002937C 10 MQIA-AUTO-REORGANIZATION PIC S9(9) BINARY VALUE 173. 002938C 10 MQIA-AUTO-REORG-INTERVAL PIC S9(9) BINARY VALUE 174. 002939C 10 MQIA-BACKOUT-THRESHOLD PIC S9(9) BINARY VALUE 22. 002940C 10 MQIA-BASE-TYPE PIC S9(9) BINARY VALUE 193. 002941C 10 MQIA-BATCH-INTERFACE-AUTO PIC S9(9) BINARY VALUE 86. 002942C 10 MQIA-BRIDGE-EVENT PIC S9(9) BINARY VALUE 74. 002943C 10 MQIA-CAP-EXPIRY PIC S9(9) BINARY VALUE 276. 002944C 10 MQIA-CERT-VAL-POLICY PIC S9(9) BINARY VALUE 252. 002945C 10 MQIA-CF-CFCONLOS PIC S9(9) BINARY VALUE 246. 002946C 10 MQIA-CF-LEVEL PIC S9(9) BINARY VALUE 70. 002947C 10 MQIA-CF-OFFLDUSE PIC S9(9) BINARY VALUE 229. 002948C 10 MQIA-CF-OFFLOAD PIC S9(9) BINARY VALUE 224. 002949C 10 MQIA-CF-OFFLOAD-THRESHOLD1 PIC S9(9) BINARY VALUE 225. 002950C 10 MQIA-CF-OFFLOAD-THRESHOLD2 PIC S9(9) BINARY VALUE 226. 002951C 10 MQIA-CF-OFFLOAD-THRESHOLD3 PIC S9(9) BINARY VALUE 227. 002952C 10 MQIA-CF-RECAUTO PIC S9(9) BINARY VALUE 244. 002953C 10 MQIA-CF-RECOVER PIC S9(9) BINARY VALUE 71. 002954C 10 MQIA-CF-SMDS-BUFFERS PIC S9(9) BINARY VALUE 228. 002955C 10 MQIA-CHANNEL-AUTO-DEF PIC S9(9) BINARY VALUE 55. 002956C 10 MQIA-CHANNEL-AUTO-DEF-EVENT PIC S9(9) BINARY VALUE 56. 002957C 10 MQIA-CHANNEL-EVENT PIC S9(9) BINARY VALUE 73. 002958C 10 MQIA-CHECK-CLIENT-BINDING PIC S9(9) BINARY VALUE 258. 002959C 10 MQIA-CHECK-LOCAL-BINDING PIC S9(9) BINARY VALUE 257. 002960C 10 MQIA-CHINIT-ADAPTERS PIC S9(9) BINARY VALUE 101. 002961C 10 MQIA-CHINIT-CONTROL PIC S9(9) BINARY VALUE 119. 002962C 10 MQIA-CHINIT-DISPATCHERS PIC S9(9) BINARY VALUE 105. 002963C 10 MQIA-CHINIT-TRACE-AUTO-START PIC S9(9) BINARY VALUE 117. 002964C 10 MQIA-CHINIT-TRACE-TABLE-SIZE PIC S9(9) BINARY VALUE 118. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 56 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002965C 10 MQIA-CHLAUTH-RECORDS PIC S9(9) BINARY VALUE 248. 002966C 10 MQIA-CLUSTER-OBJECT-STATE PIC S9(9) BINARY VALUE 256. 002967C 10 MQIA-CLUSTER-PUB-ROUTE PIC S9(9) BINARY VALUE 255. 002968C 10 MQIA-CLUSTER-Q-TYPE PIC S9(9) BINARY VALUE 59. 002969C 10 MQIA-CLUSTER-WORKLOAD-LENGTH PIC S9(9) BINARY VALUE 58. 002970C 10 MQIA-CLWL-MRU-CHANNELS PIC S9(9) BINARY VALUE 97. 002971C 10 MQIA-CLWL-Q-PRIORITY PIC S9(9) BINARY VALUE 96. 002972C 10 MQIA-CLWL-Q-RANK PIC S9(9) BINARY VALUE 95. 002973C 10 MQIA-CLWL-USEQ PIC S9(9) BINARY VALUE 98. 002974C 10 MQIA-CMD-SERVER-AUTO PIC S9(9) BINARY VALUE 87. 002975C 10 MQIA-CMD-SERVER-CONTROL PIC S9(9) BINARY VALUE 120. 002976C 10 MQIA-CMD-SERVER-CONVERT-MSG PIC S9(9) BINARY VALUE 88. 002977C 10 MQIA-CMD-SERVER-DLQ-MSG PIC S9(9) BINARY VALUE 89. 002978C 10 MQIA-CODED-CHAR-SET-ID PIC S9(9) BINARY VALUE 2. 002979C 10 MQIA-COMMAND-EVENT PIC S9(9) BINARY VALUE 99. 002980C 10 MQIA-COMMAND-LEVEL PIC S9(9) BINARY VALUE 31. 002981C 10 MQIA-COMM-EVENT PIC S9(9) BINARY VALUE 232. 002982C 10 MQIA-COMM-INFO-TYPE PIC S9(9) BINARY VALUE 223. 002983C 10 MQIA-CONFIGURATION-EVENT PIC S9(9) BINARY VALUE 51. 002984C 10 MQIA-CPI-LEVEL PIC S9(9) BINARY VALUE 27. 002985C 10 MQIA-CURRENT-Q-DEPTH PIC S9(9) BINARY VALUE 3. 002986C 10 MQIA-DEFINITION-TYPE PIC S9(9) BINARY VALUE 7. 002987C 10 MQIA-DEF-BIND PIC S9(9) BINARY VALUE 61. 002988C 10 MQIA-DEF-CLUSTER-XMIT-Q-TYPE PIC S9(9) BINARY VALUE 250. 002989C 10 MQIA-DEF-INPUT-OPEN-OPTION PIC S9(9) BINARY VALUE 4. 002990C 10 MQIA-DEF-PERSISTENCE PIC S9(9) BINARY VALUE 5. 002991C 10 MQIA-DEF-PRIORITY PIC S9(9) BINARY VALUE 6. 002992C 10 MQIA-DEF-PUT-RESPONSE-TYPE PIC S9(9) BINARY VALUE 184. 002993C 10 MQIA-DEF-READ-AHEAD PIC S9(9) BINARY VALUE 188. 002994C 10 MQIA-DISPLAY-TYPE PIC S9(9) BINARY VALUE 262. 002995C 10 MQIA-DIST-LISTS PIC S9(9) BINARY VALUE 34. 002996C 10 MQIA-DNS-WLM PIC S9(9) BINARY VALUE 106. 002997C 10 MQIA-DURABLE-SUB PIC S9(9) BINARY VALUE 175. 002998C 10 MQIA-ENCRYPTION-ALGORITHM PIC S9(9) BINARY VALUE 237. 002999C 10 MQIA-EXPIRY-INTERVAL PIC S9(9) BINARY VALUE 39. 003000C 10 MQIA-FIRST PIC S9(9) BINARY VALUE 1. 003001C 10 MQIA-GROUP-UR PIC S9(9) BINARY VALUE 221. 003002C 10 MQIA-HARDEN-GET-BACKOUT PIC S9(9) BINARY VALUE 8. 003003C 10 MQIA-HIGH-Q-DEPTH PIC S9(9) BINARY VALUE 36. 003004C 10 MQIA-IGQ-PUT-AUTHORITY PIC S9(9) BINARY VALUE 65. 003005C 10 MQIA-INDEX-TYPE PIC S9(9) BINARY VALUE 57. 003006C 10 MQIA-INHIBIT-EVENT PIC S9(9) BINARY VALUE 48. 003007C 10 MQIA-INHIBIT-GET PIC S9(9) BINARY VALUE 9. 003008C 10 MQIA-INHIBIT-PUB PIC S9(9) BINARY VALUE 181. 003009C 10 MQIA-INHIBIT-PUT PIC S9(9) BINARY VALUE 10. 003010C 10 MQIA-INHIBIT-SUB PIC S9(9) BINARY VALUE 182. 003011C 10 MQIA-INTRA-GROUP-QUEUING PIC S9(9) BINARY VALUE 64. 003012C 10 MQIA-INT-ACTION PIC S9(9) BINARY VALUE 10000. 003013C 10 MQIA-INT-ADS-DESCRIPTOR PIC S9(9) BINARY VALUE 10004. 003014C 10 MQIA-INT-ALL-ATTRS PIC S9(9) BINARY VALUE 10089. 003015C 10 MQIA-INT-ALL-BYTE-ATTRS PIC S9(9) BINARY VALUE 10093. 003016C 10 MQIA-INT-ALL-CHAR-ATTRS PIC S9(9) BINARY VALUE 10082. 003017C 10 MQIA-INT-ALL-COMMANDS PIC S9(9) BINARY VALUE 10088. 003018C 10 MQIA-INT-ALL-GET-OPTIONS PIC S9(9) BINARY VALUE 10090. 003019C 10 MQIA-INT-ALL-GROUP-ATTRS PIC S9(9) BINARY VALUE 10094. 003020C 10 MQIA-INT-ALL-INT-ATTRS PIC S9(9) BINARY VALUE 10081. 003021C 10 MQIA-INT-ALL-SEL-ATTRS PIC S9(9) BINARY VALUE 10095. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 57 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003022C 10 MQIA-INT-ATTR-VALUES PIC S9(9) BINARY VALUE 10034. 003023C 10 MQIA-INT-AUTHENTICATION-TYPE PIC S9(9) BINARY VALUE 10017. 003024C 10 MQIA-INT-AUTHENTICATION-TYPES PIC S9(9) BINARY VALUE 10070. 003025C 10 MQIA-INT-AUTHORIZATIONS PIC S9(9) BINARY VALUE 10069. 003026C 10 MQIA-INT-BAG-HANDLES PIC S9(9) BINARY VALUE 10030. 003027C 10 MQIA-INT-BEGIN-OPTIONS PIC S9(9) BINARY VALUE 10003. 003028C 10 MQIA-INT-BUFFER-LENGTH PIC S9(9) BINARY VALUE 10001. 003029C 10 MQIA-INT-BUFMH-OPTIONS PIC S9(9) BINARY VALUE 10002. 003030C 10 MQIA-INT-CAPABILITY-FLAGS PIC S9(9) BINARY VALUE 10009. 003031C 10 MQIA-INT-CB-FLAGS PIC S9(9) BINARY VALUE 10005. 003032C 10 MQIA-INT-CB-MAX-MSG-LENGTH PIC S9(9) BINARY VALUE 10006. 003033C 10 MQIA-INT-CB-STATE PIC S9(9) BINARY VALUE 10018. 003034C 10 MQIA-INT-CFH-CONTROL PIC S9(9) BINARY VALUE 10103. 003035C 10 MQIA-INT-CFH-TYPE PIC S9(9) BINARY VALUE 10102. 003036C 10 MQIA-INT-CICS-RETURN-CODE PIC S9(9) BINARY VALUE 10016. 003037C 10 MQIA-INT-CIH-FLAGS PIC S9(9) BINARY VALUE 10011. 003038C 10 MQIA-INT-CLUS-CHAR-ATTRS PIC S9(9) BINARY VALUE 10084. 003039C 10 MQIA-INT-CLUS-COMMANDS PIC S9(9) BINARY VALUE 10085. 003040C 10 MQIA-INT-CLUS-INT-ATTRS PIC S9(9) BINARY VALUE 10083. 003041C 10 MQIA-INT-CLUS-QUERY PIC S9(9) BINARY VALUE 10087. 003042C 10 MQIA-INT-CLUS-QUERY-REFRESH PIC S9(9) BINARY VALUE 10086. 003043C 10 MQIA-INT-COMMIT-MODES PIC S9(9) BINARY VALUE 10100. 003044C 10 MQIA-INT-CONN-HANDLES PIC S9(9) BINARY VALUE 10031. 003045C 10 MQIA-INT-CONTINUATION-INDIC PIC S9(9) BINARY VALUE 10071. 003046C 10 MQIA-INT-CONVERSATIONAL-TASK PIC S9(9) BINARY VALUE 10007. 003047C 10 MQIA-INT-COPY-OPTIONS PIC S9(9) BINARY VALUE 10015. 003048C 10 MQIA-INT-CRTMH-OPTIONS PIC S9(9) BINARY VALUE 10013. 003049C 10 MQIA-INT-CTL-OPTIONS PIC S9(9) BINARY VALUE 10020. 003050C 10 MQIA-INT-DELETE-OPTIONS PIC S9(9) BINARY VALUE 10023. 003051C 10 MQIA-INT-DH-FLAGS PIC S9(9) BINARY VALUE 10024. 003052C 10 MQIA-INT-DLTMH-OPTIONS PIC S9(9) BINARY VALUE 10025. 003053C 10 MQIA-INT-DLTMP-OPTIONS PIC S9(9) BINARY VALUE 10026. 003054C 10 MQIA-INT-DXP-EXIT-RESPONSE PIC S9(9) BINARY VALUE 10064. 003055C 10 MQIA-INT-EPH-FLAGS PIC S9(9) BINARY VALUE 10028. 003056C 10 MQIA-INT-ERRNO PIC S9(9) BINARY VALUE 10092. 003057C 10 MQIA-INT-EXIT-COMMANDS PIC S9(9) BINARY VALUE 10063. 003058C 10 MQIA-INT-EXIT-IDENTIFIERS PIC S9(9) BINARY VALUE 10068. 003059C 10 MQIA-INT-EXIT-OPTIONS PIC S9(9) BINARY VALUE 10065. 003060C 10 MQIA-INT-EXIT-REASONS PIC S9(9) BINARY VALUE 10067. 003061C 10 MQIA-INT-EXIT-RESPONSES PIC S9(9) BINARY VALUE 10062. 003062C 10 MQIA-INT-EXIT-RESPONSE-2 PIC S9(9) BINARY VALUE 10066. 003063C 10 MQIA-INT-EXPORT-OPTIONS PIC S9(9) BINARY VALUE 10029. 003064C 10 MQIA-INT-FILTER-OPERATORS PIC S9(9) BINARY VALUE 10008. 003065C 10 MQIA-INT-GET-WAIT-INTERVAL PIC S9(9) BINARY VALUE 10010. 003066C 10 MQIA-INT-GROUP-STATUS PIC S9(9) BINARY VALUE 10096. 003067C 10 MQIA-INT-IEP-FLAGS PIC S9(9) BINARY VALUE 10035. 003068C 10 MQIA-INT-IIH-FLAGS PIC S9(9) BINARY VALUE 10036. 003069C 10 MQIA-INT-INIT-OPTIONS PIC S9(9) BINARY VALUE 10072. 003070C 10 MQIA-INT-INQMP-OPTIONS PIC S9(9) BINARY VALUE 10037. 003071C 10 MQIA-INT-ITEM-INDEX PIC S9(9) BINARY VALUE 10038. 003072C 10 MQIA-INT-LINK-TYPE PIC S9(9) BINARY VALUE 10012. 003073C 10 MQIA-INT-MATCH-OPTIONS PIC S9(9) BINARY VALUE 10042. 003074C 10 MQIA-INT-MC-EVENT-CODE PIC S9(9) BINARY VALUE 10039. 003075C 10 MQIA-INT-MDE-FLAGS PIC S9(9) BINARY VALUE 10040. 003076C 10 MQIA-INT-MHBUF-OPTIONS PIC S9(9) BINARY VALUE 10041. 003077C 10 MQIA-INT-MP-TYPES PIC S9(9) BINARY VALUE 10056. 003078C 10 MQIA-INT-MSG-HANDLES PIC S9(9) BINARY VALUE 10032. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 58 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003079C 10 MQIA-INT-NAME-COUNT PIC S9(9) BINARY VALUE 10043. 003080C 10 MQIA-INT-OBJECT-HANDLES PIC S9(9) BINARY VALUE 10033. 003081C 10 MQIA-INT-OUTPUT-DATA-LENGTH PIC S9(9) BINARY VALUE 10014. 003082C 10 MQIA-INT-PD-SUPPORT PIC S9(9) BINARY VALUE 10044. 003083C 10 MQIA-INT-PUBLICATION-OPTIONS PIC S9(9) BINARY VALUE 10046. 003084C 10 MQIA-INT-PUT-MSG-REC-FIELDS PIC S9(9) BINARY VALUE 10045. 003085C 10 MQIA-INT-QUIESCE PIC S9(9) BINARY VALUE 10049. 003086C 10 MQIA-INT-RECONNECT-DELAY PIC S9(9) BINARY VALUE 10050. 003087C 10 MQIA-INT-REGISTRATION-OPTIONS PIC S9(9) BINARY VALUE 10051. 003088C 10 MQIA-INT-RETURNED-LENGTH PIC S9(9) BINARY VALUE 10053. 003089C 10 MQIA-INT-RFH-FLAGS PIC S9(9) BINARY VALUE 10052. 003090C 10 MQIA-INT-RMH-FLAGS PIC S9(9) BINARY VALUE 10091. 003091C 10 MQIA-INT-SECURITY-SCOPES PIC S9(9) BINARY VALUE 10101. 003092C 10 MQIA-INT-SEGMENTATION PIC S9(9) BINARY VALUE 10098. 003093C 10 MQIA-INT-SEGMENT-STATUS PIC S9(9) BINARY VALUE 10097. 003094C 10 MQIA-INT-SELECTOR-INDIC PIC S9(9) BINARY VALUE 10074. 003095C 10 MQIA-INT-SETMP-OPTIONS PIC S9(9) BINARY VALUE 10054. 003096C 10 MQIA-INT-SIGNAL1 PIC S9(9) BINARY VALUE 10027. 003097C 10 MQIA-INT-SMDS-USAGE PIC S9(9) BINARY VALUE 10057. 003098C 10 MQIA-INT-START-ENUM-INDIC PIC S9(9) BINARY VALUE 10073. 003099C 10 MQIA-INT-SYSTEM-OBJECTS PIC S9(9) BINARY VALUE 10055. 003100C 10 MQIA-INT-TASK-END-STATUS PIC S9(9) BINARY VALUE 10019. 003101C 10 MQIA-INT-TERM-OPTIONS PIC S9(9) BINARY VALUE 10075. 003102C 10 MQIA-INT-TRANSACTION-STATES PIC S9(9) BINARY VALUE 10099. 003103C 10 MQIA-INT-TT-KEEP-ALIVE PIC S9(9) BINARY VALUE 10076. 003104C 10 MQIA-INT-UNIX-SIGNAL PIC S9(9) BINARY VALUE 10104. 003105C 10 MQIA-INT-UOW-CONTROL PIC S9(9) BINARY VALUE 10021. 003106C 10 MQIA-INT-VALUE-LENGTH PIC S9(9) BINARY VALUE 10058. 003107C 10 MQIA-INT-VS-LENGTH PIC S9(9) BINARY VALUE 10059. 003108C 10 MQIA-INT-WDR-Q-MGR-FLAGS PIC S9(9) BINARY VALUE 10048. 003109C 10 MQIA-INT-WIH-FLAGS PIC S9(9) BINARY VALUE 10060. 003110C 10 MQIA-INT-WQR-Q-FLAGS PIC S9(9) BINARY VALUE 10047. 003111C 10 MQIA-INT-WXP-FLAGS PIC S9(9) BINARY VALUE 10061. 003112C 10 MQIA-INT-XCNVC-OPTIONS PIC S9(9) BINARY VALUE 10022. 003113C 10 MQIA-INT-ZID-AUTHORITY PIC S9(9) BINARY VALUE 10078. 003114C 10 MQIA-INT-ZID-COMMON PIC S9(9) BINARY VALUE 10077. 003115C 10 MQIA-INT-ZID-NAME PIC S9(9) BINARY VALUE 10079. 003116C 10 MQIA-INT-ZID-USERID PIC S9(9) BINARY VALUE 10080. 003117C 10 MQIA-IP-ADDRESS-VERSION PIC S9(9) BINARY VALUE 93. 003118C 10 MQIA-KEY-REUSE-COUNT PIC S9(9) BINARY VALUE 267. 003119C 10 MQIA-LAST PIC S9(9) BINARY VALUE 2000. 003120C 10 MQIA-LAST-USED PIC S9(9) BINARY VALUE 279. 003121C 10 MQIA-LDAP-AUTHORMD PIC S9(9) BINARY VALUE 263. 003122C 10 MQIA-LDAP-NESTGRP PIC S9(9) BINARY VALUE 264. 003123C 10 MQIA-LDAP-SECURE-COMM PIC S9(9) BINARY VALUE 261. 003124C 10 MQIA-LISTENER-PORT-NUMBER PIC S9(9) BINARY VALUE 85. 003125C 10 MQIA-LISTENER-TIMER PIC S9(9) BINARY VALUE 107. 003126C 10 MQIA-LOCAL-EVENT PIC S9(9) BINARY VALUE 49. 003127C 10 MQIA-LOGGER-EVENT PIC S9(9) BINARY VALUE 94. 003128C 10 MQIA-LU62-CHANNELS PIC S9(9) BINARY VALUE 108. 003129C 10 MQIA-MASTER-ADMIN PIC S9(9) BINARY VALUE 186. 003130C 10 MQIA-MAX-CHANNELS PIC S9(9) BINARY VALUE 109. 003131C 10 MQIA-MAX-CLIENTS PIC S9(9) BINARY VALUE 172. 003132C 10 MQIA-MAX-GLOBAL-LOCKS PIC S9(9) BINARY VALUE 83. 003133C 10 MQIA-MAX-HANDLES PIC S9(9) BINARY VALUE 11. 003134C 10 MQIA-MAX-LOCAL-LOCKS PIC S9(9) BINARY VALUE 84. 003135C 10 MQIA-MAX-MSG-LENGTH PIC S9(9) BINARY VALUE 13. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 59 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003136C 10 MQIA-MAX-OPEN-Q PIC S9(9) BINARY VALUE 80. 003137C 10 MQIA-MAX-PRIORITY PIC S9(9) BINARY VALUE 14. 003138C 10 MQIA-MAX-PROPERTIES-LENGTH PIC S9(9) BINARY VALUE 192. 003139C 10 MQIA-MAX-Q-DEPTH PIC S9(9) BINARY VALUE 15. 003140C 10 MQIA-MAX-Q-FILE-SIZE PIC S9(9) BINARY VALUE 274. 003141C 10 MQIA-MAX-Q-TRIGGERS PIC S9(9) BINARY VALUE 90. 003142C 10 MQIA-MAX-RECOVERY-TASKS PIC S9(9) BINARY VALUE 171. 003143C 10 MQIA-MAX-RESPONSES PIC S9(9) BINARY VALUE 230. 003144C 10 MQIA-MAX-UNCOMMITTED-MSGS PIC S9(9) BINARY VALUE 33. 003145C 10 MQIA-MCAST-BRIDGE PIC S9(9) BINARY VALUE 233. 003146C 10 MQIA-MEDIA-IMAGE-INTERVAL PIC S9(9) BINARY VALUE 269. 003147C 10 MQIA-MEDIA-IMAGE-LOG-LENGTH PIC S9(9) BINARY VALUE 270. 003148C 10 MQIA-MEDIA-IMAGE-RECOVER-OBJ PIC S9(9) BINARY VALUE 271. 003149C 10 MQIA-MEDIA-IMAGE-RECOVER-Q PIC S9(9) BINARY VALUE 272. 003150C 10 MQIA-MEDIA-IMAGE-SCHEDULING PIC S9(9) BINARY VALUE 268. 003151C 10 MQIA-MONITORING-AUTO-CLUSSDR PIC S9(9) BINARY VALUE 124. 003152C 10 MQIA-MONITORING-CHANNEL PIC S9(9) BINARY VALUE 122. 003153C 10 MQIA-MONITORING-Q PIC S9(9) BINARY VALUE 123. 003154C 10 MQIA-MONITOR-INTERVAL PIC S9(9) BINARY VALUE 81. 003155C 10 MQIA-MSG-DELIVERY-SEQUENCE PIC S9(9) BINARY VALUE 16. 003156C 10 MQIA-MSG-DEQ-COUNT PIC S9(9) BINARY VALUE 38. 003157C 10 MQIA-MSG-ENQ-COUNT PIC S9(9) BINARY VALUE 37. 003158C 10 MQIA-MSG-MARK-BROWSE-INTERVAL PIC S9(9) BINARY VALUE 68. 003159C 10 MQIA-MULTICAST PIC S9(9) BINARY VALUE 176. 003160C 10 MQIA-NAMELIST-TYPE PIC S9(9) BINARY VALUE 72. 003161C 10 MQIA-NAME-COUNT PIC S9(9) BINARY VALUE 19. 003162C 10 MQIA-NPM-CLASS PIC S9(9) BINARY VALUE 78. 003163C 10 MQIA-NPM-DELIVERY PIC S9(9) BINARY VALUE 196. 003164C 10 MQIA-OPEN-INPUT-COUNT PIC S9(9) BINARY VALUE 17. 003165C 10 MQIA-OPEN-OUTPUT-COUNT PIC S9(9) BINARY VALUE 18. 003166C 10 MQIA-OTEL-PROPAGATION-CONTROL PIC S9(9) BINARY VALUE 279. 003167C 10 MQIA-OTEL-TRACE PIC S9(9) BINARY VALUE 278. 003168C 10 MQIA-OUTBOUND-PORT-MAX PIC S9(9) BINARY VALUE 140. 003169C 10 MQIA-OUTBOUND-PORT-MIN PIC S9(9) BINARY VALUE 110. 003170C 10 MQIA-PAGESET-ID PIC S9(9) BINARY VALUE 62. 003171C 10 MQIA-PERFORMANCE-EVENT PIC S9(9) BINARY VALUE 53. 003172C 10 MQIA-PLATFORM PIC S9(9) BINARY VALUE 32. 003173C 10 MQIA-PM-DELIVERY PIC S9(9) BINARY VALUE 195. 003174C 10 MQIA-POLICY-VERSION PIC S9(9) BINARY VALUE 238. 003175C 10 MQIA-PROPERTY-CONTROL PIC S9(9) BINARY VALUE 190. 003176C 10 MQIA-PROT-POLICY-CAPABILITY PIC S9(9) BINARY VALUE 251. 003177C 10 MQIA-PROXY-SUB PIC S9(9) BINARY VALUE 199. 003178C 10 MQIA-PUBSUB-CLUSTER PIC S9(9) BINARY VALUE 249. 003179C 10 MQIA-PUBSUB-MAXMSG-RETRY-COUNT PIC S9(9) BINARY VALUE 206. 003180C 10 MQIA-PUBSUB-MODE PIC S9(9) BINARY VALUE 187. 003181C 10 MQIA-PUBSUB-NP-MSG PIC S9(9) BINARY VALUE 203. 003182C 10 MQIA-PUBSUB-NP-RESP PIC S9(9) BINARY VALUE 205. 003183C 10 MQIA-PUBSUB-SYNC-PT PIC S9(9) BINARY VALUE 207. 003184C 10 MQIA-PUB-COUNT PIC S9(9) BINARY VALUE 215. 003185C 10 MQIA-PUB-SCOPE PIC S9(9) BINARY VALUE 219. 003186C 10 MQIA-QMGR-CFCONLOS PIC S9(9) BINARY VALUE 245. 003187C 10 MQIA-QMOPT-CONS-COMMS-MSGS PIC S9(9) BINARY VALUE 155. 003188C 10 MQIA-QMOPT-CONS-CRITICAL-MSGS PIC S9(9) BINARY VALUE 154. 003189C 10 MQIA-QMOPT-CONS-ERROR-MSGS PIC S9(9) BINARY VALUE 153. 003190C 10 MQIA-QMOPT-CONS-INFO-MSGS PIC S9(9) BINARY VALUE 151. 003191C 10 MQIA-QMOPT-CONS-REORG-MSGS PIC S9(9) BINARY VALUE 156. 003192C 10 MQIA-QMOPT-CONS-SYSTEM-MSGS PIC S9(9) BINARY VALUE 157. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 60 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003193C 10 MQIA-QMOPT-CONS-WARNING-MSGS PIC S9(9) BINARY VALUE 152. 003194C 10 MQIA-QMOPT-CSMT-ON-ERROR PIC S9(9) BINARY VALUE 150. 003195C 10 MQIA-QMOPT-INTERNAL-DUMP PIC S9(9) BINARY VALUE 170. 003196C 10 MQIA-QMOPT-LOG-COMMS-MSGS PIC S9(9) BINARY VALUE 162. 003197C 10 MQIA-QMOPT-LOG-CRITICAL-MSGS PIC S9(9) BINARY VALUE 161. 003198C 10 MQIA-QMOPT-LOG-ERROR-MSGS PIC S9(9) BINARY VALUE 160. 003199C 10 MQIA-QMOPT-LOG-INFO-MSGS PIC S9(9) BINARY VALUE 158. 003200C 10 MQIA-QMOPT-LOG-REORG-MSGS PIC S9(9) BINARY VALUE 163. 003201C 10 MQIA-QMOPT-LOG-SYSTEM-MSGS PIC S9(9) BINARY VALUE 164. 003202C 10 MQIA-QMOPT-LOG-WARNING-MSGS PIC S9(9) BINARY VALUE 159. 003203C 10 MQIA-QMOPT-TRACE-COMMS PIC S9(9) BINARY VALUE 166. 003204C 10 MQIA-QMOPT-TRACE-CONVERSION PIC S9(9) BINARY VALUE 168. 003205C 10 MQIA-QMOPT-TRACE-MQI-CALLS PIC S9(9) BINARY VALUE 165. 003206C 10 MQIA-QMOPT-TRACE-REORG PIC S9(9) BINARY VALUE 167. 003207C 10 MQIA-QMOPT-TRACE-SYSTEM PIC S9(9) BINARY VALUE 169. 003208C 10 MQIA-QSG-DISP PIC S9(9) BINARY VALUE 63. 003209C 10 MQIA-Q-DEPTH-HIGH-EVENT PIC S9(9) BINARY VALUE 43. 003210C 10 MQIA-Q-DEPTH-HIGH-LIMIT PIC S9(9) BINARY VALUE 40. 003211C 10 MQIA-Q-DEPTH-LOW-EVENT PIC S9(9) BINARY VALUE 44. 003212C 10 MQIA-Q-DEPTH-LOW-LIMIT PIC S9(9) BINARY VALUE 41. 003213C 10 MQIA-Q-DEPTH-MAX-EVENT PIC S9(9) BINARY VALUE 42. 003214C 10 MQIA-Q-SERVICE-INTERVAL PIC S9(9) BINARY VALUE 54. 003215C 10 MQIA-Q-SERVICE-INTERVAL-EVENT PIC S9(9) BINARY VALUE 46. 003216C 10 MQIA-Q-TYPE PIC S9(9) BINARY VALUE 20. 003217C 10 MQIA-Q-USERS PIC S9(9) BINARY VALUE 82. 003218C 10 MQIA-READ-AHEAD PIC S9(9) BINARY VALUE 189. 003219C 10 MQIA-RECEIVE-TIMEOUT PIC S9(9) BINARY VALUE 111. 003220C 10 MQIA-RECEIVE-TIMEOUT-MIN PIC S9(9) BINARY VALUE 113. 003221C 10 MQIA-RECEIVE-TIMEOUT-TYPE PIC S9(9) BINARY VALUE 112. 003222C 10 MQIA-REMOTE-EVENT PIC S9(9) BINARY VALUE 50. 003223C 10 MQIA-RESPONSE-RESTART-POINT PIC S9(9) BINARY VALUE 231. 003224C 10 MQIA-RETENTION-INTERVAL PIC S9(9) BINARY VALUE 21. 003225C 10 MQIA-REVERSE-DNS-LOOKUP PIC S9(9) BINARY VALUE 254. 003226C 10 MQIA-SCOPE PIC S9(9) BINARY VALUE 45. 003227C 10 MQIA-SECURITY-CASE PIC S9(9) BINARY VALUE 141. 003228C 10 MQIA-SERVICE-CONTROL PIC S9(9) BINARY VALUE 139. 003229C 10 MQIA-SERVICE-TYPE PIC S9(9) BINARY VALUE 121. 003230C 10 MQIA-SHAREABILITY PIC S9(9) BINARY VALUE 23. 003231C 10 MQIA-SHARED-Q-Q-MGR-NAME PIC S9(9) BINARY VALUE 77. 003232C 10 MQIA-SIGNATURE-ALGORITHM PIC S9(9) BINARY VALUE 236. 003233C 10 MQIA-SSL-EVENT PIC S9(9) BINARY VALUE 75. 003234C 10 MQIA-SSL-FIPS-REQUIRED PIC S9(9) BINARY VALUE 92. 003235C 10 MQIA-SSL-RESET-COUNT PIC S9(9) BINARY VALUE 76. 003236C 10 MQIA-SSL-TASKS PIC S9(9) BINARY VALUE 69. 003237C 10 MQIA-START-STOP-EVENT PIC S9(9) BINARY VALUE 52. 003238C 10 MQIA-STATISTICS-AUTO-CLUSSDR PIC S9(9) BINARY VALUE 130. 003239C 10 MQIA-STATISTICS-CHANNEL PIC S9(9) BINARY VALUE 129. 003240C 10 MQIA-STATISTICS-INTERVAL PIC S9(9) BINARY VALUE 131. 003241C 10 MQIA-STATISTICS-MQI PIC S9(9) BINARY VALUE 127. 003242C 10 MQIA-STATISTICS-Q PIC S9(9) BINARY VALUE 128. 003243C 10 MQIA-STREAM-QUEUE-QOS PIC S9(9) BINARY VALUE 275. 003244C 10 MQIA-SUB-CONFIGURATION-EVENT PIC S9(9) BINARY VALUE 242. 003245C 10 MQIA-SUB-COUNT PIC S9(9) BINARY VALUE 204. 003246C 10 MQIA-SUB-SCOPE PIC S9(9) BINARY VALUE 218. 003247C 10 MQIA-SUITE-B-STRENGTH PIC S9(9) BINARY VALUE 247. 003248C 10 MQIA-SYNCPOINT PIC S9(9) BINARY VALUE 30. 003249C 10 MQIA-TCP-CHANNELS PIC S9(9) BINARY VALUE 114. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 61 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003250C 10 MQIA-TCP-KEEP-ALIVE PIC S9(9) BINARY VALUE 115. 003251C 10 MQIA-TCP-STACK-TYPE PIC S9(9) BINARY VALUE 116. 003252C 10 MQIA-TIME-SINCE-RESET PIC S9(9) BINARY VALUE 35. 003253C 10 MQIA-TOLERATE-UNPROTECTED PIC S9(9) BINARY VALUE 235. 003254C 10 MQIA-TOPIC-DEF-PERSISTENCE PIC S9(9) BINARY VALUE 185. 003255C 10 MQIA-TOPIC-NODE-COUNT PIC S9(9) BINARY VALUE 253. 003256C 10 MQIA-TOPIC-TYPE PIC S9(9) BINARY VALUE 208. 003257C 10 MQIA-TRACE-ROUTE-RECORDING PIC S9(9) BINARY VALUE 137. 003258C 10 MQIA-TREE-LIFE-TIME PIC S9(9) BINARY VALUE 183. 003259C 10 MQIA-TRIGGER-CONTROL PIC S9(9) BINARY VALUE 24. 003260C 10 MQIA-TRIGGER-DEPTH PIC S9(9) BINARY VALUE 29. 003261C 10 MQIA-TRIGGER-INTERVAL PIC S9(9) BINARY VALUE 25. 003262C 10 MQIA-TRIGGER-MSG-PRIORITY PIC S9(9) BINARY VALUE 26. 003263C 10 MQIA-TRIGGER-RESTART PIC S9(9) BINARY VALUE 91. 003264C 10 MQIA-TRIGGER-TYPE PIC S9(9) BINARY VALUE 28. 003265C 10 MQIA-UR-DISP PIC S9(9) BINARY VALUE 222. 003266C 10 MQIA-USAGE PIC S9(9) BINARY VALUE 12. 003267C 10 MQIA-USER-LIST PIC S9(9) BINARY VALUE 2000. 003268C 10 MQIA-USE-DEAD-LETTER-Q PIC S9(9) BINARY VALUE 234. 003269C 10 MQIA-WILDCARD-OPERATION PIC S9(9) BINARY VALUE 216. 003270C 10 MQIA-XR-CAPABILITY PIC S9(9) BINARY VALUE 243. 003271C 003272C ** Integer Attribute Values 003273C 10 MQIAV-NOT-APPLICABLE PIC S9(9) BINARY VALUE -1. 003274C 10 MQIAV-UNDEFINED PIC S9(9) BINARY VALUE -2. 003275C 003276C ** CommInfo Bridge 003277C 10 MQMCB-DISABLED PIC S9(9) BINARY VALUE 0. 003278C 10 MQMCB-ENABLED PIC S9(9) BINARY VALUE 1. 003279C 003280C ** Key reuse count 003281C 10 MQKEY-REUSE-DISABLED PIC S9(9) BINARY VALUE 0. 003282C 10 MQKEY-REUSE-UNLIMITED PIC S9(9) BINARY VALUE -1. 003283C 003284C ** Group Attribute Selectors 003285C 10 MQGA-FIRST PIC S9(9) BINARY VALUE 8001. 003286C 10 MQGA-LAST PIC S9(9) BINARY VALUE 9000. 003287C 003288C ****************************************************************** 003289C ** Values Related to MQOPEN Function 003290C ****************************************************************** 003291C ** Open Options 003292C 10 MQOO-BIND-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003293C 10 MQOO-READ-AHEAD-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003294C 10 MQOO-INPUT-AS-Q-DEF PIC S9(9) BINARY VALUE 1. 003295C 10 MQOO-INPUT-SHARED PIC S9(9) BINARY VALUE 2. 003296C 10 MQOO-INPUT-EXCLUSIVE PIC S9(9) BINARY VALUE 4. 003297C 10 MQOO-BROWSE PIC S9(9) BINARY VALUE 8. 003298C 10 MQOO-OUTPUT PIC S9(9) BINARY VALUE 16. 003299C 10 MQOO-INQUIRE PIC S9(9) BINARY VALUE 32. 003300C 10 MQOO-SET PIC S9(9) BINARY VALUE 64. 003301C 10 MQOO-SAVE-ALL-CONTEXT PIC S9(9) BINARY VALUE 128. 003302C 10 MQOO-PASS-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 256. 003303C 10 MQOO-PASS-ALL-CONTEXT PIC S9(9) BINARY VALUE 512. 003304C 10 MQOO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 1024. 003305C 10 MQOO-SET-ALL-CONTEXT PIC S9(9) BINARY VALUE 2048. 003306C 10 MQOO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY VALUE 4096. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 62 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003307C 10 MQOO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 003308C 10 MQOO-BIND-ON-OPEN PIC S9(9) BINARY VALUE 16384. 003309C 10 MQOO-BIND-ON-GROUP PIC S9(9) BINARY VALUE 4194304. 003310C 10 MQOO-BIND-NOT-FIXED PIC S9(9) BINARY VALUE 32768. 003311C 10 MQOO-CO-OP PIC S9(9) BINARY VALUE 131072. 003312C 10 MQOO-NO-READ-AHEAD PIC S9(9) BINARY VALUE 524288. 003313C 10 MQOO-READ-AHEAD PIC S9(9) BINARY VALUE 1048576. 003314C 10 MQOO-NO-MULTICAST PIC S9(9) BINARY VALUE 2097152. 003315C 10 MQOO-RESOLVE-LOCAL-Q PIC S9(9) BINARY VALUE 262144. 003316C 10 MQOO-RESOLVE-LOCAL-TOPIC PIC S9(9) BINARY VALUE 262144. 003317C 003318C ** Following used in C++ only 003319C 10 MQOO-RESOLVE-NAMES PIC S9(9) BINARY VALUE 65536. 003320C 003321C ****************************************************************** 003322C ** Values Related to MQSETMP Function 003323C ****************************************************************** 003324C ** Property data types 003325C 10 MQTYPE-AS-SET PIC S9(9) BINARY VALUE 0. 003326C 10 MQTYPE-NULL PIC S9(9) BINARY VALUE 2. 003327C 10 MQTYPE-BOOLEAN PIC S9(9) BINARY VALUE 4. 003328C 10 MQTYPE-BYTE-STRING PIC S9(9) BINARY VALUE 8. 003329C 10 MQTYPE-INT8 PIC S9(9) BINARY VALUE 16. 003330C 10 MQTYPE-INT16 PIC S9(9) BINARY VALUE 32. 003331C 10 MQTYPE-INT32 PIC S9(9) BINARY VALUE 64. 003332C 10 MQTYPE-LONG PIC S9(9) BINARY VALUE 64. 003333C 10 MQTYPE-INT64 PIC S9(9) BINARY VALUE 128. 003334C 10 MQTYPE-FLOAT32 PIC S9(9) BINARY VALUE 256. 003335C 10 MQTYPE-FLOAT64 PIC S9(9) BINARY VALUE 512. 003336C 10 MQTYPE-STRING PIC S9(9) BINARY VALUE 1024. 003337C 003338C ** Property value lengths 003339C 10 MQVL-NULL-TERMINATED PIC S9(9) BINARY VALUE -1. 003340C 10 MQVL-EMPTY-STRING PIC S9(9) BINARY VALUE 0. 003341C 003342C ****************************************************************** 003343C ** Values Related to MQSTAT Function 003344C ****************************************************************** 003345C ** Stat Options 003346C 10 MQSTAT-TYPE-ASYNC-ERROR PIC S9(9) BINARY VALUE 0. 003347C 10 MQSTAT-TYPE-RECONNECTION PIC S9(9) BINARY VALUE 1. 003348C 10 MQSTAT-TYPE-RECONNECTION-ERROR PIC S9(9) BINARY VALUE 2. 003349C 003350C ****************************************************************** 003351C ** Values Related to MQSUB Function 003352C ****************************************************************** 003353C ** Subscribe Options 003354C 10 MQSO-NONE PIC S9(9) BINARY VALUE 0. 003355C 10 MQSO-NON-DURABLE PIC S9(9) BINARY VALUE 0. 003356C 10 MQSO-READ-AHEAD-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003357C 10 MQSO-ALTER PIC S9(9) BINARY VALUE 1. 003358C 10 MQSO-CREATE PIC S9(9) BINARY VALUE 2. 003359C 10 MQSO-RESUME PIC S9(9) BINARY VALUE 4. 003360C 10 MQSO-DURABLE PIC S9(9) BINARY VALUE 8. 003361C 10 MQSO-GROUP-SUB PIC S9(9) BINARY VALUE 16. 003362C 10 MQSO-MANAGED PIC S9(9) BINARY VALUE 32. 003363C 10 MQSO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 64. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 63 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003364C 10 MQSO-NO-MULTICAST PIC S9(9) BINARY VALUE 128. 003365C 10 MQSO-FIXED-USERID PIC S9(9) BINARY VALUE 256. 003366C 10 MQSO-ANY-USERID PIC S9(9) BINARY VALUE 512. 003367C 10 MQSO-PUBLICATIONS-ON-REQUEST PIC S9(9) BINARY VALUE 2048. 003368C 10 MQSO-NEW-PUBLICATIONS-ONLY PIC S9(9) BINARY VALUE 4096. 003369C 10 MQSO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 003370C 10 MQSO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY 003371C VALUE 262144. 003372C 10 MQSO-WILDCARD-CHAR PIC S9(9) BINARY VALUE 1048576. 003373C 10 MQSO-WILDCARD-TOPIC PIC S9(9) BINARY VALUE 2097152. 003374C 10 MQSO-SET-CORREL-ID PIC S9(9) BINARY VALUE 4194304. 003375C 10 MQSO-SCOPE-QMGR PIC S9(9) BINARY VALUE 67108864. 003376C 10 MQSO-NO-READ-AHEAD PIC S9(9) BINARY VALUE 134217728. 003377C 10 MQSO-READ-AHEAD PIC S9(9) BINARY VALUE 268435456. 003378C 003379C ****************************************************************** 003380C ** Values Related to MQSUBRQ Function 003381C ****************************************************************** 003382C ** Action 003383C 10 MQSR-ACTION-PUBLICATION PIC S9(9) BINARY VALUE 1. 003384C 003385C ** 003386C 003387C ****************************************************************** 003388C ** Constants for MQ Extended Reach 003389C ****************************************************************** 003390C ** General Constants 003391C 10 MQ-MQTT-MAX-KEEP-ALIVE PIC S9(9) BINARY VALUE 65536. 003392C 10 MQ-SSL-KEY-PASSPHRASE-LENGTH PIC S9(9) BINARY VALUE 1024. 003393C 003394C 003395C 003396C ****************************************************************** 003397C ** End of CMQV ** 003398C ****************************************************************** 003399 003400 01 MQM-OBJECT-DESCRIPTOR. 003401 COPY CMQODV. 003402C ****************************************************************** 003403C ** ** 003404C ** IBM MQ for z/OS ** 003405C ** ** 003406C ** FILE NAME: CMQODV ** 003407C ** ** 003408C ** DESCRIPTION: MQOD Structure -- Object descriptor ** 003409C ** ** 003410C ****************************************************************** 003411C ** @START_COPYRIGHT@ ** 003412C ** Statement: Licensed Materials - Property of IBM ** 003413C ** ** 003414C ** 5655-MQ9 ** 003415C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003416C ** @END_COPYRIGHT@ ** 003417C ****************************************************************** 003418C ** ** 003419C ** FUNCTION: This file declares the structure MQOD, ** 003420C ** which is used by the main MQI. ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 64 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003421C ** ** 003422C ** PROCESSOR: COBOL ** 003423C ** ** 003424C ****************************************************************** 003425C 003426C ** MQOD structure 003427C 10 MQOD. 003428C ** Structure identifier 003429C 15 MQOD-STRUCID PIC X(4) VALUE 'OD '. 003430C ** Structure version number 003431C 15 MQOD-VERSION PIC S9(9) BINARY VALUE 1. 003432C ** Object type 003433C 15 MQOD-OBJECTTYPE PIC S9(9) BINARY VALUE 1. 003434C ** Object name 003435C 15 MQOD-OBJECTNAME PIC X(48) VALUE SPACES. 003436C ** Object queue manager name 003437C 15 MQOD-OBJECTQMGRNAME PIC X(48) VALUE SPACES. 003438C ** Dynamic queue name 003439C 15 MQOD-DYNAMICQNAME PIC X(48) VALUE 'CSQ.*'. 003440C ** Alternate user identifier 003441C 15 MQOD-ALTERNATEUSERID PIC X(12) VALUE SPACES. 003442C ** Ver:1 ** 003443C ** Number of object records present 003444C 15 MQOD-RECSPRESENT PIC S9(9) BINARY VALUE 0. 003445C ** Number of local queues opened successfully 003446C 15 MQOD-KNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003447C ** Number of remote queues opened 003448C 15 MQOD-UNKNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003449C ** Number of queues that failed to open 003450C 15 MQOD-INVALIDDESTCOUNT PIC S9(9) BINARY VALUE 0. 003451C ** Offset of first object record from start of MQOD 003452C 15 MQOD-OBJECTRECOFFSET PIC S9(9) BINARY VALUE 0. 003453C ** Offset of first response record from start of MQOD 003454C 15 MQOD-RESPONSERECOFFSET PIC S9(9) BINARY VALUE 0. 003455C ** Address of first object record 003456C 15 MQOD-OBJECTRECPTR POINTER VALUE NULL. 003457C ** Address of first response record 003458C 15 MQOD-RESPONSERECPTR POINTER VALUE NULL. 003459C ** Ver:2 ** 003460C ** Alternate security identifier 003461C 15 MQOD-ALTERNATESECURITYID PIC X(40) VALUE LOW-VALUES. 003462C ** Resolved queue name 003463C 15 MQOD-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003464C ** Resolved queue manager name 003465C 15 MQOD-RESOLVEDQMGRNAME PIC X(48) VALUE SPACES. 003466C ** Ver:3 ** 003467C ** Object long name 003468C 15 MQOD-OBJECTSTRING. 003469C ** Address of variable length string 003470C 20 MQOD-OBJECTSTRING-VSPTR POINTER VALUE NULL. 003471C ** Offset of variable length string 003472C 20 MQOD-OBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003473C ** Size of buffer 003474C 20 MQOD-OBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003475C ** Length of variable length string 003476C 20 MQOD-OBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003477C ** CCSID of variable length string 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 65 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003478C 20 MQOD-OBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003479C ** Message Selector 003480C 15 MQOD-SELECTIONSTRING. 003481C ** Address of variable length string 003482C 20 MQOD-SELECTIONSTRING-VSPTR POINTER VALUE NULL. 003483C ** Offset of variable length string 003484C 20 MQOD-SELECTIONSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003485C ** Size of buffer 003486C 20 MQOD-SELECTIONSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003487C ** Length of variable length string 003488C 20 MQOD-SELECTIONSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003489C ** CCSID of variable length string 003490C 20 MQOD-SELECTIONSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003491C ** Resolved long object name 003492C 15 MQOD-RESOBJECTSTRING. 003493C ** Address of variable length string 003494C 20 MQOD-RESOBJECTSTRING-VSPTR POINTER VALUE NULL. 003495C ** Offset of variable length string 003496C 20 MQOD-RESOBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003497C ** Size of buffer 003498C 20 MQOD-RESOBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003499C ** Length of variable length string 003500C 20 MQOD-RESOBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003501C ** CCSID of variable length string 003502C 20 MQOD-RESOBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003503C ** Alias queue resolved object type 003504C 15 MQOD-RESOLVEDTYPE PIC S9(9) BINARY VALUE 0. 003505C ** Ver:4 ** 003506C 003507C 003508C ****************************************************************** 003509C ** End of CMQODV ** 003510C ****************************************************************** 003511 003512 01 MQM-MESSAGE-DESCRIPTOR. 003513 COPY CMQMDV. 003514C ****************************************************************** 003515C ** ** 003516C ** IBM MQ for z/OS ** 003517C ** ** 003518C ** FILE NAME: CMQMDV ** 003519C ** ** 003520C ** DESCRIPTION: MQMD Structure -- Message Descriptor ** 003521C ** ** 003522C ****************************************************************** 003523C ** @START_COPYRIGHT@ ** 003524C ** Statement: Licensed Materials - Property of IBM ** 003525C ** ** 003526C ** 5655-MQ9 ** 003527C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003528C ** @END_COPYRIGHT@ ** 003529C ****************************************************************** 003530C ** ** 003531C ** FUNCTION: This file declares the structure MQMD, ** 003532C ** which is used by the main MQI. ** 003533C ** ** 003534C ** PROCESSOR: COBOL ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 66 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003535C ** ** 003536C ****************************************************************** 003537C 003538C ** MQMD structure 003539C 10 MQMD. 003540C ** Structure identifier 003541C 15 MQMD-STRUCID PIC X(4) VALUE 'MD '. 003542C ** Structure version number 003543C 15 MQMD-VERSION PIC S9(9) BINARY VALUE 1. 003544C ** Options for report messages 003545C 15 MQMD-REPORT PIC S9(9) BINARY VALUE 0. 003546C ** Message type 003547C 15 MQMD-MSGTYPE PIC S9(9) BINARY VALUE 8. 003548C ** Message lifetime 003549C 15 MQMD-EXPIRY PIC S9(9) BINARY VALUE -1. 003550C ** Feedback or reason code 003551C 15 MQMD-FEEDBACK PIC S9(9) BINARY VALUE 0. 003552C ** Numeric encoding of message data 003553C 15 MQMD-ENCODING PIC S9(9) BINARY VALUE 785. 003554C ** Character set identifier of message data 003555C 15 MQMD-CODEDCHARSETID PIC S9(9) BINARY VALUE 0. 003556C ** Format name of message data 003557C 15 MQMD-FORMAT PIC X(8) VALUE SPACES. 003558C ** Message priority 003559C 15 MQMD-PRIORITY PIC S9(9) BINARY VALUE -1. 003560C ** Message persistence 003561C 15 MQMD-PERSISTENCE PIC S9(9) BINARY VALUE 2. 003562C ** Message identifier 003563C 15 MQMD-MSGID PIC X(24) VALUE LOW-VALUES. 003564C ** Correlation identifier 003565C 15 MQMD-CORRELID PIC X(24) VALUE LOW-VALUES. 003566C ** Backout counter 003567C 15 MQMD-BACKOUTCOUNT PIC S9(9) BINARY VALUE 0. 003568C ** Name of reply queue 003569C 15 MQMD-REPLYTOQ PIC X(48) VALUE SPACES. 003570C ** Name of reply queue manager 003571C 15 MQMD-REPLYTOQMGR PIC X(48) VALUE SPACES. 003572C ** User identifier 003573C 15 MQMD-USERIDENTIFIER PIC X(12) VALUE SPACES. 003574C ** Accounting token 003575C 15 MQMD-ACCOUNTINGTOKEN PIC X(32) VALUE LOW-VALUES. 003576C ** Application data relating to identity 003577C 15 MQMD-APPLIDENTITYDATA PIC X(32) VALUE SPACES. 003578C ** Type of application that put the message 003579C 15 MQMD-PUTAPPLTYPE PIC S9(9) BINARY VALUE 0. 003580C ** Name of application that put the message 003581C 15 MQMD-PUTAPPLNAME PIC X(28) VALUE SPACES. 003582C ** Date when message was put 003583C 15 MQMD-PUTDATE PIC X(8) VALUE SPACES. 003584C ** Time when message was put 003585C 15 MQMD-PUTTIME PIC X(8) VALUE SPACES. 003586C ** Application data relating to origin 003587C 15 MQMD-APPLORIGINDATA PIC X(4) VALUE SPACES. 003588C ** Ver:1 ** 003589C 003590C 003591C ****************************************************************** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 67 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003592C ** End of CMQMDV ** 003593C ****************************************************************** 003594 003595 01 MQM-GET-MESSAGE-OPTIONS. 003596 COPY CMQGMOV. 003597C ****************************************************************** 003598C ** ** 003599C ** IBM MQ for z/OS ** 003600C ** ** 003601C ** FILE NAME: CMQGMOV ** 003602C ** ** 003603C ** DESCRIPTION: MQGMO Structure -- Get Message Options ** 003604C ** ** 003605C ****************************************************************** 003606C ** @START_COPYRIGHT@ ** 003607C ** Statement: Licensed Materials - Property of IBM ** 003608C ** ** 003609C ** 5655-MQ9 ** 003610C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003611C ** @END_COPYRIGHT@ ** 003612C ****************************************************************** 003613C ** ** 003614C ** FUNCTION: This file declares the structure MQGMO, ** 003615C ** which is used by the main MQI. ** 003616C ** ** 003617C ** PROCESSOR: COBOL ** 003618C ** ** 003619C ****************************************************************** 003620C 003621C ** MQGMO structure 003622C 10 MQGMO. 003623C ** Structure identifier 003624C 15 MQGMO-STRUCID PIC X(4) VALUE 'GMO '. 003625C ** Structure version number 003626C 15 MQGMO-VERSION PIC S9(9) BINARY VALUE 1. 003627C ** Options that control the action of MQGET 003628C 15 MQGMO-OPTIONS PIC S9(9) BINARY VALUE 0. 003629C ** Wait interval 003630C 15 MQGMO-WAITINTERVAL PIC S9(9) BINARY VALUE 0. 003631C ** Signal 003632C 15 MQGMO-SIGNAL1 POINTER VALUE NULL. 003633C ** Signal identifier 003634C 15 MQGMO-SIGNAL2 PIC S9(9) BINARY VALUE 0. 003635C ** Resolved name of destination queue 003636C 15 MQGMO-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003637C ** Ver:1 ** 003638C ** Options controlling selection criteria used for MQGET 003639C 15 MQGMO-MATCHOPTIONS PIC S9(9) BINARY VALUE 3. 003640C ** Flag indicating whether message retrieved is in a group 003641C 15 MQGMO-GROUPSTATUS PIC X VALUE ' '. 003642C ** Flag indicating whether message retrieved is a segment of a 003643C ** logical message 003644C 15 MQGMO-SEGMENTSTATUS PIC X VALUE ' '. 003645C ** Flag indicating whether further segmentation is allowed for 003646C ** the message retrieved 003647C 15 MQGMO-SEGMENTATION PIC X VALUE ' '. 003648C ** Reserved 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 68 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003649C 15 MQGMO-RESERVED1 PIC X VALUE ' '. 003650C ** Ver:2 ** 003651C ** Message token 003652C 15 MQGMO-MSGTOKEN PIC X(16) VALUE LOW-VALUES. 003653C ** Length of message data returned (bytes) 003654C 15 MQGMO-RETURNEDLENGTH PIC S9(9) BINARY VALUE -1. 003655C ** Ver:3 ** 003656C ** Reserved 003657C 15 MQGMO-RESERVED2 PIC S9(9) BINARY VALUE 0. 003658C ** Message handle 003659C 15 MQGMO-MSGHANDLE PIC S9(18) BINARY VALUE 0. 003660C ** Ver:4 ** 003661C 003662C 003663C ****************************************************************** 003664C ** End of CMQGMOV ** 003665C ****************************************************************** 003666 003667 01 MQM-PUT-MESSAGE-OPTIONS. 003668 COPY CMQPMOV. 003669C ****************************************************************** 003670C ** ** 003671C ** IBM MQ for z/OS ** 003672C ** ** 003673C ** FILE NAME: CMQPMOV ** 003674C ** ** 003675C ** DESCRIPTION: MQPMO Structure -- Put Message Options ** 003676C ** ** 003677C ****************************************************************** 003678C ** @START_COPYRIGHT@ ** 003679C ** Statement: Licensed Materials - Property of IBM ** 003680C ** ** 003681C ** 5655-MQ9 ** 003682C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003683C ** @END_COPYRIGHT@ ** 003684C ****************************************************************** 003685C ** ** 003686C ** FUNCTION: This file declares the structure MQPMO, ** 003687C ** which is used by the main MQI. ** 003688C ** ** 003689C ** PROCESSOR: COBOL ** 003690C ** ** 003691C ****************************************************************** 003692C 003693C ** MQPMO structure 003694C 10 MQPMO. 003695C ** Structure identifier 003696C 15 MQPMO-STRUCID PIC X(4) VALUE 'PMO '. 003697C ** Structure version number 003698C 15 MQPMO-VERSION PIC S9(9) BINARY VALUE 1. 003699C ** Options that control the action of MQPUT and MQPUT1 003700C 15 MQPMO-OPTIONS PIC S9(9) BINARY VALUE 0. 003701C ** Reserved 003702C 15 MQPMO-TIMEOUT PIC S9(9) BINARY VALUE -1. 003703C ** Object handle of input queue 003704C 15 MQPMO-CONTEXT PIC S9(9) BINARY VALUE 0. 003705C ** Number of messages sent successfully to local queues 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 69 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003706C 15 MQPMO-KNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003707C ** Number of messages sent successfully to remote queues 003708C 15 MQPMO-UNKNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003709C ** Number of messages that could not be sent 003710C 15 MQPMO-INVALIDDESTCOUNT PIC S9(9) BINARY VALUE 0. 003711C ** Resolved name of destination queue 003712C 15 MQPMO-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003713C ** Resolved name of destination queue manager 003714C 15 MQPMO-RESOLVEDQMGRNAME PIC X(48) VALUE SPACES. 003715C ** Ver:1 ** 003716C ** Number of put message records or response records present 003717C 15 MQPMO-RECSPRESENT PIC S9(9) BINARY VALUE 0. 003718C ** Flags indicating which MQPMR fields are present 003719C 15 MQPMO-PUTMSGRECFIELDS PIC S9(9) BINARY VALUE 0. 003720C ** Offset of first put message record from start of MQPMO 003721C 15 MQPMO-PUTMSGRECOFFSET PIC S9(9) BINARY VALUE 0. 003722C ** Offset of first response record from start of MQPMO 003723C 15 MQPMO-RESPONSERECOFFSET PIC S9(9) BINARY VALUE 0. 003724C ** Address of first put message record 003725C 15 MQPMO-PUTMSGRECPTR POINTER VALUE NULL. 003726C ** Address of first response record 003727C 15 MQPMO-RESPONSERECPTR POINTER VALUE NULL. 003728C ** Ver:2 ** 003729C ** Original message handle 003730C 15 MQPMO-ORIGINALMSGHANDLE PIC S9(18) BINARY VALUE 0. 003731C ** New message handle 003732C 15 MQPMO-NEWMSGHANDLE PIC S9(18) BINARY VALUE 0. 003733C ** The action being performed 003734C 15 MQPMO-ACTION PIC S9(9) BINARY VALUE 0. 003735C ** Publication level 003736C 15 MQPMO-PUBLEVEL PIC S9(9) BINARY VALUE 9. 003737C ** Ver:3 **

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Вот ссылки на **новый вариант**:

- LIBMQCIC_mqdefaults_trace.cbl
    
- LIBMQCIC_mqdefaults_trace.diff
    

(Если ты имел в виду _какой-то другой_ “новый вариант” из более старых файлов — часть прежних загрузок уже успела “протухнуть”, тогда просто перезагрузи их сюда, и я снова дам ссылки.)

---

## Нужно ли `CBL SQL OFFSET TEST NOXREF NOMAP`?

Коротко: **это нормальный “debug-friendly” набор**, но “нужно” зависит от цели компиляции (debug vs prod).

### Что реально важно

- **`SQL`** — _да_, если у тебя embedded SQL (`EXEC SQL ... END-EXEC`) и нужен DB2 SQL coprocessor.
    
- **`TEST`** — _да_, если хочешь отладку (DBG/Debug Tool): брейкпоинты, просмотр переменных и т.д.
    
- **`OFFSET`** — обычно _да_ для диагностики/отладки (смещения в объектнике, полезно в dumps/листингах).
    

### Что “по вкусу”

- **`NOMAP`** — отключает MAP в листинге (меньше бумаги/спула). Если тебе нужно видеть MAP, ставь `MAP`.
    
- **`NOXREF`** — отключает cross-reference (тоже уменьшает листинг). Если надо искать “где используется поле/параграф” — ставь `XREF`.
    

### Типичные профили

**Для отладки (DEV/TEST):**

- `CBL SQL OFFSET TEST ...`
    
- `MAP/XREF` — по ситуации (включай, если реально пользуешься листингом)
    

**Для продакшена (PROD):**

- обычно **без `TEST`** (и часто без `OFFSET`, если нет требований)
    
- `NOXREF NOMAP` часто оставляют, чтобы не раздувать листинги
    

---

## По твоему листингу — всё ок, но есть нюанс CCSID

У тебя компилятор пишет:

- SQL обрабатывается в **CCSID 1140**,
    
- а `DSNHDECP` имеет **EBCDIC CCSID 1047** (и потому warning).
    

Это **не про `CBL ...`**, а про настройки DB2/ко-процессора (DSNHDECP, CCSID/апострофы/кавычки). Если начнутся странности с национальными символами в SQL-литералах — тогда уже надо ровнять CCSID.

Если скажешь, **как ты компилируешь** (JCL/PROC — IGYCRCTL + DSNHPC/DSNHCOB? или “integrated” через COBOL), я дам точный “рекомендованный” compile step и где правильно задавать CCSID/DSNHDECP.

  

1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 1 0Invocation parameters: SQL 0PROCESS(CBL) statements: CBL SQL OFFSET TEST NOXREF NOMAP Process rent,nodynam 0Options in effect: NOADATA ADV AFP(NOVOLATILE) QUOTE ARCH(10) ARITH(COMPAT) NOAWO NOBLOCK0 BUFSIZE(4096) NOCICS CODEPAGE(1140) NOCOMPILE(S) CONDCOMP(NOSKIPSRC) NOCOPYLOC NOCOPYRIGHT NOCURRENCY DATA(31) DBCS NODECK NODEFINE NODIAGTRUNC DISPSIGN(COMPAT) NODLL NODUMP NODYNAM NOEXIT NOEXPORTALL NOFASTSRT FLAG(I,I) NOFLAGSTD HGPR(PRESERVE) NOINITCHECK NOINITIAL INLINE INTDATE(ANSI) NOINVDATA NOJAVAIOP LANGUAGE(EN) LINECOUNT(60) NOLIST LP(32) NOLSACHECK NOMAP MAXPCF(100000) NOMDECK NONAME NSYMBOL(NATIONAL) NONUMBER NONUMCHECK NUMPROC(NOPFD) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 2 0 OBJECT OFFSET OPTIMIZE(0) OUTDD(SYSOUT) NOPARMCHECK PGMNAME(COMPAT) QUALIFY(COMPAT) RENT RMODE(AUTO) NORULES NOSERVICE SEQUENCE SMARTBIN(NONAMES) SOURCE(DEC) SPACE(1) SQL SQLCCSID NOSQLIMS NOSSRANGE NOSTGOPT SUPPRESS NOTERM TEST(NOEJPD,DWARF,SOURCE,NOSEPARATE) NOTHREAD TRUNC(STD) TUNE(10) NOVBREF VLR(STANDARD) VSAMOPENFS(COMPAT) NOWORD XMLPARSE(XMLSS) NOXREF ZWB IGYOS4077-I DSNH4790I DSNHPSRV DSNHDECP HAS CCSID 1047 IN EFFECT IGYOS4078-W DSNH4791I DSNHPSRV CCSID 1140 IS USED TO PROCESS SQL, BUT DSNHDECP HAS EBCDIC CCSID 1047 IN EFFECT IGYOS4077-I DSNH4760I DSNHPSRV THE DB2 SQL COPROCESSOR IS USING THE LEVEL 2 INTERFACE UNDER DB2 V13 -SQL Options in effect: ATTACH(TSO) CCSID(1140) CONNECT(2) DEC(15) DECP(DSNHDECP) SQLLEVEL(V13R1M504) ONEPASS PERIOD QUOTESQL STDSQL(NO) SQL(DB2) NOXREF NOSOURCE 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:31:42 Page 3 0 DSNHDECP LOADED FROM - (DSND10.DBDG.SDSNEXIT(DSNHDECP)) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 4 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000001 IDENTIFICATION DIVISION. 000002 PROGRAM-ID. LIBMQCIC. 000003 000004 ENVIRONMENT DIVISION. 000005 INPUT-OUTPUT SECTION. 000006 FILE-CONTROL. 000007 SELECT PARAMSFILE ASSIGN TO PARAMS 000008 ORGANIZATION IS SEQUENTIAL 000009 ACCESS IS SEQUENTIAL 000010 FILE STATUS IS PARAMS-STATUS. 000011 000012 DATA DIVISION. 000013 FILE SECTION. 000014 FD PARAMSFILE 000015 RECORDING MODE IS F 000016 RECORD CONTAINS 80 CHARACTERS. 000017 01 PARAMS-REC PIC X(80). 000018 000019 WORKING-STORAGE SECTION. 000020 000021 EXEC SQL INCLUDE SQLCA END-EXEC. 000022C 01 SQLCA GLOBAL VOLATILE. 000023C 05 SQLCAID PIC X(8). 000024C 05 SQLCABC PIC S9(9) COMP-5. 000025C 05 SQLCODE PIC S9(9) COMP-5. 000026C 05 SQLERRM. 000027C 49 SQLERRML PIC S9(4) COMP-5. 000028C 49 SQLERRMC PIC X(70). 000029C 05 SQLERRP PIC X(8). 000030C 05 SQLERRD PIC S9(9) COMP-5 000031C OCCURS 6 TIMES. 000032C 05 SQLWARN. 000033C 10 SQLWARN0 PIC X. 000034C 10 SQLWARN1 PIC X. 000035C 10 SQLWARN2 PIC X. 000036C 10 SQLWARN3 PIC X. 000037C 10 SQLWARN4 PIC X. 000038C 10 SQLWARN5 PIC X. 000039C 10 SQLWARN6 PIC X. 000040C 10 SQLWARN7 PIC X. 000041C 05 SQLEXT. 000042C 10 SQLWARN8 PIC X. 000043C 10 SQLWARN9 PIC X. 000044C 10 SQLWARNA PIC X. 000045C 10 SQLSTATE PIC X(5). 000046 000047 01 PARAMS-STATUS PIC XX. 000048 01 WS-SQLCODE-EDIT PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY. 000049 000050 01 MQM-CONSTANTS. 000051 COPY CMQV. 000052C ****************************************************************** 000053C ** ** 000054C ** IBM MQ for z/OS ** 000055C ** ** 000056C ** FILE NAME: CMQV ** 000057C ** ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 5 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000058C ** DESCRIPTION: Declarations for Main MQI ** 000059C ** ** 000060C ****************************************************************** 000061C ** @START_COPYRIGHT@ ** 000062C ** Statement: Licensed Materials - Property of IBM ** 000063C ** ** 000064C ** 5655-MQ9 ** 000065C ** (C) Copyright IBM Corporation. 1997, 2026 ** 000066C ** @END_COPYRIGHT@ ** 000067C ****************************************************************** 000068C ** ** 000069C ** FUNCTION: This file declares the functions, ** 000070C ** structures and named constants for the ** 000071C ** main MQI. ** 000072C ** ** 000073C ** PROCESSOR: COBOL ** 000074C ** ** 000075C ****************************************************************** 000076C 000077C ****************************************************************** 000078C ** Values Related to MQAIR Structure 000079C ****************************************************************** 000080C ** Structure Identifier 000081C 10 MQAIR-STRUC-ID PIC X(4) VALUE 'AIR '. 000082C 000083C ** Structure Version Number 000084C 10 MQAIR-VERSION-1 PIC S9(9) BINARY VALUE 1. 000085C 10 MQAIR-VERSION-2 PIC S9(9) BINARY VALUE 2. 000086C 10 MQAIR-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000087C 000088C ** Structure Length 000089C 10 MQAIR-LENGTH-1 PIC S9(9) BINARY VALUE 320. 000090C 10 MQAIR-LENGTH-2 PIC S9(9) BINARY VALUE 576. 000091C 10 MQAIR-CURRENT-LENGTH PIC S9(9) BINARY VALUE 576. 000092C 000093C ** Authentication Information Type 000094C 10 MQAIT-ALL PIC S9(9) BINARY VALUE 0. 000095C 10 MQAIT-CRL-LDAP PIC S9(9) BINARY VALUE 1. 000096C 10 MQAIT-OCSP PIC S9(9) BINARY VALUE 2. 000097C 10 MQAIT-IDPW-OS PIC S9(9) BINARY VALUE 3. 000098C 10 MQAIT-IDPW-LDAP PIC S9(9) BINARY VALUE 4. 000099C 000100C ****************************************************************** 000101C ** Values Related to MQBNO Structure 000102C ****************************************************************** 000103C ** Structure Identifier 000104C 10 MQBNO-STRUC-ID PIC X(4) VALUE 'BNO '. 000105C 000106C ** Structure Version Number 000107C 10 MQBNO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000108C 10 MQBNO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000109C 000110C ** Structure Length 000111C 10 MQBNO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 000112C 10 MQBNO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 000113C 000114C ** MQ Balancing Options 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 6 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000115C 10 MQBNO-OPTIONS-NONE PIC S9(9) BINARY VALUE 0. 000116C 10 MQBNO-OPTIONS-IGNORE-TRANS PIC S9(9) BINARY VALUE 1. 000117C 000118C ** MQ Balancing Application Type 000119C 10 MQBNO-BALTYPE-SIMPLE PIC S9(9) BINARY VALUE 0. 000120C 10 MQBNO-BALTYPE-REQREP PIC S9(9) BINARY VALUE 1. 000121C 10 MQBNO-BALTYPE-RA-MANAGED PIC S9(9) BINARY VALUE 65536. 000122C 000123C ** MQ Balancing Timeout 000124C 10 MQBNO-TIMEOUT-AS-DEFAULT PIC S9(9) BINARY VALUE -1. 000125C 10 MQBNO-TIMEOUT-IMMEDIATE PIC S9(9) BINARY VALUE 0. 000126C 10 MQBNO-TIMEOUT-NEVER PIC S9(9) BINARY VALUE -2. 000127C 000128C ****************************************************************** 000129C ** Values Related to MQBMHO Structure 000130C ****************************************************************** 000131C ** Structure Identifier 000132C 10 MQBMHO-STRUC-ID PIC X(4) VALUE 'BMHO'. 000133C 000134C ** Structure Version Number 000135C 10 MQBMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000136C 10 MQBMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000137C 000138C ** Structure Length 000139C 10 MQBMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000140C 10 MQBMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000141C 000142C ** Buffer To Message Handle Options 000143C 10 MQBMHO-NONE PIC S9(9) BINARY VALUE 0. 000144C 10 MQBMHO-DELETE-PROPERTIES PIC S9(9) BINARY VALUE 1. 000145C 000146C ****************************************************************** 000147C ** Values Related to MQCBC Structure 000148C ****************************************************************** 000149C ** Structure Identifier 000150C 10 MQCBC-STRUC-ID PIC X(4) VALUE 'CBC '. 000151C 000152C ** Structure Version Number 000153C 10 MQCBC-VERSION-1 PIC S9(9) BINARY VALUE 1. 000154C 10 MQCBC-VERSION-2 PIC S9(9) BINARY VALUE 2. 000155C 10 MQCBC-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000156C 000157C ** Structure Length 000158C 10 MQCBC-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000159C 10 MQCBC-LENGTH-2 PIC S9(9) BINARY VALUE 52. 000160C 10 MQCBC-CURRENT-LENGTH PIC S9(9) BINARY VALUE 52. 000161C 000162C ** Flags 000163C 10 MQCBCF-NONE PIC S9(9) BINARY VALUE 0. 000164C 10 MQCBCF-READA-BUFFER-EMPTY PIC S9(9) BINARY VALUE 1. 000165C 000166C ** Callback type 000167C 10 MQCBCT-START-CALL PIC S9(9) BINARY VALUE 1. 000168C 10 MQCBCT-STOP-CALL PIC S9(9) BINARY VALUE 2. 000169C 10 MQCBCT-REGISTER-CALL PIC S9(9) BINARY VALUE 3. 000170C 10 MQCBCT-DEREGISTER-CALL PIC S9(9) BINARY VALUE 4. 000171C 10 MQCBCT-EVENT-CALL PIC S9(9) BINARY VALUE 5. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 7 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000172C 10 MQCBCT-MSG-REMOVED PIC S9(9) BINARY VALUE 6. 000173C 10 MQCBCT-MSG-NOT-REMOVED PIC S9(9) BINARY VALUE 7. 000174C 10 MQCBCT-MC-EVENT-CALL PIC S9(9) BINARY VALUE 8. 000175C 000176C ** Consumer state 000177C 10 MQCS-NONE PIC S9(9) BINARY VALUE 0. 000178C 10 MQCS-SUSPENDED-TEMPORARY PIC S9(9) BINARY VALUE 1. 000179C 10 MQCS-SUSPENDED-USER-ACTION PIC S9(9) BINARY VALUE 2. 000180C 10 MQCS-SUSPENDED PIC S9(9) BINARY VALUE 3. 000181C 10 MQCS-STOPPED PIC S9(9) BINARY VALUE 4. 000182C 000183C ** Reconnect delay 000184C 10 MQRD-NO-RECONNECT PIC S9(9) BINARY VALUE -1. 000185C 10 MQRD-NO-DELAY PIC S9(9) BINARY VALUE 0. 000186C 000187C ****************************************************************** 000188C ** Values Related to MQCBD Structure 000189C ****************************************************************** 000190C ** Structure Identifier 000191C 10 MQCBD-STRUC-ID PIC X(4) VALUE 'CBD '. 000192C 000193C ** Structure Version Number 000194C 10 MQCBD-VERSION-1 PIC S9(9) BINARY VALUE 1. 000195C 10 MQCBD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000196C 000197C ** Structure Length 000198C 10 MQCBD-LENGTH-1 PIC S9(9) BINARY VALUE 156. 000199C 10 MQCBD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 156. 000200C 000201C ** Callback Options 000202C 10 MQCBDO-NONE PIC S9(9) BINARY VALUE 0. 000203C 10 MQCBDO-START-CALL PIC S9(9) BINARY VALUE 1. 000204C 10 MQCBDO-STOP-CALL PIC S9(9) BINARY VALUE 4. 000205C 10 MQCBDO-REGISTER-CALL PIC S9(9) BINARY VALUE 256. 000206C 10 MQCBDO-DEREGISTER-CALL PIC S9(9) BINARY VALUE 512. 000207C 10 MQCBDO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000208C 10 MQCBDO-EVENT-CALL PIC S9(9) BINARY VALUE 16384. 000209C 10 MQCBDO-MC-EVENT-CALL PIC S9(9) BINARY VALUE 32768. 000210C 000211C ** This is the type of the Callback Function 000212C 10 MQCBT-MESSAGE-CONSUMER PIC S9(9) BINARY VALUE 1. 000213C 10 MQCBT-EVENT-HANDLER PIC S9(9) BINARY VALUE 2. 000214C 000215C ** Buffer size values 000216C 10 MQCBD-FULL-MSG-LENGTH PIC S9(9) BINARY VALUE -1. 000217C 000218C ****************************************************************** 000219C ** Values Related to MQCHARV Structure 000220C ****************************************************************** 000221C ** Variable String Length 000222C 10 MQVS-NULL-TERMINATED PIC S9(9) BINARY VALUE -1. 000223C 000224C ****************************************************************** 000225C ** Values Related to MQCIH Structure 000226C ****************************************************************** 000227C ** Structure Identifier 000228C 10 MQCIH-STRUC-ID PIC X(4) VALUE 'CIH '. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 8 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000229C 000230C ** Structure Version Number 000231C 10 MQCIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000232C 10 MQCIH-VERSION-2 PIC S9(9) BINARY VALUE 2. 000233C 10 MQCIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000234C 000235C ** Structure Length 000236C 10 MQCIH-LENGTH-1 PIC S9(9) BINARY VALUE 164. 000237C 10 MQCIH-LENGTH-2 PIC S9(9) BINARY VALUE 180. 000238C 10 MQCIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 180. 000239C 000240C ** Flags 000241C 10 MQCIH-NONE PIC S9(9) BINARY VALUE 0. 000242C 10 MQCIH-PASS-EXPIRATION PIC S9(9) BINARY VALUE 1. 000243C 10 MQCIH-UNLIMITED-EXPIRATION PIC S9(9) BINARY VALUE 0. 000244C 10 MQCIH-REPLY-WITHOUT-NULLS PIC S9(9) BINARY VALUE 2. 000245C 10 MQCIH-REPLY-WITH-NULLS PIC S9(9) BINARY VALUE 0. 000246C 10 MQCIH-SYNC-ON-RETURN PIC S9(9) BINARY VALUE 4. 000247C 10 MQCIH-NO-SYNC-ON-RETURN PIC S9(9) BINARY VALUE 0. 000248C 000249C ** Return Codes 000250C 10 MQCRC-OK PIC S9(9) BINARY VALUE 0. 000251C 10 MQCRC-CICS-EXEC-ERROR PIC S9(9) BINARY VALUE 1. 000252C 10 MQCRC-MQ-API-ERROR PIC S9(9) BINARY VALUE 2. 000253C 10 MQCRC-BRIDGE-ERROR PIC S9(9) BINARY VALUE 3. 000254C 10 MQCRC-BRIDGE-ABEND PIC S9(9) BINARY VALUE 4. 000255C 10 MQCRC-APPLICATION-ABEND PIC S9(9) BINARY VALUE 5. 000256C 10 MQCRC-SECURITY-ERROR PIC S9(9) BINARY VALUE 6. 000257C 10 MQCRC-PROGRAM-NOT-AVAILABLE PIC S9(9) BINARY VALUE 7. 000258C 10 MQCRC-BRIDGE-TIMEOUT PIC S9(9) BINARY VALUE 8. 000259C 10 MQCRC-TRANSID-NOT-AVAILABLE PIC S9(9) BINARY VALUE 9. 000260C 000261C ** Unit-of-Work Controls 000262C 10 MQCUOWC-ONLY PIC S9(9) BINARY VALUE 273. 000263C 10 MQCUOWC-CONTINUE PIC S9(9) BINARY VALUE 65536. 000264C 10 MQCUOWC-FIRST PIC S9(9) BINARY VALUE 17. 000265C 10 MQCUOWC-MIDDLE PIC S9(9) BINARY VALUE 16. 000266C 10 MQCUOWC-LAST PIC S9(9) BINARY VALUE 272. 000267C 10 MQCUOWC-COMMIT PIC S9(9) BINARY VALUE 256. 000268C 10 MQCUOWC-BACKOUT PIC S9(9) BINARY VALUE 4352. 000269C 000270C ** Get Wait Interval 000271C 10 MQCGWI-DEFAULT PIC S9(9) BINARY VALUE -2. 000272C 000273C ** Link Types 000274C 10 MQCLT-PROGRAM PIC S9(9) BINARY VALUE 1. 000275C 10 MQCLT-TRANSACTION PIC S9(9) BINARY VALUE 2. 000276C 000277C ** Output Data Length 000278C 10 MQCODL-AS-INPUT PIC S9(9) BINARY VALUE -1. 000279C 000280C ** ADS Descriptors 000281C 10 MQCADSD-NONE PIC S9(9) BINARY VALUE 0. 000282C 10 MQCADSD-SEND PIC S9(9) BINARY VALUE 1. 000283C 10 MQCADSD-RECV PIC S9(9) BINARY VALUE 16. 000284C 10 MQCADSD-MSGFORMAT PIC S9(9) BINARY VALUE 256. 000285C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 9 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000286C ** Conversational Task Options 000287C 10 MQCCT-YES PIC S9(9) BINARY VALUE 1. 000288C 10 MQCCT-NO PIC S9(9) BINARY VALUE 0. 000289C 000290C ** Task End Status 000291C 10 MQCTES-NOSYNC PIC S9(9) BINARY VALUE 0. 000292C 10 MQCTES-COMMIT PIC S9(9) BINARY VALUE 256. 000293C 10 MQCTES-BACKOUT PIC S9(9) BINARY VALUE 4352. 000294C 10 MQCTES-ENDTASK PIC S9(9) BINARY VALUE 65536. 000295C 000296C ** Facility 000297C 10 MQCFAC-NONE PIC X(8) VALUE LOW-VALUES. 000298C 000299C ** Functions 000300C 10 MQCFUNC-MQCONN PIC X(4) VALUE 'CONN'. 000301C 10 MQCFUNC-MQGET PIC X(4) VALUE 'GET '. 000302C 10 MQCFUNC-MQINQ PIC X(4) VALUE 'INQ '. 000303C 10 MQCFUNC-MQOPEN PIC X(4) VALUE 'OPEN'. 000304C 10 MQCFUNC-MQPUT PIC X(4) VALUE 'PUT '. 000305C 10 MQCFUNC-MQPUT1 PIC X(4) VALUE 'PUT1'. 000306C 10 MQCFUNC-NONE PIC X(4) VALUE SPACES. 000307C 000308C ** Start Codes 000309C 10 MQCSC-START PIC X(4) VALUE 'S '. 000310C 10 MQCSC-STARTDATA PIC X(4) VALUE 'SD '. 000311C 10 MQCSC-TERMINPUT PIC X(4) VALUE 'TD '. 000312C 10 MQCSC-NONE PIC X(4) VALUE SPACES. 000313C 000314C ****************************************************************** 000315C ** Values Related to MQCMHO Structure 000316C ****************************************************************** 000317C ** Structure Identifier 000318C 10 MQCMHO-STRUC-ID PIC X(4) VALUE 'CMHO'. 000319C 000320C ** Structure Version Number 000321C 10 MQCMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000322C 10 MQCMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000323C 000324C ** Structure Length 000325C 10 MQCMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000326C 10 MQCMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000327C 000328C ** Create Message Handle Options 000329C 10 MQCMHO-DEFAULT-VALIDATION PIC S9(9) BINARY VALUE 0. 000330C 10 MQCMHO-NO-VALIDATION PIC S9(9) BINARY VALUE 1. 000331C 10 MQCMHO-VALIDATE PIC S9(9) BINARY VALUE 2. 000332C 10 MQCMHO-NONE PIC S9(9) BINARY VALUE 0. 000333C 000334C ****************************************************************** 000335C ** Values Related to MQCTLO Structure 000336C ****************************************************************** 000337C ** Structure Identifier 000338C 10 MQCTLO-STRUC-ID PIC X(4) VALUE 'CTLO'. 000339C 000340C ** Structure Version Number 000341C 10 MQCTLO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000342C 10 MQCTLO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 10 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000343C 000344C ** Structure Length 000345C 10 MQCTLO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 000346C 10 MQCTLO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 000347C 000348C ** Consumer Control Options 000349C 10 MQCTLO-NONE PIC S9(9) BINARY VALUE 0. 000350C 10 MQCTLO-THREAD-AFFINITY PIC S9(9) BINARY VALUE 1. 000351C 10 MQCTLO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000352C 000353C ****************************************************************** 000354C ** Values Related to MQSCO Structure 000355C ****************************************************************** 000356C ** Structure Identifier 000357C 10 MQSCO-STRUC-ID PIC X(4) VALUE 'SCO '. 000358C 000359C ** Structure Version Number 000360C 10 MQSCO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000361C 10 MQSCO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000362C 10 MQSCO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000363C 10 MQSCO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000364C 10 MQSCO-VERSION-5 PIC S9(9) BINARY VALUE 5. 000365C 10 MQSCO-VERSION-6 PIC S9(9) BINARY VALUE 6. 000366C 10 MQSCO-VERSION-7 PIC S9(9) BINARY VALUE 7. 000367C 10 MQSCO-CURRENT-VERSION PIC S9(9) BINARY VALUE 7. 000368C 000369C ** Structure Length 000370C 10 MQSCO-LENGTH-1 PIC S9(9) BINARY VALUE 532. 000371C 10 MQSCO-LENGTH-2 PIC S9(9) BINARY VALUE 540. 000372C 10 MQSCO-LENGTH-3 PIC S9(9) BINARY VALUE 556. 000373C 10 MQSCO-LENGTH-4 PIC S9(9) BINARY VALUE 560. 000374C 10 MQSCO-LENGTH-5 PIC S9(9) BINARY VALUE 624. 000375C 10 MQSCO-LENGTH-6 PIC S9(9) BINARY VALUE 636. 000376C 10 MQSCO-LENGTH-7 PIC S9(9) BINARY VALUE 656. 000377C 10 MQSCO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 656. 000378C 000379C ** SuiteB Type 000380C 10 MQ-SUITE-B-NOT-AVAILABLE PIC S9(9) BINARY VALUE 0. 000381C 10 MQ-SUITE-B-NONE PIC S9(9) BINARY VALUE 1. 000382C 10 MQ-SUITE-B-128-BIT PIC S9(9) BINARY VALUE 2. 000383C 10 MQ-SUITE-B-192-BIT PIC S9(9) BINARY VALUE 4. 000384C 000385C ** Key Reset Count 000386C 10 MQSCO-RESET-COUNT-DEFAULT PIC S9(9) BINARY VALUE 0. 000387C 000388C ** Certificate Validation Policy Type 000389C 10 MQ-CERT-VAL-POLICY-DEFAULT PIC S9(9) BINARY VALUE 0. 000390C 10 MQ-CERT-VAL-POLICY-ANY PIC S9(9) BINARY VALUE 0. 000391C 10 MQ-CERT-VAL-POLICY-RFC5280 PIC S9(9) BINARY VALUE 1. 000392C 10 MQ-CERT-VAL-POLICY-NONE PIC S9(9) BINARY VALUE 2. 000393C 000394C ** HTTPS Certificate Validation Type 000395C 10 MQ-HTTPSCERTVAL-DEFAULT PIC S9(9) BINARY VALUE 0. 000396C 10 MQ-HTTPSCERTVAL-ANY PIC S9(9) BINARY VALUE 1. 000397C 10 MQ-HTTPSCERTVAL-NONE PIC S9(9) BINARY VALUE 2. 000398C 10 MQ-HTTPSCERTVAL-HOSTNAMECN PIC S9(9) BINARY VALUE 3. 000399C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 11 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000400C ** HTTPS Certificate Revocation Type 000401C 10 MQ-HTTPSCERTREV-DEFAULT PIC S9(9) BINARY VALUE 0. 000402C 10 MQ-HTTPSCERTREV-REQUIRED PIC S9(9) BINARY VALUE 1. 000403C 10 MQ-HTTPSCERTREV-DISABLED PIC S9(9) BINARY VALUE 2. 000404C 10 MQ-HTTPSCERTREV-OPTIONAL PIC S9(9) BINARY VALUE 3. 000405C 000406C ****************************************************************** 000407C ** Values Related to MQCSP Structure 000408C ****************************************************************** 000409C ** Structure Identifier 000410C 10 MQCSP-STRUC-ID PIC X(4) VALUE 'CSP '. 000411C 000412C ** Structure Version Number 000413C 10 MQCSP-VERSION-1 PIC S9(9) BINARY VALUE 1. 000414C 10 MQCSP-VERSION-2 PIC S9(9) BINARY VALUE 2. 000415C 10 MQCSP-VERSION-3 PIC S9(9) BINARY VALUE 3. 000416C 10 MQCSP-CURRENT-VERSION PIC S9(9) BINARY VALUE 3. 000417C 000418C ** Structure Length 000419C 10 MQCSP-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000420C 10 MQCSP-LENGTH-2 PIC S9(9) BINARY VALUE 68. 000421C 10 MQCSP-LENGTH-3 PIC S9(9) BINARY VALUE 88. 000422C 10 MQCSP-CURRENT-LENGTH PIC S9(9) BINARY VALUE 88. 000423C 000424C ** Authentication Types 000425C 10 MQCSP-AUTH-NONE PIC S9(9) BINARY VALUE 0. 000426C 10 MQCSP-AUTH-USER-ID-AND-PWD PIC S9(9) BINARY VALUE 1. 000427C 10 MQCSP-AUTH-ID-TOKEN PIC S9(9) BINARY VALUE 2. 000428C 000429C ****************************************************************** 000430C ** Values Related to MQCNO Structure 000431C ****************************************************************** 000432C ** Structure Identifier 000433C 10 MQCNO-STRUC-ID PIC X(4) VALUE 'CNO '. 000434C 000435C ** Structure Version Number 000436C 10 MQCNO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000437C 10 MQCNO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000438C 10 MQCNO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000439C 10 MQCNO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000440C 10 MQCNO-VERSION-5 PIC S9(9) BINARY VALUE 5. 000441C 10 MQCNO-VERSION-6 PIC S9(9) BINARY VALUE 6. 000442C 10 MQCNO-VERSION-7 PIC S9(9) BINARY VALUE 7. 000443C 10 MQCNO-VERSION-8 PIC S9(9) BINARY VALUE 8. 000444C 10 MQCNO-CURRENT-VERSION PIC S9(9) BINARY VALUE 8. 000445C 000446C ** Structure Length 000447C 10 MQCNO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000448C 10 MQCNO-LENGTH-2 PIC S9(9) BINARY VALUE 20. 000449C 10 MQCNO-LENGTH-3 PIC S9(9) BINARY VALUE 148. 000450C 10 MQCNO-LENGTH-4 PIC S9(9) BINARY VALUE 156. 000451C 10 MQCNO-LENGTH-5 PIC S9(9) BINARY VALUE 188. 000452C 10 MQCNO-LENGTH-6 PIC S9(9) BINARY VALUE 208. 000453C 10 MQCNO-LENGTH-7 PIC S9(9) BINARY VALUE 240. 000454C 10 MQCNO-LENGTH-8 PIC S9(9) BINARY VALUE 252. 000455C 10 MQCNO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 252. 000456C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 12 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000457C ** Connect Options 000458C 10 MQCNO-STANDARD-BINDING PIC S9(9) BINARY VALUE 0. 000459C 10 MQCNO-FASTPATH-BINDING PIC S9(9) BINARY VALUE 1. 000460C 10 MQCNO-SERIALIZE-CONN-TAG-Q-MGR PIC S9(9) BINARY VALUE 2. 000461C 10 MQCNO-SERIALIZE-CONN-TAG-QSG PIC S9(9) BINARY VALUE 4. 000462C 10 MQCNO-RESTRICT-CONN-TAG-Q-MGR PIC S9(9) BINARY VALUE 8. 000463C 10 MQCNO-RESTRICT-CONN-TAG-QSG PIC S9(9) BINARY VALUE 16. 000464C 10 MQCNO-HANDLE-SHARE-NONE PIC S9(9) BINARY VALUE 32. 000465C 10 MQCNO-HANDLE-SHARE-BLOCK PIC S9(9) BINARY VALUE 64. 000466C 10 MQCNO-HANDLE-SHARE-NO-BLOCK PIC S9(9) BINARY VALUE 128. 000467C 10 MQCNO-SHARED-BINDING PIC S9(9) BINARY VALUE 256. 000468C 10 MQCNO-ISOLATED-BINDING PIC S9(9) BINARY VALUE 512. 000469C 10 MQCNO-LOCAL-BINDING PIC S9(9) BINARY VALUE 1024. 000470C 10 MQCNO-CLIENT-BINDING PIC S9(9) BINARY VALUE 2048. 000471C 10 MQCNO-ACCOUNTING-MQI-ENABLED PIC S9(9) BINARY VALUE 4096. 000472C 10 MQCNO-ACCOUNTING-MQI-DISABLED PIC S9(9) BINARY VALUE 8192. 000473C 10 MQCNO-ACCOUNTING-Q-ENABLED PIC S9(9) BINARY VALUE 16384. 000474C 10 MQCNO-ACCOUNTING-Q-DISABLED PIC S9(9) BINARY VALUE 32768. 000475C 10 MQCNO-NO-CONV-SHARING PIC S9(9) BINARY VALUE 65536. 000476C 10 MQCNO-ALL-CONVS-SHARE PIC S9(9) BINARY VALUE 262144. 000477C 10 MQCNO-CD-FOR-OUTPUT-ONLY PIC S9(9) BINARY VALUE 524288. 000478C 10 MQCNO-USE-CD-SELECTION PIC S9(9) BINARY VALUE 1048576. 000479C 10 MQCNO-GENERATE-CONN-TAG PIC S9(9) BINARY VALUE 2097152. 000480C 10 MQCNO-RECONNECT-AS-DEF PIC S9(9) BINARY VALUE 0. 000481C 10 MQCNO-RECONNECT PIC S9(9) BINARY VALUE 16777216. 000482C 10 MQCNO-RECONNECT-DISABLED PIC S9(9) BINARY VALUE 33554432. 000483C 10 MQCNO-RECONNECT-Q-MGR PIC S9(9) BINARY VALUE 67108864. 000484C 10 MQCNO-ACTIVITY-TRACE-ENABLED PIC S9(9) BINARY 000485C VALUE 134217728. 000486C 10 MQCNO-ACTIVITY-TRACE-DISABLED PIC S9(9) BINARY 000487C VALUE 268435456. 000488C 10 MQCNO-NONE PIC S9(9) BINARY VALUE 0. 000489C 000490C ** Queue Manager Connection Tag 000491C 10 MQCT-NONE PIC X(128) VALUE LOW-VALUES. 000492C 000493C ** Connection Identifier 000494C 10 MQCONNID-NONE PIC X(24) VALUE LOW-VALUES. 000495C 000496C ** Application Name 000497C 10 MQAN-NONE PIC X(28) VALUE SPACES. 000498C 000499C ****************************************************************** 000500C ** Values Related to MQDH Structure 000501C ****************************************************************** 000502C ** Structure Identifier 000503C 10 MQDH-STRUC-ID PIC X(4) VALUE 'DH '. 000504C 000505C ** Structure Version Number 000506C 10 MQDH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000507C 10 MQDH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000508C 000509C ** Structure Length 000510C 10 MQDH-LENGTH-1 PIC S9(9) BINARY VALUE 48. 000511C 10 MQDH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 48. 000512C 000513C ** Flags 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 13 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000514C 10 MQDHF-NEW-MSG-IDS PIC S9(9) BINARY VALUE 1. 000515C 10 MQDHF-NONE PIC S9(9) BINARY VALUE 0. 000516C 000517C ****************************************************************** 000518C ** Values Related to MQDLH Structure 000519C ****************************************************************** 000520C ** Structure Identifier 000521C 10 MQDLH-STRUC-ID PIC X(4) VALUE 'DLH '. 000522C 000523C ** Structure Version Number 000524C 10 MQDLH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000525C 10 MQDLH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000526C 000527C ** Structure Length 000528C 10 MQDLH-LENGTH-1 PIC S9(9) BINARY VALUE 172. 000529C 10 MQDLH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 172. 000530C 000531C ****************************************************************** 000532C ** Values Related to MQDMHO Structure 000533C ****************************************************************** 000534C ** Structure Identifier 000535C 10 MQDMHO-STRUC-ID PIC X(4) VALUE 'DMHO'. 000536C 000537C ** Structure Version Number 000538C 10 MQDMHO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000539C 10 MQDMHO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000540C 000541C ** Structure Length 000542C 10 MQDMHO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000543C 10 MQDMHO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000544C 000545C ** Delete Message Handle Options 000546C 10 MQDMHO-NONE PIC S9(9) BINARY VALUE 0. 000547C 000548C ****************************************************************** 000549C ** Values Related to MQDMPO Structure 000550C ****************************************************************** 000551C ** Structure Identifier 000552C 10 MQDMPO-STRUC-ID PIC X(4) VALUE 'DMPO'. 000553C 000554C ** Structure Version Number 000555C 10 MQDMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000556C 10 MQDMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000557C 000558C ** Structure Length 000559C 10 MQDMPO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 000560C 10 MQDMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 000561C 000562C ** Delete Message Property Options 000563C 10 MQDMPO-DEL-FIRST PIC S9(9) BINARY VALUE 0. 000564C 10 MQDMPO-DEL-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 1. 000565C 10 MQDMPO-NONE PIC S9(9) BINARY VALUE 0. 000566C 000567C ****************************************************************** 000568C ** Values Related to MQGMO Structure 000569C ****************************************************************** 000570C ** Structure Identifier 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 14 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000571C 10 MQGMO-STRUC-ID PIC X(4) VALUE 'GMO '. 000572C 000573C ** Structure Version Number 000574C 10 MQGMO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000575C 10 MQGMO-VERSION-2 PIC S9(9) BINARY VALUE 2. 000576C 10 MQGMO-VERSION-3 PIC S9(9) BINARY VALUE 3. 000577C 10 MQGMO-VERSION-4 PIC S9(9) BINARY VALUE 4. 000578C 10 MQGMO-CURRENT-VERSION PIC S9(9) BINARY VALUE 4. 000579C 000580C ** Structure Length 000581C 10 MQGMO-LENGTH-1 PIC S9(9) BINARY VALUE 72. 000582C 10 MQGMO-LENGTH-2 PIC S9(9) BINARY VALUE 80. 000583C 10 MQGMO-LENGTH-3 PIC S9(9) BINARY VALUE 100. 000584C 10 MQGMO-LENGTH-4 PIC S9(9) BINARY VALUE 112. 000585C 10 MQGMO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 112. 000586C 000587C ** Get Message Options 000588C 10 MQGMO-WAIT PIC S9(9) BINARY VALUE 1. 000589C 10 MQGMO-NO-WAIT PIC S9(9) BINARY VALUE 0. 000590C 10 MQGMO-SET-SIGNAL PIC S9(9) BINARY VALUE 8. 000591C 10 MQGMO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 000592C 10 MQGMO-SYNCPOINT PIC S9(9) BINARY VALUE 2. 000593C 10 MQGMO-SYNCPOINT-IF-PERSISTENT PIC S9(9) BINARY VALUE 4096. 000594C 10 MQGMO-NO-SYNCPOINT PIC S9(9) BINARY VALUE 4. 000595C 10 MQGMO-MARK-SKIP-BACKOUT PIC S9(9) BINARY VALUE 128. 000596C 10 MQGMO-BROWSE-FIRST PIC S9(9) BINARY VALUE 16. 000597C 10 MQGMO-BROWSE-NEXT PIC S9(9) BINARY VALUE 32. 000598C 10 MQGMO-BROWSE-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2048. 000599C 10 MQGMO-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 256. 000600C 10 MQGMO-LOCK PIC S9(9) BINARY VALUE 512. 000601C 10 MQGMO-UNLOCK PIC S9(9) BINARY VALUE 1024. 000602C 10 MQGMO-ACCEPT-TRUNCATED-MSG PIC S9(9) BINARY VALUE 64. 000603C 10 MQGMO-CONVERT PIC S9(9) BINARY VALUE 16384. 000604C 10 MQGMO-LOGICAL-ORDER PIC S9(9) BINARY VALUE 32768. 000605C 10 MQGMO-COMPLETE-MSG PIC S9(9) BINARY VALUE 65536. 000606C 10 MQGMO-ALL-MSGS-AVAILABLE PIC S9(9) BINARY VALUE 131072. 000607C 10 MQGMO-ALL-SEGMENTS-AVAILABLE PIC S9(9) BINARY VALUE 262144. 000608C 10 MQGMO-MARK-BROWSE-HANDLE PIC S9(9) BINARY VALUE 1048576. 000609C 10 MQGMO-MARK-BROWSE-CO-OP PIC S9(9) BINARY VALUE 2097152. 000610C 10 MQGMO-UNMARK-BROWSE-CO-OP PIC S9(9) BINARY VALUE 4194304. 000611C 10 MQGMO-UNMARK-BROWSE-HANDLE PIC S9(9) BINARY VALUE 8388608. 000612C 10 MQGMO-UNMARKED-BROWSE-MSG PIC S9(9) BINARY VALUE 16777216. 000613C 10 MQGMO-PROPERTIES-FORCE-MQRFH2 PIC S9(9) BINARY 000614C VALUE 33554432. 000615C 10 MQGMO-NO-PROPERTIES PIC S9(9) BINARY VALUE 67108864. 000616C 10 MQGMO-PROPERTIES-IN-HANDLE PIC S9(9) BINARY 000617C VALUE 134217728. 000618C 10 MQGMO-PROPERTIES-COMPATIBILITY PIC S9(9) BINARY 000619C VALUE 268435456. 000620C 10 MQGMO-PROPERTIES-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 000621C 10 MQGMO-NONE PIC S9(9) BINARY VALUE 0. 000622C 10 MQGMO-BROWSE-HANDLE PIC S9(9) BINARY VALUE 17825808. 000623C 10 MQGMO-BROWSE-CO-OP PIC S9(9) BINARY VALUE 18874384. 000624C 000625C ** Wait Interval 000626C 10 MQWI-UNLIMITED PIC S9(9) BINARY VALUE -1. 000627C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 15 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000628C ** Signal Values 000629C 10 MQEC-MSG-ARRIVED PIC S9(9) BINARY VALUE 2. 000630C 10 MQEC-WAIT-INTERVAL-EXPIRED PIC S9(9) BINARY VALUE 3. 000631C 10 MQEC-WAIT-CANCELED PIC S9(9) BINARY VALUE 4. 000632C 10 MQEC-Q-MGR-QUIESCING PIC S9(9) BINARY VALUE 5. 000633C 10 MQEC-CONNECTION-QUIESCING PIC S9(9) BINARY VALUE 6. 000634C 000635C ** Match Options 000636C 10 MQMO-MATCH-MSG-ID PIC S9(9) BINARY VALUE 1. 000637C 10 MQMO-MATCH-CORREL-ID PIC S9(9) BINARY VALUE 2. 000638C 10 MQMO-MATCH-GROUP-ID PIC S9(9) BINARY VALUE 4. 000639C 10 MQMO-MATCH-MSG-SEQ-NUMBER PIC S9(9) BINARY VALUE 8. 000640C 10 MQMO-MATCH-OFFSET PIC S9(9) BINARY VALUE 16. 000641C 10 MQMO-MATCH-MSG-TOKEN PIC S9(9) BINARY VALUE 32. 000642C 10 MQMO-NONE PIC S9(9) BINARY VALUE 0. 000643C 000644C ** Group Status 000645C 10 MQGS-NOT-IN-GROUP PIC X VALUE ' '. 000646C 10 MQGS-MSG-IN-GROUP PIC X VALUE 'G'. 000647C 10 MQGS-LAST-MSG-IN-GROUP PIC X VALUE 'L'. 000648C 000649C ** Segment Status 000650C 10 MQSS-NOT-A-SEGMENT PIC X VALUE ' '. 000651C 10 MQSS-SEGMENT PIC X VALUE 'S'. 000652C 10 MQSS-LAST-SEGMENT PIC X VALUE 'L'. 000653C 000654C ** Segmentation 000655C 10 MQSEG-INHIBITED PIC X VALUE ' '. 000656C 10 MQSEG-ALLOWED PIC X VALUE 'A'. 000657C 000658C ** Message Token 000659C 10 MQMTOK-NONE PIC X(16) VALUE LOW-VALUES. 000660C 000661C ** Returned Length 000662C 10 MQRL-UNDEFINED PIC S9(9) BINARY VALUE -1. 000663C 000664C ****************************************************************** 000665C ** Values Related to MQIIH Structure 000666C ****************************************************************** 000667C ** Structure Identifier 000668C 10 MQIIH-STRUC-ID PIC X(4) VALUE 'IIH '. 000669C 000670C ** Structure Version Number 000671C 10 MQIIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 000672C 10 MQIIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000673C 000674C ** Structure Length 000675C 10 MQIIH-LENGTH-1 PIC S9(9) BINARY VALUE 84. 000676C 10 MQIIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 84. 000677C 000678C ** Flags 000679C 10 MQIIH-NONE PIC S9(9) BINARY VALUE 0. 000680C 10 MQIIH-PASS-EXPIRATION PIC S9(9) BINARY VALUE 1. 000681C 10 MQIIH-UNLIMITED-EXPIRATION PIC S9(9) BINARY VALUE 0. 000682C 10 MQIIH-REPLY-FORMAT-NONE PIC S9(9) BINARY VALUE 8. 000683C 10 MQIIH-IGNORE-PURG PIC S9(9) BINARY VALUE 16. 000684C 10 MQIIH-CM0-REQUEST-RESPONSE PIC S9(9) BINARY VALUE 32. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 16 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000685C 000686C ** Authenticator 000687C 10 MQIAUT-NONE PIC X(8) VALUE SPACES. 000688C 000689C ** Transaction Instance Identifier 000690C 10 MQITII-NONE PIC X(16) VALUE LOW-VALUES. 000691C 000692C ** Transaction States 000693C 10 MQITS-IN-CONVERSATION PIC X VALUE 'C'. 000694C 10 MQITS-NOT-IN-CONVERSATION PIC X VALUE ' '. 000695C 10 MQITS-ARCHITECTED PIC X VALUE 'A'. 000696C 000697C ** Commit Modes 000698C 10 MQICM-COMMIT-THEN-SEND PIC X VALUE '0'. 000699C 10 MQICM-SEND-THEN-COMMIT PIC X VALUE '1'. 000700C 000701C ** Security Scopes 000702C 10 MQISS-CHECK PIC X VALUE 'C'. 000703C 10 MQISS-FULL PIC X VALUE 'F'. 000704C 000705C ****************************************************************** 000706C ** Values Related to MQIMPO Structure 000707C ****************************************************************** 000708C ** Structure Identifier 000709C 10 MQIMPO-STRUC-ID PIC X(4) VALUE 'IMPO'. 000710C 000711C ** Structure Version Number 000712C 10 MQIMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 000713C 10 MQIMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 000714C 000715C ** Structure Length 000716C 10 MQIMPO-LENGTH-1 PIC S9(9) BINARY VALUE 60. 000717C 10 MQIMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 60. 000718C 000719C ** Inquire Message Property Options 000720C 10 MQIMPO-CONVERT-TYPE PIC S9(9) BINARY VALUE 2. 000721C 10 MQIMPO-QUERY-LENGTH PIC S9(9) BINARY VALUE 4. 000722C 10 MQIMPO-INQ-FIRST PIC S9(9) BINARY VALUE 0. 000723C 10 MQIMPO-INQ-NEXT PIC S9(9) BINARY VALUE 8. 000724C 10 MQIMPO-INQ-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 16. 000725C 10 MQIMPO-CONVERT-VALUE PIC S9(9) BINARY VALUE 32. 000726C 10 MQIMPO-NONE PIC S9(9) BINARY VALUE 0. 000727C 000728C ****************************************************************** 000729C ** Values Related to MQMD Structure 000730C ****************************************************************** 000731C ** Structure Identifier 000732C 10 MQMD-STRUC-ID PIC X(4) VALUE 'MD '. 000733C 000734C ** Structure Version Number 000735C 10 MQMD-VERSION-1 PIC S9(9) BINARY VALUE 1. 000736C 10 MQMD-VERSION-2 PIC S9(9) BINARY VALUE 2. 000737C 10 MQMD-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 000738C 000739C ** Structure Length 000740C 10 MQMD-LENGTH-1 PIC S9(9) BINARY VALUE 324. 000741C 10 MQMD-LENGTH-2 PIC S9(9) BINARY VALUE 364. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 17 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000742C 10 MQMD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 364. 000743C 000744C ** Report Options 000745C 10 MQRO-EXCEPTION PIC S9(9) BINARY VALUE 16777216. 000746C 10 MQRO-EXCEPTION-WITH-DATA PIC S9(9) BINARY VALUE 50331648. 000747C 10 MQRO-EXCEPTION-WITH-FULL-DATA PIC S9(9) BINARY 000748C VALUE 117440512. 000749C 10 MQRO-EXPIRATION PIC S9(9) BINARY VALUE 2097152. 000750C 10 MQRO-EXPIRATION-WITH-DATA PIC S9(9) BINARY VALUE 6291456. 000751C 10 MQRO-EXPIRATION-WITH-FULL-DATA PIC S9(9) BINARY 000752C VALUE 14680064. 000753C 10 MQRO-COA PIC S9(9) BINARY VALUE 256. 000754C 10 MQRO-COA-WITH-DATA PIC S9(9) BINARY VALUE 768. 000755C 10 MQRO-COA-WITH-FULL-DATA PIC S9(9) BINARY VALUE 1792. 000756C 10 MQRO-COD PIC S9(9) BINARY VALUE 2048. 000757C 10 MQRO-COD-WITH-DATA PIC S9(9) BINARY VALUE 6144. 000758C 10 MQRO-COD-WITH-FULL-DATA PIC S9(9) BINARY VALUE 14336. 000759C 10 MQRO-PAN PIC S9(9) BINARY VALUE 1. 000760C 10 MQRO-NAN PIC S9(9) BINARY VALUE 2. 000761C 10 MQRO-ACTIVITY PIC S9(9) BINARY VALUE 4. 000762C 10 MQRO-NEW-MSG-ID PIC S9(9) BINARY VALUE 0. 000763C 10 MQRO-PASS-MSG-ID PIC S9(9) BINARY VALUE 128. 000764C 10 MQRO-COPY-MSG-ID-TO-CORREL-ID PIC S9(9) BINARY VALUE 0. 000765C 10 MQRO-PASS-CORREL-ID PIC S9(9) BINARY VALUE 64. 000766C 10 MQRO-DEAD-LETTER-Q PIC S9(9) BINARY VALUE 0. 000767C 10 MQRO-DISCARD-MSG PIC S9(9) BINARY VALUE 134217728. 000768C 10 MQRO-PASS-DISCARD-AND-EXPIRY PIC S9(9) BINARY VALUE 16384. 000769C 10 MQRO-NONE PIC S9(9) BINARY VALUE 0. 000770C 000771C ** Report Options Masks 000772C 10 MQRO-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE 270270464. 000773C 10 MQRO-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE -270532353. 000774C 10 MQRO-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 000775C VALUE 261888. 000776C 000777C ** Message Types 000778C 10 MQMT-SYSTEM-FIRST PIC S9(9) BINARY VALUE 1. 000779C 10 MQMT-REQUEST PIC S9(9) BINARY VALUE 1. 000780C 10 MQMT-REPLY PIC S9(9) BINARY VALUE 2. 000781C 10 MQMT-DATAGRAM PIC S9(9) BINARY VALUE 8. 000782C 10 MQMT-REPORT PIC S9(9) BINARY VALUE 4. 000783C 10 MQMT-MQE-FIELDS-FROM-MQE PIC S9(9) BINARY VALUE 112. 000784C 10 MQMT-MQE-FIELDS PIC S9(9) BINARY VALUE 113. 000785C 10 MQMT-SYSTEM-LAST PIC S9(9) BINARY VALUE 65535. 000786C 10 MQMT-APPL-FIRST PIC S9(9) BINARY VALUE 65536. 000787C 10 MQMT-APPL-LAST PIC S9(9) BINARY VALUE 999999999. 000788C 000789C ** Expiry 000790C 10 MQEI-UNLIMITED PIC S9(9) BINARY VALUE -1. 000791C 000792C ** Feedback Values 000793C 10 MQFB-NONE PIC S9(9) BINARY VALUE 0. 000794C 10 MQFB-SYSTEM-FIRST PIC S9(9) BINARY VALUE 1. 000795C 10 MQFB-QUIT PIC S9(9) BINARY VALUE 256. 000796C 10 MQFB-EXPIRATION PIC S9(9) BINARY VALUE 258. 000797C 10 MQFB-COA PIC S9(9) BINARY VALUE 259. 000798C 10 MQFB-COD PIC S9(9) BINARY VALUE 260. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 18 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000799C 10 MQFB-CHANNEL-COMPLETED PIC S9(9) BINARY VALUE 262. 000800C 10 MQFB-CHANNEL-FAIL-RETRY PIC S9(9) BINARY VALUE 263. 000801C 10 MQFB-CHANNEL-FAIL PIC S9(9) BINARY VALUE 264. 000802C 10 MQFB-APPL-CANNOT-BE-STARTED PIC S9(9) BINARY VALUE 265. 000803C 10 MQFB-TM-ERROR PIC S9(9) BINARY VALUE 266. 000804C 10 MQFB-APPL-TYPE-ERROR PIC S9(9) BINARY VALUE 267. 000805C 10 MQFB-STOPPED-BY-MSG-EXIT PIC S9(9) BINARY VALUE 268. 000806C 10 MQFB-ACTIVITY PIC S9(9) BINARY VALUE 269. 000807C 10 MQFB-XMIT-Q-MSG-ERROR PIC S9(9) BINARY VALUE 271. 000808C 10 MQFB-PAN PIC S9(9) BINARY VALUE 275. 000809C 10 MQFB-NAN PIC S9(9) BINARY VALUE 276. 000810C 10 MQFB-STOPPED-BY-CHAD-EXIT PIC S9(9) BINARY VALUE 277. 000811C 10 MQFB-STOPPED-BY-PUBSUB-EXIT PIC S9(9) BINARY VALUE 279. 000812C 10 MQFB-NOT-A-REPOSITORY-MSG PIC S9(9) BINARY VALUE 280. 000813C 10 MQFB-BIND-OPEN-CLUSRCVR-DEL PIC S9(9) BINARY VALUE 281. 000814C 10 MQFB-MAX-ACTIVITIES PIC S9(9) BINARY VALUE 282. 000815C 10 MQFB-NOT-FORWARDED PIC S9(9) BINARY VALUE 283. 000816C 10 MQFB-NOT-DELIVERED PIC S9(9) BINARY VALUE 284. 000817C 10 MQFB-UNSUPPORTED-FORWARDING PIC S9(9) BINARY VALUE 285. 000818C 10 MQFB-UNSUPPORTED-DELIVERY PIC S9(9) BINARY VALUE 286. 000819C 10 MQFB-DATA-LENGTH-ZERO PIC S9(9) BINARY VALUE 291. 000820C 10 MQFB-DATA-LENGTH-NEGATIVE PIC S9(9) BINARY VALUE 292. 000821C 10 MQFB-DATA-LENGTH-TOO-BIG PIC S9(9) BINARY VALUE 293. 000822C 10 MQFB-BUFFER-OVERFLOW PIC S9(9) BINARY VALUE 294. 000823C 10 MQFB-LENGTH-OFF-BY-ONE PIC S9(9) BINARY VALUE 295. 000824C 10 MQFB-IIH-ERROR PIC S9(9) BINARY VALUE 296. 000825C 10 MQFB-NOT-AUTHORIZED-FOR-IMS PIC S9(9) BINARY VALUE 298. 000826C 10 MQFB-DATA-LENGTH-TOO-SHORT PIC S9(9) BINARY VALUE 299. 000827C 10 MQFB-IMS-ERROR PIC S9(9) BINARY VALUE 300. 000828C 10 MQFB-IMS-FIRST PIC S9(9) BINARY VALUE 301. 000829C 10 MQFB-IMS-LAST PIC S9(9) BINARY VALUE 399. 000830C 10 MQFB-CICS-INTERNAL-ERROR PIC S9(9) BINARY VALUE 401. 000831C 10 MQFB-CICS-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 402. 000832C 10 MQFB-CICS-BRIDGE-FAILURE PIC S9(9) BINARY VALUE 403. 000833C 10 MQFB-CICS-CORREL-ID-ERROR PIC S9(9) BINARY VALUE 404. 000834C 10 MQFB-CICS-CCSID-ERROR PIC S9(9) BINARY VALUE 405. 000835C 10 MQFB-CICS-ENCODING-ERROR PIC S9(9) BINARY VALUE 406. 000836C 10 MQFB-CICS-CIH-ERROR PIC S9(9) BINARY VALUE 407. 000837C 10 MQFB-CICS-UOW-ERROR PIC S9(9) BINARY VALUE 408. 000838C 10 MQFB-CICS-COMMAREA-ERROR PIC S9(9) BINARY VALUE 409. 000839C 10 MQFB-CICS-APPL-NOT-STARTED PIC S9(9) BINARY VALUE 410. 000840C 10 MQFB-CICS-APPL-ABENDED PIC S9(9) BINARY VALUE 411. 000841C 10 MQFB-CICS-DLQ-ERROR PIC S9(9) BINARY VALUE 412. 000842C 10 MQFB-CICS-UOW-BACKED-OUT PIC S9(9) BINARY VALUE 413. 000843C 10 MQFB-PUBLICATIONS-ON-REQUEST PIC S9(9) BINARY VALUE 501. 000844C 10 MQFB-SUBSCRIBER-IS-PUBLISHER PIC S9(9) BINARY VALUE 502. 000845C 10 MQFB-MSG-SCOPE-MISMATCH PIC S9(9) BINARY VALUE 503. 000846C 10 MQFB-SELECTOR-MISMATCH PIC S9(9) BINARY VALUE 504. 000847C 10 MQFB-NOT-A-GROUPUR-MSG PIC S9(9) BINARY VALUE 505. 000848C 10 MQFB-IMS-NACK-1A-REASON-FIRST PIC S9(9) BINARY VALUE 600. 000849C 10 MQFB-IMS-NACK-1A-REASON-LAST PIC S9(9) BINARY VALUE 855. 000850C 10 MQFB-SYSTEM-LAST PIC S9(9) BINARY VALUE 65535. 000851C 10 MQFB-APPL-FIRST PIC S9(9) BINARY VALUE 65536. 000852C 10 MQFB-APPL-LAST PIC S9(9) BINARY VALUE 999999999. 000853C 000854C ** Encoding 000855C 10 MQENC-NATIVE PIC S9(9) BINARY VALUE 785. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 19 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000856C 000857C ** Encoding Masks 000858C 10 MQENC-INTEGER-MASK PIC S9(9) BINARY VALUE 15. 000859C 10 MQENC-DECIMAL-MASK PIC S9(9) BINARY VALUE 240. 000860C 10 MQENC-FLOAT-MASK PIC S9(9) BINARY VALUE 3840. 000861C 10 MQENC-RESERVED-MASK PIC S9(9) BINARY VALUE -4096. 000862C 000863C ** Encodings for Binary Integers 000864C 10 MQENC-INTEGER-UNDEFINED PIC S9(9) BINARY VALUE 0. 000865C 10 MQENC-INTEGER-NORMAL PIC S9(9) BINARY VALUE 1. 000866C 10 MQENC-INTEGER-REVERSED PIC S9(9) BINARY VALUE 2. 000867C 000868C ** Encodings for Packed Decimal Integers 000869C 10 MQENC-DECIMAL-UNDEFINED PIC S9(9) BINARY VALUE 0. 000870C 10 MQENC-DECIMAL-NORMAL PIC S9(9) BINARY VALUE 16. 000871C 10 MQENC-DECIMAL-REVERSED PIC S9(9) BINARY VALUE 32. 000872C 000873C ** Encodings for Floating Point Numbers 000874C 10 MQENC-FLOAT-UNDEFINED PIC S9(9) BINARY VALUE 0. 000875C 10 MQENC-FLOAT-IEEE-NORMAL PIC S9(9) BINARY VALUE 256. 000876C 10 MQENC-FLOAT-IEEE-REVERSED PIC S9(9) BINARY VALUE 512. 000877C 10 MQENC-FLOAT-S390 PIC S9(9) BINARY VALUE 768. 000878C 10 MQENC-FLOAT-TNS PIC S9(9) BINARY VALUE 1024. 000879C 000880C ** Encodings for Multicast 000881C 10 MQENC-NORMAL PIC S9(9) BINARY VALUE 273. 000882C 10 MQENC-REVERSED PIC S9(9) BINARY VALUE 546. 000883C 10 MQENC-S390 PIC S9(9) BINARY VALUE 785. 000884C 10 MQENC-TNS PIC S9(9) BINARY VALUE 1041. 000885C 10 MQENC-AS-PUBLISHED PIC S9(9) BINARY VALUE -1. 000886C 000887C ** Coded Character Set Identifiers 000888C 10 MQCCSI-UNDEFINED PIC S9(9) BINARY VALUE 0. 000889C 10 MQCCSI-DEFAULT PIC S9(9) BINARY VALUE 0. 000890C 10 MQCCSI-Q-MGR PIC S9(9) BINARY VALUE 0. 000891C 10 MQCCSI-INHERIT PIC S9(9) BINARY VALUE -2. 000892C 10 MQCCSI-EMBEDDED PIC S9(9) BINARY VALUE -1. 000893C 10 MQCCSI-APPL PIC S9(9) BINARY VALUE -3. 000894C 10 MQCCSI-AS-PUBLISHED PIC S9(9) BINARY VALUE -4. 000895C 000896C ** Formats 000897C 10 MQFMT-NONE PIC X(8) VALUE SPACES. 000898C 10 MQFMT-ADMIN PIC X(8) VALUE 'MQADMIN '. 000899C 10 MQFMT-AMQP PIC X(8) VALUE 'MQAMQP '. 000900C 10 MQFMT-CHANNEL-COMPLETED PIC X(8) VALUE 'MQCHCOM '. 000901C 10 MQFMT-CICS PIC X(8) VALUE 'MQCICS '. 000902C 10 MQFMT-COMMAND-1 PIC X(8) VALUE 'MQCMD1 '. 000903C 10 MQFMT-COMMAND-2 PIC X(8) VALUE 'MQCMD2 '. 000904C 10 MQFMT-DEAD-LETTER-HEADER PIC X(8) VALUE 'MQDEAD '. 000905C 10 MQFMT-DIST-HEADER PIC X(8) VALUE 'MQHDIST '. 000906C 10 MQFMT-EMBEDDED-PCF PIC X(8) VALUE 'MQHEPCF '. 000907C 10 MQFMT-EVENT PIC X(8) VALUE 'MQEVENT '. 000908C 10 MQFMT-IMS PIC X(8) VALUE 'MQIMS '. 000909C 10 MQFMT-IMS-VAR-STRING PIC X(8) VALUE 'MQIMSVS '. 000910C 10 MQFMT-MD-EXTENSION PIC X(8) VALUE 'MQHMDE '. 000911C 10 MQFMT-PCF PIC X(8) VALUE 'MQPCF '. 000912C 10 MQFMT-REF-MSG-HEADER PIC X(8) VALUE 'MQHREF '. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 20 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000913C 10 MQFMT-RF-HEADER PIC X(8) VALUE 'MQHRF '. 000914C 10 MQFMT-RF-HEADER-1 PIC X(8) VALUE 'MQHRF '. 000915C 10 MQFMT-RF-HEADER-2 PIC X(8) VALUE 'MQHRF2 '. 000916C 10 MQFMT-STRING PIC X(8) VALUE 'MQSTR '. 000917C 10 MQFMT-TRIGGER PIC X(8) VALUE 'MQTRIG '. 000918C 10 MQFMT-WORK-INFO-HEADER PIC X(8) VALUE 'MQHWIH '. 000919C 10 MQFMT-XMIT-Q-HEADER PIC X(8) VALUE 'MQXMIT '. 000920C 000921C ** Priority 000922C 10 MQPRI-PRIORITY-AS-Q-DEF PIC S9(9) BINARY VALUE -1. 000923C 10 MQPRI-PRIORITY-AS-PARENT PIC S9(9) BINARY VALUE -2. 000924C 10 MQPRI-PRIORITY-AS-PUBLISHED PIC S9(9) BINARY VALUE -3. 000925C 10 MQPRI-PRIORITY-AS-TOPIC-DEF PIC S9(9) BINARY VALUE -1. 000926C 000927C ** Persistence Values 000928C 10 MQPER-PERSISTENCE-AS-PARENT PIC S9(9) BINARY VALUE -1. 000929C 10 MQPER-NOT-PERSISTENT PIC S9(9) BINARY VALUE 0. 000930C 10 MQPER-PERSISTENT PIC S9(9) BINARY VALUE 1. 000931C 10 MQPER-PERSISTENCE-AS-Q-DEF PIC S9(9) BINARY VALUE 2. 000932C 10 MQPER-PERSISTENCE-AS-TOPIC-DEF PIC S9(9) BINARY VALUE 2. 000933C 000934C ** Put Response Values 000935C 10 MQPRT-RESPONSE-AS-PARENT PIC S9(9) BINARY VALUE 0. 000936C 10 MQPRT-SYNC-RESPONSE PIC S9(9) BINARY VALUE 1. 000937C 10 MQPRT-ASYNC-RESPONSE PIC S9(9) BINARY VALUE 2. 000938C 000939C ** Message Identifier 000940C 10 MQMI-NONE PIC X(24) VALUE LOW-VALUES. 000941C 000942C ** Correlation Identifier 000943C 10 MQCI-NONE PIC X(24) VALUE LOW-VALUES. 000944C 10 MQCI-NEW-SESSION PIC X(24) 000945C VALUE X'414D51214E45575F53455353494F4E5F434F5252454C4944'. 000946C 000947C ** Accounting Token 000948C 10 MQACT-NONE PIC X(32) VALUE LOW-VALUES. 000949C 000950C ** Put Application Types 000951C 10 MQAT-UNKNOWN PIC S9(9) BINARY VALUE -1. 000952C 10 MQAT-NO-CONTEXT PIC S9(9) BINARY VALUE 0. 000953C 10 MQAT-CICS PIC S9(9) BINARY VALUE 1. 000954C 10 MQAT-MVS PIC S9(9) BINARY VALUE 2. 000955C 10 MQAT-OS390 PIC S9(9) BINARY VALUE 2. 000956C 10 MQAT-ZOS PIC S9(9) BINARY VALUE 2. 000957C 10 MQAT-IMS PIC S9(9) BINARY VALUE 3. 000958C 10 MQAT-OS2 PIC S9(9) BINARY VALUE 4. 000959C 10 MQAT-DOS PIC S9(9) BINARY VALUE 5. 000960C 10 MQAT-AIX PIC S9(9) BINARY VALUE 6. 000961C 10 MQAT-UNIX PIC S9(9) BINARY VALUE 6. 000962C 10 MQAT-QMGR PIC S9(9) BINARY VALUE 7. 000963C 10 MQAT-OS400 PIC S9(9) BINARY VALUE 8. 000964C 10 MQAT-WINDOWS PIC S9(9) BINARY VALUE 9. 000965C 10 MQAT-CICS-VSE PIC S9(9) BINARY VALUE 10. 000966C 10 MQAT-WINDOWS-NT PIC S9(9) BINARY VALUE 11. 000967C 10 MQAT-VMS PIC S9(9) BINARY VALUE 12. 000968C 10 MQAT-GUARDIAN PIC S9(9) BINARY VALUE 13. 000969C 10 MQAT-NSK PIC S9(9) BINARY VALUE 13. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 21 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 000970C 10 MQAT-VOS PIC S9(9) BINARY VALUE 14. 000971C 10 MQAT-OPEN-TP1 PIC S9(9) BINARY VALUE 15. 000972C 10 MQAT-VM PIC S9(9) BINARY VALUE 18. 000973C 10 MQAT-IMS-BRIDGE PIC S9(9) BINARY VALUE 19. 000974C 10 MQAT-XCF PIC S9(9) BINARY VALUE 20. 000975C 10 MQAT-CICS-BRIDGE PIC S9(9) BINARY VALUE 21. 000976C 10 MQAT-NOTES-AGENT PIC S9(9) BINARY VALUE 22. 000977C 10 MQAT-TPF PIC S9(9) BINARY VALUE 23. 000978C 10 MQAT-USER PIC S9(9) BINARY VALUE 25. 000979C 10 MQAT-BROKER PIC S9(9) BINARY VALUE 26. 000980C 10 MQAT-QMGR-PUBLISH PIC S9(9) BINARY VALUE 26. 000981C 10 MQAT-JAVA PIC S9(9) BINARY VALUE 28. 000982C 10 MQAT-DQM PIC S9(9) BINARY VALUE 29. 000983C 10 MQAT-CHANNEL-INITIATOR PIC S9(9) BINARY VALUE 30. 000984C 10 MQAT-WLM PIC S9(9) BINARY VALUE 31. 000985C 10 MQAT-BATCH PIC S9(9) BINARY VALUE 32. 000986C 10 MQAT-RRS-BATCH PIC S9(9) BINARY VALUE 33. 000987C 10 MQAT-SIB PIC S9(9) BINARY VALUE 34. 000988C 10 MQAT-SYSTEM-EXTENSION PIC S9(9) BINARY VALUE 35. 000989C 10 MQAT-MCAST-PUBLISH PIC S9(9) BINARY VALUE 36. 000990C 10 MQAT-AMQP PIC S9(9) BINARY VALUE 37. 000991C 10 MQAT-DEFAULT PIC S9(9) BINARY VALUE 2. 000992C 10 MQAT-USER-FIRST PIC S9(9) BINARY VALUE 65536. 000993C 10 MQAT-USER-LAST PIC S9(9) BINARY VALUE 999999999. 000994C 000995C ** Group Identifier 000996C 10 MQGI-NONE PIC X(24) VALUE LOW-VALUES. 000997C 000998C ** Message Flags 000999C 10 MQMF-SEGMENTATION-INHIBITED PIC S9(9) BINARY VALUE 0. 001000C 10 MQMF-SEGMENTATION-ALLOWED PIC S9(9) BINARY VALUE 1. 001001C 10 MQMF-MSG-IN-GROUP PIC S9(9) BINARY VALUE 8. 001002C 10 MQMF-LAST-MSG-IN-GROUP PIC S9(9) BINARY VALUE 16. 001003C 10 MQMF-SEGMENT PIC S9(9) BINARY VALUE 2. 001004C 10 MQMF-LAST-SEGMENT PIC S9(9) BINARY VALUE 4. 001005C 10 MQMF-NONE PIC S9(9) BINARY VALUE 0. 001006C 001007C ** Message Flags Masks 001008C 10 MQMF-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE 4095. 001009C 10 MQMF-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE -1048576. 001010C 10 MQMF-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 001011C VALUE 1044480. 001012C 001013C ** Original Length 001014C 10 MQOL-UNDEFINED PIC S9(9) BINARY VALUE -1. 001015C 001016C ****************************************************************** 001017C ** Values Related to MQMDE Structure 001018C ****************************************************************** 001019C ** Structure Identifier 001020C 10 MQMDE-STRUC-ID PIC X(4) VALUE 'MDE '. 001021C 001022C ** Structure Version Number 001023C 10 MQMDE-VERSION-2 PIC S9(9) BINARY VALUE 2. 001024C 10 MQMDE-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 001025C 001026C ** Structure Length 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 22 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001027C 10 MQMDE-LENGTH-2 PIC S9(9) BINARY VALUE 72. 001028C 10 MQMDE-CURRENT-LENGTH PIC S9(9) BINARY VALUE 72. 001029C 001030C ** Flags 001031C 10 MQMDEF-NONE PIC S9(9) BINARY VALUE 0. 001032C 001033C ****************************************************************** 001034C ** Values Related to MQMD1 Structure 001035C ****************************************************************** 001036C ** Structure Length 001037C 10 MQMD1-LENGTH-1 PIC S9(9) BINARY VALUE 324. 001038C 10 MQMD1-CURRENT-LENGTH PIC S9(9) BINARY VALUE 324. 001039C 001040C ****************************************************************** 001041C ** Values Related to MQMD2 Structure 001042C ****************************************************************** 001043C ** Structure Length 001044C 10 MQMD2-LENGTH-1 PIC S9(9) BINARY VALUE 324. 001045C 10 MQMD2-LENGTH-2 PIC S9(9) BINARY VALUE 364. 001046C 10 MQMD2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 364. 001047C 001048C ****************************************************************** 001049C ** Values Related to MQMHBO Structure 001050C ****************************************************************** 001051C ** Structure Identifier 001052C 10 MQMHBO-STRUC-ID PIC X(4) VALUE 'MHBO'. 001053C 001054C ** Structure Version Number 001055C 10 MQMHBO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001056C 10 MQMHBO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001057C 001058C ** Structure Length 001059C 10 MQMHBO-LENGTH-1 PIC S9(9) BINARY VALUE 12. 001060C 10 MQMHBO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 12. 001061C 001062C ** Message Handle To Buffer Options 001063C 10 MQMHBO-PROPERTIES-IN-MQRFH2 PIC S9(9) BINARY VALUE 1. 001064C 10 MQMHBO-DELETE-PROPERTIES PIC S9(9) BINARY VALUE 2. 001065C 10 MQMHBO-NONE PIC S9(9) BINARY VALUE 0. 001066C 001067C ****************************************************************** 001068C ** Values Related to MQOD Structure 001069C ****************************************************************** 001070C ** Structure Identifier 001071C 10 MQOD-STRUC-ID PIC X(4) VALUE 'OD '. 001072C 001073C ** Structure Version Number 001074C 10 MQOD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001075C 10 MQOD-VERSION-2 PIC S9(9) BINARY VALUE 2. 001076C 10 MQOD-VERSION-3 PIC S9(9) BINARY VALUE 3. 001077C 10 MQOD-VERSION-4 PIC S9(9) BINARY VALUE 4. 001078C 10 MQOD-CURRENT-VERSION PIC S9(9) BINARY VALUE 4. 001079C 001080C ** Structure Length 001081C 10 MQOD-LENGTH-1 PIC S9(9) BINARY VALUE 168. 001082C 10 MQOD-LENGTH-2 PIC S9(9) BINARY VALUE 200. 001083C 10 MQOD-LENGTH-3 PIC S9(9) BINARY VALUE 336. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 23 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001084C 10 MQOD-LENGTH-4 PIC S9(9) BINARY VALUE 400. 001085C 10 MQOD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 400. 001086C 001087C ** Obsolete DB2 Messages options on Inquire Group 001088C 10 MQOM-NO PIC S9(9) BINARY VALUE 0. 001089C 10 MQOM-YES PIC S9(9) BINARY VALUE 1. 001090C 001091C ** Object Types 001092C 10 MQOT-NONE PIC S9(9) BINARY VALUE 0. 001093C 10 MQOT-Q PIC S9(9) BINARY VALUE 1. 001094C 10 MQOT-NAMELIST PIC S9(9) BINARY VALUE 2. 001095C 10 MQOT-PROCESS PIC S9(9) BINARY VALUE 3. 001096C 10 MQOT-STORAGE-CLASS PIC S9(9) BINARY VALUE 4. 001097C 10 MQOT-Q-MGR PIC S9(9) BINARY VALUE 5. 001098C 10 MQOT-CHANNEL PIC S9(9) BINARY VALUE 6. 001099C 10 MQOT-AUTH-INFO PIC S9(9) BINARY VALUE 7. 001100C 10 MQOT-TOPIC PIC S9(9) BINARY VALUE 8. 001101C 10 MQOT-COMM-INFO PIC S9(9) BINARY VALUE 9. 001102C 10 MQOT-CF-STRUC PIC S9(9) BINARY VALUE 10. 001103C 10 MQOT-LISTENER PIC S9(9) BINARY VALUE 11. 001104C 10 MQOT-SERVICE PIC S9(9) BINARY VALUE 12. 001105C 10 MQOT-RESERVED-1 PIC S9(9) BINARY VALUE 999. 001106C 001107C ** Extended Object Types 001108C 10 MQOT-ALL PIC S9(9) BINARY VALUE 1001. 001109C 10 MQOT-ALIAS-Q PIC S9(9) BINARY VALUE 1002. 001110C 10 MQOT-MODEL-Q PIC S9(9) BINARY VALUE 1003. 001111C 10 MQOT-LOCAL-Q PIC S9(9) BINARY VALUE 1004. 001112C 10 MQOT-REMOTE-Q PIC S9(9) BINARY VALUE 1005. 001113C 10 MQOT-SENDER-CHANNEL PIC S9(9) BINARY VALUE 1007. 001114C 10 MQOT-SERVER-CHANNEL PIC S9(9) BINARY VALUE 1008. 001115C 10 MQOT-REQUESTER-CHANNEL PIC S9(9) BINARY VALUE 1009. 001116C 10 MQOT-RECEIVER-CHANNEL PIC S9(9) BINARY VALUE 1010. 001117C 10 MQOT-CURRENT-CHANNEL PIC S9(9) BINARY VALUE 1011. 001118C 10 MQOT-SAVED-CHANNEL PIC S9(9) BINARY VALUE 1012. 001119C 10 MQOT-SVRCONN-CHANNEL PIC S9(9) BINARY VALUE 1013. 001120C 10 MQOT-CLNTCONN-CHANNEL PIC S9(9) BINARY VALUE 1014. 001121C 10 MQOT-SHORT-CHANNEL PIC S9(9) BINARY VALUE 1015. 001122C 10 MQOT-CHLAUTH PIC S9(9) BINARY VALUE 1016. 001123C 10 MQOT-REMOTE-Q-MGR-NAME PIC S9(9) BINARY VALUE 1017. 001124C 10 MQOT-PROT-POLICY PIC S9(9) BINARY VALUE 1019. 001125C 10 MQOT-TT-CHANNEL PIC S9(9) BINARY VALUE 1020. 001126C 10 MQOT-AMQP-CHANNEL PIC S9(9) BINARY VALUE 1021. 001127C 10 MQOT-AUTH-REC PIC S9(9) BINARY VALUE 1022. 001128C 001129C ****************************************************************** 001130C ** Values Related to MQPD Structure 001131C ****************************************************************** 001132C ** Structure Identifier 001133C 10 MQPD-STRUC-ID PIC X(4) VALUE 'PD '. 001134C 001135C ** Structure Version Number 001136C 10 MQPD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001137C 10 MQPD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001138C 001139C ** Structure Length 001140C 10 MQPD-LENGTH-1 PIC S9(9) BINARY VALUE 24. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 24 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001141C 10 MQPD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 24. 001142C 001143C ** Property Descriptor Options 001144C 10 MQPD-NONE PIC S9(9) BINARY VALUE 0. 001145C 001146C ** Property Support Options 001147C 10 MQPD-SUPPORT-OPTIONAL PIC S9(9) BINARY VALUE 1. 001148C 10 MQPD-SUPPORT-REQUIRED PIC S9(9) BINARY VALUE 1048576. 001149C 10 MQPD-SUPPORT-REQUIRED-IF-LOCAL PIC S9(9) BINARY VALUE 1024. 001150C 10 MQPD-REJECT-UNSUP-MASK PIC S9(9) BINARY VALUE -1048576. 001151C 10 MQPD-ACCEPT-UNSUP-IF-XMIT-MASK PIC S9(9) BINARY 001152C VALUE 1047552. 001153C 10 MQPD-ACCEPT-UNSUP-MASK PIC S9(9) BINARY VALUE 1023. 001154C 001155C ** Property Context 001156C 10 MQPD-NO-CONTEXT PIC S9(9) BINARY VALUE 0. 001157C 10 MQPD-USER-CONTEXT PIC S9(9) BINARY VALUE 1. 001158C 001159C ** Property Copy Options 001160C 10 MQCOPY-NONE PIC S9(9) BINARY VALUE 0. 001161C 10 MQCOPY-ALL PIC S9(9) BINARY VALUE 1. 001162C 10 MQCOPY-FORWARD PIC S9(9) BINARY VALUE 2. 001163C 10 MQCOPY-PUBLISH PIC S9(9) BINARY VALUE 4. 001164C 10 MQCOPY-REPLY PIC S9(9) BINARY VALUE 8. 001165C 10 MQCOPY-REPORT PIC S9(9) BINARY VALUE 16. 001166C 10 MQCOPY-DEFAULT PIC S9(9) BINARY VALUE 22. 001167C 001168C ****************************************************************** 001169C ** Values Related to MQPMO Structure 001170C ****************************************************************** 001171C ** Structure Identifier 001172C 10 MQPMO-STRUC-ID PIC X(4) VALUE 'PMO '. 001173C 001174C ** Structure Version Number 001175C 10 MQPMO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001176C 10 MQPMO-VERSION-2 PIC S9(9) BINARY VALUE 2. 001177C 10 MQPMO-VERSION-3 PIC S9(9) BINARY VALUE 3. 001178C 10 MQPMO-CURRENT-VERSION PIC S9(9) BINARY VALUE 3. 001179C 001180C ** Structure Length 001181C 10 MQPMO-LENGTH-1 PIC S9(9) BINARY VALUE 128. 001182C 10 MQPMO-LENGTH-2 PIC S9(9) BINARY VALUE 152. 001183C 10 MQPMO-LENGTH-3 PIC S9(9) BINARY VALUE 176. 001184C 10 MQPMO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 176. 001185C 001186C ** Put Message Options 001187C 10 MQPMO-SYNCPOINT PIC S9(9) BINARY VALUE 2. 001188C 10 MQPMO-NO-SYNCPOINT PIC S9(9) BINARY VALUE 4. 001189C 10 MQPMO-DEFAULT-CONTEXT PIC S9(9) BINARY VALUE 32. 001190C 10 MQPMO-NEW-MSG-ID PIC S9(9) BINARY VALUE 64. 001191C 10 MQPMO-NEW-CORREL-ID PIC S9(9) BINARY VALUE 128. 001192C 10 MQPMO-PASS-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 256. 001193C 10 MQPMO-PASS-ALL-CONTEXT PIC S9(9) BINARY VALUE 512. 001194C 10 MQPMO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 1024. 001195C 10 MQPMO-SET-ALL-CONTEXT PIC S9(9) BINARY VALUE 2048. 001196C 10 MQPMO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY VALUE 4096. 001197C 10 MQPMO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 25 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001198C 10 MQPMO-NO-CONTEXT PIC S9(9) BINARY VALUE 16384. 001199C 10 MQPMO-LOGICAL-ORDER PIC S9(9) BINARY VALUE 32768. 001200C 10 MQPMO-ASYNC-RESPONSE PIC S9(9) BINARY VALUE 65536. 001201C 10 MQPMO-SYNC-RESPONSE PIC S9(9) BINARY VALUE 131072. 001202C 10 MQPMO-RESOLVE-LOCAL-Q PIC S9(9) BINARY VALUE 262144. 001203C 10 MQPMO-WARN-IF-NO-SUBS-MATCHED PIC S9(9) BINARY 001204C VALUE 524288. 001205C 10 MQPMO-RETAIN PIC S9(9) BINARY VALUE 2097152. 001206C 10 MQPMO-MD-FOR-OUTPUT-ONLY PIC S9(9) BINARY VALUE 8388608. 001207C 10 MQPMO-SCOPE-QMGR PIC S9(9) BINARY VALUE 67108864. 001208C 10 MQPMO-SUPPRESS-REPLYTO PIC S9(9) BINARY VALUE 134217728. 001209C 10 MQPMO-NOT-OWN-SUBS PIC S9(9) BINARY VALUE 268435456. 001210C 10 MQPMO-RESPONSE-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 001211C 10 MQPMO-RESPONSE-AS-TOPIC-DEF PIC S9(9) BINARY VALUE 0. 001212C 10 MQPMO-NONE PIC S9(9) BINARY VALUE 0. 001213C 001214C ** Put Message Options for publish mask 001215C 10 MQPMO-PUB-OPTIONS-MASK PIC S9(9) BINARY VALUE 2097152. 001216C 001217C ** Put Message Record Fields 001218C 10 MQPMRF-MSG-ID PIC S9(9) BINARY VALUE 1. 001219C 10 MQPMRF-CORREL-ID PIC S9(9) BINARY VALUE 2. 001220C 10 MQPMRF-GROUP-ID PIC S9(9) BINARY VALUE 4. 001221C 10 MQPMRF-FEEDBACK PIC S9(9) BINARY VALUE 8. 001222C 10 MQPMRF-ACCOUNTING-TOKEN PIC S9(9) BINARY VALUE 16. 001223C 10 MQPMRF-NONE PIC S9(9) BINARY VALUE 0. 001224C 001225C ** Action 001226C 10 MQACTP-NEW PIC S9(9) BINARY VALUE 0. 001227C 10 MQACTP-FORWARD PIC S9(9) BINARY VALUE 1. 001228C 10 MQACTP-REPLY PIC S9(9) BINARY VALUE 2. 001229C 10 MQACTP-REPORT PIC S9(9) BINARY VALUE 3. 001230C 001231C ****************************************************************** 001232C ** Values Related to MQRFH Structure 001233C ****************************************************************** 001234C ** Structure Identifier 001235C 10 MQRFH-STRUC-ID PIC X(4) VALUE 'RFH '. 001236C 001237C ** Structure Version Number 001238C 10 MQRFH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001239C 10 MQRFH-VERSION-2 PIC S9(9) BINARY VALUE 2. 001240C 001241C ** Structure Length 001242C 10 MQRFH-STRUC-LENGTH-FIXED PIC S9(9) BINARY VALUE 32. 001243C 10 MQRFH-STRUC-LENGTH-FIXED-2 PIC S9(9) BINARY VALUE 36. 001244C 10 MQRFH-LENGTH-1 PIC S9(9) BINARY VALUE 32. 001245C 10 MQRFH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 32. 001246C 001247C ** Flags 001248C 10 MQRFH-NONE PIC S9(9) BINARY VALUE 0. 001249C 10 MQRFH-NO-FLAGS PIC S9(9) BINARY VALUE 0. 001250C 10 MQRFH-FLAGS-RESTRICTED-MASK PIC S9(9) BINARY VALUE -65536. 001251C ** MQRFH2 flags in the restricted mask are reserved for MQ use: 001252C 001253C ** 0x80000000 - MQRFH_INTERNAL - This flag indicates the RFH2 001254C ** header was created by IBM MQ for internal use. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 26 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001255C 001256C 001257C ** Names for Name/Value String 001258C 10 MQNVS-APPL-TYPE PIC X(12) VALUE 'OPT_APP_GRP '. 001259C 10 MQNVS-MSG-TYPE PIC X(13) VALUE 'OPT_MSG_TYPE '. 001260C 001261C ****************************************************************** 001262C ** Values Related to MQRFH2 Structure 001263C ****************************************************************** 001264C ** Structure Length 001265C 10 MQRFH2-LENGTH-2 PIC S9(9) BINARY VALUE 36. 001266C 10 MQRFH2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 36. 001267C 001268C ****************************************************************** 001269C ** Values Related to MQRMH Structure 001270C ****************************************************************** 001271C ** Structure Identifier 001272C 10 MQRMH-STRUC-ID PIC X(4) VALUE 'RMH '. 001273C 001274C ** Structure Version Number 001275C 10 MQRMH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001276C 10 MQRMH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001277C 001278C ** Structure Length 001279C 10 MQRMH-LENGTH-1 PIC S9(9) BINARY VALUE 108. 001280C 10 MQRMH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 108. 001281C 001282C ** Flags 001283C 10 MQRMHF-LAST PIC S9(9) BINARY VALUE 1. 001284C 10 MQRMHF-NOT-LAST PIC S9(9) BINARY VALUE 0. 001285C 001286C ** Object Instance Identifier 001287C 10 MQOII-NONE PIC X(24) VALUE LOW-VALUES. 001288C 001289C ****************************************************************** 001290C ** Values Related to MQSD Structure 001291C ****************************************************************** 001292C ** Structure Identifier 001293C 10 MQSD-STRUC-ID PIC X(4) VALUE 'SD '. 001294C 001295C ** Structure Version Number 001296C 10 MQSD-VERSION-1 PIC S9(9) BINARY VALUE 1. 001297C 10 MQSD-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001298C 001299C ** Structure Length 001300C 10 MQSD-LENGTH-1 PIC S9(9) BINARY VALUE 312. 001301C 10 MQSD-CURRENT-LENGTH PIC S9(9) BINARY VALUE 312. 001302C 001303C ** Security Identifier 001304C 10 MQSID-NONE PIC X(40) VALUE LOW-VALUES. 001305C 001306C ** Security Identifier Types 001307C 10 MQSIDT-NONE PIC X VALUE X'00'. 001308C 10 MQSIDT-NT-SECURITY-ID PIC X VALUE X'01'. 001309C 10 MQSIDT-WAS-SECURITY-ID PIC X VALUE X'02'. 001310C 001311C ****************************************************************** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 27 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001312C ** Values Related to MQSMPO Structure 001313C ****************************************************************** 001314C ** Structure Identifier 001315C 10 MQSMPO-STRUC-ID PIC X(4) VALUE 'SMPO'. 001316C 001317C ** Structure Version Number 001318C 10 MQSMPO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001319C 10 MQSMPO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001320C 001321C ** Structure Length 001322C 10 MQSMPO-LENGTH-1 PIC S9(9) BINARY VALUE 20. 001323C 10 MQSMPO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 20. 001324C 001325C ** Set Message Property Options 001326C 10 MQSMPO-SET-FIRST PIC S9(9) BINARY VALUE 0. 001327C 10 MQSMPO-SET-PROP-UNDER-CURSOR PIC S9(9) BINARY VALUE 1. 001328C 10 MQSMPO-SET-PROP-AFTER-CURSOR PIC S9(9) BINARY VALUE 2. 001329C 10 MQSMPO-APPEND-PROPERTY PIC S9(9) BINARY VALUE 4. 001330C 10 MQSMPO-SET-PROP-BEFORE-CURSOR PIC S9(9) BINARY VALUE 8. 001331C 10 MQSMPO-NONE PIC S9(9) BINARY VALUE 0. 001332C 001333C ****************************************************************** 001334C ** Values Related to MQSRO Structure 001335C ****************************************************************** 001336C ** Structure Identifier 001337C 10 MQSRO-STRUC-ID PIC X(4) VALUE 'SRO '. 001338C 001339C ** Structure Version Number 001340C 10 MQSRO-VERSION-1 PIC S9(9) BINARY VALUE 1. 001341C 10 MQSRO-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001342C 001343C ** Structure Length 001344C 10 MQSRO-LENGTH-1 PIC S9(9) BINARY VALUE 16. 001345C 10 MQSRO-CURRENT-LENGTH PIC S9(9) BINARY VALUE 16. 001346C 001347C ** Subscription Request Options 001348C 10 MQSRO-NONE PIC S9(9) BINARY VALUE 0. 001349C 10 MQSRO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 001350C 001351C ****************************************************************** 001352C ** Values Related to MQSTS Structure 001353C ****************************************************************** 001354C ** Structure Identifier 001355C 10 MQSTS-STRUC-ID PIC X(4) VALUE 'STAT'. 001356C 001357C ** Structure Version Number 001358C 10 MQSTS-VERSION-1 PIC S9(9) BINARY VALUE 1. 001359C 10 MQSTS-VERSION-2 PIC S9(9) BINARY VALUE 2. 001360C 10 MQSTS-CURRENT-VERSION PIC S9(9) BINARY VALUE 2. 001361C 001362C ** Structure Length 001363C 10 MQSTS-LENGTH-1 PIC S9(9) BINARY VALUE 224. 001364C 10 MQSTS-LENGTH-2 PIC S9(9) BINARY VALUE 272. 001365C 10 MQSTS-CURRENT-LENGTH PIC S9(9) BINARY VALUE 272. 001366C 001367C ****************************************************************** 001368C ** Values Related to MQTM Structure 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 28 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001369C ****************************************************************** 001370C ** Structure Identifier 001371C 10 MQTM-STRUC-ID PIC X(4) VALUE 'TM '. 001372C 001373C ** Structure Version Number 001374C 10 MQTM-VERSION-1 PIC S9(9) BINARY VALUE 1. 001375C 10 MQTM-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001376C 001377C ** Structure Length 001378C 10 MQTM-LENGTH-1 PIC S9(9) BINARY VALUE 684. 001379C 10 MQTM-CURRENT-LENGTH PIC S9(9) BINARY VALUE 684. 001380C 001381C ****************************************************************** 001382C ** Values Related to MQTMC2 Structure 001383C ****************************************************************** 001384C ** Structure Identifier 001385C 10 MQTMC-STRUC-ID PIC X(4) VALUE 'TMC '. 001386C 001387C ** Structure Length 001388C 10 MQTMC2-LENGTH-1 PIC S9(9) BINARY VALUE 684. 001389C 10 MQTMC2-LENGTH-2 PIC S9(9) BINARY VALUE 732. 001390C 10 MQTMC2-CURRENT-LENGTH PIC S9(9) BINARY VALUE 732. 001391C 001392C ** Structure Version Number 001393C 10 MQTMC-VERSION-1 PIC X(4) VALUE ' 1'. 001394C 10 MQTMC-VERSION-2 PIC X(4) VALUE ' 2'. 001395C 10 MQTMC-CURRENT-VERSION PIC X(4) VALUE ' 2'. 001396C 001397C ****************************************************************** 001398C ** Values Related to MQWIH Structure 001399C ****************************************************************** 001400C ** Structure Identifier 001401C 10 MQWIH-STRUC-ID PIC X(4) VALUE 'WIH '. 001402C 001403C ** Structure Version Number 001404C 10 MQWIH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001405C 10 MQWIH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001406C 001407C ** Structure Length 001408C 10 MQWIH-LENGTH-1 PIC S9(9) BINARY VALUE 120. 001409C 10 MQWIH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 120. 001410C 001411C ** Flags 001412C 10 MQWIH-NONE PIC S9(9) BINARY VALUE 0. 001413C 001414C ****************************************************************** 001415C ** Values Related to MQXQH Structure 001416C ****************************************************************** 001417C ** Structure Identifier 001418C 10 MQXQH-STRUC-ID PIC X(4) VALUE 'XQH '. 001419C 001420C ** Structure Version Number 001421C 10 MQXQH-VERSION-1 PIC S9(9) BINARY VALUE 1. 001422C 10 MQXQH-CURRENT-VERSION PIC S9(9) BINARY VALUE 1. 001423C 001424C ** Structure Length 001425C 10 MQXQH-LENGTH-1 PIC S9(9) BINARY VALUE 428. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 29 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001426C 10 MQXQH-CURRENT-LENGTH PIC S9(9) BINARY VALUE 428. 001427C 001428C ** 001429C 001430C ****************************************************************** 001431C ** Values Related to All Functions 001432C ****************************************************************** 001433C ** Connection Handles 001434C 10 MQHC-DEF-HCONN PIC S9(9) COMP-5 VALUE 0. 001435C 10 MQHC-UNUSABLE-HCONN PIC S9(9) COMP-5 VALUE -1. 001436C 10 MQHC-UNASSOCIATED-HCONN PIC S9(9) COMP-5 VALUE -3. 001437C 001438C ** String Lengths 001439C 10 MQ-OPERATOR-MESSAGE-LENGTH PIC S9(9) BINARY VALUE 4. 001440C 10 MQ-ABEND-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001441C 10 MQ-ACCOUNTING-TOKEN-LENGTH PIC S9(9) BINARY VALUE 32. 001442C 10 MQ-APPL-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001443C 10 MQ-APPL-IDENTITY-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001444C 10 MQ-APPL-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001445C 10 MQ-APPL-ORIGIN-DATA-LENGTH PIC S9(9) BINARY VALUE 4. 001446C 10 MQ-APPL-TAG-LENGTH PIC S9(9) BINARY VALUE 28. 001447C 10 MQ-ARM-SUFFIX-LENGTH PIC S9(9) BINARY VALUE 2. 001448C 10 MQ-ATTENTION-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001449C 10 MQ-AUTH-INFO-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 264. 001450C 10 MQ-AUTH-INFO-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001451C 10 MQ-AUTH-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001452C 10 MQ-AUTH-INFO-OCSP-URL-LENGTH PIC S9(9) BINARY VALUE 256. 001453C 10 MQ-AUTHENTICATOR-LENGTH PIC S9(9) BINARY VALUE 8. 001454C 10 MQ-AUTO-REORG-CATALOG-LENGTH PIC S9(9) BINARY VALUE 44. 001455C 10 MQ-AUTO-REORG-TIME-LENGTH PIC S9(9) BINARY VALUE 4. 001456C 10 MQ-BATCH-INTERFACE-ID-LENGTH PIC S9(9) BINARY VALUE 8. 001457C 10 MQ-BRIDGE-NAME-LENGTH PIC S9(9) BINARY VALUE 24. 001458C 10 MQ-CANCEL-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001459C 10 MQ-CF-STRUC-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001460C 10 MQ-CF-STRUC-NAME-LENGTH PIC S9(9) BINARY VALUE 12. 001461C 10 MQ-CHANNEL-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001462C 10 MQ-CHANNEL-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001463C 10 MQ-CHANNEL-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001464C 10 MQ-CHANNEL-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001465C 10 MQ-CHINIT-SERVICE-PARM-LENGTH PIC S9(9) BINARY VALUE 32. 001466C 10 MQ-CICS-FILE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001467C 10 MQ-AMQP-CLIENT-ID-LENGTH PIC S9(9) BINARY VALUE 256. 001468C 10 MQ-CLIENT-ID-LENGTH PIC S9(9) BINARY VALUE 23. 001469C 10 MQ-CLIENT-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001470C 10 MQ-CLUSTER-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001471C 10 MQ-COMM-INFO-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001472C 10 MQ-COMM-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001473C 10 MQ-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 264. 001474C 10 MQ-CONN-TAG-LENGTH PIC S9(9) BINARY VALUE 128. 001475C 10 MQ-CONNECTION-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001476C 10 MQ-CORREL-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001477C 10 MQ-CREATION-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001478C 10 MQ-CREATION-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001479C 10 MQ-CSP-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 256. 001480C 10 MQ-CSP-TOKEN-LENGTH PIC S9(9) BINARY VALUE 8192. 001481C 10 MQ-DATE-LENGTH PIC S9(9) BINARY VALUE 12. 001482C 10 MQ-DISTINGUISHED-NAME-LENGTH PIC S9(9) BINARY VALUE 1024. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 30 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001483C 10 MQ-DNS-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 18. 001484C 10 MQ-EXIT-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001485C 10 MQ-EXIT-INFO-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001486C 10 MQ-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001487C 10 MQ-EXIT-PD-AREA-LENGTH PIC S9(9) BINARY VALUE 48. 001488C 10 MQ-EXIT-USER-AREA-LENGTH PIC S9(9) BINARY VALUE 16. 001489C 10 MQ-FACILITY-LENGTH PIC S9(9) BINARY VALUE 8. 001490C 10 MQ-FACILITY-LIKE-LENGTH PIC S9(9) BINARY VALUE 4. 001491C 10 MQ-FORMAT-LENGTH PIC S9(9) BINARY VALUE 8. 001492C 10 MQ-FUNCTION-LENGTH PIC S9(9) BINARY VALUE 4. 001493C 10 MQ-GROUP-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001494C 10 MQ-APPL-FUNCTION-NAME-LENGTH PIC S9(9) BINARY VALUE 10. 001495C 10 MQ-INITIAL-KEY-LENGTH PIC S9(9) BINARY VALUE 256. 001496C 10 MQ-INSTALLATION-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001497C 10 MQ-INSTALLATION-NAME-LENGTH PIC S9(9) BINARY VALUE 16. 001498C 10 MQ-INSTALLATION-PATH-LENGTH PIC S9(9) BINARY VALUE 256. 001499C 10 MQ-ISOTIME-LENGTH PIC S9(9) BINARY VALUE 64. 001500C 10 MQ-JAAS-CONFIG-LENGTH PIC S9(9) BINARY VALUE 1024. 001501C 10 MQ-LDAP-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 32. 001502C 10 MQ-LDAP-BASE-DN-LENGTH PIC S9(9) BINARY VALUE 1024. 001503C 10 MQ-LDAP-FIELD-LENGTH PIC S9(9) BINARY VALUE 128. 001504C 10 MQ-LDAP-CLASS-LENGTH PIC S9(9) BINARY VALUE 128. 001505C 10 MQ-LISTENER-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001506C 10 MQ-LISTENER-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001507C 10 MQ-LOCAL-ADDRESS-LENGTH PIC S9(9) BINARY VALUE 48. 001508C 10 MQ-LTERM-OVERRIDE-LENGTH PIC S9(9) BINARY VALUE 8. 001509C 10 MQ-LU-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001510C 10 MQ-LUWID-LENGTH PIC S9(9) BINARY VALUE 16. 001511C 10 MQ-MAX-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 128. 001512C 10 MQ-MAX-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 64. 001513C 10 MQ-MAX-LDAP-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001514C 10 MQ-MAX-PROPERTY-NAME-LENGTH PIC S9(9) BINARY VALUE 4095. 001515C 10 MQ-MAX-USER-ID-LENGTH PIC S9(9) BINARY VALUE 64. 001516C 10 MQ-MCA-JOB-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001517C 10 MQ-MCA-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001518C 10 MQ-MCA-USER-DATA-LENGTH PIC S9(9) BINARY VALUE 32. 001519C 10 MQ-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001520C 10 MQ-LDAP-MCA-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001521C 10 MQ-MFS-MAP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001522C 10 MQ-MODE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001523C 10 MQ-MSG-HEADER-LENGTH PIC S9(9) BINARY VALUE 4000. 001524C 10 MQ-MSG-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001525C 10 MQ-MSG-TOKEN-LENGTH PIC S9(9) BINARY VALUE 16. 001526C 10 MQ-NAMELIST-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001527C 10 MQ-NAMELIST-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001528C 10 MQ-NHA-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001529C 10 MQ-NHA-INSTANCE-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001530C 10 MQ-OBJECT-INSTANCE-ID-LENGTH PIC S9(9) BINARY VALUE 24. 001531C 10 MQ-OBJECT-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001532C 10 MQ-PASS-TICKET-APPL-LENGTH PIC S9(9) BINARY VALUE 8. 001533C 10 MQ-PASSWORD-LENGTH PIC S9(9) BINARY VALUE 12. 001534C 10 MQ-PROCESS-APPL-ID-LENGTH PIC S9(9) BINARY VALUE 256. 001535C 10 MQ-PROCESS-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001536C 10 MQ-PROCESS-ENV-DATA-LENGTH PIC S9(9) BINARY VALUE 128. 001537C 10 MQ-PROCESS-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001538C 10 MQ-PROCESS-USER-DATA-LENGTH PIC S9(9) BINARY VALUE 128. 001539C 10 MQ-PROGRAM-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 31 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001540C 10 MQ-PUT-APPL-NAME-LENGTH PIC S9(9) BINARY VALUE 28. 001541C 10 MQ-PUT-DATE-LENGTH PIC S9(9) BINARY VALUE 8. 001542C 10 MQ-PUT-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001543C 10 MQ-Q-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001544C 10 MQ-Q-MGR-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001545C 10 MQ-Q-MGR-IDENTIFIER-LENGTH PIC S9(9) BINARY VALUE 48. 001546C 10 MQ-Q-MGR-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001547C 10 MQ-Q-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001548C 10 MQ-QSG-NAME-LENGTH PIC S9(9) BINARY VALUE 4. 001549C 10 MQ-REMOTE-SYS-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001550C 10 MQ-SECURITY-ID-LENGTH PIC S9(9) BINARY VALUE 40. 001551C 10 MQ-SELECTOR-LENGTH PIC S9(9) BINARY VALUE 10240. 001552C 10 MQ-SERVICE-ARGS-LENGTH PIC S9(9) BINARY VALUE 255. 001553C 10 MQ-SERVICE-COMMAND-LENGTH PIC S9(9) BINARY VALUE 255. 001554C 10 MQ-SERVICE-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001555C 10 MQ-SERVICE-NAME-LENGTH PIC S9(9) BINARY VALUE 32. 001556C 10 MQ-SERVICE-PATH-LENGTH PIC S9(9) BINARY VALUE 255. 001557C 10 MQ-SERVICE-STEP-LENGTH PIC S9(9) BINARY VALUE 8. 001558C 10 MQ-SHORT-CONN-NAME-LENGTH PIC S9(9) BINARY VALUE 20. 001559C 10 MQ-SHORT-DNAME-LENGTH PIC S9(9) BINARY VALUE 256. 001560C 10 MQ-SSL-CIPHER-SPEC-LENGTH PIC S9(9) BINARY VALUE 32. 001561C 10 MQ-SSL-CIPHER-SUITE-LENGTH PIC S9(9) BINARY VALUE 32. 001562C 10 MQ-SSL-CRYPTO-HARDWARE-LENGTH PIC S9(9) BINARY VALUE 256. 001563C 10 MQ-SSL-ENCRYP-KEY-REPO-PWD-LEN PIC S9(9) BINARY VALUE 1536. 001564C 10 MQ-SSL-HANDSHAKE-STAGE-LENGTH PIC S9(9) BINARY VALUE 32. 001565C 10 MQ-SSL-KEY-LIBRARY-LENGTH PIC S9(9) BINARY VALUE 44. 001566C 10 MQ-SSL-KEY-MEMBER-LENGTH PIC S9(9) BINARY VALUE 8. 001567C 10 MQ-SSL-KEY-REPOSITORY-LENGTH PIC S9(9) BINARY VALUE 256. 001568C 10 MQ-SSL-KEY-REPO-PWD-LEN PIC S9(9) BINARY VALUE 1024. 001569C 10 MQ-SSL-PEER-NAME-LENGTH PIC S9(9) BINARY VALUE 1024. 001570C 10 MQ-SSL-SHORT-PEER-NAME-LENGTH PIC S9(9) BINARY VALUE 256. 001571C 10 MQ-START-CODE-LENGTH PIC S9(9) BINARY VALUE 4. 001572C 10 MQ-STORAGE-CLASS-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001573C 10 MQ-STORAGE-CLASS-LENGTH PIC S9(9) BINARY VALUE 8. 001574C 10 MQ-SUB-IDENTITY-LENGTH PIC S9(9) BINARY VALUE 128. 001575C 10 MQ-SUB-POINT-LENGTH PIC S9(9) BINARY VALUE 128. 001576C 10 MQ-TCP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001577C 10 MQ-TEMPORARY-Q-PREFIX-LENGTH PIC S9(9) BINARY VALUE 32. 001578C 10 MQ-TIME-LENGTH PIC S9(9) BINARY VALUE 8. 001579C 10 MQ-TOPIC-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001580C 10 MQ-TOPIC-NAME-LENGTH PIC S9(9) BINARY VALUE 48. 001581C 10 MQ-TOPIC-STR-LENGTH PIC S9(9) BINARY VALUE 10240. 001582C 10 MQ-TOTAL-EXIT-DATA-LENGTH PIC S9(9) BINARY VALUE 999. 001583C 10 MQ-TOTAL-EXIT-NAME-LENGTH PIC S9(9) BINARY VALUE 999. 001584C 10 MQ-TP-NAME-LENGTH PIC S9(9) BINARY VALUE 64. 001585C 10 MQ-TPIPE-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001586C 10 MQ-TRAN-INSTANCE-ID-LENGTH PIC S9(9) BINARY VALUE 16. 001587C 10 MQ-TRANSACTION-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001588C 10 MQ-TRIGGER-DATA-LENGTH PIC S9(9) BINARY VALUE 64. 001589C 10 MQ-TRIGGER-PROGRAM-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001590C 10 MQ-TRIGGER-TERM-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001591C 10 MQ-TRIGGER-TRANS-ID-LENGTH PIC S9(9) BINARY VALUE 4. 001592C 10 MQ-USER-ID-LENGTH PIC S9(9) BINARY VALUE 12. 001593C 10 MQ-LONG-USER-ID-LENGTH PIC S9(9) BINARY VALUE 1024. 001594C 10 MQ-VERSION-LENGTH PIC S9(9) BINARY VALUE 8. 001595C 10 MQ-XCF-GROUP-NAME-LENGTH PIC S9(9) BINARY VALUE 8. 001596C 10 MQ-XCF-MEMBER-NAME-LENGTH PIC S9(9) BINARY VALUE 16. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 32 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001597C 10 MQ-SMDS-NAME-LENGTH PIC S9(9) BINARY VALUE 4. 001598C 10 MQ-CHLAUTH-DESC-LENGTH PIC S9(9) BINARY VALUE 64. 001599C 10 MQ-CUSTOM-LENGTH PIC S9(9) BINARY VALUE 128. 001600C 10 MQ-SUITE-B-SIZE PIC S9(9) BINARY VALUE 4. 001601C 10 MQ-CERT-LABEL-LENGTH PIC S9(9) BINARY VALUE 32. 001602C 001603C ** Completion Codes 001604C 10 MQCC-OK PIC S9(9) BINARY VALUE 0. 001605C 10 MQCC-WARNING PIC S9(9) BINARY VALUE 1. 001606C 10 MQCC-FAILED PIC S9(9) BINARY VALUE 2. 001607C 10 MQCC-UNKNOWN PIC S9(9) BINARY VALUE -1. 001608C 001609C ** Reason Codes 001610C 10 MQRC-NONE PIC S9(9) BINARY VALUE 0. 001611C 10 MQRC-APPL-FIRST PIC S9(9) BINARY VALUE 900. 001612C 10 MQRC-APPL-LAST PIC S9(9) BINARY VALUE 999. 001613C 10 MQRC-ALIAS-BASE-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2001. 001614C 10 MQRC-ALREADY-CONNECTED PIC S9(9) BINARY VALUE 2002. 001615C 10 MQRC-BACKED-OUT PIC S9(9) BINARY VALUE 2003. 001616C 10 MQRC-BUFFER-ERROR PIC S9(9) BINARY VALUE 2004. 001617C 10 MQRC-BUFFER-LENGTH-ERROR PIC S9(9) BINARY VALUE 2005. 001618C 10 MQRC-CHAR-ATTR-LENGTH-ERROR PIC S9(9) BINARY VALUE 2006. 001619C 10 MQRC-CHAR-ATTRS-ERROR PIC S9(9) BINARY VALUE 2007. 001620C 10 MQRC-CHAR-ATTRS-TOO-SHORT PIC S9(9) BINARY VALUE 2008. 001621C 10 MQRC-CONNECTION-BROKEN PIC S9(9) BINARY VALUE 2009. 001622C 10 MQRC-DATA-LENGTH-ERROR PIC S9(9) BINARY VALUE 2010. 001623C 10 MQRC-DYNAMIC-Q-NAME-ERROR PIC S9(9) BINARY VALUE 2011. 001624C 10 MQRC-ENVIRONMENT-ERROR PIC S9(9) BINARY VALUE 2012. 001625C 10 MQRC-EXPIRY-ERROR PIC S9(9) BINARY VALUE 2013. 001626C 10 MQRC-FEEDBACK-ERROR PIC S9(9) BINARY VALUE 2014. 001627C 10 MQRC-GET-INHIBITED PIC S9(9) BINARY VALUE 2016. 001628C 10 MQRC-HANDLE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2017. 001629C 10 MQRC-HCONN-ERROR PIC S9(9) BINARY VALUE 2018. 001630C 10 MQRC-HOBJ-ERROR PIC S9(9) BINARY VALUE 2019. 001631C 10 MQRC-INHIBIT-VALUE-ERROR PIC S9(9) BINARY VALUE 2020. 001632C 10 MQRC-INT-ATTR-COUNT-ERROR PIC S9(9) BINARY VALUE 2021. 001633C 10 MQRC-INT-ATTR-COUNT-TOO-SMALL PIC S9(9) BINARY VALUE 2022. 001634C 10 MQRC-INT-ATTRS-ARRAY-ERROR PIC S9(9) BINARY VALUE 2023. 001635C 10 MQRC-SYNCPOINT-LIMIT-REACHED PIC S9(9) BINARY VALUE 2024. 001636C 10 MQRC-MAX-CONNS-LIMIT-REACHED PIC S9(9) BINARY VALUE 2025. 001637C 10 MQRC-MD-ERROR PIC S9(9) BINARY VALUE 2026. 001638C 10 MQRC-MISSING-REPLY-TO-Q PIC S9(9) BINARY VALUE 2027. 001639C 10 MQRC-MSG-TYPE-ERROR PIC S9(9) BINARY VALUE 2029. 001640C 10 MQRC-MSG-TOO-BIG-FOR-Q PIC S9(9) BINARY VALUE 2030. 001641C 10 MQRC-MSG-TOO-BIG-FOR-Q-MGR PIC S9(9) BINARY VALUE 2031. 001642C 10 MQRC-NO-MSG-AVAILABLE PIC S9(9) BINARY VALUE 2033. 001643C 10 MQRC-NO-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2034. 001644C 10 MQRC-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 2035. 001645C 10 MQRC-NOT-OPEN-FOR-BROWSE PIC S9(9) BINARY VALUE 2036. 001646C 10 MQRC-NOT-OPEN-FOR-INPUT PIC S9(9) BINARY VALUE 2037. 001647C 10 MQRC-NOT-OPEN-FOR-INQUIRE PIC S9(9) BINARY VALUE 2038. 001648C 10 MQRC-NOT-OPEN-FOR-OUTPUT PIC S9(9) BINARY VALUE 2039. 001649C 10 MQRC-NOT-OPEN-FOR-SET PIC S9(9) BINARY VALUE 2040. 001650C 10 MQRC-OBJECT-CHANGED PIC S9(9) BINARY VALUE 2041. 001651C 10 MQRC-OBJECT-IN-USE PIC S9(9) BINARY VALUE 2042. 001652C 10 MQRC-OBJECT-TYPE-ERROR PIC S9(9) BINARY VALUE 2043. 001653C 10 MQRC-OD-ERROR PIC S9(9) BINARY VALUE 2044. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 33 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001654C 10 MQRC-OPTION-NOT-VALID-FOR-TYPE PIC S9(9) BINARY VALUE 2045. 001655C 10 MQRC-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2046. 001656C 10 MQRC-PERSISTENCE-ERROR PIC S9(9) BINARY VALUE 2047. 001657C 10 MQRC-PERSISTENT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2048. 001658C 10 MQRC-PRIORITY-EXCEEDS-MAXIMUM PIC S9(9) BINARY VALUE 2049. 001659C 10 MQRC-PRIORITY-ERROR PIC S9(9) BINARY VALUE 2050. 001660C 10 MQRC-PUT-INHIBITED PIC S9(9) BINARY VALUE 2051. 001661C 10 MQRC-Q-DELETED PIC S9(9) BINARY VALUE 2052. 001662C 10 MQRC-Q-FULL PIC S9(9) BINARY VALUE 2053. 001663C 10 MQRC-Q-NOT-EMPTY PIC S9(9) BINARY VALUE 2055. 001664C 10 MQRC-Q-SPACE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2056. 001665C 10 MQRC-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2057. 001666C 10 MQRC-Q-MGR-NAME-ERROR PIC S9(9) BINARY VALUE 2058. 001667C 10 MQRC-Q-MGR-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2059. 001668C 10 MQRC-REPORT-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2061. 001669C 10 MQRC-SECOND-MARK-NOT-ALLOWED PIC S9(9) BINARY VALUE 2062. 001670C 10 MQRC-SECURITY-ERROR PIC S9(9) BINARY VALUE 2063. 001671C 10 MQRC-TOKEN-TIMESTAMP-NOT-VALID PIC S9(9) BINARY VALUE 2064. 001672C 10 MQRC-SELECTOR-COUNT-ERROR PIC S9(9) BINARY VALUE 2065. 001673C 10 MQRC-SELECTOR-LIMIT-EXCEEDED PIC S9(9) BINARY VALUE 2066. 001674C 10 MQRC-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2067. 001675C 10 MQRC-SELECTOR-NOT-FOR-TYPE PIC S9(9) BINARY VALUE 2068. 001676C 10 MQRC-SIGNAL-OUTSTANDING PIC S9(9) BINARY VALUE 2069. 001677C 10 MQRC-SIGNAL-REQUEST-ACCEPTED PIC S9(9) BINARY VALUE 2070. 001678C 10 MQRC-STORAGE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2071. 001679C 10 MQRC-SYNCPOINT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2072. 001680C 10 MQRC-TRIGGER-CONTROL-ERROR PIC S9(9) BINARY VALUE 2075. 001681C 10 MQRC-TRIGGER-DEPTH-ERROR PIC S9(9) BINARY VALUE 2076. 001682C 10 MQRC-TRIGGER-MSG-PRIORITY-ERR PIC S9(9) BINARY VALUE 2077. 001683C 10 MQRC-TRIGGER-TYPE-ERROR PIC S9(9) BINARY VALUE 2078. 001684C 10 MQRC-TRUNCATED-MSG-ACCEPTED PIC S9(9) BINARY VALUE 2079. 001685C 10 MQRC-TRUNCATED-MSG-FAILED PIC S9(9) BINARY VALUE 2080. 001686C 10 MQRC-UNKNOWN-ALIAS-BASE-Q PIC S9(9) BINARY VALUE 2082. 001687C 10 MQRC-UNKNOWN-OBJECT-NAME PIC S9(9) BINARY VALUE 2085. 001688C 10 MQRC-UNKNOWN-OBJECT-Q-MGR PIC S9(9) BINARY VALUE 2086. 001689C 10 MQRC-UNKNOWN-REMOTE-Q-MGR PIC S9(9) BINARY VALUE 2087. 001690C 10 MQRC-WAIT-INTERVAL-ERROR PIC S9(9) BINARY VALUE 2090. 001691C 10 MQRC-XMIT-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2091. 001692C 10 MQRC-XMIT-Q-USAGE-ERROR PIC S9(9) BINARY VALUE 2092. 001693C 10 MQRC-NOT-OPEN-FOR-PASS-ALL PIC S9(9) BINARY VALUE 2093. 001694C 10 MQRC-NOT-OPEN-FOR-PASS-IDENT PIC S9(9) BINARY VALUE 2094. 001695C 10 MQRC-NOT-OPEN-FOR-SET-ALL PIC S9(9) BINARY VALUE 2095. 001696C 10 MQRC-NOT-OPEN-FOR-SET-IDENT PIC S9(9) BINARY VALUE 2096. 001697C 10 MQRC-CONTEXT-HANDLE-ERROR PIC S9(9) BINARY VALUE 2097. 001698C 10 MQRC-CONTEXT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2098. 001699C 10 MQRC-SIGNAL1-ERROR PIC S9(9) BINARY VALUE 2099. 001700C 10 MQRC-OBJECT-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2100. 001701C 10 MQRC-OBJECT-DAMAGED PIC S9(9) BINARY VALUE 2101. 001702C 10 MQRC-RESOURCE-PROBLEM PIC S9(9) BINARY VALUE 2102. 001703C 10 MQRC-ANOTHER-Q-MGR-CONNECTED PIC S9(9) BINARY VALUE 2103. 001704C 10 MQRC-UNKNOWN-REPORT-OPTION PIC S9(9) BINARY VALUE 2104. 001705C 10 MQRC-STORAGE-CLASS-ERROR PIC S9(9) BINARY VALUE 2105. 001706C 10 MQRC-COD-NOT-VALID-FOR-XCF-Q PIC S9(9) BINARY VALUE 2106. 001707C 10 MQRC-XWAIT-CANCELED PIC S9(9) BINARY VALUE 2107. 001708C 10 MQRC-XWAIT-ERROR PIC S9(9) BINARY VALUE 2108. 001709C 10 MQRC-SUPPRESSED-BY-EXIT PIC S9(9) BINARY VALUE 2109. 001710C 10 MQRC-FORMAT-ERROR PIC S9(9) BINARY VALUE 2110. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 34 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001711C 10 MQRC-SOURCE-CCSID-ERROR PIC S9(9) BINARY VALUE 2111. 001712C 10 MQRC-SOURCE-INTEGER-ENC-ERROR PIC S9(9) BINARY VALUE 2112. 001713C 10 MQRC-SOURCE-DECIMAL-ENC-ERROR PIC S9(9) BINARY VALUE 2113. 001714C 10 MQRC-SOURCE-FLOAT-ENC-ERROR PIC S9(9) BINARY VALUE 2114. 001715C 10 MQRC-TARGET-CCSID-ERROR PIC S9(9) BINARY VALUE 2115. 001716C 10 MQRC-TARGET-INTEGER-ENC-ERROR PIC S9(9) BINARY VALUE 2116. 001717C 10 MQRC-TARGET-DECIMAL-ENC-ERROR PIC S9(9) BINARY VALUE 2117. 001718C 10 MQRC-TARGET-FLOAT-ENC-ERROR PIC S9(9) BINARY VALUE 2118. 001719C 10 MQRC-NOT-CONVERTED PIC S9(9) BINARY VALUE 2119. 001720C 10 MQRC-CONVERTED-MSG-TOO-BIG PIC S9(9) BINARY VALUE 2120. 001721C 10 MQRC-TRUNCATED PIC S9(9) BINARY VALUE 2120. 001722C 10 MQRC-NO-EXTERNAL-PARTICIPANTS PIC S9(9) BINARY VALUE 2121. 001723C 10 MQRC-PARTICIPANT-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2122. 001724C 10 MQRC-OUTCOME-MIXED PIC S9(9) BINARY VALUE 2123. 001725C 10 MQRC-OUTCOME-PENDING PIC S9(9) BINARY VALUE 2124. 001726C 10 MQRC-BRIDGE-STARTED PIC S9(9) BINARY VALUE 2125. 001727C 10 MQRC-BRIDGE-STOPPED PIC S9(9) BINARY VALUE 2126. 001728C 10 MQRC-ADAPTER-STORAGE-SHORTAGE PIC S9(9) BINARY VALUE 2127. 001729C 10 MQRC-UOW-IN-PROGRESS PIC S9(9) BINARY VALUE 2128. 001730C 10 MQRC-ADAPTER-CONN-LOAD-ERROR PIC S9(9) BINARY VALUE 2129. 001731C 10 MQRC-ADAPTER-SERV-LOAD-ERROR PIC S9(9) BINARY VALUE 2130. 001732C 10 MQRC-ADAPTER-DEFS-ERROR PIC S9(9) BINARY VALUE 2131. 001733C 10 MQRC-ADAPTER-DEFS-LOAD-ERROR PIC S9(9) BINARY VALUE 2132. 001734C 10 MQRC-ADAPTER-CONV-LOAD-ERROR PIC S9(9) BINARY VALUE 2133. 001735C 10 MQRC-BO-ERROR PIC S9(9) BINARY VALUE 2134. 001736C 10 MQRC-DH-ERROR PIC S9(9) BINARY VALUE 2135. 001737C 10 MQRC-MULTIPLE-REASONS PIC S9(9) BINARY VALUE 2136. 001738C 10 MQRC-OPEN-FAILED PIC S9(9) BINARY VALUE 2137. 001739C 10 MQRC-ADAPTER-DISC-LOAD-ERROR PIC S9(9) BINARY VALUE 2138. 001740C 10 MQRC-CNO-ERROR PIC S9(9) BINARY VALUE 2139. 001741C 10 MQRC-CICS-WAIT-FAILED PIC S9(9) BINARY VALUE 2140. 001742C 10 MQRC-DLH-ERROR PIC S9(9) BINARY VALUE 2141. 001743C 10 MQRC-HEADER-ERROR PIC S9(9) BINARY VALUE 2142. 001744C 10 MQRC-SOURCE-LENGTH-ERROR PIC S9(9) BINARY VALUE 2143. 001745C 10 MQRC-TARGET-LENGTH-ERROR PIC S9(9) BINARY VALUE 2144. 001746C 10 MQRC-SOURCE-BUFFER-ERROR PIC S9(9) BINARY VALUE 2145. 001747C 10 MQRC-TARGET-BUFFER-ERROR PIC S9(9) BINARY VALUE 2146. 001748C 10 MQRC-INCOMPLETE-TRANSACTION PIC S9(9) BINARY VALUE 2147. 001749C 10 MQRC-IIH-ERROR PIC S9(9) BINARY VALUE 2148. 001750C 10 MQRC-PCF-ERROR PIC S9(9) BINARY VALUE 2149. 001751C 10 MQRC-DBCS-ERROR PIC S9(9) BINARY VALUE 2150. 001752C 10 MQRC-OBJECT-NAME-ERROR PIC S9(9) BINARY VALUE 2152. 001753C 10 MQRC-OBJECT-Q-MGR-NAME-ERROR PIC S9(9) BINARY VALUE 2153. 001754C 10 MQRC-RECS-PRESENT-ERROR PIC S9(9) BINARY VALUE 2154. 001755C 10 MQRC-OBJECT-RECORDS-ERROR PIC S9(9) BINARY VALUE 2155. 001756C 10 MQRC-RESPONSE-RECORDS-ERROR PIC S9(9) BINARY VALUE 2156. 001757C 10 MQRC-ASID-MISMATCH PIC S9(9) BINARY VALUE 2157. 001758C 10 MQRC-PMO-RECORD-FLAGS-ERROR PIC S9(9) BINARY VALUE 2158. 001759C 10 MQRC-PUT-MSG-RECORDS-ERROR PIC S9(9) BINARY VALUE 2159. 001760C 10 MQRC-CONN-ID-IN-USE PIC S9(9) BINARY VALUE 2160. 001761C 10 MQRC-Q-MGR-QUIESCING PIC S9(9) BINARY VALUE 2161. 001762C 10 MQRC-Q-MGR-STOPPING PIC S9(9) BINARY VALUE 2162. 001763C 10 MQRC-DUPLICATE-RECOV-COORD PIC S9(9) BINARY VALUE 2163. 001764C 10 MQRC-PMO-ERROR PIC S9(9) BINARY VALUE 2173. 001765C 10 MQRC-API-EXIT-NOT-FOUND PIC S9(9) BINARY VALUE 2182. 001766C 10 MQRC-API-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2183. 001767C 10 MQRC-REMOTE-Q-NAME-ERROR PIC S9(9) BINARY VALUE 2184. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 35 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001768C 10 MQRC-INCONSISTENT-PERSISTENCE PIC S9(9) BINARY VALUE 2185. 001769C 10 MQRC-GMO-ERROR PIC S9(9) BINARY VALUE 2186. 001770C 10 MQRC-CICS-BRIDGE-RESTRICTION PIC S9(9) BINARY VALUE 2187. 001771C 10 MQRC-STOPPED-BY-CLUSTER-EXIT PIC S9(9) BINARY VALUE 2188. 001772C 10 MQRC-CLUSTER-RESOLUTION-ERROR PIC S9(9) BINARY VALUE 2189. 001773C 10 MQRC-CONVERTED-STRING-TOO-BIG PIC S9(9) BINARY VALUE 2190. 001774C 10 MQRC-TMC-ERROR PIC S9(9) BINARY VALUE 2191. 001775C 10 MQRC-STORAGE-MEDIUM-FULL PIC S9(9) BINARY VALUE 2192. 001776C 10 MQRC-PAGESET-FULL PIC S9(9) BINARY VALUE 2192. 001777C 10 MQRC-PAGESET-ERROR PIC S9(9) BINARY VALUE 2193. 001778C 10 MQRC-NAME-NOT-VALID-FOR-TYPE PIC S9(9) BINARY VALUE 2194. 001779C 10 MQRC-UNEXPECTED-ERROR PIC S9(9) BINARY VALUE 2195. 001780C 10 MQRC-UNKNOWN-XMIT-Q PIC S9(9) BINARY VALUE 2196. 001781C 10 MQRC-UNKNOWN-DEF-XMIT-Q PIC S9(9) BINARY VALUE 2197. 001782C 10 MQRC-DEF-XMIT-Q-TYPE-ERROR PIC S9(9) BINARY VALUE 2198. 001783C 10 MQRC-DEF-XMIT-Q-USAGE-ERROR PIC S9(9) BINARY VALUE 2199. 001784C 10 MQRC-MSG-MARKED-BROWSE-CO-OP PIC S9(9) BINARY VALUE 2200. 001785C 10 MQRC-NAME-IN-USE PIC S9(9) BINARY VALUE 2201. 001786C 10 MQRC-CONNECTION-QUIESCING PIC S9(9) BINARY VALUE 2202. 001787C 10 MQRC-CONNECTION-STOPPING PIC S9(9) BINARY VALUE 2203. 001788C 10 MQRC-ADAPTER-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2204. 001789C 10 MQRC-MSG-ID-ERROR PIC S9(9) BINARY VALUE 2206. 001790C 10 MQRC-CORREL-ID-ERROR PIC S9(9) BINARY VALUE 2207. 001791C 10 MQRC-FILE-SYSTEM-ERROR PIC S9(9) BINARY VALUE 2208. 001792C 10 MQRC-NO-MSG-LOCKED PIC S9(9) BINARY VALUE 2209. 001793C 10 MQRC-SOAP-DOTNET-ERROR PIC S9(9) BINARY VALUE 2210. 001794C 10 MQRC-SOAP-AXIS-ERROR PIC S9(9) BINARY VALUE 2211. 001795C 10 MQRC-SOAP-URL-ERROR PIC S9(9) BINARY VALUE 2212. 001796C 10 MQRC-FILE-NOT-AUDITED PIC S9(9) BINARY VALUE 2216. 001797C 10 MQRC-CONNECTION-NOT-AUTHORIZED PIC S9(9) BINARY VALUE 2217. 001798C 10 MQRC-MSG-TOO-BIG-FOR-CHANNEL PIC S9(9) BINARY VALUE 2218. 001799C 10 MQRC-CALL-IN-PROGRESS PIC S9(9) BINARY VALUE 2219. 001800C 10 MQRC-RMH-ERROR PIC S9(9) BINARY VALUE 2220. 001801C 10 MQRC-Q-MGR-ACTIVE PIC S9(9) BINARY VALUE 2222. 001802C 10 MQRC-Q-MGR-NOT-ACTIVE PIC S9(9) BINARY VALUE 2223. 001803C 10 MQRC-Q-DEPTH-HIGH PIC S9(9) BINARY VALUE 2224. 001804C 10 MQRC-Q-DEPTH-LOW PIC S9(9) BINARY VALUE 2225. 001805C 10 MQRC-Q-SERVICE-INTERVAL-HIGH PIC S9(9) BINARY VALUE 2226. 001806C 10 MQRC-Q-SERVICE-INTERVAL-OK PIC S9(9) BINARY VALUE 2227. 001807C 10 MQRC-RFH-HEADER-FIELD-ERROR PIC S9(9) BINARY VALUE 2228. 001808C 10 MQRC-RAS-PROPERTY-ERROR PIC S9(9) BINARY VALUE 2229. 001809C 10 MQRC-UNIT-OF-WORK-NOT-STARTED PIC S9(9) BINARY VALUE 2232. 001810C 10 MQRC-CHANNEL-AUTO-DEF-OK PIC S9(9) BINARY VALUE 2233. 001811C 10 MQRC-CHANNEL-AUTO-DEF-ERROR PIC S9(9) BINARY VALUE 2234. 001812C 10 MQRC-CFH-ERROR PIC S9(9) BINARY VALUE 2235. 001813C 10 MQRC-CFIL-ERROR PIC S9(9) BINARY VALUE 2236. 001814C 10 MQRC-CFIN-ERROR PIC S9(9) BINARY VALUE 2237. 001815C 10 MQRC-CFSL-ERROR PIC S9(9) BINARY VALUE 2238. 001816C 10 MQRC-CFST-ERROR PIC S9(9) BINARY VALUE 2239. 001817C 10 MQRC-INCOMPLETE-GROUP PIC S9(9) BINARY VALUE 2241. 001818C 10 MQRC-INCOMPLETE-MSG PIC S9(9) BINARY VALUE 2242. 001819C 10 MQRC-INCONSISTENT-CCSIDS PIC S9(9) BINARY VALUE 2243. 001820C 10 MQRC-INCONSISTENT-ENCODINGS PIC S9(9) BINARY VALUE 2244. 001821C 10 MQRC-INCONSISTENT-UOW PIC S9(9) BINARY VALUE 2245. 001822C 10 MQRC-INVALID-MSG-UNDER-CURSOR PIC S9(9) BINARY VALUE 2246. 001823C 10 MQRC-MATCH-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2247. 001824C 10 MQRC-MDE-ERROR PIC S9(9) BINARY VALUE 2248. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 36 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001825C 10 MQRC-MSG-FLAGS-ERROR PIC S9(9) BINARY VALUE 2249. 001826C 10 MQRC-MSG-SEQ-NUMBER-ERROR PIC S9(9) BINARY VALUE 2250. 001827C 10 MQRC-OFFSET-ERROR PIC S9(9) BINARY VALUE 2251. 001828C 10 MQRC-ORIGINAL-LENGTH-ERROR PIC S9(9) BINARY VALUE 2252. 001829C 10 MQRC-SEGMENT-LENGTH-ZERO PIC S9(9) BINARY VALUE 2253. 001830C 10 MQRC-UOW-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2255. 001831C 10 MQRC-WRONG-GMO-VERSION PIC S9(9) BINARY VALUE 2256. 001832C 10 MQRC-WRONG-MD-VERSION PIC S9(9) BINARY VALUE 2257. 001833C 10 MQRC-GROUP-ID-ERROR PIC S9(9) BINARY VALUE 2258. 001834C 10 MQRC-INCONSISTENT-BROWSE PIC S9(9) BINARY VALUE 2259. 001835C 10 MQRC-XQH-ERROR PIC S9(9) BINARY VALUE 2260. 001836C 10 MQRC-SRC-ENV-ERROR PIC S9(9) BINARY VALUE 2261. 001837C 10 MQRC-SRC-NAME-ERROR PIC S9(9) BINARY VALUE 2262. 001838C 10 MQRC-DEST-ENV-ERROR PIC S9(9) BINARY VALUE 2263. 001839C 10 MQRC-DEST-NAME-ERROR PIC S9(9) BINARY VALUE 2264. 001840C 10 MQRC-TM-ERROR PIC S9(9) BINARY VALUE 2265. 001841C 10 MQRC-CLUSTER-EXIT-ERROR PIC S9(9) BINARY VALUE 2266. 001842C 10 MQRC-CLUSTER-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2267. 001843C 10 MQRC-CLUSTER-PUT-INHIBITED PIC S9(9) BINARY VALUE 2268. 001844C 10 MQRC-CLUSTER-RESOURCE-ERROR PIC S9(9) BINARY VALUE 2269. 001845C 10 MQRC-NO-DESTINATIONS-AVAILABLE PIC S9(9) BINARY VALUE 2270. 001846C 10 MQRC-CONN-TAG-IN-USE PIC S9(9) BINARY VALUE 2271. 001847C 10 MQRC-PARTIALLY-CONVERTED PIC S9(9) BINARY VALUE 2272. 001848C 10 MQRC-CONNECTION-ERROR PIC S9(9) BINARY VALUE 2273. 001849C 10 MQRC-OPTION-ENVIRONMENT-ERROR PIC S9(9) BINARY VALUE 2274. 001850C 10 MQRC-CD-ERROR PIC S9(9) BINARY VALUE 2277. 001851C 10 MQRC-CLIENT-CONN-ERROR PIC S9(9) BINARY VALUE 2278. 001852C 10 MQRC-CHANNEL-STOPPED-BY-USER PIC S9(9) BINARY VALUE 2279. 001853C 10 MQRC-HCONFIG-ERROR PIC S9(9) BINARY VALUE 2280. 001854C 10 MQRC-FUNCTION-ERROR PIC S9(9) BINARY VALUE 2281. 001855C 10 MQRC-CHANNEL-STARTED PIC S9(9) BINARY VALUE 2282. 001856C 10 MQRC-CHANNEL-STOPPED PIC S9(9) BINARY VALUE 2283. 001857C 10 MQRC-CHANNEL-CONV-ERROR PIC S9(9) BINARY VALUE 2284. 001858C 10 MQRC-SERVICE-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2285. 001859C 10 MQRC-INITIALIZATION-FAILED PIC S9(9) BINARY VALUE 2286. 001860C 10 MQRC-TERMINATION-FAILED PIC S9(9) BINARY VALUE 2287. 001861C 10 MQRC-UNKNOWN-Q-NAME PIC S9(9) BINARY VALUE 2288. 001862C 10 MQRC-SERVICE-ERROR PIC S9(9) BINARY VALUE 2289. 001863C 10 MQRC-Q-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2290. 001864C 10 MQRC-USER-ID-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2291. 001865C 10 MQRC-UNKNOWN-ENTITY PIC S9(9) BINARY VALUE 2292. 001866C 10 MQRC-UNKNOWN-AUTH-ENTITY PIC S9(9) BINARY VALUE 2293. 001867C 10 MQRC-UNKNOWN-REF-OBJECT PIC S9(9) BINARY VALUE 2294. 001868C 10 MQRC-CHANNEL-ACTIVATED PIC S9(9) BINARY VALUE 2295. 001869C 10 MQRC-CHANNEL-NOT-ACTIVATED PIC S9(9) BINARY VALUE 2296. 001870C 10 MQRC-UOW-CANCELED PIC S9(9) BINARY VALUE 2297. 001871C 10 MQRC-FUNCTION-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2298. 001872C 10 MQRC-SELECTOR-TYPE-ERROR PIC S9(9) BINARY VALUE 2299. 001873C 10 MQRC-COMMAND-TYPE-ERROR PIC S9(9) BINARY VALUE 2300. 001874C 10 MQRC-MULTIPLE-INSTANCE-ERROR PIC S9(9) BINARY VALUE 2301. 001875C 10 MQRC-SYSTEM-ITEM-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2302. 001876C 10 MQRC-BAG-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2303. 001877C 10 MQRC-SELECTOR-OUT-OF-RANGE PIC S9(9) BINARY VALUE 2304. 001878C 10 MQRC-SELECTOR-NOT-UNIQUE PIC S9(9) BINARY VALUE 2305. 001879C 10 MQRC-INDEX-NOT-PRESENT PIC S9(9) BINARY VALUE 2306. 001880C 10 MQRC-STRING-ERROR PIC S9(9) BINARY VALUE 2307. 001881C 10 MQRC-ENCODING-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2308. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 37 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001882C 10 MQRC-SELECTOR-NOT-PRESENT PIC S9(9) BINARY VALUE 2309. 001883C 10 MQRC-OUT-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2310. 001884C 10 MQRC-STRING-TRUNCATED PIC S9(9) BINARY VALUE 2311. 001885C 10 MQRC-SELECTOR-WRONG-TYPE PIC S9(9) BINARY VALUE 2312. 001886C 10 MQRC-INCONSISTENT-ITEM-TYPE PIC S9(9) BINARY VALUE 2313. 001887C 10 MQRC-INDEX-ERROR PIC S9(9) BINARY VALUE 2314. 001888C 10 MQRC-SYSTEM-BAG-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2315. 001889C 10 MQRC-ITEM-COUNT-ERROR PIC S9(9) BINARY VALUE 2316. 001890C 10 MQRC-FORMAT-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2317. 001891C 10 MQRC-SELECTOR-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2318. 001892C 10 MQRC-ITEM-VALUE-ERROR PIC S9(9) BINARY VALUE 2319. 001893C 10 MQRC-HBAG-ERROR PIC S9(9) BINARY VALUE 2320. 001894C 10 MQRC-PARAMETER-MISSING PIC S9(9) BINARY VALUE 2321. 001895C 10 MQRC-CMD-SERVER-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2322. 001896C 10 MQRC-STRING-LENGTH-ERROR PIC S9(9) BINARY VALUE 2323. 001897C 10 MQRC-INQUIRY-COMMAND-ERROR PIC S9(9) BINARY VALUE 2324. 001898C 10 MQRC-NESTED-BAG-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2325. 001899C 10 MQRC-BAG-WRONG-TYPE PIC S9(9) BINARY VALUE 2326. 001900C 10 MQRC-ITEM-TYPE-ERROR PIC S9(9) BINARY VALUE 2327. 001901C 10 MQRC-SYSTEM-BAG-NOT-DELETABLE PIC S9(9) BINARY VALUE 2328. 001902C 10 MQRC-SYSTEM-ITEM-NOT-DELETABLE PIC S9(9) BINARY VALUE 2329. 001903C 10 MQRC-CODED-CHAR-SET-ID-ERROR PIC S9(9) BINARY VALUE 2330. 001904C 10 MQRC-MSG-TOKEN-ERROR PIC S9(9) BINARY VALUE 2331. 001905C 10 MQRC-MISSING-WIH PIC S9(9) BINARY VALUE 2332. 001906C 10 MQRC-WIH-ERROR PIC S9(9) BINARY VALUE 2333. 001907C 10 MQRC-RFH-ERROR PIC S9(9) BINARY VALUE 2334. 001908C 10 MQRC-RFH-STRING-ERROR PIC S9(9) BINARY VALUE 2335. 001909C 10 MQRC-RFH-COMMAND-ERROR PIC S9(9) BINARY VALUE 2336. 001910C 10 MQRC-RFH-PARM-ERROR PIC S9(9) BINARY VALUE 2337. 001911C 10 MQRC-RFH-DUPLICATE-PARM PIC S9(9) BINARY VALUE 2338. 001912C 10 MQRC-RFH-PARM-MISSING PIC S9(9) BINARY VALUE 2339. 001913C 10 MQRC-CHAR-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2340. 001914C 10 MQRC-UCS2-CONVERSION-ERROR PIC S9(9) BINARY VALUE 2341. 001915C 10 MQRC-DB2-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2342. 001916C 10 MQRC-OBJECT-NOT-UNIQUE PIC S9(9) BINARY VALUE 2343. 001917C 10 MQRC-CONN-TAG-NOT-RELEASED PIC S9(9) BINARY VALUE 2344. 001918C 10 MQRC-CF-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2345. 001919C 10 MQRC-CF-STRUC-IN-USE PIC S9(9) BINARY VALUE 2346. 001920C 10 MQRC-CF-STRUC-LIST-HDR-IN-USE PIC S9(9) BINARY VALUE 2347. 001921C 10 MQRC-CF-STRUC-AUTH-FAILED PIC S9(9) BINARY VALUE 2348. 001922C 10 MQRC-CF-STRUC-ERROR PIC S9(9) BINARY VALUE 2349. 001923C 10 MQRC-CONN-TAG-NOT-USABLE PIC S9(9) BINARY VALUE 2350. 001924C 10 MQRC-GLOBAL-UOW-CONFLICT PIC S9(9) BINARY VALUE 2351. 001925C 10 MQRC-LOCAL-UOW-CONFLICT PIC S9(9) BINARY VALUE 2352. 001926C 10 MQRC-HANDLE-IN-USE-FOR-UOW PIC S9(9) BINARY VALUE 2353. 001927C 10 MQRC-UOW-ENLISTMENT-ERROR PIC S9(9) BINARY VALUE 2354. 001928C 10 MQRC-UOW-MIX-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2355. 001929C 10 MQRC-WXP-ERROR PIC S9(9) BINARY VALUE 2356. 001930C 10 MQRC-CURRENT-RECORD-ERROR PIC S9(9) BINARY VALUE 2357. 001931C 10 MQRC-NEXT-OFFSET-ERROR PIC S9(9) BINARY VALUE 2358. 001932C 10 MQRC-NO-RECORD-AVAILABLE PIC S9(9) BINARY VALUE 2359. 001933C 10 MQRC-OBJECT-LEVEL-INCOMPATIBLE PIC S9(9) BINARY VALUE 2360. 001934C 10 MQRC-NEXT-RECORD-ERROR PIC S9(9) BINARY VALUE 2361. 001935C 10 MQRC-BACKOUT-THRESHOLD-REACHED PIC S9(9) BINARY VALUE 2362. 001936C 10 MQRC-MSG-NOT-MATCHED PIC S9(9) BINARY VALUE 2363. 001937C 10 MQRC-JMS-FORMAT-ERROR PIC S9(9) BINARY VALUE 2364. 001938C 10 MQRC-SEGMENTS-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2365. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 38 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001939C 10 MQRC-WRONG-CF-LEVEL PIC S9(9) BINARY VALUE 2366. 001940C 10 MQRC-CONFIG-CREATE-OBJECT PIC S9(9) BINARY VALUE 2367. 001941C 10 MQRC-CONFIG-CHANGE-OBJECT PIC S9(9) BINARY VALUE 2368. 001942C 10 MQRC-CONFIG-DELETE-OBJECT PIC S9(9) BINARY VALUE 2369. 001943C 10 MQRC-CONFIG-REFRESH-OBJECT PIC S9(9) BINARY VALUE 2370. 001944C 10 MQRC-CHANNEL-SSL-ERROR PIC S9(9) BINARY VALUE 2371. 001945C 10 MQRC-PARTICIPANT-NOT-DEFINED PIC S9(9) BINARY VALUE 2372. 001946C 10 MQRC-CF-STRUC-FAILED PIC S9(9) BINARY VALUE 2373. 001947C 10 MQRC-API-EXIT-ERROR PIC S9(9) BINARY VALUE 2374. 001948C 10 MQRC-API-EXIT-INIT-ERROR PIC S9(9) BINARY VALUE 2375. 001949C 10 MQRC-API-EXIT-TERM-ERROR PIC S9(9) BINARY VALUE 2376. 001950C 10 MQRC-EXIT-REASON-ERROR PIC S9(9) BINARY VALUE 2377. 001951C 10 MQRC-RESERVED-VALUE-ERROR PIC S9(9) BINARY VALUE 2378. 001952C 10 MQRC-NO-DATA-AVAILABLE PIC S9(9) BINARY VALUE 2379. 001953C 10 MQRC-SCO-ERROR PIC S9(9) BINARY VALUE 2380. 001954C 10 MQRC-KEY-REPOSITORY-ERROR PIC S9(9) BINARY VALUE 2381. 001955C 10 MQRC-CRYPTO-HARDWARE-ERROR PIC S9(9) BINARY VALUE 2382. 001956C 10 MQRC-AUTH-INFO-REC-COUNT-ERROR PIC S9(9) BINARY VALUE 2383. 001957C 10 MQRC-AUTH-INFO-REC-ERROR PIC S9(9) BINARY VALUE 2384. 001958C 10 MQRC-AIR-ERROR PIC S9(9) BINARY VALUE 2385. 001959C 10 MQRC-AUTH-INFO-TYPE-ERROR PIC S9(9) BINARY VALUE 2386. 001960C 10 MQRC-AUTH-INFO-CONN-NAME-ERROR PIC S9(9) BINARY VALUE 2387. 001961C 10 MQRC-LDAP-USER-NAME-ERROR PIC S9(9) BINARY VALUE 2388. 001962C 10 MQRC-LDAP-USER-NAME-LENGTH-ERR PIC S9(9) BINARY VALUE 2389. 001963C 10 MQRC-LDAP-PASSWORD-ERROR PIC S9(9) BINARY VALUE 2390. 001964C 10 MQRC-SSL-ALREADY-INITIALIZED PIC S9(9) BINARY VALUE 2391. 001965C 10 MQRC-SSL-CONFIG-ERROR PIC S9(9) BINARY VALUE 2392. 001966C 10 MQRC-SSL-INITIALIZATION-ERROR PIC S9(9) BINARY VALUE 2393. 001967C 10 MQRC-Q-INDEX-TYPE-ERROR PIC S9(9) BINARY VALUE 2394. 001968C 10 MQRC-CFBS-ERROR PIC S9(9) BINARY VALUE 2395. 001969C 10 MQRC-SSL-NOT-ALLOWED PIC S9(9) BINARY VALUE 2396. 001970C 10 MQRC-JSSE-ERROR PIC S9(9) BINARY VALUE 2397. 001971C 10 MQRC-SSL-PEER-NAME-MISMATCH PIC S9(9) BINARY VALUE 2398. 001972C 10 MQRC-SSL-PEER-NAME-ERROR PIC S9(9) BINARY VALUE 2399. 001973C 10 MQRC-UNSUPPORTED-CIPHER-SUITE PIC S9(9) BINARY VALUE 2400. 001974C 10 MQRC-SSL-CERTIFICATE-REVOKED PIC S9(9) BINARY VALUE 2401. 001975C 10 MQRC-SSL-CERT-STORE-ERROR PIC S9(9) BINARY VALUE 2402. 001976C 10 MQRC-CLIENT-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2406. 001977C 10 MQRC-CLIENT-EXIT-ERROR PIC S9(9) BINARY VALUE 2407. 001978C 10 MQRC-UOW-COMMITTED PIC S9(9) BINARY VALUE 2408. 001979C 10 MQRC-SSL-KEY-RESET-ERROR PIC S9(9) BINARY VALUE 2409. 001980C 10 MQRC-UNKNOWN-COMPONENT-NAME PIC S9(9) BINARY VALUE 2410. 001981C 10 MQRC-LOGGER-STATUS PIC S9(9) BINARY VALUE 2411. 001982C 10 MQRC-COMMAND-MQSC PIC S9(9) BINARY VALUE 2412. 001983C 10 MQRC-COMMAND-PCF PIC S9(9) BINARY VALUE 2413. 001984C 10 MQRC-CFIF-ERROR PIC S9(9) BINARY VALUE 2414. 001985C 10 MQRC-CFSF-ERROR PIC S9(9) BINARY VALUE 2415. 001986C 10 MQRC-CFGR-ERROR PIC S9(9) BINARY VALUE 2416. 001987C 10 MQRC-MSG-NOT-ALLOWED-IN-GROUP PIC S9(9) BINARY VALUE 2417. 001988C 10 MQRC-FILTER-OPERATOR-ERROR PIC S9(9) BINARY VALUE 2418. 001989C 10 MQRC-NESTED-SELECTOR-ERROR PIC S9(9) BINARY VALUE 2419. 001990C 10 MQRC-EPH-ERROR PIC S9(9) BINARY VALUE 2420. 001991C 10 MQRC-RFH-FORMAT-ERROR PIC S9(9) BINARY VALUE 2421. 001992C 10 MQRC-CFBF-ERROR PIC S9(9) BINARY VALUE 2422. 001993C 10 MQRC-CLIENT-CHANNEL-CONFLICT PIC S9(9) BINARY VALUE 2423. 001994C 10 MQRC-SD-ERROR PIC S9(9) BINARY VALUE 2424. 001995C 10 MQRC-TOPIC-STRING-ERROR PIC S9(9) BINARY VALUE 2425. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 39 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 001996C 10 MQRC-STS-ERROR PIC S9(9) BINARY VALUE 2426. 001997C 10 MQRC-NO-SUBSCRIPTION PIC S9(9) BINARY VALUE 2428. 001998C 10 MQRC-SUBSCRIPTION-IN-USE PIC S9(9) BINARY VALUE 2429. 001999C 10 MQRC-STAT-TYPE-ERROR PIC S9(9) BINARY VALUE 2430. 002000C 10 MQRC-SUB-USER-DATA-ERROR PIC S9(9) BINARY VALUE 2431. 002001C 10 MQRC-SUB-ALREADY-EXISTS PIC S9(9) BINARY VALUE 2432. 002002C 10 MQRC-IDENTITY-MISMATCH PIC S9(9) BINARY VALUE 2434. 002003C 10 MQRC-ALTER-SUB-ERROR PIC S9(9) BINARY VALUE 2435. 002004C 10 MQRC-DURABILITY-NOT-ALLOWED PIC S9(9) BINARY VALUE 2436. 002005C 10 MQRC-NO-RETAINED-MSG PIC S9(9) BINARY VALUE 2437. 002006C 10 MQRC-SRO-ERROR PIC S9(9) BINARY VALUE 2438. 002007C 10 MQRC-SUB-NAME-ERROR PIC S9(9) BINARY VALUE 2440. 002008C 10 MQRC-OBJECT-STRING-ERROR PIC S9(9) BINARY VALUE 2441. 002009C 10 MQRC-PROPERTY-NAME-ERROR PIC S9(9) BINARY VALUE 2442. 002010C 10 MQRC-SEGMENTATION-NOT-ALLOWED PIC S9(9) BINARY VALUE 2443. 002011C 10 MQRC-CBD-ERROR PIC S9(9) BINARY VALUE 2444. 002012C 10 MQRC-CTLO-ERROR PIC S9(9) BINARY VALUE 2445. 002013C 10 MQRC-NO-CALLBACKS-ACTIVE PIC S9(9) BINARY VALUE 2446. 002014C 10 MQRC-CALLBACK-NOT-REGISTERED PIC S9(9) BINARY VALUE 2448. 002015C 10 MQRC-OPTIONS-CHANGED PIC S9(9) BINARY VALUE 2457. 002016C 10 MQRC-READ-AHEAD-MSGS PIC S9(9) BINARY VALUE 2458. 002017C 10 MQRC-SELECTOR-SYNTAX-ERROR PIC S9(9) BINARY VALUE 2459. 002018C 10 MQRC-HMSG-ERROR PIC S9(9) BINARY VALUE 2460. 002019C 10 MQRC-CMHO-ERROR PIC S9(9) BINARY VALUE 2461. 002020C 10 MQRC-DMHO-ERROR PIC S9(9) BINARY VALUE 2462. 002021C 10 MQRC-SMPO-ERROR PIC S9(9) BINARY VALUE 2463. 002022C 10 MQRC-IMPO-ERROR PIC S9(9) BINARY VALUE 2464. 002023C 10 MQRC-PROPERTY-NAME-TOO-BIG PIC S9(9) BINARY VALUE 2465. 002024C 10 MQRC-PROP-VALUE-NOT-CONVERTED PIC S9(9) BINARY VALUE 2466. 002025C 10 MQRC-PROP-TYPE-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2467. 002026C 10 MQRC-PROPERTY-VALUE-TOO-BIG PIC S9(9) BINARY VALUE 2469. 002027C 10 MQRC-PROP-CONV-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2470. 002028C 10 MQRC-PROPERTY-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2471. 002029C 10 MQRC-PROP-NUMBER-FORMAT-ERROR PIC S9(9) BINARY VALUE 2472. 002030C 10 MQRC-PROPERTY-TYPE-ERROR PIC S9(9) BINARY VALUE 2473. 002031C 10 MQRC-PROPERTIES-TOO-BIG PIC S9(9) BINARY VALUE 2478. 002032C 10 MQRC-PUT-NOT-RETAINED PIC S9(9) BINARY VALUE 2479. 002033C 10 MQRC-ALIAS-TARGTYPE-CHANGED PIC S9(9) BINARY VALUE 2480. 002034C 10 MQRC-DMPO-ERROR PIC S9(9) BINARY VALUE 2481. 002035C 10 MQRC-PD-ERROR PIC S9(9) BINARY VALUE 2482. 002036C 10 MQRC-CALLBACK-TYPE-ERROR PIC S9(9) BINARY VALUE 2483. 002037C 10 MQRC-CBD-OPTIONS-ERROR PIC S9(9) BINARY VALUE 2484. 002038C 10 MQRC-MAX-MSG-LENGTH-ERROR PIC S9(9) BINARY VALUE 2485. 002039C 10 MQRC-CALLBACK-ROUTINE-ERROR PIC S9(9) BINARY VALUE 2486. 002040C 10 MQRC-CALLBACK-LINK-ERROR PIC S9(9) BINARY VALUE 2487. 002041C 10 MQRC-OPERATION-ERROR PIC S9(9) BINARY VALUE 2488. 002042C 10 MQRC-BMHO-ERROR PIC S9(9) BINARY VALUE 2489. 002043C 10 MQRC-UNSUPPORTED-PROPERTY PIC S9(9) BINARY VALUE 2490. 002044C 10 MQRC-MSG-LENGTH-ERROR PIC S9(9) BINARY VALUE 2491. 002045C 10 MQRC-PROP-NAME-NOT-CONVERTED PIC S9(9) BINARY VALUE 2492. 002046C 10 MQRC-GET-ENABLED PIC S9(9) BINARY VALUE 2494. 002047C 10 MQRC-MODULE-NOT-FOUND PIC S9(9) BINARY VALUE 2495. 002048C 10 MQRC-MODULE-INVALID PIC S9(9) BINARY VALUE 2496. 002049C 10 MQRC-MODULE-ENTRY-NOT-FOUND PIC S9(9) BINARY VALUE 2497. 002050C 10 MQRC-MIXED-CONTENT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2498. 002051C 10 MQRC-MSG-HANDLE-IN-USE PIC S9(9) BINARY VALUE 2499. 002052C 10 MQRC-HCONN-ASYNC-ACTIVE PIC S9(9) BINARY VALUE 2500. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 40 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002053C 10 MQRC-MHBO-ERROR PIC S9(9) BINARY VALUE 2501. 002054C 10 MQRC-PUBLICATION-FAILURE PIC S9(9) BINARY VALUE 2502. 002055C 10 MQRC-SUB-INHIBITED PIC S9(9) BINARY VALUE 2503. 002056C 10 MQRC-SELECTOR-ALWAYS-FALSE PIC S9(9) BINARY VALUE 2504. 002057C 10 MQRC-XEPO-ERROR PIC S9(9) BINARY VALUE 2507. 002058C 10 MQRC-DURABILITY-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2509. 002059C 10 MQRC-TOPIC-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2510. 002060C 10 MQRC-SUBLEVEL-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2512. 002061C 10 MQRC-PROPERTY-NAME-LENGTH-ERR PIC S9(9) BINARY VALUE 2513. 002062C 10 MQRC-DUPLICATE-GROUP-SUB PIC S9(9) BINARY VALUE 2514. 002063C 10 MQRC-GROUPING-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2515. 002064C 10 MQRC-SELECTOR-INVALID-FOR-TYPE PIC S9(9) BINARY VALUE 2516. 002065C 10 MQRC-HOBJ-QUIESCED PIC S9(9) BINARY VALUE 2517. 002066C 10 MQRC-HOBJ-QUIESCED-NO-MSGS PIC S9(9) BINARY VALUE 2518. 002067C 10 MQRC-SELECTION-STRING-ERROR PIC S9(9) BINARY VALUE 2519. 002068C 10 MQRC-RES-OBJECT-STRING-ERROR PIC S9(9) BINARY VALUE 2520. 002069C 10 MQRC-CONNECTION-SUSPENDED PIC S9(9) BINARY VALUE 2521. 002070C 10 MQRC-INVALID-DESTINATION PIC S9(9) BINARY VALUE 2522. 002071C 10 MQRC-INVALID-SUBSCRIPTION PIC S9(9) BINARY VALUE 2523. 002072C 10 MQRC-SELECTOR-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2524. 002073C 10 MQRC-RETAINED-MSG-Q-ERROR PIC S9(9) BINARY VALUE 2525. 002074C 10 MQRC-RETAINED-NOT-DELIVERED PIC S9(9) BINARY VALUE 2526. 002075C 10 MQRC-RFH-RESTRICTED-FORMAT-ERR PIC S9(9) BINARY VALUE 2527. 002076C 10 MQRC-CONNECTION-STOPPED PIC S9(9) BINARY VALUE 2528. 002077C 10 MQRC-ASYNC-UOW-CONFLICT PIC S9(9) BINARY VALUE 2529. 002078C 10 MQRC-ASYNC-XA-CONFLICT PIC S9(9) BINARY VALUE 2530. 002079C 10 MQRC-PUBSUB-INHIBITED PIC S9(9) BINARY VALUE 2531. 002080C 10 MQRC-MSG-HANDLE-COPY-FAILURE PIC S9(9) BINARY VALUE 2532. 002081C 10 MQRC-DEST-CLASS-NOT-ALTERABLE PIC S9(9) BINARY VALUE 2533. 002082C 10 MQRC-OPERATION-NOT-ALLOWED PIC S9(9) BINARY VALUE 2534. 002083C 10 MQRC-ACTION-ERROR PIC S9(9) BINARY VALUE 2535. 002084C 10 MQRC-CHANNEL-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2537. 002085C 10 MQRC-HOST-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2538. 002086C 10 MQRC-CHANNEL-CONFIG-ERROR PIC S9(9) BINARY VALUE 2539. 002087C 10 MQRC-UNKNOWN-CHANNEL-NAME PIC S9(9) BINARY VALUE 2540. 002088C 10 MQRC-LOOPING-PUBLICATION PIC S9(9) BINARY VALUE 2541. 002089C 10 MQRC-ALREADY-JOINED PIC S9(9) BINARY VALUE 2542. 002090C 10 MQRC-STANDBY-Q-MGR PIC S9(9) BINARY VALUE 2543. 002091C 10 MQRC-RECONNECTING PIC S9(9) BINARY VALUE 2544. 002092C 10 MQRC-RECONNECTED PIC S9(9) BINARY VALUE 2545. 002093C 10 MQRC-RECONNECT-QMID-MISMATCH PIC S9(9) BINARY VALUE 2546. 002094C 10 MQRC-RECONNECT-INCOMPATIBLE PIC S9(9) BINARY VALUE 2547. 002095C 10 MQRC-RECONNECT-FAILED PIC S9(9) BINARY VALUE 2548. 002096C 10 MQRC-CALL-INTERRUPTED PIC S9(9) BINARY VALUE 2549. 002097C 10 MQRC-NO-SUBS-MATCHED PIC S9(9) BINARY VALUE 2550. 002098C 10 MQRC-SELECTION-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2551. 002099C 10 MQRC-CHANNEL-SSL-WARNING PIC S9(9) BINARY VALUE 2552. 002100C 10 MQRC-OCSP-URL-ERROR PIC S9(9) BINARY VALUE 2553. 002101C 10 MQRC-CONTENT-ERROR PIC S9(9) BINARY VALUE 2554. 002102C 10 MQRC-RECONNECT-Q-MGR-REQD PIC S9(9) BINARY VALUE 2555. 002103C 10 MQRC-RECONNECT-TIMED-OUT PIC S9(9) BINARY VALUE 2556. 002104C 10 MQRC-PUBLISH-EXIT-ERROR PIC S9(9) BINARY VALUE 2557. 002105C 10 MQRC-COMMINFO-ERROR PIC S9(9) BINARY VALUE 2558. 002106C 10 MQRC-DEF-SYNCPOINT-INHIBITED PIC S9(9) BINARY VALUE 2559. 002107C 10 MQRC-MULTICAST-ONLY PIC S9(9) BINARY VALUE 2560. 002108C 10 MQRC-DATA-SET-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2561. 002109C 10 MQRC-GROUPING-NOT-ALLOWED PIC S9(9) BINARY VALUE 2562. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 41 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002110C 10 MQRC-GROUP-ADDRESS-ERROR PIC S9(9) BINARY VALUE 2563. 002111C 10 MQRC-MULTICAST-CONFIG-ERROR PIC S9(9) BINARY VALUE 2564. 002112C 10 MQRC-MULTICAST-INTERFACE-ERROR PIC S9(9) BINARY VALUE 2565. 002113C 10 MQRC-MULTICAST-SEND-ERROR PIC S9(9) BINARY VALUE 2566. 002114C 10 MQRC-MULTICAST-INTERNAL-ERROR PIC S9(9) BINARY VALUE 2567. 002115C 10 MQRC-CONNECTION-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2568. 002116C 10 MQRC-SYNCPOINT-NOT-ALLOWED PIC S9(9) BINARY VALUE 2569. 002117C 10 MQRC-SSL-ALT-PROVIDER-REQUIRED PIC S9(9) BINARY VALUE 2570. 002118C 10 MQRC-MCAST-PUB-STATUS PIC S9(9) BINARY VALUE 2571. 002119C 10 MQRC-MCAST-SUB-STATUS PIC S9(9) BINARY VALUE 2572. 002120C 10 MQRC-PRECONN-EXIT-LOAD-ERROR PIC S9(9) BINARY VALUE 2573. 002121C 10 MQRC-PRECONN-EXIT-NOT-FOUND PIC S9(9) BINARY VALUE 2574. 002122C 10 MQRC-PRECONN-EXIT-ERROR PIC S9(9) BINARY VALUE 2575. 002123C 10 MQRC-CD-ARRAY-ERROR PIC S9(9) BINARY VALUE 2576. 002124C 10 MQRC-CHANNEL-BLOCKED PIC S9(9) BINARY VALUE 2577. 002125C 10 MQRC-CHANNEL-BLOCKED-WARNING PIC S9(9) BINARY VALUE 2578. 002126C 10 MQRC-SUBSCRIPTION-CREATE PIC S9(9) BINARY VALUE 2579. 002127C 10 MQRC-SUBSCRIPTION-DELETE PIC S9(9) BINARY VALUE 2580. 002128C 10 MQRC-SUBSCRIPTION-CHANGE PIC S9(9) BINARY VALUE 2581. 002129C 10 MQRC-SUBSCRIPTION-REFRESH PIC S9(9) BINARY VALUE 2582. 002130C 10 MQRC-INSTALLATION-MISMATCH PIC S9(9) BINARY VALUE 2583. 002131C 10 MQRC-NOT-PRIVILEGED PIC S9(9) BINARY VALUE 2584. 002132C 10 MQRC-PROPERTIES-DISABLED PIC S9(9) BINARY VALUE 2586. 002133C 10 MQRC-HMSG-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2587. 002134C 10 MQRC-EXIT-PROPS-NOT-SUPPORTED PIC S9(9) BINARY VALUE 2588. 002135C 10 MQRC-INSTALLATION-MISSING PIC S9(9) BINARY VALUE 2589. 002136C 10 MQRC-FASTPATH-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2590. 002137C 10 MQRC-CIPHER-SPEC-NOT-SUITE-B PIC S9(9) BINARY VALUE 2591. 002138C 10 MQRC-SUITE-B-ERROR PIC S9(9) BINARY VALUE 2592. 002139C 10 MQRC-CERT-VAL-POLICY-ERROR PIC S9(9) BINARY VALUE 2593. 002140C 10 MQRC-PASSWORD-PROTECTION-ERROR PIC S9(9) BINARY VALUE 2594. 002141C 10 MQRC-CSP-ERROR PIC S9(9) BINARY VALUE 2595. 002142C 10 MQRC-CERT-LABEL-NOT-ALLOWED PIC S9(9) BINARY VALUE 2596. 002143C 10 MQRC-ADMIN-TOPIC-STRING-ERROR PIC S9(9) BINARY VALUE 2598. 002144C 10 MQRC-AMQP-NOT-AVAILABLE PIC S9(9) BINARY VALUE 2599. 002145C 10 MQRC-CCDT-URL-ERROR PIC S9(9) BINARY VALUE 2600. 002146C 10 MQRC-Q-MGR-RECONNECT-REQUESTED PIC S9(9) BINARY VALUE 2601. 002147C 10 MQRC-BNO-ERROR PIC S9(9) BINARY VALUE 2602. 002148C 10 MQRC-OUTBOUND-SNI-NOT-VALID PIC S9(9) BINARY VALUE 2603. 002149C 10 MQRC-HTTPS-KEYSTORE-ERROR PIC S9(9) BINARY VALUE 2604. 002150C 10 MQRC-REOPEN-EXCL-INPUT-ERROR PIC S9(9) BINARY VALUE 6100. 002151C 10 MQRC-REOPEN-INQUIRE-ERROR PIC S9(9) BINARY VALUE 6101. 002152C 10 MQRC-REOPEN-SAVED-CONTEXT-ERR PIC S9(9) BINARY VALUE 6102. 002153C 10 MQRC-REOPEN-TEMPORARY-Q-ERROR PIC S9(9) BINARY VALUE 6103. 002154C 10 MQRC-ATTRIBUTE-LOCKED PIC S9(9) BINARY VALUE 6104. 002155C 10 MQRC-CURSOR-NOT-VALID PIC S9(9) BINARY VALUE 6105. 002156C 10 MQRC-ENCODING-ERROR PIC S9(9) BINARY VALUE 6106. 002157C 10 MQRC-STRUC-ID-ERROR PIC S9(9) BINARY VALUE 6107. 002158C 10 MQRC-NULL-POINTER PIC S9(9) BINARY VALUE 6108. 002159C 10 MQRC-NO-CONNECTION-REFERENCE PIC S9(9) BINARY VALUE 6109. 002160C 10 MQRC-NO-BUFFER PIC S9(9) BINARY VALUE 6110. 002161C 10 MQRC-BINARY-DATA-LENGTH-ERROR PIC S9(9) BINARY VALUE 6111. 002162C 10 MQRC-BUFFER-NOT-AUTOMATIC PIC S9(9) BINARY VALUE 6112. 002163C 10 MQRC-INSUFFICIENT-BUFFER PIC S9(9) BINARY VALUE 6113. 002164C 10 MQRC-INSUFFICIENT-DATA PIC S9(9) BINARY VALUE 6114. 002165C 10 MQRC-DATA-TRUNCATED PIC S9(9) BINARY VALUE 6115. 002166C 10 MQRC-ZERO-LENGTH PIC S9(9) BINARY VALUE 6116. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 42 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002167C 10 MQRC-NEGATIVE-LENGTH PIC S9(9) BINARY VALUE 6117. 002168C 10 MQRC-NEGATIVE-OFFSET PIC S9(9) BINARY VALUE 6118. 002169C 10 MQRC-INCONSISTENT-FORMAT PIC S9(9) BINARY VALUE 6119. 002170C 10 MQRC-INCONSISTENT-OBJECT-STATE PIC S9(9) BINARY VALUE 6120. 002171C 10 MQRC-CONTEXT-OBJECT-NOT-VALID PIC S9(9) BINARY VALUE 6121. 002172C 10 MQRC-CONTEXT-OPEN-ERROR PIC S9(9) BINARY VALUE 6122. 002173C 10 MQRC-STRUC-LENGTH-ERROR PIC S9(9) BINARY VALUE 6123. 002174C 10 MQRC-NOT-CONNECTED PIC S9(9) BINARY VALUE 6124. 002175C 10 MQRC-NOT-OPEN PIC S9(9) BINARY VALUE 6125. 002176C 10 MQRC-DISTRIBUTION-LIST-EMPTY PIC S9(9) BINARY VALUE 6126. 002177C 10 MQRC-INCONSISTENT-OPEN-OPTIONS PIC S9(9) BINARY VALUE 6127. 002178C 10 MQRC-WRONG-VERSION PIC S9(9) BINARY VALUE 6128. 002179C 10 MQRC-REFERENCE-ERROR PIC S9(9) BINARY VALUE 6129. 002180C 10 MQRC-XR-NOT-AVAILABLE PIC S9(9) BINARY VALUE 6130. 002181C 10 MQRC-SUB-JOIN-NOT-ALTERABLE PIC S9(9) BINARY VALUE 29440. 002182C 002183C ****************************************************************** 002184C ** Values Related to Queue Attributes 002185C ****************************************************************** 002186C ** Queue Types 002187C 10 MQQT-LOCAL PIC S9(9) BINARY VALUE 1. 002188C 10 MQQT-MODEL PIC S9(9) BINARY VALUE 2. 002189C 10 MQQT-ALIAS PIC S9(9) BINARY VALUE 3. 002190C 10 MQQT-REMOTE PIC S9(9) BINARY VALUE 6. 002191C 10 MQQT-CLUSTER PIC S9(9) BINARY VALUE 7. 002192C 002193C ** Cluster Queue Types 002194C 10 MQCQT-LOCAL-Q PIC S9(9) BINARY VALUE 1. 002195C 10 MQCQT-ALIAS-Q PIC S9(9) BINARY VALUE 2. 002196C 10 MQCQT-REMOTE-Q PIC S9(9) BINARY VALUE 3. 002197C 10 MQCQT-Q-MGR-ALIAS PIC S9(9) BINARY VALUE 4. 002198C 002199C ** Extended Queue Types 002200C 10 MQQT-ALL PIC S9(9) BINARY VALUE 1001. 002201C 002202C ** Queue Definition Types 002203C 10 MQQDT-PREDEFINED PIC S9(9) BINARY VALUE 1. 002204C 10 MQQDT-PERMANENT-DYNAMIC PIC S9(9) BINARY VALUE 2. 002205C 10 MQQDT-TEMPORARY-DYNAMIC PIC S9(9) BINARY VALUE 3. 002206C 10 MQQDT-SHARED-DYNAMIC PIC S9(9) BINARY VALUE 4. 002207C 002208C ** Inhibit Get Values 002209C 10 MQQA-GET-INHIBITED PIC S9(9) BINARY VALUE 1. 002210C 10 MQQA-GET-ALLOWED PIC S9(9) BINARY VALUE 0. 002211C 002212C ** Inhibit Put Values 002213C 10 MQQA-PUT-INHIBITED PIC S9(9) BINARY VALUE 1. 002214C 10 MQQA-PUT-ALLOWED PIC S9(9) BINARY VALUE 0. 002215C 002216C ** Queue Shareability 002217C 10 MQQA-SHAREABLE PIC S9(9) BINARY VALUE 1. 002218C 10 MQQA-NOT-SHAREABLE PIC S9(9) BINARY VALUE 0. 002219C 002220C ** Back-Out Hardening 002221C 10 MQQA-BACKOUT-HARDENED PIC S9(9) BINARY VALUE 1. 002222C 10 MQQA-BACKOUT-NOT-HARDENED PIC S9(9) BINARY VALUE 0. 002223C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 43 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002224C ** Message Delivery Sequence 002225C 10 MQMDS-PRIORITY PIC S9(9) BINARY VALUE 0. 002226C 10 MQMDS-FIFO PIC S9(9) BINARY VALUE 1. 002227C 002228C ** Nonpersistent Message Class 002229C 10 MQNPM-CLASS-NORMAL PIC S9(9) BINARY VALUE 0. 002230C 10 MQNPM-CLASS-HIGH PIC S9(9) BINARY VALUE 10. 002231C 002232C ** Trigger Controls 002233C 10 MQTC-OFF PIC S9(9) BINARY VALUE 0. 002234C 10 MQTC-ON PIC S9(9) BINARY VALUE 1. 002235C 002236C ** Trigger Types 002237C 10 MQTT-NONE PIC S9(9) BINARY VALUE 0. 002238C 10 MQTT-FIRST PIC S9(9) BINARY VALUE 1. 002239C 10 MQTT-EVERY PIC S9(9) BINARY VALUE 2. 002240C 10 MQTT-DEPTH PIC S9(9) BINARY VALUE 3. 002241C 002242C ** Trigger Restart 002243C 10 MQTRIGGER-RESTART-NO PIC S9(9) BINARY VALUE 0. 002244C 10 MQTRIGGER-RESTART-YES PIC S9(9) BINARY VALUE 1. 002245C 002246C ** Queue Usages 002247C 10 MQUS-NORMAL PIC S9(9) BINARY VALUE 0. 002248C 10 MQUS-TRANSMISSION PIC S9(9) BINARY VALUE 1. 002249C 002250C ** Distribution Lists 002251C 10 MQDL-SUPPORTED PIC S9(9) BINARY VALUE 1. 002252C 10 MQDL-NOT-SUPPORTED PIC S9(9) BINARY VALUE 0. 002253C 002254C ** Index Types 002255C 10 MQIT-NONE PIC S9(9) BINARY VALUE 0. 002256C 10 MQIT-MSG-ID PIC S9(9) BINARY VALUE 1. 002257C 10 MQIT-CORREL-ID PIC S9(9) BINARY VALUE 2. 002258C 10 MQIT-MSG-TOKEN PIC S9(9) BINARY VALUE 4. 002259C 10 MQIT-GROUP-ID PIC S9(9) BINARY VALUE 5. 002260C 002261C ** Default Bindings 002262C 10 MQBND-BIND-ON-OPEN PIC S9(9) BINARY VALUE 0. 002263C 10 MQBND-BIND-NOT-FIXED PIC S9(9) BINARY VALUE 1. 002264C 10 MQBND-BIND-ON-GROUP PIC S9(9) BINARY VALUE 2. 002265C 002266C ** Queue Sharing Group Dispositions 002267C 10 MQQSGD-ALL PIC S9(9) BINARY VALUE -1. 002268C 10 MQQSGD-Q-MGR PIC S9(9) BINARY VALUE 0. 002269C 10 MQQSGD-COPY PIC S9(9) BINARY VALUE 1. 002270C 10 MQQSGD-SHARED PIC S9(9) BINARY VALUE 2. 002271C 10 MQQSGD-GROUP PIC S9(9) BINARY VALUE 3. 002272C 10 MQQSGD-PRIVATE PIC S9(9) BINARY VALUE 4. 002273C 10 MQQSGD-LIVE PIC S9(9) BINARY VALUE 6. 002274C 002275C ** Reorganization Controls 002276C 10 MQREORG-DISABLED PIC S9(9) BINARY VALUE 0. 002277C 10 MQREORG-ENABLED PIC S9(9) BINARY VALUE 1. 002278C 002279C ** Max queue file size values 002280C 10 MQQFS-DEFAULT PIC S9(9) BINARY VALUE -1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 44 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002281C 002282C ** Queue cap expiry values 002283C 10 MQCEX-NOLIMIT PIC S9(9) BINARY VALUE -1. 002284C 10 MQCEX-AS-PARENT PIC S9(9) BINARY VALUE -2. 002285C 002286C ** OTELTRAC values 002287C 10 MQOTEL-TRACE-QMGR PIC S9(9) BINARY VALUE 0. 002288C 10 MQOTEL-TRACE-OFF PIC S9(9) BINARY VALUE 1. 002289C 10 MQOTEL-TRACE-ON PIC S9(9) BINARY VALUE 2. 002290C 10 MQOTEL-TRACE-NONE PIC S9(9) BINARY VALUE 3. 002291C 10 MQOTEL-TRACE-AS-PARENT PIC S9(9) BINARY VALUE 4. 002292C 002293C ** OTELPCTL values 002294C 10 MQOTEL-PCTL-QMGR PIC S9(9) BINARY VALUE 0. 002295C 10 MQOTEL-PCTL-MANUAL PIC S9(9) BINARY VALUE 1. 002296C 10 MQOTEL-PCTL-AUTO PIC S9(9) BINARY VALUE 2. 002297C 10 MQOTEL-PCTL-AS-PARENT PIC S9(9) BINARY VALUE 3. 002298C 002299C ** Read Ahead Values 002300C 10 MQREADA-NO PIC S9(9) BINARY VALUE 0. 002301C 10 MQREADA-YES PIC S9(9) BINARY VALUE 1. 002302C 10 MQREADA-DISABLED PIC S9(9) BINARY VALUE 2. 002303C 10 MQREADA-INHIBITED PIC S9(9) BINARY VALUE 3. 002304C 10 MQREADA-BACKLOG PIC S9(9) BINARY VALUE 4. 002305C 002306C ** Queue and Channel Property Control Values 002307C 10 MQPROP-COMPATIBILITY PIC S9(9) BINARY VALUE 0. 002308C 10 MQPROP-NONE PIC S9(9) BINARY VALUE 1. 002309C 10 MQPROP-ALL PIC S9(9) BINARY VALUE 2. 002310C 10 MQPROP-FORCE-MQRFH2 PIC S9(9) BINARY VALUE 3. 002311C 10 MQPROP-V6COMPAT PIC S9(9) BINARY VALUE 4. 002312C 002313C ** Streaming Queue Quality of Service Values 002314C 10 MQST-BEST-EFFORT PIC S9(9) BINARY VALUE 0. 002315C 10 MQST-MUST-DUP PIC S9(9) BINARY VALUE 1. 002316C 002317C ****************************************************************** 002318C ** Values Related to Namelist Attributes 002319C ****************************************************************** 002320C ** Name Count 002321C 10 MQNC-MAX-NAMELIST-NAME-COUNT PIC S9(9) BINARY VALUE 256. 002322C 002323C ** Namelist Types 002324C 10 MQNT-NONE PIC S9(9) BINARY VALUE 0. 002325C 10 MQNT-Q PIC S9(9) BINARY VALUE 1. 002326C 10 MQNT-CLUSTER PIC S9(9) BINARY VALUE 2. 002327C 10 MQNT-AUTH-INFO PIC S9(9) BINARY VALUE 4. 002328C 10 MQNT-ALL PIC S9(9) BINARY VALUE 1001. 002329C 002330C ****************************************************************** 002331C ** Values Related to CF-Structure Attributes 002332C ****************************************************************** 002333C ** CF Recoverability 002334C 10 MQCFR-YES PIC S9(9) BINARY VALUE 1. 002335C 10 MQCFR-NO PIC S9(9) BINARY VALUE 0. 002336C 002337C ** CF Automatic Recovery 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 45 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002338C 10 MQRECAUTO-NO PIC S9(9) BINARY VALUE 0. 002339C 10 MQRECAUTO-YES PIC S9(9) BINARY VALUE 1. 002340C 002341C ** CF Loss of Connectivity Action 002342C 10 MQCFCONLOS-TERMINATE PIC S9(9) BINARY VALUE 0. 002343C 10 MQCFCONLOS-TOLERATE PIC S9(9) BINARY VALUE 1. 002344C 10 MQCFCONLOS-ASQMGR PIC S9(9) BINARY VALUE 2. 002345C 002346C ****************************************************************** 002347C ** Values Related to Service Attributes 002348C ****************************************************************** 002349C ** Service Types 002350C 10 MQSVC-TYPE-COMMAND PIC S9(9) BINARY VALUE 0. 002351C 10 MQSVC-TYPE-SERVER PIC S9(9) BINARY VALUE 1. 002352C 002353C ****************************************************************** 002354C ** Values Related to QueueManager Attributes 002355C ****************************************************************** 002356C ** Adopt New MCA Checks 002357C 10 MQADOPT-CHECK-NONE PIC S9(9) BINARY VALUE 0. 002358C 10 MQADOPT-CHECK-ALL PIC S9(9) BINARY VALUE 1. 002359C 10 MQADOPT-CHECK-Q-MGR-NAME PIC S9(9) BINARY VALUE 2. 002360C 10 MQADOPT-CHECK-NET-ADDR PIC S9(9) BINARY VALUE 4. 002361C 10 MQADOPT-CHECK-CHANNEL-NAME PIC S9(9) BINARY VALUE 8. 002362C 002363C ** Adopt New MCA Types 002364C 10 MQADOPT-TYPE-NO PIC S9(9) BINARY VALUE 0. 002365C 10 MQADOPT-TYPE-ALL PIC S9(9) BINARY VALUE 1. 002366C 10 MQADOPT-TYPE-SVR PIC S9(9) BINARY VALUE 2. 002367C 10 MQADOPT-TYPE-SDR PIC S9(9) BINARY VALUE 4. 002368C 10 MQADOPT-TYPE-RCVR PIC S9(9) BINARY VALUE 8. 002369C 10 MQADOPT-TYPE-CLUSRCVR PIC S9(9) BINARY VALUE 16. 002370C 002371C ** Autostart 002372C 10 MQAUTO-START-NO PIC S9(9) BINARY VALUE 0. 002373C 10 MQAUTO-START-YES PIC S9(9) BINARY VALUE 1. 002374C 002375C ** Channel Auto Definition 002376C 10 MQCHAD-DISABLED PIC S9(9) BINARY VALUE 0. 002377C 10 MQCHAD-ENABLED PIC S9(9) BINARY VALUE 1. 002378C 002379C ** Cluster Workload 002380C 10 MQCLWL-USEQ-LOCAL PIC S9(9) BINARY VALUE 0. 002381C 10 MQCLWL-USEQ-ANY PIC S9(9) BINARY VALUE 1. 002382C 10 MQCLWL-USEQ-AS-Q-MGR PIC S9(9) BINARY VALUE -3. 002383C 002384C ** Command Levels 002385C 10 MQCMDL-LEVEL-1 PIC S9(9) BINARY VALUE 100. 002386C 10 MQCMDL-LEVEL-101 PIC S9(9) BINARY VALUE 101. 002387C 10 MQCMDL-LEVEL-110 PIC S9(9) BINARY VALUE 110. 002388C 10 MQCMDL-LEVEL-114 PIC S9(9) BINARY VALUE 114. 002389C 10 MQCMDL-LEVEL-120 PIC S9(9) BINARY VALUE 120. 002390C 10 MQCMDL-LEVEL-200 PIC S9(9) BINARY VALUE 200. 002391C 10 MQCMDL-LEVEL-201 PIC S9(9) BINARY VALUE 201. 002392C 10 MQCMDL-LEVEL-210 PIC S9(9) BINARY VALUE 210. 002393C 10 MQCMDL-LEVEL-211 PIC S9(9) BINARY VALUE 211. 002394C 10 MQCMDL-LEVEL-220 PIC S9(9) BINARY VALUE 220. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 46 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002395C 10 MQCMDL-LEVEL-221 PIC S9(9) BINARY VALUE 221. 002396C 10 MQCMDL-LEVEL-230 PIC S9(9) BINARY VALUE 230. 002397C 10 MQCMDL-LEVEL-320 PIC S9(9) BINARY VALUE 320. 002398C 10 MQCMDL-LEVEL-420 PIC S9(9) BINARY VALUE 420. 002399C 10 MQCMDL-LEVEL-500 PIC S9(9) BINARY VALUE 500. 002400C 10 MQCMDL-LEVEL-510 PIC S9(9) BINARY VALUE 510. 002401C 10 MQCMDL-LEVEL-520 PIC S9(9) BINARY VALUE 520. 002402C 10 MQCMDL-LEVEL-530 PIC S9(9) BINARY VALUE 530. 002403C 10 MQCMDL-LEVEL-531 PIC S9(9) BINARY VALUE 531. 002404C 10 MQCMDL-LEVEL-600 PIC S9(9) BINARY VALUE 600. 002405C 10 MQCMDL-LEVEL-700 PIC S9(9) BINARY VALUE 700. 002406C 10 MQCMDL-LEVEL-701 PIC S9(9) BINARY VALUE 701. 002407C 10 MQCMDL-LEVEL-710 PIC S9(9) BINARY VALUE 710. 002408C 10 MQCMDL-LEVEL-711 PIC S9(9) BINARY VALUE 711. 002409C 10 MQCMDL-LEVEL-750 PIC S9(9) BINARY VALUE 750. 002410C 10 MQCMDL-LEVEL-800 PIC S9(9) BINARY VALUE 800. 002411C 10 MQCMDL-LEVEL-801 PIC S9(9) BINARY VALUE 801. 002412C 10 MQCMDL-LEVEL-802 PIC S9(9) BINARY VALUE 802. 002413C 10 MQCMDL-LEVEL-900 PIC S9(9) BINARY VALUE 900. 002414C 10 MQCMDL-LEVEL-901 PIC S9(9) BINARY VALUE 901. 002415C 10 MQCMDL-LEVEL-902 PIC S9(9) BINARY VALUE 902. 002416C 10 MQCMDL-LEVEL-903 PIC S9(9) BINARY VALUE 903. 002417C 10 MQCMDL-LEVEL-904 PIC S9(9) BINARY VALUE 904. 002418C 10 MQCMDL-LEVEL-905 PIC S9(9) BINARY VALUE 905. 002419C 10 MQCMDL-LEVEL-910 PIC S9(9) BINARY VALUE 910. 002420C 10 MQCMDL-LEVEL-911 PIC S9(9) BINARY VALUE 911. 002421C 10 MQCMDL-LEVEL-912 PIC S9(9) BINARY VALUE 912. 002422C 10 MQCMDL-LEVEL-913 PIC S9(9) BINARY VALUE 913. 002423C 10 MQCMDL-LEVEL-914 PIC S9(9) BINARY VALUE 914. 002424C 10 MQCMDL-LEVEL-915 PIC S9(9) BINARY VALUE 915. 002425C 10 MQCMDL-LEVEL-920 PIC S9(9) BINARY VALUE 920. 002426C 10 MQCMDL-LEVEL-921 PIC S9(9) BINARY VALUE 921. 002427C 10 MQCMDL-LEVEL-922 PIC S9(9) BINARY VALUE 922. 002428C 10 MQCMDL-LEVEL-923 PIC S9(9) BINARY VALUE 923. 002429C 10 MQCMDL-LEVEL-924 PIC S9(9) BINARY VALUE 924. 002430C 10 MQCMDL-LEVEL-925 PIC S9(9) BINARY VALUE 925. 002431C 10 MQCMDL-LEVEL-930 PIC S9(9) BINARY VALUE 930. 002432C 10 MQCMDL-LEVEL-931 PIC S9(9) BINARY VALUE 931. 002433C 10 MQCMDL-LEVEL-932 PIC S9(9) BINARY VALUE 932. 002434C 10 MQCMDL-LEVEL-933 PIC S9(9) BINARY VALUE 933. 002435C 10 MQCMDL-LEVEL-934 PIC S9(9) BINARY VALUE 934. 002436C 10 MQCMDL-LEVEL-935 PIC S9(9) BINARY VALUE 935. 002437C 10 MQCMDL-LEVEL-940 PIC S9(9) BINARY VALUE 940. 002438C 10 MQCMDL-LEVEL-941 PIC S9(9) BINARY VALUE 941. 002439C 10 MQCMDL-LEVEL-942 PIC S9(9) BINARY VALUE 942. 002440C 10 MQCMDL-LEVEL-943 PIC S9(9) BINARY VALUE 943. 002441C 10 MQCMDL-LEVEL-944 PIC S9(9) BINARY VALUE 944. 002442C 10 MQCMDL-LEVEL-945 PIC S9(9) BINARY VALUE 945. 002443C 10 MQCMDL-CURRENT-LEVEL PIC S9(9) BINARY VALUE 945. 002444C 002445C ** Command Server Options 002446C 10 MQCSRV-CONVERT-NO PIC S9(9) BINARY VALUE 0. 002447C 10 MQCSRV-CONVERT-YES PIC S9(9) BINARY VALUE 1. 002448C 10 MQCSRV-DLQ-NO PIC S9(9) BINARY VALUE 0. 002449C 10 MQCSRV-DLQ-YES PIC S9(9) BINARY VALUE 1. 002450C 002451C ** DNS WLM 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 47 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002452C 10 MQDNSWLM-NO PIC S9(9) BINARY VALUE 0. 002453C 10 MQDNSWLM-YES PIC S9(9) BINARY VALUE 1. 002454C 002455C ** Expiration Scan Interval 002456C 10 MQEXPI-OFF PIC S9(9) BINARY VALUE 0. 002457C 002458C ** Intra-Group Queuing 002459C 10 MQIGQ-DISABLED PIC S9(9) BINARY VALUE 0. 002460C 10 MQIGQ-ENABLED PIC S9(9) BINARY VALUE 1. 002461C 002462C ** Intra-Group Queuing Put Authority 002463C 10 MQIGQPA-DEFAULT PIC S9(9) BINARY VALUE 1. 002464C 10 MQIGQPA-CONTEXT PIC S9(9) BINARY VALUE 2. 002465C 10 MQIGQPA-ONLY-IGQ PIC S9(9) BINARY VALUE 3. 002466C 10 MQIGQPA-ALTERNATE-OR-IGQ PIC S9(9) BINARY VALUE 4. 002467C 002468C ** IP Address Versions 002469C 10 MQIPADDR-IPV4 PIC S9(9) BINARY VALUE 0. 002470C 10 MQIPADDR-IPV6 PIC S9(9) BINARY VALUE 1. 002471C 002472C ** Message Mark-Browse Interval 002473C 10 MQMMBI-UNLIMITED PIC S9(9) BINARY VALUE -1. 002474C 002475C ** Monitoring Values 002476C 10 MQMON-NOT-AVAILABLE PIC S9(9) BINARY VALUE -1. 002477C 10 MQMON-NONE PIC S9(9) BINARY VALUE -1. 002478C 10 MQMON-Q-MGR PIC S9(9) BINARY VALUE -3. 002479C 10 MQMON-OFF PIC S9(9) BINARY VALUE 0. 002480C 10 MQMON-ON PIC S9(9) BINARY VALUE 1. 002481C 10 MQMON-DISABLED PIC S9(9) BINARY VALUE 0. 002482C 10 MQMON-ENABLED PIC S9(9) BINARY VALUE 1. 002483C 10 MQMON-LOW PIC S9(9) BINARY VALUE 17. 002484C 10 MQMON-MEDIUM PIC S9(9) BINARY VALUE 33. 002485C 10 MQMON-HIGH PIC S9(9) BINARY VALUE 65. 002486C 002487C ** Application Function Types 002488C 10 MQFUN-TYPE-UNKNOWN PIC S9(9) BINARY VALUE 0. 002489C 10 MQFUN-TYPE-JVM PIC S9(9) BINARY VALUE 1. 002490C 10 MQFUN-TYPE-PROGRAM PIC S9(9) BINARY VALUE 2. 002491C 10 MQFUN-TYPE-PROCEDURE PIC S9(9) BINARY VALUE 3. 002492C 10 MQFUN-TYPE-USERDEF PIC S9(9) BINARY VALUE 4. 002493C 10 MQFUN-TYPE-COMMAND PIC S9(9) BINARY VALUE 5. 002494C 002495C ** Application Activity Trace Detail 002496C 10 MQACTV-DETAIL-LOW PIC S9(9) BINARY VALUE 1. 002497C 10 MQACTV-DETAIL-MEDIUM PIC S9(9) BINARY VALUE 2. 002498C 10 MQACTV-DETAIL-HIGH PIC S9(9) BINARY VALUE 3. 002499C 002500C ** Platforms 002501C 10 MQPL-MVS PIC S9(9) BINARY VALUE 1. 002502C 10 MQPL-OS390 PIC S9(9) BINARY VALUE 1. 002503C 10 MQPL-ZOS PIC S9(9) BINARY VALUE 1. 002504C 10 MQPL-OS2 PIC S9(9) BINARY VALUE 2. 002505C 10 MQPL-AIX PIC S9(9) BINARY VALUE 3. 002506C 10 MQPL-UNIX PIC S9(9) BINARY VALUE 3. 002507C 10 MQPL-OS400 PIC S9(9) BINARY VALUE 4. 002508C 10 MQPL-WINDOWS PIC S9(9) BINARY VALUE 5. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 48 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002509C 10 MQPL-WINDOWS-NT PIC S9(9) BINARY VALUE 11. 002510C 10 MQPL-VMS PIC S9(9) BINARY VALUE 12. 002511C 10 MQPL-NSK PIC S9(9) BINARY VALUE 13. 002512C 10 MQPL-NSS PIC S9(9) BINARY VALUE 13. 002513C 10 MQPL-OPEN-TP1 PIC S9(9) BINARY VALUE 15. 002514C 10 MQPL-VM PIC S9(9) BINARY VALUE 18. 002515C 10 MQPL-TPF PIC S9(9) BINARY VALUE 23. 002516C 10 MQPL-VSE PIC S9(9) BINARY VALUE 27. 002517C 10 MQPL-APPLIANCE PIC S9(9) BINARY VALUE 28. 002518C 002519C ** Maximum Properties Length 002520C 10 MQPROP-UNRESTRICTED-LENGTH PIC S9(9) BINARY VALUE -1. 002521C 002522C ** Pub/Sub Mode 002523C 10 MQPSM-DISABLED PIC S9(9) BINARY VALUE 0. 002524C 10 MQPSM-COMPAT PIC S9(9) BINARY VALUE 1. 002525C 10 MQPSM-ENABLED PIC S9(9) BINARY VALUE 2. 002526C 002527C ** Pub/Sub clusters 002528C 10 MQPSCLUS-DISABLED PIC S9(9) BINARY VALUE 0. 002529C 10 MQPSCLUS-ENABLED PIC S9(9) BINARY VALUE 1. 002530C 002531C ** Control Options 002532C 10 MQQMOPT-DISABLED PIC S9(9) BINARY VALUE 0. 002533C 10 MQQMOPT-ENABLED PIC S9(9) BINARY VALUE 1. 002534C 10 MQQMOPT-REPLY PIC S9(9) BINARY VALUE 2. 002535C 002536C ** Receive Timeout Types 002537C 10 MQRCVTIME-MULTIPLY PIC S9(9) BINARY VALUE 0. 002538C 10 MQRCVTIME-ADD PIC S9(9) BINARY VALUE 1. 002539C 10 MQRCVTIME-EQUAL PIC S9(9) BINARY VALUE 2. 002540C 002541C ** Recording Options 002542C 10 MQRECORDING-DISABLED PIC S9(9) BINARY VALUE 0. 002543C 10 MQRECORDING-Q PIC S9(9) BINARY VALUE 1. 002544C 10 MQRECORDING-MSG PIC S9(9) BINARY VALUE 2. 002545C 002546C ** Security Case 002547C 10 MQSCYC-UPPER PIC S9(9) BINARY VALUE 0. 002548C 10 MQSCYC-MIXED PIC S9(9) BINARY VALUE 1. 002549C 002550C ** Shared Queue Queue Manager Name 002551C 10 MQSQQM-USE PIC S9(9) BINARY VALUE 0. 002552C 10 MQSQQM-IGNORE PIC S9(9) BINARY VALUE 1. 002553C 002554C ** SSL FIPS Requirements 002555C 10 MQSSL-FIPS-NO PIC S9(9) BINARY VALUE 0. 002556C 10 MQSSL-FIPS-YES PIC S9(9) BINARY VALUE 1. 002557C 002558C ** Syncpoint Availability 002559C 10 MQSP-AVAILABLE PIC S9(9) BINARY VALUE 1. 002560C 10 MQSP-NOT-AVAILABLE PIC S9(9) BINARY VALUE 0. 002561C 002562C ** Service Controls 002563C 10 MQSVC-CONTROL-Q-MGR PIC S9(9) BINARY VALUE 0. 002564C 10 MQSVC-CONTROL-Q-MGR-START PIC S9(9) BINARY VALUE 1. 002565C 10 MQSVC-CONTROL-MANUAL PIC S9(9) BINARY VALUE 2. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 49 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002566C 002567C ** Service Status 002568C 10 MQSVC-STATUS-STOPPED PIC S9(9) BINARY VALUE 0. 002569C 10 MQSVC-STATUS-STARTING PIC S9(9) BINARY VALUE 1. 002570C 10 MQSVC-STATUS-RUNNING PIC S9(9) BINARY VALUE 2. 002571C 10 MQSVC-STATUS-STOPPING PIC S9(9) BINARY VALUE 3. 002572C 10 MQSVC-STATUS-RETRYING PIC S9(9) BINARY VALUE 4. 002573C 002574C ** TCP Keepalive 002575C 10 MQTCPKEEP-NO PIC S9(9) BINARY VALUE 0. 002576C 10 MQTCPKEEP-YES PIC S9(9) BINARY VALUE 1. 002577C 002578C ** TCP Stack Types 002579C 10 MQTCPSTACK-SINGLE PIC S9(9) BINARY VALUE 0. 002580C 10 MQTCPSTACK-MULTIPLE PIC S9(9) BINARY VALUE 1. 002581C 002582C ** Channel Initiator Trace Autostart 002583C 10 MQTRAXSTR-NO PIC S9(9) BINARY VALUE 0. 002584C 10 MQTRAXSTR-YES PIC S9(9) BINARY VALUE 1. 002585C 002586C ** Capability 002587C 10 MQCAP-NOT-SUPPORTED PIC S9(9) BINARY VALUE 0. 002588C 10 MQCAP-SUPPORTED PIC S9(9) BINARY VALUE 1. 002589C 10 MQCAP-EXPIRED PIC S9(9) BINARY VALUE 2. 002590C 002591C ** Media Image Scheduling 002592C 10 MQMEDIMGSCHED-MANUAL PIC S9(9) BINARY VALUE 0. 002593C 10 MQMEDIMGSCHED-AUTO PIC S9(9) BINARY VALUE 1. 002594C 002595C ** Automatic Media Image Interval 002596C 10 MQMEDIMGINTVL-OFF PIC S9(9) BINARY VALUE 0. 002597C 002598C ** Automatic Media Image Log Length 002599C 10 MQMEDIMGLOGLN-OFF PIC S9(9) BINARY VALUE 0. 002600C 002601C ** Media Image Recoverability 002602C 10 MQIMGRCOV-NO PIC S9(9) BINARY VALUE 0. 002603C 10 MQIMGRCOV-YES PIC S9(9) BINARY VALUE 1. 002604C 10 MQIMGRCOV-AS-Q-MGR PIC S9(9) BINARY VALUE 2. 002605C 002606C ****************************************************************** 002607C ** Values Related to Topic Attributes 002608C ****************************************************************** 002609C ** Persistent/Non-persistent Message Delivery 002610C 10 MQDLV-AS-PARENT PIC S9(9) BINARY VALUE 0. 002611C 10 MQDLV-ALL PIC S9(9) BINARY VALUE 1. 002612C 10 MQDLV-ALL-DUR PIC S9(9) BINARY VALUE 2. 002613C 10 MQDLV-ALL-AVAIL PIC S9(9) BINARY VALUE 3. 002614C 002615C ** Master administration 002616C 10 MQMASTER-NO PIC S9(9) BINARY VALUE 0. 002617C 10 MQMASTER-YES PIC S9(9) BINARY VALUE 1. 002618C 002619C ** Publish scope 002620C 10 MQSCOPE-ALL PIC S9(9) BINARY VALUE 0. 002621C 10 MQSCOPE-AS-PARENT PIC S9(9) BINARY VALUE 1. 002622C 10 MQSCOPE-QMGR PIC S9(9) BINARY VALUE 4. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 50 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002623C 002624C ** Durable subscriptions 002625C 10 MQSUB-DURABLE-AS-PARENT PIC S9(9) BINARY VALUE 0. 002626C 10 MQSUB-DURABLE-ALLOWED PIC S9(9) BINARY VALUE 1. 002627C 10 MQSUB-DURABLE-INHIBITED PIC S9(9) BINARY VALUE 2. 002628C 002629C ** Wildcards 002630C 10 MQTA-BLOCK PIC S9(9) BINARY VALUE 1. 002631C 10 MQTA-PASSTHRU PIC S9(9) BINARY VALUE 2. 002632C 002633C ** Subscriptions Allowed 002634C 10 MQTA-SUB-AS-PARENT PIC S9(9) BINARY VALUE 0. 002635C 10 MQTA-SUB-INHIBITED PIC S9(9) BINARY VALUE 1. 002636C 10 MQTA-SUB-ALLOWED PIC S9(9) BINARY VALUE 2. 002637C 002638C ** Proxy Sub Propagation 002639C 10 MQTA-PROXY-SUB-FORCE PIC S9(9) BINARY VALUE 1. 002640C 10 MQTA-PROXY-SUB-FIRSTUSE PIC S9(9) BINARY VALUE 2. 002641C 002642C ** Publications Allowed 002643C 10 MQTA-PUB-AS-PARENT PIC S9(9) BINARY VALUE 0. 002644C 10 MQTA-PUB-INHIBITED PIC S9(9) BINARY VALUE 1. 002645C 10 MQTA-PUB-ALLOWED PIC S9(9) BINARY VALUE 2. 002646C 002647C ** Topic Type 002648C 10 MQTOPT-LOCAL PIC S9(9) BINARY VALUE 0. 002649C 10 MQTOPT-CLUSTER PIC S9(9) BINARY VALUE 1. 002650C 10 MQTOPT-ALL PIC S9(9) BINARY VALUE 2. 002651C 002652C ** Multicast 002653C 10 MQMC-AS-PARENT PIC S9(9) BINARY VALUE 0. 002654C 10 MQMC-ENABLED PIC S9(9) BINARY VALUE 1. 002655C 10 MQMC-DISABLED PIC S9(9) BINARY VALUE 2. 002656C 10 MQMC-ONLY PIC S9(9) BINARY VALUE 3. 002657C 002658C ** CommInfo Type 002659C 10 MQCIT-MULTICAST PIC S9(9) BINARY VALUE 1. 002660C 002661C ****************************************************************** 002662C ** Values Related to Subscription Attributes 002663C ****************************************************************** 002664C ** Destination Class 002665C 10 MQDC-MANAGED PIC S9(9) BINARY VALUE 1. 002666C 10 MQDC-PROVIDED PIC S9(9) BINARY VALUE 2. 002667C 002668C ** Pub/Sub Message Properties 002669C 10 MQPSPROP-NONE PIC S9(9) BINARY VALUE 0. 002670C 10 MQPSPROP-COMPAT PIC S9(9) BINARY VALUE 1. 002671C 10 MQPSPROP-RFH2 PIC S9(9) BINARY VALUE 2. 002672C 10 MQPSPROP-MSGPROP PIC S9(9) BINARY VALUE 3. 002673C 002674C ** Request Only 002675C 10 MQRU-PUBLISH-ON-REQUEST PIC S9(9) BINARY VALUE 1. 002676C 10 MQRU-PUBLISH-ALL PIC S9(9) BINARY VALUE 2. 002677C 002678C ** Durable Subscriptions 002679C 10 MQSUB-DURABLE-ALL PIC S9(9) BINARY VALUE -1. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 51 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002680C 10 MQSUB-DURABLE-YES PIC S9(9) BINARY VALUE 1. 002681C 10 MQSUB-DURABLE-NO PIC S9(9) BINARY VALUE 2. 002682C 002683C ** Subscription Scope 002684C 10 MQTSCOPE-QMGR PIC S9(9) BINARY VALUE 1. 002685C 10 MQTSCOPE-ALL PIC S9(9) BINARY VALUE 2. 002686C 002687C ** Variable User ID 002688C 10 MQVU-FIXED-USER PIC S9(9) BINARY VALUE 1. 002689C 10 MQVU-ANY-USER PIC S9(9) BINARY VALUE 2. 002690C 002691C ** Wildcard Schema 002692C 10 MQWS-DEFAULT PIC S9(9) BINARY VALUE 0. 002693C 10 MQWS-CHAR PIC S9(9) BINARY VALUE 1. 002694C 10 MQWS-TOPIC PIC S9(9) BINARY VALUE 2. 002695C 002696C ****************************************************************** 002697C ** Values Related to Channel Authentication Configuration 002698C ** Attributes 002699C ****************************************************************** 002700C ** User Source Options 002701C 10 MQUSRC-MAP PIC S9(9) BINARY VALUE 0. 002702C 10 MQUSRC-NOACCESS PIC S9(9) BINARY VALUE 1. 002703C 10 MQUSRC-CHANNEL PIC S9(9) BINARY VALUE 2. 002704C 002705C ** Warn Options 002706C 10 MQWARN-YES PIC S9(9) BINARY VALUE 1. 002707C 10 MQWARN-NO PIC S9(9) BINARY VALUE 0. 002708C 002709C ** DSBlock Options 002710C 10 MQDSB-DEFAULT PIC S9(9) BINARY VALUE 0. 002711C 10 MQDSB-8K PIC S9(9) BINARY VALUE 1. 002712C 10 MQDSB-16K PIC S9(9) BINARY VALUE 2. 002713C 10 MQDSB-32K PIC S9(9) BINARY VALUE 3. 002714C 10 MQDSB-64K PIC S9(9) BINARY VALUE 4. 002715C 10 MQDSB-128K PIC S9(9) BINARY VALUE 5. 002716C 10 MQDSB-256K PIC S9(9) BINARY VALUE 6. 002717C 10 MQDSB-512K PIC S9(9) BINARY VALUE 7. 002718C 10 MQDSB-1024K PIC S9(9) BINARY VALUE 8. 002719C 10 MQDSB-1M PIC S9(9) BINARY VALUE 8. 002720C 002721C ** DSExpand Options 002722C 10 MQDSE-DEFAULT PIC S9(9) BINARY VALUE 0. 002723C 10 MQDSE-YES PIC S9(9) BINARY VALUE 1. 002724C 10 MQDSE-NO PIC S9(9) BINARY VALUE 2. 002725C 002726C ** OffldUse Options 002727C 10 MQCFOFFLD-NONE PIC S9(9) BINARY VALUE 0. 002728C 10 MQCFOFFLD-SMDS PIC S9(9) BINARY VALUE 1. 002729C 10 MQCFOFFLD-DB2 PIC S9(9) BINARY VALUE 2. 002730C 10 MQCFOFFLD-BOTH PIC S9(9) BINARY VALUE 3. 002731C 002732C ** Use Dead Letter Queue Options 002733C 10 MQUSEDLQ-AS-PARENT PIC S9(9) BINARY VALUE 0. 002734C 10 MQUSEDLQ-NO PIC S9(9) BINARY VALUE 1. 002735C 10 MQUSEDLQ-YES PIC S9(9) BINARY VALUE 2. 002736C 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 52 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002737C ****************************************************************** 002738C ** Values Related to MQCLOSE Function 002739C ****************************************************************** 002740C ** Object Handle 002741C 10 MQHO-UNUSABLE-HOBJ PIC S9(9) BINARY VALUE -1. 002742C 10 MQHO-NONE PIC S9(9) BINARY VALUE 0. 002743C 002744C ** Close Options 002745C 10 MQCO-IMMEDIATE PIC S9(9) BINARY VALUE 0. 002746C 10 MQCO-NONE PIC S9(9) BINARY VALUE 0. 002747C 10 MQCO-DELETE PIC S9(9) BINARY VALUE 1. 002748C 10 MQCO-DELETE-PURGE PIC S9(9) BINARY VALUE 2. 002749C 10 MQCO-KEEP-SUB PIC S9(9) BINARY VALUE 4. 002750C 10 MQCO-REMOVE-SUB PIC S9(9) BINARY VALUE 8. 002751C 10 MQCO-QUIESCE PIC S9(9) BINARY VALUE 32. 002752C 002753C ****************************************************************** 002754C ** Values Related to MQCTL and MQCB Functions 002755C ****************************************************************** 002756C ** Operation codes for MQCTL 002757C 10 MQOP-START PIC S9(9) BINARY VALUE 1. 002758C 10 MQOP-START-WAIT PIC S9(9) BINARY VALUE 2. 002759C 10 MQOP-STOP PIC S9(9) BINARY VALUE 4. 002760C 002761C ** Operation codes for MQCB 002762C 10 MQOP-REGISTER PIC S9(9) BINARY VALUE 256. 002763C 10 MQOP-DEREGISTER PIC S9(9) BINARY VALUE 512. 002764C 002765C ** Operation codes for MQCTL and MQCB 002766C 10 MQOP-SUSPEND PIC S9(9) BINARY VALUE 65536. 002767C 10 MQOP-RESUME PIC S9(9) BINARY VALUE 131072. 002768C 002769C ****************************************************************** 002770C ** Values Related to MQDLTMH Function 002771C ****************************************************************** 002772C ** Message handle 002773C 10 MQHM-UNUSABLE-HMSG PIC S9(18) BINARY VALUE -1. 002774C 10 MQHM-NONE PIC S9(18) BINARY VALUE 0. 002775C 002776C ****************************************************************** 002777C ** Values Related to MQINQ Function 002778C ****************************************************************** 002779C ** Byte Attribute Selectors 002780C 10 MQBA-FIRST PIC S9(9) BINARY VALUE 6001. 002781C 10 MQBA-LAST PIC S9(9) BINARY VALUE 8000. 002782C 002783C ** Character Attribute Selectors 002784C 10 MQCA-ADMIN-TOPIC-NAME PIC S9(9) BINARY VALUE 2105. 002785C 10 MQCA-ALTERATION-DATE PIC S9(9) BINARY VALUE 2027. 002786C 10 MQCA-ALTERATION-TIME PIC S9(9) BINARY VALUE 2028. 002787C 10 MQCA-AMQP-SSL-CIPHER-SUITES PIC S9(9) BINARY VALUE 2137. 002788C 10 MQCA-AMQP-VERSION PIC S9(9) BINARY VALUE 2136. 002789C 10 MQCA-APPL-ID PIC S9(9) BINARY VALUE 2001. 002790C 10 MQCA-AUTH-INFO-CONN-NAME PIC S9(9) BINARY VALUE 2053. 002791C 10 MQCA-AUTH-INFO-DESC PIC S9(9) BINARY VALUE 2046. 002792C 10 MQCA-AUTH-INFO-NAME PIC S9(9) BINARY VALUE 2045. 002793C 10 MQCA-AUTH-INFO-OCSP-URL PIC S9(9) BINARY VALUE 2109. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 53 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002794C 10 MQCA-AUTO-REORG-CATALOG PIC S9(9) BINARY VALUE 2091. 002795C 10 MQCA-AUTO-REORG-START-TIME PIC S9(9) BINARY VALUE 2090. 002796C 10 MQCA-BACKOUT-REQ-Q-NAME PIC S9(9) BINARY VALUE 2019. 002797C 10 MQCA-BASE-OBJECT-NAME PIC S9(9) BINARY VALUE 2002. 002798C 10 MQCA-BASE-Q-NAME PIC S9(9) BINARY VALUE 2002. 002799C 10 MQCA-BATCH-INTERFACE-ID PIC S9(9) BINARY VALUE 2068. 002800C 10 MQCA-CERT-LABEL PIC S9(9) BINARY VALUE 2121. 002801C 10 MQCA-CF-STRUC-DESC PIC S9(9) BINARY VALUE 2052. 002802C 10 MQCA-CF-STRUC-NAME PIC S9(9) BINARY VALUE 2039. 002803C 10 MQCA-CHANNEL-AUTO-DEF-EXIT PIC S9(9) BINARY VALUE 2026. 002804C 10 MQCA-CHILD PIC S9(9) BINARY VALUE 2101. 002805C 10 MQCA-CHINIT-SERVICE-PARM PIC S9(9) BINARY VALUE 2076. 002806C 10 MQCA-CHLAUTH-DESC PIC S9(9) BINARY VALUE 2118. 002807C 10 MQCA-CICS-FILE-NAME PIC S9(9) BINARY VALUE 2060. 002808C 10 MQCA-CLUSTER-DATE PIC S9(9) BINARY VALUE 2037. 002809C 10 MQCA-CLUSTER-NAME PIC S9(9) BINARY VALUE 2029. 002810C 10 MQCA-CLUSTER-NAMELIST PIC S9(9) BINARY VALUE 2030. 002811C 10 MQCA-CLUSTER-Q-MGR-NAME PIC S9(9) BINARY VALUE 2031. 002812C 10 MQCA-CLUSTER-TIME PIC S9(9) BINARY VALUE 2038. 002813C 10 MQCA-CLUSTER-WORKLOAD-DATA PIC S9(9) BINARY VALUE 2034. 002814C 10 MQCA-CLUSTER-WORKLOAD-EXIT PIC S9(9) BINARY VALUE 2033. 002815C 10 MQCA-CLUS-CHL-NAME PIC S9(9) BINARY VALUE 2124. 002816C 10 MQCA-COMMAND-INPUT-Q-NAME PIC S9(9) BINARY VALUE 2003. 002817C 10 MQCA-COMMAND-REPLY-Q-NAME PIC S9(9) BINARY VALUE 2067. 002818C 10 MQCA-COMM-INFO-DESC PIC S9(9) BINARY VALUE 2111. 002819C 10 MQCA-COMM-INFO-NAME PIC S9(9) BINARY VALUE 2110. 002820C 10 MQCA-CONN-AUTH PIC S9(9) BINARY VALUE 2125. 002821C 10 MQCA-CREATION-DATE PIC S9(9) BINARY VALUE 2004. 002822C 10 MQCA-CREATION-TIME PIC S9(9) BINARY VALUE 2005. 002823C 10 MQCA-CUSTOM PIC S9(9) BINARY VALUE 2119. 002824C 10 MQCA-DEAD-LETTER-Q-NAME PIC S9(9) BINARY VALUE 2006. 002825C 10 MQCA-DEF-XMIT-Q-NAME PIC S9(9) BINARY VALUE 2025. 002826C 10 MQCA-DNS-GROUP PIC S9(9) BINARY VALUE 2071. 002827C 10 MQCA-ENV-DATA PIC S9(9) BINARY VALUE 2007. 002828C 10 MQCA-FIRST PIC S9(9) BINARY VALUE 2001. 002829C 10 MQCA-IGQ-USER-ID PIC S9(9) BINARY VALUE 2041. 002830C 10 MQCA-INITIAL-KEY PIC S9(9) BINARY VALUE 2054. 002831C 10 MQCA-INITIATION-Q-NAME PIC S9(9) BINARY VALUE 2008. 002832C 10 MQCA-INSTALLATION-DESC PIC S9(9) BINARY VALUE 2115. 002833C 10 MQCA-INSTALLATION-NAME PIC S9(9) BINARY VALUE 2116. 002834C 10 MQCA-INSTALLATION-PATH PIC S9(9) BINARY VALUE 2117. 002835C 10 MQCA-LAST PIC S9(9) BINARY VALUE 4000. 002836C 10 MQCA-LAST-USED PIC S9(9) BINARY VALUE 2138. 002837C 10 MQCA-LDAP-BASE-DN-GROUPS PIC S9(9) BINARY VALUE 2132. 002838C 10 MQCA-LDAP-BASE-DN-USERS PIC S9(9) BINARY VALUE 2126. 002839C 10 MQCA-LDAP-FIND-GROUP-FIELD PIC S9(9) BINARY VALUE 2135. 002840C 10 MQCA-LDAP-GROUP-ATTR-FIELD PIC S9(9) BINARY VALUE 2134. 002841C 10 MQCA-LDAP-GROUP-OBJECT-CLASS PIC S9(9) BINARY VALUE 2133. 002842C 10 MQCA-LDAP-PASSWORD PIC S9(9) BINARY VALUE 2048. 002843C 10 MQCA-LDAP-SHORT-USER-FIELD PIC S9(9) BINARY VALUE 2127. 002844C 10 MQCA-LDAP-USER-ATTR-FIELD PIC S9(9) BINARY VALUE 2129. 002845C 10 MQCA-LDAP-USER-NAME PIC S9(9) BINARY VALUE 2047. 002846C 10 MQCA-LDAP-USER-OBJECT-CLASS PIC S9(9) BINARY VALUE 2128. 002847C 10 MQCA-LU62-ARM-SUFFIX PIC S9(9) BINARY VALUE 2074. 002848C 10 MQCA-LU-GROUP-NAME PIC S9(9) BINARY VALUE 2072. 002849C 10 MQCA-LU-NAME PIC S9(9) BINARY VALUE 2073. 002850C 10 MQCA-MODEL-DURABLE-Q PIC S9(9) BINARY VALUE 2096. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 54 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002851C 10 MQCA-MODEL-NON-DURABLE-Q PIC S9(9) BINARY VALUE 2097. 002852C 10 MQCA-MONITOR-Q-NAME PIC S9(9) BINARY VALUE 2066. 002853C 10 MQCA-NAMELIST-DESC PIC S9(9) BINARY VALUE 2009. 002854C 10 MQCA-NAMELIST-NAME PIC S9(9) BINARY VALUE 2010. 002855C 10 MQCA-NAMES PIC S9(9) BINARY VALUE 2020. 002856C 10 MQCA-PARENT PIC S9(9) BINARY VALUE 2102. 002857C 10 MQCA-PASS-TICKET-APPL PIC S9(9) BINARY VALUE 2086. 002858C 10 MQCA-POLICY-NAME PIC S9(9) BINARY VALUE 2112. 002859C 10 MQCA-PROCESS-DESC PIC S9(9) BINARY VALUE 2011. 002860C 10 MQCA-PROCESS-NAME PIC S9(9) BINARY VALUE 2012. 002861C 10 MQCA-QSG-CERT-LABEL PIC S9(9) BINARY VALUE 2131. 002862C 10 MQCA-QSG-NAME PIC S9(9) BINARY VALUE 2040. 002863C 10 MQCA-Q-DESC PIC S9(9) BINARY VALUE 2013. 002864C 10 MQCA-Q-MGR-DESC PIC S9(9) BINARY VALUE 2014. 002865C 10 MQCA-Q-MGR-IDENTIFIER PIC S9(9) BINARY VALUE 2032. 002866C 10 MQCA-Q-MGR-NAME PIC S9(9) BINARY VALUE 2015. 002867C 10 MQCA-Q-NAME PIC S9(9) BINARY VALUE 2016. 002868C 10 MQCA-RECIPIENT-DN PIC S9(9) BINARY VALUE 2114. 002869C 10 MQCA-REMOTE-Q-MGR-NAME PIC S9(9) BINARY VALUE 2017. 002870C 10 MQCA-REMOTE-Q-NAME PIC S9(9) BINARY VALUE 2018. 002871C 10 MQCA-REPOSITORY-NAME PIC S9(9) BINARY VALUE 2035. 002872C 10 MQCA-REPOSITORY-NAMELIST PIC S9(9) BINARY VALUE 2036. 002873C 10 MQCA-RESUME-DATE PIC S9(9) BINARY VALUE 2098. 002874C 10 MQCA-RESUME-TIME PIC S9(9) BINARY VALUE 2099. 002875C 10 MQCA-SERVICE-DESC PIC S9(9) BINARY VALUE 2078. 002876C 10 MQCA-SERVICE-NAME PIC S9(9) BINARY VALUE 2077. 002877C 10 MQCA-SERVICE-START-ARGS PIC S9(9) BINARY VALUE 2080. 002878C 10 MQCA-SERVICE-START-COMMAND PIC S9(9) BINARY VALUE 2079. 002879C 10 MQCA-SERVICE-STOP-ARGS PIC S9(9) BINARY VALUE 2082. 002880C 10 MQCA-SERVICE-STOP-COMMAND PIC S9(9) BINARY VALUE 2081. 002881C 10 MQCA-SIGNER-DN PIC S9(9) BINARY VALUE 2113. 002882C 10 MQCA-SSL-CERT-ISSUER-NAME PIC S9(9) BINARY VALUE 2130. 002883C 10 MQCA-SSL-CRL-NAMELIST PIC S9(9) BINARY VALUE 2050. 002884C 10 MQCA-SSL-CRYPTO-HARDWARE PIC S9(9) BINARY VALUE 2051. 002885C 10 MQCA-SSL-KEY-LIBRARY PIC S9(9) BINARY VALUE 2069. 002886C 10 MQCA-SSL-KEY-MEMBER PIC S9(9) BINARY VALUE 2070. 002887C 10 MQCA-SSL-KEY-REPOSITORY PIC S9(9) BINARY VALUE 2049. 002888C 10 MQCA-SSL-KEY-REPO-PASSWORD PIC S9(9) BINARY VALUE 2055. 002889C 10 MQCA-STDERR-DESTINATION PIC S9(9) BINARY VALUE 2084. 002890C 10 MQCA-STDOUT-DESTINATION PIC S9(9) BINARY VALUE 2083. 002891C 10 MQCA-STORAGE-CLASS PIC S9(9) BINARY VALUE 2022. 002892C 10 MQCA-STORAGE-CLASS-DESC PIC S9(9) BINARY VALUE 2042. 002893C 10 MQCA-STREAM-QUEUE-NAME PIC S9(9) BINARY VALUE 2138. 002894C 10 MQCA-SYSTEM-LOG-Q-NAME PIC S9(9) BINARY VALUE 2065. 002895C 10 MQCA-TCP-NAME PIC S9(9) BINARY VALUE 2075. 002896C 10 MQCA-TOPIC-DESC PIC S9(9) BINARY VALUE 2093. 002897C 10 MQCA-TOPIC-NAME PIC S9(9) BINARY VALUE 2092. 002898C 10 MQCA-TOPIC-STRING PIC S9(9) BINARY VALUE 2094. 002899C 10 MQCA-TOPIC-STRING-FILTER PIC S9(9) BINARY VALUE 2108. 002900C 10 MQCA-TPIPE-NAME PIC S9(9) BINARY VALUE 2085. 002901C 10 MQCA-TRIGGER-CHANNEL-NAME PIC S9(9) BINARY VALUE 2064. 002902C 10 MQCA-TRIGGER-DATA PIC S9(9) BINARY VALUE 2023. 002903C 10 MQCA-TRIGGER-PROGRAM-NAME PIC S9(9) BINARY VALUE 2062. 002904C 10 MQCA-TRIGGER-TERM-ID PIC S9(9) BINARY VALUE 2063. 002905C 10 MQCA-TRIGGER-TRANS-ID PIC S9(9) BINARY VALUE 2061. 002906C 10 MQCA-USER-DATA PIC S9(9) BINARY VALUE 2021. 002907C 10 MQCA-USER-LIST PIC S9(9) BINARY VALUE 4000. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 55 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002908C 10 MQCA-VERSION PIC S9(9) BINARY VALUE 2120. 002909C 10 MQCA-XCF-GROUP-NAME PIC S9(9) BINARY VALUE 2043. 002910C 10 MQCA-XCF-MEMBER-NAME PIC S9(9) BINARY VALUE 2044. 002911C 10 MQCA-XMIT-Q-NAME PIC S9(9) BINARY VALUE 2024. 002912C 10 MQCA-XR-SSL-CIPHER-SUITES PIC S9(9) BINARY VALUE 2123. 002913C 10 MQCA-XR-VERSION PIC S9(9) BINARY VALUE 2122. 002914C 002915C ** Integer Attribute Selectors 002916C 10 MQIA-ACCOUNTING-CONN-OVERRIDE PIC S9(9) BINARY VALUE 136. 002917C 10 MQIA-ACCOUNTING-INTERVAL PIC S9(9) BINARY VALUE 135. 002918C 10 MQIA-ACCOUNTING-MQI PIC S9(9) BINARY VALUE 133. 002919C 10 MQIA-ACCOUNTING-Q PIC S9(9) BINARY VALUE 134. 002920C 10 MQIA-ACTIVE-CHANNELS PIC S9(9) BINARY VALUE 100. 002921C 10 MQIA-ACTIVITY-CONN-OVERRIDE PIC S9(9) BINARY VALUE 239. 002922C 10 MQIA-ACTIVITY-RECORDING PIC S9(9) BINARY VALUE 138. 002923C 10 MQIA-ACTIVITY-TRACE PIC S9(9) BINARY VALUE 240. 002924C 10 MQIA-ADOPTNEWMCA-CHECK PIC S9(9) BINARY VALUE 102. 002925C 10 MQIA-ADOPTNEWMCA-INTERVAL PIC S9(9) BINARY VALUE 104. 002926C 10 MQIA-ADOPTNEWMCA-TYPE PIC S9(9) BINARY VALUE 103. 002927C 10 MQIA-ADOPT-CONTEXT PIC S9(9) BINARY VALUE 260. 002928C 10 MQIA-ADVANCED-CAPABILITY PIC S9(9) BINARY VALUE 273. 002929C 10 MQIA-AMQP-CAPABILITY PIC S9(9) BINARY VALUE 265. 002930C 10 MQIA-APPL-TYPE PIC S9(9) BINARY VALUE 1. 002931C 10 MQIA-ARCHIVE PIC S9(9) BINARY VALUE 60. 002932C 10 MQIA-AUTHENTICATION-FAIL-DELAY PIC S9(9) BINARY VALUE 259. 002933C 10 MQIA-AUTHENTICATION-METHOD PIC S9(9) BINARY VALUE 266. 002934C 10 MQIA-AUTHOREV-SCOPE PIC S9(9) BINARY VALUE 277. 002935C 10 MQIA-AUTHORITY-EVENT PIC S9(9) BINARY VALUE 47. 002936C 10 MQIA-AUTH-INFO-TYPE PIC S9(9) BINARY VALUE 66. 002937C 10 MQIA-AUTO-REORGANIZATION PIC S9(9) BINARY VALUE 173. 002938C 10 MQIA-AUTO-REORG-INTERVAL PIC S9(9) BINARY VALUE 174. 002939C 10 MQIA-BACKOUT-THRESHOLD PIC S9(9) BINARY VALUE 22. 002940C 10 MQIA-BASE-TYPE PIC S9(9) BINARY VALUE 193. 002941C 10 MQIA-BATCH-INTERFACE-AUTO PIC S9(9) BINARY VALUE 86. 002942C 10 MQIA-BRIDGE-EVENT PIC S9(9) BINARY VALUE 74. 002943C 10 MQIA-CAP-EXPIRY PIC S9(9) BINARY VALUE 276. 002944C 10 MQIA-CERT-VAL-POLICY PIC S9(9) BINARY VALUE 252. 002945C 10 MQIA-CF-CFCONLOS PIC S9(9) BINARY VALUE 246. 002946C 10 MQIA-CF-LEVEL PIC S9(9) BINARY VALUE 70. 002947C 10 MQIA-CF-OFFLDUSE PIC S9(9) BINARY VALUE 229. 002948C 10 MQIA-CF-OFFLOAD PIC S9(9) BINARY VALUE 224. 002949C 10 MQIA-CF-OFFLOAD-THRESHOLD1 PIC S9(9) BINARY VALUE 225. 002950C 10 MQIA-CF-OFFLOAD-THRESHOLD2 PIC S9(9) BINARY VALUE 226. 002951C 10 MQIA-CF-OFFLOAD-THRESHOLD3 PIC S9(9) BINARY VALUE 227. 002952C 10 MQIA-CF-RECAUTO PIC S9(9) BINARY VALUE 244. 002953C 10 MQIA-CF-RECOVER PIC S9(9) BINARY VALUE 71. 002954C 10 MQIA-CF-SMDS-BUFFERS PIC S9(9) BINARY VALUE 228. 002955C 10 MQIA-CHANNEL-AUTO-DEF PIC S9(9) BINARY VALUE 55. 002956C 10 MQIA-CHANNEL-AUTO-DEF-EVENT PIC S9(9) BINARY VALUE 56. 002957C 10 MQIA-CHANNEL-EVENT PIC S9(9) BINARY VALUE 73. 002958C 10 MQIA-CHECK-CLIENT-BINDING PIC S9(9) BINARY VALUE 258. 002959C 10 MQIA-CHECK-LOCAL-BINDING PIC S9(9) BINARY VALUE 257. 002960C 10 MQIA-CHINIT-ADAPTERS PIC S9(9) BINARY VALUE 101. 002961C 10 MQIA-CHINIT-CONTROL PIC S9(9) BINARY VALUE 119. 002962C 10 MQIA-CHINIT-DISPATCHERS PIC S9(9) BINARY VALUE 105. 002963C 10 MQIA-CHINIT-TRACE-AUTO-START PIC S9(9) BINARY VALUE 117. 002964C 10 MQIA-CHINIT-TRACE-TABLE-SIZE PIC S9(9) BINARY VALUE 118. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 56 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 002965C 10 MQIA-CHLAUTH-RECORDS PIC S9(9) BINARY VALUE 248. 002966C 10 MQIA-CLUSTER-OBJECT-STATE PIC S9(9) BINARY VALUE 256. 002967C 10 MQIA-CLUSTER-PUB-ROUTE PIC S9(9) BINARY VALUE 255. 002968C 10 MQIA-CLUSTER-Q-TYPE PIC S9(9) BINARY VALUE 59. 002969C 10 MQIA-CLUSTER-WORKLOAD-LENGTH PIC S9(9) BINARY VALUE 58. 002970C 10 MQIA-CLWL-MRU-CHANNELS PIC S9(9) BINARY VALUE 97. 002971C 10 MQIA-CLWL-Q-PRIORITY PIC S9(9) BINARY VALUE 96. 002972C 10 MQIA-CLWL-Q-RANK PIC S9(9) BINARY VALUE 95. 002973C 10 MQIA-CLWL-USEQ PIC S9(9) BINARY VALUE 98. 002974C 10 MQIA-CMD-SERVER-AUTO PIC S9(9) BINARY VALUE 87. 002975C 10 MQIA-CMD-SERVER-CONTROL PIC S9(9) BINARY VALUE 120. 002976C 10 MQIA-CMD-SERVER-CONVERT-MSG PIC S9(9) BINARY VALUE 88. 002977C 10 MQIA-CMD-SERVER-DLQ-MSG PIC S9(9) BINARY VALUE 89. 002978C 10 MQIA-CODED-CHAR-SET-ID PIC S9(9) BINARY VALUE 2. 002979C 10 MQIA-COMMAND-EVENT PIC S9(9) BINARY VALUE 99. 002980C 10 MQIA-COMMAND-LEVEL PIC S9(9) BINARY VALUE 31. 002981C 10 MQIA-COMM-EVENT PIC S9(9) BINARY VALUE 232. 002982C 10 MQIA-COMM-INFO-TYPE PIC S9(9) BINARY VALUE 223. 002983C 10 MQIA-CONFIGURATION-EVENT PIC S9(9) BINARY VALUE 51. 002984C 10 MQIA-CPI-LEVEL PIC S9(9) BINARY VALUE 27. 002985C 10 MQIA-CURRENT-Q-DEPTH PIC S9(9) BINARY VALUE 3. 002986C 10 MQIA-DEFINITION-TYPE PIC S9(9) BINARY VALUE 7. 002987C 10 MQIA-DEF-BIND PIC S9(9) BINARY VALUE 61. 002988C 10 MQIA-DEF-CLUSTER-XMIT-Q-TYPE PIC S9(9) BINARY VALUE 250. 002989C 10 MQIA-DEF-INPUT-OPEN-OPTION PIC S9(9) BINARY VALUE 4. 002990C 10 MQIA-DEF-PERSISTENCE PIC S9(9) BINARY VALUE 5. 002991C 10 MQIA-DEF-PRIORITY PIC S9(9) BINARY VALUE 6. 002992C 10 MQIA-DEF-PUT-RESPONSE-TYPE PIC S9(9) BINARY VALUE 184. 002993C 10 MQIA-DEF-READ-AHEAD PIC S9(9) BINARY VALUE 188. 002994C 10 MQIA-DISPLAY-TYPE PIC S9(9) BINARY VALUE 262. 002995C 10 MQIA-DIST-LISTS PIC S9(9) BINARY VALUE 34. 002996C 10 MQIA-DNS-WLM PIC S9(9) BINARY VALUE 106. 002997C 10 MQIA-DURABLE-SUB PIC S9(9) BINARY VALUE 175. 002998C 10 MQIA-ENCRYPTION-ALGORITHM PIC S9(9) BINARY VALUE 237. 002999C 10 MQIA-EXPIRY-INTERVAL PIC S9(9) BINARY VALUE 39. 003000C 10 MQIA-FIRST PIC S9(9) BINARY VALUE 1. 003001C 10 MQIA-GROUP-UR PIC S9(9) BINARY VALUE 221. 003002C 10 MQIA-HARDEN-GET-BACKOUT PIC S9(9) BINARY VALUE 8. 003003C 10 MQIA-HIGH-Q-DEPTH PIC S9(9) BINARY VALUE 36. 003004C 10 MQIA-IGQ-PUT-AUTHORITY PIC S9(9) BINARY VALUE 65. 003005C 10 MQIA-INDEX-TYPE PIC S9(9) BINARY VALUE 57. 003006C 10 MQIA-INHIBIT-EVENT PIC S9(9) BINARY VALUE 48. 003007C 10 MQIA-INHIBIT-GET PIC S9(9) BINARY VALUE 9. 003008C 10 MQIA-INHIBIT-PUB PIC S9(9) BINARY VALUE 181. 003009C 10 MQIA-INHIBIT-PUT PIC S9(9) BINARY VALUE 10. 003010C 10 MQIA-INHIBIT-SUB PIC S9(9) BINARY VALUE 182. 003011C 10 MQIA-INTRA-GROUP-QUEUING PIC S9(9) BINARY VALUE 64. 003012C 10 MQIA-INT-ACTION PIC S9(9) BINARY VALUE 10000. 003013C 10 MQIA-INT-ADS-DESCRIPTOR PIC S9(9) BINARY VALUE 10004. 003014C 10 MQIA-INT-ALL-ATTRS PIC S9(9) BINARY VALUE 10089. 003015C 10 MQIA-INT-ALL-BYTE-ATTRS PIC S9(9) BINARY VALUE 10093. 003016C 10 MQIA-INT-ALL-CHAR-ATTRS PIC S9(9) BINARY VALUE 10082. 003017C 10 MQIA-INT-ALL-COMMANDS PIC S9(9) BINARY VALUE 10088. 003018C 10 MQIA-INT-ALL-GET-OPTIONS PIC S9(9) BINARY VALUE 10090. 003019C 10 MQIA-INT-ALL-GROUP-ATTRS PIC S9(9) BINARY VALUE 10094. 003020C 10 MQIA-INT-ALL-INT-ATTRS PIC S9(9) BINARY VALUE 10081. 003021C 10 MQIA-INT-ALL-SEL-ATTRS PIC S9(9) BINARY VALUE 10095. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 57 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003022C 10 MQIA-INT-ATTR-VALUES PIC S9(9) BINARY VALUE 10034. 003023C 10 MQIA-INT-AUTHENTICATION-TYPE PIC S9(9) BINARY VALUE 10017. 003024C 10 MQIA-INT-AUTHENTICATION-TYPES PIC S9(9) BINARY VALUE 10070. 003025C 10 MQIA-INT-AUTHORIZATIONS PIC S9(9) BINARY VALUE 10069. 003026C 10 MQIA-INT-BAG-HANDLES PIC S9(9) BINARY VALUE 10030. 003027C 10 MQIA-INT-BEGIN-OPTIONS PIC S9(9) BINARY VALUE 10003. 003028C 10 MQIA-INT-BUFFER-LENGTH PIC S9(9) BINARY VALUE 10001. 003029C 10 MQIA-INT-BUFMH-OPTIONS PIC S9(9) BINARY VALUE 10002. 003030C 10 MQIA-INT-CAPABILITY-FLAGS PIC S9(9) BINARY VALUE 10009. 003031C 10 MQIA-INT-CB-FLAGS PIC S9(9) BINARY VALUE 10005. 003032C 10 MQIA-INT-CB-MAX-MSG-LENGTH PIC S9(9) BINARY VALUE 10006. 003033C 10 MQIA-INT-CB-STATE PIC S9(9) BINARY VALUE 10018. 003034C 10 MQIA-INT-CFH-CONTROL PIC S9(9) BINARY VALUE 10103. 003035C 10 MQIA-INT-CFH-TYPE PIC S9(9) BINARY VALUE 10102. 003036C 10 MQIA-INT-CICS-RETURN-CODE PIC S9(9) BINARY VALUE 10016. 003037C 10 MQIA-INT-CIH-FLAGS PIC S9(9) BINARY VALUE 10011. 003038C 10 MQIA-INT-CLUS-CHAR-ATTRS PIC S9(9) BINARY VALUE 10084. 003039C 10 MQIA-INT-CLUS-COMMANDS PIC S9(9) BINARY VALUE 10085. 003040C 10 MQIA-INT-CLUS-INT-ATTRS PIC S9(9) BINARY VALUE 10083. 003041C 10 MQIA-INT-CLUS-QUERY PIC S9(9) BINARY VALUE 10087. 003042C 10 MQIA-INT-CLUS-QUERY-REFRESH PIC S9(9) BINARY VALUE 10086. 003043C 10 MQIA-INT-COMMIT-MODES PIC S9(9) BINARY VALUE 10100. 003044C 10 MQIA-INT-CONN-HANDLES PIC S9(9) BINARY VALUE 10031. 003045C 10 MQIA-INT-CONTINUATION-INDIC PIC S9(9) BINARY VALUE 10071. 003046C 10 MQIA-INT-CONVERSATIONAL-TASK PIC S9(9) BINARY VALUE 10007. 003047C 10 MQIA-INT-COPY-OPTIONS PIC S9(9) BINARY VALUE 10015. 003048C 10 MQIA-INT-CRTMH-OPTIONS PIC S9(9) BINARY VALUE 10013. 003049C 10 MQIA-INT-CTL-OPTIONS PIC S9(9) BINARY VALUE 10020. 003050C 10 MQIA-INT-DELETE-OPTIONS PIC S9(9) BINARY VALUE 10023. 003051C 10 MQIA-INT-DH-FLAGS PIC S9(9) BINARY VALUE 10024. 003052C 10 MQIA-INT-DLTMH-OPTIONS PIC S9(9) BINARY VALUE 10025. 003053C 10 MQIA-INT-DLTMP-OPTIONS PIC S9(9) BINARY VALUE 10026. 003054C 10 MQIA-INT-DXP-EXIT-RESPONSE PIC S9(9) BINARY VALUE 10064. 003055C 10 MQIA-INT-EPH-FLAGS PIC S9(9) BINARY VALUE 10028. 003056C 10 MQIA-INT-ERRNO PIC S9(9) BINARY VALUE 10092. 003057C 10 MQIA-INT-EXIT-COMMANDS PIC S9(9) BINARY VALUE 10063. 003058C 10 MQIA-INT-EXIT-IDENTIFIERS PIC S9(9) BINARY VALUE 10068. 003059C 10 MQIA-INT-EXIT-OPTIONS PIC S9(9) BINARY VALUE 10065. 003060C 10 MQIA-INT-EXIT-REASONS PIC S9(9) BINARY VALUE 10067. 003061C 10 MQIA-INT-EXIT-RESPONSES PIC S9(9) BINARY VALUE 10062. 003062C 10 MQIA-INT-EXIT-RESPONSE-2 PIC S9(9) BINARY VALUE 10066. 003063C 10 MQIA-INT-EXPORT-OPTIONS PIC S9(9) BINARY VALUE 10029. 003064C 10 MQIA-INT-FILTER-OPERATORS PIC S9(9) BINARY VALUE 10008. 003065C 10 MQIA-INT-GET-WAIT-INTERVAL PIC S9(9) BINARY VALUE 10010. 003066C 10 MQIA-INT-GROUP-STATUS PIC S9(9) BINARY VALUE 10096. 003067C 10 MQIA-INT-IEP-FLAGS PIC S9(9) BINARY VALUE 10035. 003068C 10 MQIA-INT-IIH-FLAGS PIC S9(9) BINARY VALUE 10036. 003069C 10 MQIA-INT-INIT-OPTIONS PIC S9(9) BINARY VALUE 10072. 003070C 10 MQIA-INT-INQMP-OPTIONS PIC S9(9) BINARY VALUE 10037. 003071C 10 MQIA-INT-ITEM-INDEX PIC S9(9) BINARY VALUE 10038. 003072C 10 MQIA-INT-LINK-TYPE PIC S9(9) BINARY VALUE 10012. 003073C 10 MQIA-INT-MATCH-OPTIONS PIC S9(9) BINARY VALUE 10042. 003074C 10 MQIA-INT-MC-EVENT-CODE PIC S9(9) BINARY VALUE 10039. 003075C 10 MQIA-INT-MDE-FLAGS PIC S9(9) BINARY VALUE 10040. 003076C 10 MQIA-INT-MHBUF-OPTIONS PIC S9(9) BINARY VALUE 10041. 003077C 10 MQIA-INT-MP-TYPES PIC S9(9) BINARY VALUE 10056. 003078C 10 MQIA-INT-MSG-HANDLES PIC S9(9) BINARY VALUE 10032. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 58 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003079C 10 MQIA-INT-NAME-COUNT PIC S9(9) BINARY VALUE 10043. 003080C 10 MQIA-INT-OBJECT-HANDLES PIC S9(9) BINARY VALUE 10033. 003081C 10 MQIA-INT-OUTPUT-DATA-LENGTH PIC S9(9) BINARY VALUE 10014. 003082C 10 MQIA-INT-PD-SUPPORT PIC S9(9) BINARY VALUE 10044. 003083C 10 MQIA-INT-PUBLICATION-OPTIONS PIC S9(9) BINARY VALUE 10046. 003084C 10 MQIA-INT-PUT-MSG-REC-FIELDS PIC S9(9) BINARY VALUE 10045. 003085C 10 MQIA-INT-QUIESCE PIC S9(9) BINARY VALUE 10049. 003086C 10 MQIA-INT-RECONNECT-DELAY PIC S9(9) BINARY VALUE 10050. 003087C 10 MQIA-INT-REGISTRATION-OPTIONS PIC S9(9) BINARY VALUE 10051. 003088C 10 MQIA-INT-RETURNED-LENGTH PIC S9(9) BINARY VALUE 10053. 003089C 10 MQIA-INT-RFH-FLAGS PIC S9(9) BINARY VALUE 10052. 003090C 10 MQIA-INT-RMH-FLAGS PIC S9(9) BINARY VALUE 10091. 003091C 10 MQIA-INT-SECURITY-SCOPES PIC S9(9) BINARY VALUE 10101. 003092C 10 MQIA-INT-SEGMENTATION PIC S9(9) BINARY VALUE 10098. 003093C 10 MQIA-INT-SEGMENT-STATUS PIC S9(9) BINARY VALUE 10097. 003094C 10 MQIA-INT-SELECTOR-INDIC PIC S9(9) BINARY VALUE 10074. 003095C 10 MQIA-INT-SETMP-OPTIONS PIC S9(9) BINARY VALUE 10054. 003096C 10 MQIA-INT-SIGNAL1 PIC S9(9) BINARY VALUE 10027. 003097C 10 MQIA-INT-SMDS-USAGE PIC S9(9) BINARY VALUE 10057. 003098C 10 MQIA-INT-START-ENUM-INDIC PIC S9(9) BINARY VALUE 10073. 003099C 10 MQIA-INT-SYSTEM-OBJECTS PIC S9(9) BINARY VALUE 10055. 003100C 10 MQIA-INT-TASK-END-STATUS PIC S9(9) BINARY VALUE 10019. 003101C 10 MQIA-INT-TERM-OPTIONS PIC S9(9) BINARY VALUE 10075. 003102C 10 MQIA-INT-TRANSACTION-STATES PIC S9(9) BINARY VALUE 10099. 003103C 10 MQIA-INT-TT-KEEP-ALIVE PIC S9(9) BINARY VALUE 10076. 003104C 10 MQIA-INT-UNIX-SIGNAL PIC S9(9) BINARY VALUE 10104. 003105C 10 MQIA-INT-UOW-CONTROL PIC S9(9) BINARY VALUE 10021. 003106C 10 MQIA-INT-VALUE-LENGTH PIC S9(9) BINARY VALUE 10058. 003107C 10 MQIA-INT-VS-LENGTH PIC S9(9) BINARY VALUE 10059. 003108C 10 MQIA-INT-WDR-Q-MGR-FLAGS PIC S9(9) BINARY VALUE 10048. 003109C 10 MQIA-INT-WIH-FLAGS PIC S9(9) BINARY VALUE 10060. 003110C 10 MQIA-INT-WQR-Q-FLAGS PIC S9(9) BINARY VALUE 10047. 003111C 10 MQIA-INT-WXP-FLAGS PIC S9(9) BINARY VALUE 10061. 003112C 10 MQIA-INT-XCNVC-OPTIONS PIC S9(9) BINARY VALUE 10022. 003113C 10 MQIA-INT-ZID-AUTHORITY PIC S9(9) BINARY VALUE 10078. 003114C 10 MQIA-INT-ZID-COMMON PIC S9(9) BINARY VALUE 10077. 003115C 10 MQIA-INT-ZID-NAME PIC S9(9) BINARY VALUE 10079. 003116C 10 MQIA-INT-ZID-USERID PIC S9(9) BINARY VALUE 10080. 003117C 10 MQIA-IP-ADDRESS-VERSION PIC S9(9) BINARY VALUE 93. 003118C 10 MQIA-KEY-REUSE-COUNT PIC S9(9) BINARY VALUE 267. 003119C 10 MQIA-LAST PIC S9(9) BINARY VALUE 2000. 003120C 10 MQIA-LAST-USED PIC S9(9) BINARY VALUE 279. 003121C 10 MQIA-LDAP-AUTHORMD PIC S9(9) BINARY VALUE 263. 003122C 10 MQIA-LDAP-NESTGRP PIC S9(9) BINARY VALUE 264. 003123C 10 MQIA-LDAP-SECURE-COMM PIC S9(9) BINARY VALUE 261. 003124C 10 MQIA-LISTENER-PORT-NUMBER PIC S9(9) BINARY VALUE 85. 003125C 10 MQIA-LISTENER-TIMER PIC S9(9) BINARY VALUE 107. 003126C 10 MQIA-LOCAL-EVENT PIC S9(9) BINARY VALUE 49. 003127C 10 MQIA-LOGGER-EVENT PIC S9(9) BINARY VALUE 94. 003128C 10 MQIA-LU62-CHANNELS PIC S9(9) BINARY VALUE 108. 003129C 10 MQIA-MASTER-ADMIN PIC S9(9) BINARY VALUE 186. 003130C 10 MQIA-MAX-CHANNELS PIC S9(9) BINARY VALUE 109. 003131C 10 MQIA-MAX-CLIENTS PIC S9(9) BINARY VALUE 172. 003132C 10 MQIA-MAX-GLOBAL-LOCKS PIC S9(9) BINARY VALUE 83. 003133C 10 MQIA-MAX-HANDLES PIC S9(9) BINARY VALUE 11. 003134C 10 MQIA-MAX-LOCAL-LOCKS PIC S9(9) BINARY VALUE 84. 003135C 10 MQIA-MAX-MSG-LENGTH PIC S9(9) BINARY VALUE 13. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 59 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003136C 10 MQIA-MAX-OPEN-Q PIC S9(9) BINARY VALUE 80. 003137C 10 MQIA-MAX-PRIORITY PIC S9(9) BINARY VALUE 14. 003138C 10 MQIA-MAX-PROPERTIES-LENGTH PIC S9(9) BINARY VALUE 192. 003139C 10 MQIA-MAX-Q-DEPTH PIC S9(9) BINARY VALUE 15. 003140C 10 MQIA-MAX-Q-FILE-SIZE PIC S9(9) BINARY VALUE 274. 003141C 10 MQIA-MAX-Q-TRIGGERS PIC S9(9) BINARY VALUE 90. 003142C 10 MQIA-MAX-RECOVERY-TASKS PIC S9(9) BINARY VALUE 171. 003143C 10 MQIA-MAX-RESPONSES PIC S9(9) BINARY VALUE 230. 003144C 10 MQIA-MAX-UNCOMMITTED-MSGS PIC S9(9) BINARY VALUE 33. 003145C 10 MQIA-MCAST-BRIDGE PIC S9(9) BINARY VALUE 233. 003146C 10 MQIA-MEDIA-IMAGE-INTERVAL PIC S9(9) BINARY VALUE 269. 003147C 10 MQIA-MEDIA-IMAGE-LOG-LENGTH PIC S9(9) BINARY VALUE 270. 003148C 10 MQIA-MEDIA-IMAGE-RECOVER-OBJ PIC S9(9) BINARY VALUE 271. 003149C 10 MQIA-MEDIA-IMAGE-RECOVER-Q PIC S9(9) BINARY VALUE 272. 003150C 10 MQIA-MEDIA-IMAGE-SCHEDULING PIC S9(9) BINARY VALUE 268. 003151C 10 MQIA-MONITORING-AUTO-CLUSSDR PIC S9(9) BINARY VALUE 124. 003152C 10 MQIA-MONITORING-CHANNEL PIC S9(9) BINARY VALUE 122. 003153C 10 MQIA-MONITORING-Q PIC S9(9) BINARY VALUE 123. 003154C 10 MQIA-MONITOR-INTERVAL PIC S9(9) BINARY VALUE 81. 003155C 10 MQIA-MSG-DELIVERY-SEQUENCE PIC S9(9) BINARY VALUE 16. 003156C 10 MQIA-MSG-DEQ-COUNT PIC S9(9) BINARY VALUE 38. 003157C 10 MQIA-MSG-ENQ-COUNT PIC S9(9) BINARY VALUE 37. 003158C 10 MQIA-MSG-MARK-BROWSE-INTERVAL PIC S9(9) BINARY VALUE 68. 003159C 10 MQIA-MULTICAST PIC S9(9) BINARY VALUE 176. 003160C 10 MQIA-NAMELIST-TYPE PIC S9(9) BINARY VALUE 72. 003161C 10 MQIA-NAME-COUNT PIC S9(9) BINARY VALUE 19. 003162C 10 MQIA-NPM-CLASS PIC S9(9) BINARY VALUE 78. 003163C 10 MQIA-NPM-DELIVERY PIC S9(9) BINARY VALUE 196. 003164C 10 MQIA-OPEN-INPUT-COUNT PIC S9(9) BINARY VALUE 17. 003165C 10 MQIA-OPEN-OUTPUT-COUNT PIC S9(9) BINARY VALUE 18. 003166C 10 MQIA-OTEL-PROPAGATION-CONTROL PIC S9(9) BINARY VALUE 279. 003167C 10 MQIA-OTEL-TRACE PIC S9(9) BINARY VALUE 278. 003168C 10 MQIA-OUTBOUND-PORT-MAX PIC S9(9) BINARY VALUE 140. 003169C 10 MQIA-OUTBOUND-PORT-MIN PIC S9(9) BINARY VALUE 110. 003170C 10 MQIA-PAGESET-ID PIC S9(9) BINARY VALUE 62. 003171C 10 MQIA-PERFORMANCE-EVENT PIC S9(9) BINARY VALUE 53. 003172C 10 MQIA-PLATFORM PIC S9(9) BINARY VALUE 32. 003173C 10 MQIA-PM-DELIVERY PIC S9(9) BINARY VALUE 195. 003174C 10 MQIA-POLICY-VERSION PIC S9(9) BINARY VALUE 238. 003175C 10 MQIA-PROPERTY-CONTROL PIC S9(9) BINARY VALUE 190. 003176C 10 MQIA-PROT-POLICY-CAPABILITY PIC S9(9) BINARY VALUE 251. 003177C 10 MQIA-PROXY-SUB PIC S9(9) BINARY VALUE 199. 003178C 10 MQIA-PUBSUB-CLUSTER PIC S9(9) BINARY VALUE 249. 003179C 10 MQIA-PUBSUB-MAXMSG-RETRY-COUNT PIC S9(9) BINARY VALUE 206. 003180C 10 MQIA-PUBSUB-MODE PIC S9(9) BINARY VALUE 187. 003181C 10 MQIA-PUBSUB-NP-MSG PIC S9(9) BINARY VALUE 203. 003182C 10 MQIA-PUBSUB-NP-RESP PIC S9(9) BINARY VALUE 205. 003183C 10 MQIA-PUBSUB-SYNC-PT PIC S9(9) BINARY VALUE 207. 003184C 10 MQIA-PUB-COUNT PIC S9(9) BINARY VALUE 215. 003185C 10 MQIA-PUB-SCOPE PIC S9(9) BINARY VALUE 219. 003186C 10 MQIA-QMGR-CFCONLOS PIC S9(9) BINARY VALUE 245. 003187C 10 MQIA-QMOPT-CONS-COMMS-MSGS PIC S9(9) BINARY VALUE 155. 003188C 10 MQIA-QMOPT-CONS-CRITICAL-MSGS PIC S9(9) BINARY VALUE 154. 003189C 10 MQIA-QMOPT-CONS-ERROR-MSGS PIC S9(9) BINARY VALUE 153. 003190C 10 MQIA-QMOPT-CONS-INFO-MSGS PIC S9(9) BINARY VALUE 151. 003191C 10 MQIA-QMOPT-CONS-REORG-MSGS PIC S9(9) BINARY VALUE 156. 003192C 10 MQIA-QMOPT-CONS-SYSTEM-MSGS PIC S9(9) BINARY VALUE 157. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 60 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003193C 10 MQIA-QMOPT-CONS-WARNING-MSGS PIC S9(9) BINARY VALUE 152. 003194C 10 MQIA-QMOPT-CSMT-ON-ERROR PIC S9(9) BINARY VALUE 150. 003195C 10 MQIA-QMOPT-INTERNAL-DUMP PIC S9(9) BINARY VALUE 170. 003196C 10 MQIA-QMOPT-LOG-COMMS-MSGS PIC S9(9) BINARY VALUE 162. 003197C 10 MQIA-QMOPT-LOG-CRITICAL-MSGS PIC S9(9) BINARY VALUE 161. 003198C 10 MQIA-QMOPT-LOG-ERROR-MSGS PIC S9(9) BINARY VALUE 160. 003199C 10 MQIA-QMOPT-LOG-INFO-MSGS PIC S9(9) BINARY VALUE 158. 003200C 10 MQIA-QMOPT-LOG-REORG-MSGS PIC S9(9) BINARY VALUE 163. 003201C 10 MQIA-QMOPT-LOG-SYSTEM-MSGS PIC S9(9) BINARY VALUE 164. 003202C 10 MQIA-QMOPT-LOG-WARNING-MSGS PIC S9(9) BINARY VALUE 159. 003203C 10 MQIA-QMOPT-TRACE-COMMS PIC S9(9) BINARY VALUE 166. 003204C 10 MQIA-QMOPT-TRACE-CONVERSION PIC S9(9) BINARY VALUE 168. 003205C 10 MQIA-QMOPT-TRACE-MQI-CALLS PIC S9(9) BINARY VALUE 165. 003206C 10 MQIA-QMOPT-TRACE-REORG PIC S9(9) BINARY VALUE 167. 003207C 10 MQIA-QMOPT-TRACE-SYSTEM PIC S9(9) BINARY VALUE 169. 003208C 10 MQIA-QSG-DISP PIC S9(9) BINARY VALUE 63. 003209C 10 MQIA-Q-DEPTH-HIGH-EVENT PIC S9(9) BINARY VALUE 43. 003210C 10 MQIA-Q-DEPTH-HIGH-LIMIT PIC S9(9) BINARY VALUE 40. 003211C 10 MQIA-Q-DEPTH-LOW-EVENT PIC S9(9) BINARY VALUE 44. 003212C 10 MQIA-Q-DEPTH-LOW-LIMIT PIC S9(9) BINARY VALUE 41. 003213C 10 MQIA-Q-DEPTH-MAX-EVENT PIC S9(9) BINARY VALUE 42. 003214C 10 MQIA-Q-SERVICE-INTERVAL PIC S9(9) BINARY VALUE 54. 003215C 10 MQIA-Q-SERVICE-INTERVAL-EVENT PIC S9(9) BINARY VALUE 46. 003216C 10 MQIA-Q-TYPE PIC S9(9) BINARY VALUE 20. 003217C 10 MQIA-Q-USERS PIC S9(9) BINARY VALUE 82. 003218C 10 MQIA-READ-AHEAD PIC S9(9) BINARY VALUE 189. 003219C 10 MQIA-RECEIVE-TIMEOUT PIC S9(9) BINARY VALUE 111. 003220C 10 MQIA-RECEIVE-TIMEOUT-MIN PIC S9(9) BINARY VALUE 113. 003221C 10 MQIA-RECEIVE-TIMEOUT-TYPE PIC S9(9) BINARY VALUE 112. 003222C 10 MQIA-REMOTE-EVENT PIC S9(9) BINARY VALUE 50. 003223C 10 MQIA-RESPONSE-RESTART-POINT PIC S9(9) BINARY VALUE 231. 003224C 10 MQIA-RETENTION-INTERVAL PIC S9(9) BINARY VALUE 21. 003225C 10 MQIA-REVERSE-DNS-LOOKUP PIC S9(9) BINARY VALUE 254. 003226C 10 MQIA-SCOPE PIC S9(9) BINARY VALUE 45. 003227C 10 MQIA-SECURITY-CASE PIC S9(9) BINARY VALUE 141. 003228C 10 MQIA-SERVICE-CONTROL PIC S9(9) BINARY VALUE 139. 003229C 10 MQIA-SERVICE-TYPE PIC S9(9) BINARY VALUE 121. 003230C 10 MQIA-SHAREABILITY PIC S9(9) BINARY VALUE 23. 003231C 10 MQIA-SHARED-Q-Q-MGR-NAME PIC S9(9) BINARY VALUE 77. 003232C 10 MQIA-SIGNATURE-ALGORITHM PIC S9(9) BINARY VALUE 236. 003233C 10 MQIA-SSL-EVENT PIC S9(9) BINARY VALUE 75. 003234C 10 MQIA-SSL-FIPS-REQUIRED PIC S9(9) BINARY VALUE 92. 003235C 10 MQIA-SSL-RESET-COUNT PIC S9(9) BINARY VALUE 76. 003236C 10 MQIA-SSL-TASKS PIC S9(9) BINARY VALUE 69. 003237C 10 MQIA-START-STOP-EVENT PIC S9(9) BINARY VALUE 52. 003238C 10 MQIA-STATISTICS-AUTO-CLUSSDR PIC S9(9) BINARY VALUE 130. 003239C 10 MQIA-STATISTICS-CHANNEL PIC S9(9) BINARY VALUE 129. 003240C 10 MQIA-STATISTICS-INTERVAL PIC S9(9) BINARY VALUE 131. 003241C 10 MQIA-STATISTICS-MQI PIC S9(9) BINARY VALUE 127. 003242C 10 MQIA-STATISTICS-Q PIC S9(9) BINARY VALUE 128. 003243C 10 MQIA-STREAM-QUEUE-QOS PIC S9(9) BINARY VALUE 275. 003244C 10 MQIA-SUB-CONFIGURATION-EVENT PIC S9(9) BINARY VALUE 242. 003245C 10 MQIA-SUB-COUNT PIC S9(9) BINARY VALUE 204. 003246C 10 MQIA-SUB-SCOPE PIC S9(9) BINARY VALUE 218. 003247C 10 MQIA-SUITE-B-STRENGTH PIC S9(9) BINARY VALUE 247. 003248C 10 MQIA-SYNCPOINT PIC S9(9) BINARY VALUE 30. 003249C 10 MQIA-TCP-CHANNELS PIC S9(9) BINARY VALUE 114. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 61 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003250C 10 MQIA-TCP-KEEP-ALIVE PIC S9(9) BINARY VALUE 115. 003251C 10 MQIA-TCP-STACK-TYPE PIC S9(9) BINARY VALUE 116. 003252C 10 MQIA-TIME-SINCE-RESET PIC S9(9) BINARY VALUE 35. 003253C 10 MQIA-TOLERATE-UNPROTECTED PIC S9(9) BINARY VALUE 235. 003254C 10 MQIA-TOPIC-DEF-PERSISTENCE PIC S9(9) BINARY VALUE 185. 003255C 10 MQIA-TOPIC-NODE-COUNT PIC S9(9) BINARY VALUE 253. 003256C 10 MQIA-TOPIC-TYPE PIC S9(9) BINARY VALUE 208. 003257C 10 MQIA-TRACE-ROUTE-RECORDING PIC S9(9) BINARY VALUE 137. 003258C 10 MQIA-TREE-LIFE-TIME PIC S9(9) BINARY VALUE 183. 003259C 10 MQIA-TRIGGER-CONTROL PIC S9(9) BINARY VALUE 24. 003260C 10 MQIA-TRIGGER-DEPTH PIC S9(9) BINARY VALUE 29. 003261C 10 MQIA-TRIGGER-INTERVAL PIC S9(9) BINARY VALUE 25. 003262C 10 MQIA-TRIGGER-MSG-PRIORITY PIC S9(9) BINARY VALUE 26. 003263C 10 MQIA-TRIGGER-RESTART PIC S9(9) BINARY VALUE 91. 003264C 10 MQIA-TRIGGER-TYPE PIC S9(9) BINARY VALUE 28. 003265C 10 MQIA-UR-DISP PIC S9(9) BINARY VALUE 222. 003266C 10 MQIA-USAGE PIC S9(9) BINARY VALUE 12. 003267C 10 MQIA-USER-LIST PIC S9(9) BINARY VALUE 2000. 003268C 10 MQIA-USE-DEAD-LETTER-Q PIC S9(9) BINARY VALUE 234. 003269C 10 MQIA-WILDCARD-OPERATION PIC S9(9) BINARY VALUE 216. 003270C 10 MQIA-XR-CAPABILITY PIC S9(9) BINARY VALUE 243. 003271C 003272C ** Integer Attribute Values 003273C 10 MQIAV-NOT-APPLICABLE PIC S9(9) BINARY VALUE -1. 003274C 10 MQIAV-UNDEFINED PIC S9(9) BINARY VALUE -2. 003275C 003276C ** CommInfo Bridge 003277C 10 MQMCB-DISABLED PIC S9(9) BINARY VALUE 0. 003278C 10 MQMCB-ENABLED PIC S9(9) BINARY VALUE 1. 003279C 003280C ** Key reuse count 003281C 10 MQKEY-REUSE-DISABLED PIC S9(9) BINARY VALUE 0. 003282C 10 MQKEY-REUSE-UNLIMITED PIC S9(9) BINARY VALUE -1. 003283C 003284C ** Group Attribute Selectors 003285C 10 MQGA-FIRST PIC S9(9) BINARY VALUE 8001. 003286C 10 MQGA-LAST PIC S9(9) BINARY VALUE 9000. 003287C 003288C ****************************************************************** 003289C ** Values Related to MQOPEN Function 003290C ****************************************************************** 003291C ** Open Options 003292C 10 MQOO-BIND-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003293C 10 MQOO-READ-AHEAD-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003294C 10 MQOO-INPUT-AS-Q-DEF PIC S9(9) BINARY VALUE 1. 003295C 10 MQOO-INPUT-SHARED PIC S9(9) BINARY VALUE 2. 003296C 10 MQOO-INPUT-EXCLUSIVE PIC S9(9) BINARY VALUE 4. 003297C 10 MQOO-BROWSE PIC S9(9) BINARY VALUE 8. 003298C 10 MQOO-OUTPUT PIC S9(9) BINARY VALUE 16. 003299C 10 MQOO-INQUIRE PIC S9(9) BINARY VALUE 32. 003300C 10 MQOO-SET PIC S9(9) BINARY VALUE 64. 003301C 10 MQOO-SAVE-ALL-CONTEXT PIC S9(9) BINARY VALUE 128. 003302C 10 MQOO-PASS-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 256. 003303C 10 MQOO-PASS-ALL-CONTEXT PIC S9(9) BINARY VALUE 512. 003304C 10 MQOO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 1024. 003305C 10 MQOO-SET-ALL-CONTEXT PIC S9(9) BINARY VALUE 2048. 003306C 10 MQOO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY VALUE 4096. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 62 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003307C 10 MQOO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 003308C 10 MQOO-BIND-ON-OPEN PIC S9(9) BINARY VALUE 16384. 003309C 10 MQOO-BIND-ON-GROUP PIC S9(9) BINARY VALUE 4194304. 003310C 10 MQOO-BIND-NOT-FIXED PIC S9(9) BINARY VALUE 32768. 003311C 10 MQOO-CO-OP PIC S9(9) BINARY VALUE 131072. 003312C 10 MQOO-NO-READ-AHEAD PIC S9(9) BINARY VALUE 524288. 003313C 10 MQOO-READ-AHEAD PIC S9(9) BINARY VALUE 1048576. 003314C 10 MQOO-NO-MULTICAST PIC S9(9) BINARY VALUE 2097152. 003315C 10 MQOO-RESOLVE-LOCAL-Q PIC S9(9) BINARY VALUE 262144. 003316C 10 MQOO-RESOLVE-LOCAL-TOPIC PIC S9(9) BINARY VALUE 262144. 003317C 003318C ** Following used in C++ only 003319C 10 MQOO-RESOLVE-NAMES PIC S9(9) BINARY VALUE 65536. 003320C 003321C ****************************************************************** 003322C ** Values Related to MQSETMP Function 003323C ****************************************************************** 003324C ** Property data types 003325C 10 MQTYPE-AS-SET PIC S9(9) BINARY VALUE 0. 003326C 10 MQTYPE-NULL PIC S9(9) BINARY VALUE 2. 003327C 10 MQTYPE-BOOLEAN PIC S9(9) BINARY VALUE 4. 003328C 10 MQTYPE-BYTE-STRING PIC S9(9) BINARY VALUE 8. 003329C 10 MQTYPE-INT8 PIC S9(9) BINARY VALUE 16. 003330C 10 MQTYPE-INT16 PIC S9(9) BINARY VALUE 32. 003331C 10 MQTYPE-INT32 PIC S9(9) BINARY VALUE 64. 003332C 10 MQTYPE-LONG PIC S9(9) BINARY VALUE 64. 003333C 10 MQTYPE-INT64 PIC S9(9) BINARY VALUE 128. 003334C 10 MQTYPE-FLOAT32 PIC S9(9) BINARY VALUE 256. 003335C 10 MQTYPE-FLOAT64 PIC S9(9) BINARY VALUE 512. 003336C 10 MQTYPE-STRING PIC S9(9) BINARY VALUE 1024. 003337C 003338C ** Property value lengths 003339C 10 MQVL-NULL-TERMINATED PIC S9(9) BINARY VALUE -1. 003340C 10 MQVL-EMPTY-STRING PIC S9(9) BINARY VALUE 0. 003341C 003342C ****************************************************************** 003343C ** Values Related to MQSTAT Function 003344C ****************************************************************** 003345C ** Stat Options 003346C 10 MQSTAT-TYPE-ASYNC-ERROR PIC S9(9) BINARY VALUE 0. 003347C 10 MQSTAT-TYPE-RECONNECTION PIC S9(9) BINARY VALUE 1. 003348C 10 MQSTAT-TYPE-RECONNECTION-ERROR PIC S9(9) BINARY VALUE 2. 003349C 003350C ****************************************************************** 003351C ** Values Related to MQSUB Function 003352C ****************************************************************** 003353C ** Subscribe Options 003354C 10 MQSO-NONE PIC S9(9) BINARY VALUE 0. 003355C 10 MQSO-NON-DURABLE PIC S9(9) BINARY VALUE 0. 003356C 10 MQSO-READ-AHEAD-AS-Q-DEF PIC S9(9) BINARY VALUE 0. 003357C 10 MQSO-ALTER PIC S9(9) BINARY VALUE 1. 003358C 10 MQSO-CREATE PIC S9(9) BINARY VALUE 2. 003359C 10 MQSO-RESUME PIC S9(9) BINARY VALUE 4. 003360C 10 MQSO-DURABLE PIC S9(9) BINARY VALUE 8. 003361C 10 MQSO-GROUP-SUB PIC S9(9) BINARY VALUE 16. 003362C 10 MQSO-MANAGED PIC S9(9) BINARY VALUE 32. 003363C 10 MQSO-SET-IDENTITY-CONTEXT PIC S9(9) BINARY VALUE 64. 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 63 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003364C 10 MQSO-NO-MULTICAST PIC S9(9) BINARY VALUE 128. 003365C 10 MQSO-FIXED-USERID PIC S9(9) BINARY VALUE 256. 003366C 10 MQSO-ANY-USERID PIC S9(9) BINARY VALUE 512. 003367C 10 MQSO-PUBLICATIONS-ON-REQUEST PIC S9(9) BINARY VALUE 2048. 003368C 10 MQSO-NEW-PUBLICATIONS-ONLY PIC S9(9) BINARY VALUE 4096. 003369C 10 MQSO-FAIL-IF-QUIESCING PIC S9(9) BINARY VALUE 8192. 003370C 10 MQSO-ALTERNATE-USER-AUTHORITY PIC S9(9) BINARY 003371C VALUE 262144. 003372C 10 MQSO-WILDCARD-CHAR PIC S9(9) BINARY VALUE 1048576. 003373C 10 MQSO-WILDCARD-TOPIC PIC S9(9) BINARY VALUE 2097152. 003374C 10 MQSO-SET-CORREL-ID PIC S9(9) BINARY VALUE 4194304. 003375C 10 MQSO-SCOPE-QMGR PIC S9(9) BINARY VALUE 67108864. 003376C 10 MQSO-NO-READ-AHEAD PIC S9(9) BINARY VALUE 134217728. 003377C 10 MQSO-READ-AHEAD PIC S9(9) BINARY VALUE 268435456. 003378C 003379C ****************************************************************** 003380C ** Values Related to MQSUBRQ Function 003381C ****************************************************************** 003382C ** Action 003383C 10 MQSR-ACTION-PUBLICATION PIC S9(9) BINARY VALUE 1. 003384C 003385C ** 003386C 003387C ****************************************************************** 003388C ** Constants for MQ Extended Reach 003389C ****************************************************************** 003390C ** General Constants 003391C 10 MQ-MQTT-MAX-KEEP-ALIVE PIC S9(9) BINARY VALUE 65536. 003392C 10 MQ-SSL-KEY-PASSPHRASE-LENGTH PIC S9(9) BINARY VALUE 1024. 003393C 003394C 003395C 003396C ****************************************************************** 003397C ** End of CMQV ** 003398C ****************************************************************** 003399 003400 01 MQM-OBJECT-DESCRIPTOR. 003401 COPY CMQODV. 003402C ****************************************************************** 003403C ** ** 003404C ** IBM MQ for z/OS ** 003405C ** ** 003406C ** FILE NAME: CMQODV ** 003407C ** ** 003408C ** DESCRIPTION: MQOD Structure -- Object descriptor ** 003409C ** ** 003410C ****************************************************************** 003411C ** @START_COPYRIGHT@ ** 003412C ** Statement: Licensed Materials - Property of IBM ** 003413C ** ** 003414C ** 5655-MQ9 ** 003415C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003416C ** @END_COPYRIGHT@ ** 003417C ****************************************************************** 003418C ** ** 003419C ** FUNCTION: This file declares the structure MQOD, ** 003420C ** which is used by the main MQI. ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 64 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003421C ** ** 003422C ** PROCESSOR: COBOL ** 003423C ** ** 003424C ****************************************************************** 003425C 003426C ** MQOD structure 003427C 10 MQOD. 003428C ** Structure identifier 003429C 15 MQOD-STRUCID PIC X(4) VALUE 'OD '. 003430C ** Structure version number 003431C 15 MQOD-VERSION PIC S9(9) BINARY VALUE 1. 003432C ** Object type 003433C 15 MQOD-OBJECTTYPE PIC S9(9) BINARY VALUE 1. 003434C ** Object name 003435C 15 MQOD-OBJECTNAME PIC X(48) VALUE SPACES. 003436C ** Object queue manager name 003437C 15 MQOD-OBJECTQMGRNAME PIC X(48) VALUE SPACES. 003438C ** Dynamic queue name 003439C 15 MQOD-DYNAMICQNAME PIC X(48) VALUE 'CSQ.*'. 003440C ** Alternate user identifier 003441C 15 MQOD-ALTERNATEUSERID PIC X(12) VALUE SPACES. 003442C ** Ver:1 ** 003443C ** Number of object records present 003444C 15 MQOD-RECSPRESENT PIC S9(9) BINARY VALUE 0. 003445C ** Number of local queues opened successfully 003446C 15 MQOD-KNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003447C ** Number of remote queues opened 003448C 15 MQOD-UNKNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003449C ** Number of queues that failed to open 003450C 15 MQOD-INVALIDDESTCOUNT PIC S9(9) BINARY VALUE 0. 003451C ** Offset of first object record from start of MQOD 003452C 15 MQOD-OBJECTRECOFFSET PIC S9(9) BINARY VALUE 0. 003453C ** Offset of first response record from start of MQOD 003454C 15 MQOD-RESPONSERECOFFSET PIC S9(9) BINARY VALUE 0. 003455C ** Address of first object record 003456C 15 MQOD-OBJECTRECPTR POINTER VALUE NULL. 003457C ** Address of first response record 003458C 15 MQOD-RESPONSERECPTR POINTER VALUE NULL. 003459C ** Ver:2 ** 003460C ** Alternate security identifier 003461C 15 MQOD-ALTERNATESECURITYID PIC X(40) VALUE LOW-VALUES. 003462C ** Resolved queue name 003463C 15 MQOD-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003464C ** Resolved queue manager name 003465C 15 MQOD-RESOLVEDQMGRNAME PIC X(48) VALUE SPACES. 003466C ** Ver:3 ** 003467C ** Object long name 003468C 15 MQOD-OBJECTSTRING. 003469C ** Address of variable length string 003470C 20 MQOD-OBJECTSTRING-VSPTR POINTER VALUE NULL. 003471C ** Offset of variable length string 003472C 20 MQOD-OBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003473C ** Size of buffer 003474C 20 MQOD-OBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003475C ** Length of variable length string 003476C 20 MQOD-OBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003477C ** CCSID of variable length string 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 65 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003478C 20 MQOD-OBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003479C ** Message Selector 003480C 15 MQOD-SELECTIONSTRING. 003481C ** Address of variable length string 003482C 20 MQOD-SELECTIONSTRING-VSPTR POINTER VALUE NULL. 003483C ** Offset of variable length string 003484C 20 MQOD-SELECTIONSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003485C ** Size of buffer 003486C 20 MQOD-SELECTIONSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003487C ** Length of variable length string 003488C 20 MQOD-SELECTIONSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003489C ** CCSID of variable length string 003490C 20 MQOD-SELECTIONSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003491C ** Resolved long object name 003492C 15 MQOD-RESOBJECTSTRING. 003493C ** Address of variable length string 003494C 20 MQOD-RESOBJECTSTRING-VSPTR POINTER VALUE NULL. 003495C ** Offset of variable length string 003496C 20 MQOD-RESOBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. 003497C ** Size of buffer 003498C 20 MQOD-RESOBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. 003499C ** Length of variable length string 003500C 20 MQOD-RESOBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. 003501C ** CCSID of variable length string 003502C 20 MQOD-RESOBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. 003503C ** Alias queue resolved object type 003504C 15 MQOD-RESOLVEDTYPE PIC S9(9) BINARY VALUE 0. 003505C ** Ver:4 ** 003506C 003507C 003508C ****************************************************************** 003509C ** End of CMQODV ** 003510C ****************************************************************** 003511 003512 01 MQM-MESSAGE-DESCRIPTOR. 003513 COPY CMQMDV. 003514C ****************************************************************** 003515C ** ** 003516C ** IBM MQ for z/OS ** 003517C ** ** 003518C ** FILE NAME: CMQMDV ** 003519C ** ** 003520C ** DESCRIPTION: MQMD Structure -- Message Descriptor ** 003521C ** ** 003522C ****************************************************************** 003523C ** @START_COPYRIGHT@ ** 003524C ** Statement: Licensed Materials - Property of IBM ** 003525C ** ** 003526C ** 5655-MQ9 ** 003527C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003528C ** @END_COPYRIGHT@ ** 003529C ****************************************************************** 003530C ** ** 003531C ** FUNCTION: This file declares the structure MQMD, ** 003532C ** which is used by the main MQI. ** 003533C ** ** 003534C ** PROCESSOR: COBOL ** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 66 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003535C ** ** 003536C ****************************************************************** 003537C 003538C ** MQMD structure 003539C 10 MQMD. 003540C ** Structure identifier 003541C 15 MQMD-STRUCID PIC X(4) VALUE 'MD '. 003542C ** Structure version number 003543C 15 MQMD-VERSION PIC S9(9) BINARY VALUE 1. 003544C ** Options for report messages 003545C 15 MQMD-REPORT PIC S9(9) BINARY VALUE 0. 003546C ** Message type 003547C 15 MQMD-MSGTYPE PIC S9(9) BINARY VALUE 8. 003548C ** Message lifetime 003549C 15 MQMD-EXPIRY PIC S9(9) BINARY VALUE -1. 003550C ** Feedback or reason code 003551C 15 MQMD-FEEDBACK PIC S9(9) BINARY VALUE 0. 003552C ** Numeric encoding of message data 003553C 15 MQMD-ENCODING PIC S9(9) BINARY VALUE 785. 003554C ** Character set identifier of message data 003555C 15 MQMD-CODEDCHARSETID PIC S9(9) BINARY VALUE 0. 003556C ** Format name of message data 003557C 15 MQMD-FORMAT PIC X(8) VALUE SPACES. 003558C ** Message priority 003559C 15 MQMD-PRIORITY PIC S9(9) BINARY VALUE -1. 003560C ** Message persistence 003561C 15 MQMD-PERSISTENCE PIC S9(9) BINARY VALUE 2. 003562C ** Message identifier 003563C 15 MQMD-MSGID PIC X(24) VALUE LOW-VALUES. 003564C ** Correlation identifier 003565C 15 MQMD-CORRELID PIC X(24) VALUE LOW-VALUES. 003566C ** Backout counter 003567C 15 MQMD-BACKOUTCOUNT PIC S9(9) BINARY VALUE 0. 003568C ** Name of reply queue 003569C 15 MQMD-REPLYTOQ PIC X(48) VALUE SPACES. 003570C ** Name of reply queue manager 003571C 15 MQMD-REPLYTOQMGR PIC X(48) VALUE SPACES. 003572C ** User identifier 003573C 15 MQMD-USERIDENTIFIER PIC X(12) VALUE SPACES. 003574C ** Accounting token 003575C 15 MQMD-ACCOUNTINGTOKEN PIC X(32) VALUE LOW-VALUES. 003576C ** Application data relating to identity 003577C 15 MQMD-APPLIDENTITYDATA PIC X(32) VALUE SPACES. 003578C ** Type of application that put the message 003579C 15 MQMD-PUTAPPLTYPE PIC S9(9) BINARY VALUE 0. 003580C ** Name of application that put the message 003581C 15 MQMD-PUTAPPLNAME PIC X(28) VALUE SPACES. 003582C ** Date when message was put 003583C 15 MQMD-PUTDATE PIC X(8) VALUE SPACES. 003584C ** Time when message was put 003585C 15 MQMD-PUTTIME PIC X(8) VALUE SPACES. 003586C ** Application data relating to origin 003587C 15 MQMD-APPLORIGINDATA PIC X(4) VALUE SPACES. 003588C ** Ver:1 ** 003589C 003590C 003591C ****************************************************************** 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 67 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003592C ** End of CMQMDV ** 003593C ****************************************************************** 003594 003595 01 MQM-GET-MESSAGE-OPTIONS. 003596 COPY CMQGMOV. 003597C ****************************************************************** 003598C ** ** 003599C ** IBM MQ for z/OS ** 003600C ** ** 003601C ** FILE NAME: CMQGMOV ** 003602C ** ** 003603C ** DESCRIPTION: MQGMO Structure -- Get Message Options ** 003604C ** ** 003605C ****************************************************************** 003606C ** @START_COPYRIGHT@ ** 003607C ** Statement: Licensed Materials - Property of IBM ** 003608C ** ** 003609C ** 5655-MQ9 ** 003610C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003611C ** @END_COPYRIGHT@ ** 003612C ****************************************************************** 003613C ** ** 003614C ** FUNCTION: This file declares the structure MQGMO, ** 003615C ** which is used by the main MQI. ** 003616C ** ** 003617C ** PROCESSOR: COBOL ** 003618C ** ** 003619C ****************************************************************** 003620C 003621C ** MQGMO structure 003622C 10 MQGMO. 003623C ** Structure identifier 003624C 15 MQGMO-STRUCID PIC X(4) VALUE 'GMO '. 003625C ** Structure version number 003626C 15 MQGMO-VERSION PIC S9(9) BINARY VALUE 1. 003627C ** Options that control the action of MQGET 003628C 15 MQGMO-OPTIONS PIC S9(9) BINARY VALUE 0. 003629C ** Wait interval 003630C 15 MQGMO-WAITINTERVAL PIC S9(9) BINARY VALUE 0. 003631C ** Signal 003632C 15 MQGMO-SIGNAL1 POINTER VALUE NULL. 003633C ** Signal identifier 003634C 15 MQGMO-SIGNAL2 PIC S9(9) BINARY VALUE 0. 003635C ** Resolved name of destination queue 003636C 15 MQGMO-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003637C ** Ver:1 ** 003638C ** Options controlling selection criteria used for MQGET 003639C 15 MQGMO-MATCHOPTIONS PIC S9(9) BINARY VALUE 3. 003640C ** Flag indicating whether message retrieved is in a group 003641C 15 MQGMO-GROUPSTATUS PIC X VALUE ' '. 003642C ** Flag indicating whether message retrieved is a segment of a 003643C ** logical message 003644C 15 MQGMO-SEGMENTSTATUS PIC X VALUE ' '. 003645C ** Flag indicating whether further segmentation is allowed for 003646C ** the message retrieved 003647C 15 MQGMO-SEGMENTATION PIC X VALUE ' '. 003648C ** Reserved 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 68 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003649C 15 MQGMO-RESERVED1 PIC X VALUE ' '. 003650C ** Ver:2 ** 003651C ** Message token 003652C 15 MQGMO-MSGTOKEN PIC X(16) VALUE LOW-VALUES. 003653C ** Length of message data returned (bytes) 003654C 15 MQGMO-RETURNEDLENGTH PIC S9(9) BINARY VALUE -1. 003655C ** Ver:3 ** 003656C ** Reserved 003657C 15 MQGMO-RESERVED2 PIC S9(9) BINARY VALUE 0. 003658C ** Message handle 003659C 15 MQGMO-MSGHANDLE PIC S9(18) BINARY VALUE 0. 003660C ** Ver:4 ** 003661C 003662C 003663C ****************************************************************** 003664C ** End of CMQGMOV ** 003665C ****************************************************************** 003666 003667 01 MQM-PUT-MESSAGE-OPTIONS. 003668 COPY CMQPMOV. 003669C ****************************************************************** 003670C ** ** 003671C ** IBM MQ for z/OS ** 003672C ** ** 003673C ** FILE NAME: CMQPMOV ** 003674C ** ** 003675C ** DESCRIPTION: MQPMO Structure -- Put Message Options ** 003676C ** ** 003677C ****************************************************************** 003678C ** @START_COPYRIGHT@ ** 003679C ** Statement: Licensed Materials - Property of IBM ** 003680C ** ** 003681C ** 5655-MQ9 ** 003682C ** (C) Copyright IBM Corporation. 1997, 2026 ** 003683C ** @END_COPYRIGHT@ ** 003684C ****************************************************************** 003685C ** ** 003686C ** FUNCTION: This file declares the structure MQPMO, ** 003687C ** which is used by the main MQI. ** 003688C ** ** 003689C ** PROCESSOR: COBOL ** 003690C ** ** 003691C ****************************************************************** 003692C 003693C ** MQPMO structure 003694C 10 MQPMO. 003695C ** Structure identifier 003696C 15 MQPMO-STRUCID PIC X(4) VALUE 'PMO '. 003697C ** Structure version number 003698C 15 MQPMO-VERSION PIC S9(9) BINARY VALUE 1. 003699C ** Options that control the action of MQPUT and MQPUT1 003700C 15 MQPMO-OPTIONS PIC S9(9) BINARY VALUE 0. 003701C ** Reserved 003702C 15 MQPMO-TIMEOUT PIC S9(9) BINARY VALUE -1. 003703C ** Object handle of input queue 003704C 15 MQPMO-CONTEXT PIC S9(9) BINARY VALUE 0. 003705C ** Number of messages sent successfully to local queues 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:31:42 Page 69 LineID PL SL ----+-*A-1-B--+----2----+----3----+----4----+----5----+----6----+----7-|--+----8 Map and Cross Reference 0 003706C 15 MQPMO-KNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003707C ** Number of messages sent successfully to remote queues 003708C 15 MQPMO-UNKNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. 003709C ** Number of messages that could not be sent 003710C 15 MQPMO-INVALIDDESTCOUNT PIC S9(9) BINARY VALUE 0. 003711C ** Resolved name of destination queue 003712C 15 MQPMO-RESOLVEDQNAME PIC X(48) VALUE SPACES. 003713C ** Resolved name of destination queue manager 003714C 15 MQPMO-RESOLVEDQMGRNAME PIC X(48) VALUE SPACES. 003715C ** Ver:1 ** 003716C ** Number of put message records or response records present 003717C 15 MQPMO-RECSPRESENT PIC S9(9) BINARY VALUE 0. 003718C ** Flags indicating which MQPMR fields are present 003719C 15 MQPMO-PUTMSGRECFIELDS PIC S9(9) BINARY VALUE 0. 003720C ** Offset of first put message record from start of MQPMO 003721C 15 MQPMO-PUTMSGRECOFFSET PIC S9(9) BINARY VALUE 0. 003722C ** Offset of first response record from start of MQPMO 003723C 15 MQPMO-RESPONSERECOFFSET PIC S9(9) BINARY VALUE 0. 003724C ** Address of first put message record 003725C 15 MQPMO-PUTMSGRECPTR POINTER VALUE NULL. 003726C ** Address of first response record 003727C 15 MQPMO-RESPONSERECPTR POINTER VALUE NULL. 003728C ** Ver:2 ** 003729C ** Original message handle 003730C 15 MQPMO-ORIGINALMSGHANDLE PIC S9(18) BINARY VALUE 0. 003731C ** New message handle 003732C 15 MQPMO-NEWMSGHANDLE PIC S9(18) BINARY VALUE 0. 003733C ** The action being performed 003734C 15 MQPMO-ACTION PIC S9(9) BINARY VALUE 0. 003735C ** Publication level 003736C 15 MQPMO-PUBLEVEL PIC S9(9) BINARY VALUE 9. 003737C ** Ver:3 **

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

По этому листингу ключевое — **предупреждение про несовпадение CCSID между SQL-копроцессором и DSNHDECP**:

- `DSNH4760I ... DB2 SQL COPROCESSOR ... under DB2 V13` — ок, копроцессор DB2 V13.
    
- `DSNH4790I ... DSNHDECP has CCSID 1047 in effect` — у загруженного `DSNHDECP` “дефолтный” EBCDIC CCSID **1047**.
    
- `DSNH4791I ... CCSID 1140 is used to process SQL, but DSNHDECP has EBCDIC CCSID 1047 in effect` — **SQL-текст обрабатывается как 1140**, но таблицы/параметры из `DSNHDECP` у тебя рассчитаны на 1047. Это и даёт warning.
    

### Что это означает practically

- Если в embedded SQL есть **национальные символы** (DE umlauts, спецсимволы), либо строковые литералы/идентификаторы чувствительны к кодировке, то возможны “тихие” ошибки: неправильные символы в DCLGEN/SQL, неожиданные результаты сравнения строк, проблемы с host variables/литералами.
    
- Если у тебя всё строго A-Z/0-9/underscore и без “расширенной” таблицы — часто проходит без боли, но **warning лучше исправить**, чтобы не ловить фантомы позже.
    

### Как правильно поправить (обычные варианты)

1. **Сделать CCSID единым** (рекомендовано):
    
    - либо **использовать/сгенерировать DSNHDECP**, где EBCDIC CCSID = **1140**,
        
    - либо переключить компиляцию SQL на 1047 (если это стандарт твоей установки), но у тебя уже явно стоит `CCSID(1140)`.
        
2. **Проверить, откуда реально берётся DSNHDECP**  
    У тебя в листинге:
    
    - `DSNHDECP LOADED FROM - (DSND10.DBDG.SDSNEXIT(DSNHDECP))`
        
    
    Значит, конкретно этот load-module лежит в **SDSNEXIT**. Если в системе есть “правильный” DSNHDECP в другом `SDSNEXIT`/STEPLIB, но не тот порядок конкатенации — ты можешь просто подхватывать “не тот” модуль.
    
3. **Подтянуть корректный DSNHDECP через JCL/PROC**
    
    - Убедись, что в шаге компиляции (IGYCRCTL + DB2 coprocessor) **STEPLIB/JOBLIB** (или `DSNEXIT`/`DSNLOAD`) указывает на тот DB2, где `DSNHDECP` настроен под 1140.
        
    - Иногда это решается банально: **поменять порядок** библиотек в STEPLIB, чтобы первым был нужный `SDSNEXIT`.
        
4. Если нужно именно “быстро и локально”:
    
    - оставить `CCSID(1140)` как есть,
        
    - а `DSNHDECP` пересобрать/заменить на вариант с CCSID 1140 (это обычно зона ответственности DB2 sysprog’ов/DBA, потому что это site-wide дефолты препроцессора).
        

### Мини-чеклист “что проверить у себя”

- В твоих SQL options видно: `CCSID(1140)` — это ты явно запросил 1140.
    
- А `DSNHDECP` говорит: EBCDIC CCSID 1047 — значит **site defaults** (или этот конкретный DSNHDECP) на 1047.
    
- Значит решение: **или DSNHDECP под 1140**, или **перейти на CCSID(1047)**, но тогда надо консистентно и с COBOL CODEPAGE, и с тем, как у вас хранят исходники.
    

---

Если скажешь, **в каком контексте ты это смотришь** (TSO compile? JCL in batch? какой proc), я могу прямо по твоему JCL подсказать **где именно переставить/добавить STEPLIB** или какой member/exit обычно правят.

И ещё: у меня часть ранее загруженных файлов из прошлых шагов **уже истекла** в окружении. Если тебе нужно, чтобы я сверялся с теми файлами (исходник/дифф и т.п.) — просто загрузи их ещё раз.

  

1 J E S 2 J O B L O G -- S Y S T E M S 0 W 1 -- N O D E S V S C J E S 2 0 16.37.46 JOB05119 ---- SATURDAY, 04 APR 2026 ---- 16.37.46 JOB05119 IRR010I USERID Z88011 IS ASSIGNED TO THIS JOB. 16.37.48 JOB05119 ICH70001I Z88011 LAST ACCESS AT 16:35:18 ON SATURDAY, APRIL 4, 2026 16.37.48 JOB05119 $HASP373 CBLMQCIX STARTED - INIT 1 - CLASS A - SYS S0W1 16.37.49 JOB05119 IEF764I CBLMQCIX TRANSL DFHAPIR DFHEIMOD PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND. 16.37.50 JOB05119 - -----TIMINGS (MINS.)------ -----PAGING COUNTS---- 16.37.50 JOB05119 -STEPNAME PROCSTEP RC EXCP CONN TCB SRB CLOCK SERV WORKLOAD PAGE SWAP VIO SWAPS 16.37.50 JOB05119 -TRANSL 00 1106 51 .00 .00 .0 40 BATCH 0 0 0 0 16.37.53 JOB05119 $HASP375 CBLMQCIX ESTIMATED LINES EXCEEDED 16.37.53 JOB05119 IEF450I CBLMQCIX COBOL - ABEND=S722 U0000 REASON=00000000 16.37.54 JOB05119 -COBOL *S722 3831 231 .00 .00 .0 195 BATCH 0 0 0 0 16.37.54 JOB05119 -LKED FLUSH 0 0 .00 .00 .0 BATCH 0 0 0 0 16.37.54 JOB05119 -BIND FLUSH 0 0 .00 .00 .0 BATCH 0 0 0 0 16.37.55 JOB05119 -CBLMQCIX ENDED. NAME- TOTAL TCB CPU TIME= .00 TOTAL ELAPSED TIME= .1 16.37.55 JOB05119 $HASP395 CBLMQCIX ENDED - ABEND=S722 0------ JES2 JOB STATISTICS ------ - 04 APR 2026 JOB EXECUTION DATE - 82 CARDS READ - 5,098 SYSOUT PRINT RECORDS - 0 SYSOUT PUNCH RECORDS - 343 SYSOUT SPOOL KBYTES - 0.13 MINUTES EXECUTION TIME

  

1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 1 0 CBL SQL OFFSET TEST NOXREF NOMAP 0*OPTIONS IN EFFECT* CICS DEBUG SPIE EDF LINECOUNT(60) TABLE(DFHEITAB) NATLANG(EN) SOURCE NOVBREF OPTIONS FLAG(W) SEQ APOST NONUM SPACE(1) CBLCARD NOSYSEIB NOFEPI NOCPSM LINKAGE LENGTH COBOL2 0 LINE SOURCE LISTING 00001 IDENTIFICATION DIVISION. 00002 PROGRAM-ID. LIBMQCIC. 00003 00004 ENVIRONMENT DIVISION. 00005 INPUT-OUTPUT SECTION. 00006 FILE-CONTROL. 00007 SELECT PARAMSFILE ASSIGN TO PARAMS 00008 ORGANIZATION IS SEQUENTIAL 00009 ACCESS IS SEQUENTIAL 00010 FILE STATUS IS PARAMS-STATUS. 00011 00012 DATA DIVISION. 00013 FILE SECTION. 00014 FD PARAMSFILE 00015 RECORDING MODE IS F 00016 RECORD CONTAINS 80 CHARACTERS. 00017 01 PARAMS-REC PIC X(80). 00018 00019 WORKING-STORAGE SECTION. 00020 00021 EXEC SQL INCLUDE SQLCA END-EXEC. 00022 00023 01 PARAMS-STATUS PIC XX. 00024 01 WS-SQLCODE-EDIT PIC -ZZZ,ZZZ,ZZ9 USAGE DISPLAY. 00025 00026 01 MQM-CONSTANTS. 00027 COPY CMQV. 00028 00029 01 MQM-OBJECT-DESCRIPTOR. 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 2 0 LINE SOURCE LISTING 000030 COPY CMQODV. 00031 00032 01 MQM-MESSAGE-DESCRIPTOR. 00033 COPY CMQMDV. 00034 00035 01 MQM-GET-MESSAGE-OPTIONS. 00036 COPY CMQGMOV. 00037 00038 01 MQM-PUT-MESSAGE-OPTIONS. 00039 COPY CMQPMOV. 00040 00041 01 WS-QMGR-NAME PIC X(48) VALUE SPACES. 00042 01 WS-REQ-QUEUE PIC X(48) VALUE 'LIB.REQ.TEST'. 00043 01 WS-REP-QUEUE PIC X(48) VALUE 'LIB.REP.TEST'. 00044 01 WS-WAIT-MS-DISP PIC 9(9) VALUE 0. 00045 01 WS-WAIT-VAL-STR PIC X(9). 00046 01 WS-WAIT-LEN PIC S9(4) COMP. 00047 01 WS-WAIT-MS PIC S9(9) COMP-5 VALUE 0. 00048 01 WS-CTL-LINE PIC X(256). 00049 01 WS-VAL PIC X(200). 00050 01 WS-EOF PIC X VALUE 'N'. 00051 01 WS-KEY PIC X(16). 00052 01 WS-REQUEST-TYPE PIC X(6) VALUE SPACES. 00053 00054 COPY LIBLOAN. 00055 00056 EXEC SQL 00057 DECLARE CUR-ACTIVE-LOANS CURSOR FOR 00058 SELECT LOAN_ID_NUM, BOOK_ID 00059 FROM LOAN 00060 WHERE USER_ID = :HAU-USER-ID 00061 AND RETURN_DATE IS NULL 00062 ORDER BY LOAN_ID_NUM 00063 END-EXEC. 00064 00065 01 HCONN PIC S9(9) COMP. 00066 01 HOBJ-REQ PIC S9(9) COMP. 00067 01 HOBJ-REP PIC S9(9) COMP. 00068 01 COMPCODE PIC S9(9) COMP. 00069 01 REASON PIC S9(9) COMP. 00070 00071 01 REQ-DATA PIC X(8192). 00072 01 RSP-DATA PIC X(8192). 00073 01 REQ-DATA-LEN PIC S9(9) COMP VALUE 8192. 00074 01 RSP-DATA-LEN PIC S9(9) COMP VALUE 0. 00075 00076 01 WS-ACTIVE-COUNT PIC S9(9) COMP VALUE 0. 00077 01 WS-LOAN-ID-NUM PIC S9(9) COMP VALUE 0. 00078 01 WS-NEW-LOAN-NUM PIC 9(9) VALUE 0. 00079 01 WS-NEW-LOAN-ID PIC X(10) VALUE SPACES. 00080 01 WS-PADDED PIC X(9) VALUE SPACES. 00081 01 WS-ACTIVE-LOAN-COUNT PIC 9(2) COMP VALUE 0. 00082 01 WS-ACTIVE-LOAN-ID-NUM PIC S9(9) COMP VALUE 0. 00083 01 WS-ACTIVE-BOOK-ID PIC X(10) VALUE SPACES. 00084 00085 01 WS-SQL-MSG PIC X(80) VALUE SPACES. 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 3 0 LINE SOURCE LISTING 000086 01 WS-XML-REQUEST PIC X(8192) VALUE SPACES. 00087 01 WS-XML-RESPONSE PIC X(8192) VALUE SPACES. 00088 01 WS-XML PIC X(8192) VALUE SPACES. 00089 01 WS-XML-LEN PIC S9(9) COMP. 00090 01 WS-PTR PIC S9(9) COMP. 00091 01 WS-INDEX PIC 9(2) COMP VALUE 0. 00092 00093 01 WS-RETURN-COUNT PIC S9(9) COMP VALUE 0. 00094 01 WS-ACTIVE-REQ-COUNT PIC S9(9) COMP VALUE 0. 00095 01 WS-TAG-USER-START PIC X(10) VALUE "<user><id>". 00096 01 WS-TAG-USER-END PIC X(12) VALUE "</id></user>". 00097 01 WS-TAG-BOOK-START PIC X(10) VALUE "<book><id>". 00098 01 WS-TAG-BOOK-END PIC X(12) VALUE "</id></book>". 00099 01 WS-TAG-ACTIVE-USERID-START PIC X(8) VALUE "<userId>". 00100 01 WS-TAG-ACTIVE-USERID-END PIC X(9) VALUE "</userId>". 00101 01 WS-TAG-LOANID-START PIC X(8) VALUE "<loanId>". 00102 01 WS-TAG-LOANID-END PIC X(9) VALUE "</loanId>". 00103 01 WS-START PIC S9(9) COMP VALUE 0. 00104 01 WS-END PIC S9(9) COMP VALUE 0. 00105 01 WS-LEN PIC S9(9) COMP VALUE 0. 00106 * 00107 * W03 - MQ API fields 00108 * 00109 01 W03-BUFFER-LENGTH PIC S9(9) BINARY VALUE 80. 00110 01 W03-HCONN PIC S9(9) COMP-5. 00111 01 W03-OPTIONS PIC S9(9) BINARY. 00112 01 W03-HOBJ PIC S9(9) BINARY. 00113 01 W03-DATA-LENGTH PIC S9(9) BINARY. 00114 01 W03-COMPCODE PIC S9(9) BINARY. 00115 01 W03-REASON PIC S9(9) BINARY. 00116 01 W03-MESSAGE-DATA PIC X(80) VALUE SPACES. 00117 00118 PROCEDURE DIVISION. 00119 00120 MAIN-SECTION. 00121 00122 DISPLAY 'LIBMQCIC STARTING (CICS MVP)'. 00123 00124 DISPLAY 'MQ QMGR=' WS-QMGR-NAME 00125 ' REQQ=' WS-REQ-QUEUE 00126 ' RPLYQ=' WS-REP-QUEUE 00127 ' MODE=NO-WAIT'. 00128 00129 00130 DISPLAY 'A: INIT MQ STRUCTS (DEFAULTS)'. 00131 00132 MOVE MQOD-DEFAULT TO MQM-OBJECT-DESCRIPTOR. 00133 MOVE MQMD-DEFAULT TO MQM-MESSAGE-DESCRIPTOR. 00134 MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS. 00135 MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS. 00136 00137 DISPLAY 'B: BEFORE MQCONN QMGR=[' WS-QMGR-NAME ']'. 00138 CALL 'MQCONN' USING WS-QMGR-NAME 00139 HCONN 00140 COMPCODE 00141 REASON. 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 4 0 LINE SOURCE LISTING 000142 DISPLAY 'C: AFTER MQCONN CC=' COMPCODE 00143 ' RC=' REASON ' HCONN=' HCONN. 00144 IF COMPCODE NOT = MQCC-OK 00145 DISPLAY 'MQCONN FAILED, REASON=' REASON 00146 EXEC CICS RETURN END-EXEC 00147 END-IF. 00148 DISPLAY 'MQCONN SUCCEEDED, HCONN=' HCONN. 00149 00150 DISPLAY 'D: BEFORE MQOPEN REQ Q=[' WS-REQ-QUEUE ']'. 00151 MOVE MQOD-VERSION-4 TO MQOD-VERSION. 00152 MOVE WS-REQ-QUEUE TO MQOD-OBJECTNAME. 00153 CALL 'MQOPEN' USING HCONN 00154 MQM-OBJECT-DESCRIPTOR 00155 MQOO-INPUT-SHARED 00156 HOBJ-REQ 00157 COMPCODE 00158 REASON. 00159 DISPLAY 'E: AFTER MQOPEN REQ CC=' COMPCODE 00160 ' RC=' REASON ' HOBJ-REQ=' HOBJ-REQ. 00161 IF COMPCODE NOT = MQCC-OK 00162 DISPLAY 'MQOPEN REQ FAILED, REASON=' REASON 00163 GO TO MQ-DISCONNECT 00164 END-IF. 00165 00166 DISPLAY 'F: BEFORE MQOPEN REP Q=[' WS-REP-QUEUE ']'. 00167 MOVE MQOD-VERSION-4 TO MQOD-VERSION. 00168 MOVE WS-REP-QUEUE TO MQOD-OBJECTNAME. 00169 CALL 'MQOPEN' USING HCONN 00170 MQM-OBJECT-DESCRIPTOR 00171 MQOO-OUTPUT 00172 HOBJ-REP 00173 COMPCODE 00174 REASON. 00175 DISPLAY 'G: AFTER MQOPEN REP CC=' COMPCODE 00176 ' RC=' REASON ' HOBJ-REP=' HOBJ-REP. 00177 IF COMPCODE NOT = MQCC-OK 00178 DISPLAY 'MQOPEN REP FAILED, REASON=' REASON 00179 GO TO MQ-CLOSE-REQ 00180 END-IF. 00181 DISPLAY 'MQOPEN SUCCEEDED FOR BOTH QUEUES'. 00182 00183 MOVE MQGMO-VERSION-1 TO MQGMO-VERSION. 00184 MOVE MQMT-DATAGRAM TO MQMD-MSGTYPE. 00185 00186 MOVE MQGMO-NO-WAIT TO MQGMO-OPTIONS 00187 ADD MQGMO-CONVERT TO MQGMO-OPTIONS 00188 ADD MQGMO-FAIL-IF-QUIESCING TO MQGMO-OPTIONS 00189 ADD MQGMO-SYNCPOINT TO MQGMO-OPTIONS. 00190 00191 MOVE 1047 TO MQMD-CODEDCHARSETID 00192 MOVE MQENC-NATIVE TO MQMD-ENCODING. 00193 00194 DISPLAY 'H: BEFORE MQGET (NO-WAIT)'. 00195 CALL 'MQGET' USING HCONN 00196 HOBJ-REQ 00197 MQM-MESSAGE-DESCRIPTOR 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 5 0 LINE SOURCE LISTING 000198 MQM-GET-MESSAGE-OPTIONS 00199 REQ-DATA-LEN 00200 REQ-DATA 00201 W03-DATA-LENGTH 00202 COMPCODE 00203 REASON. 00204 IF COMPCODE NOT = MQCC-OK 00205 IF REASON = MQRC-NO-MSG-AVAILABLE 00206 DISPLAY 'MQGET: NO MESSAGE AVAILABLE' 00207 GO TO MQ-CLOSE-BOTH 00208 END-IF 00209 DISPLAY 'MQGET failed CC=' COMPCODE ' RC=' REASON 00210 EXEC CICS SYNCPOINT ROLLBACK END-EXEC 00211 GO TO MQ-CLOSE-BOTH 00212 ELSE 00213 DISPLAY 'Got ' W03-DATA-LENGTH 00214 ' bytes (converted to CCSID ' 00215 MQMD-CODEDCHARSETID ')' 00216 DISPLAY 'MSG: ' REQ-DATA(1:W03-DATA-LENGTH) 00217 END-IF. 00218 00219 MOVE MQMD-MSGID TO MQMD-CORRELID. 00220 MOVE MQMI-NONE TO MQMD-MSGID. 00221 00222 MOVE REQ-DATA(1:W03-DATA-LENGTH) TO WS-XML-REQUEST. 00223 00224 PERFORM PARSE-XML-REQUEST. 00225 00226 IF WS-REQUEST-TYPE = 'ACTIVE' 00227 DISPLAY 'PARSE COMPLETE, STATUS=' HAU-STATUS-CODE 00228 ELSE 00229 IF WS-REQUEST-TYPE = 'RETURN' 00230 DISPLAY 'PARSE COMPLETE, STATUS=' HRR-STATUS-CODE 00231 ELSE 00232 DISPLAY 'PARSE COMPLETE, STATUS=' HBR-STATUS-CODE 00233 END-IF 00234 END-IF 00235 00236 IF WS-REQUEST-TYPE = 'ACTIVE' 00237 IF HAU-STATUS-CODE NOT = 'ERR ' 00238 PERFORM PROCESS-ACTIVE-BY-USER 00239 END-IF 00240 ELSE 00241 IF WS-REQUEST-TYPE = 'RETURN' 00242 IF HRR-STATUS-CODE NOT = 'ERR ' 00243 PERFORM PROCESS-RETURN 00244 END-IF 00245 ELSE 00246 IF HBR-STATUS-CODE NOT = 'ERR ' 00247 PERFORM PROCESS-BORROW 00248 END-IF 00249 END-IF 00250 END-IF 00251 00252 IF WS-REQUEST-TYPE = 'ACTIVE' 00253 DISPLAY 'PROCESS COMPLETE, STATUS=' HAU-STATUS-CODE 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 6 0 LINE SOURCE LISTING 000254 ELSE 00255 IF WS-REQUEST-TYPE = 'RETURN' 00256 DISPLAY 'PROCESS COMPLETE, STATUS=' HRR-STATUS-CODE 00257 ELSE 00258 DISPLAY 'PROCESS COMPLETE, STATUS=' HBR-STATUS-CODE 00259 END-IF 00260 END-IF 00261 00262 PERFORM BUILD-XML-RESPONSE. 00263 00264 MOVE MQPMO-VERSION-1 TO MQPMO-VERSION. 00265 MOVE MQPMO-NO-SYNCPOINT TO MQPMO-OPTIONS. 00266 ADD MQPMO-SYNCPOINT TO MQPMO-OPTIONS. 00267 ADD MQPMO-FAIL-IF-QUIESCING TO MQPMO-OPTIONS. 00268 00269 COMPUTE RSP-DATA-LEN = FUNCTION LENGTH(RSP-DATA). 00270 00271 CALL 'MQPUT' USING HCONN 00272 HOBJ-REP 00273 MQM-MESSAGE-DESCRIPTOR 00274 MQM-PUT-MESSAGE-OPTIONS 00275 RSP-DATA-LEN 00276 RSP-DATA 00277 COMPCODE 00278 REASON. 00279 IF COMPCODE NOT = MQCC-OK 00280 DISPLAY 'MQPUT FAILED, REASON=' REASON 00281 EXEC CICS SYNCPOINT ROLLBACK END-EXEC 00282 ELSE 00283 DISPLAY 'REPLY SENT, CORRELID SET FROM REQUEST MSGID' 00284 EXEC CICS SYNCPOINT END-EXEC 00285 END-IF. 00286 00287 MQ-CLOSE-BOTH. 00288 CALL 'MQCLOSE' USING HCONN 00289 HOBJ-REP 00290 MQCO-NONE 00291 COMPCODE 00292 REASON. 00293 MQ-CLOSE-REQ. 00294 CALL 'MQCLOSE' USING HCONN 00295 HOBJ-REQ 00296 MQCO-NONE 00297 COMPCODE 00298 REASON. 00299 MQ-DISCONNECT. 00300 CALL 'MQDISC' USING HCONN 00301 COMPCODE 00302 REASON. 00303 00304 DISPLAY 'LIBMQCIC ENDING'. 00305 EXEC CICS RETURN END-EXEC. 00306 00307 ****************************************************************** 00308 ** Process the request using DB2 and build response 00309 ****************************************************************** 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 7 0 LINE SOURCE LISTING 000310 PROCESS-BORROW. 00311 MOVE SPACES TO HOST-BORROW-RESPONSE. 00312 MOVE HBR-USER-ID TO HBR-USER-ID-R. 00313 MOVE HBR-BOOK-ID TO HBR-BOOK-ID-R. 00314 00315 EXEC SQL 00316 SELECT COUNT(*) 00317 INTO :WS-ACTIVE-COUNT 00318 FROM LOAN 00319 WHERE BOOK_ID = :HBR-BOOK-ID 00320 AND RETURN_DATE IS NULL 00321 END-EXEC 00322 00323 DISPLAY 'sqlcode after select= ' SQLCODE 00324 DISPLAY 'ACTIVE COUNT=' WS-ACTIVE-COUNT 00325 00326 IF SQLCODE NOT = 0 00327 PERFORM SQL-ERROR 00328 PERFORM BUILD-RESPONSE 00329 EXIT 00330 END-IF 00331 00332 IF WS-ACTIVE-COUNT > 0 00333 MOVE 'BUSY' TO HBR-STATUS-CODE 00334 MOVE 'Book already on loan' TO HBR-MESSAGE 00335 DISPLAY 'BOOK ' HBR-BOOK-ID ' ALREADY ON LOAN' 00336 PERFORM BUILD-RESPONSE 00337 EXIT 00338 END-IF 00339 00340 EXEC SQL 00341 INSERT INTO LOAN 00342 (USER_ID, BOOK_ID, LOAN_DATE, DUE_DATE, RETURN_DATE) 00343 VALUES (:HBR-USER-ID, :HBR-BOOK-ID, 00344 CURRENT DATE, CURRENT DATE + 14 DAYS, NULL) 00345 END-EXEC 00346 00347 DISPLAY 'sqlcode after insert= ' SQLCODE 00348 00349 IF SQLCODE NOT = 0 00350 PERFORM SQL-ERROR 00351 PERFORM BUILD-RESPONSE 00352 EXIT 00353 END-IF 00354 00355 EXEC SQL 00356 VALUES IDENTITY_VAL_LOCAL() 00357 INTO :WS-LOAN-ID-NUM 00358 END-EXEC 00359 00360 DISPLAY 'sqlcode after IDENTITY_VAL_LOCAL= ' SQLCODE 00361 IF SQLCODE NOT = 0 00362 PERFORM SQL-ERROR 00363 PERFORM BUILD-RESPONSE 00364 EXIT 00365 END-IF 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 8 0 LINE SOURCE LISTING 000366 00367 MOVE WS-LOAN-ID-NUM TO WS-NEW-LOAN-NUM 00368 DISPLAY 'NEW LOAN NUM=' WS-NEW-LOAN-NUM 00369 00370 MOVE SPACES TO WS-NEW-LOAN-ID 00371 MOVE 'L' TO WS-NEW-LOAN-ID (1:1) 00372 MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9) 00373 00374 DISPLAY 'WS-NEW-LOAN-ID=' WS-NEW-LOAN-ID 00375 00376 MOVE WS-NEW-LOAN-ID TO HBR-LOAN-ID 00377 MOVE 'OK' TO HBR-STATUS-CODE 00378 MOVE 'Loan created' TO HBR-MESSAGE 00379 DISPLAY 'LOAN CREATED, ID=' HBR-LOAN-ID 00380 00381 CONTINUE. 00382 00383 PROCESS-RETURN. 00384 MOVE SPACES TO HOST-RETURN-RESPONSE. 00385 MOVE HRR-LOAN-ID TO HRR-LOAN-ID-R. 00386 MOVE SPACES TO HRR-USER-ID-R HRR-BOOK-ID-R. 00387 00388 IF HRR-LOAN-ID = SPACES 00389 MOVE 'ERR ' TO HRR-STATUS-CODE 00390 MOVE 'Missing loanId' TO HRR-MESSAGE 00391 EXIT 00392 END-IF 00393 00394 MOVE SPACES TO WS-PADDED 00395 IF HRR-LOAN-ID(1:1) = 'L' 00396 MOVE HRR-LOAN-ID(2:9) TO WS-PADDED 00397 ELSE 00398 MOVE HRR-LOAN-ID TO WS-PADDED 00399 END-IF 00400 00401 IF WS-PADDED IS NOT NUMERIC 00402 MOVE 'ERR ' TO HRR-STATUS-CODE 00403 MOVE 'Invalid loanId' TO HRR-MESSAGE 00404 EXIT 00405 END-IF 00406 00407 MOVE WS-PADDED TO WS-LOAN-ID-NUM 00408 00409 EXEC SQL 00410 SELECT USER_ID, BOOK_ID 00411 INTO :HRR-USER-ID-R, :HRR-BOOK-ID-R 00412 FROM LOAN 00413 WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM 00414 AND RETURN_DATE IS NULL 00415 END-EXEC 00416 00417 DISPLAY 'sqlcode after select= ' SQLCODE 00418 00419 IF SQLCODE = 100 00420 MOVE 'NOTF' TO HRR-STATUS-CODE 00421 MOVE 'Loan not found or already returned' TO HRR-MESSAGE 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 9 0 LINE SOURCE LISTING 000422 EXIT 00423 END-IF 00424 00425 IF SQLCODE NOT = 0 00426 PERFORM SQL-ERROR 00427 EXIT 00428 END-IF 00429 00430 EXEC SQL 00431 UPDATE LOAN 00432 SET RETURN_DATE = CURRENT DATE 00433 WHERE LOAN_ID_NUM = :WS-LOAN-ID-NUM 00434 AND RETURN_DATE IS NULL 00435 END-EXEC 00436 00437 DISPLAY 'sqlcode after update= ' SQLCODE 00438 00439 IF SQLCODE NOT = 0 00440 PERFORM SQL-ERROR 00441 EXIT 00442 END-IF 00443 00444 MOVE 'OK' TO HRR-STATUS-CODE 00445 MOVE 'Loan returned' TO HRR-MESSAGE 00446 DISPLAY 'LOAN RETURNED, ID=' HRR-LOAN-ID-R 00447 00448 CONTINUE. 00449 00450 PROCESS-ACTIVE-BY-USER. 00451 MOVE SPACES TO HOST-ACTIVE-BY-USER-RESPONSE. 00452 MOVE HAU-USER-ID TO HAU-USER-ID-R. 00453 MOVE 0 TO WS-ACTIVE-LOAN-COUNT HAU-LOAN-COUNT. 00454 MOVE SPACES TO HAU-LOANS. 00455 00456 IF HAU-USER-ID = SPACES 00457 MOVE 'ERR ' TO HAU-STATUS-CODE 00458 MOVE 'Missing userId' TO HAU-MESSAGE 00459 EXIT 00460 END-IF 00461 00462 EXEC SQL 00463 OPEN CUR-ACTIVE-LOANS 00464 END-EXEC 00465 IF SQLCODE NOT = 0 00466 PERFORM SQL-ERROR 00467 EXIT 00468 END-IF 00469 00470 PERFORM UNTIL WS-ACTIVE-LOAN-COUNT >= 50 00471 EXEC SQL 00472 FETCH CUR-ACTIVE-LOANS 00473 INTO :WS-ACTIVE-LOAN-ID-NUM, :WS-ACTIVE-BOOK-ID 00474 END-EXEC 00475 IF SQLCODE = 0 00476 ADD 1 TO WS-ACTIVE-LOAN-COUNT 00477 MOVE WS-ACTIVE-LOAN-ID-NUM TO WS-NEW-LOAN-NUM 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 10 0 LINE SOURCE LISTING 000478 MOVE SPACES TO WS-NEW-LOAN-ID 00479 MOVE 'L' TO WS-NEW-LOAN-ID (1:1) 00480 MOVE WS-NEW-LOAN-NUM TO WS-NEW-LOAN-ID (2:9) 00481 MOVE WS-NEW-LOAN-ID 00482 TO HAU-LOAN-ID (WS-ACTIVE-LOAN-COUNT) 00483 MOVE WS-ACTIVE-BOOK-ID 00484 TO HAU-BOOK-ID (WS-ACTIVE-LOAN-COUNT) 00485 ELSE 00486 IF SQLCODE = 100 00487 EXIT PERFORM 00488 ELSE 00489 PERFORM SQL-ERROR 00490 EXIT PERFORM 00491 END-IF 00492 END-IF 00493 END-PERFORM 00494 00495 EXEC SQL 00496 CLOSE CUR-ACTIVE-LOANS 00497 END-EXEC 00498 00499 IF HAU-STATUS-CODE NOT = 'ERR ' 00500 MOVE WS-ACTIVE-LOAN-COUNT TO HAU-LOAN-COUNT 00501 MOVE 'OK' TO HAU-STATUS-CODE 00502 MOVE 'Active loans returned' TO HAU-MESSAGE 00503 END-IF 00504 EXIT. 00505 00506 BUILD-RESPONSE. 00507 MOVE SPACES TO RSP-DATA. 00508 IF WS-REQUEST-TYPE = 'ACTIVE' 00509 MOVE HOST-ACTIVE-BY-USER-RESPONSE TO RSP-DATA 00510 ELSE 00511 IF WS-REQUEST-TYPE = 'RETURN' 00512 MOVE HOST-RETURN-RESPONSE TO RSP-DATA 00513 ELSE 00514 MOVE HOST-BORROW-RESPONSE TO RSP-DATA 00515 END-IF 00516 END-IF. 00517 EXIT. 00518 00519 SQL-ERROR. 00520 MOVE SPACES TO WS-SQL-MSG. 00521 MOVE SQLCODE TO WS-SQLCODE-EDIT. 00522 00523 STRING 'SQL ERROR ' DELIMITED BY SIZE 00524 WS-SQLCODE-EDIT DELIMITED BY SIZE 00525 INTO WS-SQL-MSG. 00526 IF WS-REQUEST-TYPE = 'ACTIVE' 00527 MOVE 'ERR ' TO HAU-STATUS-CODE 00528 MOVE WS-SQL-MSG TO HAU-MESSAGE 00529 ELSE 00530 IF WS-REQUEST-TYPE = 'RETURN' 00531 MOVE 'ERR ' TO HRR-STATUS-CODE 00532 MOVE WS-SQL-MSG TO HRR-MESSAGE 00533 ELSE 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 11 0 LINE SOURCE LISTING 000534 MOVE 'ERR ' TO HBR-STATUS-CODE 00535 MOVE WS-SQL-MSG TO HBR-MESSAGE 00536 END-IF 00537 END-IF. 00538 CONTINUE. 00539 EXIT. 00540 00541 ****************************************************************** 00542 ** Parse XML request into HOST-BORROW-REQUEST 00543 ****************************************************************** 00544 PARSE-XML-REQUEST. 00545 MOVE SPACES TO HOST-BORROW-REQUEST HOST-RETURN-REQUEST 00546 HOST-ACTIVE-BY-USER-REQUEST. 00547 MOVE 'OK' TO HBR-STATUS-CODE HRR-STATUS-CODE 00548 HAU-STATUS-CODE. 00549 MOVE SPACES TO HBR-MESSAGE HRR-MESSAGE HAU-MESSAGE. 00550 MOVE SPACES TO WS-REQUEST-TYPE. 00551 00552 MOVE 0 TO WS-ACTIVE-REQ-COUNT. 00553 INSPECT WS-XML-REQUEST 00554 TALLYING WS-ACTIVE-REQ-COUNT 00555 FOR ALL "<HostActiveLoansByUserRequest". 00556 00557 MOVE 0 TO WS-RETURN-COUNT. 00558 INSPECT WS-XML-REQUEST 00559 TALLYING WS-RETURN-COUNT 00560 FOR ALL "<HostReturnRequest". 00561 00562 IF WS-ACTIVE-REQ-COUNT > 0 00563 MOVE 'ACTIVE' TO WS-REQUEST-TYPE 00564 PERFORM EXTRACT-ACTIVE-USER-ID 00565 IF HAU-USER-ID = SPACES 00566 MOVE 'ERR ' TO HAU-STATUS-CODE 00567 MOVE 'Invalid XML' TO HAU-MESSAGE 00568 END-IF 00569 ELSE 00570 IF WS-RETURN-COUNT > 0 00571 MOVE 'RETURN' TO WS-REQUEST-TYPE 00572 PERFORM EXTRACT-LOAN-ID 00573 IF HRR-LOAN-ID = SPACES 00574 MOVE 'ERR ' TO HRR-STATUS-CODE 00575 MOVE 'Invalid XML' TO HRR-MESSAGE 00576 END-IF 00577 ELSE 00578 MOVE 'BORROW' TO WS-REQUEST-TYPE 00579 PERFORM EXTRACT-USER 00580 PERFORM EXTRACT-BOOK 00581 IF HBR-USER-ID = SPACES OR HBR-BOOK-ID = SPACES 00582 MOVE 'ERR ' TO HBR-STATUS-CODE 00583 MOVE 'Invalid XML' TO HBR-MESSAGE 00584 END-IF 00585 END-IF 00586 END-IF. 00587 00588 EXIT. 00589 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 12 0 LINE SOURCE LISTING 000590 EXTRACT-USER. 00591 MOVE 0 TO WS-START WS-END WS-LEN. 00592 INSPECT WS-XML-REQUEST 00593 TALLYING WS-START 00594 FOR CHARACTERS BEFORE WS-TAG-USER-START. 00595 IF WS-START >= LENGTH OF WS-XML-REQUEST 00596 EXIT 00597 END-IF 00598 COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-USER-START. 00599 INSPECT WS-XML-REQUEST 00600 TALLYING WS-END 00601 FOR CHARACTERS BEFORE WS-TAG-USER-END. 00602 IF WS-END <= WS-START 00603 EXIT 00604 END-IF 00605 COMPUTE WS-LEN = WS-END - WS-START. 00606 IF WS-LEN > 0 00607 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-USER-ID 00608 END-IF 00609 DISPLAY 'EXTRACT-USER: ' HBR-USER-ID 00610 EXIT. 00611 00612 EXTRACT-BOOK. 00613 MOVE 0 TO WS-START WS-END WS-LEN. 00614 INSPECT WS-XML-REQUEST 00615 TALLYING WS-START 00616 FOR CHARACTERS BEFORE WS-TAG-BOOK-START. 00617 IF WS-START >= LENGTH OF WS-XML-REQUEST 00618 EXIT 00619 END-IF 00620 COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-BOOK-START. 00621 INSPECT WS-XML-REQUEST 00622 TALLYING WS-END 00623 FOR CHARACTERS BEFORE WS-TAG-BOOK-END. 00624 IF WS-END <= WS-START 00625 EXIT 00626 END-IF 00627 COMPUTE WS-LEN = WS-END - WS-START. 00628 IF WS-LEN > 0 00629 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HBR-BOOK-ID 00630 END-IF 00631 DISPLAY 'EXTRACT-BOOK: ' HBR-BOOK-ID 00632 EXIT. 00633 00634 EXTRACT-ACTIVE-USER-ID. 00635 MOVE 0 TO WS-START WS-END WS-LEN. 00636 INSPECT WS-XML-REQUEST 00637 TALLYING WS-START 00638 FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-START. 00639 IF WS-START >= LENGTH OF WS-XML-REQUEST 00640 EXIT 00641 END-IF 00642 COMPUTE WS-START = WS-START + LENGTH 00643 OF WS-TAG-ACTIVE-USERID-START. 00644 INSPECT WS-XML-REQUEST 00645 TALLYING WS-END 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 13 0 LINE SOURCE LISTING 000646 FOR CHARACTERS BEFORE WS-TAG-ACTIVE-USERID-END. 00647 IF WS-END <= WS-START 00648 EXIT 00649 END-IF 00650 COMPUTE WS-LEN = WS-END - WS-START. 00651 IF WS-LEN > 0 00652 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HAU-USER-ID 00653 END-IF 00654 DISPLAY 'EXTRACT-ACTIVE-USER-ID: ' HAU-USER-ID 00655 EXIT. 00656 00657 EXTRACT-LOAN-ID. 00658 MOVE 0 TO WS-START WS-END WS-LEN. 00659 INSPECT WS-XML-REQUEST 00660 TALLYING WS-START 00661 FOR CHARACTERS BEFORE WS-TAG-LOANID-START. 00662 IF WS-START >= LENGTH OF WS-XML-REQUEST 00663 EXIT 00664 END-IF 00665 COMPUTE WS-START = WS-START + LENGTH OF WS-TAG-LOANID-START. 00666 INSPECT WS-XML-REQUEST 00667 TALLYING WS-END 00668 FOR CHARACTERS BEFORE WS-TAG-LOANID-END. 00669 IF WS-END <= WS-START 00670 EXIT 00671 END-IF 00672 COMPUTE WS-LEN = WS-END - WS-START. 00673 IF WS-LEN > 0 00674 MOVE WS-XML-REQUEST (WS-START + 1: WS-LEN) TO HRR-LOAN-ID 00675 END-IF 00676 DISPLAY 'EXTRACT-LOAN-ID: ' HRR-LOAN-ID 00677 EXIT. 00678 00679 ****************************************************************** 00680 ** Build XML response from HOST-BORROW-RESPONSE 00681 ****************************************************************** 00682 BUILD-XML-RESPONSE. 00683 MOVE SPACES TO WS-XML-RESPONSE. 00684 IF WS-REQUEST-TYPE = 'ACTIVE' 00685 MOVE 1 TO WS-PTR 00686 STRING 00687 '<HostActiveLoansByUserResponse ' DELIMITED BY SIZE 00688 ' xmlns="http://company.com/library/host/schema">' 00689 DELIMITED BY SIZE 00690 '<statusCode>' DELIMITED BY SIZE 00691 FUNCTION TRIM(HAU-STATUS-CODE) DELIMITED BY SIZE 00692 '</statusCode>' DELIMITED BY SIZE 00693 '<message>' DELIMITED BY SIZE 00694 FUNCTION TRIM(HAU-MESSAGE) DELIMITED BY SIZE 00695 '</message>' DELIMITED BY SIZE 00696 '<userId>' DELIMITED BY SIZE 00697 FUNCTION TRIM(HAU-USER-ID-R) DELIMITED BY SIZE 00698 '</userId>' DELIMITED BY SIZE 00699 INTO WS-XML-RESPONSE WITH POINTER WS-PTR 00700 END-STRING 00701 MOVE 1 TO WS-INDEX 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 14 0 LINE SOURCE LISTING 000702 PERFORM UNTIL WS-INDEX > HAU-LOAN-COUNT 00703 STRING 00704 '<loan>' DELIMITED BY SIZE 00705 '<loanId>' DELIMITED BY SIZE 00706 FUNCTION TRIM(HAU-LOAN-ID (WS-INDEX)) 00707 DELIMITED BY SIZE 00708 '</loanId>' DELIMITED BY SIZE 00709 '<bookId>' DELIMITED BY SIZE 00710 FUNCTION TRIM(HAU-BOOK-ID (WS-INDEX)) 00711 DELIMITED BY SIZE 00712 '</bookId>' DELIMITED BY SIZE 00713 '</loan>' DELIMITED BY SIZE 00714 INTO WS-XML-RESPONSE WITH POINTER WS-PTR 00715 END-STRING 00716 ADD 1 TO WS-INDEX 00717 END-PERFORM 00718 STRING 00719 '</HostActiveLoansByUserResponse>' DELIMITED BY SIZE 00720 INTO WS-XML-RESPONSE WITH POINTER WS-PTR 00721 END-STRING 00722 ELSE 00723 IF WS-REQUEST-TYPE = 'RETURN' 00724 STRING 00725 '<HostReturnResponse ' DELIMITED BY SIZE 00726 ' xmlns="http://company.com/library/host/schema">' 00727 DELIMITED BY SIZE 00728 '<loan>' DELIMITED BY SIZE 00729 '<loanId>' DELIMITED BY SIZE 00730 HRR-LOAN-ID-R DELIMITED BY SIZE 00731 '</loanId>' DELIMITED BY SIZE 00732 '<user>' DELIMITED BY SIZE 00733 '<id>' DELIMITED BY SIZE 00734 HRR-USER-ID-R DELIMITED BY SIZE 00735 '</id>' DELIMITED BY SIZE 00736 '</user>' DELIMITED BY SIZE 00737 '<book>' DELIMITED BY SIZE 00738 '<id>' DELIMITED BY SIZE 00739 HRR-BOOK-ID-R DELIMITED BY SIZE 00740 '</id>' DELIMITED BY SIZE 00741 '</book>' DELIMITED BY SIZE 00742 '</loan>' DELIMITED BY SIZE 00743 '<statusCode>' DELIMITED BY SIZE 00744 FUNCTION TRIM(HRR-STATUS-CODE) DELIMITED BY SIZE 00745 '</statusCode>' DELIMITED BY SIZE 00746 '<message>' DELIMITED BY SIZE 00747 FUNCTION TRIM(HRR-MESSAGE) DELIMITED BY SIZE 00748 '</message>' DELIMITED BY SIZE 00749 '</HostReturnResponse>' DELIMITED BY SIZE 00750 INTO WS-XML-RESPONSE 00751 END-STRING 00752 ELSE 00753 STRING 00754 '<HostBorrowResponse ' DELIMITED BY SIZE 00755 ' xmlns="http://company.com/library/host/schema">' 00756 DELIMITED BY SIZE 00757 '<loan>' DELIMITED BY SIZE 1CICS 7.5.0 COMMAND LANGUAGE TRANSLATOR TIME 16.37 DATE 4 APR 26 PAGE 15 0 LINE SOURCE LISTING 000758 '<loanId>' DELIMITED BY SIZE 00759 HBR-LOAN-ID DELIMITED BY SIZE 00760 '</loanId>' DELIMITED BY SIZE 00761 '<user>' DELIMITED BY SIZE 00762 '<id>' DELIMITED BY SIZE 00763 HBR-USER-ID-R DELIMITED BY SIZE 00764 '</id>' DELIMITED BY SIZE 00765 '</user>' DELIMITED BY SIZE 00766 '<book>' DELIMITED BY SIZE 00767 '<id>' DELIMITED BY SIZE 00768 HBR-BOOK-ID-R DELIMITED BY SIZE 00769 '</id>' DELIMITED BY SIZE 00770 '</book>' DELIMITED BY SIZE 00771 '</loan>' DELIMITED BY SIZE 00772 '<statusCode>' DELIMITED BY SIZE 00773 FUNCTION TRIM(HBR-STATUS-CODE) DELIMITED BY SIZE 00774 '</statusCode>' DELIMITED BY SIZE 00775 '<message>' DELIMITED BY SIZE 00776 FUNCTION TRIM(HBR-MESSAGE) DELIMITED BY SIZE 00777 '</message>' DELIMITED BY SIZE 00778 '</HostBorrowResponse>' DELIMITED BY SIZE 00779 INTO WS-XML-RESPONSE 00780 END-STRING 00781 END-IF 00782 END-IF. 00783 MOVE SPACES TO RSP-DATA. 00784 MOVE WS-XML-RESPONSE TO RSP-DATA. 00785 EXIT. 00786 00787 END PROGRAM LIBMQCIC. 0NO MESSAGES PRODUCED BY TRANSLATOR. 0TRANSLATION TIME:- 0.00 MINS.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 13s

По этому логу у тебя **реальная причина падения — не CICS-translator**, а **JES2 “output limit exceeded” → ABEND S722**.

### Что означает S722 в твоём случае

Ключевые строки:

- `$HASP375 CBLMQCIX ESTIMATED LINES EXCEEDED`
    
- `IEF450I ... COBOL - ABEND=S722`
    

Это типичная ситуация: **JES2 оценил, что JOB/STEP произведёт больше строк SYSOUT, чем разрешено лимитами (LINES / OUTLIM / лимит класса/партитишна)** и **завалил шаг компиляции**.

У тебя в статистике: **5,098 SYSOUT PRINT RECORDS** — а лимит мог быть, например, 2,000 или 5,000 (часто ставят маленький лимит на dev/учебных системах).

---

## Как починить (2 пути)

### Путь A (самый быстрый): поднять лимит вывода

В зависимости от того, что у вас разрешено в JES2/PROC, варианты:

1. На JOB:
    

//CBLMQCIX JOB ...,MSGCLASS=H,MSGLEVEL=(1,1)

(поставить MSGCLASS/SYSOUT класс, где лимит выше)

2. Добавить JOBPARM LINES (если разрешено):
    

/*JOBPARM LINES=20000

3. На конкретных DD поставить OUTLIM= (если у вас используется):
    

//SYSPRINT DD SYSOUT=*,OUTLIM=20000  
//SYSOUT   DD SYSOUT=*,OUTLIM=20000

> Какой из вариантов сработает — зависит от вашей инсталляции (часто самый рабочий — **другой SYSOUT/MSGCLASS**).

---

### Путь B (правильный для компиляций): резко уменьшить листинги

Сейчас у тебя translator печатает много (у тебя в “OPTIONS IN EFFECT” видно `SOURCE`, `SEQ`, `LINECOUNT(60)` и т.д.), плюс COBOL компилятор обычно тоже печатает листинг/кросс-реф.

Что можно сделать:

#### 1) Убрать листинг CICS translator

В SYSIN для translator убери `SOURCE` и/или попроси “no listing”.  
Например вместо:

CBL SQL OFFSET TEST NOXREF NOMAP

сделай (идея):

CBL SQL NOOFFSET TEST NOXREF NOMAP NOSOURCE

_Точное имя опции зависит от вашего translator-а, но смысл — отключить “source listing”._

#### 2) Убрать “тяжёлые” листинги у COBOL

В компиляторе отключить:

- XREF
    
- OFFSET
    
- LIST/SOURCE (если есть)
    
- MAP / PMAP / PDUMP и т.п.
    

И/или направить компиляторский листинг не в SYSOUT, а в dataset (если политика позволяет), чтобы не забивать spool.

---

## Отдельно: сообщение про DFHAPIR (пока не критично, но надо поправить)

Это:

`IEF764I ... PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND.`

Обычно значит: в шаге translator-а подключён **PARMLIB/DFHPARM**, но dataset **не содержит member DFHAPIR** (или не тот HLQ/не та библиотека).

Что проверить в JCL/PROC шага TRANSL:

- есть ли `//DFHPARM DD DISP=SHR,DSN=...SDFHPARM` (или аналог)
    
- правильный ли DSN CICS TS 7.5 (где лежит DFHAPIR)
    
- либо убрать/исправить PARMLIB-настройку, если она вам не нужна
    

Но важно: **TRANSL у тебя прошёл RC=00**, так что это **не причина ABEND**, просто “грязь” в настройке.

---

## Мини-диагностика “чтобы быстро понять, что именно лимитит”

1. Посмотри JOB card / PROC: есть ли `LINES=...` или `OUTLIM=...`
    
2. Посмотри, какой `MSGCLASS` / `SYSOUT class` используется
    
3. На системе часто можно узнать лимиты для класса у JES2/операторов (но обычно проще переключить SYSOUT класс)
    

---

Если хочешь — вставь сюда **JCL (JOB + шаг TRANSL/COBOL DD-шки SYSPRINT/SYSOUT/CEEMSG/...)** и я скажу **конкретно куда поставить** `MSGCLASS/SYSOUT/OUTLIM` и какие опции отключить, чтобы гарантированно уйти от S722.

  

1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:42:03 Page 1 0Invocation parameters: SQL 0PROCESS(CBL) statements: CBL CICS SQL NOXREF NOMAP NOOFFSET NOSOURCE Process rent,nodynam 0Options in effect: NOADATA ADV AFP(NOVOLATILE) QUOTE ARCH(10) ARITH(COMPAT) NOAWO NOBLOCK0 BUFSIZE(4096) CICS CODEPAGE(1140) NOCOMPILE(S) CONDCOMP(NOSKIPSRC) NOCOPYLOC NOCOPYRIGHT NOCURRENCY DATA(31) DBCS NODECK NODEFINE NODIAGTRUNC DISPSIGN(COMPAT) NODLL NODUMP NODYNAM NOEXIT NOEXPORTALL NOFASTSRT FLAG(I,I) NOFLAGSTD HGPR(PRESERVE) NOINITCHECK NOINITIAL INLINE INTDATE(ANSI) NOINVDATA NOJAVAIOP LANGUAGE(EN) LINECOUNT(60) NOLIST LP(32) NOLSACHECK NOMAP MAXPCF(100000) NOMDECK NONAME NSYMBOL(NATIONAL) NONUMBER NONUMCHECK NUMPROC(NOPFD) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:42:03 Page 2 0 OBJECT NOOFFSET OPTIMIZE(0) OUTDD(SYSOUT) NOPARMCHECK PGMNAME(COMPAT) QUALIFY(COMPAT) RENT RMODE(AUTO) NORULES NOSERVICE SEQUENCE SMARTBIN(NONAMES) NOSOURCE SPACE(1) SQL SQLCCSID NOSQLIMS NOSSRANGE NOSTGOPT SUPPRESS NOTERM NOTEST(NODWARF,NOSOURCE,NOSEPARATE) NOTHREAD TRUNC(STD) TUNE(10) NOVBREF VLR(STANDARD) VSAMOPENFS(COMPAT) NOWORD XMLPARSE(XMLSS) NOXREF ZWB IGYOS4077-I DSNH4790I DSNHPSRV DSNHDECP HAS CCSID 1047 IN EFFECT IGYOS4078-W DSNH4791I DSNHPSRV CCSID 1140 IS USED TO PROCESS SQL, BUT DSNHDECP HAS EBCDIC CCSID 1047 IN EFFECT IGYOS4077-I DSNH4760I DSNHPSRV THE DB2 SQL COPROCESSOR IS USING THE LEVEL 2 INTERFACE UNDER DB2 V13 -SQL Options in effect: ATTACH(TSO) CCSID(1140) CONNECT(2) DEC(15) DECP(DSNHDECP) SQLLEVEL(V13R1M504) ONEPASS PERIOD QUOTESQL STDSQL(NO) SQL(DB2) NOXREF NOSOURCE 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:42:03 Page 3 0 DSNHDECP LOADED FROM - (DSND10.DBDG.SDSNEXIT(DSNHDECP)) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:42:03 Page 4 0LineID Message code Message text IGYOS0230-S The "CICS" compiler option was in effect, but the compiler was unable to load the CICS integrated translator services module. All "EXEC CICS" statements were discarded. IGYDS0139-W Diagnostic messages were issued during processing of compiler options. These messages are located at the beginning of the listing. IGYSC0238-W "CICS" option was specified, but there is no "EXEC CICS" statement in the program. 3992 IGYPS2121-S "MQOD-DEFAULT" was not defined as a data-name. The statement was discarded. 3993 IGYPS2121-S "MQMD-DEFAULT" was not defined as a data-name. The statement was discarded. 3994 IGYPS2121-S "MQGMO-DEFAULT" was not defined as a data-name. The statement was discarded. 3995 IGYPS2121-S "MQPMO-DEFAULT" was not defined as a data-name. The statement was discarded. 4013 IGYPS2121-S "WS-REQ-QUEGGUE" was not defined as a data-name. The statement was discarded. 4660 IGYSC0208-I DSNH050I DSNHPSRV WARNINGS HAVE BEEN SUPPRESSED DUE TO LACK OF TABLE DECLARATIONS -Messages Total Informational Warning Error Severe Terminating 0Printed: 12 3 3 6 -* Statistics for COBOL program LIBMQCIC: * Source records = 5441 * Data Division statements = 2880 * Procedure Division statements = 308 * Generated COBOL statements = 215 * Program complexity factor = 546 0End of compilation 1, program LIBMQCIC, highest severity 12. 0Return code 12

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 16s

По логам у тебя **две разные проблемы**, и они “склеились” в одну картину:

## 1) ABEND S722 + “ESTIMATED LINES EXCEEDED” (JES2)

В joblog:

- `$HASP375 ... ESTIMATED LINES EXCEEDED`
    
- `ABEND=S722`
    

Это почти всегда означает: **лимит на объём SYSOUT/спула (кол-во строк/страниц) для класса/партии**. Т.е. компиляция/трансляция могла идти, но как только оценка вывода превысила лимит — JES прибил step.

### Что делать

- Максимально **урезать листинги**:
    
    - Для CICS translator: `NOLIST, NOXREF, NOMAP` (и не печатать SOURCE, если не надо).
        
    - Для COBOL: `NOLIST, NOSOURCE, NOXREF, NOOFFSET` (как у тебя сейчас — это правильно).
        
    - Для DB2: тоже `NOSOURCE, NOXREF`.
        
- Если листинг всё же нужен — попросить ops/админа:
    
    - либо **увеличить лимит** (output limit / spool limit) для твоего job class,
        
    - либо дать другой класс, где лимит выше.
        

---

## 2) COBOL RC=12: CICS integrated translator не подгрузился + MQ “DEFAULT” не определены

### 2.1. Критично: `IGYOS0230-S` (CICS option, но нет integrated translator services)

Сообщение:

> The "CICS" compiler option was in effect, but the compiler was unable to load the CICS integrated translator services module. All "EXEC CICS" statements were discarded.

Это значит:

- Ты компилируешь с опцией **`CICS`** (интегрированный транслятор),
    
- но в **STEPLIB / доступных LOADLIB** нет CICS-модуля интегрированной трансляции (или он недоступен/не того релиза),
    
- поэтому компилятор **выкинул все `EXEC CICS`** и дальше пишет “EXEC CICS нет”:
    

> `IGYSC0238-W "CICS" option was specified, but there is no "EXEC CICS" statement in the program.`

Это “вторичное” — потому что EXEC CICS он сам же и выбросил.

#### Два правильных пути (выбирай один)

**Путь A (классика и чаще всего проще): отдельный CICS translator step, а COBOL — без `CICS`**

- STEP1: `DFHECP1` (или ваш CICS translator proc) — делает трансляцию
    
- STEP2: COBOL compile **с `NOCICS`** (или просто без `CICS`)
    
- STEP3: linkedit, bind и т.д.
    

У тебя в логе уже видно TRANSL step и листинг “CICS COMMAND LANGUAGE TRANSLATOR” — т.е. этот путь у тебя **уже почти работает**. Тогда **не надо** включать `CICS` на компиляции — иначе ты пытаешься использовать второй механизм.

**Путь B: интегрированный CICS translator (опция `CICS`), но тогда нужно обеспечить правильные библиотеки**  
Нужно, чтобы в compile step:

- **STEPLIB** включал CICS load library вашего релиза (обычно `...SDFHLOAD`)
    
- и часто ещё **SYSLIB** для copybook’ов CICS (например `...SDFHCOB` / `...SDFHMAC` — как принято у вас)
    

(Конкретные DSN зависят от вашего HLQ и релиза CICS, но смысл: **подложить CICS runtime/translator модули в STEPLIB**.)

---

### 2.2. MQ “DEFAULT” не определены: `MQOD-DEFAULT`, `MQMD-DEFAULT`, `MQGMO-DEFAULT`, `MQPMO-DEFAULT`

Ошибки:

- `"MQOD-DEFAULT" was not defined as a data-name` и аналогичные
    

Это почти всегда означает одно из двух:

1. **MQ copybook’и не подключились** (COPY не нашёлся / не тот library в SYSLIB)  
    Тогда структуры/константы из `CMQ*` просто не объявлены → `MQOD-DEFAULT` не существует.
    
2. Подключился **не тот вариант copybook’а** (редко, но бывает при конфликте версий/языка)
    

✅ Проверь в compile step **SYSLIB**:

- должен быть датасет с MQ COBOL copybooks (у IBM MQ это обычно отдельная библиотека типа `SCSQCOBC` или похожая по соглашениям у вас).
    
- плюс твои application copybooks.
    

Также обрати внимание: у тебя `COPY CMQV / CMQODV / CMQMDV / CMQGMOV / CMQPMOV`.  
Если хоть один из них не находится — дефолты тоже не появятся.

---

### 2.3. Отдельно: явная опечатка

Сообщение:

- `"WS-REQ-QUEGGUE" was not defined as a data-name`
    

Это уже не про библиотеки. Это **опечатка в исходнике** (QUEGGUE вместо QUEUE). Исправить.

---

## Рекомендованный “быстрый фикс” (самый практичный)

Если твоя цель — просто собрать и запустить, я бы сделал так:

1. **Оставь отдельный CICS translator step (DFHECP1)**, раз он у тебя уже есть и даёт нормальный листинг.
    
2. В COBOL compile step **убери `CICS`** (то есть компилируй уже “переведённый” код).
    
3. В compile step добавь в **SYSLIB** библиотеку MQ copybooks (где лежат `CMQ*`), иначе `MQOD-DEFAULT`не появится.
    
4. Исправь `WS-REQ-QUEGGUE` → `WS-REQ-QUEUE`.
    
5. Чтобы не ловить S722:
    
    - оставь `NOLIST/NOSOURCE/NOXREF` на compile,
        
    - и/или урежь листинг translator,
        
    - и только если нужно — повышай лимит output у класса.
        

---

Если хочешь, кинь сюда **JCL PROC** (TRANSL/COBOL step) с DD’шками `STEPLIB` и `SYSLIB` (можно замазать HLQ), и я скажу **точно**, чего не хватает: где подключить `SDFHLOAD` (если идёшь через integrated), и какой именно `SYSLIB` нужен для MQ copybooks в вашем окружении.

  

1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:45:20 Page 1 0Invocation parameters: SQL 0PROCESS(CBL) statements: CBL SQL NOXREF NOMAP NOOFFSET NOSOURCE Process rent,nodynam 0Options in effect: NOADATA ADV AFP(NOVOLATILE) QUOTE ARCH(10) ARITH(COMPAT) NOAWO NOBLOCK0 BUFSIZE(4096) NOCICS CODEPAGE(1140) NOCOMPILE(S) CONDCOMP(NOSKIPSRC) NOCOPYLOC NOCOPYRIGHT NOCURRENCY DATA(31) DBCS NODECK NODEFINE NODIAGTRUNC DISPSIGN(COMPAT) NODLL NODUMP NODYNAM NOEXIT NOEXPORTALL NOFASTSRT FLAG(I,I) NOFLAGSTD HGPR(PRESERVE) NOINITCHECK NOINITIAL INLINE INTDATE(ANSI) NOINVDATA NOJAVAIOP LANGUAGE(EN) LINECOUNT(60) NOLIST LP(32) NOLSACHECK NOMAP MAXPCF(100000) NOMDECK NONAME NSYMBOL(NATIONAL) NONUMBER NONUMCHECK NUMPROC(NOPFD) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:45:20 Page 2 0 OBJECT NOOFFSET OPTIMIZE(0) OUTDD(SYSOUT) NOPARMCHECK PGMNAME(COMPAT) QUALIFY(COMPAT) RENT RMODE(AUTO) NORULES NOSERVICE SEQUENCE SMARTBIN(NONAMES) NOSOURCE SPACE(1) SQL SQLCCSID NOSQLIMS NOSSRANGE NOSTGOPT SUPPRESS NOTERM NOTEST(NODWARF,NOSOURCE,NOSEPARATE) NOTHREAD TRUNC(STD) TUNE(10) NOVBREF VLR(STANDARD) VSAMOPENFS(COMPAT) NOWORD XMLPARSE(XMLSS) NOXREF ZWB IGYOS4077-I DSNH4790I DSNHPSRV DSNHDECP HAS CCSID 1047 IN EFFECT IGYOS4078-W DSNH4791I DSNHPSRV CCSID 1140 IS USED TO PROCESS SQL, BUT DSNHDECP HAS EBCDIC CCSID 1047 IN EFFECT IGYOS4077-I DSNH4760I DSNHPSRV THE DB2 SQL COPROCESSOR IS USING THE LEVEL 2 INTERFACE UNDER DB2 V13 -SQL Options in effect: ATTACH(TSO) CCSID(1140) CONNECT(2) DEC(15) DECP(DSNHDECP) SQLLEVEL(V13R1M504) ONEPASS PERIOD QUOTESQL STDSQL(NO) SQL(DB2) NOXREF NOSOURCE 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 Date 04/04/2026 Time 16:45:20 Page 3 0 DSNHDECP LOADED FROM - (DSND10.DBDG.SDSNEXIT(DSNHDECP)) 1PP 5655-EC6 IBM Enterprise COBOL for z/OS 6.4.0 P260220 LIBMQCIC Date 04/04/2026 Time 16:45:20 Page 4 0LineID Message code Message text IGYDS0139-W Diagnostic messages were issued during processing of compiler options. These messages are located at the beginning of the listing. 3992 IGYPS2121-S "MQOD-DEFAULT" was not defined as a data-name. The statement was discarded. 3993 IGYPS2121-S "MQMD-DEFAULT" was not defined as a data-name. The statement was discarded. 3994 IGYPS2121-S "MQGMO-DEFAULT" was not defined as a data-name. The statement was discarded. 3995 IGYPS2121-S "MQPMO-DEFAULT" was not defined as a data-name. The statement was discarded. 4013 IGYPS2121-S "WS-REQ-QUEGGUE" was not defined as a data-name. The statement was discarded. 4660 IGYSC0208-I DSNH050I DSNHPSRV WARNINGS HAVE BEEN SUPPRESSED DUE TO LACK OF TABLE DECLARATIONS -Messages Total Informational Warning Error Severe Terminating 0Printed: 10 3 2 5 -* Statistics for COBOL program LIBMQCIC: * Source records = 5441 * Data Division statements = 2880 * Procedure Division statements = 308 * Generated COBOL statements = 215 * Program complexity factor = 546 0End of compilation 1, program LIBMQCIC, highest severity 12. 0Return code 12

  

Denkvorgang abgeschlossen

Nachgedacht für 21s

По твоим листингам тут **две разные проблемы** (CICS-транслятор и MQ copybooks) + **одна банальная опечатка**.

---

## 1) Почему в первом прогоне был ABEND S722 на шаге COBOL после TRANSL

В JES-логе:

- `TRANSL ... PARMLIB READ FAILED - MEMBER DFHAPIR NOT FOUND`
    
- дальше `$HASP375 ... LINES EXCEEDED`
    
- и `COBOL - ABEND=S722`
    

**Смысл:** CICS-транслятор (шаг TRANSL) пытается прочитать **parmlib member DFHAPIR**, но не находит его в библиотеке, которую ты ему подсовываешь как “PARMLIB/DFHEIMOD”. После этого вывод разрастается, spool превышает лимит и компиляция падает S722 (обычно “out of spool / output limit / region”, зависит от настроек JES/TSO).

✅ Что делать:

- Либо **подключить правильную CICS parmlib**, где реально есть member `DFHAPIR` (часто это что-то вроде `…SDFHPARM`), например через нужный DD в процедуре/джобе (установочные имена зависят от твоего PROC).
    
- Либо если APIR тебе не нужен — **убрать использование DFHAPIR/APIR** из параметров транслятора (чтобы он не искал этот member).
    

> Практически: открой PROC, который выполняет TRANSL (DFHCOB/DFH$…/кастомный) и посмотри, **какой DD указывает на PARMLIB** для translator’а, и что там реально за dataset. В ISPF 3.4 проверь: есть ли в этой библиотеке member `DFHAPIR`.

---

## 2) Почему компилятор ругался: _“CICS option was in effect … unable to load the CICS integrated translator services module”_

Сообщение:

`IGYOS0230-S The "CICS" compiler option was in effect, but the compiler was unable to load the CICS integrated translator services module. All "EXEC CICS" statements were discarded.`

Это бывает, когда ты **компилируешь с опцией CICS**, но в STEPLIB/конкатенации нет модулей интегрированного CICS translator’а.

✅ Правильные варианты:

- **Вариант A (классический):** отдельный шаг `TRANSL`, затем компиляция **с NOCICS** (то, что ты сделал во втором прогоне — правильно).
    
- **Вариант B (интегрированный translator):** компиляция с `CICS`, но тогда в JCL должны быть корректно подключены CICS библиотеки (обычно CICS loadlib типа `SDFHLOAD`) так, чтобы компилятор смог load’нуть translator services module.
    

Раз ты уже гоняешь отдельный TRANSL — **оставляй NOCICS на компиляции**, и проблема исчезает (как во втором листинге).

---

## 3) Главная текущая причина RC=12: MQOD-DEFAULT / MQMD-DEFAULT / MQGMO-DEFAULT / MQPMO-DEFAULT “not defined”

Сообщения:

- `"MQOD-DEFAULT" was not defined as a data-name.`
    
- `"MQMD-DEFAULT" was not defined...`
    
- `"MQGMO-DEFAULT" ...`
    
- `"MQPMO-DEFAULT" ...`
    

Это почти всегда означает одно из двух:

### 3.1. Не те copybooks MQ (ты подключил `…V`-варианты)

В исходнике у тебя:

- `COPY CMQV.`
    
- `COPY CMQODV.`
    
- `COPY CMQMDV.`
    
- `COPY CMQGMOV.`
    
- `COPY CMQPMOV.`
    

А **имена `MQOD-DEFAULT`, `MQMD-DEFAULT`, `MQGMO-DEFAULT`, `MQPMO-DEFAULT` обычно определены в copybooks без суффикса `V`** (типа `CMQOD`, `CMQMD`, `CMQGMO`, `CMQPMO`).

✅ Быстрый фикс в коде (самый вероятный):

- заменить `CMQODV → CMQOD`
    
- `CMQMDV → CMQMD`
    
- `CMQGMOV → CMQGMO`
    
- `CMQPMOV → CMQPMO`
    

(а `CMQV` обычно оставляют как есть)

### 3.2. SYSLIB не содержит библиотеку MQ copybooks

Даже если имена правильные, если в JCL на компиляции `SYSLIB` не конкатенирован с MQ COPYLIB, компилятор “увидит” только твой исходник и твои локальные копибуки.

✅ Проверь в compile step:

- есть ли `//SYSLIB DD DSN=...SCSQCOBC` или `...SCSQCOPY` (у IBM MQ на z/OS это типичные библиотеки copybooks),
    
- и что этот DD реально участвует именно в **COBOL compile step** (не только в TRANSL).
    

---

## 4) Отдельно: опечатка в имени переменной

Сообщение:

`"WS-REQ-QUEGGUE" was not defined as a data-name.`

У тебя объявлено: `WS-REQ-QUEUE`.

Значит в одном месте в коде реально написано `WS-REQ-QUEGGUE` (GG вместо UE).

✅ Исправь опечатку — это отдельная причина ошибки компиляции.

---

# Мини-чеклист “чтобы завелось”

1. **TRANSL**: убрать/починить `DFHAPIR` (правильная CICS parmlib или убрать APIR).
    
2. **COBOL compile**: если TRANSL отдельный — компилировать **NOCICS** (как у тебя во втором прогоне).
    
3. **MQ copybooks**:
    
    - либо поменять `CMQODV/CMQMDV/CMQGMOV/CMQPMOV` на `CMQOD/CMQMD/CMQGMO/CMQPMO`,
        
    - и/или убедиться, что `SYSLIB` содержит MQ copybook library (`SCSQCOBC/SCSQCOPY`).
        
4. **Исправить WS-REQ-QUEGGUE** → `WS-REQ-QUEUE`.
    

Если хочешь — кинь кусок твоего **JCL/PROC** (только DD’шки шагов TRANSL и COBOL + SYSLIB/STEPLIB), и я точечно скажу: _какой DD добавить/куда конкатенировать_, чтобы и DFHAPIR, и MQ copybooks подхватились.

  

какие есть возможности конфигурировать cobol программы для cics транзакций через скрипты

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Есть несколько уровней, где **“конфигурация COBOL-программ под CICS транзакции”** делается _скриптами/джобами_ (JCL, REXX, CLIST, ISPF, pipeline), и это обычно выглядит как **автоматизация сборки + генерация артефактов + деплой/обновление ресурсов CICS**.

Ниже — практическая «карта возможностей», что именно можно конфигурировать и чем это обычно делается.

---

## 1) Конфигурация через сборку (скриптами) — самый частый путь

### A) Управление поведением через **compile-time** define’ы

- **COBOL conditional compilation**: `>>IF/>>ELSE/>>END-IF` (в Enterprise COBOL) + прокидывание символов сборки из JCL.
    
- Подходит для: включения/выключения логики (trace, debug, разные endpoints, разные очереди MQ, разные DB2 планы), “DEV/TEST/PROD”.
    

**Типовой паттерн:** в JCL выставляешь `SYSLIB/COBOL COPTS` или `PROCESS`/`CBL` + символы, а код содержит `>>IF ENV='PROD'`.

### B) Макро-подстановка / генерация копибуков

- Генерация `COPY`-книг (например, `COPY ENVPARMS`, `COPY MQCFG`) по шаблону перед компиляцией.
    
- Делают REXX/DFSORT/IEBUPDTE/IDCAMS + простые текстовые подстановки.
    
- Хорошо, когда хочешь держать **один исходник**, а окружение меняется “снаружи”.
    

### C) Управление **CICS translator / DB2 coprocessor** параметрами из JCL

- Для CICS обычно есть 2 подхода:
    
    1. **Integrated translator** (компилятор с CICS option + доступный translator module)
        
    2. **Separate translate step** (классика: DFHEIT + потом компиляция)
        

Скриптами конфигурируется:

- какие библиотеки в `STEPLIB/SYSLIB` (CICS SDFHLOAD, SDFHCOB и т.д.)
    
- какой режим трансляции/листинг/опции (`CICS`, `EDF`, `SPIE`, `NATLANG`, `TABLE(DFHEITAB)` и т.п.)
    
- как стыкуется с DB2 SQL coprocessor.
    

> По твоему листингу видно типичную боль: **IGYOS0230-S “unable to load CICS integrated translator services module; EXEC CICS discarded”** — это прямо про то, что сборочный шаг/STEPLIB не подтянул нужные CICS модули. Это как раз “конфиг скриптами”.

---

## 2) Конфигурация через runtime-параметры (без перекомпиляции)

### A) **Файлы/параметрические датасеты** + DDNAME

- Например: `SELECT PARAMSFILE ASSIGN TO PARAMS ...`
    
- В CICS это часто делается через:
    
    - DFHRPL / LIBRARY concatenation (где лежит файл/таблица/табличка)
        
    - либо через **JCL в batch** (как у тебя), где `//PARAMS DD DISP=SHR,DSN=...`
        
- В online-CICS (под транзакцией) чаще читают **TDQ/TSQ**, DB2 таблицу настроек или MQ messages.
    

### B) Настройки в DB2 таблицах

- “таблица параметров” (key/value) для очередей, таймаутов, feature flags.
    
- Очень удобно: скриптом (SPUFI/DSNTEP2/REXX) обновляешь значения, код не трогаешь.
    

### C) Использование **CICS system variables / environment**

- Например, чтение `SYSID`, `APPLID`, `EIBTRNID`, `EIBTASKN`, `EIBTRMID` и т.п. для выбора поведения.
    
- Скриптами это не “настраивается”, но часто используется, чтобы один бинарь работал по-разному в разных регионах.
    

---

## 3) Конфигурация через CICS ресурсы (автодеплой скриптами)

Вот здесь “скрипты” особенно полезны, потому что ресурсы можно создавать/обновлять пакетно.

### A) CEDA/DFHCSDUP (batch) / RDO

- **CEDA DEFINE/INSTALL** (интерактивно)
    
- **DFHCSDUP** (batch utility) — позволяет скриптом:
    
    - DEFINE/ALTER/DELETE **PROGRAM, TRANSACTION, FILE, TDQUEUE, TSQUEUE, DB2CONN, DB2ENTRY, DB2TRAN, MQCONN/MQMONITOR (если используется), URIMAP, TCPIPSERVICE, WEBSERVICE, PIPELINE** и т.д.
        
- Это прям “инфраструктура как код” для CICS.
    

### B) CICSPlex SM / BAS

Если у тебя CPSM:

- можно управлять ресурсами через **BAS (Business Application Services)**, deployment bundles и т.п., что тоже автоматизируется.
    

### C) CMCI / scripts

- Через **CMCI (CICS Management Client Interface)** можно делать automation извне (скрипт дергает REST/HTTP и создает/меняет ресурсы).
    
- Это удобно для CI/CD пайплайна.
    

---

## 4) Что обычно конфигурируют именно “для транзакций”

В разрезе “CICS транзакция ↔ COBOL программа” чаще всего скриптами управляют:

1. **TRANSACTION** (TRN)
    
    - имя транзакции, приоритет, профили, security, timeout/priority, изоляция
        
2. **PROGRAM**
    
    - имя load module, residency, execution key (CICS/USER), reentrancy expectations, threadsafe (если relevant), библиотека/DFHRPL/начиная с CICS TS 5/6 — LIBRARY/Bundle
        
3. **DB2 ресурсы**
    
    - DB2CONN/ENTRY/TRAN, plan/package, authid, thread limits
        
4. **MQ / connectivity**
    
    - очереди обычно не как “CICS resource”, а как runtime/таблица/копибук,
        
    - но connectivity (если используешь CICS-MQ adapter/features) может иметь resource definitions
        
5. **WEB / URIMAP / TCPIPSERVICE / PIPELINE / WEBSERVICE**
    
    - если транзакция дергается по HTTP/SOAP/JSON.
        

---

## 5) Практический “минимальный набор” скриптов/джобов в проекте

Если ты хочешь реально “скриптами конфигурировать” как в нормальном пайплайне, обычно делают 4 артефакта:

1. **BUILD JCL**
    
    - translate (если separate)
        
    - compile (COBOL + SQL coprocessor)
        
    - linkedit (include MQ stubs/DB2, CICS stub if needed)
        
    - bind (DB2 package/plan)
        
2. **DEPLOY JCL**
    
    - копирование load module в target loadlib
        
    - обновление DBRM/PDS
        
    - обновление таблиц параметров (DB2) или generation of copybooks
        
3. **CICS RDO deploy (DFHCSDUP)**
    
    - создать/обновить PROGRAM/TRANSACTION (+ остальные нужные ресурсы)
        
4. **SMOKE / verify**
    
    - CEMT INQ PROGRAM/TRANSACTION
        
    - тестовая транзакция / batch driver / MQ ping
        

---

## 6) Связь с твоими логами (важно)

- **S722** в joblog + “estimated lines exceeded” часто означает, что что-то ушло в огромный output или цикл, но у тебя параллельно есть более ключевое:
    
- **IGYOS0230-S: CICS option in effect, but compiler unable to load CICS integrated translator services module; EXEC CICS discarded.**  
    Это на 99% лечится **скриптами сборки**: правильный `STEPLIB`/`SYSLIB` на CICS translator modules (SDFHLOAD/SDFHCOB* зависит от установки) или переход на **separate translate step**.
    

---

Если хочешь — я могу прямо из твоего кейса предложить **2 эталонных пайплайна JCL**:

1. separate translate (DFHEIT) → compile → linkedit → bind
    
2. integrated translator → compile → linkedit → bind
    

…и указать, где именно в JCL должны быть CICS/DB2/MQ библиотеки, чтобы не ловить IGYOS0230-S и чтобы `MQOD-DEFAULT`/`MQMD-DEFAULT` подтянулись из `COPY CMQV/CMQ*V` (это уже вопрос SYSLIB concatenation и правильных copybooks для MQ).

  

собери по этим пунктам 3) Конфигурация через CICS ресурсы (автодеплой скриптами) Вот здесь “скрипты” особенно полезны, потому что ресурсы можно создавать/обновлять пакетно. A) CEDA/DFHCSDUP (batch) / RDO • CEDA DEFINE/INSTALL (интерактивно) • DFHCSDUP (batch utility) — позволяет скриптом: • DEFINE/ALTER/DELETE PROGRAM, TRANSACTION, FILE, TDQUEUE, TSQUEUE, DB2CONN, DB2ENTRY, DB2TRAN, MQCONN/MQMONITOR (если используется), URIMAP, TCPIPSERVICE, WEBSERVICE, PIPELINE и т.д. • Это прям “инфраструктура как код” для CICS. B) CICSPlex SM / BAS Если у тебя CPSM: • можно управлять ресурсами через BAS (Business Application Services), deployment bundles и т.п., что тоже автоматизируется. C) CMCI / scripts • Через CMCI (CICS Management Client Interface) можно делать automation извне (скрипт дергает REST/HTTP и создает/меняет ресурсы). • Это удобно для CI/CD пайплайна. ⸻ runbook_cics_config.md с примерами и дай мне ссылку

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Готово — собрал runbook по пунктам (CEDA/DFHCSDUP/RDO, CPSM/BAS, CMCI) с примерами SYSIN, JCL и curl-шаблонами.

Скачать runbook_cics_config.md 

  

где определен MQOD-DEFAULT

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

`MQOD-DEFAULT` **не “где-то в CICS/COBOL”**, а **в IBM MQ COBOL copybook**.

Обычно он определён **в copybook `CMQODV`** (это _Object Descriptor_), примерно как:

- `01 MQOD-DEFAULT.` … (структура MQOD с предустановленными значениями)
    
- аналогично:
    
    - `MQMD-DEFAULT` в `CMQMDV`
        
    - `MQGMO-DEFAULT` в `CMQGMOV`
        
    - `MQPMO-DEFAULT` в `CMQPMOV`
        

### Почему у тебя “MQOD-DEFAULT was not defined…”

Почти всегда это значит: **COPY не подтянулся**, т.е. компилятор **не нашёл member `CMQODV` в SYSLIB**(или подтянул “не тот” member).

### Что проверить (быстро)

1. **Есть ли `CMQODV` в MQ copylib** (обычно это PDS/E типа `...SCSQCOB` или `...SCSQCOPY` — зависит от установки).
    
2. **В JCL compile step добавить этот датасет в `SYSLIB`** (или в `COPYLIB`, если у вас так принято), например:
    
    - `//SYSLIB DD DISP=SHR,DSN=MQM.Vxxx.SCSQCOB`
        
    - (и/или `...SCSQCOPY`)
        
3. Убедиться, что в сорсе реально есть строка:
    
    - `COPY CMQODV.`  
        и что она не “съедается” препроцессором/условной компиляцией.
        

Если скажешь, **какие DD у тебя в compile step (SYSLIB/COBOLLIB/… )** и **как называется MQ HLQ (CSQ…/MQM… )**, я точно подскажу, какой датасет надо добавить именно в твоей среде.

  

0LineID Message code Message text IGYDS0139-W Diagnostic messages were issued during processing of compiler options. These messages are located at the beginning of the listing. 3991 IGYPS2121-S "MQOD-DEFAULT" was not defined as a data-name. The statement was discarded. 3992 IGYPS2121-S "MQMD-DEFAULT" was not defined as a data-name. The statement was discarded. 3993 IGYPS2121-S "MQGMO-DEFAULT" was not defined as a data-name. The statement was discarded. 3994 IGYPS2121-S "MQPMO-DEFAULT" was not defined as a data-name. The statement was discarded. 4651 IGYSC0208-I DSNH050I DSNHPSRV WARNINGS HAVE BEEN SUPPRESSED DUE TO LACK OF TABLE DECLARATIONS -Messages Total Informational Warning Error Severe Terminating

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

`MQOD-DEFAULT` — это **не CICS** и не “встроенная” часть COBOL. Это **константа-структура IBM MQ**, которая определяется в **MQ COBOL copybook** для Object Descriptor.

Конкретно:

- **`MQOD-DEFAULT`** определяется в copybook **`CMQODV`** (там же определяется структура `MQOD-...` / поля `MQOD-*`).
    
- Аналогично:
    
    - `MQMD-DEFAULT` → **`CMQMDV`**
        
    - `MQGMO-DEFAULT` → **`CMQGMOV`**
        
    - `MQPMO-DEFAULT` → **`CMQPMOV`**
        

### Почему у тебя “не определён”

Если компилятор пишет `IGYPS2121-S "MQOD-DEFAULT" was not defined`, то почти всегда причина такая:

**COPY не был реально подставлен**, т.е. компилятор **не нашёл** `CMQODV` в SYSLIB-конкатенации (или нашёл “не тот” набор copybook’ов).

### Что проверить/починить (быстро)

1. Проверь, что member **CMQODV** реально существует в MQ copybook library (обычно что-то вроде `...SCSQCOBC`, имя HLQ зависит от установки MQ).
    
2. В JCL компиляции убедись, что в `//COBOL.SYSLIB DD` (или `//SYSLIB DD`) **есть** MQ библиотека с copybook’ами (и, при необходимости, DB2 + CICS copybook libs).
    
3. Самый простой тест: открой member `CMQODV` и найди строку вида:
    

- `01 MQOD-DEFAULT ...`  
    (она там должна быть).
    

Если скажешь, **какой у тебя MQ HLQ** (или покажешь `SYSLIB` concat из compile step), я подскажу точную DD-конкатенацию и где именно добавить `SCSQCOBC` (или её аналог в твоей системе).

  

****************************************************************** ** ** ** IBM MQ for z/OS ** ** ** ** FILE NAME: CMQODV ** ** ** ** DESCRIPTION: MQOD Structure -- Object descriptor ** ** ** ****************************************************************** ** @START_COPYRIGHT@ ** ** Statement: Licensed Materials - Property of IBM ** ** ** ** 5655-MQ9 ** ** (C) Copyright IBM Corporation. 1997, 2026 ** ** @END_COPYRIGHT@ ** ****************************************************************** ** ** ** FUNCTION: This file declares the structure MQOD, ** ** which is used by the main MQI. ** ** ** ** PROCESSOR: COBOL ** ** ** ****************************************************************** ** MQOD structure 10 MQOD. ** Structure identifier 15 MQOD-STRUCID PIC X(4) VALUE 'OD '. ** Structure version number 15 MQOD-VERSION PIC S9(9) BINARY VALUE 1. ** Object type 15 MQOD-OBJECTTYPE PIC S9(9) BINARY VALUE 1. ** Object name 15 MQOD-OBJECTNAME PIC X(48) VALUE SPACES. ** Object queue manager name 15 MQOD-OBJECTQMGRNAME PIC X(48) VALUE SPACES. ** Dynamic queue name 15 MQOD-DYNAMICQNAME PIC X(48) VALUE 'CSQ.*'. ** Alternate user identifier 15 MQOD-ALTERNATEUSERID PIC X(12) VALUE SPACES. ** Ver:1 ** ** Number of object records present 15 MQOD-RECSPRESENT PIC S9(9) BINARY VALUE 0. ** Number of local queues opened successfully 15 MQOD-KNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. ** Number of remote queues opened 15 MQOD-UNKNOWNDESTCOUNT PIC S9(9) BINARY VALUE 0. ** Number of queues that failed to open 15 MQOD-INVALIDDESTCOUNT PIC S9(9) BINARY VALUE 0. ** Offset of first object record from start of MQOD 15 MQOD-OBJECTRECOFFSET PIC S9(9) BINARY VALUE 0. ** Offset of first response record from start of MQOD 15 MQOD-RESPONSERECOFFSET PIC S9(9) BINARY VALUE 0. ** Address of first object record 15 MQOD-OBJECTRECPTR POINTER VALUE NULL. ** Address of first response record 15 MQOD-RESPONSERECPTR POINTER VALUE NULL. ** Ver:2 ** ** Alternate security identifier 15 MQOD-ALTERNATESECURITYID PIC X(40) VALUE LOW-VALUES. ** Resolved queue name 15 MQOD-RESOLVEDQNAME PIC X(48) VALUE SPACES. ** Resolved queue manager name 15 MQOD-RESOLVEDQMGRNAME PIC X(48) VALUE SPACES. ** Ver:3 ** ** Object long name 15 MQOD-OBJECTSTRING. ** Address of variable length string 20 MQOD-OBJECTSTRING-VSPTR POINTER VALUE NULL. ** Offset of variable length string 20 MQOD-OBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. ** Size of buffer 20 MQOD-OBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. ** Length of variable length string 20 MQOD-OBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. ** CCSID of variable length string 20 MQOD-OBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. ** Message Selector 15 MQOD-SELECTIONSTRING. ** Address of variable length string 20 MQOD-SELECTIONSTRING-VSPTR POINTER VALUE NULL. ** Offset of variable length string 20 MQOD-SELECTIONSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. ** Size of buffer 20 MQOD-SELECTIONSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. ** Length of variable length string 20 MQOD-SELECTIONSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. ** CCSID of variable length string 20 MQOD-SELECTIONSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. ** Resolved long object name 15 MQOD-RESOBJECTSTRING. ** Address of variable length string 20 MQOD-RESOBJECTSTRING-VSPTR POINTER VALUE NULL. ** Offset of variable length string 20 MQOD-RESOBJECTSTRING-VSOFFSET PIC S9(9) BINARY VALUE 0. ** Size of buffer 20 MQOD-RESOBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY VALUE 0. ** Length of variable length string 20 MQOD-RESOBJECTSTRING-VSLENGTH PIC S9(9) BINARY VALUE 0. ** CCSID of variable length string 20 MQOD-RESOBJECTSTRING-VSCCSID PIC S9(9) BINARY VALUE -3. ** Alias queue resolved object type 15 MQOD-RESOLVEDTYPE PIC S9(9) BINARY VALUE 0. ** Ver:4 ** ****************************************************************** ** End of CMQODV ** ******************************************************************

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 18s

`MQOD-DEFAULT` **не является “встроенным” именем COBOL** — это **константа (шаблон-структура)**, которую **определяет MQ COBOL copybook** для Object Descriptor.

### Где он должен быть определён

Обычно `MQOD-DEFAULT` определяется **в том же copybook, где описан MQOD**, т.е. в **`CMQODV`** (а `MQMD-DEFAULT` — в `CMQMDV`, `MQGMO-DEFAULT` — в `CMQGMOV`, `MQPMO-DEFAULT` — в `CMQPMOV`).

То есть в “правильной” поставке IBM MQ COBOL copybooks ты должен увидеть внутри `CMQODV` что-то вроде отдельного “default template” уровня (например `... MQOD-DEFAULT ...`) **помимо** самого `MQOD.`

### Почему у тебя “не определён”

В твоём фрагменте `CMQODV` видно только:

- `10 MQOD.`
    
- поля `MQOD-STRUCID`, `MQOD-VERSION`, …
    

Но **не видно блока `MQOD-DEFAULT`**. Значит одно из двух:

1. **В твоём `CMQODV` реально нет `MQOD-DEFAULT`** (урезанный/кастомный/другой релиз/не тот member).
    
2. Ты смотришь **не весь member** (а `MQOD-DEFAULT` может быть ниже по тексту, после описания полей/версий).
    

### Как проверить за 30 секунд на хосте

Самый прямой способ — просто поиск по PDS member:

- В ISPF: **3.14 Search-For** по датасету MQ copybooks (обычно что-то типа `...SCSQCOBC`), строка поиска: `MQOD-DEFAULT`
    
- Или открыть member `CMQODV` и сделать `F MQOD-DEFAULT`
    

Если **не находится**, значит твой `CMQODV` **не содержит** дефолт-структуру — тогда `MOVE MQOD-DEFAULT TO ...` закономерно падает с `IGYPS2121-S`.

### Что делать, если `MQOD-DEFAULT` реально отсутствует

Есть 2 рабочих варианта:

**Вариант A (правильный):** подключить _тот_ copybook (из правильной библиотеки/релиза), где `MQOD-DEFAULT` определён.  
Проверь, что в компиляции `SYSLIB` реально конкатенирован на MQ COBOL lib (обычно `hlq.SCSQCOBC`).

**Вариант B (быстрый обходной):** инициализировать MQOD вручную:

- `MOVE SPACES TO MQM-OBJECT-DESCRIPTOR`
    
- выставить минимум нужных полей: `MQOD-STRUCID`, `MQOD-VERSION`, `MQOD-OBJECTTYPE`, `MQOD-OBJECTNAME`, …  
    (это чуть муторнее, но снимает зависимость от `MQOD-DEFAULT`)
    

---

Если покажешь **конкатенацию SYSLIB** твоего compile step (JCL) и **хвост member `CMQODV`** (последние ~50 строк), я скажу точно: “у тебя не тот member” vs “default ниже по тексту” и какой датасет/мембер должен идти в SYSLIB первым.

  

Menu RefList Utilities Help ------------------------------------------------------------------------------ Search-For Utility Invalid DSN - qualifier Search String . . MQOD-DEFAULT ISPF Library: Project . . . Group . . . . . . . . . . . . . Type . . . . Member . . . (Blank or pattern for member selection list, "*" for all members) Other Partitioned, Sequential or VSAM Data Set: Data Set Name . . . 'CSQ920.SCSQC*' Volume Serial . . . (If not cataloged) Listing Data Set . . . S0W1.SRCHFOR.LIST Data Set Password . . (If Search-For data set password protected) Enter "/" to select option Execution Mode Output Mode Specify additional search strings 1 1. Foreground 1 1. View Mixed Mode 2. Batch 2. Browse Bypass selection list

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 45s

Судя по тому, что:

- компилятор ругается `MQOD-DEFAULT was not defined as a data-name`, и
    
- ты **не находишь строку `MQOD-DEFAULT`** поиском по MQ copybook’ам,
    

— у тебя в используемых COBOL copybook’ах IBM MQ **нет готового “дефолтного” group-item** `MQOD-DEFAULT` (аналог `MQOD_DEFAULT` часто есть в C, но в COBOL он _не обязан_ существовать как переменная/группа).

В твоём фрагменте `CMQODV` действительно определён **только** сам descriptor `MQOD` (поля `MQOD-STRUCID`, `MQOD-VERSION`, …), а отдельного `MQOD-DEFAULT` там не видно.

## Как правильно сделать “DEFAULT” в COBOL (2 рабочих паттерна)

### Вариант A (самый удобный): завести “DEFAULT”-структуру через `COPY ... REPLACING`

Идея: включить тот же copybook второй раз, но переименовать “корневое имя” структуры.

       01  MQOD-DEFAULT.  
           COPY CMQODV REPLACING ==MQOD== BY ==MQOD-DEFAULT==.  
  
       01  MQMD-DEFAULT.  
           COPY CMQMDV REPLACING ==MQMD== BY ==MQMD-DEFAULT==.  
  
       01  MQGMO-DEFAULT.  
           COPY CMQGMOV REPLACING ==MQGMO== BY ==MQGMO-DEFAULT==.  
  
       01  MQPMO-DEFAULT.  
           COPY CMQPMOV REPLACING ==MQPMO== BY ==MQPMO-DEFAULT==.

После этого твои строки:

       MOVE MQOD-DEFAULT  TO MQM-OBJECT-DESCRIPTOR.  
       MOVE MQMD-DEFAULT  TO MQM-MESSAGE-DESCRIPTOR.  
       MOVE MQGMO-DEFAULT TO MQM-GET-MESSAGE-OPTIONS.  
       MOVE MQPMO-DEFAULT TO MQM-PUT-MESSAGE-OPTIONS.

— начнут компилироваться, потому что `MQOD-DEFAULT` реально появится как data-name.

> Важно: точный текст для `REPLACING` зависит от того, как в copybook’е написано имя группы (у тебя это `10 MQOD.`). Обычно хватает `==MQOD==`, но если не сработает — делай замену по токену `==MQOD.==` / `==MQOD==` (в зависимости от формы в copybook’е).

### Вариант B: инициализировать “вручную”

Например:

       INITIALIZE MQM-OBJECT-DESCRIPTOR  
           REPLACING NUMERIC BY ZERO ALPHANUMERIC BY SPACES.  
       MOVE 'OD  '        TO MQOD-STRUCID OF MQM-OBJECT-DESCRIPTOR.  
       MOVE MQOD-VERSION-4 TO MQOD-VERSION OF MQM-OBJECT-DESCRIPTOR.

Но это дольше и легко забыть какое-то поле/версию.

## Почему твой Search-For не находит `MQOD-DEFAULT`

На скриншоте у тебя в поле DSN стоит `'CSQ920.SCSQC*'` и ISPF пишет _Invalid DSN - qualifier_ — **в Search-For нельзя так задавать DSN с wildcard в кавычках** (и часто вообще wildcard там не принимается как “список датасетов”).

Чтобы _точно_ проверить наличие/отсутствие `MQOD-DEFAULT`, делай так:

1. Узнай **точные имена** датасетов с copybook’ами MQ (обычно что-то вроде `CSQxxx.SCSQCOB*`, `...SCSQCOPY`, `...SCSQMACS` — зависит от установки).
    
2. В Search-For укажи **конкретный** DSN (без `*`), либо используй batch SRCHFOR/конкатенацию датасетов.
    

## Мини-диагноз по твоим листингам

- Ошибки `MQOD-DEFAULT/MQMD-DEFAULT/MQGMO-DEFAULT/MQPMO-DEFAULT not defined` → это **не “MQ сломался”**, это просто **в твоей программе используются имена, которых нет в DATA DIVISION**.
    
- `WS-REQ-QUEGGUE` → банально опечатка (в твоём исходнике видно `WS-REQ-QUEUE`, а в листинге ошибка по `QUEGGUE`).
    

Если хочешь, скинь кусок WORKING-STORAGE где у тебя `COPY CMQV / CMQODV / ...` и я скажу **какой именно REPLACING-шаблон** лучше применить под твою версию copybook’ов, чтобы завести все `*-DEFAULT` одним стилем.

  

COBOL declaration for MQOD ** MQOD structure 10 MQOD. ** Structure identifier 15 MQOD-STRUCID PIC X(4). ** Structure version number 15 MQOD-VERSION PIC S9(9) BINARY. ** Object type 15 MQOD-OBJECTTYPE PIC S9(9) BINARY. ** Object name 15 MQOD-OBJECTNAME PIC X(48). ** Object queue manager name 15 MQOD-OBJECTQMGRNAME PIC X(48). ** Dynamic queue name 15 MQOD-DYNAMICQNAME PIC X(48). ** Alternate user identifier 15 MQOD-ALTERNATEUSERID PIC X(12). ** Number of object records present 15 MQOD-RECSPRESENT PIC S9(9) BINARY. ** Number of local queues opened successfully 15 MQOD-KNOWNDESTCOUNT PIC S9(9) BINARY. ** Number of remote queues opened successfully 15 MQOD-UNKNOWNDESTCOUNT PIC S9(9) BINARY. ** Number of queues that failed to open 15 MQOD-INVALIDDESTCOUNT PIC S9(9) BINARY. ** Offset of first object record from start of MQOD 15 MQOD-OBJECTRECOFFSET PIC S9(9) BINARY. ** Offset of first response record from start of MQOD 15 MQOD-RESPONSERECOFFSET PIC S9(9) BINARY. ** Address of first object record 15 MQOD-OBJECTRECPTR POINTER. ** Address of first response record 15 MQOD-RESPONSERECPTR POINTER. ** Alternate security identifier 15 MQOD-ALTERNATESECURITYID PIC X(40). ** Resolved queue name 15 MQOD-RESOLVEDQNAME PIC X(48). ** Resolved queue manager name 15 MQOD-RESOLVEDQMGRNAME PIC X(48). ** Object Long name 15 MQOD-OBJECTSTRING. ** Address of variable length string 20 MQOD-OBJECTSTRING-VSPTR POINTER. ** Offset of variable length string 20 MQOD-OBJECTSTRING-VSOFFSET PIC S9(9) BINARY. ** size of buffer 20 MQOD-OBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY. ** Length of variable length string 20 MQOD-OBJECTSTRING-VSLENGTH PIC S9(9) BINARY. ** CCSID of variable length string 20 MQOD-OBJECTSTRING-VSCCSID PIC S9(9) BINARY. ** Message Selector 15 MQOD-SELECTIONSTRING. ** Address of variable length string 20 MQOD-SELECTIONSTRING-VSPTR POINTER. ** Offset of variable length string 20 MQOD-SELECTIONSTRING-VSOFFSET PIC S9(9) BINARY. ** size of buffer 20 MQOD-SELECTIONSTRING-VSBUFSIZE PIC S9(9) BINARY. ** Length of variable length string 20 MQOD-SELECTIONSTRING-VSLENGTH PIC S9(9) BINARY. ** CCSID of variable length string 20 MQOD-SELECTIONSTRING-VSCCSID PIC S9(9) BINARY. ** Resolved Long object name 15 MQOD-RESOBJECTSTRING. ** Address of variable length string 20 MQOD-RESOBJECTSTRING-VSPTR POINTER. ** Offset of variable length string 20 MQOD-RESOBJECTSTRING-VSOFFSET PIC S9(9) BINARY. ** size of buffer 20 MQOD-RESOBJECTSTRING-VSBUFSIZE PIC S9(9) BINARY. ** Length of variable length string 20 MQOD-RESOBJECTSTRING-VSLENGTH PIC S9(9) BINARY. ** CCSID of variable length string 20 MQOD-RESOBJECTSTRING-VSCCSID PIC S9(9) BINARY. ** Alias queue resolved object type 15 MQOD-RESOLVEDTYPE PIC S9(9) BINARY. смотри тут https://www.ibm.com/docs/en/ibm-mq/9.2.x?topic=SSFKSJ_9.2.0/com.ibm.mq.ref.dev.doc/q098100_.html нет MQOD-DEFAULT

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 57s

`MQOD-DEFAULT` **не является “готовым” именем поля/структуры в стандартных COBOL copybook’ах IBM MQ.**

В документации IBM показано, что **`MQOD_DEFAULT` (c подчёркиванием)** — это **C-macro**, которым в C инициализируют структуру (`MQOD MyOD = {MQOD_DEFAULT};`).   
Отсюда и твой RC=12: компилятор честно говорит, что **data-name `MQOD-DEFAULT` у тебя нигде не определён**.

## Как правильно делать “default init” в COBOL

### Вариант 1 (самый простой): использовать copybook `CMQODV` как “заготовку” и делать `MOVE` из своего DEFAULT

Логика такая: `CMQODV` содержит **VALUE** на полях (то, что ты показал: `VALUE 'OD '`, `VALUE 1`, `VALUE 'CSQ.*'`, и т.д.).  
Но IBM **не даёт** готового имени `MQOD-DEFAULT`. Его обычно делают сами — отдельным 01-уровнем.

Пример шаблона:

       01  MQOD-WORK.  
           COPY CMQOD.  
  
       01  MQOD-DEFAULT.  
           COPY CMQODV.

И дальше:

       MOVE MQOD-DEFAULT TO MQOD-WORK

> Идея: `MQOD-WORK` — рабочая область без VALUE (из `CMQOD`),  
> `MQOD-DEFAULT` — константная “маска” с VALUE (из `CMQODV`).  
> Это самый типовой паттерн для MQ-структур в COBOL.

⚠️ Если у тебя в библиотеке есть только `CMQODV` (а `CMQOD` нет), можно и рабочую область тоже объявлять через `CMQODV`, но тогда ты теряешь “чистое” разделение default vs work.

---

### Вариант 2: просто “инициализировать полями”, без `MOVE` whole-structure

Т.е. после `COPY CMQODV` в рабочую структуру сделать `MOVE` нужных дефолтов руками (менее удобно, но всегда работает).

---

## Почему ты “не находишь” `MQOD-DEFAULT` в `CMQODV`

Потому что в `CMQODV` объявлена **структура `MQOD`**, а **не переменная `MQOD-DEFAULT`** (см. твой фрагмент: `10 MQOD.` …).  
И в IBM reference прямо сказано, что **`MQOD_DEFAULT` — это C macro**. 

---

## Бонус: у тебя ещё одна явная ошибка в листинге

"WS-REQ-QUEGGUE" was not defined

Это просто опечатка в имени (`QUEUE` vs `QUEGGUE`) — компилятор не найдёт такой data-name.

Если хочешь — скинь кусок WORKING-STORAGE где ты делаешь `MOVE MQOD-DEFAULT TO ...` и где встречается `WS-REQ-QUEGGUE`, я под твою структуру напишу точный “канонический” блок объявлений + init (для MQOD/MQMD/MQGMO/MQPMO).

  

как наозывается транзакция которую мы опредедлили с программой CBLMQCIC

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

В CICS **TRANSACTION ID всегда 4 символа**. Поэтому если ты “привязал” программу **CBLMQCIC** к транзакции “по умолчанию/по шаблону”, то обычно берут первые 4 символа имени программы:

✅ **Скорее всего транзакция = `CBLM`** (а PROGRAM = `CBLMQCIC` или `LIBMQCIC`, смотря что реально в RDO).

Но точно можно сказать только по записи RDO (TRANSACTION definition). Проверить быстро:

### 1) Через CEMT (runtime)

CEMT INQUIRE TRANS(CBLM)

Смотри поля **Program()** / **Status()**.

### 2) Через CEDA (если разрешено)

CEDA DISPLAY TRANS(CBLM)

Там будет `PROGRAM(CBLMQCIC)` (или другое).

### 3) Через DFHCSDUP (batch / “инфраструктура как код”)

Выгрузи definition и посмотри связку TRANSACTION→PROGRAM:

//SYSIN DD *  
  LIST TRANSACTION(CBLM)  
/*

Если хочешь — пришли кусок CEDA DEFINE/DISPLAY или DFHCSDUP LIST для этой транзакции, и я скажу точно, что у тебя сейчас стоит (и почему могло получиться не `CBLM`).

  

после остановки джоба CICS - все определения транзакций пропадают?

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 12s

Про **точное имя транзакции**, которая “привязана” к программе **CBLMQCIC**, по тем листингам/логам, что ты показал, **определить нельзя**: там есть имя _JOB/PROC_ `CBLMQCIX`, но это **не** имя CICS TRANSACTION. Имя транзакции задаётся отдельным ресурсом **TRANSACTION** (RDO) и уже в нём указывается `PROGRAM(CBLMQCIC)`.

### Как узнать, как называется транзакция для `PROGRAM(CBLMQCIC)`

**1) В активной CICS (самый быстрый способ)**

- Посмотреть список транзакций “по маске”, если вы её как-то называли (например `CBL*`):
    
    - `CEMT INQUIRE TRANSACTION(CBL*)`
        
- Посмотреть определение конкретной транзакции (если знаешь/подозреваешь имя):
    
    - `CEMT INQUIRE TRANSACTION(xxxx)`
        
    - там будет поле `Program()` → увидишь, на что она указывает.
        

> Прямого “дай мне TRANSACTION по PROGRAM” в CEMT обычно нет, поэтому чаще идут **маской по транзакциям** или смотрят **CSD**.

**2) В CSD (то, что реально “помнит” определения)**  
Если ресурсы задавались через CEDA/DFHCSDUP:

- `CEDA DISPLAY TRANSACTION(*)` (в нужной группе/списке)
    
- или batch:
    
    - `DFHCSDUP LIST TRANSACTION(*)` (и/или `LIST GROUP(xxx)` чтобы увидеть, что входит в группу)
        
    - далее ищешь строки, где `PROGRAM(CBLMQCIC)`.
        

**3) Если используется CPSM/BAS**  
Ищи bundle/definition в BAS (WUI) по `PROGRAM(CBLMQCIC)` или по bundle, который деплоили.

---

## После остановки job CICS — транзакции “пропадают”?

Надо различать **активную таблицу ресурсов** и **репозиторий определений**:

### ✅ Что происходит всегда

- При остановке региона CICS **активные installed ресурсы исчезают из памяти**, потому что регион умер.
    
- При следующем старте они появятся **только если** CICS их **установит заново** (INSTALL) из того, где они хранятся.
    

### ✅ Если транзакции определены “правильно” (через CSD/BAS)

- Если делали `CEDA DEFINE` (что пишет в CSD) и ресурс включён в **GRPLIST** (или BAS bundle деплоится при старте),  
    то **после рестарта ничего не теряется**: определения **не пропадают**, просто “переустанавливаются” при старте.
    

### ⚠️ Когда реально “пропадают” после рестарта

- Если ты создавал ресурсы **только временно** (в рантайме) и **не записал их** в CSD/BAS:
    
    - например через динамическое создание ресурсов (в зависимости от версии/функций: dynamic RDO / API / временные определения),
        
    - или “ручные изменения”, которые не были сохранены как часть CSD/BAS деплоя,  
        — тогда после перезапуска региона они **не восстановятся**.
        

---

### Практический чек-лист

1. **Покажи, как вы определяли транзакцию**: CEDA DEFINE? DFHCSDUP? CPSM BAS?
    
2. В регионе выполни:
    

- `CEMT I TRAN(CBL*)` (или по вашей маске)
    
- и `CEDA DISPLAY TRAN(xxxx)` (если найдёшь кандидата)
    

3. Если после рестарта “исчезает” — значит, ресурс **не в GRPLIST/BAS**, или определение **не попало** в CSD.
    

Если кинешь кусок `CEDA DISPLAY TRAN(xxxx)` (или DFHCSDUP LIST output), я скажу **точно**, как называется транзакция и почему она не возвращается после рестарта (если это твой случай).

  

runbook_LIBT_v2.md

Datei

мы делали так

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 19s

Транзакция, которую вы связали с программой **CBLMQCIC**, называется **`LIBT`**.

Это прямо зафиксировано в вашем runbook:

- `PROGRAM(LIBMQCIC)`
    
- `TRANSACTION(LIBT)` → запускает `PROGRAM(LIBMQCIC)`  
    и проверка была: `CEMT I TRANS(LIBT)` (там видно `Pro(LIBMQCIC)`).
    

---

## После остановки CICS job — “все определения транзакций пропадают”?

Нужно различать **2 вещи**:

### 1) Определения в CSD (DFHCSD) — **НЕ пропадают**

Если вы делали `CEDA DEFINE ...` и нажимали Enter (сохранение), то запись уходит в **CSD dataset** (у вас: `Z88011.CICS.DFHCSD`) и **остается там** после рестарта региона.

### 2) “Установленные” (installed) ресурсы в памяти региона — **пропадают**

Когда вы стопаете регион, его runtime-память очищается. Поэтому после старта региона **транзакция может быть “не установлена”**, пока вы снова не сделаете:

- `CEDA INSTALL GROUP(Z88011)`  
    или пока CICS сам не установит этот GROUP автоматически при старте.
    

---

## Как сделать, чтобы после рестарта оно поднималось само

Нужно, чтобы ваш `GROUP(Z88011)` попадал в startup install, обычно через:

- **GRPLIST** (SIT параметр) — установить группы при старте региона
    
- или **PLTPI** (startup program list)
    
- или **CICSPlex SM/BAS** (если используется)
    

Итого по вашему кейсу: **определение `LIBT` в CSD не исчезает**, но **после рестарта его надо снова “INSTALL”**, если вы не подключили автозагрузку группы при старте.

  

INSTALL GROUP(Z88011) OVERTYPE TO MODIFY CEDA Install ALl ATomservice ==> Bundle ==> CONnection ==> CORbaserver ==> DB2Conn ==> DB2Entry ==> DB2Tran ==> DJar ==> DOctemplate ==> DUmpcode ==> Enqmodel ==> File ==> Ipconn ==> JOurnalmodel ==> JVmserver ==> + LIBrary ==> SYSID=S750 APPLID=CXZ88011 INSTALL SUCCESSFUL DSN=Z88011.CICS.DFHCSD PF 1 HELP 3 END 6 CRSR 7 SBH 8 SFH 9 MSG 10 SB 11 SF 12 CNCL

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 16s

Транзакция, которую вы связали с программой **CBLMQCIC / LIBMQCIC**, называется **`LIBT`**.

Это прямо видно из вашего runbook:

- определяли `PROGRAM(LIBMQCIC)`
    
- проверяли/использовали `TRANSACTION(LIBT)` → `PROGRAM(LIBMQCIC)`
    
- проверка: `CEMT I TRANS(LIBT)` показывала `Pro(LIBMQCIC)` и `Ena`
    

---

## После остановки CICS job определения пропадают?

Нужно различать **2 уровня**:

### 1) Определения в CSD (RDO) — **НЕ пропадают**

Если вы делали через **CEDA DEFINE** (или DFHCSDUP), то записи **сохранились в DFHCSD** (у вас: `Z88011.CICS.DFHCSD`).

То есть:

- `PROGRAM(LIBMQCIC)`
    
- `TRANSACTION(LIBT)`
    
- `LIBRARY(Z88011LD)` (если определяли)
    

— остаются в CSD и после стоп/старт региона никуда не деваются.

### 2) “Установленные” ресурсы в памяти региона — **пропадают**

Когда вы делаете **CEDA INSTALL GROUP(Z88011)**, это загружает/активирует ресурсы **в текущем запущенном регионе**.

Если регион остановить (shutdown) — при следующем старте:

- память региона чистая
    
- ресурсы **нужно снова INSTALL’ить**, **если** они не поднимаются автоматически при старте.
    

---

## Как сделать, чтобы после рестарта поднималось само

Самое типичное:

- добавить `GROUP(Z88011)` в **startup GRPLIST** (который указан в SIT, параметр `GRPLIST=`),  
    чтобы CICS при старте автоматически делал install этого списка групп.
    

Альтернативы:

- PLTPI/PLTSD (авто-install командой на старте),
    
- CPSM/BAS bundles (если используется),
    
- Autoinstall (для некоторых типов ресурсов, но транзакции/программы обычно через GRPLIST).
    

Если хотите — скажите, какой у региона `GRPLIST` в SIT (или покажите `CEMT I SYSTEM` / SIT print), и я напишу точные команды/DFHCSDUP job как “добавить Z88011 в startup list”, чтобы `LIBT` всегда был готов после IPL/рестарта региона.

  

да cobol программа называется LIBMQCIC после CEDA INSTALL GROUP(Z88011) моя транзакция LIBT опять доступна LIBT STATUS: SESSION ENDED DFHAC2206 10:20:51 CXZ88011 Transaction LIBT failed with abend APCW. Updates to local recoverable resources backed out.

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 1m 2s

Транзакция у тебя называется **LIBT** (ты сам это подтвердил: после `CEDA INSTALL GROUP(Z88011)` LIBT снова стала доступна).

## Почему после stop/start CICS “пропадают” транзакции

Важно различать **definition** и **install**:

- **Definitions** (TRANSACTION/PROGRAM/LIBRARY и т.д.) **не пропадают**, они лежат в **DFHCSD** (у тебя видно `DSN=Z88011.CICS.DFHCSD` на экране INSTALL).
    
- **Installed state** (то, что реально “активно” в запущенном регионе) — **пропадает при остановке региона**, потому что это память работающего CICS.
    

После рестарта регион поднимает только то, что ему сказано установить автоматически:

- через **SIT/GRPLIST** (группы, которые автo-install при старте),
    
- или через **PLTPI/PLT** (ваши стартовые процедуры),
    
- или через CPSM/BAS (если используется).
    

Поэтому у тебя и получается: **после рестарта LIBT не доступна**, пока ты не сделаешь `CEDA INSTALL GROUP(Z88011)`.

---

## Что означает abend **APCW** для LIBT

По IBM CICS Codes, **APCW** означает:

> _Program language defined as COBOL, but the compiler level under which it was compiled cannot be determined… likely compiled under OS/VS COBOL and required support is not present; transaction abends and program is disabled._ 

### Что это обычно значит practically

CICS пытается определить “какой COBOL/LE” у load module, но:

- **подхватывается не тот load module** (старый/чужой из другого loadlib в DFHRPL/LIBRARY),
    
- или load module **не LE-conforming / старый формат**,
    
- или **в определении PROGRAM/LANGUAGE** что-то не бьётся с реальным модулем.
    

### Быстрый чек-лист

1. В CICS:
    

- `CEMT I TRANS(LIBT)` → какой PROGRAM привязан?
    
- `CEMT I PROG(<progname>)` → **ENABLED?** **DISABLED?** что в статусе/why?
    
- Сделай `CEMT SET PROG(<progname>) NEWCOPY` после перекомпиляции.
    

2. Проверь, что реально запускается **правильный load module**:
    

- порядок библиотек в **DFHRPL** / CICS **LIBRARY** resource (частая причина: “старьё” раньше в concatenation),
    
- при необходимости временно убери/переупорядочь, чтобы CICS не находил старую версию.
    

3. На уровне линковки:
    

- убедись, что ты **перекомпилил и перелинковал** именно этот модуль (не только translate),
    
- что это **Enterprise COBOL + LE** (не OS/VS COBOL объект).
    

Если хочешь — кинь сюда:

- `CEDA DISPLAY TRANS(LIBT)` и `CEDA DISPLAY PROG(<prog>)`
    
- и/или `CEMT I PROG(<prog>)`  
    и я скажу точнее, где именно несостыковка.
    

---

## И ещё (к твоему прежнему вопросу про MQOD-DEFAULT)

Ты прав: **в `CMQODV` нет `MQOD-DEFAULT`** — `CMQODV` описывает **структуру** MQOD (поля), а “DEFAULT record” обычно лежит в другом copybook (часто **`CMQOD`**, без `V`) или в “constants” copybook. Поэтому `MOVE MQOD-DEFAULT TO MQM-OBJECT-DESCRIPTOR` компилятор и ругает: имени просто нет в подключённых copybooks.

Если скажешь, какие copybooks MQ у тебя доступны в `CSQ...SCSQCOBC` (или как у вас называется dataset с COBOL copybooks MQ), я подскажу точный `COPY ...` который даёт `MQOD-DEFAULT` именно в вашей версии MQ.

  

я могу запуск группы добавить в джоб запуска CICS? //CICS4ZXP JOB FB3 // EXPORT SYMLIST=(*) // SET CARD='//' //STARTCXZ EXEC PGM=IEBGENER //SYSPRINT DD DUMMY //SYSIN DD DUMMY //SYSUT2 DD SYSOUT=(*,INTRDR) //SYSUT1 DD *,SYMBOLS=CNVTSYS &CARD.CX&SYSUID JOB CICS4ZXP,CLASS=(C4Z) &CARD.C4Z EXEC PROC=CICS4ZXP,TSOUID=&SYSUID /*

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 9s

Да — **правильный способ “автоматически устанавливать (INSTALL) группу при старте региона”**существует, но делается **не через CEDA** в JCL (CEDA — интерактивная команда), а через **SIT/GRPLIST**(или через PLT), чтобы CICS сам делал INSTALL на этапе инициализации.

## 1) Почему после стопа региона “транзакция пропадает”

Когда ты делаешь `CEDA INSTALL GROUP(Z88011)`, ресурсы **становятся активными в памяти региона**.  
При остановке CICS регион теряет “in-memory install”, но **определения в DFHCSD никуда не деваются**— просто на новом старте их снова надо **INSTALL**.

Именно поэтому после нового `CEDA INSTALL GROUP(Z88011)` твоя `LIBT` снова появляется.

---

## 2) Как сделать INSTALL группы автоматически при старте (рекомендуемый путь)

### Вариант A (стандартный): добавить группу в **GRPLIST** в SIT

1. Определи, **какой SIT** использует твой стартовый PROC (`CICS4ZXP`). Обычно это:
    

- `PARM='SIT=xxxx'` в EXEC CICS,
    
- или SIT берётся по умолчанию (часто `DFHSIT` / конкретный member),
    
- иногда overrides идут через `//DFHSIP DD *` (SIT overrides).
    

2. В SIT укажи:
    

- либо `GRPLIST=Z88011` (если у тебя GRPLIST-список так называется),
    
- либо включи группу `Z88011` в GRPLIST, который уже используется (часто DFHLIST).
    

**Смысл:** при старте CICS прочитает DFHCSD и автоматически сделает `INSTALL` всех групп, перечисленных в GRPLIST.

✅ Это “инфраструктура как код” и самый правильный способ.

---

### Вариант B: создать/обновить GRPLIST (если надо) через DFHCSDUP (batch)

Если ты хочешь именно “скриптом” управлять тем, что ставится на старте — делай это утилитой **DFHCSDUP**:

- обновляешь в DFHCSD нужный **LIST** (например DFHLIST) и добавляешь туда `GROUP(Z88011)`,
    
- дальше SIT указывает `GRPLIST=DFHLIST` (или другой list).
    

---

## 3) Можно ли “впихнуть CEDA INSTALL GROUP(...)” прямо в JCL старта?

Технически можно попытаться сделать шаг, который после старта региона пошлёт команды (через console / TDQ / CEMT batching / API), **но это плохая практика**:

- регион может ещё не быть готов,
    
- команды будут зависеть от timing,
    
- ты получишь “хрупкий” старт.
    

Правильно: **SIT GRPLIST** (или PLT).

---

## 4) Вариант через PLT (если нужно что-то выполнить после старта)

Если тебе нужно _не только INSTALL_, а ещё, например, выполнить дополнительные действия после init (проверки, SET, ENABLE, какие-то custom команды) — используют **PLTPI/PLTSD**.  
Но для твоего кейса “чтобы LIBT всегда была после старта” — **GRPLIST проще и правильнее**.

---

## 5) Что конкретно делать с твоим JCL

Твой JCL:

//STARTCXZ EXEC PGM=IEBGENER  
...  
&CARD.C4Z EXEC PROC=CICS4ZXP,TSOUID=&SYSUID

👉 Внутри `PROC=CICS4ZXP` надо найти **шаг запуска CICS** (обычно `EXEC PGM=DFHSIP` или подобный) и посмотреть:

- где задаётся `SIT=...`
    
- есть ли `DFHSIP`/`DFHSIT` member
    
- есть ли `//DFHSIP DD *` overrides
    

Дальше:

- либо правишь SIT member и добавляешь `GRPLIST=...` с твоей группой,
    
- либо добавляешь override в JCL (если у вас так принято) типа `GRPLIST=...` (в зависимости от того, как именно у вас оформлен старт).
    

---

## 6) Быстрая проверка (после правки)

После старта региона **без ручного CEDA**:

- `CEMT I TRAN(LIBT)` → должна быть видна
    
- `CEMT I PROG(LIBMQCIC)` → должна быть установлена/доступна
    

---

Если хочешь, вставь сюда **кусок PROC `CICS4ZXP`** (тот шаг, где стартует CICS: `EXEC PGM=...` + DD’шки/параметры) — и я скажу **точно**, куда и в каком виде у вас лучше добавить `GRPLIST` для `Z88011`.

P.S. Ты выше ссылался на runbook-файл — часть ранее загруженных файлов у меня уже “истекла”, поэтому если тебе нужно, чтобы я сверил ответ с тем runbook, просто загрузи его ещё раз.

  

I TRANS(LIBT) STATUS: RESULTS - OVERTYPE TO MODIFY Tra(LIBT) Pri( 001 ) Pro(LIBMQCIC) Tcl( DFHTCL00 ) Ena Sta Pur Prf(DFHCICST) Uda Any Iso Bac Wai SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 10.33.40 DATE: 04/05/26 PF 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 15s

Транзакция у тебя **LIBT** — это видно из CEMT:

`I TRANS(LIBT) ... Pro(LIBMQCIC)`  
то есть **TRAN=LIBT → PROGRAM=LIBMQCIC**.

---

## После остановки/рестарта CICS “все определения пропадают”?

Надо разделять 2 вещи:

1. **Определения в CSD (DFHCSD)** — это “каталог” ресурсов (TRANSACTION/PROGRAM и т.д.).  
    Они **не пропадают** при остановке региона.
    
2. **Установленные (INSTALLED) ресурсы в памяти региона** — это то, что реально активно в работающем CICS.  
    После stop/start они **сбрасываются**, и если при старте регион _не делает INSTALL нужных групп_, транзакция становится “не доступна”, пока ты снова не сделаешь `CEDA INSTALL GROUP(...)`.
    

То, что у тебя **LIBT снова появляется после `CEDA INSTALL GROUP(Z88011)`**, идеально подтверждает именно этот сценарий.

---

## Можно ли “INSTALL GROUP(Z88011)” добавить в JOB запуска CICS?

Да. Правильный способ — **автоинсталл групп на старте через GRPLIST (в SIT)**, чтобы при каждом старте CICS автоматически делал INSTALL нужных групп.

### Вариант A (правильный): добавить группу в GRPLIST (SIT)

Нужно, чтобы в SIT был указан список групп для авто-установки, например:

- `GRPLIST=(DFHLIST,Z88011)`  _(или твой базовый список + Z88011)_
    

Где это задаётся:

- либо в **DFHSIT** (SIT table),
    
- либо как **override параметр** при старте (зависит от того, как у тебя устроен PROC `CICS4ZXP`).
    

**Что проверить/где править:**

- посмотри в PROC `CICS4ZXP` — там обычно есть DD для **DFHSIP** или параметры запуска CICS.
    
- если используется `//DFHSIP DD *` (или `//SYSIN DD *`) — туда можно добавить override вида `GRPLIST=...`
    

Пример _идеи_ (как это обычно выглядит — точные DD-имена зависят от вашего PROC):

//DFHSIP   DD *  
GRPLIST=(DFHLIST,Z88011)  
/*

Если GRPLIST задан жёстко в DFHSIT и override запрещён/не используется — тогда правят DFHSIT/или SIT source.

### Вариант B: держать всё как есть, но “инсталлировать” после старта скриптом

Технически можно автоматизировать `CEDA INSTALL GROUP(Z88011)` через:

- CMCI (REST) / CPSM BAS,
    
- или “скрипт терминала” (HLLAPI/automation) — но это хуже и менее надёжно, чем GRPLIST.
    

---

## Почему в CEMT статус “SESSION ENDED” и abend APCW?

`DFHAC2206 ... Transaction LIBT failed with abend APCW` — это уже **абенд прикладного кода/окружения** (часто: missing program, missing required resource, security, MQ/DB2 issues, bad LE options и т.п.).  
Но к “пропаданию транзакции после рестарта” это не относится: это именно runtime-проблема выполнения.

---

## Быстрый чек-лист “сделать так, чтобы LIBT всегда была после старта”

1. Убедись, что **TRAN/PROG есть в DFHCSD** (CEDA DEFINE/ALTER записывает туда).
    
2. Включи автозагрузку группы на старте:
    
    - добавить `Z88011` в **GRPLIST** (SIT/override).
        
3. Перестартовать регион и проверить:
    
    - `CEMT I TRANS(LIBT)` сразу после старта без ручного CEDA INSTALL.
        

Если покажешь JCL/PROC `CICS4ZXP` (кусок где запускается DFHSIP/DFHSIT/параметры), я прямо укажу **точное место**, куда вставить `GRPLIST=(...,Z88011)` в вашем варианте.

  

CEMT I PROG(LIBMQCIC) STATUS: RESULTS - OVERTYPE TO MODIFY Prog(LIBMQCIC) Leng(0000001952) Cob Pro Dis Pri Ced Resc(0000) Use(0000000001) Any Uex Ful Qua Cic SYSID=S750 APPLID=CXZ88011 RESPONSE: NORMAL TIME: 10.34.25 DATE: 04/05/26 PF 1 HELP 3 END 5 VAR 7 SBH 8 SFH 9 MSG 10 SB 11 SF

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 16s

Да, можно — но **не “CEDA INSTALL” прямо из JCL** в том же смысле, как ты делаешь это руками в терминале. Правильные варианты такие (от “как принято” к “хаком”):

## 1) Правильно: подключить GROUP в автозагрузку региона через GRPLIST (SIT)

То, что ты наблюдаешь, нормальное поведение:

- **Определения живут в CSD (DFHCSD)** и не “пропадают”.
    
- Но **после рестарта региона они не INSTALLED**, пока регион их не установит.
    
- Поэтому после старта CICS твоя транзакция **LIBT недоступна**, пока не сделать `CEDA INSTALL GROUP(Z88011)` (или пока это не сделает автозагрузка).
    

Чтобы **GROUP(Z88011) ставилась автоматически**, добавь её в **GRPLIST** региона (через SIT параметр `GRPLIST=`).

Идея:

- В DFHCSD есть GROUP `Z88011` (с TRANSACTION(LIBT), PROGRAM(LIBMQCIC), …)
    
- При старте региона CICS читает `GRPLIST` и делает INSTALL автоматически.
    

Как это обычно делается:

- либо правится **DFHSIT** (skeleton SIT для этого региона),
    
- либо используется **SIT override** в процедуре старта (зависит от того, как у вас устроен PROC `CICS4ZXP`).
    

Ключевое: тебе нужно добиться, чтобы при старте региона было что-то вроде:

- `GRPLIST=(DFHLIST,Z88011)` **или** `GRPLIST=Z88011` (как принято у вас).
    

---

## 2) Тоже правильно: PLTPI (startup program), который делает INSTALL GROUP

Если по политике нельзя/неудобно трогать GRPLIST, можно сделать автодействие на старте через **PLTPI**:

- в PLTPI прописывают запуск маленькой программы,
    
- она выполняет `EXEC CICS PERFORM INSTALL GROUP('Z88011')`
    

Это уже “автодеплой при старте” без ручного CEDA.

---

## 3) Внешняя автоматизация после старта: CMCI/REXX/скрипт

Если ты стартуешь регион из JCL и хочешь “после поднятия” выполнить install, то обычно делают:

- старт региона
    
- затем скрипт (например, через **CMCI REST**, или через **REXX/TSO**, или operator command/automation), который дергает INSTALL ресурсов
    

Это удобно для CI/CD.

---

## Важно: “после остановки CICS определения транзакций пропадают?”

**Нет** — если ты их **DEFINE делал в CEDA (то есть писал в DFHCSD)**, они остаются в CSD.  
**Пропадает только INSTALLED-состояние** (что было загружено в память региона).

---

## По твоему конкретному кейсу

Ты уже видишь:

- `CEMT I TRANS(LIBT)` показывает `Pro(LIBMQCIC)` — значит связка в регионе нормальная.
    
- После `CEDA INSTALL GROUP(Z88011)` транзакция снова доступна — значит **в CSD всё есть**, просто **не грузится автоматически при старте**.
    

Следующий практический шаг: **добавить Z88011 в GRPLIST этого региона** (или через PLTPI).

---

### Если хочешь — пришли кусок PROC `CICS4ZXP` (или где у вас задаются SIT overrides / DFHSIT), и я скажу **точно куда и как** вставить `GRPLIST=(...,Z88011)` для твоей сборки.

---

P.S. Мне пришло системное уведомление, что **часть ранее загруженных файлов “протухла”**. Если тебе нужно, чтобы я снова посмотрел/правил твой `runbook_LIBT_v2.md` или другие артефакты, просто загрузи их ещё раз.

  

//CICS4ZXP PROC TSOUID='' // EXPORT SYMLIST=(TSOUID) // SET TSOUID=&TSOUID //*====================================================================* //* DELETE AND DEFINE TEMPORARY DATA SETS * //*====================================================================* //DELLOGS EXEC PGM=IXCMIAPU //SYSPRINT DD SYSOUT=* //SYSOUT DD SYSOUT=* //SYSIN DD *,SYMBOLS=EXECSYS DATA TYPE(LOGR) REPORT(NO) DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLGLOG) DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHSHUNT) DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLOG) DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHJ01) /* //* //*====================================================================* //* DELETE TEMP, QUEUE DUMP AND TRACE DATASETS * //*====================================================================* //DELDSNS EXEC PGM=IDCAMS,REGION=1M //SYSPRINT DD DUMMY //SYSIN DD *,SYMBOLS=EXECSYS DELETE &TSOUID..CICS.DFHTEMP DELETE &TSOUID..CICS.DFHINTRA DELETE &TSOUID..CICS.DFHLRQ SET MAXCC=0 /* //* //*====================================================================* //* DEFINE DATASETS AND LOGSTREAMS FOR REGION LOGGER * //*====================================================================* //*DEFLOGS EXEC PGM=IXCMIAPU //*SYSPRINT DD SYSOUT=* //*SYSOUT DD SYSOUT=* //*SYSIN DD *,SYMBOLS=EXECSYS //* DATA TYPE(LOGR) REPORT(NO) //* DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHLGLOG) //* EHLQ(&TSOUID..CICS) //* DASDONLY(YES) //* MAXBUFSIZE(64000) //* LS_SIZE(3000) //* STG_SIZE(3000) //* LOWOFFLOAD(40) HIGHOFFLOAD(80) //* DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHSHUNT) //* EHLQ(&TSOUID..CICS) //* DASDONLY(YES) //* MAXBUFSIZE(64000) //* LS_SIZE(3000) //* STG_SIZE(3000) //* LOWOFFLOAD(40) HIGHOFFLOAD(80) //* DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHLOG) //* EHLQ(&TSOUID..CICS) //* DASDONLY(YES) //* MAXBUFSIZE(64000) //* LS_SIZE(3000) //* STG_SIZE(3000) //* LOWOFFLOAD(40) HIGHOFFLOAD(80) //* DEFINE LOGSTREAM NAME(&TSOUID..LOG.DFHJ01) //* EHLQ(&TSOUID..CICS) //* DASDONLY(YES) //* MAXBUFSIZE(64000) //* LS_SIZE(3000) //* STG_SIZE(3000) //* LOWOFFLOAD(40) HIGHOFFLOAD(80) //* //* //*====================================================================* //* DEFINE DATASETS FOR TEMP AND QUEUE SPACE * //*====================================================================* //DEFDSNS EXEC PGM=IDCAMS,REGION=1M //SYSPRINT DD DUMMY //SYSIN DD *,SYMBOLS=EXECSYS DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHTEMP)- RECORDSIZE(4089,4089)- REC(200)- NIXD - CISZ(4096)- VOLUME(ZXPC02) SHR(2 3)) - DATA(NAME(&TSOUID..CICS.DFHTEMP.DATA)- UNIQUE) DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHINTRA)- RECORDSIZE(4089,4089)- REC(100)- NIXD - CISZ(4096)- VOLUME(ZXPC02) SHR(2 3)) - DATA(NAME(&TSOUID..CICS.DFHINTRA.DATA)- UNIQUE) DEFINE CLUSTER(NAME(&TSOUID..CICS.DFHLRQ)- INDEXED- LOG(UNDO)- CYL(2 1)- VOLUME(ZXPC02)- RECORDSIZE( 2232 2400 )- KEYS( 40 0 )- FREESPACE ( 0 10 )- SHAREOPTIONS( 2 3 ))- DATA (NAME(&TSOUID..CICS.DFHLRQ.DATA) - CISZ(2560)) - INDEX (NAME(&TSOUID..CICS.DFHLRQ.INDEX)) /* //* //*====================================================================* //* SET RETURN CODE TO CONTROL IF CICS SHOULD BE STARTED * //*====================================================================* //CICSCNTL EXEC PGM=IDCAMS,REGION=1M //SYSPRINT DD DUMMY //SYSIN DD DISP=SHR,DSN=DFH620.SYSIN(DFHRCYES) //* //*====================================================================* //* SET RETURN CODE TO CONTROL DUMP AND TRACE ANALYSIS STEPS * //*====================================================================* //DTCNTL EXEC PGM=IDCAMS,REGION=1M //SYSPRINT DD DUMMY //SYSIN DD DISP=SHR,DSN=DFH620.SYSIN(DFHRCNO) //* //*====================================================================* //* DEFINE A & B DATASETS FOR TRACE * //*====================================================================* //DEFTRACE EXEC PGM=IEFBR14 //AUXT DD DISP=(NEW,PASS), // SPACE=(CYL,(1)), // BLKSIZE=4096,RECFM=F,LRECL=4096, // DSN=&&DFHAUXT //BUXT DD DISP=(NEW,PASS), // SPACE=(CYL,(1)), // BLKSIZE=4096,RECFM=F,LRECL=4096, // DSN=&&DFHBUXT //* //*====================================================================* //* DEFINE A & B DATASETS FOR DUMP * //*====================================================================* //DEFDUMP EXEC PGM=IEFBR14 //DMPA DD DISP=(NEW,PASS), // SPACE=(CYL,(5)), // RECFM=VB,LRECL=4092,BLKSIZE=4096, // DSN=&&DFHDMPA //DMPB DD DISP=(NEW,PASS), // SPACE=(CYL,(5)), // RECFM=VB,LRECL=4092,BLKSIZE=4096, // DSN=&&DFHDMPB //* //*====================================================================* //* SET PORTS FOR TCPIPSERVICE(S) * //*====================================================================* //PORTACQ EXEC PGM=BPXBATCH,REGION=0M //STEPLIB DD DSN=CEE.SCEERUN,DISP=SHR //STDERR DD SYSOUT=* //STDOUT DD DSN=&&CSDUP,DISP=(NEW,PASS), // SPACE=(TRK,1),LRECL=80,RECFM=F,BLKSIZE=80 //STDENV DD * _CEE_RUNOPTS=FILETAG(AUTOCVT,AUTOTAG) POSIX(ON) _BPXK_AUTOCVT=ON PATH=/z/rocket/tools/bin:/z/bin PERL5LIB=/usr/lpp/perl/lib/perl5 LIBPATH=/usr/lib:/lib /* //STDPARM DD *,SYMBOLS=EXECSYS SH /z/bin/cicsport_acquire &TSOUID. DFH\$WUTC /* //* //*====================================================================* //* UPDATE CSD WITH PORT ASSIGNMENTS //*====================================================================* //CSDUP EXEC PGM=DFHCSDUP,REGION=1M //STEPLIB DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR //DFHCSD DD DSN=&TSOUID..CICS.DFHCSD,DISP=SHR //SYSPRINT DD SYSOUT=* //SYSDUMP DD SYSOUT=* //SYSIN DD DSN=&&CSDUP,DISP=(OLD,DELETE) //* //*====================================================================* //* * //* * //* EXECUTE CICS * //* * //* * //*====================================================================* //CICS EXEC PGM=DFHSIP,REGION=0M,MEMLIMIT=10G,TIME=1, // COND=(1,NE,CICSCNTL),PARM='START=INITIAL,SYSIN' //*>> SIT OVERRIDES IN SYSIN MEMBERS //SYSIN DD DISP=SHR,DSN=DFH620.SYSIN(DFH$SIPX) // DD DISP=SHR,DSN=&TSOUID..CICS.SYSIN(DFH$SIP) // DD *,SYMBOLS=EXECSYS XTRAN=NO GMTEXT='CICS TS 6.2 - WELCOME TO YOUR PERSONAL REGION RESTRICTIONS APPLY - SEE ''ZXP.PUBLIC.CICS.README''' APPLID=(CX&TSOUID.,CX&TSOUID.) .END /* //*>> CICS SYSTEM DEFINITION DATASET //DFHCSD DD DISP=OLD,DSN=&TSOUID..CICS.DFHCSD //* //*>> MESSAGES AND CODES REFRENCE //DFHCMACD DD DISP=SHR,DSN=DFH620.DFHCMACD //* //*>> CICS STEPLIB CONCATENATION //STEPLIB DD DISP=SHR,DSN=DFH620.CICS.SDFHAUTH // DD DISP=SHR,DSN=DFH620.CICS.SDFHLINK // DD DISP=SHR,DSN=DFH620.CPSM.SEYUAUTH // DD DISP=SHR,DSN=DFH620.SDFHLIC // DD DISP=SHR,DSN=DSND10.SDSNLOAD // DD DISP=SHR,DSN=DSND10.SDSNLOD2 // DD DISP=SHR,DSN=CEE.SCEERUN2 // DD DISP=SHR,DSN=CEE.SCEERUN //* //*>> AUXILIARY TEMPORARY STORAGE DATASET //DFHTEMP DD DISP=SHR,DSN=&TSOUID..CICS.DFHTEMP //* //*>> INTRAPARTITION DATASET //DFHINTRA DD DISP=SHR,DSN=&TSOUID..CICS.DFHINTRA //* //*>> CICS LOCAL CATALOG DATASET //DFHLCD DD DISP=SHR,DSN=&TSOUID..CICS.DFHLCD //* //*>> CICS GLOBAL CATALOG DATASET //DFHGCD DD DISP=SHR,DSN=&TSOUID..CICS.DFHGCD //* //*>> CICS LOCAL REQUEST QUEUE DATASET //DFHLRQ DD DISP=SHR,DSN=&TSOUID..CICS.DFHLRQ //* //*>> EXTRAPARTITION DATASETS //DFHCXRF DD SYSOUT=* //LOGUSR DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=136) //MSGUSR DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=140) //CEEMSG DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=165) //CEEOUT DD SYSOUT=*,DCB=(DSORG=PS,RECFM=V,BLKSIZE=137) //* //*>> AUXILIARY TRACE DATASETS //DFHAUXT DD DISP=SHR,DSN=&&DFHAUXT,DCB=BUFNO=5 //DFHBUXT DD DISP=SHR,DSN=&&DFHBUXT,DCB=BUFNO=5 //* //*>> DUMP DATASETS //DFHDMPA DD DISP=SHR,DSN=&&DFHDMPA //DFHDMPB DD DISP=SHR,DSN=&&DFHDMPB //SYSABEND DD SYSOUT=* //SYSPRINT DD SYSOUT=* //PRINTER DD SYSOUT=*,DCB=BLKSIZE=121 //* //*>> CICS LIBRARY (DFHRPL) CONCATENATION //DFHRPL DD DSN=DFH620.CPSM.SEYULOAD,DISP=SHR // DD DSN=DFH620.CICS.SDFHLOAD,DISP=SHR // DD DSN=ZXP.CICS.PROD.DFHLOAD,DISP=SHR // DD DSN=&TSOUID..CICS.PROD.DFHLOAD,DISP=SHR // DD DSN=CEE.SCEECICS,DISP=SHR // DD DSN=CEE.SCEERUN2,DISP=SHR // DD DSN=CEE.SCEERUN,DISP=SHR //* //********************************************************************** //* //* //* CICS ENDS HERE * //* //* //********************************************************************** //*====================================================================* //* EXECUTE DUMP UTILITY TO PRINT DUMP DATASET A & B * //*====================================================================* //PRTDMPA EXEC PGM=DFHDU750,PARM=SINGLE,REGION=0M,COND=(1,NE,DTCNTL) //STEPLIB DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD //DFHTINDX DD SYSOUT=* //SYSPRINT DD SYSOUT=* //DFHPRINT DD SYSOUT=* //DFHDMPDS DD DISP=SHR,DSN=&&DFHDMPA //SYSIN DD DUMMY //* //PRTDMPB EXEC PGM=DFHDU750,PARM=SINGLE,REGION=0M,COND=(1,NE,DTCNTL) //STEPLIB DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD //DFHTINDX DD SYSOUT=* //SYSPRINT DD SYSOUT=* //DFHPRINT DD SYSOUT=* //DFHDMPDS DD DISP=SHR,DSN=&&DFHDMPB //SYSIN DD DUMMY //* //*====================================================================* //* EXECUTE TRACE UTILITY TO PRINT TRACE DATASET A * //*====================================================================* //PRTAUXT EXEC PGM=DFHTU750,REGION=0M,COND=(1,NE,DTCNTL) //STEPLIB DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD //DFHAUXT DD DISP=SHR,DSN=&&DFHAUXT //DFHAXPRT DD SYSOUT=* //DFHAXPRM DD DUMMY //* //*====================================================================* //* EXECUTE TRACE UTILITY TO PRINT TRACE DATASET B * //*====================================================================* //PRTBUXT EXEC PGM=DFHTU750,REGION=0M,COND=(1,NE,DTCNTL) //STEPLIB DD DISP=SHR,DSN=DFH620.CICS.SDFHLOAD //DFHAUXT DD DISP=SHR,DSN=&&DFHBUXT //DFHAXPRT DD SYSOUT=* //DFHAXPRM DD DUMMY //* //*====================================================================* //* RELEASE PORTS FOR TCPIP SERVICES * //*====================================================================* //PORTREL EXEC PGM=BPXBATCH,REGION=0M,COND=EVEN //STEPLIB DD DSN=CEE.SCEERUN,DISP=SHR //STDERR DD DUMMY //STDOUT DD SYSOUT=* //STDENV DD * _CEE_RUNOPTS=FILETAG(AUTOCVT,AUTOTAG) POSIX(ON) _BPXK_AUTOCVT=ON PATH=/z/rocket/tools/bin:/z/bin PERL5LIB=/usr/lpp/perl/lib/perl5 LIBPATH=/usr/lib:/lib /* //STDPARM DD *,SYMBOLS=EXECSYS SH /z/bin/cicsport_release &TSOUID. /* //* //*====================================================================* //* DELETE LOG DATASETS AND LOGSTREAMS * //*====================================================================* //*DELLOGS EXEC PGM=IXCMIAPU,COND=EVEN //*SYSPRINT DD SYSOUT=* //*SYSOUT DD SYSOUT=* //*SYSIN DD *,SYMBOLS=EXECSYS //* DATA TYPE(LOGR) REPORT(NO) //* DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLGLOG) //* DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHSHUNT) //* DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHLOG) //* DELETE LOGSTREAM NAME(&TSOUID..LOG.DFHJ01) //* //* //*====================================================================* //* DELETE TEMPORARY DATA SETS * //*====================================================================* //DELDSNS EXEC PGM=IDCAMS,REGION=1M,COND=EVEN //SYSPRINT DD DUMMY //SYSIN DD *,SYMBOLS=EXECSYS DELETE &TSOUID..CICS.DFHTEMP DELETE &TSOUID..CICS.DFHINTRA DELETE &TSOUID..CICS.DFHLRQ SET MAXCC=0 /*

  

Denkvorgang abgeschlossen

Denkvorgang abgeschlossen

Nachgedacht für 27s

Да — **авто-INSTALL “твоей” группы при старте региона** делается, но **не прямым `CEDA INSTALL GROUP()` в JCL**, а через **startup list (GRPLIST)** (или через PLT, если нужно более хитро).

## 1) Почему после рестарта “пропадает”

- **Определения** (PROGRAM/TRANSACTION и т.п.) у тебя хранятся в **CSD dataset**(`&TSOUID..CICS.DFHCSD`).
    
- После остановки CICS **в памяти** ничего не остаётся, поэтому ресурсы становятся **не installed**.
    
- Ты руками делаешь `CEDA INSTALL GROUP(Z88011)` — и **LIBT снова появляется**, потому что definitions были в CSD, просто не были installed.
    

## 2) Как сделать, чтобы группа ставилась сама при старте

Нужно, чтобы при инициализации CICS **выполнился install нужной группы** через **startup list**:

### Шаг A — создать LIST и добавить в него GROUP

Параметр **GRPLIST=** принимает **LIST**, а не GROUP. Поэтому обычно делают так:

1. `CEDA DEFINE LIST(Z88011L)`
    
2. `CEDA ADD GROUP(Z88011) LIST(Z88011L)`
    

То же самое можно сделать batch’ом через **DFHCSDUP** (это удобно “как код”):

**DFHCSDUP SYSIN пример**

//SYSIN DD *  
  DEFINE LIST(Z88011L) DESCRIPTION('Auto install for user Z88011')  
  ADD GROUP(Z88011) LIST(Z88011L)  
 /*

### Шаг B — прописать GRPLIST в SIT overrides (в твоём JCL это SYSIN DD *)

У тебя в PROC в конце есть:

//SYSIN DD DISP=SHR,DSN=DFH620.SYSIN(DFH$SIPX)  
//     DD DISP=SHR,DSN=&TSOUID..CICS.SYSIN(DFH$SIP)  
//     DD *,SYMBOLS=EXECSYS  
 XTRAN=NO  
 ...  
 .END

Туда добавь **GRPLIST** (плюс свои стандартные списки, если нужны):

Пример:

 GRPLIST=(DFHLIST,Z88011L)

> Если ты не уверен, какой базовый list используется в вашем “personal region” шаблоне (DFHLIST или другой), безопасный вариант — **добавить второй**, не ломая существующее: `GRPLIST=(<existing>,Z88011L)`.

После этого при каждом старте CICS **Z88011 группа будет installed автоматически**.

---

## 3) Можно ли “просто запускать CEDA INSTALL” из JCL?

Не напрямую.

- `CEDA` — это терминальная транзакция (online), не batch утилита.
    
- Batch утилита **DFHCSDUP** меняет **CSD**, но **не делает INSTALL в уже работающий регион**.
    

Если прям нужен “после старта выполнить INSTALL” автоматически — это делают **через PLTPI/PLTSD**(программа на старте), но в твоём кейсе **правильнее и проще GRPLIST**.

---

## 4) Ответ на твой факт из CEMT

Ты уже показал:

- `CEMT I TRANS(LIBT)` → **транзакция называется `LIBT`**, она вызывает **`LIBMQCIC`** (Pro(LIBMQCIC)).
    

---

Если хочешь, я могу набросать **готовый DFHCSDUP step**, который:

1. гарантирует, что LIST `Z88011L` существует и содержит GROUP `Z88011`,
    
2. и покажу ровно куда вставить строку `GRPLIST=(...,Z88011L)` в твоём SYSIN overrides (чтобы не потереть остальные параметры).