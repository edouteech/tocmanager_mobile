CREATE DATABASE IF NOT EXISTS my_database;

CREATE TABLE IF NOT EXISTS my_database.categories(
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` dateTime NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` dateTime NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.suppliers(
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(255) NOT NULL,
  `register_number` varchar(255) DEFAULT NULL,
  `legal_form` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.products (
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `quantity` double(8, 2) NOT NULL DEFAULT 0.00,
  `price_sell` double(8, 2) NOT NULL DEFAULT 0.00,
  `price_buy` double(8, 2) NOT NULL DEFAULT 0.00,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`category_id`) REFERENCES my_database.categories(id),
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.buys (
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `date_buy` dateTime,
  `amount` double(8,2) NOT NULL DEFAULT 0.00,
  `supplier_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`supplier_id`) REFERENCES my_database.suppliers(id),
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.buy_lines (
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `buy_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`buy_id`) REFERENCES my_database.buys(id),
  `product_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`product_id`) REFERENCES my_database.products(id),
  `quantity` bigint(20) UNSIGNED NOT NULL,
  `amount` double(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.sells (
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `date_sell` dateTime,
  `amount` double(8,2) NOT NULL DEFAULT 0.00,
  `client_name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS my_database.sell_lines (
  `id` bigint(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `sell_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`sell_id`) REFERENCES my_database.sells(id),
  `product_id` bigint(20) UNSIGNED NOT NULL,
  FOREIGN KEY (`product_id`) REFERENCES my_database.products(id),
  `quantity` bigint(20) UNSIGNED NOT NULL,
  `amount` double(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP()
);
