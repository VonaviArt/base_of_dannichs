-- Набор тестов для схемы steam.
--
-- Запуск:
--   psql -v ON_ERROR_STOP=1 -f sql/schema.sql -f sql/seed.sql -f sql/tests.sql



BEGIN;

DO $$ BEGIN RAISE NOTICE 'тесты схемы steam'; END $$;

-- users.username UNIQUE
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.users (username, email, password_hash)
        VALUES ('bogdan', 'someone_else@example.com', 'x');
        RAISE EXCEPTION 'ОШИБКА: дубликат username был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат username отклонён';
    END;
END $$;

-- users.email UNIQUE
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.users (username, email, password_hash)
        VALUES ('someone_else', 'bogdan@example.com', 'x');
        RAISE EXCEPTION 'ОШИБКА: дубликат email был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат email отклонён';
    END;
END $$;

-- companies.name UNIQUE
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.companies (name, country, found_year)
        VALUES ('Valve', 'USA', 2000);
        RAISE EXCEPTION 'ОШИБКА: дубликат названия компании был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат названия компании отклонён';
    END;
END $$;

-- games.developer_id должен ссылаться на существующую компанию
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.games (title, developer_id, price)
        VALUES ('Ghost Game', 999999, 9.99);
        RAISE EXCEPTION 'ОШИБКА: игра с несуществующим developer_id была принята';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: несуществующий developer_id отклонён';
    END;
END $$;

-- games.title NOT NULL
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.games (title, developer_id, price)
        VALUES (NULL, 1, 9.99);
        RAISE EXCEPTION 'ОШИБКА: игра с NULL в title была принята';
    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'OK: NULL в названии игры отклонён';
    END;
END $$;

-- games.price CHECK (price >= 0)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.games (title, developer_id, price)
        VALUES ('Negative Price Game', 1, -1.00);
        RAISE EXCEPTION 'ОШИБКА: отрицательная цена игры была принята';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: отрицательная цена игры отклонена';
    END;
END $$;

-- games.publisher_id допускает NULL (игра без издателя)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.games (title, developer_id, publisher_id, price)
        VALUES ('Self Published Game', 1, NULL, 4.99);
        RAISE NOTICE 'OK: игра с NULL в publisher_id принята';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'ОШИБКА: игра с NULL в publisher_id была отклонена (%)', SQLERRM;
    END;
END $$;

-- первичный ключ game_genres запрещает дубликаты пар (game_id, genre_id)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.game_genres (game_id, genre_id) VALUES (1, 1);
        RAISE EXCEPTION 'ОШИБКА: дубликат пары в game_genres был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат пары в game_genres отклонён';
    END;
END $$;

-- purchases.total_amount CHECK (total_amount >= 0)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.purchases (user_id, total_amount)
        VALUES (1, -5.00);
        RAISE EXCEPTION 'ОШИБКА: отрицательная сумма покупки была принята';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: отрицательная сумма покупки отклонена';
    END;
END $$;

-- purchase_items.price_at_purchase CHECK (price_at_purchase >= 0)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.purchase_items (purchase_id, game_id, price_at_purchase)
        VALUES (1, 2, -1.00);
        RAISE EXCEPTION 'ОШИБКА: отрицательный price_at_purchase был принят';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: отрицательный price_at_purchase отклонён';
    END;
END $$;

-- purchase_items UNIQUE (purchase_id, game_id)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.purchase_items (purchase_id, game_id, price_at_purchase)
        VALUES (1, 1, 19.99);
        RAISE EXCEPTION 'ОШИБКА: дубликат пары в purchase_items был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат пары в purchase_items отклонён';
    END;
END $$;

-- purchase_items удаляются вместе с покупкой (ON DELETE CASCADE)
DO $$
DECLARE
    remaining_items INTEGER;
BEGIN
    DELETE FROM steam.purchases WHERE id = 1;
    SELECT count(*) INTO remaining_items
    FROM steam.purchase_items WHERE purchase_id = 1;

    IF remaining_items <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: purchase_items остались после удаления покупки';
    END IF;
    RAISE NOTICE 'OK: purchase_items каскадно удалены вместе с покупкой';
END $$;

-- library_entries.playtime_minutes CHECK (playtime_minutes >= 0)
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.library_entries (user_id, game_id, playtime_minutes)
        VALUES (1, 3, -10);
        RAISE EXCEPTION 'ОШИБКА: отрицательный playtime_minutes был принят';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: отрицательный playtime_minutes отклонён';
    END;
END $$;

-- reviews UNIQUE (user_id, game_id): пользователь не может дважды оставить отзыв на одну игру
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.reviews (user_id, game_id, is_positive)
        VALUES (1, 1, FALSE);
        RAISE EXCEPTION 'ОШИБКА: повторный отзыв того же пользователя на ту же игру был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: повторный отзыв отклонён';
    END;
