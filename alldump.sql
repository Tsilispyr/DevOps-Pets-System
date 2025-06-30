-- DevOps Pets Database Dump
-- This file contains the initial database schema and data

-- Create database
CREATE DATABASE IF NOT EXISTS devops_pets;
USE devops_pets;

-- Create tables
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    age INTEGER,
    description TEXT,
    owner_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (username, email) VALUES
('admin', 'admin@devops-pets.com'),
('user1', 'user1@example.com'),
('user2', 'user2@example.com');

INSERT INTO pets (name, type, age, description, owner_id) VALUES
('Buddy', 'Dog', 3, 'Friendly golden retriever', 1),
('Whiskers', 'Cat', 2, 'Playful tabby cat', 2),
('Polly', 'Bird', 1, 'Colorful parrot', 3);

-- Create indexes
CREATE INDEX idx_pets_owner ON pets(owner_id);
CREATE INDEX idx_users_email ON users(email); 