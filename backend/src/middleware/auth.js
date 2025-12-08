import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';
import { error } from '../utils/response.js';

export function auth(requiredRole) {
  return (req, res, next) => {
    const header = req.headers.authorization;
    if (!header) return error(res, 'No token', 401);
    const token = header.split(' ')[1];
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      if (requiredRole && decoded.role !== requiredRole) {
        return error(res, 'Forbidden', 403);
      }
      req.user = decoded;
      next();
    } catch (e) {
      return error(res, 'Invalid token', 401);
    }
  };
}
