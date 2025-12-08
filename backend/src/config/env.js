import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
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
    bankName: process.env.BANK_NAME || 'BCA',
    accountNumber: process.env.BANK_ACCOUNT || '8421361606',
    accountName: process.env.BANK_ACCOUNT_NAME || 'Ahmad Gibran Faizal',
    whatsappPhone: process.env.WHATSAPP_PHONE || '6281290240404',
  }
};
