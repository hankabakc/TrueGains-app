-- V66: Add phone number and OTP verification columns to app_user table
ALTER TABLE app_user 
ADD COLUMN phone_number VARCHAR(20) UNIQUE,
ADD COLUMN is_phone_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN otp_code VARCHAR(6);
