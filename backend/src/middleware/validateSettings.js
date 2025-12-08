import { error } from '../utils/response.js';

export function validatePaymentSettings(req, res, next) {
  const { bank_name, account_number, account_name, whatsapp_phone } = req.body || {};

  const bn = bank_name === undefined ? undefined : String(bank_name).trim();
  const an = account_number === undefined ? undefined : String(account_number).trim();
  const aa = account_name === undefined ? undefined : String(account_name).trim();
  const wp = whatsapp_phone === undefined ? undefined : String(whatsapp_phone).trim();

  if (bn !== undefined && bn.length === 0) {
    return error(res, 'Bank name cannot be empty', 400);
  }
  if (an !== undefined && an.length === 0) {
    return error(res, 'Account number cannot be empty', 400);
  }
  if (aa !== undefined && aa.length === 0) {
    return error(res, 'Account name cannot be empty', 400);
  }

  if (wp !== undefined) {
    const normalized = wp.replace(/[^0-9+]/g, '');
    const e164 = normalized.startsWith('0') ? '62' + normalized.slice(1) : normalized;
    if (!/^\+?\d{8,15}$/.test(e164)) {
      return error(res, 'Invalid WhatsApp phone format', 400);
    }
    req.body.whatsapp_phone = e164.replace(/^\+/, '');
  }

  next();
}
