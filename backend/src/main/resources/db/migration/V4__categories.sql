CREATE TABLE categories (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    type VARCHAR(10) NOT NULL,
    icon VARCHAR(40),
    color VARCHAR(9),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_categories_type CHECK (type IN ('INCOME', 'EXPENSE'))
);

CREATE UNIQUE INDEX uk_categories_user_name_type
    ON categories (user_id, lower(name), type)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_categories_visible
    ON categories (user_id, type) WHERE deleted_at IS NULL;

INSERT INTO categories (id, user_id, name, type, icon, color, is_system) VALUES
    (gen_random_uuid(), NULL, 'Еда',          'EXPENSE', 'restaurant',   '#FF7043', TRUE),
    (gen_random_uuid(), NULL, 'Транспорт',    'EXPENSE', 'directions_car','#42A5F5', TRUE),
    (gen_random_uuid(), NULL, 'Жильё',        'EXPENSE', 'home',         '#8D6E63', TRUE),
    (gen_random_uuid(), NULL, 'Развлечения',  'EXPENSE', 'movie',        '#AB47BC', TRUE),
    (gen_random_uuid(), NULL, 'Здоровье',     'EXPENSE', 'favorite',     '#EF5350', TRUE),
    (gen_random_uuid(), NULL, 'Покупки',      'EXPENSE', 'shopping_bag', '#26A69A', TRUE),
    (gen_random_uuid(), NULL, 'Связь',        'EXPENSE', 'wifi',         '#5C6BC0', TRUE),
    (gen_random_uuid(), NULL, 'Прочее',       'EXPENSE', 'category',     '#78909C', TRUE),
    (gen_random_uuid(), NULL, 'Зарплата',     'INCOME',  'payments',     '#66BB6A', TRUE),
    (gen_random_uuid(), NULL, 'Подработка',   'INCOME',  'work',         '#9CCC65', TRUE),
    (gen_random_uuid(), NULL, 'Подарки',      'INCOME',  'redeem',       '#EC407A', TRUE),
    (gen_random_uuid(), NULL, 'Инвестиции',   'INCOME',  'trending_up',  '#26C6DA', TRUE),
    (gen_random_uuid(), NULL, 'Прочее',       'INCOME',  'category',     '#78909C', TRUE);
