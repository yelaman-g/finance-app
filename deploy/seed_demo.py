#!/usr/bin/env python3
"""
Загрузчик демо-данных AIFB через REST API.

Создаёт чистый демонстрационный набор: семья из трёх пользователей,
операции за последние месяцы, цели с разным прогрессом и лимиты со всеми
статусами (OK / WARNING / EXCEEDED).

Почему через API, а не SQL-дамп: системные категории создаёт миграция Flyway
V4 со СЛУЧАЙНЫМИ UUID (gen_random_uuid()), поэтому при каждом развёртывании их
идентификаторы разные. Сидер резолвит категории по имени в рантайме и потому
переносим между средами. Дополнительно пароли хешируются бэкендом (BCrypt),
а скоупинг семьи отрабатывает штатно.

Запуск (бэкенд уже поднят):
    python3 deploy/seed_demo.py
Переменные окружения:
    AIFB_API   базовый URL API (по умолчанию http://localhost:9090/api/v1)
    AIFB_PWD   пароль демо-пользователей (по умолчанию password1)
Скрипт идемпотентен по пользователям/семье; контент создаётся один раз
(если у owner уже есть операции — повторное наполнение пропускается).
"""
import json
import os
import random
import urllib.error
import urllib.request
from datetime import date

BASE = os.environ.get("AIFB_API", "http://localhost:9090/api/v1")
PWD = os.environ.get("AIFB_PWD", "password1")
rng = random.Random(42)
TODAY = date.today()


# ---------- HTTP ----------
def req(method, path, body=None, token=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, method=method)
    r.add_header("Content-Type", "application/json")
    if token:
        r.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw
    except urllib.error.URLError as e:
        raise SystemExit(f"Не удаётся подключиться к {BASE} — бэкенд запущен? ({e})")


