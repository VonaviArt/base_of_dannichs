INSERT INTO steam.users (
    username, 
    email, 
    password_hash
    ) 
    VALUES 
    (
        'bogdan',
        'bogdan@example.com',
        'hashed_password123'
    ), 
    (
        'artem',
        'artem@example.com',
        'hashed_password321'
    );

INSERT INTO steam.companies (name, country, found_year)
VALUES ('Valve', 'USA', 1996),
    ('CD Projekt Red', 'Poland', 1994),
    ('Firaxis Games', 'USA', 1999);

INSERT INTO steam.genres (name)
VALUES
    ('Action'),
    ('RPG'),
    ('Strategy'),
    ('Simulation');

INSERT INTO steam.games (title, developer_id, publisher_id, price, release_date, description)
VALUES
    ('Half-Life 2', 1, 1, 19.99, '2004-11-16', 'A first-person shooter game'),
    ('The Witcher 3: Wild Hunt', 1, 1, 59.99, '2015-05-19', 'A story-driven RPG'),
    ('Sid Meier''s Civilization VI', 2, 2, 59.99, '2016-10-21', 'A 4X strategy game');

INSERT INTO steam.game_genres (game_id, genre_id)
VALUES
    (1, 1),
    (2, 1),
    (2, 2),
    (3, 3);

INSERT INTO steam.purchases (user_id, total_amount)
VALUES
    (1, 19.99),
    (2, 89.99);

INSERT INTO steam.purchase_items (purchase_id, game_id, price_at_purchase)
VALUES
    (1, 1, 19.99),
    (2, 2, 59.99),
    (2, 3, 30.00);

INSERT INTO steam.library_entries (user_id, game_id, playtime_minutes)
VALUES
    (1, 1, 40),
    (2, 2, 0),
    (2, 3, 5600);

INSERT INTO steam.reviews (user_id, game_id, is_positive, review_text)
VALUES
    (1, 1, TRUE, 'Легендарная игра'),
    (2, 2, FALSE, NULL);

INSERT INTO steam.friendships (user_id, friend_id, status)
VALUES
    (1, 2, 'accepted'),
    (2, 1, 'accepted');

INSERT INTO steam.wishlist_entries (user_id, game_id)
VALUES
    (1, 2),
    (2, 1);
