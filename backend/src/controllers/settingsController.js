import { config } from '../config/env.js';
import { success, error } from '../utils/response.js';

export function getPaymentSettings(req, res) {
  const p = config.payment;
  return success(res, {
    bank_name: p.bankName,
    account_number: p.accountNumber,
    account_name: p.accountName,
    whatsapp_phone: p.whatsappPhone,
  });
}

export function updatePaymentSettings(req, res) {
  const { bank_name, account_number, account_name, whatsapp_phone } = req.body || {};
  const p = config.payment;
  if (typeof bank_name === 'string') p.bankName = bank_name;
  if (typeof account_number === 'string') p.accountNumber = account_number;
  if (typeof account_name === 'string') p.accountName = account_name;
  if (typeof whatsapp_phone === 'string') p.whatsappPhone = whatsapp_phone;
  return success(res, {
    bank_name: p.bankName,
    account_number: p.accountNumber,
    account_name: p.accountName,
    whatsapp_phone: p.whatsappPhone,
  }, 'Settings updated');
}
