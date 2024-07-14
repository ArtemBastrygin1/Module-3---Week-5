-- Создание таблиц
CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255) NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price NUMERIC(18, 2) NOT NULL,
    stock INT NOT NULL,
    category_id INT,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_date DATE NOT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Вставка данных в таблицы
INSERT INTO product_categories (category_name) VALUES
('Electronics'),
('Books'),
('Clothing'),
('Home & Kitchen'),
('Sports');

INSERT INTO customers (first_name, last_name, email, phone, address) VALUES
('John', 'Doe', 'john.doe@example.com', '123-456-7890', '123 Elm St'),
('Jane', 'Smith', 'jane.smith@example.com', '234-567-8901', '456 Oak St'),
('Alice', 'Johnson', 'alice.johnson@example.com', '345-678-9012', '789 Pine St'),
('Bob', 'Brown', 'bob.brown@example.com', '456-789-0123', '101 Maple St'),
('Charlie', 'Davis', 'charlie.davis@example.com', '567-890-1234', '202 Birch St');

INSERT INTO products (product_name, description, price, stock, category_id) VALUES
('Smartphone', 'Latest model smartphone', 699.99, 50, 1),
('Laptop', 'High performance laptop', 1299.99, 30, 1),
('Novel', 'Bestselling novel', 19.99, 100, 2),
('T-shirt', 'Cotton t-shirt', 9.99, 200, 3),
('Blender', 'Powerful blender', 49.99, 80, 4);

INSERT INTO orders (customer_id, order_date, shipping_address, order_status) VALUES
(1, '2024-01-15', '123 Elm St', 'Shipped'),
(2, '2024-01-16', '456 Oak St', 'Processing'),
(3, '2024-01-17', '789 Pine St', 'Delivered'),
(4, '2024-01-18', '101 Maple St', 'Cancelled'),
(5, '2024-01-19', '202 Birch St', 'Shipped');

INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2, 699.99),
(1, 2, 1, 1299.99),
(2, 1, 3, 699.99),
(3, 3, 5, 19.99),
(4, 4, 2, 9.99);

-- Функция для получения общей суммы продаж по категориям товаров за определенный период
CREATE OR REPLACE FUNCTION get_category_sales(start_date DATE, end_date DATE)
RETURNS TABLE(category_name VARCHAR, total_sales NUMERIC(10, 2)) AS $$
BEGIN
    RETURN QUERY
    SELECT pc.category_name, SUM(od.quantity * od.unit_price) AS total_sales
    FROM product_categories pc
    JOIN products p ON pc.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    JOIN orders o ON od.order_id = o.order_id
    WHERE o.order_date BETWEEN start_date AND end_date
    GROUP BY pc.category_name;
END;
$$ LANGUAGE plpgsql;



-- Процедура для обновления количества товара на складе после создания нового заказа
CREATE OR REPLACE PROCEDURE update_stock_after_order(order_id INT) AS $$
DECLARE
    rec RECORD;
    current_stock INT;
BEGIN
    FOR rec IN
        SELECT product_id, quantity
        FROM order_details
        WHERE order_id = update_stock_after_order.order_id
    LOOP
        -- Получаем текущее количество товара на складе
        SELECT stock INTO current_stock
        FROM products
        WHERE product_id = rec.product_id;

        -- Проверяем, достаточно ли товара на складе для выполнения заказа
        IF current_stock < rec.quantity THEN
            RAISE EXCEPTION 'Not enough stock for product_id %', rec.product_id;
        END IF;

        -- Выполняем обновление количества товара на складе
        UPDATE products
        SET stock = stock - rec.quantity
        WHERE product_id = rec.product_id;

        -- Проверка на отрицательное количество на складе после обновления
        IF (SELECT stock FROM products WHERE product_id = rec.product_id) < 0 THEN
            RAISE EXCEPTION 'Negative stock after update for product_id %', rec.product_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Пример вызова функции
SELECT * FROM get_category_sales('2024-01-15', '2024-01-20');

-- Пример вызова процедуры
CALL update_stock_after_order(1);
