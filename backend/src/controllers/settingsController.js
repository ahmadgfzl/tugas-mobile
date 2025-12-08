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

  const bn = bank_name === undefined ? undefined : String(bank_name).trim();
  const an = account_number === undefined ? undefined : String(account_number).trim();
  const aa = account_name === undefined ? undefined : String(account_name).trim();
  const wp = whatsapp_phone === undefined ? undefined : String(whatsapp_phone).trim();

  if (wp !== undefined) {
    p.whatsappPhone = wp;
  }
  if (bn !== undefined) p.bankName = bn;
  if (an !== undefined) p.accountNumber = an;
  if (aa !== undefined) p.accountName = aa;

  return success(res, {
    bank_name: p.bankName,
    account_number: p.accountNumber,
    account_name: p.accountName,
    whatsapp_phone: p.whatsappPhone,
  }, 'Settings updated');
}
