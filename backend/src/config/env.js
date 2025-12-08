import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  appBaseUrl: process.env.APP_BASE_URL || `http://localhost:${process.env.PORT || 3000}`,
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    name: process.env.DB_NAME || 'rental_motor'
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'devsecret',
    expires: process.env.TOKEN_EXPIRES || '7d'
  },
  payment: {
    bankName: process.env.PAYMENT_BANK_NAME || process.env.BANK_NAME || 'BCA',
    accountNumber: process.env.PAYMENT_ACCOUNT_NUMBER || process.env.BANK_ACCOUNT || '1234567890',
    accountName: process.env.PAYMENT_ACCOUNT_NAME || process.env.BANK_ACCOUNT_NAME || 'PT MotorKu',
    whatsappPhone: (process.env.PAYMENT_WHATSAPP_PHONE || process.env.WHATSAPP_PHONE || '6281234567890').replace(/[^0-9]/g, ''),
  }
};
8421361606
