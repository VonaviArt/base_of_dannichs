<div align="center">

# 🎮 lab1_steam

**Учебная база данных в стиле Steam: схема, тестовые данные и автотесты ограничений**

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-PL%2FpgSQL-e38c00)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Tests](https://img.shields.io/badge/tests-20%20passed-brightgreen)

</div>

---

## ✨ О проекте

Лабораторная работа №1: реляционная модель магазина игр. В схеме `steam` описаны пользователи, компании, игры и жанры, покупки, библиотеки, отзывы, друзья и списки желаемого. Целостность данных держится на ограничениях самой БД: `UNIQUE`, `CHECK`, `NOT NULL`, внешние ключи и каскадное удаление. Их и проверяют тесты.

## 🗂 Структура

```text
lab1_steam/
├── sql/
│   ├── schema.sql   # схема steam: таблицы и ограничения
│   ├── seed.sql     # тестовые данные
│   └── tests.sql    # автотесты ограничений
├── run_tests.sh     # прогон всего в одноразовом Docker-контейнере
└── README.md
```

## 🧩 Модель данных

<img width="1119" height="1280" alt="image" src="https://github.com/user-attachments/assets/f2f0df46-60ae-494d-b079-b8dc7511ece6" />


| Таблица | Назначение |
|---|---|
| `users` | пользователи (уникальные `username` и `email`) |
| `companies` | разработчики и издатели |
| `games` | игры; `publisher_id` может быть `NULL` |
| `genres`, `game_genres` | жанры и связь «многие ко многим» |
| `purchases`, `purchase_items` | покупки и их состав; цена на момент покупки хранится в `price_at_purchase` |
| `library_entries` | библиотека пользователя и время игры |
| `reviews` | один отзыв на пару «пользователь + игра» |
| `friendships` | дружба со статусом `pending`, `accepted` или `blocked` |
| `wishlist_entries` | списки желаемого |

## 🚀 Быстрый старт

### Вариант 1. Одной командой (нужен Docker)

```bash
./run_tests.sh
```

Скрипт поднимает чистый Postgres, применяет `schema.sql`, `seed.sql`, `tests.sql` в фиксированном порядке и печатает отчёт:

```text
4/4 Тесты (sql/tests.sql)
  ✔ дубликат username отклонён
  ✔ дубликат email отклонён
  ...
Итог: 20 из 20 проверок пройдено
```

После прогона контейнер удаляется, ваши базы не затрагиваются. Код выхода `0` значит, что всё прошло, иначе тесты провалены.

### Вариант 2. Локальный `psql`

```bash
createdb steam_test
psql -d steam_test -v ON_ERROR_STOP=1 -f sql/schema.sql -f sql/seed.sql -f sql/tests.sql
```

> ⚠️ `schema.sql` начинается с `DROP SCHEMA steam CASCADE`, поэтому запускайте его в отдельной базе, а не в рабочей.

Если `psql` пишет `роль "..." не существует`, создайте роль: `sudo -u postgres createuser -s $USER`.

## 🧪 Что проверяют тесты

| Группа | Проверки |
|---|---|
| 🔑 **UNIQUE** | дубликаты `username`, `email`, названия компании, пар в `game_genres`, `purchase_items`, `wishlist_entries`, повторный отзыв |
| 🚫 **NOT NULL** | `games.title` |
| ✅ **CHECK** | неотрицательные цена игры, сумма покупки, `price_at_purchase`, `playtime_minutes`; дружба с самим собой; допустимые значения `status` |
| 🔗 **FOREIGN KEY** | несуществующий `developer_id`; удаление игры с жанрами запрещено (у `game_genres` нет `ON DELETE CASCADE`) |
| 🌊 **CASCADE** | удаление покупки, пользователя или игры чистит зависимые записи |
| 🟢 **Допустимое** | игра без издателя (`publisher_id IS NULL`) принимается |

Всего **20 проверок**.

## ⚙️ Как устроены тесты

- Каждая проверка выполняется в отдельном блоке `DO`. У блока с `EXCEPTION` в PL/pgSQL есть неявная точка сохранения, поэтому ожидаемая ошибка не ломает внешнюю транзакцию.
- Весь файл обёрнут в `BEGIN` / `ROLLBACK`, поэтому тесты никогда не меняют данные из `seed.sql`, независимо от результата.
- Проваленная проверка вызывает `RAISE`, и скрипт прерывается из-за `ON_ERROR_STOP`.

