export function success(res, data = {}, message = 'success') {
  return res.json({ success: true, message, data });
}

export function error(res, message = 'error', status = 400) {
  return res.status(status).json({ success: false, message });
}