END $$;

-- при удалении пользователя удаляются его зависимые записи ON DELETE CASCADE
DO $$
DECLARE
    remaining_reviews INTEGER;
    remaining_library INTEGER;
    remaining_wishlist INTEGER;
    remaining_friendships INTEGER;
BEGIN
    DELETE FROM steam.users WHERE id = 1;

    SELECT count(*) INTO remaining_reviews FROM steam.reviews WHERE user_id = 1;
    SELECT count(*) INTO remaining_library FROM steam.library_entries WHERE user_id = 1;
    SELECT count(*) INTO remaining_wishlist FROM steam.wishlist_entries WHERE user_id = 1;
    SELECT count(*) INTO remaining_friendships FROM steam.friendships
        WHERE user_id = 1 OR friend_id = 1;

    IF remaining_reviews <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: reviews остались после удаления пользователя';
    END IF;
    IF remaining_library <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: library_entries остались после удаления пользователя';
    END IF;
    IF remaining_wishlist <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: wishlist_entries остались после удаления пользователя';
    END IF;
    IF remaining_friendships <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: friendships остались после удаления пользователя';
    END IF;
    RAISE NOTICE 'OK: удаление пользователя каскадно удаляет reviews, library_entries, wishlist_entries и friendships';
END $$;

-- friendships CHECK user_id - friend_id: нельзя дружить с самим собой
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.friendships (user_id, friend_id, status)
        VALUES (2, 2, 'accepted');
        RAISE EXCEPTION 'ОШИБКА: дружба с самим собой была принята';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: дружба с самим собой отклонена';
    END;
END $$;

-- friendships CHECK (status IN ('pending', 'accepted', 'blocked'))
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.friendships (user_id, friend_id, status)
        VALUES (2, 3, 'friends');
        RAISE EXCEPTION 'ОШИБКА: недопустимый статус дружбы был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'ОШИБКА: неожиданный unique_violation вместо check_violation';
        WHEN check_violation THEN
            RAISE NOTICE 'OK: недопустимый статус дружбы отклонён';
    END;
END $$;

-- первичный ключ wishlist_entries запрещает дубликаты пар user_id, game_id
DO $$
BEGIN
    BEGIN
        INSERT INTO steam.wishlist_entries (user_id, game_id) VALUES (2, 1);
        RAISE EXCEPTION 'ОШИБКА: дубликат пары в wishlist_entries был принят';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: дубликат пары в wishlist_entries отклонён';
    END;
END $$;

-- у game_genres НЕТ ON DELETE CASCADE по game_id, поэтому удаление игры,
-- у которой ещё есть жанры, должно отклоняться, а не каскадироваться.
DO $$
BEGIN
    BEGIN
        DELETE FROM steam.games WHERE id = 1;
        RAISE EXCEPTION 'ОШИБКА: удалена игра, на которую ещё ссылаются строки game_genres';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: удаление игры с существующими строками game_genres отклонено';
    END;
END $$;

-- wishlist_entries/library_entries/reviews удаляются вместе с игрой
-- (ON DELETE CASCADE по game_id). Используется новая игра без строк в
-- game_genres/purchase_items, чтобы само удаление не было отклонено.
DO $$
DECLARE
    new_game_id BIGINT;
    remaining_wishlist INTEGER;
    remaining_library INTEGER;
    remaining_reviews INTEGER;
BEGIN
    INSERT INTO steam.games (title, developer_id, price)
    VALUES ('Throwaway Cascade Game', 1, 1.00)
    RETURNING id INTO new_game_id;

    INSERT INTO steam.wishlist_entries (user_id, game_id) VALUES (2, new_game_id);
    INSERT INTO steam.library_entries (user_id, game_id) VALUES (2, new_game_id);
    INSERT INTO steam.reviews (user_id, game_id, is_positive) VALUES (2, new_game_id, TRUE);

    DELETE FROM steam.games WHERE id = new_game_id;

    SELECT count(*) INTO remaining_wishlist FROM steam.wishlist_entries WHERE game_id = new_game_id;
    SELECT count(*) INTO remaining_library FROM steam.library_entries WHERE game_id = new_game_id;
    SELECT count(*) INTO remaining_reviews FROM steam.reviews WHERE game_id = new_game_id;

    IF remaining_wishlist <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: wishlist_entries остались после удаления игры';
    END IF;
    IF remaining_library <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: library_entries остались после удаления игры';
    END IF;
    IF remaining_reviews <> 0 THEN
        RAISE EXCEPTION 'ОШИБКА: reviews остались после удаления игры';
    END IF;
    RAISE NOTICE 'OK: удаление игры каскадно удаляет wishlist_entries, library_entries и reviews';
END $$;

DO $$ BEGIN RAISE NOTICE 'все тесты пройдены, ура ура'; END $$;

ROLLBACK;