# ---------- helpers ----------
def months_back(n):
    """Дата с тем же днём, что и сегодня, на n месяцев назад (день ограничен концом месяца и сегодняшним днём в текущем месяце)."""
    m = TODAY.month - 1 - n
    y = TODAY.year + (m // 12)
    m = m % 12 + 1
    last = [31, 29 if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0) else 28,
            31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
    day = min(TODAY.day, last)
    return date(y, m, day)


def iso(d):
    return d.isoformat()


def auth(email, full):
    st, b = req("POST", "/auth/register", {"fullName": full, "email": email, "password": PWD})
    if st == 201:
        return b["data"]["tokens"]["accessToken"], b["data"]["user"]["id"], "создан"
    st, b = req("POST", "/auth/login", {"email": email, "password": PWD})
    if st == 200:
        return b["data"]["tokens"]["accessToken"], b["data"]["user"]["id"], "существует"
    raise SystemExit(f"Авторизация не удалась для {email}: {st} {b}")


def cats(token, ctype, scope):
    st, b = req("GET", f"/categories?type={ctype}&scope={scope}", token=token)
    return b["data"] if st == 200 and b and b.get("data") else []


def tx(token, cat, ttype, amount, note, day, shared):
    return req("POST", "/transactions", {"categoryId": cat, "type": ttype, "amount": amount,
               "note": note, "occurredOn": iso(day), "shared": shared}, token=token)[0] in (200, 201)


def goal(token, name, target, deadline, icon, color, shared, contribs):
    st, b = req("POST", "/goals", {"name": name, "targetAmount": target, "deadline": deadline,
                "icon": icon, "color": color, "shared": shared}, token=token)
    if st not in (200, 201):
        print(f"  цель «{name}» пропущена ({st})")
        return
    gid = b["data"]["id"]
    for ctoken, amount in contribs:
        req("POST", f"/goals/{gid}/contributions",
            {"amount": amount, "note": "Взнос", "contributedOn": iso(months_back(1))}, token=ctoken)
    total = sum(a for _, a in contribs)
    print(f"  «{name}»: {total}/{target} ({round(total / target * 100)}%){' [семья]' if shared else ''}")


def limit(token, cat_id, amount, shared):
    return req("POST", "/budgets", {"targetType": "CATEGORY", "categoryId": cat_id,
               "groupId": None, "amount": amount, "shared": shared}, token=token)[0] in (200, 201)


def limit_targets(token, scope):
    st, b = req("GET", f"/budgets?scope={scope}", token=token)
    return {x.get("targetId") for x in (b["data"] if st == 200 and b and b.get("data") else [])}


# ---------- 1. пользователи + семья ----------
print(f"API: {BASE}")
owner, owner_id, s1 = auth("owner_mail@mail.ru", "Алексей Владелец")
adult, adult_id, s2 = auth("adult_mail@mail.ru", "Мария Взрослая")
child, child_id, s3 = auth("child_mail@mail.ru", "Дима Ребёнок")
print(f"Пользователи: owner({s1}), adult({s2}), child({s3}) — пароль {PWD}")

st, b = req("GET", "/households/me", token=owner)
if st == 200 and b and b.get("data"):
    hh = b["data"]
else:
    hh = req("POST", "/households", {"name": "Семья Владельцевых"}, token=owner)[1]["data"]
invite = hh["inviteCode"]
for t in (adult, child):
    st, b = req("GET", "/households/me", token=t)
    if not (st == 200 and b and b.get("data")):
        req("POST", "/households/join", {"inviteCode": invite}, token=t)
req("PUT", f"/households/members/{adult_id}/role", {"role": "ADULT"}, token=owner)
req("PUT", f"/households/members/{child_id}/role", {"role": "CHILD"}, token=owner)
print(f"Семья: «{hh['name']}», код приглашения {invite} (роли OWNER/ADULT/CHILD)")

# Идемпотентность: если контент уже есть — выходим
st, b = req("GET", "/transactions?scope=PERSONAL", token=owner)
existing = (b.get("data") if isinstance(b, dict) else None)
if isinstance(existing, dict):
    existing = existing.get("items") or existing.get("content")
if isinstance(existing, list) and len(existing) > 5:
    print("Контент уже наполнен — пропускаю операции/цели/лимиты. Готово.")
    raise SystemExit(0)

# ---------- 2. операции (личные + семейные) за последние 4 месяца ----------
OFFSETS = [3, 2, 1, 0]  # месяцы назад; 0 = текущий
tx_count = 0


def seed_personal(token, salary):
    global tx_count
    exp = cats(token, "EXPENSE", "PERSONAL")
    inc = cats(token, "INCOME", "PERSONAL")
    for off in OFFSETS:
        d = months_back(off)
        if inc and tx(token, inc[0]["id"], "INCOME", salary, "Зарплата", d, False):
            tx_count += 1
        for _ in range(rng.randint(4, 6)):
            if not exp:
                break
            c = exp[rng.randrange(len(exp))]
            amount = rng.choice([1500, 2400, 3800, 5200, 7600, 12000, 18500])
            if tx(token, c["id"], "EXPENSE", amount, f"Покупка — {c['name']}", d, False):
                tx_count += 1


seed_personal(owner, 520000)
seed_personal(adult, 410000)
seed_personal(child, 35000)

fam_count = 0
for off in OFFSETS:
    d = months_back(off)
    for token in (owner, adult, child):
        fe = cats(token, "EXPENSE", "FAMILY")
        for _ in range(rng.randint(1, 3)):
            if not fe:
                break
            c = fe[rng.randrange(len(fe))]
            amount = rng.choice([4500, 8900, 15000, 23000, 31000])
            if tx(token, c["id"], "EXPENSE", amount, f"Семейные — {c['name']}", d, True):
                fam_count += 1
print(f"Операции: {tx_count} личных + {fam_count} семейных")

# ---------- 3. цели с разным прогрессом ----------
print("Цели:")
goal(owner, "Отпуск на море", 600000, "2026-09-01", "🏖️", "#5AC8FA", True, [(owner, 150000), (adult, 90000)])
goal(owner, "Новый ноутбук", 450000, "2026-08-15", "💻", "#FF9500", False, [(owner, 120000)])
goal(owner, "Подушка безопасности", 1000000, "2026-12-31", "🛡️", "#34C759", False, [(owner, 350000)])
goal(owner, "Новый телефон", 350000, "2026-07-15", "📱", "#007AFF", False, [(owner, 350000)])  # 100%
goal(owner, "Велосипед", 180000, None, "🚲", "#FF9500", False, [(owner, 45000)])
goal(owner, "Ремонт кухни", 1200000, "2027-01-01", "🔨", "#FF3B30", True, [(owner, 300000), (adult, 180000)])
goal(owner, "Новогодние подарки", 200000, "2026-12-20", "🎁", "#AF52DE", True, [])  # 0%
goal(adult, "Курсы английского", 240000, "2026-10-01", "📚", "#5AC8FA", False, [(adult, 120000)])

# ---------- 4. лимиты со всеми статусами ----------
# Расходы под лимит датируем СЕГОДНЯ (лимит считает текущий месяц).
print("Лимиты (с расходами за текущий месяц):")
p_exp = cats(owner, "EXPENSE", "PERSONAL")
free_p = [c for c in p_exp if c["id"] not in limit_targets(owner, "PERSONAL")]
for (spend, lim, label), c in zip([(90000, 60000, "EXCEEDED"), (85000, 100000, "WARNING"), (30000, 120000, "OK")], free_p):
    tx(owner, c["id"], "EXPENSE", spend, "Расход месяца", TODAY, False)
    if limit(owner, c["id"], lim, False):
        print(f"  личный «{c['name']}»: {spend}/{lim} → {label}")

f_exp = cats(owner, "EXPENSE", "FAMILY")
free_f = [c for c in f_exp if c["id"] not in limit_targets(owner, "FAMILY")]
for (spend, lim, label), c in zip([(130000, 100000, "EXCEEDED"), (50000, 60000, "WARNING"), (40000, 200000, "OK")], free_f):
    tx(owner, c["id"], "EXPENSE", spend // 2, "Семейный расход месяца", TODAY, True)
    tx(adult, c["id"], "EXPENSE", spend - spend // 2, "Семейный расход месяца", TODAY, True)
    if limit(owner, c["id"], lim, True):
        print(f"  семейный «{c['name']}»: {spend}/{lim} → {label}")

# ---------- 5. группа категорий + правила авто-категоризации ----------
req("POST", "/groups", {"name": "Обязательные платежи", "type": "EXPENSE",
    "icon": "📌", "color": "#FF3B30", "shared": True}, token=owner)
for kw, c in zip(["magnum", "small", "такси"], cats(owner, "EXPENSE", "PERSONAL")):
    req("POST", "/categorization/rules", {"keyword": kw, "categoryId": c["id"]}, token=owner)
print("Группа «Обязательные платежи» + правила авто-категоризации созданы")

print("\nГОТОВО. Вход: owner_mail@mail.ru / adult_mail@mail.ru / child_mail@mail.ru — пароль", PWD)
